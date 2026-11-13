import { generateKeyPairSync, randomUUID, sign } from 'node:crypto';
import { loadConfig } from '../src/config/env.js';
import { createSupabaseIntegration } from '../src/integrations/supabase.js';

export function fixture(options: { unavailable?: boolean } = {}) {
  const config = loadConfig({
    NODE_ENV: 'test',
    SUPABASE_URL: `https://${randomUUID()}.supabase.co`,
    SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_local_test_fixture_only',
    ALLOWED_ORIGINS: 'http://localhost:3000',
  });
  const { privateKey, publicKey } = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
  const kid = randomUUID();
  const id = randomUUID();
  const calls: Request[] = [];
  const fetchImplementation: typeof fetch = async (input, init) => {
    const request = new Request(input, init);
    calls.push(request);
    if (options.unavailable) throw new TypeError('Simulated provider failure with sensitive details');
    if (request.url === `${config.SUPABASE_URL}/auth/v1/.well-known/jwks.json`) {
      return Response.json({ keys: [{ ...publicKey.export({ format: 'jwk' }), kid, alg: 'ES256', use: 'sig' }] });
    }
    if (request.url.startsWith(`${config.SUPABASE_URL}/rest/v1/`)) return Response.json([]);
    throw new Error('Unexpected external request in test');
  };
  const supabase = createSupabaseIntegration(config, fetchImplementation);
  function token(overrides: Record<string, unknown> = {}, forged = false) {
    const header = Buffer.from(JSON.stringify({ alg: 'ES256', typ: 'JWT', kid })).toString('base64url');
    const payload = Buffer.from(JSON.stringify({
      sub: id,
      iss: `${config.SUPABASE_URL}/auth/v1`,
      aud: 'authenticated',
      role: 'authenticated',
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 3600,
      ...overrides,
    })).toString('base64url');
    const signingKey = forged
      ? generateKeyPairSync('ec', { namedCurve: 'prime256v1' }).privateKey
      : privateKey;
    const signature = sign('sha256', Buffer.from(`${header}.${payload}`), {
      key: signingKey, dsaEncoding: 'ieee-p1363',
    }).toString('base64url');
    return `${header}.${payload}.${signature}`;
  }
  return { config, id, calls, supabase, token };
}

import { createClient, isAuthError, type SupabaseClient } from '@supabase/supabase-js';
import { z } from 'zod';
import type { Config } from '../config/env.js';
import { HttpError } from '../shared/http-error.js';

export interface AuthenticatedUser {
  id: string;
}

export interface SupabaseIntegration {
  verifyToken(token: string): Promise<AuthenticatedUser | null>;
  forUser(token: string): SupabaseClient;
}

export function createSupabaseIntegration(
  config: Config,
  fetchImplementation: typeof fetch = fetch,
): SupabaseIntegration {
  const timedFetch: typeof fetch = (input, options = {}) => {
    const signal = AbortSignal.timeout(10_000);
    return fetchImplementation(input, {
      ...options,
      signal: options.signal ? AbortSignal.any([options.signal, signal]) : signal,
    });
  };
  const options = {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: { fetch: timedFetch },
  };
  const authClient = createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, options);
  const claimsSchema = z.object({
    sub: z.uuid(),
    iss: z.literal(`${config.SUPABASE_URL}/auth/v1`),
    aud: z.union([z.literal('authenticated'), z.array(z.string()).refine(
      (audience) => audience.includes('authenticated'),
    )]),
    role: z.literal('authenticated'),
    exp: z.number().int(),
    nbf: z.number().optional(),
  });
  const tokenSchema = z.object({
    header: z.object({
      alg: z.enum(['ES256', 'RS256', 'HS256']),
      kid: z.string().optional(),
    }),
    claims: claimsSchema,
  });

  return {
    async verifyToken(token) {
      // Solo comprobar la estructura aquí; la identidad exige la firma verificada por el SDK.
      try {
        const parts = token.split('.');
        if (parts.length !== 3 || !parts.every((part) => /^[A-Za-z0-9_-]+$/.test(part))) return null;
        const parsed = tokenSchema.safeParse({
          header: JSON.parse(Buffer.from(parts[0]!, 'base64url').toString('utf8')),
          claims: JSON.parse(Buffer.from(parts[1]!, 'base64url').toString('utf8')),
        });
        if (!parsed.success) return null;
      } catch {
        return null;
      }
      try {
        // Verifica firma y caducidad con las claves del proyecto; no basta decodificar.
        const { data, error } = await authClient.auth.getClaims(token);
        if (error) {
          if (error.status === 0 || (error.status !== undefined && error.status >= 500)) {
            throw new HttpError(503, 'AUTH_UNAVAILABLE', 'Autenticación temporalmente no disponible.');
          }
          return null;
        }
        const parsed = claimsSchema.safeParse(data?.claims);
        if (!parsed.success) return null;
        const now = Date.now() / 1000;
        if (parsed.data.exp <= now || (parsed.data.nbf !== undefined && parsed.data.nbf > now)) {
          return null;
        }
        return { id: parsed.data.sub };
      } catch (error) {
        if (error instanceof HttpError) throw error;
        if (isAuthError(error) && error.status !== 0 && (error.status ?? 400) < 500) return null;
        throw new HttpError(503, 'AUTH_UNAVAILABLE', 'Autenticación temporalmente no disponible.');
      }
    },
    forUser(token) {
      // Cliente independiente por petición: no comparte sesiones ni tokens entre usuarios.
      return createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, {
        ...options,
        accessToken: async () => token,
      });
    },
  };
}

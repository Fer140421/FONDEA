import assert from 'node:assert/strict';
import { once } from 'node:events';
import { randomUUID } from 'node:crypto';
import { createClient } from '@supabase/supabase-js';
import { createApp } from '../src/app.js';
import { loadConfig } from '../src/config/env.js';
import { createSupabaseIntegration, type AuthenticatedUser } from '../src/integrations/supabase.js';
import { createStellarIntegration } from '../src/integrations/stellar.js';

async function main() {
  const config = loadConfig();
  const supabase = createSupabaseIntegration(config);
  const results: boolean[] = [];

  async function check(name: string, operation: () => Promise<void>) {
    try {
      await operation();
      console.log(`OK: ${name}`);
      results.push(true);
    } catch {
      // Los errores del proveedor pueden incluir tokens, URLs o credenciales.
      console.error(`ERROR: ${name}. Revisa la configuración, el SQL y la conectividad.`);
      results.push(false);
    }
  }

  await check('Stellar: consulta Horizon y confirma testnet', async () => {
    const stellar = createStellarIntegration(config);
    const root = await stellar.horizon.root();
    assert.equal(root.network_passphrase, stellar.networkPassphrase);
  });

  const createPublicClient = () => createClient(config.SUPABASE_URL, config.SUPABASE_PUBLISHABLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: { fetch: (input, options) => fetch(input, { ...options, signal: AbortSignal.timeout(10_000) }) },
  });
  const loginClient = createPublicClient();
  const anonymous = createPublicClient();
  let token = process.env.INTEGRATION_ACCESS_TOKEN?.trim();
  let user: AuthenticatedUser | null = null;
  let signedIn = false;
  const app = createApp(config, { supabase });
  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  const address = server.address();
  assert(address && typeof address === 'object');
  const base = `http://127.0.0.1:${address.port}`;
  const request = (path: string, accessToken?: string) => fetch(`${base}${path}`, {
    headers: accessToken ? { Authorization: `Bearer ${accessToken}` } : {},
    signal: AbortSignal.timeout(15_000),
  });

  try {
    await check('HTTP: health público y API protegida sin token', async () => {
      const health = await request('/health');
      assert.equal(health.status, 200);
      assert.deepEqual(await health.json(), { status: 'ok' });
      assert.equal((await request('/api/v1/me')).status, 401);
      assert.equal((await request('/api/v1/me', 'invalid-token')).status, 401);
    });

    await check('Auth: sesión de prueba y token verificado', async () => {
      if (!token) {
        const email = process.env.INTEGRATION_EMAIL;
        const password = process.env.INTEGRATION_PASSWORD;
        if (!email || !password) {
          console.error('Configura INTEGRATION_ACCESS_TOKEN o INTEGRATION_EMAIL e INTEGRATION_PASSWORD en .env.');
          throw new Error('Falta una sesión de prueba.');
        }
        const { data, error } = await loginClient.auth.signInWithPassword({ email, password });
        assert.equal(error, null);
        token = data.session?.access_token;
        signedIn = Boolean(token);
      }
      assert(token);
      user = await supabase.verifyToken(token);
      assert(user);
      const me = await request('/api/v1/me', token);
      assert.equal(me.status, 200);
      assert.deepEqual(await me.json(), { user: { id: user.id } });
    });

    if (token && user) {
      const client = supabase.forUser(token);
      await check('Database: lectura autenticada y rechazo anónimo', async () => {
        const { data, error } = await client.from('backend_connection_checks')
          .select('id,message').eq('id', 1).single();
        assert.equal(error, null);
        assert.deepEqual(data, { id: 1, message: 'fondea-backend-ready' });
        const denied = await anonymous.from('backend_connection_checks').select('id');
        assert(denied.error, 'La tabla técnica debe rechazar consultas anónimas.');
      });

      await check('Storage: subir, descargar, aislar carpetas y eliminar archivo', async () => {
        const storage = client.storage.from(config.SUPABASE_STORAGE_BUCKET);
        const path = `${user!.id}/${randomUUID()}.txt`;
        const content = 'Fondea T03 integration check';
        let uploaded = false;
        try {
          const upload = await storage.upload(path, Buffer.from(content), { contentType: 'text/plain' });
          assert.equal(upload.error, null);
          uploaded = true;
          const download = await storage.download(path);
          assert.equal(download.error, null);
          assert.equal(await download.data!.text(), content);

          const anonymousDownload = await anonymous.storage.from(config.SUPABASE_STORAGE_BUCKET).download(path);
          assert(anonymousDownload.error, 'El archivo privado no debe ser accesible anónimamente.');

          const foreignPath = `${randomUUID()}/${randomUUID()}.txt`;
          const denied = await storage.upload(foreignPath, Buffer.from(content), { contentType: 'text/plain' });
          if (!denied.error) {
            // Limpiar también si el aislamiento está mal configurado.
            await storage.remove([foreignPath]);
            throw new Error('Storage permitió escribir fuera de la carpeta del usuario.');
          }
        } finally {
          if (uploaded) {
            const removal = await storage.remove([path]);
            assert.equal(removal.error, null);
            assert.equal(removal.data?.length, 1);
            const deleted = await storage.download(path);
            assert(deleted.error, 'El archivo de prueba debe haber sido eliminado.');
          }
        }
      });
    } else {
      console.error('PENDIENTE: Database y Storage requieren que la comprobación de Auth pase.');
      results.push(false);
    }
  } finally {
    await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
    if (signedIn) {
      const { error } = await loginClient.auth.signOut({ scope: 'local' });
      if (error) {
        console.error('ERROR: no se pudo cerrar la sesión de prueba creada por el script.');
        results.push(false);
      }
    }
  }
  if (results.some((passed) => !passed)) process.exitCode = 1;
}

main().catch(() => {
  console.error('No se pudo completar la integración. Revisa .env y los recursos de prueba en Supabase.');
  process.exitCode = 1;
});

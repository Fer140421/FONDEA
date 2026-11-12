import assert from 'node:assert/strict';
import { test } from 'node:test';
import request from 'supertest';
import { createApp } from '../src/app.js';
import { fixture } from './helpers.js';

test('health es público y no contacta Supabase', async () => {
  const context = fixture();
  const response = await request(createApp(context.config, context)).get('/health');
  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { status: 'ok' });
  assert.equal(context.calls.length, 0);
});

test('acepta un JWT firmado por el proyecto y devuelve solo la identidad', async () => {
  const context = fixture();
  const response = await request(createApp(context.config, context))
    .get('/api/v1/me').auth(context.token(), { type: 'bearer' });
  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { user: { id: context.id } });
  assert.equal(response.headers['cache-control'], 'no-store');
  assert.equal(context.calls.length, 1);
});

test('todas las rutas de módulos requieren token antes de resolver endpoints', async () => {
  const context = fixture();
  const app = createApp(context.config, context);
  for (const path of ['me', 'registro', 'solicitudes', 'aportes', 'etapas', 'cuotas', 'future-endpoint']) {
    const response = await request(app).get(`/api/v1/${path}`);
    assert.equal(response.status, 401, path);
    assert.equal(response.headers['cache-control'], 'no-store');
    assert.equal(response.headers['www-authenticate'], 'Bearer');
  }
  assert.equal(context.calls.length, 0);
});

test('rechaza formatos de autorización inválidos sin consultar Supabase', async () => {
  const context = fixture();
  const app = createApp(context.config, context);
  for (const authorization of ['Basic abc', 'Bearer invalid', 'Bearer a.b.c extra', 'Bearer']) {
    const response = await request(app).get('/api/v1/me').set('Authorization', authorization);
    assert.equal(response.status, 401);
  }
  const malformedJwt = await request(app).get('/api/v1/me').auth('a.b.c', { type: 'bearer' });
  assert.equal(malformedJwt.status, 401);
  assert.equal(context.calls.length, 0);
});

test('rechaza firma falsa aunque el JWT contenga datos aparentemente válidos', async () => {
  const context = fixture();
  const response = await request(createApp(context.config, context))
    .get('/api/v1/me').auth(context.token({}, true), { type: 'bearer' });
  assert.equal(response.status, 401);
  assert.equal(response.headers['www-authenticate'], 'Bearer error="invalid_token"');
});

test('rechaza un JWT caducado con firma válida', async () => {
  const context = fixture();
  const response = await request(createApp(context.config, context))
    .get('/api/v1/me').auth(context.token({ exp: Math.floor(Date.now() / 1000) - 60 }), { type: 'bearer' });
  assert.equal(response.status, 401);
});

test('rechaza issuer, audiencia, rol, sujeto o vigencia incompatibles', async () => {
  const context = fixture();
  const app = createApp(context.config, context);
  for (const overrides of [
    { iss: 'https://another-project.supabase.co/auth/v1' },
    { aud: 'another-api' },
    { role: 'service_role' },
    { sub: undefined },
    { sub: 'not-a-uuid' },
    { nbf: Math.floor(Date.now() / 1000) + 600 },
    { exp: undefined },
  ]) {
    const response = await request(app).get('/api/v1/me').auth(context.token(overrides), { type: 'bearer' });
    assert.equal(response.status, 401, JSON.stringify(overrides));
  }
});

test('una caída de Auth produce 503 y no expone detalles del proveedor', async () => {
  const context = fixture({ unavailable: true });
  const response = await request(createApp(context.config, context))
    .get('/api/v1/me').auth(context.token(), { type: 'bearer' });
  assert.equal(response.status, 503);
  assert.deepEqual(response.body, { error: {
    code: 'AUTH_UNAVAILABLE', message: 'Autenticación temporalmente no disponible.',
  } });
});

test('los clientes de usuarios distintos envían tokens independientes y clave publicable', async () => {
  const context = fixture();
  const firstToken = context.token();
  const secondToken = context.token({ sub: '5ea9429d-f421-46da-8aba-23521a893aa8' });
  const first = context.supabase.forUser(firstToken);
  const second = context.supabase.forUser(secondToken);
  await Promise.all([
    first.from('backend_connection_checks').select('id'),
    second.from('backend_connection_checks').select('id'),
  ]);
  await first.from('backend_connection_checks').select('id');
  assert.deepEqual(context.calls.map((call) => call.headers.get('authorization')), [
    `Bearer ${firstToken}`, `Bearer ${secondToken}`, `Bearer ${firstToken}`,
  ]);
  assert(context.calls.every((call) => call.headers.get('apikey') === context.config.SUPABASE_PUBLISHABLE_KEY));
});

test('CORS permite el preflight del origen configurado sin exigir token', async () => {
  const context = fixture();
  const app = createApp(context.config, context);
  const preflight = await request(app).options('/api/v1/me')
    .set('Origin', 'http://localhost:3000').set('Access-Control-Request-Method', 'GET');
  assert.equal(preflight.status, 204);
  assert.equal(preflight.headers['access-control-allow-origin'], 'http://localhost:3000');
  const deniedOrigin = await request(app).get('/health').set('Origin', 'https://untrusted.example');
  assert.equal(deniedOrigin.headers['access-control-allow-origin'], undefined);
});

test('las rutas futuras no simulan endpoints implementados', async () => {
  const context = fixture();
  const response = await request(createApp(context.config, context))
    .get('/api/v1/solicitudes').auth(context.token(), { type: 'bearer' });
  assert.equal(response.status, 404);
  assert.equal(response.body.error.code, 'NOT_FOUND');
});

import assert from 'node:assert/strict';
import { test } from 'node:test';
import { loadConfig } from '../src/config/env.js';

const environment = {
  SUPABASE_URL: 'https://example.supabase.co/',
  SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_local_test_fixture_only',
};

test('normaliza configuración y fija testnet por defecto', () => {
  const config = loadConfig(environment);
  assert.equal(config.SUPABASE_URL, 'https://example.supabase.co');
  assert.equal(config.STELLAR_NETWORK, 'testnet');
  assert.equal(config.STELLAR_HORIZON_URL, 'https://horizon-testnet.stellar.org');
  assert.equal(config.PORT, 3000);
  assert.deepEqual(config.ALLOWED_ORIGINS, []);
});

test('falla al arrancar con configuración ausente, administrativa o mainnet', () => {
  for (const invalid of [
    {},
    { ...environment, SUPABASE_PUBLISHABLE_KEY: 'sb_secret_sensitive_value' },
    { ...environment, SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_replace_me' },
    { ...environment, PORT: '0' },
    { ...environment, PORT: '65536' },
    { ...environment, STELLAR_NETWORK: 'mainnet' },
    { ...environment, STELLAR_HORIZON_URL: 'https://horizon.stellar.org' },
    { ...environment, SUPABASE_URL: 'https://username:password@example.supabase.co' },
    { ...environment, ALLOWED_ORIGINS: '*' },
    { ...environment, SUPABASE_URL: 'not-a-url' },
    { ...environment, SUPABASE_URL: 'https://example.supabase.co/?query=value' },
    { ...environment, SUPABASE_URL: 'https://example.supabase.co/#fragment' },
    { ...environment, SUPABASE_URL: 'https://example.supabase.co/path' },
  ]) assert.throws(() => loadConfig(invalid), /Configuración inválida/);
});

test('los errores de entorno nombran campos sin imprimir sus valores', () => {
  assert.throws(() => loadConfig({ ...environment, SUPABASE_PUBLISHABLE_KEY: 'sensitive-value' }), (error) => {
    assert(error instanceof Error);
    assert.match(error.message, /SUPABASE_PUBLISHABLE_KEY/);
    assert(!error.message.includes('sensitive-value'));
    return true;
  });
});

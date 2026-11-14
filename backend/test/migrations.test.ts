import assert from 'node:assert/strict';
import { test } from 'node:test';
import { cloudConnectionString } from '../scripts/database-cloud.js';

const project = 'https://fondea-example.supabase.co';

test('migración acepta conexión directa del proyecto configurado', () => {
  const result = cloudConnectionString('postgresql://postgres:dummy-test-password@db.fondea-example.supabase.co:5432/postgres', project);
  assert.equal(new URL(result).hostname, 'db.fondea-example.supabase.co');
});

test('migración acepta Session pooler únicamente con el usuario del proyecto', () => {
  const result = cloudConnectionString('postgresql://postgres.fondea-example:dummy-test-password@aws-0-test.pooler.supabase.com:5432/postgres', project);
  assert.equal(new URL(result).username, 'postgres.fondea-example');
});

test('migración rechaza proyecto ajeno, Transaction pooler y destinos arbitrarios', () => {
  for (const value of [
    'postgresql://postgres:dummy@db.another.supabase.co:5432/postgres',
    'postgresql://postgres.another:dummy@aws-0-test.pooler.supabase.com:5432/postgres',
    'postgresql://postgres.fondea-example:dummy@aws-0-test.pooler.supabase.com:6543/postgres',
    'postgresql://postgres:dummy@localhost:5432/postgres',
    'postgresql://postgres@db.fondea-example.supabase.co:5432/postgres',
    'https://postgres:dummy@db.fondea-example.supabase.co:5432/postgres',
  ]) assert.throws(() => cloudConnectionString(value, project));
});

test('opciones de la cadena no pueden reemplazar la configuración TLS del ejecutor', () => {
  const result = cloudConnectionString('postgresql://postgres:dummy@db.fondea-example.supabase.co:5432/postgres?sslmode=disable&sslcert=/tmp/untrusted', project);
  assert.equal(new URL(result).search, '');
});

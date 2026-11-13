import { readFileSync } from 'node:fs';
import pg from 'pg';
import { migrations } from './migrations.js';

export function cloudConnectionString(value: string, projectUrl: string): string {
  const url = new URL(value);
  const project = new URL(projectUrl).hostname.split('.')[0];
  const direct = url.hostname === `db.${project}.supabase.co` && decodeURIComponent(url.username) === 'postgres';
  const sessionPooler = url.hostname.endsWith('.pooler.supabase.com') && decodeURIComponent(url.username) === `postgres.${project}`;
  if (!['postgres:', 'postgresql:'].includes(url.protocol) || (!direct && !sessionPooler) || (url.port && url.port !== '5432') || url.pathname !== '/postgres' || !url.password) {
    throw new Error('Se requiere conexión directa o Session pooler del proyecto configurado, puerto 5432 y base postgres.');
  }
  // Las opciones de la URL no pueden desactivar TLS ni leer certificados locales.
  url.search = '';
  url.hash = '';
  return url.toString();
}

async function main() {
  const index = process.argv.indexOf('--url-file');
  const path = index >= 0 ? process.argv[index + 1] : undefined;
  if (!path || !process.env.SUPABASE_URL) throw new Error('Falta archivo de conexión o SUPABASE_URL.');
  const connectionString = cloudConnectionString(readFileSync(path, 'utf8').trim(), process.env.SUPABASE_URL);
  const client = new pg.Client({ connectionString, ssl: { rejectUnauthorized: true }, connectionTimeoutMillis: 15_000, query_timeout: 60_000 });
  let currentMigration = 'conexión y comprobación del proyecto';
  try {
    await client.connect();
    await client.query("select pg_advisory_lock(hashtext('fondea-schema-migrations'))");
    await client.query(`create schema if not exists supabase_migrations;
      create table if not exists supabase_migrations.schema_migrations(version text primary key, statements text[], name text);`);
    const list = migrations();
    const applied = await client.query<{ version: string }>('select version from supabase_migrations.schema_migrations');
    const versions = new Set(applied.rows.map((row) => row.version));
    if ([...versions].some((version) => !list.some((migration) => migration.version === version))) throw new Error('Existen versiones remotas fuera de este repositorio.');
    for (const migration of list) {
      if (versions.has(migration.version)) continue;
      currentMigration = migration.name;
      await client.query('begin');
      try {
        await client.query(migration.sql);
        await client.query('insert into supabase_migrations.schema_migrations(version,name,statements) values($1,$2,$3)', [migration.version, migration.name, [migration.sql]]);
        await client.query('commit');
        console.log(`Aplicada en el proyecto configurado: ${migration.name}`);
      } catch (error) {
        await client.query('rollback');
        throw error;
      }
    }
    const result = await client.query<{ count: string }>(`select count(*) from pg_tables where schemaname='public' and rowsecurity
      and tablename in ('usuarios','negocios','documentos','prestamos','etapas','aportes','evidencias','votos','cuotas','notificaciones','repartos','eventos_prestamo','eventos_reputacion','dispositivos','parametros')`);
    if (result.rows[0]?.count !== '15') throw new Error('No están las quince tablas con RLS.');
    console.log('T04: quince tablas con RLS verificadas en el proyecto configurado.');
  } catch (error) {
    const code = error instanceof pg.DatabaseError ? error.code : 'CONNECTION_OR_CONFIGURATION';
    console.error(`Migración remota incompleta en ${currentMigration}. Código: ${code}. No se muestran datos de conexión.`);
    process.exitCode = 1;
  } finally {
    await client.end();
  }
}
if (process.argv[1]?.endsWith('database-cloud.ts')) {
  main().catch(() => {
    console.error('No se pudo preparar la conexión. Revisa --url-file y el proyecto de .env.');
    process.exitCode = 1;
  });
}

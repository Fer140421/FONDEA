import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { migrations } from './migrations.js';

export const container = 'fondea-db-test';
export function sqlLocal(sql: string, role: 'postgres' | 'supabase_admin' = 'postgres'): string {
  const result = spawnSync('docker', ['exec', '-i', container, 'psql', '-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-U', role, '-d', 'postgres'], {
    input: sql, encoding: 'utf8', maxBuffer: 4 * 1024 * 1024,
  });
  if (result.status !== 0) throw new Error((result.stderr || result.error?.message || 'Falló PostgreSQL local.') + '\n' + result.stdout);
  return result.stdout;
}

if (process.argv[1]?.endsWith('database-local.ts')) {
  const operation = process.argv[2];
  if (operation === 'start') {
    const run = (args: string[]) => {
      const result = spawnSync('docker', ['compose', '-f', 'compose.database.yml', ...args], { stdio: 'inherit' });
      if (result.status !== 0) throw new Error('No se pudo iniciar el entorno Docker de pruebas.');
    };
    run(['up', '-d', '--wait', 'db']);
    sqlLocal(readFileSync('test/database/local-bootstrap.sql', 'utf8'), 'supabase_admin');
    run(['up', '-d', '--wait']);
  } else if (operation === 'migrate') {
    sqlLocal(`create schema if not exists supabase_migrations;
      create table if not exists supabase_migrations.schema_migrations(version text primary key, statements text[], name text);`);
    for (const migration of migrations()) {
      if (sqlLocal(`select count(*) from supabase_migrations.schema_migrations where version='${migration.version}';`).trim() !== '0') continue;
      sqlLocal(`begin; ${migration.sql}\ninsert into supabase_migrations.schema_migrations(version,name) values ('${migration.version}','${migration.name}'); commit;`);
      console.log(`Aplicada localmente: ${migration.name}`);
    }
  } else {
    throw new Error('Uso: database-local.ts start|migrate. Este comando solo actúa sobre el contenedor local de pruebas.');
  }
}

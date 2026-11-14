import { readdirSync, readFileSync } from 'node:fs';

export function migrations() {
  return readdirSync('supabase/migrations')
    .filter((file) => /^\d+_[a-z_]+\.sql$/.test(file)).sort()
    .map((name) => ({
      name,
      version: name.split('_')[0]!,
      // El ejecutor añade una única transacción que incluye el registro de versión.
      sql: readFileSync(`supabase/migrations/${name}`, 'utf8').replace(/^\s*(begin|commit);\s*$/gim, ''),
    }));
}

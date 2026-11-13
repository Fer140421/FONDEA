import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import { test } from 'node:test';
import { spawn } from 'node:child_process';
import { sqlLocal } from '../../scripts/database-local.js';

// psql se ejecuta dentro del contenedor local: no lee .env ni admite URLs remotas.
for (const file of readdirSync('test/database').filter((file) => file.endsWith('.test.sql')).sort()) {
  test(`PostgreSQL/RLS: ${file}`, () => {
    const fixture = readFileSync('test/database/fixtures.sql', 'utf8');
    const output = sqlLocal(`begin; create extension if not exists pgtap with schema extensions; ${fixture}\n${readFileSync(`test/database/${file}`, 'utf8')}\nrollback;`);
    const plan = /^1\.\.(\d+)$/m.exec(output);
    assert(plan, `Falta el plan pgTAP: ${output}`);
    assert(!/^not ok\b/m.test(output), output);
    assert.equal(output.split('\n').filter((line) => /^ok\b/.test(line)).length, Number(plan[1]), output);
    console.log(output.trim());
  });
}

function concurrentSql(sql: string): Promise<{ code: number | null; stderr: string }> {
  return new Promise((resolve, reject) => {
    const process = spawn('docker', ['exec', '-i', 'fondea-db-test', 'psql', '-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-U', 'postgres', '-d', 'postgres']);
    let stderr = '';
    process.stdout.resume();
    process.stderr.on('data', (chunk: Buffer) => { stderr += chunk.toString(); });
    process.once('error', reject);
    process.once('close', (code) => resolve({ code, stderr }));
    process.stdin.end(sql);
  });
}

function prepareConcurrency(): void {
  assert.equal(sqlLocal('select count(*) from public.usuarios;').trim(), '0', 'Las carreras requieren la base local de pruebas vacía.');
  sqlLocal(`begin; ${readFileSync('test/database/fixtures.sql', 'utf8')} commit;`);
}

function cleanConcurrency(): void {
  // Solo este contenedor desechable; evita deshabilitar las guardas del historial.
  sqlLocal(`truncate public.usuarios cascade;
    delete from auth.users where id in (${[1, 2, 11, 12, 13, 14, 21, 22, 30].map((id) => `'00000000-0000-4000-8000-${id.toString().padStart(12, '0')}'`).join(',')});`);
}

test('Concurrencia: dos aportes no sobre financian el préstamo', async () => {
  prepareConcurrency();
  try {
    sqlLocal(`insert into public.aportes(prestamo_id,prestamista_id,monto,tx_hash)
      values('00000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000011',400,repeat('a',64));`);
    const results = await Promise.all([12, 13].map((id, index) => concurrentSql(`begin;
      insert into public.aportes(prestamo_id,prestamista_id,monto,tx_hash)
      values('00000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-${id.toString().padStart(12, '0')}',500,repeat('${index ? 'c' : 'b'}',64));
      select pg_sleep(0.4); commit;`)));
    assert.equal(results.filter((result) => result.code === 0).length, 1);
    assert.match(results.find((result) => result.code !== 0)!.stderr, /fuera de límites/);
    assert.equal(sqlLocal("select monto_recaudado from public.prestamos where id='00000000-0000-4000-8000-000000000101';").trim(), '900.00');
  } finally {
    cleanConcurrency();
  }
});

test('Concurrencia: la promoción de primer aporte se consume una sola vez', async () => {
  prepareConcurrency();
  try {
    sqlLocal(`begin;
      insert into public.prestamos(id,negocio_id,justificacion,monto,plazo_meses,tasa_anual,meses_hasta_primera_cuota,max_prestamistas)
      values('00000000-0000-4000-8000-000000000102','00000000-0000-4000-8000-000000000202','Capital para iniciar un negocio con las herramientas necesarias.',1000,3,7,1,5);
      insert into public.etapas(prestamo_id,numero,objetivo,monto,evidencia_requerida) values
      ('00000000-0000-4000-8000-000000000102',1,'Comprar herramientas',300,'Fotos de herramientas'),
      ('00000000-0000-4000-8000-000000000102',2,'Equipar el local',700,'Fotos del local');
      update public.prestamos set estado='financiandose' where id='00000000-0000-4000-8000-000000000102'; commit;`);
    const results = await Promise.all([101, 102].map((id, index) => concurrentSql(`begin;
      insert into public.aportes(prestamo_id,prestamista_id,monto,tx_hash)
      values('00000000-0000-4000-8000-${id.toString().padStart(12, '0')}','00000000-0000-4000-8000-000000000011',100,repeat('${index ? 'c' : 'b'}',64));
      select pg_sleep(0.4); commit;`)));
    assert.equal(results.filter((result) => result.code === 0).length, 1);
    assert.match(results.find((result) => result.code !== 0)!.stderr, /fuera de límites/);
    assert.equal(sqlLocal('select count(*) from public.aportes;').trim(), '1');
  } finally {
    cleanConcurrency();
  }
});

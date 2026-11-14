select extensions.plan(14);
-- La API de Storage activa este contexto al eliminar objetos; se conserva RLS.
set local storage.allow_delete_query='true';
insert into public.documentos(negocio_id,tipo,url) values
 ('00000000-0000-4000-8000-000000000201','foto_negocio','00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000201/foto.jpg'),
 ('00000000-0000-4000-8000-000000000201','licencia','00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000201/licencia.pdf');
insert into storage.objects(bucket_id,name) values
 ('negocios','00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000201/foto.jpg'),
 ('negocios','00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000201/licencia.pdf'),
 ('identidad','00000000-0000-4000-8000-000000000001/carnet.jpg');
select extensions.is((select count(*)::int from storage.buckets where id in ('identidad','negocios','evidencias') and not public),3,'Tres buckets privados de negocio');
set local request.jwt.claims='{"sub":"00000000-0000-4000-8000-000000000013","role":"authenticated"}'; set local role authenticated;
select extensions.is((select count(*)::int from public.documentos),1,'Solo la foto del negocio es visible en mercado');
select extensions.is((select count(*)::int from storage.objects where bucket_id='negocios'),1,'La política de archivos coincide con la de documentos');
select extensions.is((select count(*)::int from storage.objects where bucket_id='identidad'),0,'El carnet no es público');
select extensions.throws_like($$insert into storage.objects(bucket_id,name) values('identidad','00000000-0000-4000-8000-000000000001/falso.jpg')$$,'%row-level security%','Nadie sube archivos a la carpeta de otro');
reset role;
-- Simula una política permisiva heredada para demostrar que las restrictivas conservan el aislamiento.
create policy prueba_abierta on storage.objects for all to authenticated using(true) with check(true);
set local role authenticated;
select extensions.is((select count(*)::int from storage.objects where bucket_id='negocios'),1,'Una política permisiva ajena no expone la licencia');
with cambios as (update storage.objects set name=name||'.nuevo' where bucket_id='negocios' returning *) select extensions.is((select count(*)::int from cambios),0,'No se sobrescriben archivos registrados');
reset role;
set local request.jwt.claims='{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}'; set local role authenticated;
select extensions.is((select count(*)::int from storage.objects where bucket_id='negocios'),2,'Dueño consulta foto y licencia');
with borrados as (delete from storage.objects where name like '%licencia.pdf' returning *) select extensions.is((select count(*)::int from borrados),0,'Archivo registrado no se elimina');
select extensions.lives_ok($$insert into storage.objects(bucket_id,name) values('identidad','00000000-0000-4000-8000-000000000001/temporal.jpg')$$,'Dueño carga un archivo propio');
with borrados as (delete from storage.objects where name like '%temporal.jpg' returning *) select extensions.is((select count(*)::int from borrados),1,'Dueño limpia una carga sin referencias');
reset role;
update public.prestamos set estado='cancelado' where id='00000000-0000-4000-8000-000000000101';
set local request.jwt.claims='{"sub":"00000000-0000-4000-8000-000000000013","role":"authenticated"}'; set local role authenticated;
select extensions.is((select count(*)::int from storage.objects where bucket_id='negocios'),0,'Al salir del mercado deja de verse la foto');
reset role;
set local role anon;
select extensions.is((select count(*)::int from storage.objects where bucket_id in ('negocios','identidad')),0,'Anónimo no lee los archivos privados');
reset role;
select extensions.throws_like($$update public.documentos set tipo='foto_negocio' where tipo='licencia'$$,'%conservar historial%','Documento publicado no se reclasifica como público');
select * from extensions.finish();

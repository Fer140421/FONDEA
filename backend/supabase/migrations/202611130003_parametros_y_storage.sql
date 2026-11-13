begin;

insert into public.parametros(clave,valor,descripcion) values
 ('comision_originacion',2,'Porcentaje del préstamo descontado en la última etapa'),
 ('comision_servicio',1,'Porcentaje de cada cuota retenido antes del reparto'),
 ('aporte_minimo',300,'Aporte mínimo ordinario en bolivianos'),
 ('aporte_minimo_inicial',100,'Primer aporte promocional en bolivianos'),
 ('tope_prestamista',50,'Porcentaje máximo por prestamista sobre el monto aceptado'),
 ('tasa_maxima_anual',7,'Tasa anual máxima expresada como porcentaje'),
 ('limite_idea_nueva',3000,'Techo por solicitud de una idea nueva en bolivianos'),
 ('limite_en_marcha',10000,'Techo por solicitud de un negocio en marcha en bolivianos'),
 ('dias_primer_aporte',7,'Días desde la primera verificación para el primer aporte promocional')
 on conflict(clave) do nothing;

insert into storage.buckets(id,name,public) values
 ('identidad','identidad',false),('negocios','negocios',false),('evidencias','evidencias',false)
 on conflict(id) do update set public=false;

create function private.leer_archivo(cubo text,ruta text) returns boolean language plpgsql stable security definer set search_path='' as $$
begin
  if (select auth.uid()) is null or ruta like '%..%' then return false; end if;
  if private.es_staff() then return true; end if;
  if cubo='identidad' then return split_part(ruta,'/',1)=(select auth.uid())::text; end if;
  if cubo='negocios' then return exists (
    select 1 from public.negocios n where n.id::text=split_part(ruta,'/',2) and n.usuario_id::text=split_part(ruta,'/',1) and
    (n.usuario_id=(select auth.uid()) or exists(select 1 from public.documentos d where d.negocio_id=n.id and d.url=ruta and d.tipo='foto_negocio' and private.negocio_en_mercado(n.id)))
  ); end if;
  if cubo='evidencias' then return exists (
    select 1 from public.etapas e join public.prestamos p on p.id=e.prestamo_id
    where e.id::text=split_part(ruta,'/',2) and p.emprendedor_id::text=split_part(ruta,'/',1) and
    (p.emprendedor_id=(select auth.uid()) or (private.es_participante(p.id) and exists(select 1 from public.evidencias v where v.etapa_id=e.id and ruta=any(v.archivos))))
  ); end if;
  return false;
end $$;
create function private.subir_archivo(cubo text,ruta text) returns boolean language plpgsql stable security definer set search_path='' as $$
begin
  if (select auth.uid()) is null or ruta like '%..%' or split_part(ruta,'/',1) is distinct from (select auth.uid())::text then return false; end if;
  if cubo='identidad' then return length(split_part(ruta,'/',2))>0; end if;
  if cubo='negocios' then return exists (
    select 1 from public.negocios n where n.id::text=split_part(ruta,'/',2) and n.usuario_id=(select auth.uid()) and length(split_part(ruta,'/',3))>0
    and not exists(select 1 from public.prestamos p where p.negocio_id=n.id and p.publicado_en is not null and p.bloquea_nueva_solicitud)
  ); end if;
  if cubo='evidencias' then return exists (
    select 1 from public.etapas e join public.prestamos p on p.id=e.prestamo_id where e.id::text=split_part(ruta,'/',2) and p.emprendedor_id=(select auth.uid())
    and e.liberada_en is not null and e.fecha_limite_evidencia>=now() and p.estado in ('en_etapas','en_pago','pausado') and length(split_part(ruta,'/',3))>0
  ); end if;
  return false;
end $$;
create function private.borrar_archivo(cubo text,ruta text) returns boolean language plpgsql stable security definer set search_path='' as $$
begin
  if (select auth.uid()) is null or split_part(ruta,'/',1) is distinct from (select auth.uid())::text then return false; end if;
  if cubo='identidad' then return not exists(select 1 from public.usuarios where carnet_anverso_url=ruta or carnet_reverso_url=ruta); end if;
  if cubo='negocios' then return not exists(select 1 from public.documentos where url=ruta); end if;
  if cubo='evidencias' then return not exists(select 1 from public.evidencias where ruta=any(archivos)); end if;
  return false;
end $$;

grant usage on schema private to anon;
revoke all on function private.leer_archivo(text,text),private.subir_archivo(text,text),private.borrar_archivo(text,text) from public,anon,authenticated;
grant execute on function private.leer_archivo(text,text),private.subir_archivo(text,text),private.borrar_archivo(text,text) to anon,authenticated;
create policy fondea_archivos_lectura on storage.objects for select to authenticated
 using(bucket_id in ('identidad','negocios','evidencias') and private.leer_archivo(bucket_id,name));
create policy fondea_archivos_alta on storage.objects for insert to authenticated
 with check(bucket_id in ('identidad','negocios','evidencias') and private.subir_archivo(bucket_id,name));
create policy fondea_archivos_borrado on storage.objects for delete to authenticated
 using(bucket_id in ('identidad','negocios','evidencias') and private.borrar_archivo(bucket_id,name));
-- AND adicional: políticas permisivas generales del proyecto no deben abrir estos buckets.
create policy fondea_limite_lectura on storage.objects as restrictive for select to anon,authenticated
 using(bucket_id not in ('identidad','negocios','evidencias') or private.leer_archivo(bucket_id,name));
create policy fondea_limite_alta on storage.objects as restrictive for insert to anon,authenticated
 with check(bucket_id not in ('identidad','negocios','evidencias') or private.subir_archivo(bucket_id,name));
create policy fondea_limite_borrado on storage.objects as restrictive for delete to anon,authenticated
 using(bucket_id not in ('identidad','negocios','evidencias') or private.borrar_archivo(bucket_id,name));
create policy fondea_sin_sobrescritura on storage.objects as restrictive for update to anon,authenticated
 using(bucket_id not in ('identidad','negocios','evidencias')) with check(bucket_id not in ('identidad','negocios','evidencias'));

commit;

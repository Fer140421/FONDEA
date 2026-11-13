begin;

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated, service_role;
-- Los permisos de ejecución se revocan explícitamente al terminar cada migración de funciones.

create domain public.monto_bob as numeric(12,2)
  check (value >= 0 and value <= 9999999999.99);
create domain public.porcentaje as numeric(5,2)
  check (value >= 0 and value <= 100);
create domain public.hash_stellar as text check (value ~ '^[0-9a-f]{64}$');

create type public.rol_usuario as enum ('emprendedor','prestamista','admin','soporte');
create type public.estado_verificacion as enum ('pendiente','verificado','rechazado');
create type public.categoria_negocio as enum ('comercio','alimentos','produccion','servicios','otros');
create type public.tipo_negocio as enum ('en_marcha','idea_nueva');
create type public.formalidad_negocio as enum ('formal','informal');
create type public.tipo_documento as enum ('matricula','licencia','foto_negocio','factura');
create type public.estado_prestamo as enum ('borrador','en_revision','rechazado','financiandose','cancelado','financiado','en_etapas','en_pago','en_mora','pausado','pagado');
create type public.estado_etapa as enum ('pendiente','liberada','en_revision','aprobada','rechazada','pausada','congelada');
create type public.estado_aporte as enum ('activo','devuelto');
create type public.estado_evidencia as enum ('en_revision','aprobada','rechazada');
create type public.decision_voto as enum ('aprueba','rechaza');
create type public.estado_cuota as enum ('pendiente','pagada','atrasada');
create type public.tipo_notificacion as enum ('vencimiento','votacion','etapa_liberada','cobro','mora','solicitud');
create type public.tipo_evento_prestamo as enum ('cambio_estado','aporte','etapa_liberada','evidencia','voto','cuota_pagada','devolucion','mediacion','intervencion_soporte');
create type public.motivo_reputacion as enum ('etapa_aprobada','cuota_a_tiempo','prestamo_completado','evidencia_rechazada','atraso','mora','evidencia_vencida');
create type public.plataforma_dispositivo as enum ('android','web');

create table public.usuarios (
  id uuid primary key default auth.uid() references auth.users(id) on delete restrict,
  nombre text not null check (length(btrim(nombre)) between 3 and 100),
  correo text not null check (correo ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'),
  celular text not null check (celular ~ '^[0-9]{8}$'),
  rol public.rol_usuario not null,
  carnet_anverso_url text,
  carnet_reverso_url text,
  estado_verificacion public.estado_verificacion not null default 'pendiente',
  contacto_emergencia_nombre text not null check (length(btrim(contacto_emergencia_nombre)) between 3 and 100),
  contacto_emergencia_celular text not null check (contacto_emergencia_celular ~ '^[0-9]{8}$'),
  billetera text unique check (billetera ~ '^G[A-Z2-7]{55}$'),
  estrellas numeric(2,1) not null default 3.0 check (estrellas between 1 and 5 and mod(estrellas,0.5)=0),
  es_nuevo boolean not null default true,
  limite_monto public.monto_bob not null default 10000 check (limite_monto > 0),
  verificado_en timestamptz,
  primer_aporte_hasta timestamptz,
  creado_en timestamptz not null default now()
);
create unique index usuarios_correo_unique on public.usuarios(lower(correo));

create table public.negocios (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references public.usuarios(id) on delete restrict,
  nombre text not null check (length(btrim(nombre)) between 3 and 100),
  categoria public.categoria_negocio not null,
  tipo public.tipo_negocio not null,
  formalidad public.formalidad_negocio,
  descripcion text not null check (length(btrim(descripcion)) between 20 and 1000),
  creado_en timestamptz not null default now(),
  check (tipo <> 'en_marcha' or formalidad is not null)
);

create table public.documentos (
  id uuid primary key default gen_random_uuid(),
  negocio_id uuid not null references public.negocios(id) on delete restrict,
  tipo public.tipo_documento not null,
  url text not null unique,
  fecha_documento date check (fecha_documento <= current_date),
  creado_en timestamptz not null default now()
);

create table public.prestamos (
  id uuid primary key default gen_random_uuid(),
  negocio_id uuid not null references public.negocios(id) on delete restrict,
  emprendedor_id uuid not null references public.usuarios(id) on delete restrict,
  justificacion text check (length(btrim(justificacion)) between 50 and 2000),
  monto public.monto_bob check (monto > 0),
  plazo_meses integer check (plazo_meses between 3 and 12),
  tasa_anual public.porcentaje,
  meses_hasta_primera_cuota integer check (meses_hasta_primera_cuota between 1 and 3),
  cantidad_cuotas integer generated always as (plazo_meses-meses_hasta_primera_cuota+1) stored,
  monto_cuota public.monto_bob generated always as
    (round(monto*(1+tasa_anual/1200*plazo_meses)/nullif(plazo_meses-meses_hasta_primera_cuota+1,0),2)) stored,
  total_devolver public.monto_bob generated always as (round(monto*(1+tasa_anual/1200*plazo_meses),2)) stored,
  max_prestamistas integer check (max_prestamistas between 2 and 5),
  monto_recaudado public.monto_bob not null default 0,
  estado public.estado_prestamo not null default 'borrador',
  motivo_rechazo text,
  escrow_id text,
  publicado_en timestamptz,
  fecha_limite_financiamiento timestamptz,
  ampliado boolean not null default false,
  financiado_en timestamptz,
  primer_desembolso_en timestamptz,
  comision_originacion_pactada public.porcentaje,
  comision_servicio_pactada public.porcentaje,
  aporte_minimo_pactado public.monto_bob,
  aporte_inicial_pactado public.monto_bob,
  tope_prestamista_pactado public.porcentaje,
  limite_monto_pactado public.monto_bob,
  tasa_maxima_pactada public.porcentaje,
  tipo_negocio_pactado public.tipo_negocio,
  bloquea_nueva_solicitud boolean not null default true,
  creado_en timestamptz not null default now(),
  check (plazo_meses is null or meses_hasta_primera_cuota is null or meses_hasta_primera_cuota <= case when plazo_meses<=6 then 2 else 3 end),
  check (estado='borrador' or (justificacion is not null and monto is not null and plazo_meses is not null and tasa_anual is not null and meses_hasta_primera_cuota is not null and max_prestamistas is not null)),
  check (estado<>'rechazado' or (motivo_rechazo is not null and length(btrim(motivo_rechazo))>0)),
  check (publicado_en is null or (comision_originacion_pactada is not null and comision_servicio_pactada is not null and aporte_minimo_pactado is not null and aporte_inicial_pactado is not null and tope_prestamista_pactado is not null and limite_monto_pactado is not null and tasa_maxima_pactada is not null and tipo_negocio_pactado is not null)),
  check (monto is null or monto_recaudado<=monto),
  check (primer_desembolso_en is null or (financiado_en is not null and primer_desembolso_en>=financiado_en))
);
create unique index prestamos_una_solicitud_abierta on public.prestamos(emprendedor_id) where bloquea_nueva_solicitud;

create table public.etapas (
  id uuid primary key default gen_random_uuid(),
  prestamo_id uuid not null references public.prestamos(id) on delete cascade,
  numero integer not null check (numero between 1 and 3),
  objetivo text not null check (length(btrim(objetivo)) between 10 and 300),
  monto public.monto_bob not null check (monto>0),
  evidencia_requerida text not null check (length(btrim(evidencia_requerida)) between 5 and 300),
  estado public.estado_etapa not null default 'pendiente',
  liberada_en timestamptz,
  fecha_limite_evidencia timestamptz,
  comision_descontada public.monto_bob not null default 0,
  tx_hash public.hash_stellar unique,
  unique(prestamo_id,numero),
  check ((liberada_en is null)=(tx_hash is null)),
  check (fecha_limite_evidencia is null or fecha_limite_evidencia in (liberada_en+interval '15 days',liberada_en+interval '20 days'))
);

create table public.aportes (
  id uuid primary key default gen_random_uuid(),
  prestamo_id uuid not null references public.prestamos(id) on delete restrict,
  prestamista_id uuid not null references public.usuarios(id) on delete restrict,
  monto public.monto_bob not null check (monto>0),
  monto_devuelto public.monto_bob not null default 0,
  porcentaje public.porcentaje not null,
  estado public.estado_aporte not null default 'activo',
  tx_hash public.hash_stellar not null unique,
  devolucion_tx_hash public.hash_stellar,
  creado_en timestamptz not null default now(),
  unique(prestamo_id,prestamista_id),
  check (monto_devuelto<=monto),
  check ((estado='devuelto')=(monto_devuelto=monto)),
  check ((monto_devuelto>0)=(devolucion_tx_hash is not null))
);

create table public.evidencias (
  id uuid primary key default gen_random_uuid(),
  etapa_id uuid not null references public.etapas(id) on delete restrict,
  intento integer not null check (intento in (1,2)),
  descripcion text not null check (length(btrim(descripcion)) between 10 and 500),
  archivos text[] not null check (cardinality(archivos) between 1 and 5 and array_position(archivos,null) is null),
  hash public.hash_stellar not null,
  estado public.estado_evidencia not null default 'en_revision',
  creado_en timestamptz not null default now(),
  fecha_limite_votacion timestamptz not null default (now()+interval '72 hours'),
  unique(etapa_id,intento),
  check (fecha_limite_votacion=creado_en+interval '72 hours')
);

create table public.votos (
  id uuid primary key default gen_random_uuid(),
  evidencia_id uuid not null references public.evidencias(id) on delete restrict,
  prestamista_id uuid not null default auth.uid() references public.usuarios(id) on delete restrict,
  decision public.decision_voto not null,
  justificacion text check (length(btrim(justificacion)) between 10 and 500),
  creado_en timestamptz not null default now(),
  unique(evidencia_id,prestamista_id),
  check (decision<>'rechaza' or justificacion is not null)
);

create table public.cuotas (
  id uuid primary key default gen_random_uuid(),
  prestamo_id uuid not null references public.prestamos(id) on delete restrict,
  numero integer not null check (numero>0),
  fecha_vencimiento date not null,
  monto public.monto_bob not null check (monto>0),
  comision public.monto_bob not null,
  estado public.estado_cuota not null default 'pendiente',
  dias_atraso integer not null default 0 check (dias_atraso>=0),
  pagada_en timestamptz,
  tx_hash public.hash_stellar unique,
  unique(prestamo_id,numero),
  check (comision<=monto),
  check ((estado='pagada')=(pagada_en is not null and tx_hash is not null)),
  check (estado='pagada' or (pagada_en is null and tx_hash is null))
);

create table public.notificaciones (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete restrict,
  tipo public.tipo_notificacion not null,
  mensaje text not null check (length(mensaje) between 1 and 300),
  prestamo_id uuid references public.prestamos(id) on delete restrict,
  leida boolean not null default false,
  creado_en timestamptz not null default now()
);

create table public.repartos (
  id uuid primary key default gen_random_uuid(),
  cuota_id uuid not null references public.cuotas(id) on delete restrict,
  aporte_id uuid not null references public.aportes(id) on delete restrict,
  monto public.monto_bob not null,
  tx_hash public.hash_stellar not null,
  unique(cuota_id,aporte_id)
);

create table public.eventos_prestamo (
  id uuid primary key default gen_random_uuid(),
  prestamo_id uuid not null references public.prestamos(id) on delete restrict,
  usuario_id uuid references public.usuarios(id) on delete restrict,
  tipo public.tipo_evento_prestamo not null,
  detalle jsonb check (jsonb_typeof(detalle)='object'),
  tx_hash public.hash_stellar,
  creado_en timestamptz not null default now()
);

create table public.eventos_reputacion (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete restrict,
  prestamo_id uuid references public.prestamos(id) on delete restrict,
  motivo public.motivo_reputacion not null,
  variacion numeric(2,1) not null check (variacion between -2 and 1 and mod(variacion,0.5)=0),
  creado_en timestamptz not null default now()
);

create table public.dispositivos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references public.usuarios(id) on delete restrict,
  fcm_token text not null unique check (length(btrim(fcm_token))>0),
  plataforma public.plataforma_dispositivo not null,
  actualizado_en timestamptz not null default now()
);

create table public.parametros (
  clave text primary key,
  valor numeric not null check (valor>=0 and valor<='9999999999.99'::numeric),
  descripcion text,
  actualizado_en timestamptz not null default now(),
  check (case
    when clave in ('tasa_maxima_anual','comision_originacion','comision_servicio','tope_prestamista') then valor<=100
    when clave in ('aporte_minimo','aporte_minimo_inicial','limite_idea_nueva','limite_en_marcha') then valor>0 and valor=round(valor,2)
    when clave='dias_primer_aporte' then valor between 1 and 365 and valor=trunc(valor)
    else false end)
);

-- Índices de relaciones usadas por las políticas y los controles de integridad.
create index negocios_usuario_idx on public.negocios(usuario_id);
create index documentos_negocio_idx on public.documentos(negocio_id);
create index prestamos_negocio_idx on public.prestamos(negocio_id);
create index prestamos_mercado_idx on public.prestamos(estado,publicado_en);
create index aportes_prestamista_idx on public.aportes(prestamista_id);
create index evidencias_etapa_idx on public.evidencias(etapa_id);
create index votos_prestamista_idx on public.votos(prestamista_id);
create index repartos_aporte_idx on public.repartos(aporte_id);
create index notificaciones_usuario_idx on public.notificaciones(usuario_id);
create index notificaciones_prestamo_idx on public.notificaciones(prestamo_id);
create index eventos_prestamo_loan_idx on public.eventos_prestamo(prestamo_id,creado_en);
create index eventos_prestamo_usuario_idx on public.eventos_prestamo(usuario_id);
create index eventos_reputacion_usuario_idx on public.eventos_reputacion(usuario_id);
create index eventos_reputacion_prestamo_idx on public.eventos_reputacion(prestamo_id);
create index dispositivos_usuario_idx on public.dispositivos(usuario_id);

do $$ declare t text; begin
  foreach t in array array['usuarios','negocios','documentos','prestamos','etapas','aportes','evidencias','votos','cuotas','notificaciones','repartos','eventos_prestamo','eventos_reputacion','dispositivos','parametros'] loop
    execute format('alter table public.%I enable row level security',t);
    execute format('revoke all on public.%I from anon, authenticated',t);
    execute format('grant all on public.%I to service_role',t);
  end loop;
end $$;

commit;

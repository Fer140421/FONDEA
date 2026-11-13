begin;

-- Helpers no expuestos por PostgREST; no usan user_metadata para autorizar.
create function private.rol_actual() returns public.rol_usuario language sql stable security definer set search_path='' as $$
  select u.rol from public.usuarios u where u.id=(select auth.uid())
$$;
create function private.es_staff() returns boolean language sql stable security definer set search_path='' as $$
  select coalesce(private.rol_actual() in ('admin','soporte'),false)
$$;
create function private.es_admin() returns boolean language sql stable security definer set search_path='' as $$
  select coalesce(private.rol_actual()='admin',false)
$$;
create function private.es_sistema() returns boolean language sql stable set search_path='' as $$
  select coalesce(current_setting('role',true),'none') in ('none','postgres','service_role')
$$;
create function private.puede_operar() returns boolean language sql stable security definer set search_path='' as $$
  select private.es_sistema() or private.es_admin()
$$;
create function private.es_participante(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
  select (select auth.uid()) is not null and exists (
    select 1 from public.prestamos p where p.id=p_id and
    (p.emprendedor_id=(select auth.uid()) or exists
      (select 1 from public.aportes a where a.prestamo_id=p.id and a.prestamista_id=(select auth.uid())))
  )
$$;
create function private.es_dueno(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.prestamos where id=p_id and emprendedor_id=(select auth.uid()))
$$;
create function private.en_mercado(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
  select (select auth.uid()) is not null and exists(select 1 from public.prestamos where id=p_id and estado='financiandose' and publicado_en is not null)
$$;
create function private.negocio_visible(n_id uuid) returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.negocios n where n.id=n_id and
    (n.usuario_id=(select auth.uid()) or private.es_staff() or exists
      (select 1 from public.prestamos p where p.negocio_id=n_id and private.es_participante(p.id))))
$$;
create function private.negocio_publicado(n_id uuid) returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.prestamos where negocio_id=n_id and publicado_en is not null)
$$;
create function private.negocio_en_mercado(n_id uuid) returns boolean language sql stable security definer set search_path='' as $$
  select (select auth.uid()) is not null and exists(select 1 from public.prestamos where negocio_id=n_id and estado='financiandose' and publicado_en is not null)
$$;
create function private.parametro(p_clave text) returns numeric language plpgsql stable security definer set search_path='' as $$
declare resultado numeric; begin
  select valor into resultado from public.parametros where clave=p_clave;
  if resultado is null then raise exception 'Falta el parámetro %',p_clave using errcode='23514'; end if;
  return resultado;
end $$;
create function private.tiene_deuda(p_id uuid, esperadas integer) returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.etapas where prestamo_id=p_id and liberada_en is not null)
    and (coalesce(esperadas,0)=0 or
      (select count(*) from public.cuotas where prestamo_id=p_id and estado='pagada')<esperadas)
$$;

create function private.proteger_usuario() returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_op='DELETE' then raise exception 'Los perfiles con historial no se eliminan desde la aplicación' using errcode='42501'; end if;
  if tg_op='UPDATE' and new.id<>old.id then raise exception 'Identidad inmutable' using errcode='23514'; end if;
  if not private.puede_operar() then
    if tg_op='INSERT' then
      if new.id is distinct from (select auth.uid()) or new.rol not in ('emprendedor','prestamista')
        or new.estado_verificacion<>'pendiente' or new.estrellas<>3 or not new.es_nuevo
        or new.limite_monto<>10000 or new.verificado_en is not null or new.primer_aporte_hasta is not null
        or new.creado_en is distinct from now() then
        raise exception 'Campos de perfil reservados a Fondea' using errcode='42501';
      end if;
      if lower(new.correo) is distinct from (select lower(email) from auth.users where id=new.id) then
        raise exception 'El correo debe coincidir con Auth' using errcode='23514';
      end if;
    elsif (to_jsonb(new)-array['nombre','celular','contacto_emergencia_nombre','contacto_emergencia_celular','carnet_anverso_url','carnet_reverso_url','billetera'])
       is distinct from (to_jsonb(old)-array['nombre','celular','contacto_emergencia_nombre','contacto_emergencia_celular','carnet_anverso_url','carnet_reverso_url','billetera']) then
      raise exception 'Solo se pueden modificar los datos personales autorizados' using errcode='42501';
    end if;
    if tg_op='UPDATE' and (new.carnet_anverso_url is distinct from old.carnet_anverso_url or new.carnet_reverso_url is distinct from old.carnet_reverso_url) then
      new.estado_verificacion:='pendiente';
    end if;
  end if;
  if new.carnet_anverso_url is not null and (new.carnet_anverso_url not like new.id::text||'/%' or new.carnet_anverso_url like '%..%') then raise exception 'Ruta de identidad inválida' using errcode='23514'; end if;
  if new.carnet_reverso_url is not null and (new.carnet_reverso_url not like new.id::text||'/%' or new.carnet_reverso_url like '%..%') then raise exception 'Ruta de identidad inválida' using errcode='23514'; end if;
  if tg_op='UPDATE' and old.verificado_en is not null then
    new.verificado_en:=old.verificado_en;
    new.primer_aporte_hasta:=old.primer_aporte_hasta;
  elsif new.estado_verificacion='verificado' then
    new.verificado_en:=coalesce(new.verificado_en,now());
    new.primer_aporte_hasta:=new.verificado_en+make_interval(days=>private.parametro('dias_primer_aporte')::int);
  end if;
  return new;
end $$;
create trigger usuarios_protegidos before insert or update or delete on public.usuarios for each row execute function private.proteger_usuario();

create function private.proteger_negocio() returns trigger language plpgsql security definer set search_path='' as $$
declare n public.negocios; begin
  if tg_op='DELETE' then n:=old; else n:=new; end if;
  if not exists(select 1 from public.usuarios where id=n.usuario_id and rol='emprendedor' and estado_verificacion='verificado') then
    raise exception 'El negocio requiere un emprendedor verificado' using errcode='23514';
  end if;
  if tg_op='UPDATE' and (new.id,new.usuario_id,new.creado_en) is distinct from (old.id,old.usuario_id,old.creado_en) then raise exception 'Propiedad del negocio inmutable' using errcode='23514'; end if;
  if tg_op<>'INSERT' and exists(select 1 from public.prestamos where negocio_id=n.id and publicado_en is not null and bloquea_nueva_solicitud) then
    raise exception 'No se modifica un negocio con un préstamo publicado abierto' using errcode='23514';
  end if;
  if tg_op='DELETE' then return old; end if;
  return new;
end $$;
create trigger negocios_protegidos before insert or update or delete on public.negocios for each row execute function private.proteger_negocio();

create function private.proteger_documento() returns trigger language plpgsql security definer set search_path='' as $$
declare n public.negocios; begin
  if tg_op<>'INSERT' and private.negocio_publicado(old.negocio_id) then raise exception 'Documento vinculado a un préstamo publicado: conservar historial' using errcode='23514'; end if;
  if tg_op='DELETE' then return old; end if;
  select * into strict n from public.negocios where id=new.negocio_id;
  if new.url not like n.usuario_id::text||'/'||n.id::text||'/%' or new.url like '%..%' then raise exception 'Ruta de documento inválida' using errcode='23514'; end if;
  if tg_op='UPDATE' and (new.id,new.negocio_id,new.creado_en) is distinct from (old.id,old.negocio_id,old.creado_en) then raise exception 'Propiedad del documento inmutable' using errcode='23514'; end if;
  return new;
end $$;
create trigger documentos_protegidos before insert or update or delete on public.documentos for each row execute function private.proteger_documento();

create function private.proteger_prestamo() returns trigger language plpgsql security definer set search_path='' as $$
declare n public.negocios; u public.usuarios; limite numeric; begin
  if tg_op='DELETE' then
    if old.estado<>'borrador' or old.publicado_en is not null then raise exception 'Solo se eliminan borradores' using errcode='42501'; end if;
    return old;
  end if;
  select * into strict n from public.negocios where id=new.negocio_id;
  select * into strict u from public.usuarios where id=n.usuario_id for update;
  if (tg_op='INSERT' or old.publicado_en is null) and (u.rol<>'emprendedor' or u.estado_verificacion<>'verificado') then raise exception 'Se requiere emprendedor verificado' using errcode='23514'; end if;
  new.emprendedor_id:=n.usuario_id;
  if tg_op='UPDATE' and (new.id,new.negocio_id,new.creado_en) is distinct from (old.id,old.negocio_id,old.creado_en) then raise exception 'Propiedad del préstamo inmutable' using errcode='23514'; end if;
  if not private.puede_operar() then
    if tg_op='INSERT' then
      if new.estado<>'borrador' or new.monto_recaudado<>0 or new.publicado_en is not null or new.financiado_en is not null
        or new.primer_desembolso_en is not null or new.escrow_id is not null or new.ampliado
        or new.motivo_rechazo is not null or new.fecha_limite_financiamiento is not null
        or new.comision_originacion_pactada is not null or new.comision_servicio_pactada is not null
        or new.aporte_minimo_pactado is not null or new.aporte_inicial_pactado is not null
        or new.tope_prestamista_pactado is not null or new.limite_monto_pactado is not null or new.tasa_maxima_pactada is not null or new.tipo_negocio_pactado is not null
        or new.creado_en is distinct from now() then raise exception 'Campos del préstamo reservados' using errcode='42501'; end if;
    elsif old.estado not in ('borrador','rechazado') or new.estado not in ('borrador','en_revision') or old.publicado_en is not null
      or (to_jsonb(new)-array['justificacion','monto','plazo_meses','tasa_anual','meses_hasta_primera_cuota','max_prestamistas','estado','cantidad_cuotas','monto_cuota','total_devolver'])
         is distinct from (to_jsonb(old)-array['justificacion','monto','plazo_meses','tasa_anual','meses_hasta_primera_cuota','max_prestamistas','estado','cantidad_cuotas','monto_cuota','total_devolver']) then
      raise exception 'Solo se editan condiciones de borradores o solicitudes rechazadas' using errcode='42501';
    end if;
  end if;
  if tg_op='UPDATE' and old.publicado_en is not null then
    if new.estado in ('borrador','en_revision','rechazado') then raise exception 'Un préstamo publicado no vuelve a estados privados de preparación' using errcode='23514'; end if;
    if old.estado<>'financiandose' and new.estado='financiandose' then raise exception 'Un préstamo ya retirado del mercado no se republica' using errcode='23514'; end if;
    if old.estado='pagado' and new.estado<>'pagado' then raise exception 'El estado pagado es definitivo' using errcode='23514'; end if;
    if old.estado='cancelado' and new.estado not in ('cancelado','pagado') then raise exception 'Una cancelación no se reactiva' using errcode='23514'; end if;
    if (new.comision_originacion_pactada,new.comision_servicio_pactada,new.aporte_minimo_pactado,new.aporte_inicial_pactado,new.tope_prestamista_pactado,new.limite_monto_pactado,new.tasa_maxima_pactada,new.tipo_negocio_pactado,new.publicado_en)
      is distinct from (old.comision_originacion_pactada,old.comision_servicio_pactada,old.aporte_minimo_pactado,old.aporte_inicial_pactado,old.tope_prestamista_pactado,old.limite_monto_pactado,old.tasa_maxima_pactada,old.tipo_negocio_pactado,old.publicado_en) then
      raise exception 'Las condiciones pactadas son inmutables' using errcode='23514';
    end if;
    if (new.plazo_meses,new.tasa_anual,new.meses_hasta_primera_cuota) is distinct from (old.plazo_meses,old.tasa_anual,old.meses_hasta_primera_cuota) then raise exception 'Plazo y tasa publicados son inmutables' using errcode='23514'; end if;
    if new.monto is distinct from old.monto and not (old.estado='financiandose' and new.estado='financiado' and new.monto=old.monto_recaudado) then raise exception 'El monto publicado solo cambia mediante cierre parcial' using errcode='23514'; end if;
  end if;
  if new.estado='financiandose' and (tg_op='INSERT' or old.publicado_en is null) then
    new.tipo_negocio_pactado:=n.tipo;
    new.comision_originacion_pactada:=private.parametro('comision_originacion');
    new.comision_servicio_pactada:=private.parametro('comision_servicio');
    new.aporte_minimo_pactado:=private.parametro('aporte_minimo');
    new.aporte_inicial_pactado:=private.parametro('aporte_minimo_inicial');
    new.tope_prestamista_pactado:=private.parametro('tope_prestamista');
    new.tasa_maxima_pactada:=private.parametro('tasa_maxima_anual');
    new.limite_monto_pactado:=least(u.limite_monto,private.parametro(case n.tipo when 'idea_nueva' then 'limite_idea_nueva' else 'limite_en_marcha' end));
    new.publicado_en:=coalesce(new.publicado_en,now());
  end if;
  if tg_op='UPDATE' and old.primer_desembolso_en is not null and new.primer_desembolso_en is distinct from old.primer_desembolso_en then raise exception 'Inicio del plazo inmutable' using errcode='23514'; end if;
  if tg_op='UPDATE' and old.financiado_en is not null and new.financiado_en is distinct from old.financiado_en then raise exception 'Financiación confirmada inmutable' using errcode='23514'; end if;
  if new.estado='financiado' then new.financiado_en:=coalesce(new.financiado_en,now()); end if;
  new.monto_recaudado:=(select coalesce(sum(monto-monto_devuelto),0) from public.aportes where prestamo_id=new.id);
  limite:=coalesce(new.limite_monto_pactado,least(u.limite_monto,private.parametro(case n.tipo when 'idea_nueva' then 'limite_idea_nueva' else 'limite_en_marcha' end)));
  if new.monto>limite or new.tasa_anual>coalesce(new.tasa_maxima_pactada,private.parametro('tasa_maxima_anual')) then raise exception 'Monto o tasa fuera de límites' using errcode='23514'; end if;
  if new.publicado_en is not null then
    new.fecha_limite_financiamiento:=new.publicado_en+case when new.ampliado then interval '15 days' else interval '8 days' end;
  end if;
  if tg_op='UPDATE' and old.ampliado and not new.ampliado then raise exception 'La ampliación solo se usa una vez' using errcode='23514'; end if;
  if new.estado in ('financiado','en_etapas','en_pago','en_mora','pausado','pagado') and new.publicado_en is null then raise exception 'El préstamo debe haberse publicado' using errcode='23514'; end if;
  new.bloquea_nueva_solicitud:=case when new.estado='cancelado' then private.tiene_deuda(new.id,new.plazo_meses-new.meses_hasta_primera_cuota+1) when new.estado in ('rechazado','pagado') then false else true end;
  if new.estado='pagado' and private.tiene_deuda(new.id,new.plazo_meses-new.meses_hasta_primera_cuota+1) then raise exception 'El préstamo conserva deuda' using errcode='23514'; end if;
  return new;
end $$;
create trigger prestamos_protegidos before insert or update or delete on public.prestamos for each row execute function private.proteger_prestamo();

create function private.actualizar_participaciones() returns trigger language plpgsql security definer set search_path='' as $$
begin
  if new.monto is distinct from old.monto then
    update public.aportes set porcentaje=round(monto/new.monto*100,2) where prestamo_id=new.id;
  end if;
  return null;
end $$;
create trigger prestamos_participaciones after update of monto on public.prestamos for each row execute function private.actualizar_participaciones();

-- Las sumas se comprueban al terminar la transacción: permite editar todas las etapas
-- y el monto de un cierre parcial de forma atómica.
create function private.validar_plan(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare p public.prestamos; tipo public.tipo_negocio; cantidad int; total numeric; minimo numeric; primera numeric; mayor int; begin
  select * into p from public.prestamos where id=p_id;
  if not found or p.estado in ('borrador','rechazado') then return; end if;
  select coalesce(p.tipo_negocio_pactado,n.tipo) into tipo from public.negocios n where n.id=p.negocio_id;
  select count(*),coalesce(sum(monto),0),min(monto),max(monto) filter(where numero=1),max(numero)
    into cantidad,total,minimo,primera,mayor from public.etapas where prestamo_id=p.id;
  if cantidad<2 or cantidad>(case when p.plazo_meses<=6 then 2 else 3 end)
    or (tipo='idea_nueva' and cantidad<>(case when p.plazo_meses<=6 then 2 else 3 end))
    or mayor<>cantidad or total<>p.monto or minimo<p.monto*0.20 or primera>p.monto*0.30 then
    raise exception 'Plan de etapas inválido' using errcode='23514';
  end if;
  if p.estado in ('financiado','en_etapas','en_pago','en_mora','pausado','pagado') then
    if (select count(*) from public.aportes where prestamo_id=p.id)<2
      or (select sum(monto) from public.aportes where prestamo_id=p.id) is distinct from p.monto
      or exists(select 1 from public.aportes where prestamo_id=p.id and monto>p.monto*p.tope_prestamista_pactado/100) then
      raise exception 'La financiación final requiere al menos dos prestamistas y respeta el tope pactado' using errcode='23514';
    end if;
  end if;
end $$;
create function private.comprobar_plan() returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_table_name='prestamos' then perform private.validar_plan(coalesce(new.id,old.id));
  else perform private.validar_plan(coalesce(new.prestamo_id,old.prestamo_id)); end if;
  return null;
end $$;
create constraint trigger prestamos_plan after insert or update on public.prestamos deferrable initially deferred for each row execute function private.comprobar_plan();
create constraint trigger etapas_plan after insert or update or delete on public.etapas deferrable initially deferred for each row execute function private.comprobar_plan();

create function private.proteger_etapa() returns trigger language plpgsql security definer set search_path='' as $$
declare p public.prestamos; begin
  select * into p from public.prestamos where id=coalesce(new.prestamo_id,old.prestamo_id) for update;
  if not found and tg_op='DELETE' then return old; end if;
  if not private.puede_operar() then
    if p.estado<>'borrador' or not private.es_dueno(p.id) then raise exception 'Solo se configuran etapas propias en borrador' using errcode='42501'; end if;
    if tg_op='INSERT' and (new.estado<>'pendiente' or new.liberada_en is not null or new.tx_hash is not null or new.comision_descontada<>0 or new.fecha_limite_evidencia is not null) then raise exception 'Desembolso reservado' using errcode='42501'; end if;
    if tg_op='UPDATE' and (to_jsonb(new)-array['numero','objetivo','monto','evidencia_requerida']) is distinct from (to_jsonb(old)-array['numero','objetivo','monto','evidencia_requerida']) then raise exception 'Campos de etapa reservados' using errcode='42501'; end if;
  end if;
  if tg_op='DELETE' then
    if p.estado<>'borrador' or p.publicado_en is not null or old.liberada_en is not null then raise exception 'Conservar etapas del historial' using errcode='42501'; end if;
    return old;
  end if;
  if tg_op='UPDATE' and (new.id,new.prestamo_id) is distinct from (old.id,old.prestamo_id) then raise exception 'Etapa inmutable' using errcode='23514'; end if;
  if tg_op='UPDATE' and old.liberada_en is not null and (new.monto,new.liberada_en,new.tx_hash,new.comision_descontada) is distinct from (old.monto,old.liberada_en,old.tx_hash,old.comision_descontada) then raise exception 'Desembolso confirmado inmutable' using errcode='23514'; end if;
  if new.liberada_en is not null and p.estado not in ('financiado','en_etapas','en_pago','en_mora','pausado','cancelado','pagado') then raise exception 'Préstamo sin financiar' using errcode='23514'; end if;
  if new.liberada_en is not null then new.fecha_limite_evidencia:=coalesce(new.fecha_limite_evidencia,new.liberada_en+interval '15 days'); end if;
  if new.liberada_en is not null and new.numero=(select max(numero) from public.etapas where prestamo_id=p.id) then
    if new.comision_descontada<>0 and new.comision_descontada<>round(p.monto*p.comision_originacion_pactada/100,2) then raise exception 'Comisión incorrecta' using errcode='23514'; end if;
    new.comision_descontada:=round(p.monto*p.comision_originacion_pactada/100,2);
  end if;
  if new.comision_descontada<>0 and (new.liberada_en is null or new.numero<>(select max(numero) from public.etapas where prestamo_id=p.id) or new.comision_descontada<>round(p.monto*p.comision_originacion_pactada/100,2)) then raise exception 'Comisión de originación inválida' using errcode='23514'; end if;
  return new;
end $$;
create trigger etapas_protegidas before insert or update or delete on public.etapas for each row execute function private.proteger_etapa();

create function private.proteger_aporte() returns trigger language plpgsql security definer set search_path='' as $$
declare p public.prestamos; u public.usuarios; minimo numeric; begin
  if not private.puede_operar() then raise exception 'Los aportes requieren una operación de dinero verificada' using errcode='42501'; end if;
  if tg_op='DELETE' then raise exception 'Los aportes se conservan' using errcode='42501'; end if;
  select * into strict p from public.prestamos where id=new.prestamo_id for update;
  select * into strict u from public.usuarios where id=new.prestamista_id for update;
  if tg_op='UPDATE' then
    if (new.id,new.prestamo_id,new.prestamista_id,new.monto,new.tx_hash,new.creado_en) is distinct from (old.id,old.prestamo_id,old.prestamista_id,old.monto,old.tx_hash,old.creado_en) then raise exception 'Aporte confirmado inmutable' using errcode='23514'; end if;
    if new.monto_devuelto<old.monto_devuelto then raise exception 'La devolución no se revierte sobrescribiendo el historial' using errcode='23514'; end if;
    if new.monto_devuelto>old.monto_devuelto and p.estado not in ('cancelado','en_mora') then raise exception 'Devolución solo por cancelación o mora' using errcode='23514'; end if;
  else
    if p.estado<>'financiandose' or p.fecha_limite_financiamiento<now() or u.rol<>'prestamista' or u.estado_verificacion<>'verificado' or u.id=p.emprendedor_id then raise exception 'Aporte no permitido' using errcode='23514'; end if;
    if (select count(*) from public.aportes where prestamo_id=p.id)>=p.max_prestamistas then raise exception 'Máximo de prestamistas alcanzado' using errcode='23514'; end if;
    minimo:=p.aporte_minimo_pactado;
    if u.primer_aporte_hasta>=now() and not exists(select 1 from public.aportes where prestamista_id=u.id) then minimo:=p.aporte_inicial_pactado; end if;
    if new.monto<minimo or new.monto>p.monto*p.tope_prestamista_pactado/100 or new.monto>p.monto-p.monto_recaudado or new.monto_devuelto<>0 then raise exception 'Monto del aporte fuera de límites' using errcode='23514'; end if;
  end if;
  new.porcentaje:=round(new.monto/p.monto*100,2);
  return new;
end $$;
create trigger aportes_protegidos before insert or update or delete on public.aportes for each row execute function private.proteger_aporte();

create function private.actualizar_financiacion() returns trigger language plpgsql security definer set search_path='' as $$
begin
  update public.prestamos set monto_recaudado=(select coalesce(sum(monto-monto_devuelto),0) from public.aportes where prestamo_id=new.prestamo_id) where id=new.prestamo_id;
  return null;
end $$;
create trigger aportes_saldo after insert or update of monto_devuelto on public.aportes for each row execute function private.actualizar_financiacion();

create function private.proteger_evidencia() returns trigger language plpgsql security definer set search_path='' as $$
declare e public.etapas; p public.prestamos; ruta text; begin
  if tg_op='DELETE' then raise exception 'Las evidencias se conservan' using errcode='42501'; end if;
  select * into strict e from public.etapas where id=new.etapa_id;
  select * into strict p from public.prestamos where id=e.prestamo_id for update;
  if tg_op='UPDATE' then
    if not private.puede_operar() or (to_jsonb(new)-'estado') is distinct from (to_jsonb(old)-'estado') then raise exception 'Solo Fondea registra el resultado de la revisión' using errcode='42501'; end if;
  else
    if e.liberada_en is null or p.estado not in ('en_etapas','en_pago','pausado') or e.fecha_limite_evidencia<now() then raise exception 'Etapa fuera de plazo para evidencia' using errcode='23514'; end if;
    if new.estado<>'en_revision' or new.creado_en is distinct from now() then raise exception 'Estado y fecha de evidencia reservados' using errcode='42501'; end if;
    if new.intento=2 and not exists(select 1 from public.evidencias where etapa_id=e.id and intento=1 and estado='rechazada') then raise exception 'La corrección exige un primer rechazo' using errcode='23514'; end if;
  end if;
  foreach ruta in array new.archivos loop
    if ruta not like p.emprendedor_id::text||'/'||e.id::text||'/%' or ruta like '%..%' then raise exception 'Ruta de evidencia inválida' using errcode='23514'; end if;
  end loop;
  return new;
end $$;
create trigger evidencias_protegidas before insert or update or delete on public.evidencias for each row execute function private.proteger_evidencia();

create function private.proteger_voto() returns trigger language plpgsql security definer set search_path='' as $$
declare e public.evidencias; p_id uuid; begin
  if tg_op<>'INSERT' then raise exception 'Los votos son inmutables' using errcode='42501'; end if;
  select * into strict e from public.evidencias where id=new.evidencia_id for update;
  select prestamo_id into p_id from public.etapas where id=e.etapa_id;
  if e.estado<>'en_revision' or now()>e.fecha_limite_votacion or not exists(select 1 from public.aportes where prestamo_id=p_id and prestamista_id=new.prestamista_id and estado='activo' and monto>monto_devuelto) then raise exception 'Votante no habilitado o votación cerrada' using errcode='23514'; end if;
  if not private.puede_operar() and (new.prestamista_id is distinct from (select auth.uid()) or new.creado_en is distinct from now()) then raise exception 'Identidad del voto inválida' using errcode='42501'; end if;
  return new;
end $$;
create trigger votos_protegidos before insert or update or delete on public.votos for each row execute function private.proteger_voto();

create function private.proteger_cuota() returns trigger language plpgsql security definer set search_path='' as $$
declare p public.prestamos; esperada numeric; begin
  if not private.puede_operar() then raise exception 'Las cuotas solo cambian mediante operaciones verificadas' using errcode='42501'; end if;
  if tg_op='DELETE' then raise exception 'Las cuotas se conservan' using errcode='42501'; end if;
  select * into strict p from public.prestamos where id=new.prestamo_id for update;
  if new.numero>p.cantidad_cuotas or p.primer_desembolso_en is null then raise exception 'Cuota sin desembolso o número inválido' using errcode='23514'; end if;
  if tg_op='UPDATE' and old.estado='pagada' and new is distinct from old then raise exception 'Pago confirmado inmutable' using errcode='23514'; end if;
  if tg_op='UPDATE' and (new.id,new.prestamo_id,new.numero) is distinct from (old.id,old.prestamo_id,old.numero) then raise exception 'Propiedad de cuota inmutable' using errcode='23514'; end if;
  esperada:=case when new.numero=p.cantidad_cuotas then p.total_devolver-(p.cantidad_cuotas-1)*p.monto_cuota else p.monto_cuota end;
  if (p.estado<>'cancelado' and new.monto<>esperada) or new.comision<>round(new.monto*p.comision_servicio_pactada/100,2) then raise exception 'Monto o comisión de cuota inválidos' using errcode='23514'; end if;
  if new.fecha_vencimiento<>(((p.primer_desembolso_en at time zone 'America/La_Paz')::date)+make_interval(months=>p.meses_hasta_primera_cuota+new.numero-1))::date then raise exception 'Vencimiento distinto del calendario pactado' using errcode='23514'; end if;
  return new;
end $$;
create trigger cuotas_protegidas before insert or update or delete on public.cuotas for each row execute function private.proteger_cuota();

create function private.refrescar_deuda() returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_table_name='etapas' then
    if new.numero=1 and new.liberada_en is not null then
      update public.prestamos set primer_desembolso_en=coalesce(primer_desembolso_en,new.liberada_en) where id=new.prestamo_id;
    end if;
  end if;
  update public.prestamos set bloquea_nueva_solicitud=bloquea_nueva_solicitud where id=new.prestamo_id;
  return null;
end $$;
create trigger cuotas_deuda after insert or update on public.cuotas for each row execute function private.refrescar_deuda();
create trigger etapas_deuda after insert or update on public.etapas for each row execute function private.refrescar_deuda();

create function private.proteger_reparto() returns trigger language plpgsql security definer set search_path='' as $$
declare c public.cuotas; a public.aportes; esperado numeric; begin
  if not private.puede_operar() or tg_op<>'INSERT' then raise exception 'Repartos confirmados de solo inserción por Fondea' using errcode='42501'; end if;
  select * into strict c from public.cuotas where id=new.cuota_id for update;
  select * into strict a from public.aportes where id=new.aporte_id;
  if a.prestamo_id<>c.prestamo_id or c.estado<>'pagada' or new.tx_hash<>c.tx_hash then raise exception 'Reparto de otro préstamo o pago sin confirmar' using errcode='23514'; end if;
  if a.estado<>'activo' or a.monto<=a.monto_devuelto then raise exception 'Aporte sin capital para repartir' using errcode='23514'; end if;
  -- Mayores restos: unidades enteras de centavo, sin utilizar porcentajes redondeados.
  with capital as (
    select id,prestamista_id,monto-monto_devuelto as vigente from public.aportes
    where prestamo_id=c.prestamo_id and estado='activo' and monto>monto_devuelto
  ), exactos as (
    select id,prestamista_id,(c.monto-c.comision)*100*vigente/sum(vigente) over() as centavos from capital
  ), ordenados as (
    select id,floor(centavos) as base,
      row_number() over(order by centavos-floor(centavos) desc,prestamista_id) as orden,
      (c.monto-c.comision)*100-sum(floor(centavos)) over() as restantes from exactos
  ) select (base+case when orden<=restantes then 1 else 0 end)/100 into esperado from ordenados where id=a.id;
  if esperado is null or new.monto<>esperado then raise exception 'Reparto no proporcional al capital vigente' using errcode='23514'; end if;
  return new;
end $$;
create trigger repartos_protegidos before insert or update or delete on public.repartos for each row execute function private.proteger_reparto();
create function private.validar_repartos() returns trigger language plpgsql security definer set search_path='' as $$
declare c public.cuotas; q uuid; total numeric; begin
  if tg_table_name='cuotas' then q:=new.id; else q:=new.cuota_id; end if;
  select * into c from public.cuotas where id=q;
  if c.estado='pagada' then
    select coalesce(sum(monto),0) into total from public.repartos where cuota_id=q;
    if total<>c.monto-c.comision then raise exception 'El reparto debe conservar el importe neto de la cuota' using errcode='23514'; end if;
  end if;
  return null;
end $$;
create constraint trigger cuotas_reparto after insert or update on public.cuotas deferrable initially deferred for each row execute function private.validar_repartos();
create constraint trigger repartos_total after insert on public.repartos deferrable initially deferred for each row execute function private.validar_repartos();

create function private.proteger_evento() returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_op<>'INSERT' then raise exception 'El historial es inmutable' using errcode='42501'; end if;
  if tg_table_name='eventos_reputacion' then
    if not private.puede_operar() then raise exception 'Reputación reservada a Fondea' using errcode='42501'; end if;
  elsif not private.puede_operar() and not (private.rol_actual()='soporte' and new.tipo='intervencion_soporte' and new.usuario_id=(select auth.uid()) and new.tx_hash is null and new.creado_en=now()) then
    raise exception 'Evento reservado a Fondea' using errcode='42501';
  end if;
  return new;
end $$;
create trigger eventos_prestamo_protegidos before insert or update or delete on public.eventos_prestamo for each row execute function private.proteger_evento();
create trigger eventos_reputacion_protegidos before insert or update or delete on public.eventos_reputacion for each row execute function private.proteger_evento();

create function private.proteger_aviso() returns trigger language plpgsql security definer set search_path='' as $$
begin
  if not private.puede_operar() and (tg_op<>'UPDATE' or (to_jsonb(new)-'leida') is distinct from (to_jsonb(old)-'leida')) then raise exception 'Solo se puede marcar un aviso como leído' using errcode='42501'; end if;
  return new;
end $$;
create trigger avisos_protegidos before insert or update on public.notificaciones for each row execute function private.proteger_aviso();
create function private.proteger_dispositivo() returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_op='UPDATE' and (new.id,new.usuario_id) is distinct from (old.id,old.usuario_id) then raise exception 'Propiedad del dispositivo inmutable' using errcode='23514'; end if;
  new.actualizado_en:=now(); return new;
end $$;
create trigger dispositivos_protegidos before insert or update on public.dispositivos for each row execute function private.proteger_dispositivo();
create function private.proteger_parametro() returns trigger language plpgsql security definer set search_path='' as $$
begin
  if not private.puede_operar() or tg_op='DELETE' then raise exception 'Parámetro reservado a administración' using errcode='42501'; end if;
  if tg_op='UPDATE' and new.clave<>old.clave then raise exception 'Clave de parámetro inmutable' using errcode='23514'; end if;
  new.actualizado_en:=now(); return new;
end $$;
create trigger parametros_protegidos before insert or update or delete on public.parametros for each row execute function private.proteger_parametro();

-- Grants deliberados. Las guardas de columnas se ejecutan incluso para admin y service_role.
grant select,insert,update on public.usuarios to authenticated;
grant select,insert,update,delete on public.negocios,public.documentos,public.prestamos,public.etapas,public.dispositivos to authenticated;
grant select on public.aportes,public.cuotas,public.repartos,public.eventos_reputacion to authenticated;
grant select,insert,update on public.evidencias to authenticated;
grant select,insert on public.votos,public.eventos_prestamo to authenticated;
grant select,update on public.notificaciones,public.parametros to authenticated;
-- Administración autenticada usa las mismas restricciones de integridad, pero puede registrar operaciones verificadas.
grant insert,update on public.aportes,public.cuotas to authenticated;
grant insert on public.repartos,public.eventos_reputacion,public.notificaciones to authenticated;

create policy usuarios_lectura on public.usuarios for select to authenticated using (id=(select auth.uid()) or private.es_staff());
create policy usuarios_alta on public.usuarios for insert to authenticated with check (id=(select auth.uid()) or private.es_admin());
create policy usuarios_edicion on public.usuarios for update to authenticated using (id=(select auth.uid()) or private.es_admin()) with check (id=(select auth.uid()) or private.es_admin());
create policy negocios_lectura on public.negocios for select to authenticated using (private.negocio_visible(id));
create policy negocios_alta on public.negocios for insert to authenticated with check (usuario_id=(select auth.uid()) or private.es_admin());
create policy negocios_edicion on public.negocios for update to authenticated using (usuario_id=(select auth.uid()) or private.es_admin()) with check (usuario_id=(select auth.uid()) or private.es_admin());
create policy negocios_borrado on public.negocios for delete to authenticated using (usuario_id=(select auth.uid()) or private.es_admin());
create policy documentos_lectura on public.documentos for select to authenticated using (private.es_staff() or exists(select 1 from public.negocios where id=negocio_id and usuario_id=(select auth.uid())) or (tipo='foto_negocio' and private.negocio_en_mercado(negocio_id)));
create policy documentos_alta on public.documentos for insert to authenticated with check (private.es_admin() or exists(select 1 from public.negocios where id=negocio_id and usuario_id=(select auth.uid())));
create policy documentos_edicion on public.documentos for update to authenticated using (private.es_admin() or exists(select 1 from public.negocios where id=negocio_id and usuario_id=(select auth.uid()))) with check (private.es_admin() or exists(select 1 from public.negocios where id=negocio_id and usuario_id=(select auth.uid())));
create policy documentos_borrado on public.documentos for delete to authenticated using (private.es_admin() or exists(select 1 from public.negocios where id=negocio_id and usuario_id=(select auth.uid())));
create policy prestamos_lectura on public.prestamos for select to authenticated using (private.es_staff() or private.es_participante(id));
create policy prestamos_alta on public.prestamos for insert to authenticated with check (emprendedor_id=(select auth.uid()) or private.es_admin());
create policy prestamos_edicion on public.prestamos for update to authenticated using (emprendedor_id=(select auth.uid()) or private.es_admin()) with check (emprendedor_id=(select auth.uid()) or private.es_admin());
create policy prestamos_borrado on public.prestamos for delete to authenticated using (estado='borrador' and (emprendedor_id=(select auth.uid()) or private.es_admin()));
create policy etapas_lectura on public.etapas for select to authenticated using (private.es_staff() or private.es_participante(prestamo_id));
create policy etapas_alta on public.etapas for insert to authenticated with check (private.es_admin() or private.es_dueno(prestamo_id));
create policy etapas_edicion on public.etapas for update to authenticated using (private.es_admin() or private.es_dueno(prestamo_id)) with check (private.es_admin() or private.es_dueno(prestamo_id));
create policy etapas_borrado on public.etapas for delete to authenticated using (private.es_admin() or private.es_dueno(prestamo_id));
create policy aportes_lectura on public.aportes for select to authenticated using (prestamista_id=(select auth.uid()) or private.es_dueno(prestamo_id) or private.es_staff());
create policy aportes_alta on public.aportes for insert to authenticated with check (private.es_admin());
create policy aportes_edicion on public.aportes for update to authenticated using (private.es_admin()) with check (private.es_admin());
create policy evidencias_lectura on public.evidencias for select to authenticated using (private.es_staff() or exists(select 1 from public.etapas where id=etapa_id and private.es_participante(prestamo_id)));
create policy evidencias_alta on public.evidencias for insert to authenticated with check (private.es_admin() or exists(select 1 from public.etapas where id=etapa_id and private.es_dueno(prestamo_id)));
create policy evidencias_edicion on public.evidencias for update to authenticated using (private.es_admin()) with check (private.es_admin());
create policy votos_lectura on public.votos for select to authenticated using (prestamista_id=(select auth.uid()) or private.es_staff() or exists(select 1 from public.evidencias e join public.etapas t on t.id=e.etapa_id where e.id=evidencia_id and private.es_dueno(t.prestamo_id)));
create policy votos_alta on public.votos for insert to authenticated with check (prestamista_id=(select auth.uid()) or private.es_admin());
create policy cuotas_lectura on public.cuotas for select to authenticated using (private.es_staff() or private.es_participante(prestamo_id));
create policy cuotas_alta on public.cuotas for insert to authenticated with check (private.es_admin());
create policy cuotas_edicion on public.cuotas for update to authenticated using (private.es_admin()) with check (private.es_admin());
create policy repartos_lectura on public.repartos for select to authenticated using (private.es_staff() or exists(select 1 from public.aportes where id=aporte_id and prestamista_id=(select auth.uid())));
create policy repartos_alta on public.repartos for insert to authenticated with check (private.es_admin());
create policy avisos_lectura on public.notificaciones for select to authenticated using (usuario_id=(select auth.uid()));
create policy avisos_alta on public.notificaciones for insert to authenticated with check (private.es_admin());
create policy avisos_edicion on public.notificaciones for update to authenticated using (usuario_id=(select auth.uid())) with check (usuario_id=(select auth.uid()));
create policy eventos_lectura on public.eventos_prestamo for select to authenticated using (private.es_staff());
create policy eventos_alta on public.eventos_prestamo for insert to authenticated with check (private.es_admin() or (private.rol_actual()='soporte' and usuario_id=(select auth.uid()) and tipo='intervencion_soporte'));
create policy reputacion_lectura on public.eventos_reputacion for select to authenticated using (usuario_id=(select auth.uid()) or private.es_staff());
create policy reputacion_alta on public.eventos_reputacion for insert to authenticated with check (private.es_admin());
create policy dispositivos_lectura on public.dispositivos for select to authenticated using (usuario_id=(select auth.uid()));
create policy dispositivos_alta on public.dispositivos for insert to authenticated with check (usuario_id=(select auth.uid()));
create policy dispositivos_edicion on public.dispositivos for update to authenticated using (usuario_id=(select auth.uid())) with check (usuario_id=(select auth.uid()));
create policy dispositivos_borrado on public.dispositivos for delete to authenticated using (usuario_id=(select auth.uid()));
create policy parametros_lectura on public.parametros for select to authenticated using (true);
create policy parametros_edicion on public.parametros for update to authenticated using (private.es_admin()) with check (private.es_admin());

-- Proyecciones con privilegios del propietario y filtros explícitos. A diferencia
-- de SELECT * sobre las tablas, solo exponen columnas aprobadas; anon no tiene grants.
create view public.mercado_prestamos with (security_barrier=true) as
 select p.id,p.negocio_id,p.justificacion,p.monto,p.plazo_meses,p.tasa_anual,p.meses_hasta_primera_cuota,p.cantidad_cuotas,p.monto_cuota,p.total_devolver,p.max_prestamistas,p.monto_recaudado,p.publicado_en,p.fecha_limite_financiamiento,
   n.nombre as negocio_nombre,n.categoria,n.tipo,n.descripcion,u.id as emprendedor_id,u.nombre as emprendedor_nombre,u.estrellas,u.estado_verificacion,(p.publicado_en is not null) as documentacion_revisada
 from public.prestamos p join public.negocios n on n.id=p.negocio_id join public.usuarios u on u.id=p.emprendedor_id
 where (select auth.uid()) is not null and p.estado='financiandose' and p.publicado_en is not null;
create view public.mercado_etapas with (security_barrier=true) as
 select e.id,e.prestamo_id,e.numero,e.objetivo,e.monto,e.evidencia_requerida
 from public.etapas e where private.en_mercado(e.prestamo_id);
create view public.perfiles_publicos with (security_barrier=true) as
 select u.id,u.nombre,u.estrellas,u.estado_verificacion from public.usuarios u
 where (select auth.uid()) is not null and (u.id=(select auth.uid()) or private.es_staff() or exists
   (select 1 from public.prestamos p where p.emprendedor_id=u.id and (private.en_mercado(p.id) or private.es_participante(p.id))));
create view public.resumen_financiamiento with (security_barrier=true) as
 select p.id as prestamo_id,count(a.id) as cantidad_prestamistas,coalesce(sum(a.monto),0) as total_aportado,coalesce(sum(a.monto_devuelto),0) as total_devuelto
 from public.prestamos p left join public.aportes a on a.prestamo_id=p.id
 where (select auth.uid()) is not null and (private.en_mercado(p.id) or private.es_participante(p.id) or private.es_staff()) group by p.id;
create view public.resumen_votacion with (security_barrier=true) as
 select e.id as evidencia_id,count(v.id) as votos_emitidos,count(v.id) filter(where v.decision='aprueba') as aprobaciones,count(v.id) filter(where v.decision='rechaza') as rechazos
 from public.evidencias e join public.etapas t on t.id=e.etapa_id left join public.votos v on v.evidencia_id=e.id
 where (select auth.uid()) is not null and (private.es_participante(t.prestamo_id) or private.es_staff()) group by e.id;
create view public.resumen_repartos with (security_barrier=true) as
 select c.id as cuota_id,c.prestamo_id,count(r.id) as cantidad_repartos,coalesce(sum(r.monto),0) as total_repartido
 from public.cuotas c left join public.repartos r on r.cuota_id=c.id
 where (select auth.uid()) is not null and (private.es_dueno(c.prestamo_id) or private.es_staff()) group by c.id,c.prestamo_id;
create view public.historial_prestamo with (security_barrier=true) as
 select e.id,e.prestamo_id,e.tipo,e.tx_hash,e.creado_en from public.eventos_prestamo e
 where (select auth.uid()) is not null and (private.es_participante(e.prestamo_id) or private.es_staff());

grant select on public.mercado_prestamos,public.mercado_etapas,public.perfiles_publicos,public.resumen_financiamiento,public.resumen_votacion,public.resumen_repartos,public.historial_prestamo to authenticated;
revoke all on public.mercado_prestamos,public.mercado_etapas,public.perfiles_publicos,public.resumen_financiamiento,public.resumen_votacion,public.resumen_repartos,public.historial_prestamo from anon;
revoke all on all functions in schema private from public,anon,authenticated;
grant execute on function private.rol_actual(),private.es_staff(),private.es_admin(),private.es_participante(uuid),private.es_dueno(uuid),private.en_mercado(uuid),private.negocio_visible(uuid),private.negocio_publicado(uuid),private.negocio_en_mercado(uuid) to authenticated;

commit;

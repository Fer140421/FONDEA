-- Usuarios ficticios sin credenciales; cada suite revierte su transacción completa.
insert into auth.users(id,email) select
 ('00000000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,
 'usuario'||i||'@example.test' from unnest(array[1,2,11,12,13,14,21,22,30]) i;
insert into public.usuarios(id,nombre,correo,celular,rol,contacto_emergencia_nombre,contacto_emergencia_celular,estado_verificacion,verificado_en)
select id,'Persona '||split_part(email,'@',1),email,'70123456',
 case when email in ('usuario1@example.test','usuario2@example.test') then 'emprendedor'::public.rol_usuario
 when email='usuario21@example.test' then 'admin'::public.rol_usuario
 when email='usuario22@example.test' then 'soporte'::public.rol_usuario
 else 'prestamista'::public.rol_usuario end,
 'Contacto Prueba','70987654','verificado',
 case when email in ('usuario13@example.test','usuario14@example.test') then now()-interval '10 days' else now()-interval '1 day' end
from auth.users where email like 'usuario%@example.test' and email<>'usuario30@example.test';

insert into public.negocios(id,usuario_id,nombre,categoria,tipo,formalidad,descripcion) values
 ('00000000-0000-4000-8000-000000000201','00000000-0000-4000-8000-000000000001','Tienda Uno','comercio','en_marcha','formal','Negocio de prueba con ventas y atención al público.'),
 ('00000000-0000-4000-8000-000000000202','00000000-0000-4000-8000-000000000002','Idea Dos','alimentos','idea_nueva',null,'Idea de negocio para elaborar alimentos de prueba.');
insert into public.prestamos(id,negocio_id,justificacion,monto,plazo_meses,tasa_anual,meses_hasta_primera_cuota,max_prestamistas) values
 ('00000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000201','Solicito capital para equipar y ampliar mi negocio de prueba.',1000,6,7,1,5);
insert into public.etapas(id,prestamo_id,numero,objetivo,monto,evidencia_requerida) values
 ('00000000-0000-4000-8000-000000000301','00000000-0000-4000-8000-000000000101',1,'Comprar herramientas',300,'Fotos de herramientas'),
 ('00000000-0000-4000-8000-000000000302','00000000-0000-4000-8000-000000000101',2,'Equipar el local',700,'Fotos del local');
update public.prestamos set estado='financiandose' where id='00000000-0000-4000-8000-000000000101';

create function pg_temp.aportar(persona int,importe numeric,letra text,prestamo uuid default '00000000-0000-4000-8000-000000000101') returns uuid language plpgsql as $$
declare identificador uuid; begin
 insert into public.aportes(prestamo_id,prestamista_id,monto,tx_hash)
 values(prestamo,('00000000-0000-4000-8000-'||lpad(persona::text,12,'0'))::uuid,importe,repeat(letra,64)) returning id into identificador;
 return identificador;
end $$;
create function pg_temp.financiar() returns void language plpgsql as $$ begin
 perform pg_temp.aportar(11,500,'1'); perform pg_temp.aportar(12,500,'2');
 update public.prestamos set estado='financiado' where id='00000000-0000-4000-8000-000000000101';
 update public.etapas set liberada_en=now(),tx_hash=repeat('a',64),estado='liberada' where id='00000000-0000-4000-8000-000000000301';
 update public.prestamos set estado='en_etapas' where id='00000000-0000-4000-8000-000000000101';
end $$;
set constraints all immediate;

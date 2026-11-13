select extensions.plan(5);
select pg_temp.aportar(11,100,'1');
insert into public.prestamos(id,negocio_id,justificacion,monto,plazo_meses,tasa_anual,meses_hasta_primera_cuota,max_prestamistas) values
 ('00000000-0000-4000-8000-000000000102','00000000-0000-4000-8000-000000000202','Capital para iniciar un negocio con las herramientas necesarias.',1000,3,7,1,5);
insert into public.etapas(prestamo_id,numero,objetivo,monto,evidencia_requerida) values
 ('00000000-0000-4000-8000-000000000102',1,'Comprar herramientas',300,'Fotos de herramientas'),
 ('00000000-0000-4000-8000-000000000102',2,'Equipar el local',700,'Fotos del local');
update public.prestamos set estado='financiandose' where id='00000000-0000-4000-8000-000000000102';
select extensions.throws_like($$select pg_temp.aportar(11,100,'2','00000000-0000-4000-8000-000000000102')$$,'%fuera de límites%','La promoción es solo para el primer aporte global');
select extensions.lives_ok($$select pg_temp.aportar(11,300,'2','00000000-0000-4000-8000-000000000102')$$,'Segundo aporte global usa el mínimo ordinario');
select extensions.throws_like($$select pg_temp.aportar(12,99.99,'3')$$,'%fuera de límites%','Ni el primer aporte puede ser menor a Bs100');
update public.usuarios set estado_verificacion='rechazado' where id='00000000-0000-4000-8000-000000000013';
update public.usuarios set estado_verificacion='verificado' where id='00000000-0000-4000-8000-000000000013';
select extensions.throws_like($$select pg_temp.aportar(13,100,'3')$$,'%fuera de límites%','Reverificar no reinicia la promoción');
select extensions.throws_like($$select pg_temp.aportar(1,300,'4')$$,'%no permitido%','El emprendedor no aporta a su propio préstamo');
select * from extensions.finish();

select extensions.plan(5);
select pg_temp.aportar(11,300,'1');
select pg_temp.aportar(12,200,'2');
create function pg_temp.cerrar(importe numeric) returns void language plpgsql as $$ begin
 set constraints all deferred;
 update public.etapas set monto=case numero when 1 then importe*0.3 else importe*0.7 end where prestamo_id='00000000-0000-4000-8000-000000000101';
 update public.prestamos set monto=importe,estado='financiado' where id='00000000-0000-4000-8000-000000000101';
 set constraints all immediate;
end $$;
select extensions.throws_like($$select pg_temp.cerrar(500)$$,'%tope pactado%','Cierre Bs500 con Bs300+Bs200 rechaza concentración de 60%');
-- El fallo anterior revierte íntegramente los cambios de su subtransacción.
select extensions.is((select monto::numeric from public.prestamos where id='00000000-0000-4000-8000-000000000101'),1000::numeric,'Cierre inválido no altera la meta');
select extensions.is((select sum(monto)::numeric from public.etapas where prestamo_id='00000000-0000-4000-8000-000000000101'),1000::numeric,'Cierre inválido no altera las etapas');
select extensions.is((select sum(porcentaje)::numeric from public.aportes where prestamo_id='00000000-0000-4000-8000-000000000101'),50::numeric,'Cierre inválido no altera participaciones');
select extensions.is((select estado::text from public.prestamos where id='00000000-0000-4000-8000-000000000101'),'financiandose','La solicitud sigue financiándose');
select * from extensions.finish();

select extensions.plan(3);
select pg_temp.financiar();
set local request.jwt.claims='{"sub":"00000000-0000-4000-8000-000000000021","role":"authenticated"}';
set local role authenticated;
select extensions.throws_like($$update public.prestamos set estado='borrador' where id='00000000-0000-4000-8000-000000000101'$$,'%publicado%','Ni administración revierte un préstamo publicado a borrador');
select extensions.throws_like($$delete from public.etapas where id='00000000-0000-4000-8000-000000000301'$$,'%historial%','Administración no borra un desembolso confirmado');
select extensions.is((select count(*)::int from public.etapas where liberada_en is not null),1,'Se conserva la etapa con fecha y hash de desembolso');
reset role;
select * from extensions.finish();

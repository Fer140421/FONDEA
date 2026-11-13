select extensions.plan(6);
select extensions.is((select count(*)::int from pg_tables where schemaname='public' and tablename in ('usuarios','negocios','documentos','prestamos','etapas','aportes','evidencias','votos','cuotas','notificaciones','repartos','eventos_prestamo','eventos_reputacion','dispositivos','parametros')),15,'Las quince tablas de negocio existen');
select extensions.is((select count(*)::int from pg_tables where schemaname='public' and rowsecurity and tablename in ('usuarios','negocios','documentos','prestamos','etapas','aportes','evidencias','votos','cuotas','notificaciones','repartos','eventos_prestamo','eventos_reputacion','dispositivos','parametros')),15,'RLS habilitado en las quince tablas');
select extensions.ok(not has_function_privilege('anon','private.parametro(text)','EXECUTE'),'Anónimo no ejecuta consultas internas de parámetros');
select extensions.ok(not has_function_privilege('authenticated','private.proteger_usuario()','EXECUTE'),'El usuario no ejecuta guardas internas directamente');
select extensions.ok(has_function_privilege('authenticated','private.es_participante(uuid)','EXECUTE'),'RLS conserva el helper explícitamente autorizado');
select extensions.ok(has_function_privilege('anon','private.leer_archivo(text,text)','EXECUTE'),'Storage conserva el helper limitado requerido por las políticas');
select * from extensions.finish();

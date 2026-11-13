select extensions.plan(1);
select extensions.results_eq('select clave,valor from public.parametros order by clave',
  $$values ('aporte_minimo',300::numeric),('aporte_minimo_inicial',100::numeric),('comision_originacion',2::numeric),('comision_servicio',1::numeric),('dias_primer_aporte',7::numeric),('limite_en_marcha',10000::numeric),('limite_idea_nueva',3000::numeric),('tasa_maxima_anual',7::numeric),('tope_prestamista',50::numeric)$$,
  'Parámetros iniciales: porcentajes en unidades de 100 e importes en Bs');
select * from extensions.finish();

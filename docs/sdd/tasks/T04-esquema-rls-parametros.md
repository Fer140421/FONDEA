# T04 · Esquema, RLS y parámetros

Rama: `feature/t04-database-rls`, creada desde `develop` después de integrar T03.

Especificación: [T04](../specs/T04-esquema-rls-parametros.md). Diseño de permisos: [acceso a datos](../design/T04-acceso-datos.md).

## Entrega

- [x] Quince tablas con dominios, tipos, restricciones, PK/FK e índices.
- [x] Enums de estados y roles, incluyendo `soporte`.
- [x] RLS y protección de columnas mediante guardas de escritura; proyecciones públicas y agregadas limitadas.
- [x] Parámetros iniciales con tasa anual máxima 7%, originación 2%, servicio 1%, mínimos Bs300/Bs100 y concentración 50%.
- [x] Políticas de Storage para identidad, documentos y evidencias.
- [x] Migraciones versionadas, ejecutores con seguimiento de versiones y entorno local reproducible.
- [x] Documentos de negocio y requerimientos actualizados con las decisiones acordadas; flujos HU07/HU10 revisados.
- [x] Reconstrucción y validación desde una base local vacía.
- [x] Revisión final y commit de entrega, incluyendo los dos documentos de producto y requerimientos.
- [ ] Aplicación y comprobación en el proyecto Supabase alojado: requiere conexión PostgreSQL administrativa del proyecto de desarrollo.

## Validación

Las suites SQL se ejecutan con pgTAP sobre las imágenes oficiales de Supabase, con Auth y Storage migrados por sus servicios. Comprueban permisos de anónimo/usuarios/administrador/soporte, promoción, cierre parcial, conservación de importes, cuotas, reparto y acceso equivalente a archivos. Dos carreras con conexiones reales verifican sobre financiación y consumo único de la promoción.

Los endpoints, automatizaciones de pagos, liquidación de cancelaciones y verificación en Stellar permanecen fuera del alcance. La aplicación del esquema remoto se informará por separado de la validación local.

Comprobaciones ejecutadas: `npm run typecheck`, `npm run build` y 19 pruebas en `npm test`; reconstrucción con `npm run db:reset:local` y `npm run test:db`, con 122 comprobaciones pgTAP y dos pruebas de concurrencia aprobadas. El entorno de pruebas no expone puertos ni carga el archivo `.env` del proyecto alojado.

## Standards

Se corrigió la revocación de `EXECUTE` sobre funciones internas: la revocación de privilegios por defecto por esquema no retiraba el permiso global de `PUBLIC`. Ahora se revoca explícitamente y se autoriza solo lo necesario para las políticas. Se conservó también el descubrimiento automático de pruebas ordinarias, separando la suite Docker en su propio directorio.

## Spec

Se bloqueó la vuelta a borrador de préstamos publicados y el borrado de sus etapas, incluso para un administrador autenticado de la aplicación. Las regresiones verifican que se conservan fecha y hash de desembolso.

Revisión: dos observaciones de estándares y una de especificación corregidas; la de mayor gravedad fue el camino de borrado de un desembolso confirmado. La aplicación remota sigue pendiente de una conexión PostgreSQL del proyecto de desarrollo.

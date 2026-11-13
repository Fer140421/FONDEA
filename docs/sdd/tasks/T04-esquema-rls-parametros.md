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
- [x] Aplicación y comprobación en el proyecto Supabase Cloud configurado en el backend, mediante conexión PostgreSQL administrativa con TLS verificado.

## Validación

Las suites SQL se ejecutan con pgTAP sobre las imágenes oficiales de Supabase, con Auth y Storage migrados por sus servicios. Comprueban permisos de anónimo/usuarios/administrador/soporte, promoción, cierre parcial, conservación de importes, cuotas, reparto y acceso equivalente a archivos. Dos carreras con conexiones reales verifican sobre financiación y consumo único de la promoción.

Los endpoints, automatizaciones de pagos, liquidación de cancelaciones y verificación en Stellar permanecen fuera del alcance. El entorno local es exclusivo de pruebas; el esquema de la aplicación está desplegado en Supabase Cloud.

Comprobaciones ejecutadas: `npm run typecheck`, `npm run build` y 19 pruebas en `npm test`; reconstrucción con `npm run db:reset:local` y `npm run test:db`, con 122 comprobaciones pgTAP y dos pruebas de concurrencia aprobadas. El entorno de pruebas no expone puertos ni carga el archivo `.env` del proyecto alojado.

Validación en Supabase Cloud, 2026-11-13: cuatro versiones registradas (la base técnica T03 y las tres migraciones T04), quince tablas con RLS y políticas, nueve parámetros con los valores acordados, rol `soporte` y tres buckets privados (`identidad`, `negocios`, `evidencias`). Se comprobaron las restricciones y los permisos de ejecución de funciones internas. Una conexión `authenticated` sin identidad no obtiene usuarios ni préstamos y puede consultar los parámetros; las solicitudes anónimas a usuarios, préstamos, parámetros y mercado reciben HTTP 401/42501. Una segunda ejecución del migrador no volvió a aplicar versiones existentes. La conexión empleó el certificado CA publicado por Supabase, conservando la validación de la cadena y del nombre del servidor.

Después del despliegue, `npm run verify:integration` aprobó los cinco controles reales: Stellar testnet, HTTP, Supabase Auth, Database y Storage. El archivo temporal de Storage se eliminó al terminar la comprobación.

## Standards

Se corrigió la revocación de `EXECUTE` sobre funciones internas: la revocación de privilegios por defecto por esquema no retiraba el permiso global de `PUBLIC`. Ahora se revoca explícitamente y se autoriza solo lo necesario para las políticas. Se conservó también el descubrimiento automático de pruebas ordinarias, separando la suite Docker en su propio directorio.

## Spec

Se bloqueó la vuelta a borrador de préstamos publicados y el borrado de sus etapas, incluso para un administrador autenticado de la aplicación. Las regresiones verifican que se conservan fecha y hash de desembolso.

Revisión: dos observaciones de estándares y una de especificación corregidas; la de mayor gravedad fue el camino de borrado de un desembolso confirmado. Las migraciones quedaron aplicadas y comprobadas en el proyecto Supabase Cloud.

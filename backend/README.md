# Backend Fondea · T03

Base Node.js con Express 5 y TypeScript estricto. Incluye Supabase Database/Auth/Storage, autenticación mediante Bearer token y Stellar testnet.

T04 incorpora las quince tablas del dominio, parámetros, restricciones, permisos y políticas de archivos. Su [contrato de acceso](../docs/sdd/design/T04-acceso-datos.md) identifica las vistas y operaciones que deben usar los futuros endpoints.

## Ejecutar

Requiere Node.js 24 o superior y npm. `.nvmrc` selecciona Node 24.

```bash
cd backend
npm ci
cp .env.example .env
# Completa SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY en .env.
npm run dev
```

Si ya tienes `.env`, conserva sus valores y añade las variables nuevas desde la plantilla. Los comandos cargan `.env` sin reemplazar variables ya definidas en el entorno del proceso. `.env` está ignorado por Git.

```bash
curl http://localhost:3000/health
# HTTP 200: {"status":"ok"}
```

Para compilar y ejecutar sin el observador de desarrollo:

```bash
npm run build
npm start
```

## Configuración

| Variable | Uso |
| --- | --- |
| `SUPABASE_URL` | URL del proyecto, disponible en Connect / configuración de API de Supabase. Obligatoria. |
| `SUPABASE_PUBLISHABLE_KEY` | Clave `sb_publishable_…` del mismo proyecto. Obligatoria. |
| `SUPABASE_STORAGE_BUCKET` | Bucket técnico `fondea-backend-checks`; coincide con el SQL de prueba. |
| `PORT` | Puerto HTTP; por defecto `3000`. |
| `NODE_ENV` | `development`, `test` o `production`; por defecto `development`. |
| `ALLOWED_ORIGINS` | Orígenes web separados por comas, sin barra final. Vacío no habilita orígenes web. Flutter nativo no depende de CORS. |
| `STELLAR_NETWORK` | `testnet`. Se rechaza otra red en este ticket. |
| `STELLAR_HORIZON_URL` | `https://horizon-testnet.stellar.org`. Se rechaza otra URL en este ticket. |

El servidor valida la configuración antes de escuchar. Los errores indican campos, sin imprimir sus valores. Este servicio utiliza la clave publicable: una variable heredada `SUPABASE_SERVICE_ROLE_KEY` no se utiliza. Las llamadas a Database y Storage usan el token del usuario; sus permisos dependen de las políticas RLS de Supabase.

## API y autenticación

| Petición | Autenticación | Resultado |
| --- | --- | --- |
| `GET /health` | Pública | `200 {"status":"ok"}`. Confirma que el proceso HTTP responde; no consulta servicios externos. |
| `GET /api/v1/me` | Bearer token de Supabase Auth | `200 {"user":{"id":"<UUID>"}}`. |
| `/api/v1/*` | Obligatoria por defecto | `401` si falta el token o es inválido/caducado. Los endpoints aún no implementados devuelven `404` después de autenticar. |

El preflight CORS (`OPTIONS`) se responde sin autenticación para que el navegador pueda enviar después la petición autenticada.

El cliente Flutter registra e inicia sesión directamente en Supabase Auth. Envía **el access token del usuario**, no la clave publicable, en `Authorization: Bearer <token>`. El backend verifica firma, caducidad, emisor del proyecto, audiencia y sujeto. No recibe refresh tokens ni renueva sesiones; esa responsabilidad permanece en el cliente.

```bash
# ACCESS_TOKEN debe contener una sesión válida del usuario, obtenida localmente.
curl -H "Authorization: Bearer $ACCESS_TOKEN" http://localhost:3000/api/v1/me
```

Un fallo del proveedor de autenticación devuelve `503 AUTH_UNAVAILABLE`; los errores internos no exponen detalles del SDK ni trazas. Los tokens verificados mediante firma siguen siendo válidos hasta su expiración: esta base no garantiza revocación inmediata tras cerrar una sesión. Las reglas por rol y el perfil de negocio se implementarán junto con sus módulos.

## Organización y extensión

```text
src/
  app.ts                    # Construcción de Express, sin abrir puertos
  server.ts                 # Configuración, arranque y cierre del servidor
  config/env.ts             # Validación de variables de entorno
  integrations/
    supabase.ts             # Validador y clientes independientes por usuario
    stellar.ts              # Horizon + passphrase de testnet
  middleware/auth.ts        # Token verificado, request.user y request.supabase
  modules/
    routes.ts               # Montaje de módulos dentro de la API protegida
    registro/routes.ts
    solicitudes/routes.ts
    aportes/routes.ts
    etapas/routes.ts
    cuotas/routes.ts
  shared/http-error.ts
  types/express.d.ts
scripts/verify-integration.ts
supabase/migrations/202611120001_backend_checks.sql
test/
```

Cada módulo tiene un router reservado, sin lógica de negocio ni respuestas ficticias. Añade sus rutas al router existente; incorpora controladores, servicios y acceso a datos cuando exista un caso de uso. El middleware expone `request.user.id` y `request.supabase` para las consultas bajo la identidad del usuario. Mantén los endpoints de negocio dentro de `/api/v1` para que hereden la autenticación.

Stellar queda accesible mediante `createStellarIntegration(config)` y en `app.locals.stellar` al arrancar el servidor: cliente `horizon`, `network` y `networkPassphrase`. T03 incluye una consulta de lectura a testnet para verificar la configuración. Las billeteras y transacciones quedan para tickets posteriores.

## Verificar contra Supabase y Stellar

1. En el SQL Editor de **tu proyecto de desarrollo** ejecuta completo [202611120001_backend_checks.sql](supabase/migrations/202611120001_backend_checks.sql). El script es transaccional y puede volver a ejecutarse.
2. Dispón de un usuario de prueba con correo confirmado en Supabase Auth.
3. Añade a `.env` **una** de estas alternativas:
   - `INTEGRATION_ACCESS_TOKEN`: un access token vigente de ese usuario.
   - `INTEGRATION_EMAIL` e `INTEGRATION_PASSWORD`: credenciales del usuario de prueba. El script inicia sesión y cierra únicamente la sesión que creó.
4. Ejecuta:

   ```bash
   npm run verify:integration
   ```

El script inicia su propio servidor en un puerto local libre: no requiere `npm run dev`. Comprueba:

- Horizon responde y anuncia la passphrase de testnet.
- `/health` responde sin token y `/api/v1/me` rechaza peticiones sin token o con formato inválido.
- Un token verificado permite obtener `/api/v1/me`.
- El usuario lee la fila técnica de `backend_connection_checks`; una consulta anónima es rechazada.
- El usuario sube y descarga un archivo de texto en `<UUID>/<archivo>.txt`, no puede escribir fuera de su carpeta y elimina el archivo al terminar, incluso si falla una comprobación posterior a la subida.

Si falta una sesión o cualquier comprobación falla, el comando termina con código distinto de cero. Nunca se considera una prueba omitida como una integración aprobada. No imprime credenciales ni respuestas completas del proveedor.

El SQL crea una tabla técnica con una fila estática, habilita RLS y concede únicamente lectura a `authenticated`. Crea también un bucket privado limitado a archivos `text/plain` de 1 KiB, con políticas separadas para insertar, leer y eliminar dentro de la carpeta del usuario. No permite actualizaciones ni sobrescritura. Los nombres de los recursos y las políticas pertenecen a estas pruebas; no los reutilices para datos de negocio.

Las políticas de Storage se combinan con otras políticas existentes: evita agregar políticas generales que concedan acceso a este bucket. Las tablas y buckets futuros necesitan sus propias reglas de acceso. Consulta [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Storage](https://supabase.com/docs/guides/storage/security/access-control), [validación de tokens](https://supabase.com/docs/reference/javascript/auth-getclaims) y [Stellar SDK](https://stellar.github.io/js-stellar-sdk/).

## Comprobaciones automáticas

```bash
npm run typecheck
npm run build
npm test
```

Las pruebas usan JWT firmados con claves EC generadas localmente y simulan las respuestas externas. Cubren tokens válidos, firmas falsas, expiración, emisor/audiencia/sujeto incorrectos, caída de Auth, protección de módulos y aislamiento de los clientes Supabase entre usuarios. No requieren credenciales ni acceso a Supabase y no sustituyen al script de integración real.

## Base de datos T04

Las migraciones están en `supabase/migrations`, ordenadas por versión:

- `202611120001_backend_checks.sql`: recursos técnicos de T03.
- `202611130001_esquema.sql`: dominios, enums, quince tablas, índices y cierre inicial de acceso.
- `202611130002_integridad_y_acceso.sql`: restricciones cruzadas, guardas de escritura, RLS y proyecciones de lectura.
- `202611130003_parametros_y_storage.sql`: parámetros y buckets privados con sus políticas.

Los importes se guardan en Bs con dos decimales. Las tasas porcentuales se almacenan como `7`, `2`, `1` y `50`. El préstamo conserva las condiciones vigentes al publicar; un cambio de parámetros afecta a publicaciones posteriores. Los endpoints y la comprobación de las transacciones Stellar se implementan en sus tickets.

Para el mercado usa `mercado_prestamos` y `mercado_etapas`, y para el perfil visible `perfiles_publicos`. Las tablas base contienen expedientes privados. `resumen_financiamiento`, `resumen_votacion`, `resumen_repartos` e `historial_prestamo` ofrecen las proyecciones agregadas y el historial sin detalles personales. Consulta la [matriz de acceso](../docs/sdd/design/T04-acceso-datos.md) antes de incorporar nuevas consultas.

### Probar el esquema y RLS

Requiere Docker con Compose y el motor en ejecución. Este entorno usa imágenes oficiales de PostgreSQL, Auth, PostgREST y Storage de Supabase. Los servicios aplican sus propias migraciones internas antes de las del proyecto.

```bash
cd backend
npm ci
npm run db:start
npm run db:migrate:local
npm run test:db
```

Las consultas de prueba se ejecutan con `psql` dentro de `fondea-db-test`: no requieren un cliente SQL instalado, puertos publicados ni montajes de carpetas del host. Esto también permite usarlas con Docker Desktop VMM desde WSL. La base local está separada de `.env` y del proyecto alojado; las credenciales conocidas del Compose solo sirven para este entorno desechable.

Las suites pgTAP ejecutan consultas e intentos de escritura como anónimo, usuarios distintos, administrador y soporte. Cada suite revierte sus fixtures. Las dos pruebas de concurrencia necesitan la base local sin perfiles: crean datos ficticios, comprueban transacciones paralelas y los retiran al terminar. El entorno se reserva para estas pruebas, no para datos de la aplicación.

Para reconstruir desde cero **solo la base de pruebas local**:

```bash
npm run db:reset:local
npm run test:db
```

El reset elimina los volúmenes del proyecto Compose de pruebas. `npm run db:stop` retira sus contenedores conservando el volumen. Ninguno de estos comandos acepta una URL de base remota.

### Aplicar al proyecto Supabase de desarrollo

El ejecutor remoto requiere una conexión PostgreSQL con permisos de migración del mismo proyecto indicado en `SUPABASE_URL`. La clave publicable de la API no permite ejecutar DDL. Obtén la conexión directa o **Session pooler**, puerto 5432, desde **Connect** en el dashboard; conserva el valor en un archivo local privado fuera de Git.

```bash
npm run db:migrate:cloud -- --url-file /ruta/privada/conexion-postgres.txt --ca-file /ruta/prod-ca-2021.crt
```

El script lee la conexión desde el archivo, valida que corresponda al proyecto configurado y utiliza TLS con verificación del certificado. No imprime la conexión ni la pasa como argumento a otro proceso. No necesita guardar una contraseña PostgreSQL en `.env`.

Descarga el certificado CA desde **Database Settings → SSL Configuration** en Supabase y pásalo con `--ca-file`. Es un certificado público, distinto de las credenciales de conexión. La opción es necesaria cuando Node no reconoce la CA de Supabase; sin ella se conserva la verificación con las autoridades del sistema. Consulta la [documentación oficial de SSL](https://supabase.com/docs/guides/platform/ssl-enforcement). No desactives la verificación TLS para resolver errores de certificado.

Cada archivo y su registro de versión se aplican en una misma transacción. `supabase_migrations.schema_migrations` conserva las versiones aplicadas; una nueva ejecución omite esas versiones. El ejecutor aborta si encuentra versiones remotas que no existen en el repositorio. Si falla una migración, las anteriores permanecen registradas y la fallida se revierte. No edites migraciones que ya se hayan aplicado a un entorno compartido: crea otra versión.

El estado final verifica las quince tablas con RLS. Las pruebas completas de permisos se ejecutan en el entorno local; aplicar el esquema no equivale a probar transferencias de Stellar.

### Operadores y archivos

El alta normal solo permite `emprendedor` y `prestamista`. Los perfiles `admin` y `soporte` los asigna Fondea mediante una sesión administrativa de Supabase. Soporte puede consultar expedientes y registrar intervenciones; las aprobaciones, parámetros y registros de dinero se reservan a administración y operaciones verificadas. El cliente Supabase por usuario de T03 conserva sus permisos y no se transforma en un cliente administrativo.

Los buckets `identidad`, `negocios` y `evidencias` son privados. Guarda rutas, no URLs públicas ni enlaces firmados permanentes. La subida, lectura y limpieza de cargas se autorizan según su propietario, referencia y estado del préstamo. No se sobrescriben archivos registrados. Los documentos vigentes y las reglas de cada campo se encuentran en el [diccionario actualizado](../docs/Fondea%20-%20Especificacion%20de%20Requerimientos.md).

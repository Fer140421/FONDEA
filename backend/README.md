# Backend Fondea · T03

Base Node.js con Express 5 y TypeScript estricto. Incluye Supabase Database/Auth/Storage, autenticación mediante Bearer token y Stellar testnet.

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

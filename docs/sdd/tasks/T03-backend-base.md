# T03 · Base del backend Node.js conectado a Supabase

Estado: implementación y verificaciones completadas; pendiente de revisión e integración en `develop`.

Especificación: [T03-backend-base.md](../specs/T03-backend-base.md).
Guía de ejecución: [backend/README.md](../../../backend/README.md).
Rama de trabajo: `feature/t03-backend-base`.

## Criterios de aceptación

- [x] Proyecto Node.js con TypeScript estricto y módulos de registro, solicitudes, aportes, etapas y cuotas. Los routers quedan preparados para sus futuros endpoints.
- [x] Clientes Supabase Database, Auth y Storage configurados mediante variables de entorno.
- [x] Middleware que valida los tokens de Supabase Auth y protege `/api/v1` por defecto. `/health` y el preflight CORS son excepciones públicas acordadas.
- [x] Stellar SDK instalado y configurado para testnet, con consulta de lectura verificada.
- [x] `GET /health` funcionando. `GET /api/v1/me` permite comprobar la identidad autenticada.

## Evidencia de verificación

Validaciones ejecutadas durante la implementación:

- `npm run typecheck`: aprobado.
- `npm run build`: aprobado.
- `npm test`: 14 pruebas aprobadas.
- Servidor compilado: `/health` devuelve 200 y `/api/v1/me` sin token devuelve 401.
- Consulta real a Horizon: passphrase de testnet confirmada.

El responsable del ticket ejecutó el asistente local y confirmó que las cinco comprobaciones de integración terminaron con `OK`: Stellar, HTTP, Auth, Database y Storage. Esta confirmación corresponde a la ejecución manual del responsable; no se guardan sus credenciales ni una transcripción de su terminal en el repositorio.

Una comprobación adicional desde el entorno de desarrollo confirmó que la API de Supabase responde a la consulta anónima de la tabla técnica con HTTP 401 y código `42501` (permiso denegado), en lugar del anterior `PGRST205` (tabla no encontrada).

El script de integración verifica lectura autenticada y rechazo anónimo en Database, así como subida, descarga, rechazo de acceso anónimo, aislamiento de carpetas y eliminación del archivo de prueba en Storage. El SQL de infraestructura puede volver a ejecutarse.

## Entrega

Revisar el diff y preparar el commit y Pull Request hacia `develop`. Los archivos `.env`, dependencias instaladas y artefactos compilados están ignorados por Git. Los endpoints y permisos por rol de los módulos de negocio se implementarán en tickets posteriores.

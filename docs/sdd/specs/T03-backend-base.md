# T03 · Base del backend Node.js conectado a Supabase

Puntos: 3. Sprint: 0, continúa en el 1. Alcance acordado con el responsable del ticket.

## Contexto y alcance

Establecer la infraestructura sobre la que se implementarán los endpoints de Fondea. Se usará Express con TypeScript y módulos de registro, solicitudes, aportes, etapas y cuotas. T03 reserva sus routers; sus casos de negocio se implementan en tickets posteriores.

El cliente registra e inicia sesión directamente mediante Supabase Auth. El backend recibe su access token, valida la identidad y transmite ese mismo token a Database y Storage para respetar RLS. La autorización por roles y los perfiles de negocio corresponden a sus futuros endpoints.

## Criterios verificables

1. `npm run typecheck`, `npm run build` y `npm test` completan correctamente en `backend/`. El servidor compilado arranca con `npm start`.
2. La configuración del proyecto Supabase se recibe mediante variables de entorno. El servidor falla antes de escuchar si faltan valores obligatorios o son inválidos, sin imprimir credenciales.
3. `GET /health` es público y devuelve `200 {"status":"ok"}` sin depender de servicios externos. El preflight CORS también está exento de autenticación.
4. Todas las rutas bajo `/api/v1` requieren autenticación por defecto. Tokens ausentes, falsificados, caducados o de otro emisor/audiencia reciben `401`. Una indisponibilidad de Auth recibe `503`.
5. `GET /api/v1/me` devuelve únicamente el UUID de un usuario autenticado. Las respuestas de la API llevan `Cache-Control: no-store`.
6. Cada petición autenticada dispone de su propio cliente Supabase. Los tokens de usuarios distintos no se mezclan y no se utiliza una clave administrativa para estas operaciones.
7. El Stellar SDK está instalado y configurado exclusivamente para testnet. Una consulta de lectura confirma la passphrase de la red, sin transacciones ni billeteras.
8. El SQL técnico es reproducible: tabla de una fila legible únicamente por usuarios autenticados y bucket privado de pruebas. Los usuarios solo pueden insertar, leer y eliminar archivos dentro de su carpeta UUID.
9. `npm run verify:integration` comprueba Auth, Database, Storage, HTTP y Stellar contra servicios reales. Si falta configuración o una comprobación se omite/falla, termina con error.

## Evidencia y límites

Las pruebas automáticas verifican firmas JWT con claves EC locales y respuestas de Supabase simuladas. El script de integración requiere aplicar el SQL en el proyecto de desarrollo y proporcionar una sesión de prueba mediante el entorno local. La compilación y las pruebas automáticas no certifican por sí solas la integración real.

La validación de firma no garantiza revocación inmediata de tokens aún vigentes. Las políticas de Storage se combinan con otras políticas del proyecto; los recursos técnicos no deben tener políticas generales que amplíen su acceso.

Implementación y comandos: [backend/README.md](../../../backend/README.md).

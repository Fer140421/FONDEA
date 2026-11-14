# T04 · Acceso a datos

Las decisiones de producto están en [T04](../specs/T04-esquema-rls-parametros.md). Esta guía define las interfaces de lectura y escritura para los futuros endpoints.

## Lecturas

| Interfaz | Audiencia / contenido |
| --- | --- |
| `mercado_prestamos` | Autenticados; solo `financiandose`. Ficha comercial, condiciones, nombre y estrellas del emprendedor; la publicación administrativa representa la revisión documental. |
| `mercado_etapas` | Autenticados; plan publicado, sin hashes de desembolso ni revisiones privadas. |
| `perfiles_publicos` | Nombre, estrellas y estado de verificación; perfiles propios, Fondea y emprendedores visibles por mercado o participación. |
| `prestamos`, `etapas`, `cuotas`, `evidencias` | Emprendedor, aportantes y Fondea. Los reembolsados conservan acceso al historial. |
| `aportes`, `votos` | Autor, emprendedor del préstamo y Fondea. |
| `repartos` | Prestamista receptor y Fondea. |
| `resumen_financiamiento`, `resumen_votacion` | Mercado cuando corresponde o participantes/Fondea; no exponen identidades ni movimientos individuales. |
| `resumen_repartos` | Emprendedor y Fondea; total y cantidad de repartos por cuota. |
| `historial_prestamo` | Participantes/Fondea; tipo, fecha y hash, sin actor ni `detalle` privado. |
| `usuarios` | Perfil completo propio y Fondea. |
| `notificaciones`, `dispositivos` | Propietario; los tokens FCM no se comparten con otros usuarios ni soporte. |
| `eventos_prestamo` | Detalle completo reservado a Fondea; la aplicación usa el historial proyectado. |
| `eventos_reputacion` | Propietario y Fondea. |
| `parametros` | Autenticados. |

Las proyecciones de mercado ejecutan la consulta con privilegios de su propietario para atravesar tablas privadas y devolver exclusivamente columnas aprobadas. No son vistas genéricas ni `SELECT *`: usan filtros de `auth.uid()`, pertenencia o financiación, grants limitados y barrera de seguridad. No deben ampliarse con datos personales o `detalle jsonb` sin revisar las pruebas de acceso.

## Escrituras

- El usuario registra un perfil coincidente con Auth como emprendedor/prestamista y edita sus datos personales permitidos. Rol, reputación, límite y verificación son protegidos. Reemplazar el carnet vuelve a dejar la revisión pendiente, sin reiniciar la primera fecha de verificación ni su promoción.
- El emprendedor verificado registra negocios, documentos y un borrador. Configura las etapas mientras el préstamo es borrador. Las condiciones incompletas no pasan a revisión; la publicación es administrativa.
- El emprendedor inserta la evidencia dentro de su plazo y puede presentar una corrección tras el primer rechazo. No se sobrescribe la evidencia previa.
- El aportante activo inserta su voto dentro de las 72 horas. El voto es inmutable y el rechazo exige justificación.
- El destinatario solo cambia `leida` en una notificación y administra sus propios dispositivos.
- Soporte inserta únicamente eventos `intervencion_soporte` bajo su identidad, sin hash de dinero.
- Administración registra estados y operaciones verificadas. El registro de aportes, cuotas y repartos no se concede como capacidad al prestamista o emprendedor por ser propietario. T03 mantiene clientes por usuario; un futuro endpoint financiero necesitará una vía administrativa protegida y comprobar Stellar antes de registrar el resultado.

Las funciones internas se ubican en `private`, no expuesto por PostgREST, con `search_path` vacío y permisos de ejecución explícitos. No se autorizan roles mediante metadatos editables de Auth.

## Restricciones y concurrencia

El propietario de un préstamo se deriva del negocio. Un indicador mantenido por la base y un índice parcial único representan la solicitud abierta, incluyendo cancelaciones con deuda. Los cambios de financiación bloquean la fila del préstamo y la del prestamista para impedir sobre financiación, aportes duplicados y consumo simultáneo de la promoción.

Los planes de etapas y las sumas de repartos se comprueban al terminar la transacción. El cierre parcial debe ajustar etapas y préstamo en la misma transacción. Las condiciones se congelan al publicar; el capital original y el monto devuelto permanecen diferenciados. Los pagos confirmados, aportes originales, votos y eventos no se sobrescriben.

## Storage

| Bucket privado | Ruta | Lectura |
| --- | --- | --- |
| `identidad` | `<usuario_uuid>/<archivo>` | Propietario y Fondea. |
| `negocios` | `<usuario_uuid>/<negocio_uuid>/<archivo>` | Propietario y Fondea; terceros autenticados solo para fotos registradas de un negocio en mercado. |
| `evidencias` | `<usuario_uuid>/<etapa_uuid>/<archivo>` | Propietario/Fondea y participantes cuando el archivo está registrado en una evidencia. |

Solo el propietario sube archivos a su ruta; las reglas de estado y plazo también se comprueban. No se habilita sobrescritura. Los archivos referenciados se conservan; las cargas propias aún no registradas se pueden eliminar. Los buckets permanecen privados para que tener una ruta no equivalga a autorización.

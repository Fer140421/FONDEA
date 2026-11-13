# T04 · Esquema de base de datos, RLS y parámetros

Puntos: 5. Sprint: 1. Decisiones confirmadas durante la entrevista del ticket, el 13 de noviembre de 2026.

## Alcance

Crear las quince tablas del diccionario, sus enums, restricciones de integridad, permisos, proyecciones de lectura, políticas de Storage y parámetros. Las migraciones deben poder reconstruir el esquema y las pruebas deben ejecutar operaciones reales como `anon`, usuarios distintos, administrador y soporte.

Fuentes actualizadas: [Especificación de requerimientos](../../Fondea%20-%20Especificacion%20de%20Requerimientos.md), secciones 3, 6, 7 y 8; [Negocio y producto](../../Fondea%20-%20Documento%20de%20Negocio%20y%20Producto.md), secciones 9 y 10; [glosario](../../../GLOSSARY.md).

## Decisiones acordadas

1. Las tablas son `usuarios`, `negocios`, `documentos`, `prestamos`, `etapas`, `aportes`, `evidencias`, `votos`, `cuotas`, `notificaciones`, `repartos`, `eventos_prestamo`, `eventos_reputacion`, `dispositivos` y `parametros`. La tabla técnica T03 conserva su propósito y no se reutiliza.
2. Los roles son `emprendedor`, `prestamista`, `admin` y `soporte`. El registro solo admite los dos primeros. Soporte consulta expedientes y registra intervenciones; no verifica usuarios, aprueba solicitudes, cambia condiciones ni autoriza dinero.
3. El mercado exige sesión y solo muestra préstamos en financiación. Después, sus fichas desaparecen; emprendedor y todos los aportantes conservan historial privado.
4. El perfil público expone nombre, estrellas y verificación del emprendedor. La información comercial y financiera publicada se separa del expediente completo. No se publican correo, teléfonos, carnet, emergencia, dispositivos ni detalles privados de eventos.
5. Solo las fotos del negocio son visibles en mercado. Licencias, matrículas y facturas se reservan al propietario y Fondea. Las evidencias se comparten con participantes y Fondea, con reglas equivalentes en Storage.
6. Los prestamistas consultan sus aportes, votos y repartos, y los agregados de los demás. El emprendedor consulta aportes y justificaciones de votos y el total repartido.
7. La edición propia no permite modificar campos del sistema. El cliente no fabrica movimientos confirmados, verificación, reputación ni estados financieros. Administración y operaciones verificadas tienen autoridad de registro; la comprobación de Stellar pertenece a los endpoints posteriores.
8. Hay una sola solicitud abierta por emprendedor entre todos sus negocios, incluyendo borrador. Se admite borrador incompleto, pero no su envío sin condiciones ni etapas válidas. Borradores sin movimientos se pueden eliminar.
9. La tasa máxima anual inicial es **7%**. El monto máximo es el menor entre el límite individual y Bs 3.000 para idea nueva o Bs 10.000 para negocio en marcha.
10. Al publicar se conservan clasificación del negocio, límite efectivo, tasa máxima, mínimos de aporte, concentración y comisiones. Los cambios de parámetros se aplican a publicaciones posteriores.
11. Un prestamista tiene un solo aporte por préstamo y un hash de pago no se reutiliza. La promoción Bs100 vale únicamente para su primer aporte global, en los siete días posteriores a su primera verificación; después rige Bs300.
12. El cierre parcial exige al menos dos prestamistas y máximo 50% por persona sobre el monto final. Monto, etapas y porcentajes se actualizan atómicamente. La base serializa los cambios de financiación por préstamo y la elegibilidad promocional por prestamista.
13. Cada devolución se registra por separado del monto aportado y no puede superarlo. Una devolución parcial mantiene capital vigente. Un mismo hash de devolución puede incluir varios receptores.
14. Financiación y primer desembolso tienen fechas distintas. El plazo y los vencimientos parten del primer desembolso, tomando la fecha local de Bolivia.
15. Cancelar tras desembolsar no elimina la deuda ni permite otra solicitud. La liquidación y reprogramación de cuotas pendientes se registrarán mediante una operación verificada. T04 no calcula automáticamente esa liquidación ni llama a Stellar.
16. Se conservan los préstamos publicados, aportes, votos, desembolsos, pagos, repartos y eventos. No se corrigen importes confirmados mediante borrado o sobrescritura.
17. Los importes tienen dos decimales, rechazan negativos y NaN. La última cuota ajusta el residuo de centavos. Los repartos usan capital vigente exacto; los centavos residuales se asignan por mayores restos, con desempate por prestamista, y conservan el neto total.

## Criterios de aceptación y comprobación

- Existen las quince tablas, sus PK/FK, índices y enums; todas tienen RLS habilitado y grants explícitos.
- Se validan campos, rangos, propiedad inmutable, promoción, concentración, número y suma de etapas, un aporte/voto por participante, correspondencia cuota/aporte, reparto exacto y conservación de registros.
- Las lecturas de mercado se realizan mediante proyecciones de columnas aprobadas. Las vistas con privilegios del propietario llevan filtros explícitos de identidad y audiencia, `security_barrier` y grants solo a autenticados. Las tablas base siguen privadas por RLS.
- Las tres clases de archivos residen en buckets privados. Las políticas restrictivas evitan que una política permisiva general del proyecto abra los archivos de Fondea. Los objetos registrados no se sobrescriben ni se eliminan desde la aplicación.
- `parametros` contiene originación 2, servicio 1, aporte ordinario 300, aporte inicial 100, tope 50 y tasa anual máxima 7. Incluye además los techos de negocio 3.000/10.000 y la ventana promocional de siete días.
- El esquema se reconstruye desde una base local vacía con las migraciones versionadas. Las suites pgTAP prueban permisos y denegaciones con distintos usuarios sobre PostgreSQL/Auth/Storage oficiales.
- `npm run typecheck`, `npm run build`, `npm test` y `npm run test:db` pasan.

## Límites explícitos

Los endpoints, verificación de firmas/transacciones de dinero, integración Trustless Work, conversión Bs/USDC, pesos de reputación y cronómetros automáticos se implementan en sus tickets. Los operadores privilegiados del panel Supabase tienen autoridad administrativa; las protecciones de la aplicación no son un aislamiento frente al propietario de la base.

Antes de automatizar liberaciones se resolverá la contradicción entre hacerlo durante la primera mitad del plazo y permitir cuotas iniciales en meses que la superan. T04 valida cantidades/importes y guarda fechas, sin imponer esa condición temporal incompatible.

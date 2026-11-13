# **Fondea — Especificación de requerimientos**

Nov 13, 2026 · Actualizado con las decisiones de T04 y el Documento de negocio y producto

## **1\. Requerimientos funcionales**

**37 requerimientos en 7 módulos; cada uno es verificable y se prueba en QA.**

| ID | El sistema debe… |
| :---- | :---- |
| **Registro** |  |
| RF-01 | Registrar usuarios con correo, contraseña y rol (emprendedor o prestamista) |
| RF-02 | Pedir un contacto de emergencia (nombre completo y celular) |
| RF-03 | Permitir subir el carnet con la cámara y marcar al usuario como "pendiente" hasta su verificación manual |
| RF-04 | Conectar una billetera móvil por WalletConnect y crear la línea de confianza de USDC si falta |
| RF-05 | Mostrar el saldo en bolivianos con su equivalente en USDC |
| **Solicitud** |  |
| RF-06 | Registrar el negocio: categoría, tipo (en marcha o idea nueva) y documentos (matrícula o licencia; si es informal, fotos y facturas de los últimos 6 meses) |
| RF-07 | Registrar la justificación del préstamo |
| RF-08 | Validar el monto contra el menor entre el límite personal y el del tipo de negocio (Bs 3.000 idea nueva; Bs 10.000 en marcha) |
| RF-09 | Permitir un plazo de 3 a 12 meses |
| RF-10 | Validar la tasa anual contra el máximo vigente de Fondea, inicialmente 7% |
| RF-11 | Permitir los meses hasta la primera cuota según el plazo (1–2 o 1–3) |
| RF-12 | Configurar etapas (objetivo, monto, evidencia) y validar cantidad y porcentajes |
| RF-13 | Permitir elegir el máximo de prestamistas (de 2 a 5\) |
| RF-14 | Mostrar en vivo la calculadora del emprendedor (cuota, cantidad de cuotas, primera fecha, total e interés) |
| RF-15 | Enviar la solicitud a revisión |
| RF-16 | Permitir a Fondea publicar o rechazar con motivo (desde Supabase) |
| **Mercado y financiamiento** |  |
| RF-17 | Para usuarios autenticados, listar únicamente solicitudes en financiación, con filtros y orden; retirar su ficha al salir de ese estado |
| RF-18 | Mostrar detalle comercial, fotos del negocio, verificación del emprendedor, información agregada, calculadora y aviso de riesgo; restringir documentos personales |
| RF-19 | Registrar un aporte firmado por el prestamista hacia el escrow, validando mínimo, 50%, monto faltante y máximo de prestamistas |
| RF-20 | Al día 8 sin meta, ofrecer ampliar 7 días (y subir el máximo de prestamistas) o cerrar con lo recaudado, recalculando cuotas y etapas |
| RF-21 | Al día 15 sin meta ni cierre, cancelar y devolver cada aporte desde el escrow |
| RF-22 | Al llegar a la meta, pasar a "Financiado"; registrar el cronograma definitivo desde el primer desembolso |
| **Etapas** |  |
| RF-23 | Liberar la etapa 1 del escrow a la billetera del emprendedor |
| RF-24 | Permitir subir evidencia (fotos y descripción) en 15 días, con 5 días extra tras un recordatorio, y registrar su hash |
| RF-25 | Permitir votar la evidencia en 72 horas: todos aprueban, el silencio aprueba y el rechazo exige justificación |
| RF-26 | Liberar la siguiente etapa solo con la evidencia aprobada y las cuotas al día |
| RF-27 | Gestionar el rechazo: una corrección, pausa con mediación de 72 horas y cancelación si no hay acuerdo |
| RF-28 | Descontar el 2% de originación en la última etapa |
| **Pagos** |  |
| RF-29 | Mostrar el cronograma de cuotas con su estado y la etapa que habilita cada una |
| RF-30 | Generar la transacción de cuota con un pago por prestamista más el 1% de Fondea, para que la firme el emprendedor |
| RF-31 | Mostrar al prestamista sus cobros, lo pendiente y su rendimiento |
| RF-32 | Enviar notificaciones push: vencimientos (3 días antes y el día), votaciones, etapas liberadas y cobros |
| **Mora** |  |
| RF-33 | Aplicar los estados de atraso (1–7, 8–30 y más de 30 días) con sus avisos |
| RF-34 | En mora: congelar etapas pendientes y devolver el saldo del escrow a los prestamistas |
| **Reputación e historial** |  |
| RF-35 | Calcular estrellas (de 1 a 5, inicio en 3 con etiqueta "Nuevo") |
| RF-36 | Ajustar el límite de monto y el rango de tasa según el puntaje |
| RF-37 | Mostrar el historial de cada préstamo con enlaces al explorador de Stellar |

## **2\. Requerimientos no funcionales**

| ID | Tipo | Requerimiento |
| :---- | :---- | :---- |
| RNF-01 | Seguridad | Login con Supabase Auth; RLS y permisos de escritura según propietario, participante, administrador y soporte. Mercado solo para autenticados durante financiación; datos personales restringidos (sección 7) |
| RNF-02 | Seguridad | Fondea nunca guarda claves privadas: el usuario firma con su billetera |
| RNF-03 | Privacidad | Los datos personales y los archivos quedan fuera de la cadena; en Stellar solo van montos, direcciones y hashes |
| RNF-04 | Rendimiento | Cada pantalla carga en menos de 3 segundos con 4G |
| RNF-05 | Usabilidad | Primero el celular, en español, montos en bolivianos y sin jerga cripto |
| RNF-06 | Compatibilidad | Android 9 o superior, y versión web para el jurado |
| RNF-07 | Trazabilidad | Cada movimiento de dinero tiene su enlace al explorador de Stellar |
| RNF-08 | Consistencia | Las operaciones de dinero son atómicas: se ejecutan completas o no se ejecutan |
| RNF-09 | Disponibilidad | La demo está disponible durante toda la evaluación |
| RNF-10 | Mantenibilidad | Código en GitHub, TypeScript y Dart, con revisión de PR |
| RNF-11 | Costo | Solo servicios con plan gratuito; solo testnet |

## **3\. Reglas de validación**

**Todos los límites en un solo lugar, para que nadie los programe distinto.**

| Regla | Valor |
| :---- | :---- |
| Monto del primer préstamo | Hasta Bs 10.000 (en marcha) · hasta Bs 3.000 (idea nueva) |
| Plazo | 3 a 12 meses |
| Tasa máxima | 7% anual; valor porcentual 7, no 0,07 |
| Meses hasta la primera cuota | 1–2 (plazo de 3 a 6\) · 1–3 (plazo de 7 a 12\) |
| Cantidad de etapas | Mínimo 2 · máximo 2 (plazo de 3 a 6\) · máximo 3 (plazo de 7 a 12\) · ideas nuevas: el máximo de su plazo |
| Monto por etapa | Etapa 1: máximo 30% · cada etapa: mínimo 20% · la suma es igual al total |
| Liberación de etapas | Por evidencia y cuotas; objetivo de primera mitad pendiente de resolver frente a los meses de espera (sección 8) |
| Plazo para evidencia | 15 días \+ 5 días tras recordatorio |
| Votación | 72 horas · aprobación unánime · el silencio aprueba |
| Mediación tras segundo rechazo | 72 horas |
| Prestamistas por préstamo | 2 a 5 |
| Aporte mínimo | Bs 300; solo el primer aporte global puede empezar en Bs 100 dentro de siete días desde la primera verificación |
| Aporte máximo por prestamista | Un aporte por préstamo, hasta 50% del monto final; el cierre parcial conserva ese tope y al menos dos prestamistas |
| Plazo para reunir la meta | 8 días \+ 7 de ampliación · cancelación al día 15 |
| Cuota | Monto × (1 \+ tasa anual porcentual ÷ 1200 × meses) ÷ cantidad de cuotas; ajuste de centavos en la última |
| Atrasos | 1–7 días: recordatorio · 8–30: aviso y baja puntaje · más de 30: mora |
| Comisiones | 2% de originación (última etapa) · 1% de cada cuota |
| Estrellas | 1 a 5 con medias · inicio en 3 · \+1 por el primer préstamo pagado a tiempo |
| Solicitudes abiertas | 1 por emprendedor entre todos sus negocios; incluye borrador y cancelación con deuda |

## **4\. Historias de usuario**

**Cada historia se da por terminada cuando cumple los RF que cubre y las reglas de la sección 3\.** Las de prioridad Alta forman el camino feliz de la demo.

| ID | Historia | RF | Prioridad |
| :---- | :---- | :---- | :---- |
| HU01 | Registrarme, iniciar y cerrar sesión | RF-01, RF-02 | Alta |
| HU02 | Verificar mi identidad | RF-03 | Media |
| HU03 | Conectar mi billetera | RF-04, RF-05 | Alta |
| HU04 | Registrar mi negocio | RF-06, RF-07 | Alta |
| HU05 | Definir monto, plazo y tasa | RF-08 a RF-10, RF-14 | Alta |
| HU06 | Elegir los meses hasta la primera cuota | RF-11 | Media |
| HU07 | Definir etapas y prestamistas | RF-12, RF-13 | Alta |
| HU08 | Revisar y publicar solicitudes | RF-15, RF-16 | Alta |
| HU09 | Ver el mercado | RF-17 | Alta |
| HU10 | Ver el detalle de una oportunidad | RF-18 | Alta |
| HU11 | Prestar | RF-19 | Alta |
| HU12 | Ampliar o cerrar el financiamiento | RF-20 a RF-22 | Media |
| HU13 | Recibir la etapa 1 | RF-23 | Alta |
| HU14 | Subir evidencia | RF-24 | Alta |
| HU15 | Votar la evidencia | RF-25 | Alta |
| HU16 | Recibir la siguiente etapa | RF-26, RF-28 | Alta |
| HU17 | Corregir una evidencia rechazada | RF-27 | Media |
| HU18 | Ver mi cronograma de cuotas | RF-29 | Alta |
| HU19 | Pagar una cuota | RF-30 | Alta |
| HU20 | Ver mis cobros | RF-31 | Media |
| HU21 | Recibir notificaciones | RF-32 | Baja |
| HU22 | Aplicar atrasos y mora | RF-33, RF-34 | Baja |
| HU23 | Ver las estrellas | RF-35, RF-36 | Media |
| HU24 | Ver el historial | RF-37 | Media |

### **4.1 Registro**

#### **HU01 · Registrarme, iniciar y cerrar sesión**

*Como* persona nueva, *quiero* registrarme como emprendedor o prestamista, *para* usar Fondea. · **RF:** RF-01, RF-02 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Estoy en la pantalla de registro | Ingreso correo, contraseña, rol y contacto de emergencia válidos | Se crea mi cuenta y entro a la pantalla de mi rol |
| 2 | El correo ya está registrado | Intento registrarme | Veo "Este correo ya tiene cuenta" |
| 3 | Falta el contacto de emergencia | Envío el formulario | No me deja continuar |
| 4 | Abro la app sin sesión | — | Veo la pantalla de inicio: qué es Fondea, cómo funciona y los botones para registrarme o ingresar |
| 5 | Ya tengo cuenta | Ingreso correo y contraseña correctos | Entro a la pantalla de mi rol |
| 6 | Ingreso una contraseña incorrecta | Intento ingresar | Veo "Correo o contraseña incorrectos" |
| 7 | Tengo la sesión abierta | Toco "Cerrar sesión" | Vuelvo a la pantalla de inicio |

#### **HU02 · Verificar mi identidad**

*Como* usuario, *quiero* subir mi carnet, *para* poder pedir o prestar. · **RF:** RF-03 · **Prioridad:** Media

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Tomé las fotos del anverso y reverso con la cámara | Las envío | Mi estado pasa a "Pendiente de verificación" |
| 2 | Mi cuenta está pendiente | Intento crear una solicitud o prestar | Veo "Tu cuenta está en verificación" |
| 3 | Fondea verificó mi carnet | Entro a la app | Mi estado es "Verificado" |

#### **HU03 · Conectar mi billetera**

*Como* usuario, *quiero* conectar mi billetera, *para* recibir y enviar dinero. · **RF:** RF-04, RF-05 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Tengo LOBSTR en testnet | Me conecto por WalletConnect | Se guarda mi dirección y veo mi saldo en Bs y USDC |
| 2 | Mi billetera no tiene la línea de confianza de USDC | Me conecto | La app me pide crearla con un toque |
| 3 | Estoy conectando la billetera | Rechazo la conexión | Veo el error y puedo reintentar |

### **4.2 Solicitud**

#### **HU04 · Registrar mi negocio**

*Como* emprendedor, *quiero* registrar mi negocio, *para* que los prestamistas confíen en mí. · **RF:** RF-06, RF-07 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Mi negocio es formal | Subo la matrícula o licencia | Queda guardada con su fecha |
| 2 | Mi negocio es informal | Subo fotos y facturas de los últimos 6 meses con la cámara | Quedan guardadas para la revisión |
| 3 | Elijo "idea nueva" | Guardo el negocio | Se marca "Idea nueva · mayor riesgo"; sus solicitudes tienen techo Bs 3.000, respetando un límite personal inferior y sin cambiar el de otros negocios |
| 4 | La justificación está vacía | Intento avanzar | No me deja |

#### **HU05 · Definir monto, plazo y tasa**

*Como* emprendedor, *quiero* ver cuánto pagaré cada mes, *para* pedir un préstamo que pueda cumplir. · **RF:** RF-08 a RF-10, RF-14 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Mi límite es Bs X | Ingreso un monto mayor | Veo "Tu límite actual es Bs X" |
| 2 | Estoy en el paso de condiciones | Ingreso un plazo fuera de 3–12 meses o una tasa fuera del rango | No me deja avanzar |
| 3 | Los datos son válidos | Cambio monto, plazo o tasa | La calculadora actualiza al instante la cuota, el total y el interés |

#### **HU06 · Elegir los meses hasta la primera cuota**

*Como* emprendedor, *quiero* elegir cuándo pago la primera cuota, *para* dar tiempo a mi negocio. · **RF:** RF-11 · **Prioridad:** Media

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | El plazo es de 3 a 6 meses | Abro la opción | Solo puedo elegir 1 o 2 (con 7 a 12 meses, de 1 a 3\) |
| 2 | Elijo más de 1 mes | Confirmo | Veo "Tu etapa 2 se liberará después de tu primera cuota" |
| 3 | Cambio el valor | — | La calculadora recalcula las cuotas y la fecha de la primera |

#### **HU07 · Definir etapas y prestamistas**

*Como* emprendedor, *quiero* dividir mi préstamo en etapas, *para* mostrar en qué usaré el dinero. · **RF:** RF-12, RF-13 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | El plazo es de 3 a 6 meses | Configuro las etapas | Solo puedo tener 2 (con 7 a 12 meses, 2 o 3; las ideas nuevas, el máximo de su plazo) |
| 2 | Estoy configurando montos | La etapa 1 supera el 30%, una etapa es menor al 20% o la suma no es igual al total | Veo el error y no puedo avanzar |
| 3 | Cada etapa tiene objetivo, monto y evidencia, y elegí entre 2 y 5 prestamistas | Envío la solicitud | Pasa a "En revisión" |

#### **HU08 · Revisar y publicar solicitudes**

*Como* Fondea, *quiero* revisar cada solicitud, *para* publicar solo las que cumplen. · **RF:** RF-15, RF-16 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Una solicitud está "En revisión" | La publico desde Supabase | Aparece en el mercado y empieza el plazo de 8 días |
| 2 | Una solicitud no cumple | La rechazo con un motivo | El emprendedor ve el motivo en la app |

### **4.3 Mercado y financiamiento**

#### **HU09 · Ver el mercado**

*Como* prestamista, *quiero* ver las solicitudes publicadas, *para* elegir a quién prestar. · **RF:** RF-17 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Hay solicitudes publicadas | Entro al mercado | Veo tarjetas con negocio, categoría, monto, tasa, plazo, % financiado, estrellas y etiquetas |
| 2 | Estoy en el mercado | Filtro por categoría u ordeno por tasa o % financiado | La lista se actualiza |
| 3 | No hay solicitudes | Entro al mercado | Veo un mensaje claro de lista vacía |

#### **HU10 · Ver el detalle**

*Como* prestamista, *quiero* ver el detalle de una solicitud, *para* decidir con información. · **RF:** RF-18 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Estoy en el mercado | Abro una solicitud | Veo justificación, fotos del negocio, verificación del emprendedor, etapas, cronograma estimado desde el primer desembolso, cantidad agregada de prestamistas, días restantes y monto faltante |
| 2 | Estoy en el detalle | Ingreso un monto en la calculadora | Veo cuánto recibiré, ya descontado el 1% |
| 3 | Estoy en el detalle | — | Siempre veo el aviso de riesgo de la etapa 1 |

#### **HU11 · Prestar**

*Como* prestamista, *quiero* prestar un monto, *para* ganar intereses. · **RF:** RF-19 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | El monto es menor al mínimo, mayor al 50%, mayor al faltante, o ya se alcanzó el máximo de prestamistas | Intento prestar | Veo el error y no puedo continuar |
| 2 | El monto es válido | Firmo con mi billetera | El pago va al escrow y el aporte se registra con su enlace a Stellar |
| 3 | Se abrió la firma | La cancelo | No se registra nada |

#### **HU12 · Ampliar o cerrar el financiamiento**

*Como* emprendedor, *quiero* decidir qué hacer si no llego a la meta, *para* no perder la oportunidad. · **RF:** RF-20 a RF-22 · **Prioridad:** Media

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Es el día 8 y no llegué al 100% | Abro mi solicitud | Puedo ampliar 7 días (y subir el máximo de prestamistas) o cerrar con lo recaudado |
| 2 | Elegí cerrar con lo recaudado | Confirmo | Se exige al menos dos prestamistas y máximo 50% por persona sobre el monto final; si cumple, se ajustan monto y etapas y pasa a "Financiado"; las fechas definitivas nacen del primer desembolso |
| 3 | Es el día 15 sin meta ni cierre | Vence el plazo | Se cancela y cada aporte vuelve desde el escrow |
| 4 | Se reunió el 100% | Entra el último aporte | Pasa a "Financiado"; el cronograma definitivo se registra desde el primer desembolso |

### **4.4 Etapas**

#### **HU13 · Recibir la etapa 1**

*Como* emprendedor, *quiero* recibir la etapa 1, *para* empezar. · **RF:** RF-23 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Mi préstamo se financió | Pasa a "Financiado" | La etapa 1 se libera cuando se hace la solicitud de liberar el dinero del escrow a mi billetera, con su enlace a Stellar |
| 2 | Recibí la etapa 1 | — | Empiezan a correr los 15 días para la evidencia y el plazo del préstamo |



#### **HU14 · Subir evidencia**

*Como* emprendedor, *quiero* subir la evidencia, *para* demostrar el uso del dinero. · **RF:** RF-24 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Recibí una etapa | Subo fotos con la cámara y una descripción | Se guardan con su hash y la etapa pasa a "En revisión" |
| 2 | Pasaron 15 días sin evidencia | — | Recibo un recordatorio y tengo 5 días más |
| 3 | Pasaron los 5 días extra sin evidencia | — | Las etapas se pausan y bajan mis estrellas |

#### **HU15 · Votar la evidencia**

*Como* prestamista, *quiero* votar la evidencia, *para* controlar el uso del dinero. · **RF:** RF-25 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Hay una evidencia en revisión | Apruebo | Se registra mi voto |
| 2 | Hay una evidencia en revisión | Rechazo sin justificación | No puedo enviar el voto hasta que llene la justificación. |
| 3 | Todos aprobaron, o pasaron 72 horas sin rechazos | — | La evidencia queda aprobada |

#### **HU16 · Recibir la siguiente etapa**

*Como* emprendedor, *quiero* recibir la siguiente etapa, *para* seguir con mi plan. · **RF:** RF-26, RF-28 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | La evidencia anterior está aprobada y mis cuotas están al día | Se cumple la última condición | La siguiente etapa se libera a mi billetera solicitando la liberación de dinero |
| 2 | Falta una de las dos condiciones | Reviso la etapa | La app me dice qué falta |
| 3 | Es la última etapa | Se libera | Se descuenta el 2% de originación |

#### **HU17 · Corregir una evidencia rechazada**

*Como* emprendedor, *quiero* corregir una evidencia rechazada, *para* no perder el préstamo. · **RF:** RF-27 · **Prioridad:** Media

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Mi evidencia fue rechazada por primera vez | Abro la etapa | Veo las justificaciones y puedo subir una corrección |
| 2 | La corrección también es rechazada | — | Administración autoriza la pausa y soporte registra las gestiones durante las 72 horas de mediación |
| 3 | No hay acuerdo en 72 horas | — | Se cancela: lo no desembolsado vuelve a los prestamistas y lo recibido queda como deuda |

### **4.5 Pagos y mora**

#### **HU18 · Ver mi cronograma**

*Como* emprendedor, *quiero* ver mis cuotas, *para* saber cuánto y cuándo pagar. · **RF:** RF-29 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Tengo un préstamo activo | Abro mis cuotas | Veo cada cuota con fecha, monto, estado y la etapa que habilita |
| 2 | Tengo cuotas pendientes | — | La próxima aparece destacada, con los días que faltan |

#### **HU19 · Pagar una cuota**

*Como* emprendedor, *quiero* pagar desde la app, *para* no tener que pagarle a cada prestamista. · **RF:** RF-30 · **Prioridad:** Alta

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Tengo una cuota pendiente | Toco "Pagar" | La app arma una sola transacción con un pago por prestamista más el 1% de Fondea |
| 2 | La transacción está lista | La firmo | Todo se ejecuta junto, la cuota pasa a "Pagada" y se revisa si se libera la siguiente etapa |
| 3 | No tengo saldo suficiente | Toco "Pagar" | Veo el aviso y no se envía nada |

#### **HU20 · Ver mis cobros**

*Como* prestamista, *quiero* ver lo que recibí, *para* saber cuánto gano. · **RF:** RF-31 · **Prioridad:** Media

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Presté a uno o más negocios | Entro a mi panel | Veo por préstamo lo prestado, lo cobrado, lo pendiente y la ganancia esperada |
| 2 | Recibí cobros | Abro un préstamo | Cada cobro muestra su fecha y su enlace a Stellar |

#### **HU21 · Recibir notificaciones**

*Como* usuario, *quiero* recibir avisos push, *para* no olvidar nada. · **RF:** RF-32 · **Prioridad:** Baja

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Tengo una cuota | Faltan 3 días o es el día del vencimiento | Recibo un push |
| 2 | Hay una votación pendiente, una etapa liberada o un cobro | Ocurre el evento | Recibo un push |

#### **HU22 · Aplicar atrasos y mora**

*Como* Fondea, *quiero* que los atrasos tengan consecuencias automáticas, *para* proteger a los prestamistas. · **RF:** RF-33, RF-34 · **Prioridad:** Baja

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Una cuota vence sin pago | Pasan de 1 a 7 días | Se envía un recordatorio diario |
| 2 | La cuota sigue impaga | Pasan de 8 a 30 días | Se avisa a los prestamistas y bajan las estrellas |
| 3 | La cuota sigue impaga | Pasan más de 30 días | El préstamo pasa a "En mora", se congelan las etapas y el saldo del escrow vuelve a los prestamistas |

### **4.6 Reputación e historial**

#### **HU23 · Ver las estrellas**

*Como* prestamista, *quiero* ver la reputación del emprendedor, *para* evaluar el riesgo. · **RF:** RF-35, RF-36 · **Prioridad:** Media

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | El emprendedor es nuevo | Veo su perfil | Tiene 3 estrellas y la etiqueta "Nuevo" |
| 2 | Cumple etapas y cuotas a tiempo (o tiene rechazos, atrasos o mora) | Se registra el evento | Sus estrellas suben (o bajan); su primer préstamo pagado a tiempo suma 1 |
| 3 | Cambian sus estrellas | Crea un nuevo préstamo | Su límite de monto y su rango de tasa se ajustan |

#### **HU24 · Ver el historial**

*Como* usuario, *quiero* ver el historial de un préstamo, *para* comprobar que todo es transparente. · **RF:** RF-37 · **Prioridad:** Media

| \# | Dado | Cuando | Entonces |
| :---- | :---- | :---- | :---- |
| 1 | Soy emprendedor o aportante del préstamo | Entro al historial privado | Veo etapas, cuotas, eventos sin datos personales y mis movimientos; el emprendedor ve aportes y justificaciones de votos, y los demás prestamistas ven agregados |
| 2 | Veo un movimiento de dinero | Lo toco | Se abre su transacción en el explorador de Stellar |

## **5\. Modelo de datos (Supabase)**

**Quince tablas; el préstamo es el centro, y todo lo demás cuelga de él.** Los campos tx\_hash guardan el enlace a la transacción de Stellar.

| Tabla | Campos principales | Relación |
| :---- | :---- | :---- |
| usuarios | id, nombre, correo, celular, rol, carnet, estado\_verificacion, contacto\_emergencia, billetera, estrellas, limite\_monto | — |
| negocios | id, usuario\_id, nombre, categoria, tipo (en\_marcha / idea\_nueva), formalidad, descripcion | 1 usuario → muchos negocios |
| documentos | id, negocio\_id, tipo (matricula, licencia, foto, factura), url, fecha | 1 negocio → muchos documentos |
| prestamos | id, negocio\_id, justificacion, monto, plazo\_meses, tasa\_anual, meses\_hasta\_primera\_cuota, max\_prestamistas, estado, escrow\_id, fecha\_limite, fecha\_financiado | 1 negocio → muchos préstamos (1 activo) |
| etapas | id, prestamo\_id, numero, objetivo, monto, evidencia\_requerida, estado, fecha\_liberacion, fecha\_limite\_evidencia, tx\_hash | 1 préstamo → 2 o 3 etapas |
| aportes | id, prestamo\_id, prestamista\_id, monto, porcentaje, tx\_hash, estado (activo / devuelto) | 1 préstamo → 2 a 5 aportes |
| evidencias | id, etapa\_id, url, hash, descripcion, intento (1 o 2), estado | 1 etapa → hasta 2 evidencias |
| votos | id, evidencia\_id, prestamista\_id, decision, justificacion, fecha | 1 evidencia → 1 voto por prestamista |
| cuotas | id, prestamo\_id, numero, fecha\_vencimiento, monto, estado (pendiente / pagada / atrasada), dias\_atraso, tx\_hash | 1 préstamo → muchas cuotas |
| notificaciones | id, usuario\_id, tipo, mensaje, leida, fecha | 1 usuario → muchas notificaciones |

**Tablas intermedias y de soporte** (detalle en 6.11 a 6.15):

* **Relaciones muchos a muchos:** aportes une prestamistas con préstamos (un prestamista presta a muchos préstamos y un préstamo tiene varios prestamistas); votos une prestamistas con evidencias; repartos une cuotas con aportes.\
* **Soporte:** eventos\_prestamo (historial), eventos\_reputacion (cálculo de estrellas), dispositivos (notificaciones push) y parametros (reglas configurables).

**Estados del préstamo:** borrador, en\_revision, rechazado, financiandose, cancelado, financiado, en\_etapas, en\_pago, en\_mora, pausado, pagado.

## **6\. Diccionario de datos**

**Tipos de PostgreSQL (Supabase). PK \= clave primaria, FK \= clave foránea. Los montos se guardan en bolivianos con 2 decimales; los montos en la cadena van en USDC.**

### **6.1 usuarios**

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK, \= id de Supabase Auth | Identificador del usuario |
| nombre | text | Sí | 3–100 caracteres | Nombre completo |
| correo | text | Sí | Único, formato válido | Correo de acceso |
| celular | text | Sí | 8 dígitos | Celular de contacto |
| rol | rol_usuario | Sí | emprendedor, prestamista, admin, soporte | Solo Fondea asigna roles privilegiados |
| carnet\_anverso\_url | text | No | Ruta en Storage | Foto del carnet (anverso) |
| carnet\_reverso\_url | text | No | Ruta en Storage | Foto del carnet (reverso) |
| estado\_verificacion | enum | Sí | pendiente, verificado, rechazado · por defecto: pendiente | Estado de la verificación de identidad |
| contacto\_emergencia\_nombre | text | Sí | 3–100 caracteres | Nombre del contacto de emergencia |
| contacto\_emergencia\_celular | text | Sí | 8 dígitos | Celular del contacto de emergencia |
| billetera | text | No | Dirección Stellar válida (56 caracteres, empieza con G), única | Dirección de la billetera conectada |
| estrellas | numeric(2,1) | Sí | 1.0–5.0, pasos de 0.5 · por defecto: 3.0 | Reputación del emprendedor |
| es\_nuevo | boolean | Sí | Por defecto: true | Muestra la etiqueta "Nuevo" |
| limite\_monto | monto_bob | Sí | Por defecto: 10000; protegido | Techo personal; la solicitud aplica además el techo por tipo de negocio |
| verificado\_en | timestamptz | No | Primera verificación; se conserva en revisiones posteriores | Origen de la promoción |
| primer\_aporte\_hasta | timestamptz | No | Primera verificación + días configurados, inicialmente 7 | La promoción requiere además no haber aportado antes |
| creado\_en | timestamptz | Sí | Por defecto: now() | Fecha de registro |

### **6.2 negocios**

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador del negocio |
| usuario\_id | uuid | Sí | FK → usuarios.id | Dueño del negocio |
| nombre | text | Sí | 3–100 caracteres | Nombre del negocio |
| categoria | enum | Sí | comercio, alimentos, produccion, servicios, otros | Rubro |
| tipo | enum | Sí | en\_marcha, idea\_nueva | Determina límites y etapas |
| formalidad | enum | No | formal, informal · obligatorio si tipo \= en\_marcha | Define qué documentos se piden |
| descripcion | text | Sí | 20–1000 caracteres | Qué hace el negocio |
| creado\_en | timestamptz | Sí | Por defecto: now() | Fecha de registro |

### **6.3 documentos**

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador |
| negocio\_id | uuid | Sí | FK → negocios.id | Negocio al que pertenece |
| tipo | enum | Sí | matricula, licencia, foto\_negocio, factura | Clase de documento |
| url | text | Sí | Ruta en Storage | Archivo |
| fecha\_documento | date | No | No futura | Fecha que figura en el documento (sirve para verificar los 6 meses) |
| creado\_en | timestamptz | Sí | Por defecto: now() | Fecha de carga |

### **6.4 prestamos**

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador del préstamo |
| negocio\_id | uuid | Sí | FK → negocios.id | Negocio que pide |
| emprendedor\_id | uuid | Sí | FK → usuarios.id; derivado del dueño del negocio e inmutable | Permite controlar una solicitud abierta entre todos sus negocios |
| justificacion | text | No en borrador | 50–2000 caracteres | Para qué es el dinero |
| monto | numeric(12,2) | No en borrador | \> 0 y ≤ limite\_monto del usuario | Monto pedido (o recaudado si cerró antes) |
| plazo\_meses | integer | No en borrador | 3–12 | Plazo total |
| tasa\_anual | numeric(5,2) | No en borrador | 0–máximo vigente; inicialmente 7% anual. Máximo pactado al publicar | Tasa de interés anual (%) |
| meses\_hasta\_primera\_cuota | integer | No en borrador | 1–2 si plazo ≤ 6 · 1–3 si plazo ≥ 7 | Meses de espera |
| cantidad\_cuotas | integer | Sí | \= plazo\_meses − meses\_hasta\_primera\_cuota \+ 1 | Calculado |
| monto\_cuota | numeric(12,2) | Sí | Fórmula de la sección 3 | Calculado |
| total\_devolver | numeric(12,2) | Sí | monto × (1 \+ tasa\_anual ÷ 1200 × plazo\_meses) | Calculado |
| max\_prestamistas | integer | No en borrador | 2–5 | Elegido por el emprendedor |
| monto\_recaudado | numeric(12,2) | Sí | ≥ 0 · por defecto: 0 | Suma de aportes activos |
| estado | enum | Sí | Ver estados del préstamo · por defecto: borrador | Estado actual |
| motivo\_rechazo | text | No | Obligatorio si estado \= rechazado | Motivo de Fondea |
| escrow\_id | text | No | ID de contrato de Trustless Work | Escrow del préstamo |
| publicado\_en | timestamptz | No | — | Inicio del plazo de financiamiento |
| fecha\_limite\_financiamiento | timestamptz | No | publicado\_en \+ 8 días (+7 si se amplía) | Límite para reunir la meta |
| ampliado | boolean | Sí | Por defecto: false · solo una vez | Si usó los 7 días extra |
| financiado\_en | timestamptz | No | — | Fecha de financiación; no inicia el plazo |
| creado\_en | timestamptz | Sí | Por defecto: now() | Fecha de creación |

Los datos de condiciones y los campos calculados son obligatorios al salir de borrador. Una solicitud rechazada libera el bloqueo; cancelada con desembolso lo conserva mientras queden cuotas sin liquidar. Las cuotas pagadas no se sobrescriben; la reprogramación pendiente tras cancelación corresponde a una operación verificada.

| Campo adicional | Tipo | Restricción / propósito |
| :---- | :---- | :---- |
| primer_desembolso_en | timestamptz | Se registra con la primera etapa; inicio inmutable del plazo |
| comision_originacion_pactada | porcentaje | Comisión congelada al publicar |
| comision_servicio_pactada | porcentaje | Comisión congelada al publicar |
| aporte_minimo_pactado | monto_bob | Mínimo ordinario congelado al publicar |
| aporte_inicial_pactado | monto_bob | Mínimo promocional congelado al publicar |
| tope_prestamista_pactado | porcentaje | Concentración congelada al publicar |
| limite_monto_pactado | monto_bob | Menor entre el techo personal y el del negocio al publicar |
| tasa_maxima_pactada | porcentaje | Máximo anual congelado al publicar |
| tipo_negocio_pactado | tipo_negocio | Clasificación que determina el plan de etapas pactado |
| bloquea_nueva_solicitud | boolean | Derivado por la base; índice único por emprendedor cuando es true |

### **6.5 etapas**

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador |
| prestamo\_id | uuid | Sí | FK → prestamos.id | Préstamo al que pertenece |
| numero | integer | Sí | 1–3, único por préstamo | Orden de la etapa |
| objetivo | text | Sí | 10–300 caracteres | Para qué es la etapa |
| monto | numeric(12,2) | Sí | Etapa 1 ≤ 30% · cada una ≥ 20% · suma \= monto del préstamo | Monto de la etapa |
| evidencia\_requerida | text | Sí | 5–300 caracteres | Qué debe subir el emprendedor |
| estado | enum | Sí | pendiente, liberada, en\_revision, aprobada, rechazada, pausada, congelada | Estado de la etapa |
| liberada\_en | timestamptz | No | — | Fecha de desembolso |
| fecha\_limite\_evidencia | timestamptz | No | liberada\_en \+ 15 días (+5 tras recordatorio) | Plazo para subir la evidencia |
| comision\_descontada | numeric(12,2) | Sí | Por defecto: 0 · 2% del préstamo solo en la última etapa | Comisión de originación |
| tx\_hash | text | No | Hash de transacción de Stellar | Desembolso en la cadena |

### **6.6 aportes**

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador |
| prestamo\_id | uuid | Sí | FK → prestamos.id | Préstamo financiado |
| prestamista\_id | uuid | Sí | FK → usuarios.id · distinto del dueño del negocio | Quién presta |
| monto | numeric(12,2) | Sí | Mínimo pactado; promoción solo en primer aporte global y dentro de su plazo · ≤ tope pactado del monto final · ≤ faltante | Monto aportado |
| monto\_devuelto | monto_bob | Sí | Por defecto 0; entre 0 y monto | Devolución acumulada, separada del aporte original |
| porcentaje | porcentaje | Sí | monto ÷ monto final × 100, redondeado a dos decimales | Presentación; el reparto usa capital vigente exacto |
| estado | estado_aporte | Sí | activo, devuelto · devuelto si monto_devuelto = monto | Una devolución parcial mantiene el aporte activo |
| tx\_hash | hash_stellar | Sí | 64 caracteres hexadecimales y único | Pago al escrow; reintentos no duplican el aporte |
| devolucion\_tx\_hash | text | No | — | Reembolso desde el escrow |
| creado\_en | timestamptz | Sí | Por defecto: now() | Fecha del aporte |

### **6.7 evidencias**

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador |
| etapa\_id | uuid | Sí | FK → etapas.id | Etapa que respalda |
| intento | integer | Sí | 1 o 2 | Original o corrección |
| descripcion | text | Sí | 10–500 caracteres | Explicación del emprendedor |
| archivos | text\[\] | Sí | 1–5 rutas en Storage | Fotos y facturas |
| hash | text | Sí | SHA-256 de los archivos | Huella que se registra |
| estado | enum | Sí | en\_revision, aprobada, rechazada · por defecto: en\_revision | Resultado |
| fecha\_limite\_votacion | timestamptz | Sí | creado\_en \+ 72 horas | Cierre de la votación |
| creado\_en | timestamptz | Sí | Por defecto: now() | Fecha de carga |

### **6.8 votos**

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador |
| evidencia\_id | uuid | Sí | FK → evidencias.id | Evidencia votada |
| prestamista\_id | uuid | Sí | FK → usuarios.id · único por evidencia · debe tener un aporte activo en el préstamo | Quién vota |
| decision | enum | Sí | aprueba, rechaza | Voto |
| justificacion | text | No | Obligatoria si decision \= rechaza (10–500 caracteres) | Motivo del rechazo |
| creado\_en | timestamptz | Sí | Por defecto: now() | Fecha del voto |

### **6.9 cuotas**

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador |
| prestamo\_id | uuid | Sí | FK → prestamos.id | Préstamo |
| numero | integer | Sí | 1 a cantidad\_cuotas, único por préstamo | Orden de la cuota |
| fecha\_vencimiento | date | Sí | Desde primer_desembolso_en, meses de espera y número de cuota; fecha local America/La_Paz | Fecha de pago |
| monto | monto_bob | Sí | Cuota ordinaria; última ajusta centavos. Tras cancelación, reprogramación solo por operación verificada | Monto a pagar |
| comision | monto_bob | Sí | Porcentaje de servicio pactado, redondeado a centavos | Parte para Fondea |
| estado | enum | Sí | pendiente, pagada, atrasada · por defecto: pendiente | Estado de pago |
| dias\_atraso | integer | Sí | ≥ 0 · por defecto: 0 | Días desde el vencimiento |
| pagada\_en | timestamptz | No | — | Fecha de pago |
| tx\_hash | text | No | Hash de la transacción de reparto | Pago en la cadena |

### **6.10 notificaciones**

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador |
| usuario\_id | uuid | Sí | FK → usuarios.id | Destinatario |
| tipo | enum | Sí | vencimiento, votacion, etapa\_liberada, cobro, mora, solicitud | Motivo del aviso |
| mensaje | text | Sí | 1–300 caracteres | Texto mostrado |
| prestamo\_id | uuid | No | FK → prestamos.id | Préstamo relacionado |
| leida | boolean | Sí | Por defecto: false | Si el usuario la vio |
| creado\_en | timestamptz | Sí | Por defecto: now() | Fecha de envío |

### **6.11 repartos**

Tabla intermedia entre cuotas y aportes: guarda cuánto recibió cada prestamista en cada cuota.

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador |
| cuota\_id | uuid | Sí | FK → cuotas.id | Cuota pagada |
| aporte\_id | uuid | Sí | FK → aportes.id · único junto con cuota\_id | Aporte (y prestamista) que recibe |
| monto | monto_bob | Sí | Proporcional al capital vigente exacto; centavos por mayores restos y desempate por prestamista | Monto recibido; puede ser cero por redondeo |
| tx\_hash | text | Sí | Igual al de la cuota (un pago dentro de la misma transacción) | Transacción en Stellar |

### **6.12 eventos\_prestamo**

Registro de todo lo que pasa en un préstamo; alimenta la línea de tiempo del historial (HU24).

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador |
| prestamo\_id | uuid | Sí | FK → prestamos.id | Préstamo |
| usuario\_id | uuid | No | FK → usuarios.id · vacío si lo hizo el sistema | Quién lo provocó |
| tipo | enum | Sí | cambio\_estado, aporte, etapa\_liberada, evidencia, voto, cuota\_pagada, devolucion, mediacion, intervencion\_soporte | Tipo de evento |
| detalle | jsonb | No | — | Datos del evento (estado anterior y nuevo, montos, etc.) |
| tx\_hash | text | No | — | Transacción de Stellar, si hubo movimiento de dinero |
| creado\_en | timestamptz | Sí | Por defecto: now() | Fecha del evento |

### **6.13 eventos\_reputacion**

Cada suma o resta de estrellas, para calcularlas y poder explicarlas.

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador |
| usuario\_id | uuid | Sí | FK → usuarios.id | Emprendedor afectado |
| prestamo\_id | uuid | No | FK → prestamos.id | Préstamo relacionado |
| motivo | enum | Sí | etapa\_aprobada, cuota\_a\_tiempo, prestamo\_completado, evidencia\_rechazada, atraso, mora, evidencia\_vencida | Causa |
| variacion | numeric(2,1) | Sí | Entre −2.0 y \+1.0, en pasos de 0.5 | Cambio en las estrellas |
| creado\_en | timestamptz | Sí | Por defecto: now() | Fecha |

### **6.14 dispositivos**

Necesaria para las notificaciones push con Firebase Cloud Messaging.

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| id | uuid | Sí | PK | Identificador |
| usuario\_id | uuid | Sí | FK → usuarios.id | Dueño del dispositivo |
| fcm\_token | text | Sí | Único | Token de Firebase para enviar el push |
| plataforma | enum | Sí | android, web | Tipo de dispositivo |
| actualizado\_en | timestamptz | Sí | Por defecto: now() | Última vez que se registró |

### **6.15 parametros**

Las reglas de negocio configurables, para no escribirlas fijas en el código (por ejemplo, la tasa máxima anual del 7%). Los porcentajes se almacenan como 7, 2, 1 y 50, no como fracciones.

| Campo | Tipo | Obligatorio | Restricciones | Descripción |
| :---- | :---- | :---- | :---- | :---- |
| clave | text | Sí | PK | Nombre del parámetro (por ejemplo: tasa\_maxima\_anual, comision\_originacion, aporte\_minimo) |
| valor | numeric | Sí | — | Valor vigente |
| descripcion | text | No | — | Para qué sirve |
| actualizado\_en | timestamptz | Sí | Por defecto: now() | Última modificación |

**Reparto de una cuota:** cada prestamista recibe su fracción del neto usando (aporte − devolución) ÷ capital vigente total, sin usar el porcentaje redondeado de presentación. Los centavos se asignan por mayores restos, con desempate por prestamista. La suma debe ser exactamente cuota − comisión, el aporte y la cuota deben corresponder al mismo préstamo y compartir el hash de pago. El backend verificará Stellar en su ticket; T04 valida esos registros y prohíbe que el cliente los fabrique.

## 7. Contrato de acceso y escritura · T04

Los dominios `monto_bob` y `porcentaje` conservan dos decimales y rechazan negativos y valores no finitos; `hash_stellar` exige 64 caracteres hexadecimales. Las restricciones cruzadas se validan dentro de la base. Los planes completos y los repartos se comprueban al finalizar la transacción para permitir cambios atómicos.

| Recurso | Lectura | Escritura desde la aplicación |
| :---- | :---- | :---- |
| usuarios | Perfil completo propio y Fondea; perfil público mínimo mediante proyección | Registro como emprendedor/prestamista y datos personales autorizados; rol, verificación, reputación y límites reservados |
| negocios | Propietario, participantes y Fondea; datos comerciales mediante mercado | Emprendedor verificado, con propiedad inmutable; se bloquean cambios durante un préstamo publicado abierto |
| documentos | Propietario/Fondea; fotos de negocio mientras hay préstamo en financiación | Propietario; documentos ligados a publicaciones se conservan |
| prestamos / etapas | Expediente privado para participantes y Fondea; proyección comercial mientras financia | Propietario configura borrador; administración publica y registra cambios verificados |
| aportes | Autor, emprendedor del préstamo y Fondea; terceros solo agregados | Solo administración u operación verificada; un aporte por persona/préstamo |
| evidencias | Participantes y Fondea | Emprendedor dentro del plazo, máximo dos intentos; el resultado está protegido |
| votos | Autor, emprendedor y Fondea; demás participantes solo agregado | Aportante activo, un voto inmutable dentro de las 72 horas; rechazo justificado |
| cuotas | Participantes y Fondea | Administración u operación verificada |
| repartos | Prestamista receptor y Fondea; emprendedor ve total | Administración u operación verificada; inmutables |
| notificaciones / dispositivos | Solo propietario en la aplicación | Marcar aviso leído y administrar dispositivos propios; contenido de avisos reservado al sistema |
| eventos_prestamo | Raw reservado a Fondea; participantes reciben historial sin actor ni detalle privado | Administración; soporte solo registra intervenciones propias, sin dinero |
| eventos_reputacion | Propietario y Fondea; puntaje público limitado durante financiación | Solo administración u operación verificada; inmutables |
| parametros | Usuarios autenticados | Solo administración; no se borran claves vigentes |

El usuario autenticado no adquiere permisos de administración por cambiar metadatos de Auth. Solo Fondea asigna `admin` y `soporte`; soporte consulta expedientes y registra intervenciones, sin aprobar solicitudes, modificar dinero o cambiar parámetros.

Las vistas `mercado_prestamos`, `mercado_etapas` y `perfiles_publicos` exponen únicamente las columnas aprobadas. Los préstamos salen del mercado al dejar `financiandose`; aportantes, incluso reembolsados, conservan acceso privado. Las vistas agregadas no revelan movimientos individuales de otros prestamistas. Los borradores sin movimientos pueden eliminarse; los registros de préstamos publicados y su historial no.

Storage utiliza los buckets privados `identidad`, `negocios` y `evidencias`. Las rutas comienzan con el UUID del propietario; documentos de negocio y evidencias incluyen el UUID del negocio o etapa. Sus políticas coinciden con las de los registros. No se sobrescriben objetos; se pueden limpiar cargas propias aún no referenciadas. No se almacenan enlaces públicos permanentes ni URLs firmadas como identificadores de archivo.

Los parámetros iniciales son: `comision_originacion=2`, `comision_servicio=1`, `aporte_minimo=300`, `aporte_minimo_inicial=100`, `tope_prestamista=50`, `tasa_maxima_anual=7`, `limite_idea_nueva=3000`, `limite_en_marcha=10000` y `dias_primer_aporte=7`. Las condiciones publicadas se conservan aunque estos valores cambien.

## 8. Alcance y pendientes de otros tickets

T04 crea el esquema, restricciones, permisos, Storage, parámetros y pruebas. Los endpoints, la comprobación de transacciones Stellar, la liquidación de cancelaciones y la ejecución automática de pagos y liberaciones se implementan en sus tickets. Un hash con formato válido no demuestra por sí solo una transferencia.

Antes de automatizar etapas debe resolverse la incompatibilidad entre el objetivo de liberarlas en la primera mitad del plazo y las esperas permitidas: plazo 3/gracia 2 libera etapa 2 en mes 2, después de 1,5 meses. T04 no convierte ese objetivo contradictorio en una restricción temporal.

La conversión Bs/USDC y los pesos detallados de reputación también quedan pendientes de sus flujos. Los diagramas HU07/HU10 revisados sirven como recorrido general; las reglas y permisos actualizados de este documento son el contrato vigente.

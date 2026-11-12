# SDD en Fondea

Usaremos Specification-Driven Development para convertir el modelo de negocio en requisitos comprobables antes de construir funcionalidades.

## Flujo

1. **Contexto**: problema, usuarios, propuesta de valor y límites del producto.
2. **Especificación**: escenarios, reglas, datos, permisos y criterios de aceptación.
3. **Diseño técnico**: arquitectura Flutter, API Node.js, Supabase y decisiones registradas.
4. **Tareas**: cambios pequeños, trazables a requisitos y decisiones.
5. **Implementación y verificación**: análisis, pruebas y revisión de seguridad acordes a cada cambio.

No fijamos reglas de negocio, esquema de base de datos ni flujos de usuario hasta definir el modelo del negocio.

## Artefactos

- `product/`: visión, personas, alcance y modelo del negocio.
- `specs/`: especificaciones por capacidad o flujo.
- `design/`: arquitectura y contratos.
- `tasks/`: planes de implementación.
- `decisions/`: decisiones de arquitectura (ADR).

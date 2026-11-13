# Fondea

Aplicación móvil de Fondea, construida con Flutter. Este repositorio contiene el punto de partida del cliente móvil, un backend Node.js con TypeScript, la configuración por entorno y la documentación de producto y arquitectura.

> **Estado:** base inicial. La pantalla Flutter es de bienvenida. El backend incluye `/health`, autenticación Supabase, `/api/v1/me` y las migraciones T04 de esquema, RLS y parámetros; los flujos y endpoints de negocio están pendientes.

## Contenido

- `lib/`: aplicación Flutter y lectura de configuración de compilación.
- `config/env/`: plantillas de configuración para desarrollo y producción.
- `backend/`: servicio Express/TypeScript, integración Supabase y Stellar testnet, esquema T04 y pruebas de base de datos. Consulta su [guía de inicio](backend/README.md).
- `docs/sdd/`: proceso y plantillas de Specification-Driven Development.
- `pubspec.yaml`: dependencias y configuración del paquete Flutter.

## Requisitos

- Git.
- Flutter estable con Dart compatible con `pubspec.yaml` (`>=3.3.0 <4.0.0`).
- Para ejecutar el proyecto, un destino configurado: emulador/dispositivo Android o iOS, o un destino de escritorio/web soportado por tu instalación de Flutter.
- Node.js 24 o superior y npm para ejecutar el backend.

Comprueba la instalación con:

```bash
flutter --version
flutter doctor
```

## Inicio rápido

1. Clona el repositorio y entra al directorio:

   ```bash
   git clone https://github.com/Fer140421/FONDEA.git
   cd FONDEA
   ```

2. Instala las dependencias de Flutter:

   ```bash
   flutter pub get
   ```

3. Crea tu configuración local a partir de la plantilla:

   **PowerShell**

   ```powershell
   Copy-Item config/env/development.example.json config/env/development.json
   ```

   **macOS/Linux**

   ```bash
   cp config/env/development.example.json config/env/development.json
   ```

4. Edita `config/env/development.json` con los valores de tu proyecto. Para la plantilla, el endpoint es un marcador de posición y Supabase no está conectado todavía.
5. Inicia la aplicación en un dispositivo o emulador disponible:

   ```bash
   flutter run --dart-define-from-file=config/env/development.json
   ```

Si Flutter informa que no hay un destino o plataforma configurada, consulta `flutter devices` y habilita/crea el destino correspondiente con las herramientas oficiales de Flutter antes de ejecutar la app.

## Configuración y secretos

Para ejecutar y verificar el backend, sigue [backend/README.md](backend/README.md). Su configuración se guarda en `backend/.env` y es independiente de la configuración Flutter.

`lib/config/app_config.dart` lee `SUPABASE_URL`, `SUPABASE_ANON_KEY` y `API_BASE_URL` mediante `String.fromEnvironment`. Los valores se pasan con `--dart-define-from-file`.

- Los archivos locales `config/env/development.json` y `config/env/production.json` están ignorados por Git. Solo se versionan los archivos `.example.json`.
- Los valores `dart-define` se incorporan al binario y pueden extraerse; no son un almacén de secretos.
- En la app móvil solo deben usarse valores públicos de cliente. La clave anon/publishable de Supabase es pública por diseño y requiere políticas RLS correctamente configuradas.
- **Nunca pongas** `SUPABASE_SERVICE_ROLE_KEY`, contraseñas, tokens privados, claves de firma o credenciales de producción en Flutter, en archivos versionados ni en CI logs. Los secretos de servidor pertenecen al entorno seguro del backend.
- Si una credencial se filtra o se confirma por error, revócala/rotála en su proveedor; borrarla en un commit posterior no elimina su historial.

Para producción, prepara la configuración local `config/env/production.json` desde `production.example.json`, verifica sus valores y compila pasando ese archivo. No subas el archivo real.

## Comandos útiles

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

Las pruebas se irán agregando junto con las funcionalidades; `flutter test` puede no encontrar pruebas todavía.

## Flujo de ramas

- `main`: versión estable/publicable. Entra código revisado y listo para entrega.
- `develop`: integración del trabajo en curso; es la base habitual de las ramas de funcionalidad.
- `feature/<tema>`: funcionalidades nuevas, por ejemplo `feature/registro`.
- `fix/<tema>`: correcciones, por ejemplo `fix/validacion-formulario`.
- `hotfix/<tema>`: arreglo urgente sobre producción, cuando exista una versión publicada.

Flujo recomendado: crea una rama corta desde `develop`, realiza commits pequeños, abre un Pull Request hacia `develop` y revisa los cambios. Cuando `develop` esté listo para una entrega, abre un Pull Request hacia `main` y etiqueta la versión. No es necesario crear una rama por cada cambio minúsculo; sí conviene aislar cada tarea que se pueda revisar y entregar por separado.

Ejemplo:

```bash
git switch develop
git pull origin develop
git switch -c feature/nombre-cambio
# realiza cambios y commits
git push -u origin feature/nombre-cambio
```

## Documentación de producto (SDD)

El proyecto usa Specification-Driven Development para definir requisitos comprobables antes de implementar funcionalidades. Consulta [`docs/sdd/README.md`](docs/sdd/README.md). Las carpetas `product/`, `specs/`, `design/`, `tasks/` y `decisions/` organizan contexto de producto, especificaciones, arquitectura, tareas y decisiones técnicas.

## Contribuir

1. Parte de `develop` y crea una rama `feature/` o `fix/`.
2. Mantén los cambios enfocados y actualiza la documentación cuando cambie el comportamiento o la configuración.
3. Ejecuta `dart format .`, `flutter analyze` y las pruebas pertinentes.
4. Revisa el diff para detectar archivos locales, credenciales o artefactos de compilación antes de abrir el Pull Request.
5. Solicita revisión antes de integrar en `develop`; integra a `main` mediante una entrega revisada.

## Licencia

Aún no se ha definido una licencia para este proyecto. Todos los derechos quedan reservados mientras no se agregue una licencia explícita.

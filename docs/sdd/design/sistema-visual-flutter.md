# Sistema visual Flutter de Fondea

Esta base implementa los fundamentos del [kit UI en Figma](https://www.figma.com/design/4r91rOBcioYTgxk6Q0GCVr/Fondea?node-id=0-1). Las referencias principales son la [guía de estilos](https://www.figma.com/design/4r91rOBcioYTgxk6Q0GCVr/Fondea?node-id=5-5), la [biblioteca](https://www.figma.com/design/4r91rOBcioYTgxk6Q0GCVr/Fondea?node-id=24-638), [Fondea/Botón](https://www.figma.com/design/4r91rOBcioYTgxk6Q0GCVr/Fondea?node-id=24-668) y [Fondea/Campo](https://www.figma.com/design/4r91rOBcioYTgxk6Q0GCVr/Fondea?node-id=24-785).

## Aplicación en el proyecto

El cliente es Flutter. Tailwind CSS aparece en el código de referencia que devuelve Figma, pero sus clases no estilizan widgets Flutter. El tema y los tokens están en `lib/design_system/`:

| Archivo | Responsabilidad |
| --- | --- |
| `fondea_colors.dart` | Paleta de marca, superficies y estados. |
| `fondea_typography.dart` | Jerarquía de texto y fuente Inter. |
| `fondea_spacing.dart` y `fondea_radius.dart` | Medidas reutilizables. |
| `fondea_sizes.dart` | Altura común de los controles. |
| `fondea_theme.dart` | Mapeo de tokens a `ThemeData` y controles Material. |
| `widgets/fondea_button.dart` | Botones primario, secundario, deshabilitado y cargando. |
| `widgets/fondea_text_field.dart` | Campo con etiqueta, ayuda y error. |

Las pantallas pueden importar `package:fondea/design_system/design_system.dart` como punto de entrada a la API visual.

`lib/main.dart` aplica `FondeaTheme.light`. La fuente Inter se distribuye en `assets/fonts/` con su licencia. Es la versión 4.1 obtenida de la [distribución oficial de Inter](https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip).

## Tokens principales

| Uso | Valor de Figma |
| --- | --- |
| Primario y texto principal | `#14324B` |
| Secundario | `#0F766E` |
| Acento | `#2DD4BF` |
| Fondo | `#F5F8FC` |
| Superficie | `#FFFFFF` |
| Borde | `#DCE5EE` |
| Advertencia | `#B45309` |
| Error | `#B42318` |
| Deshabilitado | `#E5EDF3` |

Los botones del kit miden 52 px de alto y tienen radio de 14 px. Los campos usan radio de 12 px y estados normal, enfocado y error. Las medidas de pantalla se adaptarán al espacio disponible en Flutter; no deben fijarse al ancho de 390 px de los marcos Android de Figma.

## Convenciones para el equipo

1. Reutilizar `FondeaTheme`, los tokens y los widgets compartidos al crear una pantalla.
2. Si un componente necesita una variante nueva, añadirla al componente compartido y verificarla contra el nodo de Figma correspondiente.
3. Mantener textos de negocio, validación y navegación en la funcionalidad; el sistema visual solo expresa presentación y estados.
4. Incorporar los demás componentes del kit cuando una historia los necesite. Esta base prepara los controles comunes para HU01; no afirma que toda la biblioteca esté implementada.
5. Verificar cada pantalla en un Android real antes de marcar su ticket como terminado.

El kit disponible define una apariencia clara. Un tema oscuro requerirá diseños y tokens propios antes de añadirse.

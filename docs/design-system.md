# Design System — Planify

Este documento es la **fuente de verdad versionada** de los tokens de diseño de la app Flutter. Si existe un diseño aprobado posterior en Figma que modifica algún valor, **este documento se actualiza primero**, antes de tocar el código.

- **Referencia funcional y visual:** [Design System](https://www.figma.com/design/0WRCDg9IXpespwQL97utp9/Planify-Design-System?node-id=0-1&p=f&t=2w6tj7IPHZrKMd66-0)
- **Ubicación de la implementación:** `lib/core/theme/`

---

## 1. Color de marca

| Token | Valor | Uso |
|---|---|---|
| `primary` | `#296CF2` | Color principal de marca. Botones primarios, elementos de acción destacados. |
| `secondary` | `#92C2FC` | Color secundario de marca. Elementos de apoyo, acentos suaves. |
| `lightBlue` / `primaryContainer` | `#DBEAFE` | Contenedor asociado a `primary`. Fondos de tarjetas o superficies destacadas. |
| `background` / `secondaryContainer` | `#ECF4FF` | Fondo general de superficies secundarias. |
| `accent` / `tertiary` | `#FF6B6B` | Color de acento. Llamadas de atención puntuales, badges. |
| `darkBlue` / `onPrimaryContainer` | `#3E579C` | Texto/íconos sobre `primaryContainer`. Usado también en tipografía de títulos. |

## 2. Color base y semántico

| Token | Valor | Uso |
|---|---|---|
| `error` | `#CC5A5A` | Estados de error. |
| `success` | `#3FA873` | Estados de éxito/confirmación. |
| `warning` | `#E3A94A` | Estados de advertencia. |
| `danger` | `#E74C3C` | Estados críticos/peligro. |
| `surface` | `#FFFFFF` | Superficie base de la app (fondos de pantallas y componentes). |
| `textPrimary` / `onSurface` | `#14162B` | Texto principal sobre `surface`. |
| `textSecondary` / `onSurfaceVariant` | `#6B7280` | Texto secundario/auxiliar. |
| `outline` / `border` | `#DBEAFE` | Bordes y separadores. |

## 3. ColorScheme Material 3 (light)

| Rol M3 | Valor | Rol "on" | Valor |
|---|---|---|---|
| `primary` | `#296CF2` | `onPrimary` | `#FFFFFF` |
| `primaryContainer` | `#DBEAFE` | `onPrimaryContainer` | `#3E579C` |
| `secondary` | `#92C2FC` | `onSecondary` | `#3E579C` |
| `secondaryContainer` | `#ECF4FF` | `onSecondaryContainer` | `#3E579C` |
| `tertiary` | `#FF6B6B` | `onTertiary` | `#FFFFFF` |
| `error` | `#CC5A5A` | `onError` | `#FFFFFF` |
| `surface` | `#FFFFFF` | `onSurface` | `#14162B` |
| `surfaceContainerHighest` | `#DBEAFE` | `onSurfaceVariant` | `#6B7280` |

> **Nota:** `tertiaryContainer` y `errorContainer` **no** se definen como hex fijos. Se derivan en runtime con `Color.lerp` (mezcla de `tertiary`/`error` con blanco) para evitar duplicar valores hardcodeados. Ver implementación en `lib/core/theme/app_theme.dart`.

### Colores semánticos adicionales (`AppColors`)

Además del `ColorScheme` de Material 3, se exponen los colores semánticos (`success`, `warning`, `danger`) junto con sus contrapartes `on*` (todas blancas) directamente en `AppColors`, para uso en componentes que no encajan en los roles estándar de M3 (ej. chips de estado, banners).

---

## 4. Tipografía

**Familia:** Poppins (Google Fonts), aplicada sobre la escala tipográfica de Material 3.

| Escala | Tamaño / Alto de línea | Peso |
|---|---|---|
| Display Large | 57 / 64 | Regular |
| Display Medium | 45 / 52 | Regular |
| Display Small | 36 / 44 | Regular |
| Headline Large | 32 / 40 | Regular |
| Headline Medium | 28 / 36 | Regular |
| Headline Small | 24 / 32 | Regular |
| Title Large | 22 / 28 | 400 |
| Title Medium | 16 / 24 | 500 |
| Title Small | 14 / 20 | 500 |
| Body Large | 16 / 24 | Regular |
| Body Medium | 14 / 20 | Regular |
| Body Small | 12 / 16 | Regular |
| Label Large | 14 / 20 | Regular |
| Label Medium | 12 / 16 | Regular |
| Label Small | 11 / 16 | 500 |

**Reglas de color de texto:**
- Títulos (Display, Headline, Title) → `onPrimaryContainer`
- Cuerpo (Body) → `onSurface`
- Texto secundario (Label) → `onSurfaceVariant`

Implementación: `lib/core/theme/app_typography.dart`

---

## 5. Espaciado (grid 4pt)

| Token | Valor |
|---|---|
| `xs` | 4 |
| `sm` | 8 |
| `md` | 16 |
| `lg` | 24 |
| `xl` | 32 |
| `xxl` | 48 |

Implementación: `lib/core/theme/app_spacing.dart`

## 6. Radios

| Token | Valor | Uso |
|---|---|---|
| `sm` | 8 | Elementos pequeños (chips, tags). |
| `card` | 16 | Tarjetas. |
| `lg` | 20 | Contenedores grandes. |
| `xl` | 28 | Modales, bottom sheets. |
| `bar` | 24 | Barras de navegación / búsqueda. |
| `pill` | 999 | Elementos tipo píldora (botones redondeados por completo). |

Implementación: `lib/core/theme/app_radius.dart`

## 7. Dimensiones base

| Token | Valor |
|---|---|
| Botón mínimo (alto) | 52 |
| Padding de input | 16 |
| Elevación de card | 1 |

Implementación: `lib/core/theme/app_radius.dart` (`AppDimens`)

---

## 8. Convención de uso

- Los widgets **nunca** deben usar valores hardcodeados de color, tipografía, spacing o radios.
- Todo consumo de estos tokens se hace a través de `Theme.of(context)` (para color/tipografía) o de las clases estáticas `AppSpacing` / `AppRadius` / `AppDimens` (para spacing, radios y dimensiones).
- Ante cualquier discrepancia entre este documento y una implementación en código, **prevalece este documento** — y debe corregirse el código, no al revés.
- Ante un diseño aprobado posterior en Figma que modifique un token, el flujo es: 1) actualizar Figma (fuente de diseño), 2) actualizar este documento, 3) actualizar la implementación en `lib/shared/theme/`.

---

## 9. Referencias

- **Figma — Planify Design System:** _(completar con el link definitivo del equipo de diseño)_
- **Ticket de origen:** PLANIFY-132 — Núcleo Flutter: arquitectura, tema, i18n y cliente API
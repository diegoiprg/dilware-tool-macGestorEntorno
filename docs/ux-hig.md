# Análisis UX/UI — Apple Human Interface Guidelines — macSpaces v2.11.0

## Tabla de contenido

- [Contexto](#contexto)
- [Estado actual vs HIG](#estado-actual-vs-hig)
  - [Resueltos](#resueltos)
  - [Buenas prácticas implementadas](#buenas-prácticas-implementadas)
  - [Mejoras pendientes](#mejoras-pendientes)
- [Arquitectura UX](#arquitectura-ux)
- [Decisiones de diseño del overlay](#decisiones-de-diseño-del-overlay)

---

## Contexto

macSpaces es una menubar app con dos íconos independientes: menú principal (entorno) y menú de enfoque (productividad). Incluye un overlay flotante persistente con filas coloreadas por estado activo.

---

## Estado actual vs HIG

### Resueltos

| ID | Hallazgo | Resolución |
|---|---|---|
| UX-01 | Ícono emoji → template image | Soporta template image desde `macspaces_icon.png` y `macspaces_focus_icon.png`. Fallback a emoji. |
| UX-02 | Sin feedback de perfil activo | `checked` nativo + `● / ○` + tiempo activo inline |
| UX-02b | Ítems no accionables parecen clicables | `utils.disabled_item()` con `disabled = true` |
| UX-03 | Menú demasiado largo | Submenús semánticos + menú de enfoque separado (~8 ítems primer nivel) |
| UX-04 | SF Symbols vs emojis | Unificado a emojis en todo el menú |
| UX-05 | Atajos no visibles | `⌘⌥1` / `⌘⌥2` junto al nombre del perfil |
| UX-06 | Pomodoro sin countdown | Countdown en overlay flotante con fase y ciclo |
| UX-07 | Sin confirmación al desactivar | `hs.dialog.blockAlert` configurable por perfil |
| UX-08 | Navegador global | Guarda/restaura navegador previo al activar/desactivar perfil |
| UX-09 | Batería sin submenú | Submenú con porcentaje, estado, ciclos, tiempo restante |
| UX-10 | Idioma mezclado | UI consistente en español |
| UX-11 | Incentivar descanso activo | Activado por defecto, countdown visible en overlay |
| UX-12 | Tips educativos en Pomodoro | Datos rotativos sobre productividad y neurociencia en cada notificación |

---

### Buenas prácticas implementadas

| Práctica | Detalle |
|---|---|
| Menú pre-construido | `setMenu(items)` — apertura instantánea, reconstrucción en segundo plano cada 5s |
| Dos menús con propósito claro | Principal = entorno, Enfoque = concentración |
| Overlay flotante no invasivo | Semi-transparente, esquina inferior derecha, auto-oculta, arrastrable |
| Posición del overlay persistida | Guardada en `overlay_pos.json`, restaurada entre reinicios |
| Filas coloreadas por estado | Rojo (trabajo), verde (pausa), azul (descanso pendiente), verde (descanso activo), púrpura (presentación), semáforo (Claude) |
| Barra de progreso con `▰▱` | Mejor alineación visual que `█░`; alineada con Apple HIG |
| Modo compacto en MacBook | Las filas de Claude omiten barra de progreso en MacBook para evitar solapamiento con el Dock |
| Detección automática de dispositivo | `IS_MACBOOK` vía `hs.host.localizedName()` — modo compacto sin configuración manual |
| Datos educativos en notificaciones | Rotativos, con fuentes (AAO, OSHA, Cirillo, Mayo Clinic, AHA, EFSA, Harvard Med) |
| Descanso activo por defecto | Opt-out en lugar de opt-in — el usuario debe desactivarlo conscientemente |
| Tiempo hasta el próximo descanso visible | Presión visual positiva para tomar pausas |
| Checkmarks en selección | Navegador, audio, intervalos de descanso |
| Separadores semánticos | Agrupación visual por categoría en todos los submenús |
| Feedback via notificaciones | Acciones importantes notifican al usuario vía `hs.notify` |
| Ocultamiento condicional | VPN, batería, lanzador solo aparecen cuando aplican |
| Pre-calentamiento de cachés | Timer cada 30s mantiene datos frescos |
| Notificaciones llamativas | `alert_notify()`: canvas flotante grande + sonido del sistema "Glass" + notificación estándar |

---

### Mejoras pendientes

| ID | Hallazgo | Nota |
|---|---|---|
| UX-01 | Template image | Funcional, pero el usuario debe proveer la imagen 18×18pt monocromática |
| PREM-04 | Transiciones suaves | Investigar animaciones y feedback sonoro adicional |
| PREM-07 | Historial enriquecido | Gráfico semanal, exportar CSV, resumen diario |

---

## Arquitectura UX

```
┌─────────────────────────────────────────────┐
│              Menubar de macOS               │
│  ┌──────────┐  ┌──────────┐                │
│  │ ⌘ Menú   │  │ ◎ Menú   │                │
│  │ principal │  │ enfoque  │                │
│  └────┬─────┘  └────┬─────┘                │
│       │              │                       │
│  Perfiles        Pomodoro                    │
│  Entorno         Descanso activo             │
│  Dispositivos    Presentación                │
│  Red                 │                       │
│  Portapapeles   ┌────▼─────┐                │
│  Claude         │ Overlay  │                │
│  Historial      │ flotante │                │
│  Sistema        └──────────┘                │
└─────────────────────────────────────────────┘
```

Principio de diseño: cada menú tiene un propósito único. El usuario no necesita navegar submenús para acceder a funciones de enfoque, y el menú principal no se contamina con estado temporal (countdowns, fases). El overlay es el canal pasivo de información — siempre visible, no interactivo salvo para reposicionar.

---

## Decisiones de diseño del overlay

### Por qué un overlay separado del ícono de menú

Los íconos de menubar tienen espacio limitado y pueden colisionar con otros ítems del sistema. Un overlay flotante con `hs.canvas` permite mostrar múltiples estados simultáneos (Pomodoro + breaks + Claude) sin restricciones de espacio.

### Por qué filas independientes y no un string concatenado

Cada estado tiene su propio ciclo de vida, color y lógica de visibilidad. Filas independientes permiten mostrar, ocultar y colorear cada estado sin afectar a los demás.

### Por qué persistir la posición en disco

El usuario elige la posición del overlay según su configuración de pantalla. Sin persistencia, tendría que reposicionarlo manualmente tras cada recarga de Hammerspoon.

### Por qué modo compacto en MacBook

En MacBook, el Dock se superpone a la esquina inferior. El formato compacto omite la barra de progreso (`▰▱`) y reduce el ancho del overlay para evitar solapamiento sin sacrificar la información esencial (porcentaje y tiempo de reset).

### Por qué `▰▱` en lugar de `█░`

Los caracteres `▰▱` tienen mejor alineación visual en la fuente del sistema (`.AppleSystemUIFont`) y mayor contraste. Están disponibles en Unicode sin dependencias de fuentes externas, alineados con la estética de Apple HIG.

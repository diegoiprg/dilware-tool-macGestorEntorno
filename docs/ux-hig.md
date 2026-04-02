# Análisis UX/UI — Apple Human Interface Guidelines — macSpaces v2.8.0

## Contexto

macSpaces es una menubar app con dos íconos independientes: menú principal (entorno) y menú de enfoque (productividad). Incluye un overlay flotante persistente.

---

## Estado actual vs HIG

### ✅ Resueltos

| ID | Hallazgo | Resolución |
|---|---|---|
| UX-01 | Ícono emoji → template image | Soporta template image desde `macspaces_icon.png`. Fallback a emoji. |
| UX-02 | Sin feedback de perfil activo | `checked` nativo + `● / ○` + tiempo activo inline |
| UX-02b | Ítems no accionables parecen clicables | `utils.disabled_item()` con `disabled = true` |
| UX-03 | Menú demasiado largo | Submenús semánticos + menú de enfoque separado (~8 ítems primer nivel) |
| UX-04 | SF Symbols vs emojis | Unificado a emojis |
| UX-05 | Atajos no visibles | `⌘⌥1` / `⌘⌥2` junto al nombre |
| UX-06 | Pomodoro sin countdown | Countdown en ícono de enfoque + overlay flotante |
| UX-07 | Sin confirmación al desactivar | `hs.dialog.blockAlert` configurable |
| UX-08 | Navegador global | Guarda/restaura navegador previo |
| UX-09 | Batería sin submenú | Submenú con porcentaje, estado, ciclos, tiempo |
| UX-10 | Idioma mezclado | UI consistente en español |

### 🟢 Buenas prácticas implementadas

| Práctica | Detalle |
|---|---|
| Menú pre-construido | `setMenu(items)` — apertura instantánea, reconstrucción en segundo plano |
| Dos menús con propósito claro | Principal = entorno, Enfoque = concentración |
| Overlay flotante no invasivo | Semi-transparente, esquina inferior derecha, auto-oculta, arrastrable |
| Filas coloreadas por estado | Rojo (trabajo), verde (pausa), azul (descanso), púrpura (presentación) |
| Datos educativos en notificaciones | Rotativos, con fuentes (AAO, OSHA, Cirillo, etc.) |
| Descanso activo por defecto | Opt-out en lugar de opt-in |
| Tiempo sin descanso visible | Presión visual positiva para tomar pausas |
| Checkmarks en selección | Navegador, audio, intervalos |
| Separadores semánticos | Agrupación visual por categoría |
| Feedback via notificaciones | Acciones importantes notifican al usuario |
| Ocultamiento condicional | VPN, batería, lanzador solo cuando aplica |
| Pre-calentamiento de cachés | Timer cada 30s mantiene datos frescos |

### 🟡 Mejoras pendientes (baja prioridad)

| ID | Hallazgo | Nota |
|---|---|---|
| UX-01 | Template image | Funcional, pero el usuario debe proveer la imagen 18×18pt |
| PREM-04 | Transiciones suaves | Investigar animaciones y feedback sonoro |
| PREM-07 | Historial enriquecido | Gráfico semanal, exportar CSV |

---

## Arquitectura UX

```
┌─────────────────────────────────────────────┐
│              Menubar de macOS               │
│  ┌──────────┐  ┌──────────┐                │
│  │ ⌘ Menú   │  │ 🧘 Menú  │                │
│  │ principal │  │ enfoque  │                │
│  └────┬─────┘  └────┬─────┘                │
│       │              │                       │
│  Perfiles        Pomodoro                    │
│  Entorno         Descanso                    │
│  Dispositivos    Presentación                │
│  Red                 │                       │
│  Portapapeles   ┌────▼─────┐                │
│  Historial      │ Overlay  │                │
│  Sistema        │ flotante │                │
│                 └──────────┘                │
└─────────────────────────────────────────────┘
```

Principio de diseño: cada menú tiene un propósito único. El usuario no necesita navegar submenús para acceder a funciones de enfoque, y el menú principal no se contamina con estado temporal (countdowns, fases).

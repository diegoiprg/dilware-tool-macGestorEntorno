# Arquitectura — macSpaces v2.11.0

## Tabla de contenido

- [Visión general](#visión-general)
- [Diagrama de componentes](#diagrama-de-componentes)
- [Estructura de archivos](#estructura-de-archivos)
- [Patrones de diseño](#patrones-de-diseño)
- [Flujo de inicio](#flujo-de-inicio)
- [Persistencia](#persistencia)
- [Dependencias externas](#dependencias-externas)
- [Limitaciones arquitectónicas](#limitaciones-arquitectónicas)

---

## Visión general

macSpaces es una herramienta de barra de menú para macOS construida sobre [Hammerspoon](https://www.hammerspoon.org). Se ejecuta como módulos Lua cargados al inicio de Hammerspoon, sin proceso propio ni empaquetado `.app`. Presenta dos menús independientes en la menubar y un overlay flotante persistente.

---

## Diagrama de componentes

```
┌──────────────────────────────────────────────────────────────────┐
│                        Hammerspoon (host)                        │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                        init.lua                          │   │
│  │  validación · prewarm · hotkeys · caffeinate · shutdown  │   │
│  └──────────────────┬───────────────────┬────────────────────┘   │
│                     │                   │                         │
│  ┌──────────────────▼──────┐  ┌─────────▼──────────────────┐    │
│  │        menu.lua         │  │      focus_menu.lua         │    │
│  │    (menú principal)     │  │    (menú de enfoque)        │    │
│  │   setMenu · timer 5s    │  │   setMenu · timer 5s        │    │
│  └──┬──┬──┬──┬──┬──┬──┬───┘  └──┬──────┬──────┬───────────┘    │
│     │  │  │  │  │  │  │         │      │      │                  │
│     ▼  ▼  ▼  ▼  ▼  ▼  ▼         ▼      ▼      ▼                 │
│  ┌──────────────────────┐     ┌──────┬───────┬────────┐         │
│  │ profiles  browsers   │     │pomo- │breaks │presen- │         │
│  │ audio     music      │     │doro  │       │tation  │         │
│  │ battery   bluetooth  │     └──────┴───────┴────────┘         │
│  │ network   vpn        │              │                          │
│  │ clipboard launcher   │     ┌────────▼──────────────────┐     │
│  │ history   claude     │     │      focus_overlay.lua     │     │
│  └──────────────────────┘     │  canvas · drag · persist   │     │
│                               │  pomodoro · breaks        │     │
│                               │  presentation · claude    │     │
│                               └───────────────────────────┘     │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              config.lua · utils.lua · dnd.lua             │  │
│  │                  (infraestructura compartida)              │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
         │                  │                  │
         ▼                  ▼                  ▼
   ┌──────────┐      ┌────────────┐      ┌──────────────┐
   │  macOS   │      │  ipapi.co  │      │ Disco local  │
   │  APIs    │      │  (HTTPS)   │      │ JSON / log   │
   └──────────┘      └────────────┘      └──────────────┘
```

---

## Estructura de archivos

```
~/.hammerspoon/
├── init.lua                      ← Punto de entrada, validación, prewarm
├── set_browser                   ← Binario compilado (helper Swift)
├── macspaces_icon.png            ← Ícono template del menú principal (opcional)
├── macspaces_focus_icon.png      ← Ícono template del menú de enfoque (opcional)
├── overlay_pos.json              ← Posición persistida del overlay (generado)
├── macspaces_history.json        ← Historial de sesiones (generado)
├── debug.log                     ← Log de depuración (generado)
└── macspaces/
    ├── config.lua                ← Configuración central (editable por el usuario)
    ├── utils.lua                 ← Log, notificaciones, alert canvas, helpers
    ├── menu.lua                  ← Menú principal (entorno)
    ├── focus_menu.lua            ← Menú de enfoque (Pomodoro, descanso, presentación)
    ├── focus_overlay.lua         ← Banner flotante persistente (hs.canvas)
    ├── profiles.lua              ← Espacios virtuales y ciclo de vida de perfiles
    ├── browsers.lua              ← Navegador predeterminado (helper Swift)
    ├── set_browser.swift         ← Fuente del helper nativo (NSWorkspace)
    ├── audio.lua                 ← Dispositivo de salida de audio
    ├── music.lua                 ← Control de Apple Music (AppleScript)
    ├── battery.lua               ← Estado de batería (solo MacBook)
    ├── bluetooth.lua             ← Dispositivos BT con batería (ioreg)
    ├── network.lua               ← Info de red e IP externa (ipapi.co)
    ├── vpn.lua                   ← Detección de VPN y geolocalización del túnel
    ├── clipboard.lua             ← Historial del portapapeles (memoria)
    ├── pomodoro.lua              ← Temporizador Pomodoro con fases
    ├── breaks.lua                ← Recordatorios de descanso activo
    ├── presentation.lua          ← Modo presentación (DND + Dock + escritorio)
    ├── launcher.lua              ← Lanzador rápido de apps
    ├── history.lua               ← Registro persistido de sesiones por perfil
    ├── hotkeys.lua               ← Atajos de teclado globales
    ├── dnd.lua                   ← Control de No Molestar
    └── claude.lua                ← Monitor de uso de Claude Code
```

---

## Patrones de diseño

### Módulo Lua como singleton

Cada archivo retorna una tabla `M` con funciones públicas. El estado se mantiene en variables locales (closures). `require()` cachea módulos, garantizando una sola instancia por sesión de Hammerspoon.

### Menú pre-construido con setMenu(tabla)

Ambos menús usan `setMenu(items)` con una tabla pre-construida. La reconstrucción ocurre cada 5 segundos en segundo plano via `hs.timer.doEvery(5, ...)`, no al hacer clic. Esto garantiza apertura instantánea sin bloqueo del hilo principal.

### Pre-calentamiento de cachés

`init.lua` ejecuta un timer cada 30 segundos que llama los módulos costosos (`bluetooth.devices()`, `browsers.installed()`, `browsers.current()`, `music.is_running()`, `battery.has_battery()`) para mantener sus cachés calientes.

### Caché con TTL

Módulos con datos costosos usan caché temporal:

| Módulo | TTL | Dato cacheado |
|---|---|---|
| bluetooth.lua | 120s | Dispositivos via ioreg |
| vpn.lua (interfaces) | 10s | Interfaces activas |
| vpn.lua (info remota) | 120s | Geolocalización del túnel |
| network.lua | 60s | IP externa via ipapi.co |
| audio.lua | 10s | Dispositivos de salida |
| battery.lua | Permanente | `has_battery()` |
| music.lua | 3s | `is_running`, `is_playing`, `get_current_track` |
| claude.lua | 60s | Datos de `usage_cache.json` |

### Overlay flotante con hs.canvas

`focus_overlay.lua` usa `hs.canvas` para un banner unificado con filas coloreadas por estado, visible en todos los espacios (`canJoinAllSpaces + stationary`). Se recrea completamente cada segundo para garantizar refresco visual. Arrastrable via `hs.eventtap` (`leftMouseDragged` + `leftMouseUp`).

La posición persiste en disco (`overlay_pos.json`) y se restaura al iniciar. La detección del tipo de dispositivo (`IS_MACBOOK`) ocurre una vez al cargar el módulo para habilitar el modo compacto en MacBook.

### Reloj de pared para contadores

Pomodoro y breaks usan `os.time()` como base de sus contadores (`phase_started`, `next_break_at`, `break_end_at`). El tiempo restante se calcula como diferencia respecto al tiempo actual, no acumulando segundos con el timer. Esto garantiza precisión independientemente de la frecuencia del tick y tras suspensión del sistema.

### Callbacks asíncronos encadenados

La activación de perfiles encadena `hs.timer.doAfter()` con delays configurables (`cfg.delay.short`, `cfg.delay.medium`, `cfg.delay.app_launch`) para dar tiempo al sistema operativo entre operaciones de espacios y lanzamiento de apps.

### Configuración centralizada

`config.lua` es el único archivo que el usuario debe editar. Todos los módulos lo importan via `require("macspaces.config")`. Cambios requieren recarga (⌘R en Hammerspoon).

---

## Flujo de inicio

```
Hammerspoon → init.lua
  1. Configura package.path (sin duplicados en recargas)
  2. Carga y valida config.lua (VERSION, delay, profile_order, profiles)
  3. Si validación falla: notifica y aborta
  4. Limpia debug.log, registra versión
  5. Compila set_browser.swift si el binario no existe
  6. Inicia clipboard.start() (watcher event-driven)
  7. Refresca network y VPN en segundo plano (asíncrono)
  8. Registra hotkeys globales (hotkeys.register)
  9. Inicializa menú principal (menu.init)
 10. Inicializa menú de enfoque (focus_menu.init)
     └─ focus_menu.init llama breaks.init() y overlay.start()
 11. Pre-calienta cachés costosos (diferido 1s)
 12. Inicia timer de prewarm cada 30s
 13. Registra hs.caffeinate.watcher (wake detection)
 14. Registra hs.shutdownCallback (limpieza al cerrar/reiniciar/recargar)
```

---

## Persistencia

| Dato | Ubicación | Formato | Permisos |
|---|---|---|---|
| Historial de sesiones | `~/.hammerspoon/macspaces_history.json` | JSON | 0600 |
| Posición del overlay | `~/.hammerspoon/overlay_pos.json` | JSON | No restringido |
| Log de depuración | `~/.hammerspoon/debug.log` | Texto plano | 0600 |
| Portapapeles | Solo memoria | — | — |
| Estado de perfiles | Solo memoria | — | — |
| Estado de Pomodoro | Solo memoria | — | — |
| Cache de Claude | `~/.claude/usage_cache.json` (externo) | JSON | Gestionado externamente |

---

## Dependencias externas

| Dependencia | Tipo | Versión mínima | Uso |
|---|---|---|---|
| Hammerspoon | Runtime | 0.9.97+ | Host, APIs de macOS |
| Swift compiler (`swiftc`) | Build-time | Xcode CLI tools | Compilar `set_browser` |
| ipapi.co | API HTTPS | — | IP externa y geolocalización |
| `ioreg` | Binario macOS | — | Datos de dispositivos Bluetooth |
| `defaults` | Binario macOS | — | Dock, Finder, DND (fallback) |
| AppleScript / `hs.applescript` | Runtime macOS | — | Control de Apple Music |

La API `hs.focus` (DND nativa) requiere Hammerspoon 0.9.97+. Si no está disponible, `dnd.lua` usa el fallback via `defaults`.

---

## Limitaciones arquitectónicas

1. **Sin proceso propio**: depende de que Hammerspoon esté corriendo.
2. **Sin hot-reload de config**: cambios en `config.lua` requieren ⌘R; se pierde el estado de perfiles, Pomodoro y portapapeles.
3. **Coordinación por timers**: delays fijos para operaciones de espacios, no basados en eventos del sistema.
4. **Estado volátil**: perfiles activos, portapapeles y estado de Pomodoro no persisten entre recargas.
5. **Monopantalla**: `hs.screen.mainScreen()` y `primaryScreen()` asumen una pantalla principal. Multi-monitor no está soportado.
6. **Dependencia de fuente externa para Claude**: `usage_cache.json` debe ser generado por `statusline.sh`; sin él, la fila de Claude no aparece en el overlay.

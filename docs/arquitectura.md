# Arquitectura — macSpaces v2.7.0

## Visión general

macSpaces es una herramienta de barra de menú para macOS construida sobre [Hammerspoon](https://www.hammerspoon.org). Se ejecuta como módulos Lua cargados al inicio, sin proceso propio ni empaquetado `.app`. Presenta dos menús independientes en la menubar y un overlay flotante opcional.

## Diagrama de componentes

```
┌──────────────────────────────────────────────────────────────┐
│                      Hammerspoon (host)                      │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                      init.lua                          │  │
│  │       (punto de entrada, validación, prewarm)          │  │
│  └──────────┬──────────────────────┬─────────────────────┘  │
│             │                      │                         │
│  ┌──────────▼──────────┐  ┌───────▼──────────────────┐     │
│  │      menu.lua       │  │    focus_menu.lua         │     │
│  │  (menú principal)   │  │  (menú de enfoque)        │     │
│  │  setMenu(items)     │  │  setMenu(items)           │     │
│  └──┬──┬──┬──┬──┬──┬──┘  └──┬──────┬──────┬─────────┘     │
│     │  │  │  │  │  │        │      │      │                 │
│     ▼  ▼  ▼  ▼  ▼  ▼        ▼      ▼      ▼                │
│  ┌─────┬─────┬─────┐    ┌─────┬──────┬──────┐              │
│  │prof.│brow.│audio│    │pomo.│breaks│pres. │              │
│  ├─────┼─────┼─────┤    └─────┴──────┴──────┘              │
│  │music│batt.│bluet│         │                              │
│  ├─────┼─────┼─────┤    ┌────▼───────────────┐              │
│  │netw.│ vpn │clip.│    │  focus_overlay.lua  │              │
│  ├─────┼─────┼─────┤    │  (banner flotante)  │              │
│  │laun.│hist.│hotk.│    └────────────────────┘              │
│  └─────┴─────┴─────┘                                        │
│             │                                                │
│  ┌──────────▼────────────────────────────────────────────┐  │
│  │              config.lua  ·  utils.lua  ·  dnd.lua      │  │
│  └───────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
         │              │              │
         ▼              ▼              ▼
   ┌──────────┐  ┌───────────┐  ┌──────────┐
   │ macOS    │  │ ipapi.co  │  │ ioreg    │
   │ APIs     │  │ (HTTPS)   │  │ defaults │
   └──────────┘  └───────────┘  └──────────┘
```

## Estructura de archivos

```
~/.hammerspoon/
├── init.lua                    ← Punto de entrada, prewarm de cachés
└── macspaces/
    ├── config.lua              ← Configuración central (editable)
    ├── utils.lua               ← Log, notificaciones, helpers
    ├── menu.lua                ← Menú principal (entorno)
    ├── focus_menu.lua          ← Menú de enfoque (Pomodoro, descanso, presentación)
    ├── focus_overlay.lua       ← Banner flotante persistente (hs.canvas)
    ├── profiles.lua            ← Espacios virtuales y perfiles
    ├── browsers.lua            ← Navegador predeterminado
    ├── audio.lua               ← Dispositivo de salida de audio
    ├── music.lua               ← Control de Apple Music (AppleScript)
    ├── battery.lua             ← Estado de batería (solo MacBook)
    ├── bluetooth.lua           ← Dispositivos BT (ioreg)
    ├── network.lua             ← Info de red e IP externa
    ├── vpn.lua                 ← Detección de VPN
    ├── clipboard.lua           ← Historial del portapapeles
    ├── pomodoro.lua            ← Temporizador Pomodoro
    ├── breaks.lua              ← Recordatorios de descanso
    ├── presentation.lua        ← Modo presentación
    ├── launcher.lua            ← Lanzador rápido de apps
    ├── history.lua             ← Registro de sesiones
    ├── hotkeys.lua             ← Atajos de teclado globales
    └── dnd.lua                 ← Control de No Molestar
```

## Patrones de diseño

### Módulo Lua como singleton

Cada archivo retorna una tabla `M` con funciones públicas. El estado se mantiene en variables locales (closures). `require()` cachea módulos, garantizando una sola instancia.

### Menú pre-construido

Ambos menús usan `setMenu(items)` con una tabla pre-construida. La reconstrucción ocurre cada 5 segundos en segundo plano, no al hacer clic. Esto garantiza apertura instantánea.

### Pre-calentamiento de cachés

`init.lua` ejecuta un timer cada 30 segundos que llama a los módulos costosos (`bluetooth.devices()`, `browsers.installed()`, `music.is_running()`, `battery.has_battery()`) para mantener sus cachés calientes.

### Caché con TTL

Módulos con datos costosos usan caché temporal:

| Módulo | TTL | Dato |
|---|---|---|
| bluetooth | 120s | Dispositivos ioreg |
| vpn | 10s | Interfaces, is_active |
| network | 60s | IP externa |
| audio | 10s | Dispositivos |
| battery | permanente | has_battery |
| music | 3s | is_running |

### Overlay flotante (hs.canvas)

`focus_overlay.lua` usa `hs.canvas` para un banner semi-transparente visible en todos los espacios. Se actualiza cada segundo y se oculta automáticamente cuando no hay estado activo.

### Callbacks asíncronos con timers

La activación de perfiles encadena `hs.timer.doAfter()` con delays configurables.

### Configuración centralizada

`config.lua` es el único archivo editable. Cambios requieren recarga (⌘R).

## Flujo de inicio

```
Hammerspoon → init.lua
  1. Configura package.path
  2. Carga y valida config.lua
  3. Limpia log, inicia clipboard watcher
  4. Refresca red y VPN en segundo plano
  5. Registra hotkeys globales
  6. Inicializa menú principal (menu.init)
  7. Inicializa menú de enfoque (focus_menu.init) + overlay
  8. Pre-calienta cachés costosos (diferido 1s)
  9. Inicia timer de prewarm cada 30s
```

## Dependencias externas

| Dependencia | Tipo | Uso |
|---|---|---|
| Hammerspoon | Runtime | Host, APIs de macOS |
| ipapi.co | API HTTPS | IP externa, geolocalización |
| ioreg | Binario macOS | Dispositivos Bluetooth |
| defaults | Binario macOS | Dock, Finder, DND |
| AppleScript | Runtime macOS | Control de Apple Music |

## Persistencia

| Dato | Ubicación | Formato |
|---|---|---|
| Historial de sesiones | `~/.hammerspoon/macspaces_history.json` | JSON |
| Log de depuración | `~/.hammerspoon/debug.log` | Texto plano (rotación 1MB) |
| Portapapeles | Solo memoria | — |
| Estado de perfiles | Solo memoria | — |

## Limitaciones arquitectónicas

1. **Sin proceso propio**: depende de Hammerspoon.
2. **Sin hot-reload**: cambios en `config.lua` requieren ⌘R.
3. **Coordinación por timers**: delays fijos, no eventos.
4. **Estado volátil**: perfiles activos, portapapeles y Pomodoro se pierden al recargar.
5. **Monopantalla**: `hs.screen.mainScreen()` asume una sola pantalla.

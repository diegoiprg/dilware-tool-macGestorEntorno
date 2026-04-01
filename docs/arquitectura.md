# Arquitectura — macSpaces v2.6.0

## Visión general

macSpaces es una herramienta de barra de menú para macOS construida sobre [Hammerspoon](https://www.hammerspoon.org), un framework de automatización que expone APIs del sistema a través de Lua. Se ejecuta como módulos Lua cargados por Hammerspoon al inicio, sin proceso propio ni empaquetado `.app`.

## Diagrama de componentes

```
┌─────────────────────────────────────────────────────────┐
│                    Hammerspoon (host)                    │
│  ┌───────────────────────────────────────────────────┐  │
│  │                    init.lua                        │  │
│  │         (punto de entrada, validación)             │  │
│  └──────────────────────┬────────────────────────────┘  │
│                         │                                │
│  ┌──────────────────────▼────────────────────────────┐  │
│  │                   menu.lua                         │  │
│  │        (menubar, construcción on-demand)           │  │
│  └──┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬──┘  │
│     │   │   │   │   │   │   │   │   │   │   │   │      │
│     ▼   ▼   ▼   ▼   ▼   ▼   ▼   ▼   ▼   ▼   ▼   ▼    │
│  ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐    │
│  │prof.│brow.│audio│music│batt.│bluet│netw.│ vpn  │    │
│  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤    │
│  │clip.│laun.│pomo.│break│pres.│hist.│hotk.│ dnd  │    │
│  └─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘    │
│                         │                                │
│  ┌──────────────────────▼────────────────────────────┐  │
│  │              config.lua  ·  utils.lua              │  │
│  │         (configuración central y utilidades)       │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
         │              │              │
         ▼              ▼              ▼
   ┌──────────┐  ┌───────────┐  ┌──────────┐
   │ macOS    │  │ ipapi.co │  │ ioreg    │
   │ APIs     │  │ (HTTPS)   │  │ defaults │
   └──────────┘  └───────────┘  └──────────┘
```

## Estructura de archivos

```
~/.hammerspoon/
├── init.lua                    ← Punto de entrada
└── macspaces/
    ├── config.lua              ← Configuración central (editable)
    ├── utils.lua               ← Log, notificaciones, helpers
    ├── menu.lua                ← Menú de barra de estado
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

### Menú on-demand

`menubar:setMenu(build_items)` recibe una función, no una tabla. Hammerspoon la invoca al abrir el menú, evitando reconstrucciones innecesarias y parpadeo.

### Caché con TTL

Módulos con datos costosos (`network`, `vpn`, `bluetooth`, `audio`) usan caché temporal:

```lua
local cache = { data = nil, last_fetch = 0, ttl = 60 }
```

### Callbacks asíncronos con timers

La activación de perfiles encadena `hs.timer.doAfter()` con delays configurables. No hay promesas ni corrutinas.

### Configuración centralizada

`config.lua` es el único archivo editable. Cambios requieren recarga (⌘R).

## Flujo de inicio

```
Hammerspoon → init.lua
  1. Configura package.path (sin duplicar en recargas)
  2. Carga y valida config.lua
  3. Limpia log, inicia clipboard watcher
  4. Refresca red y VPN en segundo plano
  5. Registra hotkeys globales
  6. Inicializa menubar con setMenu(fn)
```

## Flujo de activación de perfil

```
profiles.activate(key)
  1. Crea espacio virtual → hs.spaces.addSpaceToScreen()
  2. delay.short → obtiene ID del nuevo espacio
  3. Navega al espacio → hs.spaces.gotoSpace()
  4. delay.medium → lanza apps secuencialmente
  5. Cada app: launchOrFocus → delay.app_launch → moveWindowToSpace
  6. Cambia navegador predeterminado si aplica
  7. Notifica y ejecuta on_done
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
| Log de depuración | `~/.hammerspoon/debug.log` | Texto plano |
| Portapapeles | Solo memoria | — |
| Estado de perfiles | Solo memoria | — |

## Limitaciones arquitectónicas

1. **Sin proceso propio**: depende de Hammerspoon. Si se cierra, macSpaces deja de funcionar.
2. **Sin hot-reload**: cambios en `config.lua` requieren ⌘R.
3. **Coordinación por timers**: delays fijos, no eventos. Apps lentas pueden no moverse correctamente.
4. **Estado volátil**: perfiles activos, portapapeles y Pomodoro se pierden al recargar.
5. **Monopantalla**: `hs.screen.mainScreen()` asume una sola pantalla.

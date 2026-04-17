# Referencia de Módulos — macSpaces v2.11.0

Referencia detallada de cada módulo Lua: responsabilidad, estado interno, API pública y dependencias.

## Tabla de contenido

- [Convenciones](#convenciones)
- [Módulos de infraestructura](#módulos-de-infraestructura)
  - [config.lua](#configlua)
  - [utils.lua](#utilslua)
  - [dnd.lua](#dndlua)
- [Módulos de entorno](#módulos-de-entorno)
  - [profiles.lua](#profileslua)
  - [browsers.lua](#browserslua)
  - [audio.lua](#audiolua)
  - [music.lua](#musiclua)
  - [battery.lua](#batterylua)
  - [bluetooth.lua](#bluetoothlua)
  - [network.lua](#networklua)
  - [vpn.lua](#vpnlua)
  - [clipboard.lua](#clipboardlua)
  - [launcher.lua](#launcherlua)
  - [history.lua](#historylua)
  - [hotkeys.lua](#hotkeyslua)
- [Módulos de enfoque](#módulos-de-enfoque)
  - [pomodoro.lua](#pomodorolua)
  - [breaks.lua](#breakslua)
  - [presentation.lua](#presentationlua)
- [Módulo de monitoreo](#módulo-de-monitoreo)
  - [claude.lua](#claudelua)
- [Módulos de UI](#módulos-de-ui)
  - [menu.lua](#menulua)
  - [focus_menu.lua](#focus_menulua)
  - [focus_overlay.lua](#focus_overlaylua)
- [Punto de entrada](#punto-de-entrada)
  - [init.lua](#initlua)

---

## Convenciones

- Cada módulo retorna una tabla `M` con funciones públicas.
- El estado interno se mantiene en variables locales (closures). `require()` cachea módulos — una sola instancia por sesión de Hammerspoon.
- Funciones `build_submenu()` retornan tabla de ítems compatible con `hs.menubar:setMenu()`.
- Funciones `handle_wake()` son llamadas por `init.lua` al detectar `systemDidWake` o `screensDidWake`.

---

## Módulos de infraestructura

### config.lua

**Responsabilidad**: configuración central del sistema. El único archivo que el usuario debe editar.

**Estado interno**: ninguno (tabla de datos estáticos).

**API pública**: no expone funciones. Todos los campos son accesibles directamente: `cfg.VERSION`, `cfg.profiles`, `cfg.pomodoro`, etc.

**Dependencias**: ninguna.

**Validación al inicio** (realizada por `init.lua`):
- `VERSION`: string no vacío
- `delay`: tabla con `short` numérico positivo
- `profile_order`: tabla no vacía
- `profiles`: tabla

---

### utils.lua

**Responsabilidad**: log, notificaciones, alert canvas y helpers compartidos por todos los módulos.

**Estado interno**:
- `logFilePath`: ruta del archivo de log (`~/.hammerspoon/debug.log`)
- `_alert_canvas`: instancia de `hs.canvas` del alert actual (solo una a la vez)
- `_alert_timer`: timer para auto-cerrar el alert canvas

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `log` | `(msg: string)` | Escribe en `debug.log` con timestamp. Aplica `mask_ip()`. Rota si supera 1MB. Permisos 0600. |
| `clear_log` | `()` | Vacía el archivo de log. |
| `notify` | `(title: string, msg: string)` | Notificación de sistema + entrada en log. |
| `alert_notify` | `(title: string, msg: string, duration?: number)` | Canvas flotante grande + sonido "Glass" + notificación estándar. `duration` por defecto: 4s. |
| `table_contains` | `(tbl: table, item: any) → boolean` | Busca valor en tabla indexada. |
| `info_item` | `(label: string, value: string) → table` | Ítem de menú que copia `value` al portapapeles. |
| `disabled_item` | `(label: string) → table` | Ítem de menú no accionable (`disabled = true`). |
| `format_time` | `(seconds: number) → string` | Formatea como `MM:SS` o `H:MM:SS`. |

**Dependencias**: ninguna (solo APIs de Hammerspoon).

---

### dnd.lua

**Responsabilidad**: control de No Molestar (Do Not Disturb).

**Estado interno**: ninguno (sin estado propio; consulta el sistema en cada llamada).

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `enable` | `()` | Activa No Molestar. Usa `hs.focus` si disponible; fallback a `defaults`. |
| `disable` | `()` | Desactiva No Molestar. |
| `is_enabled` | `() → boolean?` | Estado actual. `nil` si sin API nativa. |
| `toggle` | `() → boolean` | Alterna estado. Retorna el nuevo estado. |

**Estrategia de implementación**:
1. Si `hs.focus.setFocusModeEnabled` existe (Hammerspoon ≥ 0.9.97): usa la API nativa.
2. Fallback: `defaults -currentHost write com.apple.notificationcenterui doNotDisturb` + `killall NotificationCenter`.

**Dependencias**: `utils.lua`.

---

## Módulos de entorno

### profiles.lua

**Responsabilidad**: ciclo de vida de perfiles — crear/eliminar espacios de Mission Control y lanzar/cerrar apps.

**Estado interno**:
```lua
state = {
    personal = { space_id = nil, started_at = nil, prev_browser = nil },
    work     = { space_id = nil, started_at = nil, prev_browser = nil },
    -- ... una entrada por perfil en cfg.profile_order
}
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `is_active` | `(key: string) → boolean` | `true` si el perfil tiene espacio activo. |
| `get_state` | `(key: string) → table` | Retorna `{ space_id, started_at, prev_browser }`. |
| `activate` | `(key: string, on_done?: function)` | Crea espacio, lanza apps, guarda navegador previo. |
| `deactivate` | `(key: string, on_done?: function)` | Cierra apps, reubica ventanas huérfanas, elimina espacio, restaura navegador. |

**Secuencia de activación**:
1. `hs.spaces.addSpaceToScreen()` — crea nuevo espacio
2. Delay `cfg.delay.short` — espera que el SO procese el espacio
3. `hs.spaces.gotoSpace(new_space)` — navega al espacio
4. Delay `cfg.delay.medium` — espera de navegación
5. Por cada app: `hs.application.launchOrFocus()` + delay `cfg.delay.app_launch` + mover ventana al espacio
6. Callback `on_done` tras el último delay

**Dependencias**: `config.lua`, `utils.lua`, `browsers.lua`.

---

### browsers.lua

**Responsabilidad**: gestión del navegador predeterminado del sistema via helper Swift nativo.

**Estado interno**: ninguno (sin caché propio; delega a `set_browser`).

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `display_name` | `(bundle_id: string) → string?` | Nombre legible desde `cfg.browser_names`. |
| `installed` | `() → string[]` | Bundle IDs instalados y reconocidos por el allowlist. |
| `current` | `() → string?` | Bundle ID del navegador predeterminado (vía helper Swift). |
| `set_default` | `(bundle_id: string)` | Cambia navegador. Hasta 2 reintentos si la API falla silenciosamente. |
| `build_submenu` | `(on_update?: function) → table` | Ítems del submenú con banner de navegador actual y checkmarks. |

**Helper nativo**: `~/.hammerspoon/set_browser` (compilado desde `macspaces/set_browser.swift`). Si el binario no existe al iniciar, `init.lua` lo compila automáticamente con `swiftc`.

**Dependencias**: `config.lua`, `utils.lua`.

---

### audio.lua

**Responsabilidad**: selección del dispositivo de salida de audio predeterminado.

**Estado interno**:
```lua
cache = { devices = nil, current = nil, last_fetch = 0, ttl = 10 }
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `output_devices` | `() → table[]` | Dispositivos de salida disponibles (caché TTL 10s). |
| `current_output` | `() → device?` | Dispositivo de salida actual. |
| `set_output` | `(device)` | Cambia dispositivo e invalida caché. Solo notifica en error. |
| `invalidate_cache` | `()` | Fuerza recarga en el próximo acceso. |
| `build_submenu` | `() → table` | Ítems con checkmark en el activo. |

**Dependencias**: `utils.lua`.

---

### music.lua

**Responsabilidad**: control de Apple Music.app via AppleScript.

**Estado interno**:
```lua
cache = { running = nil, playing = nil, track = nil, last_fetch = 0, ttl = 3 }
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `is_running` | `() → boolean` | `true` si Music.app está abierta (caché TTL 3s). |
| `is_playing` | `() → boolean` | `true` si hay reproducción activa. |
| `get_current_track` | `() → {name, artist, album}?` | Pista actual o `nil`. |
| `play` | `()` | Inicia reproducción. |
| `pause` | `()` | Pausa reproducción. |
| `playpause` | `()` | Alterna play/pause. |
| `next` | `()` | Siguiente pista. |
| `previous` | `()` | Pista anterior. |
| `invalidate_cache` | `()` | Fuerza recarga. |
| `build_submenu` | `() → table` | Ítems del submenú con pista actual y controles. |

**Implementación**: usa `hs.applescript()` con scripts literales estáticos. Bundle ID: `com.apple.Music`.

**Dependencias**: `utils.lua`.

---

### battery.lua

**Responsabilidad**: información y estado de batería. Solo visible en MacBook.

**Estado interno**:
```lua
cached_has_battery = nil  -- permanente tras primera consulta
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `has_battery` | `() → boolean` | Detecta si el dispositivo tiene batería (caché permanente). |
| `percentage` | `() → number` | Porcentaje actual. |
| `is_charging` | `() → boolean` | `true` si está cargando. |
| `is_plugged` | `() → boolean` | `true` si está conectado a CA. |
| `status_label` | `() → string?` | String formateado con ícono, % y alertas contextuales. |
| `build_submenu` | `() → table` | Submenú con %, estado, ciclos y tiempo restante. |

**Detección de batería**: usa `hs.battery.cycles()` como indicador primario. Fallback a `powerSource() == "Battery Power"`.

**Dependencias**: `utils.lua`.

---

### bluetooth.lua

**Responsabilidad**: información de dispositivos Bluetooth conectados con nivel de batería.

**Estado interno**:
```lua
cache = { devices = nil, last_fetch = 0, ttl = 120 }
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `devices` | `() → table[]` | Lista de `{ name, battery, address }` (caché TTL 120s). |
| `build_submenu` | `() → table` | Ítems con ícono por tipo y nivel de batería. |

**Fuente de datos**: parsea la salida combinada de tres comandos `ioreg`:
- `-k BatteryPercent`: dispositivos Apple (AirPods, Magic Mouse, etc.)
- `-k BatteryLevel`: dispositivos de terceros (Logitech, etc.)
- `-k DeviceAddress`: todos los dispositivos BT activos

**Íconos por tipo** (detectados por nombre en minúscula): 🎧 auriculares, 🖱 mouse, ⌨️ teclado, ⬜ trackpad, 🔊 parlante, 📱 genérico.

**Dependencias**: `utils.lua`.

---

### network.lua

**Responsabilidad**: información de la conexión de red activa e IP externa.

**Estado interno**:
```lua
cache = {
    local_info  = nil,
    remote_info = nil,
    fetching    = false,
    last_fetch  = 0,
    ttl         = 60,
}
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `refresh` | `(on_done?: function)` | Refresca info local (síncrono) e info remota (asíncrono). |
| `local_info` | `() → {interface, type, local_ip, ssid}` | Info de la interfaz activa. |
| `remote_info` | `() → {query, country, regionName, city, isp}?` | Datos de ipapi.co o `nil`. |
| `build_submenu` | `(on_update?: function) → table` | Ítems del submenú con botón de actualización. |

**IP externa**: obtenida via `hs.http.asyncGet("https://ipapi.co/json/")` para no bloquear el hilo principal.

**Dependencias**: `utils.lua`.

---

### vpn.lua

**Responsabilidad**: detección de VPN activa e información geográfica del túnel.

**Estado interno**:
```lua
cache = {
    ifaces = nil, ifaces_fetch = 0, ifaces_ttl = 10,
    data = nil, fetching = false, last_ip = nil,
    last_fetch = 0, ttl = 120,
}
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `is_active` | `() → boolean` | `true` si hay interfaz VPN activa (caché TTL 10s). |
| `interfaces` | `() → {interface, ip}[]` | Interfaces VPN activas detectadas. |
| `refresh` | `(on_done?: function)` | Refresca info geográfica del túnel via ipapi.co. |
| `build_submenu` | `(on_update?: function) → table` | Ítems del submenú. |

**Detección**: busca interfaces `utun*` y `ppp*` con IPv4 asignada. Excluye:
- IPs link-local (`169.254.x.x`) — iCloud Private Relay, Handoff
- Rango CGNAT de Apple (`100.64–127.x.x`) — AirDrop

**Dependencias**: `utils.lua`.

---

### clipboard.lua

**Responsabilidad**: historial del portapapeles en memoria con filtro de apps sensibles.

**Estado interno**:
```lua
history = {}  -- tabla en memoria, no persiste
watcher = nil -- instancia de hs.pasteboard.watcher
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `start` | `(on_change?: function)` | Inicia `hs.pasteboard.watcher` (event-driven). |
| `stop` | `()` | Detiene el watcher. |
| `clear` | `()` | Limpia el historial en memoria. |
| `restore` | `(index: number)` | Restaura la entrada `index` al portapapeles del sistema. |
| `open_chooser` | `()` | Abre `hs.chooser` con filtrado en tiempo real. |
| `build_submenu` | `(on_update?: function) → table` | Ítems del submenú. |

**Tipos soportados**: `text`, `image`, `url`, `other`. Deduplicación de entradas consecutivas idénticas (por label para texto, por tipo para imágenes).

**Filtro de seguridad**: verifica la app frontal en el momento de la copia. Si el nombre coincide con `cfg.clipboard.ignore_apps`, la entrada no se captura.

**Dependencias**: `config.lua`, `utils.lua`.

---

### launcher.lua

**Responsabilidad**: lanzador rápido de apps configurable.

**Estado interno**: ninguno.

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `launch` | `(app_name: string)` | Lanza app via `hs.application.launchOrFocus`. |
| `build_submenu` | `() → table` | Ítems del submenú. Vacío si `cfg.launcher.apps` es vacío. |

**Nota**: el submenú de lanzador no aparece en `menu.lua` si `cfg.launcher.apps` está vacío.

**Dependencias**: `config.lua`, `utils.lua`.

---

### history.lua

**Responsabilidad**: registro persistido de tiempo de sesión por perfil.

**Estado interno**:
```lua
cache = { data = nil, date = nil }  -- caché en memoria por fecha
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `record_session` | `(key: string, started_at: number)` | Registra duración en segundos. Mínimo 10s. Limpia entradas > 30 días. |
| `today_seconds` | `(key: string) → number` | Segundos acumulados hoy para un perfil. |
| `build_submenu` | `() → table` | Ítems con tiempo por perfil activo hoy. |

**Persistencia**: `~/.hammerspoon/macspaces_history.json`. Permisos 0600. Formato:
```json
{ "2026-04-15": { "personal": 3600, "work": 7200 } }
```

**Dependencias**: `config.lua`, `utils.lua`.

---

### hotkeys.lua

**Responsabilidad**: registro de atajos de teclado globales para activar/desactivar perfiles.

**Estado interno**:
```lua
registered = {}  -- lista de instancias hs.hotkey
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `register` | `(on_change?: function)` | Registra hotkeys desde `cfg.hotkeys`. Limpia registros anteriores. |
| `unregister` | `()` | Elimina todos los hotkeys registrados. |

**Dependencias**: `config.lua`, `utils.lua`, `profiles.lua`.

---

## Módulos de enfoque

### pomodoro.lua

**Responsabilidad**: temporizador Pomodoro con fases, DND integrado y notificaciones educativas.

**Estado interno**:
```lua
state = {
    active         = false,
    phase          = nil,   -- "work" | "short_break" | "long_break"
    cycle          = 0,
    seconds_left   = 0,
    timer          = nil,
    phase_started  = 0,     -- epoch de inicio de fase (reloj de pared)
    phase_duration = 0,
}
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `is_active` | `() → boolean` | `true` si el Pomodoro está corriendo. |
| `current_phase` | `() → string?` | Fase actual o `nil`. |
| `cycles_completed` | `() → number` | Ciclos completados. |
| `time_label` | `() → string?` | Label completo para overlay: `🍅 Pomodoro · 24:30 · Ciclo 1/4`. |
| `menubar_label` | `() → string?` | Label corto: `🍅 23m`. |
| `set_menubar_updater` | `(fn: function)` | Registra callback invocado en cada tick y al cambiar fase. |
| `start` | `()` | Inicia desde cero con fase `work`. |
| `stop` | `()` | Detiene y notifica ciclos completados. |
| `skip` | `()` | Salta a la siguiente fase. |
| `handle_wake` | `()` | Evalúa tiempo restante tras wake del sistema. Avanza fase si expiró. |
| `build_submenu` | `(on_update?: function) → table` | Ítems del submenú. |

**Cálculo de tiempo**: `remaining = phase_duration - (os.time() - phase_started)`. Preciso independientemente de la frecuencia del timer y tras suspensión.

**Datos educativos rotativos**: 6 mensajes sobre la técnica Pomodoro (Cirillo, Baumeister, Dehaene, DeMarco, Immordino-Yang).

**Dependencias**: `config.lua`, `utils.lua`, `dnd.lua`.

---

### breaks.lua

**Responsabilidad**: recordatorios periódicos de descanso activo con instrucciones paso a paso.

**Estado interno**:
```lua
state = {
    enabled       = cfg.breaks.enabled,
    timer         = nil,           -- hs.timer del próximo break
    display_timer = nil,           -- hs.timer de duración del banner
    next_break_at = nil,           -- epoch del próximo break
    break_end_at  = nil,           -- epoch de fin del banner
}
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `is_enabled` | `() → boolean` | Estado actual. |
| `is_on_break` | `() → boolean` | `true` si el banner está visible. |
| `init` | `()` | Arranca el primer ciclo si `enabled = true`. |
| `idle_label` | `() → string?` | Countdown para overlay: `"◎ Descanso · 48:30"` o `"🧘 Descanso · 01:45"`. |
| `enable` | `(on_update?: function)` | Activa y programa el primer break. |
| `disable` | `(on_update?: function)` | Desactiva y cancela timers. |
| `toggle` | `(on_update?: function)` | Alterna estado. |
| `handle_wake` | `()` | Reinicia ciclo al despertar el sistema. |
| `build_submenu` | `(on_update?: function) → table` | Ítems con estado, countdown e intervalos seleccionables. |

**7 mensajes rotativos** (con 3 pasos concretos y fuente científica): vista (AAO), cuello (OSHA), muñecas (Mayo Clinic), movilidad (AHA), espalda (OSHA), respiración (Harvard Med), hidratación (EFSA).

**Dependencias**: `config.lua`, `utils.lua`.

---

### presentation.lua

**Responsabilidad**: modo presentación que limpia el entorno visual del escritorio.

**Estado interno**:
```lua
state = { active = false, dock_was_hidden = false }
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `is_active` | `() → boolean` | `true` si el modo está activo. |
| `toggle` | `(on_done?: function)` | Activa/desactiva con diálogo de confirmación al activar. |
| `build_submenu` | `(on_update?: function) → table` | Ítems con estado real de cada característica. |

**Al activar**: guarda estado previo del Dock → activa DND → oculta Dock → oculta escritorio → `killall Dock` + `killall Finder`.

**Al desactivar**: restaura Dock → desactiva DND → muestra escritorio → `killall Dock` + `killall Finder`.

**Dependencias**: `config.lua`, `utils.lua`, `dnd.lua`.

---

## Módulo de monitoreo

### claude.lua

**Responsabilidad**: monitoreo de uso de rate limits de Claude Code leyendo un archivo de caché externo.

**Estado interno**:
```lua
cache = {
    data       = nil,
    last_fetch = 0,
    ttl        = 60,
}
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `fetch` | `() → {five_hour, seven_day, source}` | Lee `usage_cache.json` con caché de 60s. `source = "none"` si sin datos. |
| `invalidate` | `()` | Fuerza recarga en el próximo acceso. |
| `overlay_rows` | `(minimal?: boolean) → {label, pct}[]` | 1 o 2 filas para el overlay. `minimal=true` omite barra de progreso. |
| `overlay_label` | `() → string` | Compatibilidad: primera fila como string. |
| `color_for` | `(pct: number) → table` | Color semáforo: verde (<60%), amarillo (60–84%), rojo (≥85%). |
| `build_submenu` | `() → table` | Ítems del submenú con ventanas 5h y 7d. |

**Archivo fuente**: `~/.claude/usage_cache.json`. Generado por `statusline.sh` del proyecto `dil-ia-config`. macSpaces solo lee este archivo, nunca lo modifica.

**Estructura esperada del archivo**:
```json
{
  "updated_at": 1744000000,
  "five_hour":  { "pct": 45, "reset": 1744003600 },
  "seven_day":  { "pct": 12, "reset": 1744518000 }
}
```

**Barra de progreso**: caracteres `▰▱` (8 caracteres en overlay, 10 en submenú).

**Caducidad**: ignora caches con más de 6 horas de antigüedad (`updated_at`).

**Dependencias**: `utils.lua`.

---

## Módulos de UI

### menu.lua

**Responsabilidad**: menú principal de barra de estado con todos los módulos de entorno.

**Estado interno**:
```lua
menubar = hs.menubar.new()
rebuild_timer = nil
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `init` | `()` | Crea menubar, carga ícono template, construye menú, inicia timer de reconstrucción (5s). |
| `build` | `()` | Reconstruye menú con `hs.timer.doAfter(0, ...)`. |
| `destroy` | `()` | Detiene timer y elimina menubar. |

**Estructura del menú** (orden de aparición):
1. Perfiles (con tiempo activo y hotkeys inline)
2. Entorno: navegador, audio, música
3. Dispositivos: batería (solo MacBook), Bluetooth
4. Red: conexión + VPN (solo si activa)
5. Portapapeles
6. Lanzador (solo si `cfg.launcher.apps` no está vacío)
7. Historial
8. Claude
9. Sistema: registro, recargar
10. Versión

**Ícono**: busca `~/.hammerspoon/macspaces_icon.png` como template image 18×18pt. Fallback a `cfg.menu_icon`.

**Dependencias**: todos los módulos de entorno, `config.lua`, `utils.lua`.

---

### focus_menu.lua

**Responsabilidad**: menú independiente de enfoque con Pomodoro, descanso y presentación.

**Estado interno**:
```lua
menubar = hs.menubar.new()
rebuild_timer = nil
focus_icon = nil  -- cargado en init()
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `init` | `()` | Crea menubar, carga ícono, registra updater en pomodoro, arranca breaks y overlay. |
| `build` | `()` | Reconstruye menú y llama `overlay.refresh()`. |
| `destroy` | `()` | Detiene timer, detiene overlay, elimina menubar. |

**Ícono**: busca `~/.hammerspoon/macspaces_focus_icon.png`. Fallback a `cfg.focus_icon` (◎ por defecto).

**Dependencias**: `config.lua`, `utils.lua`, `pomodoro.lua`, `breaks.lua`, `presentation.lua`, `focus_overlay.lua`.

---

### focus_overlay.lua

**Responsabilidad**: banner flotante unificado con filas coloreadas, arrastrable y con posición persistida.

**Estado interno**:
```lua
canvas   = nil        -- instancia de hs.canvas
timer    = nil        -- hs.timer de actualización (1s)
drag_tap = nil        -- hs.eventtap para drag
saved_pos = nil       -- { x, y } cargado de disco
drag = { active = false, ox = 0, oy = 0 }
IS_MACBOOK = ...      -- calculado al cargar el módulo
```

**API pública**:

| Función | Firma | Descripción |
|---|---|---|
| `start` | `()` | Carga posición guardada, muestra overlay, arranca timer (1s). |
| `stop` | `()` | Detiene timer, cancela drag tap, destruye canvas. |
| `refresh` | `()` | Fuerza actualización inmediata. |

**Persistencia de posición**: lee `~/.hammerspoon/overlay_pos.json` al arrancar. Guarda al soltar el drag (`mouseUp`). Si no existe el archivo, posición por defecto: esquina inferior derecha de `primaryScreen()`.

**Detección de dispositivo**: `IS_MACBOOK = hs.host.localizedName():find("macbook") ~= nil`. Calculado una sola vez al cargar. Habilita modo compacto automáticamente.

**Entradas del overlay** (en orden):
1. Pomodoro — si activo
2. Presentación — si activa
3. Descanso activo — si habilitado
4. Claude — si hay sesión activa (1 o 2 filas)

**Colores** (`BG_ALPHA = 0.80`):
- `work`: `{ 0.75, 0.15, 0.10 }` — rojo
- `short_break` / `long_break`: `{ 0.15, 0.55, 0.25 }` — verde
- `breaks`: `{ 0.20, 0.40, 0.65 }` — azul
- `breaks_active`: `{ 0.15, 0.55, 0.25 }` — verde
- `presentation`: `{ 0.45, 0.20, 0.60 }` — púrpura

**Canvas**: nivel `floating`, comportamiento `canJoinAllSpaces + stationary`, `clickActivating = false`.

**Dependencias**: `pomodoro.lua`, `breaks.lua`, `presentation.lua`, `claude.lua`.

---

## Punto de entrada

### init.lua

**Responsabilidad**: arranque, validación, orquestación y limpieza al cerrar.

**Secuencia de arranque**:
```
1. Configura package.path (sin duplicados en recargas)
2. Carga y valida config.lua
3. Si validación falla → notifica y aborta
4. Limpia debug.log, registra versión
5. Compila set_browser.swift si el binario no existe
6. clipboard.start()
7. network.refresh() + vpn.refresh()
8. hotkeys.register()
9. menu.init()
10. focus_menu.init()
    └─ focus_menu.init() llama breaks.init() y overlay.start()
11. hs.timer.doAfter(1, prewarm_caches)
12. prewarm_timer = hs.timer.doEvery(30, prewarm_caches)
13. caffeinate_watcher:start()
14. hs.shutdownCallback registrado
```

**Prewarm de cachés** (`prewarm_caches`): llama `bluetooth.devices()`, `browsers.installed()`, `browsers.current()`, `battery.has_battery()`, `music.is_running()` para mantener cachés calientes.

**Wake detection**: `hs.caffeinate.watcher` detecta `systemDidWake` y `screensDidWake` → `breaks.handle_wake()` + `pomodoro.handle_wake()` + `menu.build()`.

**Shutdown callback**: al apagar/recargar, restaura DND, Dock y escritorio si están modificados; libera todos los recursos (timers, menubars, overlay, clipboard watcher, hotkeys).

**Dependencias**: todos los módulos del sistema.

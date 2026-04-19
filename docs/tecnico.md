# Referencia Técnica — macSpaces v2.11.9

## Tabla de contenido

- [API de módulos](#api-de-módulos)
  - [utils.lua](#utilslua)
  - [config.lua](#configlua)
  - [profiles.lua](#profileslua)
  - [browsers.lua](#browserslua)
  - [audio.lua](#audiolua)
  - [music.lua](#musiclua)
  - [battery.lua](#batterylua)
  - [bluetooth.lua](#bluetoothlua)
  - [network.lua](#networklua)
  - [vpn.lua](#vpnlua)
  - [clipboard.lua](#clipboardlua)
  - [pomodoro.lua](#pomodorolua)
  - [breaks.lua](#breakslua)
  - [presentation.lua](#presentationlua)
  - [history.lua](#historylua)
  - [hotkeys.lua](#hotkeyslua)
  - [dnd.lua](#dndlua)
  - [claude.lua](#claudelua)
  - [launcher.lua](#launcherlua)
  - [menu.lua](#menulua)
  - [focus_menu.lua](#focus_menulua)
  - [focus_overlay.lua](#focus_overlaylua)
  - [init.lua](#initlua)
- [Archivos de datos](#archivos-de-datos)
- [APIs externas](#apis-externas)
- [Comandos del sistema](#comandos-del-sistema)

---

## API de módulos

Cada módulo expone funciones públicas a través de una tabla `M`. El estado interno se mantiene en variables locales (closures). `require()` cachea módulos, garantizando una sola instancia por sesión de Hammerspoon.

---

### utils.lua

| Función | Descripción |
|---|---|
| `M.log(msg)` | Escribe línea con timestamp en `debug.log` (permisos 0600, rotación 1MB, IPs ofuscadas) |
| `M.clear_log()` | Vacía el archivo de log |
| `M.notify(title, msg)` | Notificación del sistema + entrada en log |
| `M.alert_notify(title, msg, duration)` | Alerta llamativa: notificación + canvas persistente + sonido "Glass" del sistema |
| `M.table_contains(tbl, item)` | Busca valor en tabla indexada |
| `M.info_item(label, value)` | Ítem de menú que copia `value` al portapapeles al hacer clic |
| `M.disabled_item(label)` | Ítem de menú no accionable (`disabled = true`) |
| `M.format_time(seconds)` | Formatea segundos como `MM:SS` o `H:MM:SS` |

El canvas de alerta (`show_alert_canvas`) usa `hs.canvas` con `floating` level y `canJoinAllSpaces`. Se destruye automáticamente al finalizar `duration`.

---

### config.lua

Tabla de configuración central. Campos validados al inicio por `init.lua`:
- `VERSION`: string no vacío
- `delay`: tabla con `short` > 0
- `profile_order`: tabla no vacía
- `profiles`: tabla

Consulta [docs/configuracion.md](configuracion.md) para la referencia completa de parámetros.

---

### profiles.lua

| Función | Descripción |
|---|---|
| `M.is_active(key)` | `true` si el perfil tiene espacio activo |
| `M.get_state(key)` | Retorna `{ space_id, started_at, prev_browser }` |
| `M.activate(key, on_done)` | Crea espacio, lanza apps con delays configurables, guarda navegador previo |
| `M.deactivate(key, on_done)` | Cierra apps, reubica ventanas huérfanas, elimina espacio, restaura navegador |

La activación encadena `hs.timer.doAfter()` con `cfg.delay.short`, `cfg.delay.medium` y `cfg.delay.app_launch`. El orden de apps respeta `cfg.profile_order`.

---

### browsers.lua

| Función | Descripción |
|---|---|
| `M.display_name(bundle_id)` | Nombre legible desde `cfg.browser_names` |
| `M.installed()` | Lista de bundle IDs instalados y reconocidos |
| `M.current()` | Bundle ID del navegador predeterminado actual (via helper Swift) |
| `M.set_default(bundle_id)` | Cambia el navegador predeterminado con hasta 2 reintentos |
| `M.build_submenu(on_update)` | Ítems del submenú con banner de navegador actual |

Usa el helper nativo compilado en `~/.hammerspoon/set_browser` (fuente: `set_browser.swift`). Se auto-compila al iniciar si no existe.

---

### audio.lua

| Función | Descripción |
|---|---|
| `M.output_devices()` | Lista de dispositivos de salida (caché TTL 10s) |
| `M.current_output()` | Dispositivo de salida actual |
| `M.set_output(device)` | Cambia dispositivo predeterminado e invalida caché |
| `M.invalidate_cache()` | Fuerza recarga en el próximo acceso |
| `M.build_submenu()` | Ítems del submenú con checkmark en el activo |

---

### music.lua

| Función | Descripción |
|---|---|
| `M.is_running()` | `true` si Music.app está abierta (caché TTL 3s) |
| `M.is_playing()` | `true` si hay reproducción activa |
| `M.get_current_track()` | `{ name, artist, album }` o `nil` |
| `M.play()` / `M.pause()` / `M.playpause()` | Control de reproducción |
| `M.next()` / `M.previous()` | Navegación de pista |
| `M.invalidate_cache()` | Fuerza recarga en el próximo acceso |
| `M.build_submenu()` | Ítems del submenú |

Control via AppleScript usando `hs.applescript`. Caché unificado para `is_running`, `is_playing` y `get_current_track`.

---

### battery.lua

| Función | Descripción |
|---|---|
| `M.has_battery()` | `true` si el dispositivo tiene batería (caché permanente) |
| `M.percentage()` | Porcentaje actual |
| `M.is_charging()` | `true` si está cargando |
| `M.is_plugged()` | `true` si está conectado a CA |
| `M.status_label()` | String formateado con ícono, porcentaje y alertas |
| `M.build_submenu()` | Submenú con porcentaje, estado, ciclos y tiempo restante |

---

### bluetooth.lua

| Función | Descripción |
|---|---|
| `M.devices()` | Lista de `{ name, battery, address }` (caché TTL 120s) |
| `M.build_submenu()` | Ítems del submenú con ícono por tipo de dispositivo |

Parsea la salida de `ioreg` buscando claves `BatteryPercent`, `BatteryLevel` y `DeviceAddress`. Deduplica por nombre, priorizando entradas con batería.

---

### network.lua

| Función | Descripción |
|---|---|
| `M.refresh(on_done)` | Refresca info local sincrónicamente e info remota de forma asíncrona |
| `M.local_info()` | `{ interface, type, local_ip, ssid }` |
| `M.remote_info()` | Datos de ipapi.co o `nil` si no disponibles |
| `M.build_submenu(on_update)` | Ítems del submenú con botón de actualización |

La IP externa se obtiene via `hs.http.asyncGet` para no bloquear el hilo principal.

---

### vpn.lua

| Función | Descripción |
|---|---|
| `M.is_active()` | `true` si hay interfaz VPN activa (caché TTL 10s) |
| `M.interfaces()` | Lista de `{ interface, ip }` |
| `M.refresh(on_done)` | Refresca info geográfica del túnel via ipapi.co |
| `M.build_submenu(on_update)` | Ítems del submenú |

Filtra interfaces del sistema: excluye IPs link-local (`169.254.x.x`) y rango CGNAT de Apple (`100.64–127.x.x`) para evitar falsos positivos.

---

### clipboard.lua

| Función | Descripción |
|---|---|
| `M.start(on_change)` | Inicia `hs.pasteboard.watcher` (event-driven, filtra blocklist) |
| `M.stop()` | Detiene watcher |
| `M.clear()` | Limpia historial en memoria |
| `M.restore(index)` | Restaura entrada al portapapeles |
| `M.open_chooser()` | Abre `hs.chooser` con filtrado en tiempo real |
| `M.build_submenu(on_update)` | Ítems del submenú |

El historial solo existe en memoria (no persiste). Soporta entradas de tipo `text`, `image` y `url`. Deduplica entradas consecutivas idénticas.

---

### pomodoro.lua

| Función | Descripción |
|---|---|
| `M.is_active()` | `true` si el Pomodoro está corriendo |
| `M.current_phase()` | `"work"`, `"short_break"` o `"long_break"` |
| `M.cycles_completed()` | Número de ciclos completados |
| `M.time_label()` | String con ícono, nombre de fase, countdown y ciclo (reloj de pared) |
| `M.menubar_label()` | Etiqueta corta para menubar (reloj de pared) |
| `M.set_menubar_updater(fn)` | Registra callback para actualizar menubar |
| `M.start()` / `M.stop()` / `M.skip()` | Control del temporizador |
| `M.handle_wake()` | Evalúa `remaining_seconds()` al wake; avanza fase si expiró |
| `M.build_submenu(on_update)` | Ítems del submenú |

El tiempo restante se calcula como `phase_duration - (os.time() - phase_started)` para ser preciso independientemente de la frecuencia del timer. Notificaciones incluyen datos educativos rotativos (Cirillo, Baumeister, Dehaene, DeMarco).

---

### breaks.lua

| Función | Descripción |
|---|---|
| `M.is_enabled()` | `true` si está activo (default: `true` según config) |
| `M.is_on_break()` | `true` si el banner de descanso está visible actualmente |
| `M.init()` | Arranca el timer si está habilitado en config |
| `M.idle_label()` | Countdown como string (`"◎ Descanso · 48:30"`) o `nil` |
| `M.enable(on_update)` / `M.disable(on_update)` / `M.toggle(on_update)` | Control |
| `M.handle_wake()` | Reinicia ciclo de descanso al despertar el sistema |
| `M.build_submenu(on_update)` | Ítems del submenú con intervalos seleccionables |

Estado interno: `next_break_at` (epoch del próximo break) y `break_end_at` (epoch de fin del banner). El `display_timer` es cancelable — desactivar durante el display cancela el ciclo correctamente. Notificaciones via `utils.alert_notify()` con mensajes rotativos con instrucciones paso a paso (AAO, OSHA, Mayo Clinic, AHA, EFSA, Harvard Med).

---

### presentation.lua

| Función | Descripción |
|---|---|
| `M.is_active()` | `true` si el modo está activo |
| `M.toggle(on_done)` | Activa/desactiva con diálogo de confirmación |
| `M.build_submenu(on_update)` | Ítems del submenú con indicadores de estado real |

Al activar: guarda estado previo del Dock (`dock_was_hidden`), activa DND, oculta Dock y limpia escritorio. Al desactivar: restaura todos los estados originales.

---

### history.lua

| Función | Descripción |
|---|---|
| `M.record_session(key, started_at)` | Registra duración de sesión (mínimo 10 segundos) |
| `M.today_seconds(key)` | Segundos acumulados hoy para un perfil |
| `M.build_submenu()` | Ítems del submenú con tiempo por perfil |

Persiste en `~/.hammerspoon/macspaces_history.json` con permisos 0600. Caché en memoria por fecha. Limpieza automática de entradas > 30 días.

---

### hotkeys.lua

| Función | Descripción |
|---|---|
| `M.register(on_change)` | Registra atajos globales desde `cfg.hotkeys` (limpia anteriores primero) |
| `M.unregister()` | Elimina todos los atajos |

---

### dnd.lua

| Función | Descripción |
|---|---|
| `M.enable()` | Activa No Molestar (API nativa si disponible, fallback a `defaults`) |
| `M.disable()` | Desactiva No Molestar |
| `M.is_enabled()` | Estado actual (`nil` si sin API nativa) |
| `M.toggle()` | Alterna estado leyendo el estado actual antes de cambiar |

Usa `hs.focus.setFocusModeEnabled()` si disponible (Hammerspoon 0.9.97+). Fallback a `defaults -currentHost write com.apple.notificationcenterui doNotDisturb`.

---

### claude.lua

| Función | Descripción |
|---|---|
| `M.fetch()` | Lee `~/.claude/usage_cache.json` con caché de 60s; retorna `{ five_hour, seven_day, updated_at, source }` |
| `M.invalidate()` | Fuerza recarga en el próximo acceso |
| `M.has_session()` | `true` si hay sesión activa con datos de rate limit |
| `M.overlay_rows()` | Retorna tabla con una fila `{ label, pct }` para el overlay; formato inline `5h X% · 7d Y%` |
| `M.color_for(pct)` | Color semáforo: verde (<60%), amarillo (60–84%), rojo (≥85%) |
| `M.build_submenu()` | Ítems del submenú con uso de ventanas 5h y 7d |

Fuente de datos: `~/.claude/usage_cache.json` generado por `statusline.sh`. Ignora caches con más de 6 horas de antigüedad (`updated_at`). La función `overlay_rows()` retorna siempre 1 fila con formato compacto inline; el color se basa en el peor porcentaje entre 5h y 7d. Si el epoch de reset de una ventana ya pasó, `adjusted_pct()` devuelve 0% automáticamente. Barras de progreso (`▰▱`), indicador de frescura y tiempo de reset se mantienen solo en `build_submenu()`.

---

### launcher.lua

| Función | Descripción |
|---|---|
| `M.launch(app_name)` | Lanza app por nombre via `hs.application.launchOrFocus` |
| `M.build_submenu()` | Ítems del submenú; cada entrada puede ser `string` o `{ name, icon }` |

No aparece en el menú principal si `cfg.launcher.apps` está vacío.

---

### menu.lua

| Función | Descripción |
|---|---|
| `M.init()` | Crea menubar, carga ícono template, construye menú, inicia timer de reconstrucción (5s) |
| `M.build()` | Reconstruye menú con `hs.timer.doAfter(0, ...)` para diferir al siguiente ciclo |
| `M.destroy()` | Detiene timer y elimina menubar |

Busca `~/.hammerspoon/macspaces_icon.png` como template image (18×18pt). Fallback a `cfg.menu_icon` (emoji). Reconstrucción cada 5 segundos en segundo plano.

---

### focus_menu.lua

| Función | Descripción |
|---|---|
| `M.init()` | Crea menubar de enfoque, inicia overlay, inicia timer de reconstrucción (5s) |
| `M.build()` | Reconstruye menú y llama `overlay.refresh()` |
| `M.destroy()` | Detiene timer, detiene overlay, elimina menubar |

Registra `pomodoro.set_menubar_updater()` para actualizar el ícono del menú de enfoque en cada tick del timer Pomodoro.

---

### focus_overlay.lua

| Función | Descripción |
|---|---|
| `M.start()` | Inicializa posición en memoria, muestra overlay, arranca timer de actualización (1s) |
| `M.stop()` | Detiene timer, cancela drag tap, destruye canvas |
| `M.refresh()` | Fuerza actualización inmediata del canvas |

**Posición en memoria**: la posición se guarda en una variable local durante la sesión. Al soltar el drag (`mouseUp`) se actualiza en memoria. La posición se resetea al recargar Hammerspoon — no hay persistencia en disco.

**Detección de dispositivo**: `IS_MACBOOK` se determina una sola vez al cargar el módulo mediante `hs.host.localizedName():find("macbook")`. En MacBook, si todas las filas AI tienen porcentaje <60% (todo verde), se ocultan del overlay para minimizar el tamaño.

**Entradas del overlay** (en orden):
1. Pomodoro — si activo: fila roja con countdown, fase y ciclo
2. Presentación — si activa: fila púrpura
3. Descanso activo — si habilitado: fila azul (countdown) o verde (banner activo)
4. Claude — si hay sesión activa: 1 fila inline `5h X% · 7d Y%` con color semáforo
5. Gemini — si hay sesión activa: 1 fila inline `pro X% · flash Y% · lite Z%` con color semáforo

Colores de fondo definidos en `BG_COLORS`:
- `work`: rojo (`0.75, 0.15, 0.10`)
- `short_break` / `long_break`: verde (`0.15, 0.55, 0.25`)
- `breaks`: azul (`0.20, 0.40, 0.65`)
- `breaks_active`: verde (`0.15, 0.55, 0.25`)
- `presentation`: púrpura (`0.45, 0.20, 0.60`)

El canvas usa `canJoinAllSpaces + stationary` para ser visible en todos los espacios. Nivel `floating`. Arrastrable via `hs.eventtap` con `leftMouseDragged` y `leftMouseUp`.

---

### init.lua

| Mecanismo | Descripción |
|---|---|
| Validación de config | Verifica `VERSION`, `delay`, `profile_order`, `profiles` al inicio; notifica y aborta si falla |
| Auto-compilación | Compila `set_browser.swift` a `set_browser` si el binario no existe |
| Prewarm de cachés | `hs.timer.doAfter(1, ...)` + `hs.timer.doEvery(30, ...)` para `bluetooth`, `browsers`, `battery`, `music` |
| `hs.caffeinate.watcher` | Detecta `systemDidWake` / `screensDidWake` → llama `handle_wake()` en breaks y pomodoro; reinicia menubar |
| `hs.shutdownCallback` | Restaura DND, Dock, escritorio; libera timers, menubars, overlay, watcher y hotkeys |

---

## Archivos de datos

### `macspaces_history.json`

```json
{
  "2026-04-15": {
    "personal": 3600,
    "work": 7200
  }
}
```

Ubicación: `~/.hammerspoon/macspaces_history.json`. Permisos 0600. Entradas > 30 días se eliminan automáticamente al registrar una sesión.

### `debug.log`

Ubicación: `~/.hammerspoon/debug.log`. Permisos 0600. Rotación automática al superar 1MB (renombra a `debug.log.old`). IPs ofuscadas (último octeto reemplazado por `***`).

### `~/.claude/usage_cache.json`

Generado externamente por `statusline.sh` del proyecto `dil-configuration`. macSpaces solo lee este archivo. Estructura esperada:

```json
{
  "updated_at": 1744000000,
  "five_hour": { "pct": 45, "reset": 1744003600 },
  "seven_day": { "pct": 12, "reset": 1744518000 }
}
```

---

## APIs externas

### ipapi.co

- **URL**: `https://ipapi.co/json/` (red local) y `https://ipapi.co/{ip}/json/` (VPN)
- **Protocolo**: HTTPS
- **Campos usados**: `ip`, `country_name`, `country_code`, `region`, `city`, `org`
- **Límite gratuito**: 1000 peticiones/día
- **TTL local**: 60s (network), 120s (vpn)
- **Módulos**: `network.lua`, `vpn.lua`

---

## Comandos del sistema

| Comando | Módulo | Propósito |
|---|---|---|
| `ioreg -r -k BatteryPercent -l` | bluetooth.lua | Batería dispositivos Apple |
| `ioreg -r -k BatteryLevel -l` | bluetooth.lua | Batería dispositivos terceros |
| `ioreg -r -k DeviceAddress -l` | bluetooth.lua | Todos los dispositivos BT activos |
| `defaults read com.apple.dock autohide` | presentation.lua | Leer estado actual del Dock |
| `defaults write com.apple.dock autohide` | presentation.lua | Cambiar autohide del Dock |
| `defaults write com.apple.finder CreateDesktop` | presentation.lua | Mostrar/ocultar íconos del escritorio |
| `killall Dock` | presentation.lua | Aplicar cambios en el Dock |
| `killall Finder` | presentation.lua | Aplicar cambios en el Finder |
| `defaults -currentHost write com.apple.notificationcenterui doNotDisturb` | dnd.lua | DND (fallback sin API nativa) |
| `swiftc set_browser.swift -o set_browser` | init.lua | Compilar helper de navegador |
| `~/.hammerspoon/set_browser [bundle_id]` | browsers.lua | Leer/cambiar navegador predeterminado |

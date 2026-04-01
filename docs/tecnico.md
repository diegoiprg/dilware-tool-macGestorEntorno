# Referencia Técnica — macSpaces v2.6.0

## API de módulos

Cada módulo expone funciones públicas a través de una tabla `M`. A continuación se documenta la API pública de cada uno.

---

### utils.lua

| Función | Descripción |
|---|---|
| `M.log(msg)` | Escribe línea con timestamp en `debug.log` |
| `M.clear_log()` | Vacía el archivo de log |
| `M.notify(title, msg)` | Notificación del sistema + log |
| `M.table_contains(tbl, item)` | Busca valor en tabla indexada |
| `M.info_item(label, value)` | Retorna ítem de menú que copia `value` al portapapeles al hacer clic |
| `M.format_time(seconds)` | Formatea segundos como `MM:SS` o `H:MM:SS` |

### config.lua

Tabla de configuración. No tiene funciones, solo datos. Ver `docs/funcional.md` para detalle de cada sección.

Campos validados al inicio por `init.lua`:
- `VERSION`: string no vacío
- `delay`: tabla con `short` > 0
- `profile_order`: tabla no vacía
- `profiles`: tabla

### profiles.lua

| Función | Descripción |
|---|---|
| `M.is_active(key)` | `true` si el perfil tiene espacio activo |
| `M.get_state(key)` | Retorna `{ space_id, started_at }` |
| `M.activate(key, on_done)` | Crea espacio, lanza apps, llama `on_done` al terminar |
| `M.deactivate(key, on_done)` | Cierra apps, elimina espacio, llama `on_done` |

### browsers.lua

| Función | Descripción |
|---|---|
| `M.display_name(bundle_id)` | Nombre legible del navegador |
| `M.installed()` | Lista de bundle IDs instalados (filtrados por allowlist) |
| `M.current()` | Bundle ID del navegador predeterminado actual |
| `M.set_default(bundle_id)` | Cambia el navegador predeterminado |
| `M.refresh_cache()` | Invalida y recarga caché |
| `M.build_submenu()` | Retorna tabla de ítems para el submenú |

### audio.lua

| Función | Descripción |
|---|---|
| `M.output_devices()` | Lista de dispositivos de salida (con caché TTL 10s) |
| `M.current_output()` | Dispositivo de salida actual |
| `M.set_output(device)` | Cambia dispositivo predeterminado |
| `M.build_submenu()` | Ítems del submenú |

### music.lua

| Función | Descripción |
|---|---|
| `M.is_running()` | `true` si Music.app está abierta |
| `M.is_playing()` | `true` si hay reproducción activa |
| `M.get_current_track()` | `{ name, artist, album }` o `nil` |
| `M.display_info()` | String formateado de la canción actual |
| `M.playpause()` / `M.next()` / `M.previous()` | Controles de reproducción |
| `M.build_submenu()` | Ítems del submenú |

### battery.lua

| Función | Descripción |
|---|---|
| `M.has_battery()` | `true` si el dispositivo tiene batería |
| `M.percentage()` | Porcentaje actual |
| `M.is_charging()` / `M.is_plugged()` | Estado de carga |
| `M.status_label()` | String formateado o `nil` si no hay batería |

### bluetooth.lua

| Función | Descripción |
|---|---|
| `M.devices()` | Lista de `{ name, battery, address }` (caché TTL 60s) |
| `M.build_submenu()` | Ítems del submenú |

Internamente usa `ioreg` con tres consultas para cubrir dispositivos Apple (`BatteryPercent`), terceros (`BatteryLevel`) y todos los conectados (`DeviceAddress`).

### network.lua

| Función | Descripción |
|---|---|
| `M.refresh(on_done)` | Refresca info local y remota. `on_done` se llama al completar |
| `M.local_info()` | `{ interface, type, local_ip, ssid }` |
| `M.remote_info()` | Datos de ipapi.co o `nil` si no se ha obtenido |
| `M.build_submenu(on_update)` | Ítems del submenú |

### vpn.lua

| Función | Descripción |
|---|---|
| `M.is_active()` | `true` si hay interfaz VPN activa |
| `M.interfaces()` | Lista de `{ interface, ip }` |
| `M.refresh(on_done)` | Refresca info geográfica del túnel |
| `M.build_submenu(on_update)` | Ítems del submenú |

### clipboard.lua

| Función | Descripción |
|---|---|
| `M.start(on_change)` | Inicia watcher del portapapeles |
| `M.stop()` | Detiene watcher |
| `M.clear()` | Limpia historial |
| `M.restore(index)` | Restaura entrada al portapapeles |
| `M.open_chooser()` | Abre buscador con `hs.chooser` |
| `M.build_submenu(on_update)` | Ítems del submenú |

### pomodoro.lua

| Función | Descripción |
|---|---|
| `M.is_active()` | `true` si el Pomodoro está corriendo |
| `M.current_phase()` | `"work"`, `"short_break"` o `"long_break"` |
| `M.cycles_completed()` | Número de ciclos completados |
| `M.time_label()` | String con ícono y tiempo restante |
| `M.start()` / `M.stop()` / `M.skip()` | Control del temporizador |
| `M.build_submenu(on_update)` | Ítems del submenú |

### breaks.lua

| Función | Descripción |
|---|---|
| `M.is_enabled()` | `true` si está activo |
| `M.enable(on_update)` / `M.disable(on_update)` / `M.toggle(on_update)` | Control |
| `M.build_submenu(on_update)` | Ítems del submenú |

### presentation.lua

| Función | Descripción |
|---|---|
| `M.is_active()` | `true` si el modo está activo |
| `M.toggle(on_done)` | Activa/desactiva con confirmación |
| `M.build_submenu(on_update)` | Ítems del submenú |

### history.lua

| Función | Descripción |
|---|---|
| `M.record_session(key, started_at)` | Registra duración de sesión |
| `M.today_seconds(key)` | Segundos acumulados hoy para un perfil |
| `M.build_submenu()` | Ítems del submenú |

### hotkeys.lua

| Función | Descripción |
|---|---|
| `M.register(on_change)` | Registra atajos globales desde `cfg.hotkeys` |
| `M.unregister()` | Elimina todos los atajos |

### dnd.lua

| Función | Descripción |
|---|---|
| `M.enable()` / `M.disable()` | Activa/desactiva No Molestar |
| `M.is_enabled()` | Estado actual (`nil` si no hay API nativa) |
| `M.toggle()` | Alterna estado |

Usa `hs.focus` (Hammerspoon 0.9.97+) con fallback a `defaults -currentHost`.

### menu.lua

| Función | Descripción |
|---|---|
| `M.init()` | Crea menubar, precarga íconos, registra `setMenu(fn)` |
| `M.build()` | Actualiza título del ícono |
| `M.destroy()` | Elimina menubar |

---

## Archivos de datos

### `macspaces_history.json`

```json
{
  "2026-03-28": {
    "personal": 3600,
    "work": 7200
  }
}
```

Claves: fecha ISO. Valores: segundos acumulados por perfil. Entradas > 30 días se eliminan automáticamente.

### `debug.log`

```
[2026-03-28 10:00:00] [INFO] macSpaces v2.6.0 iniciado
[2026-03-28 10:00:01] [INFO] Clipboard watcher iniciado
[2026-03-28 10:05:00] [OK] Safari movida a espacio 42
```

Se limpia en cada inicio. No tiene rotación ni límite de tamaño.

---

## APIs externas

### ipapi.co

- **URL**: `https://ipapi.co/json/` (HTTPS)
- **Campos utilizados**: `ip`, `country_name`, `country_code`, `region`, `city`, `org`
- **Límite**: 45 peticiones/minuto (plan gratuito)
- **Uso**: `network.lua` (IP del usuario), `vpn.lua` (IP del túnel)

### Comandos del sistema

| Comando | Módulo | Propósito |
|---|---|---|
| `ioreg -r -k BatteryPercent -l` | bluetooth.lua | Batería de dispositivos Apple |
| `ioreg -r -k BatteryLevel -l` | bluetooth.lua | Batería de dispositivos terceros |
| `ioreg -r -k DeviceAddress -l` | bluetooth.lua | Todos los dispositivos BT |
| `defaults read/write com.apple.dock autohide` | presentation.lua | Dock autohide |
| `defaults write com.apple.finder CreateDesktop` | presentation.lua | Íconos del escritorio |
| `killall Dock` / `killall Finder` | presentation.lua | Aplicar cambios |
| `defaults -currentHost write/read com.apple.notificationcenterui doNotDisturb` | dnd.lua | DND (fallback) |
| `killall NotificationCenter` | dnd.lua | Aplicar DND (fallback) |

# Referencia Técnica — macSpaces v2.7.1

## API de módulos

Cada módulo expone funciones públicas a través de una tabla `M`.

---

### utils.lua

| Función | Descripción |
|---|---|
| `M.log(msg)` | Escribe línea con timestamp en `debug.log` (permisos 0600, rotación 1MB, IPs ofuscadas) |
| `M.clear_log()` | Vacía el archivo de log |
| `M.notify(title, msg)` | Notificación del sistema + log |
| `M.table_contains(tbl, item)` | Busca valor en tabla indexada |
| `M.info_item(label, value)` | Ítem de menú que copia `value` al portapapeles |
| `M.disabled_item(label)` | Ítem de menú no accionable (`disabled = true`) |
| `M.format_time(seconds)` | Formatea segundos como `MM:SS` o `H:MM:SS` |

### config.lua

Tabla de configuración. Campos validados al inicio por `init.lua`:
- `VERSION`: string no vacío
- `delay`: tabla con `short` > 0
- `profile_order`: tabla no vacía
- `profiles`: tabla

### profiles.lua

| Función | Descripción |
|---|---|
| `M.is_active(key)` | `true` si el perfil tiene espacio activo |
| `M.get_state(key)` | Retorna `{ space_id, started_at, prev_browser }` |
| `M.activate(key, on_done)` | Crea espacio, lanza apps, guarda navegador previo |
| `M.deactivate(key, on_done)` | Cierra apps, elimina espacio, restaura navegador |

### browsers.lua

| Función | Descripción |
|---|---|
| `M.display_name(bundle_id)` | Nombre legible del navegador |
| `M.installed()` | Lista de bundle IDs instalados (con caché) |
| `M.current()` | Bundle ID del navegador predeterminado actual |
| `M.set_default(bundle_id)` | Cambia el navegador predeterminado |
| `M.refresh_cache()` | Invalida y recarga caché |
| `M.build_submenu()` | Ítems del submenú |

### audio.lua

| Función | Descripción |
|---|---|
| `M.output_devices()` | Lista de dispositivos de salida (caché TTL 10s) |
| `M.current_output()` | Dispositivo de salida actual |
| `M.set_output(device)` | Cambia dispositivo predeterminado |
| `M.build_submenu()` | Ítems del submenú |

### music.lua

| Función | Descripción |
|---|---|
| `M.is_running()` | `true` si Music.app está abierta (caché TTL 3s) |
| `M.is_playing()` | `true` si hay reproducción activa |
| `M.get_current_track()` | `{ name, artist, album }` o `nil` |
| `M.playpause()` / `M.next()` / `M.previous()` | Controles de reproducción |
| `M.build_submenu()` | Ítems del submenú |

### battery.lua

| Función | Descripción |
|---|---|
| `M.has_battery()` | `true` si el dispositivo tiene batería (caché permanente) |
| `M.percentage()` | Porcentaje actual |
| `M.is_charging()` / `M.is_plugged()` | Estado de carga |
| `M.build_submenu()` | Submenú con porcentaje, estado, ciclos, tiempo restante |

### bluetooth.lua

| Función | Descripción |
|---|---|
| `M.devices()` | Lista de `{ name, battery, address }` (caché TTL 120s) |
| `M.build_submenu()` | Ítems del submenú |

### network.lua

| Función | Descripción |
|---|---|
| `M.refresh(on_done)` | Refresca info local y remota |
| `M.local_info()` | `{ interface, type, local_ip, ssid }` |
| `M.remote_info()` | Datos de ipapi.co o `nil` |
| `M.build_submenu(on_update)` | Ítems del submenú |

### vpn.lua

| Función | Descripción |
|---|---|
| `M.is_active()` | `true` si hay interfaz VPN activa (caché TTL 10s) |
| `M.interfaces()` | Lista de `{ interface, ip }` (caché TTL 10s) |
| `M.refresh(on_done)` | Refresca info geográfica del túnel |
| `M.build_submenu(on_update)` | Ítems del submenú |

### clipboard.lua

| Función | Descripción |
|---|---|
| `M.start(on_change)` | Inicia watcher (filtra apps en blocklist) |
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
| `M.menubar_label()` | Etiqueta corta para menubar (`🍅 23m`) |
| `M.set_menubar_updater(fn)` | Registra callback para actualizar menubar |
| `M.start()` / `M.stop()` / `M.skip()` | Control del temporizador |
| `M.build_submenu(on_update)` | Ítems del submenú |

Notificaciones incluyen datos educativos rotativos (Cirillo, Baumeister, Dehaene, DeMarco).

### breaks.lua

| Función | Descripción |
|---|---|
| `M.is_enabled()` | `true` si está activo (default: `true`) |
| `M.seconds_since_break()` | Segundos desde el último descanso |
| `M.idle_label()` | `"⏱ 12:34 sin descanso"` o `nil` si < 5 min |
| `M.enable(on_update)` / `M.disable(on_update)` / `M.toggle(on_update)` | Control |
| `M.build_submenu(on_update)` | Ítems del submenú (incluye tiempo sin descanso) |

Notificaciones incluyen datos educativos rotativos (AAO, OSHA, Mayo Clinic, Cornell, AHA).

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
| `M.is_enabled()` | Estado actual |
| `M.toggle()` | Alterna estado |

### menu.lua

| Función | Descripción |
|---|---|
| `M.init()` | Crea menubar, carga ícono, construye menú, inicia timer de reconstrucción (5s) |
| `M.build()` | Reconstruye menú en segundo plano (diferido) |
| `M.destroy()` | Elimina menubar y timer |

### focus_menu.lua

| Función | Descripción |
|---|---|
| `M.init()` | Crea menubar de enfoque, inicia overlay, timer de reconstrucción (5s) |
| `M.build()` | Reconstruye menú y refresca overlay |
| `M.destroy()` | Elimina menubar, timer y overlay |

### focus_overlay.lua

| Función | Descripción |
|---|---|
| `M.start()` | Muestra overlay y arranca timer de actualización (1s) |
| `M.stop()` | Oculta overlay y detiene timer |
| `M.refresh()` | Actualiza contenido del overlay |

Usa `hs.canvas` con `canJoinAllSpaces` (visible en todos los espacios). El canvas se crea una sola vez y se actualiza en lugar de destruirse/recrearse, evitando parpadeo. Incluye fallback si `hs.drawing.getTextDrawingSize` (API deprecada) falla.

---

### init.lua

| Función / Mecanismo | Descripción |
|---|---|
| Validación de config | Verifica campos obligatorios al inicio |
| Prewarm de cachés | Timer cada 30s para mantener cachés calientes |
| `hs.shutdownCallback` | Limpieza al cerrar, reiniciar o recargar: restaura DND, Dock, escritorio; libera timers, menubars, overlay, watcher y hotkeys |

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

Permisos 0600. Entradas > 30 días se eliminan automáticamente.

### `debug.log`

Permisos 0600. Rotación automática al superar 1MB. IPs ofuscadas en el log.

---

## APIs externas

### ipapi.co

- **URL**: `https://ipapi.co/json/` (HTTPS)
- **Campos**: `ip`, `country_name`, `country_code`, `region`, `city`, `org`
- **Límite**: 45 peticiones/minuto (plan gratuito)
- **Uso**: `network.lua` (IP del usuario), `vpn.lua` (IP del túnel)

### Comandos del sistema

| Comando | Módulo | Propósito |
|---|---|---|
| `ioreg -r -k BatteryPercent -l` | bluetooth.lua | Batería dispositivos Apple |
| `ioreg -r -k BatteryLevel -l` | bluetooth.lua | Batería dispositivos terceros |
| `ioreg -r -k DeviceAddress -l` | bluetooth.lua | Todos los dispositivos BT |
| `defaults read/write com.apple.dock autohide` | presentation.lua | Dock autohide |
| `defaults write com.apple.finder CreateDesktop` | presentation.lua | Íconos del escritorio |
| `killall Dock` / `killall Finder` | presentation.lua | Aplicar cambios |

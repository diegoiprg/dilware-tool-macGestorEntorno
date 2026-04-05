# Especificación Funcional — macSpaces v2.10.0

## Propósito

Centralizar el control del entorno de trabajo en macOS desde dos íconos en la barra de menú: uno para gestión del entorno (perfiles, dispositivos, red) y otro para gestión del enfoque (Pomodoro, descanso, presentación).

---

## Arquitectura de menús

macSpaces presenta dos menús independientes en la menubar:

### Menú principal (⌘)
Gestión del entorno de trabajo: perfiles, navegador, audio, música, dispositivos, red, portapapeles.

### Menú de enfoque (◎)
Gestión de la concentración: Pomodoro, descanso activo, modo presentación. El ícono cambia dinámicamente según el estado:
- `🍅 23m` — Pomodoro activo
- `🎬` — Presentación activa
- `◎` — Por defecto

### Overlay flotante
Banner unificado en esquina inferior derecha, visible en todos los espacios. Contiene filas coloreadas independientes por estado:
- 🍅 Pomodoro (rojo): countdown regresivo con fase y ciclo
- ☕/🌿 Pausa (verde): countdown de pausa corta o larga
- ◎ Descanso (azul): countdown regresivo hasta el próximo descanso
- 🎬 Presentación (púrpura): indicador de modo activo

Arrastrable para reposicionar. La posición se mantiene durante la sesión. Se oculta automáticamente cuando no hay estado activo.

---

## Módulos funcionales

### 1. Perfiles de trabajo (`profiles.lua`)

Aísla contextos en espacios virtuales dedicados con apps asociadas.

- Activar: crea espacio, navega, lanza apps, mueve ventanas, cambia navegador.
- Desactivar: cierra apps, reubica ventanas huérfanas, elimina espacio, restaura navegador previo, registra sesión.
- Confirmación configurable al desactivar (`confirm_deactivate`).
- Atajos: ⌘⌥1 (Personal), ⌘⌥2 (Work).

| Perfil | Apps | Navegador |
|---|---|---|
| Personal | Safari | Safari |
| Work | Outlook PWA, Teams PWA, OneDrive, Edge | Microsoft Edge |

### 2. Navegador predeterminado (`browsers.lua`)

Cambia el navegador predeterminado del sistema sin diálogos del SO. Usa un helper Swift nativo (`set_browser`) que invoca `NSWorkspace.setDefaultApplication`.

- Allowlist configurable (Safari, Chrome, Edge, Firefox, Brave, Opera, Vivaldi, Arc).
- Checkmark en el navegador activo.
- Banner "Actual: ..." en el submenú.
- Reintento automático si la API falla silenciosamente.
- El helper se auto-compila al iniciar si no existe (`init.lua`).

### 3. Audio (`audio.lua`)

Cambia el dispositivo de salida de audio predeterminado. Caché de 10 segundos.

### 4. Apple Music (`music.lua`)

Controla Apple Music via AppleScript: play/pause, siguiente, anterior, canción actual. Si Music.app no está abierta, ofrece abrirla.

### 5. Batería (`battery.lua`)

Submenú con porcentaje, estado de carga, ciclos, tiempo restante. Solo visible en MacBook.

### 6. Bluetooth (`bluetooth.lua`)

Dispositivos BT conectados con nivel de batería via `ioreg`. Íconos por tipo. Caché de 120 segundos.

### 7. Red (`network.lua`)

Info local (tipo, SSID, IP) y remota (IP externa, país, ISP via ipapi.co). TTL 60s.

### 8. VPN (`vpn.lua`)

Detección de VPN activa con geolocalización del túnel. Interfaces cacheadas con TTL 10s. Solo visible cuando hay VPN activa.

### 9. Portapapeles (`clipboard.lua`)

Historial de las últimas 20 entradas. Restaurar con clic, búsqueda via `hs.chooser`. Blocklist de apps sensibles configurable. Solo en memoria.

### 10. Lanzador rápido (`launcher.lua`)

Acceso directo a apps favoritas. Configurable en `config.lua`. No aparece si no hay apps.

### 11. Pomodoro (`pomodoro.lua`)

Temporizador con ciclos configurables y DND automático.

- Trabajo: 25 min → Pausa corta: 5 min → Pausa larga: 15 min (cada 4 ciclos).
- Countdown visible en ícono del menú de enfoque y en overlay flotante.
- Etiquetas descriptivas: "🍅 Pomodoro · 24:30 · Ciclo 1/4", "☕ Pausa corta · 04:30 · Ciclo 1/4".
- Basado en reloj de pared (`os.time`) para precisión independiente del timer.
- Notificaciones con datos educativos rotativos sobre productividad (Cirillo, Baumeister, Dehaene, DeMarco).
- Reinicio automático del ciclo tras suspensión del sistema.

### 12. Descanso activo (`breaks.lua`)

Recordatorios periódicos para postura y vista. Activado por defecto.

- Intervalo configurable: 30/45/50/60/90 min (default: 50).
- Mensajes rotativos con datos educativos de salud (AAO, OSHA, Mayo Clinic, Cornell, AHA).
- Countdown regresivo visible en overlay flotante (tiempo restante hasta el próximo descanso).
- Se activa automáticamente al iniciar/recargar Hammerspoon si está habilitado en config.
- Reinicio automático del ciclo tras suspensión del sistema (tratado como ciclo nuevo).
- Timer de display (60s) ahora cancelable — desactivar durante el display cancela el ciclo correctamente.

### 13. Modo presentación (`presentation.lua`)

Activa DND, oculta Dock e íconos del escritorio. Confirmación antes de activar. Restaura estado al desactivar.

### 14. Historial de sesiones (`history.lua`)

Tiempo acumulado por perfil durante el día. Persistido en JSON. Limpieza automática > 30 días.

### 15. Sistema

- **Versión**: semver visible al final del menú principal (`macSpaces vX.Y.Z`).
- **Registro**: abre `debug.log` en Console.app.
- **Recargar**: ejecuta `hs.reload()`.
- **Wake detection**: `hs.caffeinate.watcher` en `init.lua` detecta `systemDidWake` y `screensDidWake`. Al despertar llama `breaks.handle_wake()` y `pomodoro.handle_wake()`, y reinicia la menubar.

---

## Configuración (`config.lua`)

| Sección | Parámetros clave |
|---|---|
| `profiles` | Apps y navegador por perfil |
| `profile_order` | Orden en el menú |
| `hotkeys` | Modificadores y tecla por perfil |
| `browser_names` | Allowlist de navegadores |
| `delay` | Tiempos de espera (short, medium, app_launch) |
| `pomodoro` | Duración de ciclos, pausas, DND |
| `breaks` | Intervalo, estado inicial (default: activado) |
| `clipboard` | Máximo de entradas, blocklist de apps |
| `presentation` | DND, Dock, escritorio |
| `launcher` | Apps con nombre e ícono |
| `menu_icon` | Carácter del ícono en menubar |

# Especificación Funcional — macSpaces v2.11.2

## Tabla de contenido

- [Propósito](#propósito)
- [Arquitectura de menús](#arquitectura-de-menús)
- [Módulos funcionales](#módulos-funcionales)
  - [1. Perfiles de trabajo](#1-perfiles-de-trabajo)
  - [2. Navegador predeterminado](#2-navegador-predeterminado)
  - [3. Audio](#3-audio)
  - [4. Apple Music](#4-apple-music)
  - [5. Batería](#5-batería)
  - [6. Bluetooth](#6-bluetooth)
  - [7. Red](#7-red)
  - [8. VPN](#8-vpn)
  - [9. Portapapeles](#9-portapapeles)
  - [10. Lanzador rápido](#10-lanzador-rápido)
  - [11. Pomodoro](#11-pomodoro)
  - [12. Descanso activo](#12-descanso-activo)
  - [13. Modo presentación](#13-modo-presentación)
  - [14. Monitor de Claude](#14-monitor-de-claude)
  - [15. Historial de sesiones](#15-historial-de-sesiones)
  - [16. Sistema](#16-sistema)
- [Overlay flotante](#overlay-flotante)
- [Configuración](#configuración)

---

## Propósito

Centralizar el control del entorno de trabajo en macOS desde dos íconos en la barra de menú: uno para gestión del entorno (perfiles, dispositivos, red, Claude) y otro para gestión del enfoque (Pomodoro, descanso, presentación).

---

## Arquitectura de menús

macSpaces presenta dos menús independientes en la menubar:

### Menú principal (⌘)

Gestión del entorno de trabajo: perfiles, navegador, audio, música, dispositivos, red, portapapeles, Claude. Reconstrucción automática cada 5 segundos en segundo plano.

### Menú de enfoque (◎)

Gestión de la concentración: Pomodoro, descanso activo, modo presentación. El ícono es estático (◎ por defecto, configurable).

### Overlay flotante

Banner unificado en esquina inferior derecha (posición configurable), visible en todos los espacios de Mission Control. Contiene filas coloreadas independientes por estado activo:

| Estado | Color | Contenido |
|---|---|---|
| Pomodoro trabajo | Rojo | Countdown regresivo, fase y ciclo |
| Pomodoro pausa | Verde | Countdown de pausa corta o larga |
| Descanso pendiente | Azul | Countdown hasta el próximo descanso |
| Descanso en curso | Verde | Countdown del banner de descanso |
| Presentación activa | Púrpura | Indicador de modo activo |
| Claude (baja carga) | Verde oscuro | Uso 5h y/o 7d con % y tiempo de reset |
| Claude (media carga) | Amarillo | Ídem |
| Claude (alta carga) | Rojo | Ídem |

Arrastrable para reposicionar. La posición se mantiene en memoria durante la sesión y se resetea al recargar Hammerspoon. Se oculta automáticamente cuando no hay ningún estado activo.

---

## Módulos funcionales

### 1. Perfiles de trabajo

`profiles.lua` — Aisla contextos en espacios virtuales dedicados con apps asociadas.

**Activar perfil:**
1. Crea un nuevo espacio de Mission Control
2. Navega al nuevo espacio
3. Lanza cada app del perfil con delay configurable
4. Mueve cada ventana al nuevo espacio
5. Cambia el navegador predeterminado al vinculado con el perfil
6. Notifica al usuario

**Desactivar perfil:**
1. Solicita confirmación si `confirm_deactivate = true`
2. Cierra todas las apps del perfil
3. Mueve ventanas huérfanas al espacio principal
4. Navega al espacio principal
5. Elimina el espacio del perfil
6. Restaura el navegador predeterminado previo
7. Registra la sesión en el historial
8. Notifica al usuario

**Perfiles disponibles:**

| Perfil | Hotkey | Apps | Navegador |
|---|---|---|---|
| Personal | ⌘⌥1 | Safari | Safari |
| Work | ⌘⌥2 | Outlook PWA, Teams PWA, OneDrive, Edge | Microsoft Edge |

El menú muestra el tiempo activo inline: `● Work — 1:23:45`.

---

### 2. Navegador predeterminado

`browsers.lua` — Cambia el navegador predeterminado del sistema sin diálogos del SO.

- Usa helper Swift nativo (`set_browser`) via `NSWorkspace.setDefaultApplication`
- Allowlist configurable en `cfg.browser_names` (Safari, Chrome, Edge, Firefox, Brave, Opera, Vivaldi, Arc)
- Checkmark en el navegador activo
- Banner "Actual: ..." en el submenú
- Reintento automático (hasta 2 veces) si la API falla silenciosamente
- El helper se auto-compila al iniciar si el binario no existe

---

### 3. Audio

`audio.lua` — Cambia el dispositivo de salida de audio predeterminado.

- Lista todos los dispositivos de salida disponibles
- Checkmark en el dispositivo activo
- Caché de 10 segundos para evitar consultas repetidas
- Solo notifica en caso de error (no al cambiar exitosamente, siguiendo HIG)

---

### 4. Apple Music

`music.lua` — Control de Apple Music via AppleScript.

- Muestra canción actual (título, artista, álbum) si Music.app está abierta
- Controles: play/pause, siguiente, anterior
- Si Music.app no está abierta, ofrece abrirla
- Caché de 3 segundos para estado y pista actual

---

### 5. Batería

`battery.lua` — Submenú con información de batería. Solo visible en MacBook.

- Porcentaje actual con clic para copiar
- Estado: cargando, conectado o usando batería
- Ciclos de carga
- Tiempo restante estimado
- Alertas en batería baja (<40%) y crítica (<20%)

---

### 6. Bluetooth

`bluetooth.lua` — Dispositivos BT conectados con nivel de batería.

- Parsea `ioreg` para obtener nombre, batería y dirección MAC
- Íconos por tipo de dispositivo: auriculares, mouse, teclado, trackpad, parlante
- Caché de 120 segundos (consulta `ioreg` es costosa)
- Deduplicación por nombre, priorizando entradas con datos de batería
- Contador de dispositivos visible inline en el menú: `Dispositivos (3)`

---

### 7. Red

`network.lua` — Información de la conexión actual.

- Tipo de conexión: WiFi, Ethernet o VPN
- SSID de la red WiFi
- IP local
- IP externa, país, región, ciudad e ISP via ipapi.co (asíncrono, TTL 60s)
- Botón de actualización manual

---

### 8. VPN

`vpn.lua` — Detección de VPN activa con información del túnel.

- Detecta interfaces `utun*` y `ppp*` activas con IPv4
- Excluye interfaces del sistema (iCloud Private Relay, Handoff, AirDrop)
- Muestra IP del túnel e información geográfica via ipapi.co
- Solo aparece en el menú cuando hay VPN activa
- Caché de interfaces: TTL 10s; caché de info remota: TTL 120s

---

### 9. Portapapeles

`clipboard.lua` — Historial del portapapeles en memoria.

- Captura automáticamente via `hs.pasteboard.watcher` (event-driven)
- Hasta 20 entradas configurables (`cfg.clipboard.max_entries`)
- Soporta texto, imágenes y URLs
- Deduplicación de entradas consecutivas idénticas
- Blocklist de apps sensibles en `cfg.clipboard.ignore_apps` (1Password, Bitwarden, etc.)
- Restaurar cualquier entrada con un clic
- Búsqueda via `hs.chooser` con filtrado en tiempo real
- No persiste al recargar Hammerspoon

---

### 10. Lanzador rápido

`launcher.lua` — Acceso directo a apps favoritas.

- Configurable en `cfg.launcher.apps` (string o `{ name, icon }`)
- No aparece en el menú si la lista está vacía
- Usa `hs.application.launchOrFocus` (lanza o trae al frente)

---

### 11. Pomodoro

`pomodoro.lua` — Temporizador con ciclos configurables y DND integrado.

**Ciclo por defecto:**
- Trabajo: 25 min → Pausa corta: 5 min → ... → Pausa larga: 15 min (cada 4 ciclos)

**Comportamiento:**
- DND se activa automáticamente durante el trabajo y se desactiva en pausas
- Countdown visible en el overlay flotante con fase y número de ciclo
- Etiqueta en el overlay: `🍅 Pomodoro · 24:30 · Ciclo 1/4`
- Tiempo calculado con reloj de pared (`os.time()`) para precisión tras suspensión
- Al despertar el sistema: evalúa si la fase expiró y avanza o reinicia el timer
- Notificaciones con datos educativos rotativos (Cirillo, Baumeister, Dehaene, DeMarco)
- Notificaciones via `utils.alert_notify()`: canvas grande + sonido del sistema

---

### 12. Descanso activo

`breaks.lua` — Recordatorios periódicos para salud postural y visual.

**Comportamiento:**
- Activado por defecto cada 50 minutos (configurable: 30/45/50/60/90 min)
- Al disparar: muestra banner durante 120 segundos (`break_display_seconds`)
- Durante el banner: la fila del overlay cambia de azul a verde
- Después del banner: reinicia el ciclo si breaks sigue habilitado
- Al despertar el sistema: reinicia ciclo (la suspensión cuenta como descanso)
- `display_timer` cancelable si el usuario desactiva breaks durante el display

**Mensajes rotativos (7 categorías):**
1. Vista — Regla 20-20-20 (AAO)
2. Cuello y hombros — Estiramiento cervical (OSHA)
3. Muñecas y manos — Prevención túnel carpiano (Mayo Clinic)
4. Movilidad — Caminar 2 minutos (AHA)
5. Espalda lumbar — Flexión lumbar (OSHA)
6. Respiración — Técnica 4-7-8 (Harvard Med)
7. Hidratación — Consumo de agua (EFSA)

Cada mensaje incluye 3 pasos concretos + dato educativo con fuente.

---

### 13. Modo presentación

`presentation.lua` — Prepara el escritorio para presentaciones.

Al activar (con confirmación previa):
- Activa No Molestar
- Habilita autohide del Dock (oculta el Dock)
- Oculta íconos del escritorio (`CreateDesktop = false`)
- Reinicia Finder y Dock para aplicar cambios

Al desactivar:
- Restaura el estado previo del Dock (autohide o visible)
- Desactiva No Molestar
- Restaura íconos del escritorio
- Reinicia Finder y Dock

---

### 14. Monitor de Claude

`claude.lua` — Monitoreo de uso de rate limits de Claude Code.

- Lee `~/.claude/usage_cache.json` (generado externamente por `statusline.sh`)
- Muestra ventana de 5 horas y ventana de 7 días
- Barra de progreso con caracteres `▰▱` (8 o 10 caracteres según contexto)
- Porcentaje de uso y tiempo hasta el reset
- Color semáforo: verde (<60%), amarillo (60–84%), rojo (≥85%)
- En MacBook: modo compacto sin barra de progreso para ahorrar espacio
- Caché de 60 segundos; ignora caches con más de 6 horas de antigüedad
- El submenú incluye botón de actualización e ítem para abrir `claude.ai/settings/usage`

---

### 15. Historial de sesiones

`history.lua` — Tiempo acumulado por perfil durante el día.

- Se registra automáticamente al desactivar un perfil (mínimo 10 segundos)
- Persiste en `~/.hammerspoon/macspaces_history.json`
- Muestra tiempo de hoy por perfil activo
- Limpieza automática de entradas con más de 30 días

---

### 16. Sistema

Ítems fijos en el menú principal:

- **Versión**: semver visible al final (`macSpaces v2.11.2`)
- **Registro**: abre `~/.hammerspoon/debug.log` en Console.app
- **Recargar**: ejecuta `hs.reload()` para aplicar cambios en config.lua

**Wake detection** (`hs.caffeinate.watcher` en `init.lua`): detecta `systemDidWake` y `screensDidWake`. Al despertar, llama `breaks.handle_wake()` y `pomodoro.handle_wake()`, y reinicia la menubar.

---

## Overlay flotante

El overlay es el canal de información pasiva de macSpaces. Se muestra solo cuando hay al menos un estado activo.

**Posición**: se mantiene en memoria durante la sesión activa; se resetea al recargar Hammerspoon. Por defecto: esquina inferior derecha de la pantalla primaria.

**Arrastre**: mouseDown inicia el drag via `hs.eventtap`. mouseUp actualiza la posición en memoria.

**Detección de dispositivo**: en MacBook (detectado via `hs.host.localizedName()`), las filas de Claude usan formato compacto sin barra de progreso para evitar solapamiento con el Dock.

**Actualización**: cada segundo via `hs.timer.doEvery(1, ...)`. Se omite la actualización si hay un drag activo.

---

## Configuración

Consulta [docs/configuracion.md](configuracion.md) para la guía completa de todos los parámetros de `config.lua`.

**Resumen de secciones:**

| Sección | Parámetros clave |
|---|---|
| `profiles` | Apps y navegador por perfil, confirmación al desactivar |
| `profile_order` | Orden de aparición en el menú |
| `hotkeys` | Modificadores y tecla por perfil |
| `browser_names` | Allowlist de navegadores reconocidos |
| `delay` | Tiempos de espera (short, medium, app_launch) |
| `pomodoro` | Duración de ciclos, pausas, DND automático |
| `breaks` | Intervalo, estado inicial, duración del banner |
| `clipboard` | Máximo de entradas, blocklist de apps |
| `presentation` | DND, Dock, escritorio |
| `launcher` | Apps con nombre e ícono |
| `menu_icon` | Carácter del ícono del menú principal |
| `focus_icon` | Carácter del ícono del menú de enfoque |

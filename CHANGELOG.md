# Changelog

Registro de cambios del proyecto `dilware-tool-macGestorEntorno`.

## [2.6.0] - 2026-03-27

### Agregado
- `music.lua`: nuevo módulo para controlar Apple Music — muestra canción actual, artista y controles (play/pause, siguiente, anterior)
- Menú de Apple Music integrado en la barra de estado después de Audio
- SF Symbols para todos los ítems del menú siguiendo Apple Human Interface Guidelines

### Cambiado
- Menú reducido y más limpio: nombres más cortos (ej: "Navegador" en vez de "Navegador predeterminado")
- Íconos SF Symbols en lugar de emojis para consistencia con macOS
- Checkmarks visuales para elementos activos usando `checkmark.circle.fill`
- Validación de configuración al inicio de la aplicación

### Corregido
- `browsers.lua`: cacheo implementado para evitar múltiples diálogos del sistema al cambiar navegador
- Versión bumpeada a v2.6.0

## [2.5.0] - 2026-03-17

### Agregado
- `config.lua`: perfil Work reemplaza apps nativas de Microsoft (Outlook, Teams) por sus PWAs instaladas en `~/Applications/Edge Apps.localized/` — evita restricciones MDM que bloquean las apps nativas en entornos corporativos
- `config.lua`: OneDrive agregado al perfil Work como PWA (`Microsoft OneDrive`)

### Cambiado
- Versión bumpeada a v2.5.0

## [2.4.0] - 2026-03-16

### Corregido
- `profiles.lua`: `on_done` y la notificación "activado" ahora se llaman después de que TODOS los timers de lanzamiento de apps hayan terminado — antes se llamaban prematuramente, antes de que las apps estuvieran en su espacio
- `history.lua`: `prune_old_entries()` ya no modifica la tabla mientras itera con `pairs()` — comportamiento indefinido en Lua 5.4; ahora recolecta claves a eliminar en una lista separada y las borra en un segundo paso
- `clipboard.lua`: deduplicación de imágenes consecutivas corregida — antes `history[1].label == "[Imagen]"` ignoraba cualquier imagen si la anterior también era imagen; ahora se compara por tipo directamente
- `menu.lua`: guard para `battery.percentage()` nil en el ítem de batería — `math.floor(nil)` causaba crash en el instante de inicialización; ahora muestra "?%" como fallback
- `install.sh`: variable `local_bak` renombrada a `bak_dir` — `local` fuera de función es inválido en bash estricto y puede causar error en shells distintos de bash

### Mejorado
- `init.lua`: `package.path` ya no acumula rutas duplicadas en recargas sucesivas (`hs.reload`) — se verifica si la ruta ya está incluida antes de concatenar
- `vpn.lua`: eliminado wrapper `info_item()` local que solo delegaba a `utils.info_item()` — código muerto/redundante
- `pomodoro.lua`: mensaje de notificación al detener simplificado — pluralización más legible y mantenible
- `presentation.lua`: documentado que `hs.dialog.blockAlert` es síncrono e intencional en este contexto

### Cambiado
- Versión bumpeada a v2.4.0

## [2.3.1] - 2026-03-16

### Corregido
- `hotkeys.lua`: línea rota en el bucle `for key, binding in pairs(cfg.hotkeys)` — artefacto de edición anterior que pegaba dos sentencias en una sola línea, causando error de sintaxis Lua
- `menu.lua`: guard para `HOME` nil en la función "Ver registro" — inconsistente con el fix aplicado en `utils.lua` en v2.3.0
- `profiles.lua`: inicialización del estado con `ipairs(cfg.profile_order)` en lugar de `pairs(cfg.profiles)` — garantiza orden determinístico y consistencia con el array de orden definido en config

### Cambiado
- Versión bumpeada a v2.3.1

## [2.3.0] - 2026-03-16

### Corregido
- `vpn.lua`: `fetch_tunnel_info()` ya no consulta ip-api.com si `tunnel_ip` es nil — evitaba exponer la IP real del usuario en lugar de la del túnel VPN
- `dnd.lua`: `M.toggle()` sin API nativa (`hs.focus`) ahora lee el estado actual antes de cambiar — antes siempre activaba DND, nunca desactivaba
- `breaks.lua`: eliminada asignación `state.on_update = on_update` en `M.enable()` — campo no declarado en el estado inicial (código muerto residual)
- `history.lua`: `load_data()` valida que el JSON decodificado sea una tabla — evita crash con archivos malformados o con estructura inesperada
- `install.sh`: `pull --ff-only` ya no aborta el script si hay cambios locales — informa al usuario con mensaje claro y continúa con la versión local
- `install.sh`: respaldo `macspaces.bak/` ya no sobreescribe silenciosamente — el respaldo anterior se renombra con timestamp antes de crear el nuevo

### Mejorado
- `utils.lua`: nueva función `M.info_item(label, value)` compartida — elimina duplicación entre `network.lua` y `vpn.lua`
- `utils.lua`: guard para `HOME` nil — `logFilePath` usa `/tmp` como fallback en entornos restringidos
- `history.lua`: guard para `HOME` nil en `history_path`
- `history.lua`: nueva función `prune_old_entries()` — elimina entradas con más de 30 días al registrar una sesión; evita crecimiento indefinido del JSON
- `bluetooth.lua`: caché de 30 segundos en `M.devices()` — evita llamadas repetidas a `ioreg` (proceso externo) en cada apertura del menú
- `battery.lua`: rango 40–79% ahora muestra "Carga media" — distinguible visualmente de 80–100%
- `menu.lua`: ítem de batería ahora copia el porcentaje al portapapeles al hacer clic
- `menu.lua`: VPN inactiva ya no abre submenú vacío — muestra ítem informativo `VPN 🔓` directamente
- `network.lua` y `vpn.lua`: usan `utils.info_item()` en lugar de función local duplicada
- `hotkeys.lua`: iteración sobre `cfg.hotkeys` documentada (orden no garantizado por `pairs()`, aceptable para hotkeys independientes)

### Cambiado
- Versión bumpeada a v2.3.0

## [2.2.3] - 2026-03-16

### Corregido
- `network.lua` y `vpn.lua`: botón "Actualizar" llamaba `on_update` dos veces — eliminada llamada redundante tras `M.refresh(on_update)`
- `bluetooth.lua`: `battery_icon()` tenía rama muerta para < 20% — ahora devuelve ⚠️ para crítico, 🪫 para medio/bajo, 🔋 para alto
- `breaks.lua`: eliminado campo `state.on_update` que se asignaba pero nunca se usaba (código muerto)
- `clipboard.lua`: reemplazado polling `hs.timer.doEvery(1, ...)` por `hs.pasteboard.watcher` nativo (event-driven, sin CPU innecesaria)
- `presentation.lua`: indicadores del submenú ahora muestran estado real (activo/inactivo) en lugar de solo la configuración estática
- `menu.lua`: ítem "Lanzador" ya no aparece si `cfg.launcher.apps` está vacío (evita ruido para usuarios que no lo configuraron)
- `menu.lua`: "Ver registro" ahora abre el log con Console.app en lugar de la app por defecto del sistema
- `pomodoro.lua`: eliminado `¡` en mensaje de notificación de inicio de ciclo (inconsistente con el resto del proyecto)

### Cambiado
- Versión bumpeada a v2.2.3

## [2.2.2] - 2026-03-16

### Corregido
- `bluetooth.lua`: `battery_icon()` corregía mal el rango 20–79% — ahora devuelve 🪫 en lugar de 🔋 para ese rango
- `utils.lua`: `format_time()` mostraba solo `MM:SS` para duraciones ≥ 1 hora — ahora devuelve `H:MM:SS`
- `pomodoro.lua`: eliminado campo `state.on_update` y parámetro `on_update` en `M.start()` — código muerto huérfano desde v2.2.1 (el timer ya no llama callbacks externos)
- `install.sh`: `git fetch --dry-run` envuelto en subshell para no abortar el script con `set -euo pipefail` cuando no hay acceso a red

### Cambiado
- Versión bumpeada a v2.2.2

## [2.2.1] - 2026-03-16

### Corregido
- `menu.lua`: menú ya no parpadea ni se cierra al abrirse desde Finder — reemplazado `setMenu(tabla)` por `setMenu(función)`; Hammerspoon construye el contenido on-demand solo cuando el usuario abre el menú, nunca mientras está visible
- `init.lua`: eliminados callbacks de `menu.build()` en `clipboard.start()`, `network.refresh()` y `vpn.refresh()`; ya no son necesarios con el modelo on-demand
- `pomodoro.lua`: eliminada llamada a `on_update()` cada segundo dentro del timer; eliminaba el menú si estaba abierto durante un ciclo Pomodoro activo

### Cambiado
- `menu.lua`: nueva función `M.init()` para registrar el menú on-demand; `M.build()` solo actualiza el ícono del título
- Versión bumpeada a v2.2.1

## [2.2.0] - 2026-03-16

### Mejorado (UX/UI)
- `menu.lua`: reorganización completa del menú en grupos semánticos con separadores — Perfiles / Entorno / Dispositivos / Red / Productividad / Historial / Sistema
- `menu.lua`: "Cerrar" perfil renombrado a "Desactivar" (verbo más preciso según HIG de Apple)
- `menu.lua`: Pomodoro muestra el tiempo restante en el título del ítem padre cuando está activo (`Pomodoro  🍅 23:41`) en lugar de un ítem suelto en el menú principal
- `menu.lua`: Red muestra IP local e ícono de tipo de conexión inline en el título (`Red  📶  192.168.1.5`)
- `menu.lua`: Bluetooth muestra conteo de dispositivos conectados inline (`Bluetooth  (3)`)
- `menu.lua`: Descanso activo muestra indicador ◉ en el título cuando está activo
- `menu.lua`: Modo presentación usa título dinámico unificado; eliminado ítem duplicado de acceso rápido
- `battery.lua`: alertas contextuales en batería baja (`— Batería baja`) y crítica (`— Batería crítica`)
- `clipboard.lua`: buscador reemplazado por `hs.chooser` nativo con filtrado en tiempo real; eliminado `hs.dialog.textPrompt` que no existe en Hammerspoon
- `breaks.lua`: eliminado label "Intervalo:" suelto que se veía igual que ítems accionables
- `history.lua`: caché en memoria para `load_data()`; evita lectura de disco en cada apertura del menú
- `presentation.lua`: diálogo de confirmación antes de ejecutar `killall Finder/Dock`; el usuario puede cancelar

### Cambiado
- Versión bumpeada a v2.2.0

## [2.1.4] - 2026-03-16

### Corregido
- `bluetooth.lua`: dispositivos Logitech (y otros terceros) ya aparecen en el menú — se amplió la consulta `ioreg` para incluir `BatteryLevel` y `DeviceAddress`; antes solo se buscaba `BatteryPercent`, clave que Logitech no expone en macOS
- `bluetooth.lua`: deduplicación mejorada para priorizar la entrada con batería cuando un dispositivo aparece en múltiples consultas
- `bluetooth.lua`: `device_icon` reconoce ahora MX Master, MX Anywhere, Lift, Keys y variantes de auriculares (buds)

### Cambiado
- Versión bumpeada a v2.1.4

## [2.1.3] - 2026-03-16

### Corregido
- `network.lua`: archivo truncado reconstruido — funciones `M.refresh()`, `M.local_info()`, `M.remote_info()` y `fetch_remote_info()` restauradas; el submenú Red ya no crashea al abrirse
- `dnd.lua`: eliminada función `toggle_via_shortcut()` definida pero nunca usada (código muerto)
- `clipboard.lua`: reemplazado `hs.image.imageFromName()` con emojis (no funciona en Hammerspoon) por texto con ícono en el campo `text` del chooser; elimina crash potencial al buscar en el historial
- `browsers.lua`: ítem fallback "Sin navegadores detectados" cambiado de `disabled = true` a `fn = function() end` para mantener legibilidad
- `audio.lua`: ítem fallback "Sin dispositivos de audio" cambiado de `disabled = true` a `fn = function() end`
- `launcher.lua`: ítems de estado vacío ("Sin apps configuradas", "Edita launcher.apps…") cambiados de `disabled = true` a `fn = function() end`
- `vpn.lua`: filtrado de interfaces `utun*` del sistema (iCloud Private Relay, Handoff, AirDrop) que generaban falsos positivos de VPN; se excluyen IPs link-local (`169.254.x.x`) y rango CGNAT de Apple (`100.64–127.x.x`)

### Cambiado
- Versión bumpeada a v2.1.3

## [2.1.2] - 2026-03-16

### Corregido
- Todos los ítems informativos del menú cambiados de `disabled = true` (gris ilegible) a `fn = function() end` (color normal); los que muestran valores copiables (IPs, batería, tiempos) copian el valor al portapapeles al hacer clic
- `clipboard.lua`: agregada búsqueda via `hs.dialog.textPrompt` + `hs.chooser` para filtrar entre las entradas del historial
- `presentation.lua`: indicadores de estado del modo presentación ahora legibles
- `menu.lua`: ítem de batería y tiempo Pomodoro ahora legibles en el menú principal

### Cambiado
- Versión bumpeada a v2.1.2

## [2.1.1] - 2026-03-16

### Corregido
- `pomodoro.lua`: bug donde `M.stop()` mostraba "0 ciclos" en la notificación por leer `state.cycle` después de resetearlo
- `dnd.lua`: reescrito para usar `hs.focus` (API nativa de Hammerspoon) con fallback limpio a `defaults -currentHost`; eliminado bloque AppleScript vacío que generaba errores silenciosos
- `battery.lua`: detección de batería mejorada usando `hs.battery.cycles()` como indicador primario; evita falsos positivos en Mac mini con batería al 0%
- `bluetooth.lua`: parser de `ioreg` reescrito con regex correcta para valores string y numéricos; eliminados duplicados por nombre; íconos dinámicos según tipo de dispositivo
- `network.lua`: `hs.network.primaryInterfaces` ahora se verifica antes de llamar (no existe en todas las versiones de Hammerspoon)
- `breaks.lua`: al cambiar el intervalo notifica al usuario que el nuevo valor aplica desde ahora
- `audio.lua`: eliminada notificación ruidosa al cambiar audio (solo se notifica en caso de error, siguiendo HIG de Apple)

### Cambiado
- `README.md`: reescrito en estilo funcional/negocio Dilware, sin capturas de pantalla
- `.gitignore`: actualizado para excluir `macspaces_history.json` y archivos macOS adicionales
- `pomodoro.lua`: ícono de pausa larga cambiado de 🛋 a 🌿 (más reconocible, alineado con HIG)
- Versión bumpeada a v2.1.1

## [2.1.0] - 2026-03-16

### Agregado
- `macspaces/clipboard.lua` — historial del portapapeles (hasta 20 entradas por defecto, configurable); soporta texto, imágenes y URLs; restaura al portapapeles con un clic para pegado manual
- `macspaces/bluetooth.lua` — lista dispositivos Bluetooth conectados con nivel de batería via `ioreg`
- `macspaces/network.lua` — información de red: tipo de conexión (WiFi/Ethernet), IP local, SSID, IP externa asíncrona via ip-api.com con país, región, ciudad, ISP y operador
- `macspaces/vpn.lua` — detección de VPN activa (interfaces `utun*`/`ppp*`), IP del túnel e información geográfica via ip-api.com
- `macspaces/presentation.lua` — modo presentación: activa No Molestar, oculta el Dock y limpia el escritorio; restaura el estado original al desactivar
- `macspaces/launcher.lua` — lanzador rápido de apps configurable desde `config.lua` (vacío por defecto)
- `config.lua`: nuevas secciones `clipboard`, `presentation` y `launcher`
- `init.lua`: arranca `clipboard.start()`, `network.refresh()` y `vpn.refresh()` al iniciar
- Indicador visual de VPN en el título del submenú (🔒 cuando está activa)
- Acceso rápido a "Desactivar presentación" en la parte superior del menú cuando está activa

### Cambiado
- `menu.lua` integra los 6 nuevos submenús en orden lógico
- Versión bumpeada a v2.1.0

## [2.0.0] - 2025-03-16

### Agregado
- Arquitectura modular: código reorganizado en `macspaces/` con un módulo por responsabilidad
- `macspaces/config.lua` — configuración central editable por el usuario
- `macspaces/utils.lua` — log, notificaciones y helpers compartidos
- `macspaces/profiles.lua` — gestión de espacios y ciclo de vida de perfiles
- `macspaces/browsers.lua` — navegador predeterminado con allowlist (filtra apps no navegadoras)
- `macspaces/audio.lua` — selección de dispositivo de salida de audio desde el menú
- `macspaces/battery.lua` — estado de batería condicional (invisible en Mac mini/iMac)
- `macspaces/history.lua` — historial de sesiones por perfil con duración acumulada del día
- `macspaces/pomodoro.lua` — temporizador Pomodoro con ciclos configurables y DND automático
- `macspaces/breaks.lua` — recordatorios de descanso activo con intervalo configurable (30–90 min)
- `macspaces/dnd.lua` — control de No Molestar integrado con Pomodoro
- `macspaces/hotkeys.lua` — atajos de teclado globales ⌘⌥1 / ⌘⌥2 para activar perfiles
- `macspaces/menu.lua` — menú principal centralizado con todos los submenús
- Navegador vinculado al perfil: Personal → Safari, Work → Edge (cambio automático al activar)
- Ícono del menú cambiado de ◇ a ⌘ (más idiomático para herramienta de control de macOS)
- `install.sh` copia la carpeta `macspaces/` completa y hace respaldo de ambos

### Cambiado
- `init.lua` reducido a punto de entrada limpio (carga módulos, registra hotkeys, construye menú)
- Perfiles Work actualizados: Google Chrome reemplazado por Microsoft Edge
- Historial de sesiones registrado automáticamente al cerrar un perfil

## [1.3.0] - 2025-03-16

### Corregido
- Orden no determinístico del menú — reemplazado por `profile_order` (array)
- Estado inconsistente de `space_id` tras fallo de `removeSpace`
- Badge de versión en README desactualizado
- Feedback prematuro al cambiar navegador antes de confirmación del sistema
- `install.sh`: supresión silenciosa de errores de git
- Bundle ID incorrecto de Arc (`com.arc.app`) eliminado
- `require("hs.urlevent")` faltante — importado explícitamente
- Notificación ruidosa al iniciar/recargar eliminada
- `open -a TextEdit` reemplazado por `open` genérico

### Cambiado
- `deactivate_profile` espera `delay.medium * 2` para cierre limpio de apps
- `install.sh` agrega respaldo automático y verifica conectividad antes de pull

## [1.2.0] - 2025-06-16

### Agregado
- Submenú "Navegador predeterminado" con detección automática de navegadores instalados
- Indicador visual del navegador activo (◉)
- Mapeo de bundle IDs a nombres legibles

## [1.1.0] - 2025-06-16

### Corregido
- `clearLog()` podía crashear con handle nulo
- `activate_profile` borraba el log completo al activar
- `app:kill9()` reemplazado por `app:kill()`
- `os.exit()` en opción "Salir" causaba cierre abrupto

### Agregado
- Protección contra doble activación
- Estado visual de perfiles en el menú
- Lanzamiento secuencial de apps con delay

## [1.0.0] - 2025-06-09

### Agregado
- Primera versión estable
- Perfiles Personal y Work
- Menú en barra superior, notificaciones y log
- Script de instalación automática
- Licencia GPLv3

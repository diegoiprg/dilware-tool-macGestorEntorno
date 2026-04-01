# Especificación Funcional — macSpaces v2.6.0

## Propósito

Centralizar el control del entorno de trabajo en macOS desde un único ícono en la barra de menú: espacios virtuales, navegador, audio, red, productividad y más.

---

## Módulos funcionales

### 1. Perfiles de trabajo (`profiles.lua`)

Aísla contextos en espacios virtuales dedicados con apps asociadas.

- Activar: crea espacio, navega, lanza apps, mueve ventanas, cambia navegador.
- Desactivar: cierra apps, reubica ventanas huérfanas, elimina espacio, registra sesión.
- Atajos: ⌘⌥1 (Personal), ⌘⌥2 (Work).

| Perfil | Apps | Navegador |
|---|---|---|
| Personal | Safari | Safari |
| Work | Outlook PWA, Teams PWA, OneDrive, Edge | Microsoft Edge |

### 2. Navegador predeterminado (`browsers.lua`)

Cambia el navegador predeterminado del sistema sin abrir Preferencias.

- Allowlist configurable (Safari, Chrome, Edge, Firefox, Brave, Opera, Vivaldi, Arc).
- Checkmark en el navegador activo.
- Cambio inmediato y global (afecta todo el sistema).

### 3. Audio (`audio.lua`)

Cambia el dispositivo de salida de audio predeterminado.

- Lista dispositivos disponibles con checkmark en el activo.
- Caché de 10 segundos.

### 4. Apple Music (`music.lua`)

Controla Apple Music via AppleScript.

- Muestra canción, artista y álbum actuales.
- Controles: play/pause, siguiente, anterior.
- Si Music.app no está abierta, ofrece abrirla.

### 5. Batería (`battery.lua`)

Estado de batería (solo MacBook, invisible en escritorio).

- Porcentaje, estado de carga, alertas (baja < 40%, crítica < 20%).
- Clic copia porcentaje al portapapeles.

### 6. Bluetooth (`bluetooth.lua`)

Dispositivos BT conectados con nivel de batería.

- Detección via `ioreg`. Soporta Apple y terceros (Logitech, etc.).
- Íconos por tipo: 🎧 auriculares, 🖱 mouse, ⌨️ teclado, etc.
- Caché de 60 segundos.

### 7. Red (`network.lua`)

Información de conexión local y remota.

- Local: tipo (WiFi/Ethernet/VPN), SSID, IP local.
- Remota (ipapi.co): IP externa, país, región, ciudad, ISP.
- TTL de 60 segundos. Actualización manual disponible.

### 8. VPN (`vpn.lua`)

Detección de VPN activa con geolocalización del túnel.

- Detecta interfaces `utun*`/`ppp*` (excluye iCloud Private Relay, Handoff).
- Muestra IP del túnel e info geográfica via ipapi.co.
- Solo visible cuando hay VPN activa. TTL de 120 segundos.

### 9. Portapapeles (`clipboard.lua`)

Historial de las últimas 20 entradas copiadas (configurable).

- Captura texto, imágenes y URLs automáticamente.
- Restaurar con clic. Búsqueda via `hs.chooser`.
- Deduplicación de entradas consecutivas.
- Solo en memoria (se pierde al recargar).

### 10. Lanzador rápido (`launcher.lua`)

Acceso directo a apps favoritas. Vacío por defecto, configurable en `config.lua`. No aparece si no hay apps configuradas.

### 11. Pomodoro (`pomodoro.lua`)

Temporizador con ciclos configurables y DND automático.

- Trabajo: 25 min → Pausa corta: 5 min → ... → Pausa larga: 15 min (cada 4 ciclos).
- Notificación al cambiar fase. Opción de saltar fase.
- Tiempo restante visible en el título del ítem del menú.

### 12. Descanso activo (`breaks.lua`)

Recordatorios periódicos para postura y vista.

- Desactivado por defecto. Intervalo: 30/45/50/60/90 min.
- Mensajes rotativos con sugerencias de estiramiento e hidratación.

### 13. Modo presentación (`presentation.lua`)

Prepara el Mac para presentar con un clic.

- Activa DND, oculta Dock, oculta íconos del escritorio.
- Confirmación antes de activar (reinicia Dock/Finder).
- Restaura estado original al desactivar.

### 14. Historial de sesiones (`history.lua`)

Tiempo acumulado por perfil durante el día.

- Registro automático al desactivar perfil (ignora < 10 seg).
- Persistido en JSON. Limpieza automática > 30 días.

### 15. Sistema

- **Registro**: abre `debug.log` en Console.app.
- **Recargar**: ejecuta `hs.reload()`.

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
| `breaks` | Intervalo, estado inicial |
| `clipboard` | Máximo de entradas |
| `presentation` | DND, Dock, escritorio |
| `launcher` | Apps con nombre e ícono |
| `menu_icon` | Carácter del ícono en menubar |

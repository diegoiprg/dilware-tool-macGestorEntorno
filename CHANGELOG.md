# Changelog

Registro de cambios del proyecto `dilware-tool-macSpaces`.

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

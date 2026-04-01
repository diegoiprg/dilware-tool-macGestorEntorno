# Guía de Uso — macSpaces v2.6.0

## Requisitos

- macOS con Mission Control habilitado
- [Hammerspoon](https://www.hammerspoon.org) instalado y ejecutado al menos una vez
- Permisos de Accesibilidad y Automatización para Hammerspoon (Preferencias del Sistema → Privacidad y Seguridad)

## Instalación

```bash
curl -sL https://raw.githubusercontent.com/diegoiprg/dilware-tool-macGestorEntorno/main/install.sh | bash
```

El script:
1. Clona el repositorio en `~/dilware-tool-macSpaces` (o actualiza si ya existe)
2. Respalda `init.lua` y `macspaces/` existentes
3. Copia los archivos a `~/.hammerspoon/`

Después: abre Hammerspoon y presiona ⌘R para recargar. El ícono ⌘ aparecerá en la barra de menú.

## Uso básico

### Perfiles

Haz clic en el ícono ⌘ de la barra de menú. Los perfiles aparecen en la parte superior:

- **Personal** (⌘⌥1): abre Safari en un espacio dedicado
- **Work** (⌘⌥2): abre Outlook, Teams, OneDrive y Edge en un espacio dedicado

Al activar un perfil:
- Se crea un nuevo espacio virtual
- Se lanzan las apps configuradas y se mueven al espacio
- El navegador predeterminado cambia al vinculado con el perfil

Al hacer clic de nuevo en un perfil activo (o presionar el atajo):
- Se cierran las apps del perfil
- Se elimina el espacio virtual
- Se registra el tiempo de la sesión

### Navegador

Submenú **Navegador**: muestra los navegadores instalados. Haz clic en uno para hacerlo predeterminado del sistema. El activo tiene un checkmark.

### Audio

Submenú **Audio**: lista los dispositivos de salida. Haz clic para cambiar.

### Apple Music

Submenú **Music**: muestra la canción actual y ofrece controles de reproducción. Si Music.app no está abierta, puedes abrirla desde aquí.

### Batería

Solo visible en MacBook. Muestra porcentaje y estado. Haz clic para copiar el porcentaje.

### Bluetooth

Submenú **Bluetooth**: lista dispositivos conectados con nivel de batería. El número entre paréntesis indica cuántos hay conectados.

### Red

Submenú **Red**: muestra tipo de conexión, IP local, IP externa con geolocalización. Botón "Actualizar" para refrescar.

### VPN

Solo aparece cuando hay una VPN activa. Muestra interfaz, IP del túnel e información geográfica de la IP pública via VPN.

### Portapapeles

Submenú **Portapapeles**: historial de las últimas 20 entradas copiadas.

- Haz clic en una entrada para restaurarla al portapapeles
- **Buscar…**: abre un buscador con filtrado en tiempo real
- **Limpiar historial**: vacía todas las entradas

⚠️ El historial se pierde al recargar Hammerspoon.

### Pomodoro

Submenú **Pomodoro**: temporizador de productividad.

- **Iniciar**: comienza ciclo de 25 min trabajo → 5 min pausa
- Cada 4 ciclos: pausa larga de 15 min
- No Molestar se activa automáticamente durante el trabajo
- **Saltar fase**: avanza a la siguiente fase
- **Detener**: para el temporizador

El tiempo restante aparece en el título del ítem cuando está activo.

### Descanso activo

Submenú **Descanso**: recordatorios periódicos para postura y vista.

- Desactivado por defecto
- Elige intervalo (30–90 min) y activa
- Recibirás notificaciones con sugerencias de estiramiento

### Modo presentación

Submenú **Presentación**: prepara el Mac para presentar.

- Activa No Molestar, oculta Dock y limpia escritorio
- Pide confirmación antes de activar (reinicia Dock y Finder)
- Al desactivar, restaura el estado original

### Lanzador rápido

Solo aparece si has configurado apps en `config.lua`. Permite abrir apps favoritas con un clic.

### Historial

Submenú **Historial**: muestra el tiempo acumulado por perfil durante el día. Haz clic en un tiempo para copiarlo.

### Sistema

- **Registro**: abre el archivo de log en Console.app
- **Recargar**: recarga Hammerspoon (aplica cambios en config)

---

## Personalización

Edita `~/.hammerspoon/macspaces/config.lua`:

### Agregar un perfil

```lua
M.profile_order = { "personal", "work", "study" }

M.profiles.study = {
    name    = "Study",
    apps    = { "Notion", "Safari" },
    browser = "com.apple.Safari",
}

-- Opcional: atajo de teclado
M.hotkeys.study = { mods = { "cmd", "alt" }, key = "3" }
```

### Configurar el lanzador

```lua
M.launcher = {
    apps = {
        { name = "Visual Studio Code", icon = "💻" },
        { name = "Spotify",            icon = "🎵" },
        { name = "Terminal",           icon = "⌨️"  },
    },
}
```

### Ajustar Pomodoro

```lua
M.pomodoro = {
    work_minutes  = 50,
    short_break   = 10,
    long_break    = 20,
    cycles_before_long_break = 3,
    enable_dnd    = true,
}
```

### Cambiar ícono del menú

```lua
M.menu_icon = "◇"  -- o cualquier carácter/emoji
```

Después de editar, presiona ⌘R en Hammerspoon para aplicar.

---

## Solución de problemas

| Problema | Solución |
|---|---|
| El ícono ⌘ no aparece | Verifica que Hammerspoon esté abierto. Presiona ⌘R para recargar. |
| Las apps no se mueven al espacio | Aumenta `delay.app_launch` en config.lua (ej: 2.0 o 3.0). |
| "Configuración inválida" al iniciar | Revisa config.lua: `VERSION`, `delay.short`, `profile_order` y `profiles` son obligatorios. |
| Bluetooth no muestra dispositivos | Verifica que estén conectados. La detección usa `ioreg` y puede tardar hasta 60 seg en actualizar. |
| IP externa dice "Obteniendo…" | Verifica conexión a internet. ipapi.co puede estar temporalmente inaccesible. |
| Modo presentación no restaura el Dock | Ejecuta manualmente: `defaults write com.apple.dock autohide -bool false && killall Dock` |
| Permisos de Accesibilidad | Preferencias del Sistema → Privacidad y Seguridad → Accesibilidad → Habilitar Hammerspoon |

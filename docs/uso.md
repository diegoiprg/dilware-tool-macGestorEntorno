# Guía de Uso — macSpaces v2.11.9

## Tabla de contenido

- [Requisitos](#requisitos)
- [Instalación](#instalación)
  - [Automática (recomendada)](#automática-recomendada)
  - [Manual](#manual)
- [Dos menús en la menubar](#dos-menús-en-la-menubar)
- [Uso básico](#uso-básico)
  - [Perfiles](#perfiles)
  - [Pomodoro](#pomodoro)
  - [Descanso activo](#descanso-activo)
  - [Modo presentación](#modo-presentación)
  - [Portapapeles](#portapapeles)
  - [Red y VPN](#red-y-vpn)
  - [Monitor de Claude](#monitor-de-claude)
- [Personalización](#personalización)
- [Solución de problemas](#solución-de-problemas)

---

## Requisitos

- macOS con Mission Control habilitado

El instalador automático se encarga de instalar Xcode CLI Tools, Homebrew y Hammerspoon si no están presentes.

---

## Instalación

### Automática (recomendada)

Un solo comando que instala todo: Xcode CLI Tools, Homebrew, Hammerspoon, archivos de configuración, helper Swift compilado, y lanza Hammerspoon listo para usar.

El instalador detecta automáticamente cómo se ejecutó:

**Desde un clon local** — crea symlinks (los cambios en el repo se reflejan al instante):

```bash
git clone https://github.com/diegoiprg/dilware-tool-macGestorEntorno.git
cd dilware-tool-macGestorEntorno
bash install.sh
```

**Remoto** — descarga los archivos directamente:

> Ejecutar scripts remotos con `curl | bash` implica confiar en el contenido del repositorio. [Revisa el código](https://github.com/diegoiprg/dilware-tool-macGestorEntorno/blob/main/install.sh) antes de ejecutar.

```bash
curl -sL https://raw.githubusercontent.com/diegoiprg/dilware-tool-macGestorEntorno/main/install.sh | bash
```

Usa `--dry-run` para previsualizar sin aplicar cambios.

El instalador preserva tu `config.lua` si ya tenías una configuración personalizada.

Después de la instalación, macOS te pedirá permisos para Hammerspoon:
- Ajustes del Sistema → Privacidad y Seguridad → Accesibilidad → Hammerspoon ✓
- Ajustes del Sistema → Privacidad y Seguridad → Automatización → Hammerspoon ✓

### Manual

```bash
# 1. Instalar Hammerspoon (si no lo tienes)
brew install --cask hammerspoon

# 2. Clonar el repositorio
git clone https://github.com/diegoiprg/dilware-tool-macGestorEntorno.git ~/dilware-tool-macGestorEntorno

# 3. Copiar archivos a Hammerspoon
cp ~/dilware-tool-macGestorEntorno/init.lua ~/.hammerspoon/init.lua
cp -r ~/dilware-tool-macGestorEntorno/macspaces ~/.hammerspoon/macspaces

# 4. Abrir Hammerspoon y presionar ⌘R para recargar
```

---

## Dos menús en la menubar

macSpaces presenta dos íconos independientes en la barra de menú:

### ⌘ Menú principal — gestión del entorno

- Perfiles de trabajo (activar/desactivar con clic o `⌘⌥1` / `⌘⌥2`)
- Entorno: navegador predeterminado, audio, Apple Music
- Dispositivos: batería (solo MacBook), Bluetooth con nivel de batería
- Red: conexión local, IP externa, VPN (cuando está activa)
- Portapapeles: historial de las últimas 20 entradas con búsqueda
- Lanzador rápido (visible solo si hay apps configuradas)
- Claude: uso de rate limits de Claude Code
- Historial de sesiones del día
- Registro (debug.log) y recarga

### ◎ Menú de enfoque — gestión de la concentración

- Pomodoro: temporizador con ciclos configurables y DND automático
- Descanso activo: recordatorios periódicos de postura y vista (50 min por defecto)
- Presentación: DND + Dock oculto + escritorio limpio con un clic

El ícono de enfoque es estático (`◎` por defecto, configurable en `config.lua`).

### Overlay flotante

Un banner unificado en la esquina inferior derecha muestra filas coloreadas por estado activo:

| Color | Estado | Contenido |
|---|---|---|
| Rojo | Pomodoro trabajando | Countdown, fase y ciclo |
| Verde | Pausa Pomodoro | Countdown de pausa corta o larga |
| Azul | Descanso pendiente | Countdown hasta el próximo descanso |
| Verde | Descanso en curso | Countdown del banner de descanso activo |
| Púrpura | Presentación activa | Indicador de modo activo |
| Verde/Amarillo/Rojo | Claude activo | Uso 5h y/o 7d con % y tiempo de reset |

Arrastrable: haz clic y arrastra para reposicionar. La posición se mantiene durante la sesión y se resetea al recargar Hammerspoon. Visible en todos los espacios de Mission Control. Se oculta automáticamente cuando no hay estado activo.

En MacBook, las filas de Claude usan formato compacto (sin barra de progreso `▰▱`) para evitar solapamiento con el Dock.

---

## Uso básico

### Perfiles

Los perfiles aparecen en la parte superior del menú principal:

- **Personal** (`⌘⌥1`): abre Safari en un espacio dedicado
- **Work** (`⌘⌥2`): abre Outlook PWA, Teams PWA, OneDrive y Edge en un espacio dedicado

Al activar:
1. Se crea un nuevo espacio en Mission Control
2. Se navega automáticamente al espacio
3. Se lanzan las apps del perfil
4. Se cambia el navegador predeterminado al vinculado con el perfil

Al desactivar:
1. Se pide confirmación si el perfil lo requiere (solo Work por defecto)
2. Se cierran las apps del perfil
3. Se elimina el espacio
4. Se restaura el navegador que estaba activo antes de activar el perfil
5. Se registra la sesión en el historial del día

El menú muestra el tiempo activo inline: `● Work — 1:23:45`.

### Pomodoro

Desde el menú de enfoque `◎`:

- **Iniciar**: 25 min trabajo → 5 min pausa corta → (repite 4 ciclos) → 15 min pausa larga
- Durante el trabajo: DND se activa automáticamente
- Durante las pausas: DND se desactiva
- El countdown aparece en el overlay flotante con la fase y el número de ciclo
- Cada transición de fase muestra un canvas grande con datos educativos sobre productividad
- Puedes **Saltar fase** o **Detener** desde el submenú

El tiempo se calcula con reloj de pared (`os.time()`), por lo que el countdown es preciso incluso si el equipo se suspendió durante una sesión.

### Descanso activo

Activado por defecto cada 50 minutos. Al disparar:

1. Aparece un banner grande en pantalla con instrucciones de ejercicio en 3 pasos
2. El overlay cambia de azul (countdown) a verde (banner activo)
3. Después de 120 segundos, el banner se cierra y comienza el siguiente ciclo

Categorías de mensajes (rotan en orden):
- Vista: Regla 20-20-20 (AAO)
- Cuello y hombros: estiramiento cervical (OSHA)
- Muñecas y manos: prevención del túnel carpiano (Mayo Clinic)
- Movilidad: caminar 2 minutos (AHA)
- Espalda lumbar: flexión lumbar (OSHA)
- Respiración: técnica 4-7-8 (Harvard Med)
- Hidratación: consumo de agua (EFSA)

Puedes cambiar el intervalo (30/45/50/60/90 min) o desactivar los descansos desde el menú de enfoque sin editar `config.lua`.

### Modo presentación

Desde el menú de enfoque: activa DND, habilita autohide del Dock y oculta los íconos del escritorio con un clic. Pide confirmación antes de ejecutar cambios en el Dock y Finder.

Al desactivar: restaura todos los estados originales (Dock, DND, escritorio).

### Portapapeles

El historial captura automáticamente cada cosa que copies (texto, imágenes, URLs). Aparece en el menú principal bajo "Portapapeles".

- Clic en cualquier entrada para restaurarla al portapapeles
- **Buscar...** abre un buscador con filtrado en tiempo real
- El historial no se persiste: se pierde al recargar Hammerspoon
- El contenido copiado desde gestores de contraseñas (1Password, Bitwarden, etc.) no se captura

### Red y VPN

El submenú **Red** muestra:
- Tipo de conexión (WiFi, Ethernet)
- SSID de la red WiFi
- IP local
- IP externa con país, región, ciudad e ISP (via ipapi.co)

El submenú **VPN** solo aparece cuando hay una VPN activa. Muestra la interfaz del túnel, su IP y geolocalización.

### Monitor de Claude

El submenú **Claude** muestra el uso de rate limits de Claude Code:

- **Ventana 5h**: porcentaje de uso en la última ventana de 5 horas y tiempo hasta el reset
- **Ventana 7d**: porcentaje de uso en la ventana de 7 días y tiempo hasta el reset
- Barra de progreso con `▰▱` y color semáforo (verde < 60%, amarillo 60–84%, rojo ≥ 85%)
- El overlay flotante muestra estas filas cuando hay una sesión activa

Esta información se lee desde `~/.claude/usage_cache.json`, generado por `statusline.sh` del proyecto [dil-configuration](https://github.com/diegoiprg/dil-configuration). Sin ese archivo, la sección de Claude no aparece.

---

## Personalización

Edita `~/.hammerspoon/macspaces/config.lua` y presiona `⌘R` para aplicar cambios. Consulta [docs/configuracion.md](configuracion.md) para la referencia completa de parámetros.

### Agregar un perfil

```lua
M.profile_order = { "personal", "work", "study" }

M.profiles.study = {
    name               = "Study",
    apps               = { "Notion", "Safari" },
    browser            = "com.apple.Safari",
    confirm_deactivate = false,
}

M.hotkeys.study = { mods = { "cmd", "alt" }, key = "3" }
```

### Ajustar Pomodoro

```lua
M.pomodoro = {
    work_minutes             = 50,
    short_break              = 10,
    long_break               = 20,
    cycles_before_long_break = 3,
    enable_dnd               = true,
}
```

### Ajustar descanso activo

```lua
M.breaks = {
    interval_minutes      = 45,
    enabled               = true,
    break_display_seconds = 90,
}
```

### Configurar lanzador

```lua
M.launcher = {
    apps = {
        { name = "Visual Studio Code", icon = "💻" },
        { name = "Spotify",            icon = "🎵" },
        "Notion",
    },
}
```

---

## Solución de problemas

| Problema | Solución |
|---|---|
| Los íconos no aparecen en la barra | Verifica que Hammerspoon esté abierto. Presiona `⌘R` para recargar. |
| "Configuración inválida" al iniciar | Revisa `config.lua`: `VERSION`, `delay.short`, `profile_order` y `profiles` son obligatorios y deben tener el tipo correcto. |
| Las apps no se mueven al espacio correcto | Aumenta `delay.app_launch` en `config.lua` a `2.0` o `2.5`. |
| Bluetooth no muestra dispositivos | Verifica que los dispositivos estén conectados. El caché se actualiza cada 120 segundos. |
| IP externa muestra "Obteniendo..." | Verifica conexión a internet. ipapi.co puede estar temporalmente inaccesible. |
| El overlay no aparece | El overlay se muestra solo cuando hay algún estado activo (Pomodoro, descanso, presentación o Claude). |
| Claude no aparece en el overlay | Verifica que `~/.claude/usage_cache.json` exista y tenga menos de 6 horas de antigüedad. |
| No se puede cambiar el navegador | Verifica que el helper Swift esté compilado: debe existir `~/.hammerspoon/set_browser`. Si no, instala Xcode CLI tools con `xcode-select --install` y recarga. |
| Hammerspoon pide permisos | Preferencias del Sistema → Privacidad y Seguridad → Accesibilidad → habilitar Hammerspoon. Repite para Automatización si es necesario. |

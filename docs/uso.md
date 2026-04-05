# Guía de Uso — macSpaces v2.10.0

## Requisitos

- macOS con Mission Control habilitado
- [Hammerspoon](https://www.hammerspoon.org) instalado
- Permisos de Accesibilidad y Automatización para Hammerspoon

## Instalación

### Método manual (recomendado)

```bash
git clone https://github.com/diegoiprg/dilware-tool-macGestorEntorno.git ~/dilware-tool-macGestorEntorno
cp ~/dilware-tool-macGestorEntorno/init.lua ~/.hammerspoon/init.lua
cp -r ~/dilware-tool-macGestorEntorno/macspaces ~/.hammerspoon/macspaces
```

Abre Hammerspoon y presiona ⌘R para recargar.

### Script de instalación

> ⚠️ Revisa el código antes de ejecutar scripts remotos.

```bash
curl -sL https://raw.githubusercontent.com/diegoiprg/dilware-tool-macGestorEntorno/main/install.sh | bash
```

---

## Dos menús en la menubar

macSpaces presenta dos íconos independientes:

### ⌘ Menú principal — gestión del entorno
- Perfiles de trabajo (activar/desactivar con clic o ⌘⌥1 / ⌘⌥2)
- Entorno: navegador, audio, música
- Dispositivos: batería, Bluetooth
- Red: conexión local, IP externa, VPN
- Portapapeles: historial, búsqueda
- Lanzador rápido (si hay apps configuradas)
- Historial de sesiones
- Registro y recarga

### ◎ Menú de enfoque — gestión de la concentración
- Pomodoro: temporizador con ciclos y DND automático
- Descanso activo: recordatorios periódicos de postura y vista
- Presentación: DND + Dock oculto + escritorio limpio

El ícono de enfoque cambia según el estado: `🍅 23m` (Pomodoro), `🎬` (presentación), `◎` (por defecto).

### Overlay flotante

Un banner unificado en la esquina inferior derecha muestra filas coloreadas por estado:
- 🍅 **Rojo**: Pomodoro con countdown, fase y ciclo
- ☕ **Verde**: Pausa corta o larga
- ◎ **Azul**: Countdown regresivo hasta el próximo descanso
- 🎬 **Púrpura**: Modo presentación activo

Arrastrable: haz clic y arrastra para reposicionar. La posición se mantiene durante la sesión. Visible en todos los espacios de Mission Control. Se oculta automáticamente cuando no hay estado activo.

---

## Uso básico

### Perfiles

Los perfiles aparecen en la parte superior del menú principal:

- **Personal** (⌘⌥1): abre Safari en un espacio dedicado
- **Work** (⌘⌥2): abre Outlook, Teams, OneDrive y Edge en un espacio dedicado

Al activar: se crea espacio, se lanzan apps, se cambia navegador.
Al desactivar: se cierran apps, se elimina espacio, se restaura navegador previo, se registra sesión.

### Pomodoro

Desde el menú de enfoque 🧘:
- **Iniciar**: 25 min trabajo → 5 min pausa → ... → 15 min pausa larga (cada 4 ciclos)
- DND se activa automáticamente durante el trabajo
- El countdown aparece en el ícono y en el overlay flotante
- Cada notificación incluye un dato educativo sobre productividad

### Descanso activo

Activado por defecto. Cada 50 minutos recibes una notificación con:
- Una sugerencia de estiramiento o hidratación
- Un dato de salud basado en estándares (AAO, OSHA, Mayo Clinic)

El overlay muestra un countdown regresivo con el tiempo restante hasta el próximo descanso. Puedes cambiar el intervalo (30-90 min) o desactivarlo desde el menú de enfoque.

### Modo presentación

Desde el menú de enfoque: activa DND, oculta Dock y limpia escritorio con un clic. Pide confirmación. Al desactivar, restaura todo.

### Portapapeles

Historial de las últimas 20 entradas. Clic para restaurar. **Buscar…** abre un buscador con filtrado. Se pierde al recargar.

### Red y VPN

Submenú Red muestra conexión local e IP externa con geolocalización. VPN aparece solo cuando está activa, con IP del túnel e info geográfica.

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
    confirm_deactivate = true,
}

M.hotkeys.study = { mods = { "cmd", "alt" }, key = "3" }
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

### Ajustar descanso activo

```lua
M.breaks = {
    interval_minutes = 45,
    enabled          = true,
}
```

### Configurar lanzador

```lua
M.launcher = {
    apps = {
        { name = "Visual Studio Code", icon = "💻" },
        { name = "Spotify",            icon = "🎵" },
    },
}
```

Después de editar, presiona ⌘R para aplicar.

---

## Solución de problemas

| Problema | Solución |
|---|---|
| Los íconos no aparecen | Verifica que Hammerspoon esté abierto. ⌘R para recargar. |
| Apps no se mueven al espacio | Aumenta `delay.app_launch` en config.lua (ej: 2.0). |
| "Configuración inválida" | Revisa config.lua: `VERSION`, `delay.short`, `profile_order` y `profiles` son obligatorios. |
| Bluetooth no muestra dispositivos | Verifica conexión. Caché se actualiza cada 120s. |
| IP externa dice "Obteniendo…" | Verifica internet. ipapi.co puede estar inaccesible. |
| Overlay no aparece | Se muestra solo cuando Pomodoro, presentación o descanso activo están activos. |
| Permisos de Accesibilidad | Preferencias del Sistema → Privacidad y Seguridad → Accesibilidad → Habilitar Hammerspoon. |

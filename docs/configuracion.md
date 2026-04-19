# Guía de Configuración — macSpaces v2.11.8

Referencia completa de todos los parámetros de `~/.hammerspoon/macspaces/config.lua`.

## Tabla de contenido

- [Cómo editar](#cómo-editar)
- [VERSION](#version)
- [profile_order](#profile_order)
- [profiles](#profiles)
- [hotkeys](#hotkeys)
- [browser_names](#browser_names)
- [delay](#delay)
- [pomodoro](#pomodoro)
- [breaks](#breaks)
- [clipboard](#clipboard)
- [presentation](#presentation)
- [launcher](#launcher)
- [menu_icon y focus_icon](#menu_icon-y-focus_icon)
- [Ejemplos de personalización](#ejemplos-de-personalización)

---

## Cómo editar

1. Abre `~/.hammerspoon/macspaces/config.lua` con cualquier editor de texto.
2. Guarda los cambios.
3. Abre Hammerspoon y presiona `⌘R` para recargar.

Los cambios entran en vigor de inmediato tras la recarga. El estado de perfiles activos, Pomodoro y portapapeles se pierde al recargar.

---

## VERSION

```lua
M.VERSION = require("macspaces.version")
```

Versión semántica del proyecto, definida en `macspaces/version.lua`. Visible en el menú "Acerca de macSpaces". No requiere modificación manual — se actualiza automáticamente via symlink.

---

## profile_order

```lua
M.profile_order = { "personal", "work" }
```

Array que define el orden de aparición de los perfiles en el menú principal. Las claves deben coincidir con las definidas en `M.profiles`. El orden en este array es el orden visual en el menú.

---

## profiles

```lua
M.profiles = {
    personal = {
        name     = "Personal",
        apps     = { "Safari" },
        browser  = "com.apple.Safari",
        confirm_deactivate = false,
    },
    work = {
        name    = "Work",
        browser = "com.microsoft.edgemac",
        confirm_deactivate = true,
        apps = {
            "Microsoft Outlook webapp",
            "Microsoft Teams webapp",
            "Microsoft OneDrive",
            "Microsoft Edge",
        },
    },
}
```

### Parámetros por perfil

| Parámetro | Tipo | Descripción |
|---|---|---|
| `name` | string | Nombre visible en el menú |
| `apps` | tabla de strings | Apps a lanzar al activar. Deben coincidir con el nombre exacto en macOS. |
| `browser` | string | Bundle ID del navegador vinculado. Se establece como predeterminado al activar. Opcional. |
| `confirm_deactivate` | boolean | Si `true`, pide confirmación antes de cerrar el perfil. Recomendado para perfiles de trabajo. |

### Bundle IDs de navegadores disponibles

| Navegador | Bundle ID |
|---|---|
| Safari | `com.apple.Safari` |
| Google Chrome | `com.google.Chrome` |
| Microsoft Edge | `com.microsoft.edgemac` |
| Firefox | `org.mozilla.firefox` |
| Brave | `com.brave.Browser` |
| Opera | `com.operasoftware.Opera` |
| Vivaldi | `com.vivaldi.Vivaldi` |
| Arc | `company.thebrowser.Browser` |

---

## hotkeys

```lua
M.hotkeys = {
    personal = { mods = { "cmd", "alt" }, key = "1" },
    work     = { mods = { "cmd", "alt" }, key = "2" },
}
```

Atajos de teclado globales para activar/desactivar perfiles. Las claves deben coincidir con las de `M.profiles`.

| Parámetro | Descripción |
|---|---|
| `mods` | Modificadores: `"cmd"`, `"alt"`, `"shift"`, `"ctrl"` |
| `key` | Tecla: carácter o nombre (`"1"`, `"a"`, `"f1"`) |

Para desactivar un hotkey de un perfil específico, borra su entrada de esta tabla.

---

## browser_names

```lua
M.browser_names = {
    ["com.apple.Safari"]           = "Safari",
    ["com.google.Chrome"]          = "Google Chrome",
    ["com.microsoft.edgemac"]      = "Microsoft Edge",
    ["org.mozilla.firefox"]        = "Firefox",
    ["com.brave.Browser"]          = "Brave",
    ["com.operasoftware.Opera"]    = "Opera",
    ["com.vivaldi.Vivaldi"]        = "Vivaldi",
    ["company.thebrowser.Browser"] = "Arc",
}
```

Allowlist de navegadores reconocidos. Solo los navegadores listados aquí aparecen en el submenú de navegador. Para agregar un navegador no listado, agrega su bundle ID y nombre.

---

## delay

```lua
M.delay = {
    short      = 0.5,
    medium     = 1.0,
    app_launch = 1.5,
}
```

Tiempos de espera en segundos usados al activar/desactivar perfiles.

| Parámetro | Uso | Valor por defecto |
|---|---|---|
| `short` | Espera tras crear el espacio antes de navegar | 0.5s |
| `medium` | Espera tras navegar al espacio antes de lanzar apps | 1.0s |
| `app_launch` | Delay entre lanzamiento de cada app | 1.5s |

Si las apps no se mueven al espacio correcto, aumenta `app_launch` a `2.0` o `2.5`.

---

## pomodoro

```lua
M.pomodoro = {
    work_minutes  = 25,
    short_break   = 5,
    long_break    = 15,
    cycles_before_long_break = 4,
    enable_dnd    = true,
}
```

| Parámetro | Descripción | Por defecto |
|---|---|---|
| `work_minutes` | Duración de cada sesión de trabajo en minutos | 25 |
| `short_break` | Duración de la pausa corta en minutos | 5 |
| `long_break` | Duración de la pausa larga en minutos | 15 |
| `cycles_before_long_break` | Número de ciclos de trabajo antes de la pausa larga | 4 |
| `enable_dnd` | Si `true`, activa No Molestar durante el trabajo y lo desactiva en pausas | `true` |

---

## breaks

```lua
M.breaks = {
    interval_minutes      = 50,
    enabled               = true,
    break_display_seconds = 120,
}
```

| Parámetro | Descripción | Por defecto |
|---|---|---|
| `interval_minutes` | Minutos entre recordatorios de descanso. Valores válidos: 30, 45, 50, 60, 90 | 50 |
| `enabled` | Si `true`, los recordatorios se activan automáticamente al iniciar | `true` |
| `break_display_seconds` | Duración en segundos del banner de descanso activo en pantalla | 120 |

El intervalo también puede cambiarse en tiempo real desde el menú de enfoque sin editar el archivo.

---

## clipboard

```lua
M.clipboard = {
    max_entries = 20,
    ignore_apps = {
        "1Password",
        "Keychain Access",
        "Bitwarden",
        "LastPass",
        "Dashlane",
        "KeePassXC",
    },
}
```

| Parámetro | Descripción | Por defecto |
|---|---|---|
| `max_entries` | Número máximo de entradas en el historial del portapapeles | 20 |
| `ignore_apps` | Lista de nombres exactos de apps cuyo contenido copiado no se captura | Ver arriba |

Agrega a `ignore_apps` el nombre exacto de cualquier gestor de contraseñas o app con datos sensibles que uses. El nombre debe coincidir con el que muestra macOS (no el bundle ID).

---

## presentation

```lua
M.presentation = {
    enable_dnd    = true,
    hide_dock     = true,
    hide_desktop  = true,
}
```

| Parámetro | Descripción | Por defecto |
|---|---|---|
| `enable_dnd` | Si `true`, activa No Molestar al entrar en modo presentación | `true` |
| `hide_dock` | Si `true`, habilita autohide del Dock al entrar en modo presentación | `true` |
| `hide_desktop` | Si `true`, oculta los íconos del escritorio al entrar en modo presentación | `true` |

Puedes desactivar cualquiera de estas opciones individualmente cambiando su valor a `false`.

---

## launcher

```lua
M.launcher = {
    apps = {},
}
```

Lista de apps para el lanzador rápido. Vacío por defecto — el submenú de lanzador no aparece en el menú si la lista está vacía.

Cada entrada puede ser:
- Un string simple: `"Visual Studio Code"`
- Una tabla con nombre e ícono: `{ name = "Spotify", icon = "🎵" }`

Ejemplo con apps configuradas:

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

## menu_icon y focus_icon

```lua
M.menu_icon  = "⌘"
M.focus_icon = "◎"
```

Carácter emoji que se usa como ícono de cada menubar cuando no hay imagen PNG disponible.

Para usar un ícono nativo (recomendado):
1. Crea una imagen PNG de **18×18pt, monocromática**.
2. Nómbrala `macspaces_icon.png` (menú principal) o `macspaces_focus_icon.png` (menú de enfoque).
3. Colócala en `~/.hammerspoon/`.
4. Recarga con `⌘R`.

Si la imagen existe y es válida, el ícono emoji es ignorado.

---

## Ejemplos de personalización

### Agregar un perfil de estudio

```lua
M.profile_order = { "personal", "work", "study" }

M.profiles.study = {
    name               = "Study",
    apps               = { "Notion", "Safari", "Spotify" },
    browser            = "com.apple.Safari",
    confirm_deactivate = false,
}

M.hotkeys.study = { mods = { "cmd", "alt" }, key = "3" }
```

### Pomodoro extendido

```lua
M.pomodoro = {
    work_minutes             = 50,
    short_break              = 10,
    long_break               = 30,
    cycles_before_long_break = 3,
    enable_dnd               = true,
}
```

### Descanso más frecuente

```lua
M.breaks = {
    interval_minutes      = 30,
    enabled               = true,
    break_display_seconds = 90,
}
```

### Agregar un navegador personalizado

```lua
M.browser_names["com.sigmaos.sigmaos"] = "SigmaOS"
```

Después de editar cualquier parámetro, guarda y presiona `⌘R` en Hammerspoon para aplicar.

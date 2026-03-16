-- macspaces/config.lua
-- Configuración central de macSpaces. Edita este archivo para personalizar.

local M = {}

-- ─────────────────────────────────────────────
-- Versión
-- ─────────────────────────────────────────────
M.VERSION = "2.1.4"

-- ─────────────────────────────────────────────
-- Perfiles: orden de aparición en el menú
-- ─────────────────────────────────────────────
M.profile_order = { "personal", "work" }

M.profiles = {
    personal = {
        name     = "Personal",
        apps     = { "Safari" },
        browser  = "com.apple.Safari",
    },
    work = {
        name     = "Work",
        apps     = { "Microsoft Outlook", "Microsoft Teams", "Microsoft Edge" },
        browser  = "com.microsoft.edgemac",
    },
}

-- ─────────────────────────────────────────────
-- Retrasos (segundos)
-- ─────────────────────────────────────────────
M.delay = {
    short      = 0.5,
    medium     = 1.0,
    app_launch = 1.5,
}

-- ─────────────────────────────────────────────
-- Hotkeys: activar perfiles
-- ─────────────────────────────────────────────
M.hotkeys = {
    personal = { mods = { "cmd", "alt" }, key = "1" },
    work     = { mods = { "cmd", "alt" }, key = "2" },
}

-- ─────────────────────────────────────────────
-- Navegadores conocidos (allowlist)
-- Solo estos aparecen en el submenú.
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- Pomodoro
-- ─────────────────────────────────────────────
M.pomodoro = {
    work_minutes  = 25,   -- duración del ciclo de trabajo
    short_break   = 5,    -- pausa corta entre ciclos
    long_break    = 15,   -- pausa larga cada N ciclos
    cycles_before_long_break = 4,
    enable_dnd    = true, -- activar No Molestar durante el ciclo de trabajo
}

-- ─────────────────────────────────────────────
-- Descanso activo
-- ─────────────────────────────────────────────
M.breaks = {
    interval_minutes = 50, -- recordatorio cada N minutos
    enabled          = false, -- desactivado por defecto, el usuario lo activa
}

-- ─────────────────────────────────────────────
-- Portapapeles
-- ─────────────────────────────────────────────
M.clipboard = {
    max_entries = 20, -- máximo de entradas en el historial
}

-- ─────────────────────────────────────────────
-- Modo presentación
-- ─────────────────────────────────────────────
M.presentation = {
    enable_dnd    = true,  -- activar No Molestar al entrar en modo presentación
    hide_dock     = true,  -- ocultar el Dock automáticamente
    hide_desktop  = true,  -- ocultar íconos del escritorio
}

-- ─────────────────────────────────────────────
-- Lanzador rápido de apps
-- Agrega entradas como: { name = "Nombre App", icon = "🚀" }
-- o simplemente como string: "Nombre App"
-- ─────────────────────────────────────────────
M.launcher = {
    apps = {
        -- Ejemplos (descomenta los que quieras usar):
        -- { name = "Safari",           icon = "🌐" },
        -- { name = "Visual Studio Code", icon = "💻" },
        -- { name = "Spotify",          icon = "🎵" },
        -- { name = "Terminal",         icon = "⌨️"  },
    },
}

-- ─────────────────────────────────────────────
-- Ícono del menú
-- ─────────────────────────────────────────────
M.menu_icon = "⌘"

return M

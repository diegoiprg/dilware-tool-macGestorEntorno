-- macspaces/config.lua
-- Configuración central de macSpaces. Edita este archivo para personalizar.

local M = {}

M.VERSION = "2.11.6"

M.profile_order = { "personal", "work" }

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

M.delay = {
    short      = 0.5,
    medium     = 1.0,
    app_launch = 1.5,
}

M.hotkeys = {
    personal = { mods = { "cmd", "alt" }, key = "1" },
    work     = { mods = { "cmd", "alt" }, key = "2" },
}

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

M.pomodoro = {
    work_minutes  = 25,
    short_break   = 5,
    long_break    = 15,
    cycles_before_long_break = 4,
    enable_dnd    = true,
}

M.breaks = {
    interval_minutes      = 50,
    enabled               = true,
    break_display_seconds = 120,
}

M.clipboard = {
    max_entries = 20,
    -- Apps cuyo contenido copiado NO se captura (gestores de contraseñas, etc.)
    ignore_apps = {
        "1Password",
        "Keychain Access",
        "Bitwarden",
        "LastPass",
        "Dashlane",
        "KeePassXC",
    },
}

M.presentation = {
    enable_dnd    = true,
    hide_dock     = true,
    hide_desktop  = true,
}

M.launcher = {
    apps = {},
}

-- Ícono del menú (emoji fallback; para ícono nativo coloca macspaces_icon.png
-- 18×18pt monocromática en ~/.hammerspoon/)
M.menu_icon = "⌘"

-- Ícono del menú de enfoque (emoji fallback; para ícono nativo coloca
-- macspaces_focus_icon.png 18×18pt monocromática en ~/.hammerspoon/)
M.focus_icon = "◎"

return M

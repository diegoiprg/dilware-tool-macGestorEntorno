-- macspaces/dnd.lua
-- Control de No Molestar (Do Not Disturb) via hs.focus (Hammerspoon 0.9.97+)
-- con fallback a Focus via atajo de teclado del sistema.

local M = {}

local utils = require("macspaces.utils")

-- ─────────────────────────────────────────────
-- Helpers internos
-- ─────────────────────────────────────────────

-- Intenta usar la API nativa de Hammerspoon si está disponible
local function has_focus_api()
    return hs.focus ~= nil and hs.focus.setFocusModeEnabled ~= nil
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────

function M.enable()
    if has_focus_api() then
        hs.focus.setFocusModeEnabled(true)
        utils.log("[INFO] DND activado via hs.focus")
    else
        -- Fallback: escribir preferencia directamente (macOS Monterey y anteriores)
        hs.execute(
            "defaults -currentHost write com.apple.notificationcenterui doNotDisturb -bool true 2>/dev/null; " ..
            "killall NotificationCenter 2>/dev/null; true"
        )
        utils.log("[INFO] DND activado via defaults")
    end
end

function M.disable()
    if has_focus_api() then
        hs.focus.setFocusModeEnabled(false)
        utils.log("[INFO] DND desactivado via hs.focus")
    else
        hs.execute(
            "defaults -currentHost write com.apple.notificationcenterui doNotDisturb -bool false 2>/dev/null; " ..
            "killall NotificationCenter 2>/dev/null; true"
        )
        utils.log("[INFO] DND desactivado via defaults")
    end
end

-- Devuelve true si DND está activo (solo con API nativa)
function M.is_enabled()
    if has_focus_api() then
        return hs.focus.focusModeEnabled()
    end
    return nil -- desconocido sin API nativa
end

function M.toggle()
    if has_focus_api() then
        local enabled = hs.focus.focusModeEnabled()
        hs.focus.setFocusModeEnabled(not enabled)
        utils.log("[INFO] DND " .. (not enabled and "activado" or "desactivado") .. " via hs.focus")
        return not enabled
    else
        -- Sin API nativa: leer estado actual antes de cambiar
        local out = hs.execute("defaults -currentHost read com.apple.notificationcenterui doNotDisturb 2>/dev/null")
        local currently_on = out:match("1") ~= nil
        if currently_on then
            M.disable()
            return false
        else
            M.enable()
            return true
        end
    end
end

return M

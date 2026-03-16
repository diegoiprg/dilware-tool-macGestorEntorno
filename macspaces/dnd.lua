-- macspaces/dnd.lua
-- Control de No Molestar (Do Not Disturb) via AppleScript.
-- Compatible con macOS Monterey y posteriores (Focus / DND).

local M = {}

local utils = require("macspaces.utils")

-- Activa No Molestar
function M.enable()
    local script = [[
        tell application "System Events"
            tell process "Control Center"
                -- Activar Focus via shortcuts del sistema
            end tell
        end tell
    ]]
    -- Método más confiable: usar el shortcut de sistema via osascript
    local cmd = "shortcuts run 'Activar No Molestar' 2>/dev/null; " ..
                "defaults write com.apple.notificationcenterui doNotDisturb -bool true 2>/dev/null; " ..
                "killall NotificationCenter 2>/dev/null; true"
    hs.execute(cmd)
    utils.log("[INFO] DND activado")
end

-- Desactiva No Molestar
function M.disable()
    local cmd = "shortcuts run 'Desactivar No Molestar' 2>/dev/null; " ..
                "defaults write com.apple.notificationcenterui doNotDisturb -bool false 2>/dev/null; " ..
                "killall NotificationCenter 2>/dev/null; true"
    hs.execute(cmd)
    utils.log("[INFO] DND desactivado")
end

-- Alterna el estado de No Molestar via Focus API de Hammerspoon (si disponible)
-- Hammerspoon 0.9.97+ expone hs.focus
function M.toggle()
    if hs.focus then
        -- API nativa si está disponible
        local enabled = hs.focus.focusModeEnabled()
        if enabled then
            hs.focus.setFocusModeEnabled(false)
            utils.log("[INFO] DND desactivado via hs.focus")
        else
            hs.focus.setFocusModeEnabled(true)
            utils.log("[INFO] DND activado via hs.focus")
        end
        return not enabled
    end
    -- Fallback: no podemos leer el estado, solo intentamos activar
    M.enable()
    return true
end

return M

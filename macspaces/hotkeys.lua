-- macspaces/hotkeys.lua
-- Atajos de teclado globales para activar/desactivar perfiles.

local M = {}

local cfg      = require("macspaces.config")
local utils    = require("macspaces.utils")
local profiles = require("macspaces.profiles")

local registered = {}

-- Registra todos los hotkeys definidos en config
function M.register(on_change)
    -- Limpiar registros anteriores
    for _, hk in ipairs(registered) do
        hk:delete()
    end
    registered = {}

    for key, binding in pairs(cfg.hotkeys) do        local profile = cfg.profiles[key]
        if profile and binding then
            local hk = hs.hotkey.bind(binding.mods, binding.key, function()
                if profiles.is_active(key) then
                    profiles.deactivate(key, on_change)
                else
                    profiles.activate(key, on_change)
                end
            end)
            table.insert(registered, hk)
            utils.log(string.format("[INFO] Hotkey registrado: %s+%s → %s",
                table.concat(binding.mods, "+"), binding.key, profile.name))
        end
    end
end

-- Elimina todos los hotkeys registrados
function M.unregister()
    for _, hk in ipairs(registered) do
        hk:delete()
    end
    registered = {}
    utils.log("[INFO] Hotkeys eliminados")
end

return M

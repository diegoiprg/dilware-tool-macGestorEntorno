-- macspaces/audio.lua
-- Gestión del dispositivo de salida de audio predeterminado.

local M = {}

local utils = require("macspaces.utils")

-- Devuelve todos los dispositivos de salida disponibles
function M.output_devices()
    local devices = hs.audiodevice.allOutputDevices()
    local result  = {}
    for _, dev in ipairs(devices) do
        -- Excluir dispositivos virtuales sin nombre útil
        local name = dev:name()
        if name and name ~= "" then
            table.insert(result, dev)
        end
    end
    return result
end

-- Devuelve el dispositivo de salida predeterminado actual
function M.current_output()
    return hs.audiodevice.defaultOutputDevice()
end

-- Cambia el dispositivo de salida predeterminado
function M.set_output(device)
    local ok = device:setDefaultOutputDevice()
    if ok then
        utils.log("[OK] Audio: salida cambiada a " .. device:name())
        utils.notify("macSpaces", "Audio: " .. device:name())
    else
        utils.log("[ERROR] Audio: no se pudo cambiar a " .. device:name())
    end
end

-- Construye el submenú de selección de audio
function M.build_submenu()
    local devices = M.output_devices()
    local current = M.current_output()

    if #devices == 0 then
        return {{ title = "Sin dispositivos de audio", disabled = true }}
    end

    local items = {}
    for _, dev in ipairs(devices) do
        local name   = dev:name()
        local active = current and (dev:uid() == current:uid())

        table.insert(items, {
            title   = (active and "◉  " or "○  ") .. name,
            checked = active,
            fn      = function()
                if not active then M.set_output(dev) end
            end,
        })
    end

    return items
end

return M

-- macspaces/audio.lua
-- Gestión del dispositivo de salida de audio predeterminado.

local M = {}

local utils = require("macspaces.utils")

local cache = {
    devices       = nil,
    current       = nil,
    last_fetch    = 0,
    ttl           = 10,
}

function M.invalidate_cache()
    cache.devices    = nil
    cache.current    = nil
    cache.last_fetch = 0
end

-- Devuelve todos los dispositivos de salida disponibles
function M.output_devices()
    local now = os.time()
    if cache.devices and (now - cache.last_fetch) < cache.ttl then
        return cache.devices
    end

    local devices = hs.audiodevice.allOutputDevices()
    local result  = {}
    for _, dev in ipairs(devices) do
        local name = dev:name()
        if name and name ~= "" then
            table.insert(result, dev)
        end
    end

    cache.devices    = result
    cache.current    = hs.audiodevice.defaultOutputDevice()
    cache.last_fetch = now
    return result
end

-- Devuelve el dispositivo de salida predeterminado actual
function M.current_output()
    M.output_devices() -- Ensure cache is populated
    return cache.current
end

-- Cambia el dispositivo de salida predeterminado
function M.set_output(device)
    local ok = device:setDefaultOutputDevice()
    if ok then
        M.invalidate_cache()
        utils.log("[OK] Audio: salida cambiada a " .. device:name())
    else
        utils.log("[ERROR] Audio: no se pudo cambiar a " .. device:name())
        utils.notify("macSpaces", "No se pudo cambiar el audio a " .. device:name())
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
            title   = name,
            checked = active,
            fn      = function()
                if not active then M.set_output(dev) end
            end,
        })
    end

    return items
end

return M

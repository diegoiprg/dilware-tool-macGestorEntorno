-- macspaces/bluetooth.lua
-- Lista dispositivos Bluetooth conectados con información de batería.
-- Usa ioreg (herramienta nativa de macOS) para leer datos del sistema.

local M = {}

local utils = require("macspaces.utils")

-- Caché para evitar múltiples llamadas a ioreg por apertura del menú
local cache = {
    devices    = nil,
    last_fetch = 0,
    ttl        = 30,   -- segundos
}

-- ─────────────────────────────────────────────
-- Lectura via ioreg
-- ─────────────────────────────────────────────

local function parse_ioreg()
    -- Consulta 1: dispositivos con BatteryPercent (Apple, AirPods, algunos BT)
    -- Consulta 2: dispositivos con BatteryLevel (Logitech y otros terceros via BT)
    -- Consulta 3: todos los dispositivos BT conectados (para capturar los sin batería)
    local output = hs.execute(
        "ioreg -r -k BatteryPercent -l 2>/dev/null | grep -E '\"(Product|BatteryPercent|BatteryLevel|DeviceAddress)\"'; " ..
        "ioreg -r -k BatteryLevel -l 2>/dev/null | grep -E '\"(Product|BatteryPercent|BatteryLevel|DeviceAddress)\"'; " ..
        "ioreg -r -k DeviceAddress -l 2>/dev/null | grep -E '\"(Product|BatteryPercent|BatteryLevel|DeviceAddress)\"'"
    )

    local devices = {}
    local current = {}

    for line in output:gmatch("[^\n]+") do
        -- Valor string: "Product" = "MX Master 3"
        local key, val = line:match('"(%w+)"%s*=%s*"([^"]*)"')
        if not key then
            -- Valor numérico: "BatteryPercent" = 85
            key, val = line:match('"(%w+)"%s*=%s*(%d+)')
        end

        if key and val then
            if key == "Product" then
                if current.name then
                    table.insert(devices, current)
                end
                current = { name = val }
            elseif key == "BatteryPercent" then
                current.battery = tonumber(val)
            elseif key == "BatteryLevel" then
                -- Solo usar BatteryLevel si no hay BatteryPercent ya
                if not current.battery then
                    current.battery = tonumber(val)
                end
            elseif key == "DeviceAddress" then
                current.address = val
            end
        end
    end

    if current.name then
        table.insert(devices, current)
    end

    -- Eliminar duplicados por nombre (priorizar el que tenga batería)
    local seen = {}
    local unique = {}
    for _, dev in ipairs(devices) do
        if not seen[dev.name] then
            seen[dev.name] = true
            table.insert(unique, dev)
        elseif dev.battery and not seen[dev.name .. "_bat"] then
            -- Actualizar batería si el duplicado la tiene y el original no
            for _, u in ipairs(unique) do
                if u.name == dev.name and not u.battery then
                    u.battery = dev.battery
                    break
                end
            end
            seen[dev.name .. "_bat"] = true
        end
    end

    return unique
end

-- ─────────────────────────────────────────────
-- Helpers de presentación
-- ─────────────────────────────────────────────

local function battery_icon(pct)
    if not pct then return "○" end
    if pct >= 80 then return "🔋" end  -- carga alta
    if pct >= 20 then return "🪫" end  -- carga media/baja
    return "⚠️"                        -- crítico (< 20%)
end

local function battery_label(device)
    if device.battery then
        return string.format("%s  %d%%", battery_icon(device.battery), device.battery)
    end
    return "Sin datos de batería"
end

-- Ícono según tipo de dispositivo (heurística por nombre)
local function device_icon(name)
    local lower = name:lower()
    if lower:match("airpod") or lower:match("headphone") or lower:match("auricular") or lower:match("buds") then
        return "🎧"
    elseif lower:match("mouse") or lower:match("mx master") or lower:match("mx anywhere") or lower:match("lift") then
        return "🖱"
    elseif lower:match("keyboard") or lower:match("teclado") or lower:match("keys") then
        return "⌨️"
    elseif lower:match("trackpad") then
        return "⬜"
    elseif lower:match("speaker") or lower:match("altavoz") or lower:match("soundlink") then
        return "🔊"
    end
    return "📱"
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────

function M.devices()
    local now = os.time()
    if cache.devices and (now - cache.last_fetch) < cache.ttl then
        return cache.devices
    end
    local ok, result = pcall(parse_ioreg)
    if not ok then
        utils.log("[ERROR] bluetooth: " .. tostring(result))
        cache.devices = {}
    else
        cache.devices = result
    end
    cache.last_fetch = now
    return cache.devices
end

function M.build_submenu()
    local devices = M.devices()
    local items   = {}

    if #devices == 0 then
        table.insert(items, { title = "Sin dispositivos Bluetooth conectados", fn = function() end })
        return items
    end

    for i, dev in ipairs(devices) do
        local icon = device_icon(dev.name)
        -- Nombre del dispositivo (accionable, no disabled)
        table.insert(items, { title = icon .. "  " .. dev.name, fn = function() end })
        -- Batería: clic copia el porcentaje
        local bat = battery_label(dev)
        table.insert(items, {
            title = "Batería: " .. bat,
            fn    = function()
                if dev.battery then
                    hs.pasteboard.setContents(tostring(dev.battery) .. "%")
                end
            end,
        })
        if i < #devices then
            table.insert(items, { title = "-" })
        end
    end

    return items
end

return M

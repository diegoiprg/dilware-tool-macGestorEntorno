-- macspaces/bluetooth.lua
-- Lista dispositivos Bluetooth conectados con información de batería.

local M = {}

local utils = require("macspaces.utils")

local cache = { devices = nil, last_fetch = 0, ttl = 120 }

local function parse_ioreg()
    local output = hs.execute(
        "ioreg -r -k BatteryPercent -l 2>/dev/null | grep -E '\"(Product|BatteryPercent|BatteryLevel|DeviceAddress)\"'; " ..
        "ioreg -r -k BatteryLevel -l 2>/dev/null | grep -E '\"(Product|BatteryPercent|BatteryLevel|DeviceAddress)\"'; " ..
        "ioreg -r -k DeviceAddress -l 2>/dev/null | grep -E '\"(Product|BatteryPercent|BatteryLevel|DeviceAddress)\"'"
    )
    local devices, current = {}, {}
    for line in output:gmatch("[^\n]+") do
        local key, val = line:match('"(%w+)"%s*=%s*"([^"]*)"')
        if not key then key, val = line:match('"(%w+)"%s*=%s*(%d+)') end
        if key and val then
            if key == "Product" then
                if current.name then table.insert(devices, current) end
                current = { name = val }
            elseif key == "BatteryPercent" then current.battery = tonumber(val)
            elseif key == "BatteryLevel" and not current.battery then current.battery = tonumber(val)
            elseif key == "DeviceAddress" then current.address = val
            end
        end
    end
    if current.name then table.insert(devices, current) end

    local seen, unique = {}, {}
    for _, dev in ipairs(devices) do
        if not seen[dev.name] then
            seen[dev.name] = true; table.insert(unique, dev)
        elseif dev.battery then
            for _, u in ipairs(unique) do
                if u.name == dev.name and not u.battery then u.battery = dev.battery; break end
            end
        end
    end
    return unique
end

local function device_icon(name)
    local l = name:lower()
    if l:match("airpod") or l:match("headphone") or l:match("buds") then return "🎧"
    elseif l:match("mouse") or l:match("mx master") or l:match("mx anywhere") then return "🖱"
    elseif l:match("keyboard") or l:match("teclado") or l:match("keys") then return "⌨️"
    elseif l:match("trackpad") then return "⬜"
    elseif l:match("speaker") or l:match("soundlink") then return "🔊"
    end
    return "📱"
end

local function battery_icon(pct)
    if not pct then return "○" end
    if pct >= 80 then return "🔋" elseif pct >= 20 then return "🪫" end
    return "⚠️"
end

function M.devices()
    local now = os.time()
    if cache.devices and (now - cache.last_fetch) < cache.ttl then return cache.devices end
    local ok, result = pcall(parse_ioreg)
    cache.devices = ok and result or {}
    cache.last_fetch = now
    if not ok then utils.log("[ERROR] bluetooth: " .. tostring(result)) end
    return cache.devices
end

function M.build_submenu()
    local devices = M.devices()
    if #devices == 0 then return { utils.disabled_item("Sin dispositivos conectados") } end
    local items = {}
    for i, dev in ipairs(devices) do
        table.insert(items, utils.disabled_item(device_icon(dev.name) .. "  " .. dev.name))
        local bat = dev.battery and string.format("%s  %d%%", battery_icon(dev.battery), dev.battery) or "Sin datos"
        table.insert(items, {
            title = "Batería: " .. bat,
            fn = function() if dev.battery then hs.pasteboard.setContents(tostring(dev.battery).."%") end end,
        })
        if i < #devices then table.insert(items, { title = "-" }) end
    end
    return items
end

return M

-- macspaces/bluetooth.lua
-- Lista dispositivos Bluetooth conectados con información de batería.
-- Usa helper Swift nativo (bt_devices) para obtener nombres BT reales.

local M = {}

local utils = require("macspaces.utils")

local cache = { devices = nil, last_fetch = 0, ttl = 120 }

-- ── Helper Swift ──

local HS_DIR  = (os.getenv("HOME") or "") .. "/.hammerspoon"
local BIN     = HS_DIR .. "/bt_devices"
local SRC     = HS_DIR .. "/bt_devices.swift"

local function ensure_binary()
    local f = io.open(BIN, "r")
    if f then f:close(); return true end
    local fs = io.open(SRC, "r")
    if not fs then utils.log("[WARN] bluetooth: bt_devices.swift no encontrado"); return false end
    fs:close()
    local cmd = string.format("swiftc %s -o %s 2>&1", SRC, BIN)
    local output, ok = hs.execute(cmd, true)
    if not ok then utils.log("[ERROR] bluetooth: compilación falló — " .. (output or "")); return false end
    return true
end

local function parse_helper()
    if not ensure_binary() then return {} end
    local output, ok = hs.execute(BIN .. " 2>/dev/null", true)
    if not ok or not output or output == "" then return {} end

    local devices = {}
    for line in output:gmatch("[^\n]+") do
        local name, addr, bat = line:match("^(.-)|(.-)|(-?%d+)$")
        if name then
            local battery = tonumber(bat)
            if battery and battery < 0 then battery = nil end
            table.insert(devices, { name = name, address = addr, battery = battery })
        end
    end
    return devices
end

-- ── UI ──

local function device_icon(name)
    local l = name:lower()
    if l:match("airpod") or l:match("headphone") or l:match("buds") then return "🎧"
    elseif l:match("mouse") or l:match("mx") then return "🖱"
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
    local ok, result = pcall(parse_helper)
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

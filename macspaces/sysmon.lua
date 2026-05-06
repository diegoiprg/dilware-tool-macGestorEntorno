-- macspaces/sysmon.lua
-- Fila base del overlay: CPU, RAM, GPU, Red, Batería/Corriente
-- Semáforo individual por métrica: verde <60%, amarillo <85%, rojo ≥85%
-- CPU via hs.host.cpuUsage (async), RAM via memory_pressure, GPU via ioreg

local M = {}
local battery = require("macspaces.battery")

local CACHE_TTL     = 2
local NET_CHECK_TTL = 10  -- ping cada 10s, no cada 2s

local state = {
    cpu         = nil,
    ram         = nil,
    gpu         = nil,
    net_up      = nil,
    net_down    = nil,
    online      = nil,   -- true / false / nil
    iface_type  = nil,   -- "wifi" / "eth" / nil
    vpn         = false,
    last        = 0,
    last_net    = 0,
    cpu_pending = false,
    net_prev    = nil,
}

-- ── Colores semáforo ────────────────────────────────────────────────────────

local C = {
    ok   = { red = 0.25, green = 0.85, blue = 0.45, alpha = 1 },
    warn = { red = 0.95, green = 0.75, blue = 0.10, alpha = 1 },
    crit = { red = 0.95, green = 0.28, blue = 0.22, alpha = 1 },
    dim  = { red = 0.55, green = 0.55, blue = 0.60, alpha = 1 },
    bat_ok      = { red = 0.25, green = 0.85, blue = 0.45, alpha = 1 },
    bat_low     = { red = 0.95, green = 0.75, blue = 0.10, alpha = 1 },
    bat_crit    = { red = 0.95, green = 0.28, blue = 0.22, alpha = 1 },
    bat_plugged  = { red = 0.40, green = 0.70, blue = 1.00, alpha = 1 },
    bat_nomini   = { red = 0.55, green = 0.55, blue = 0.60, alpha = 1 },
    net          = { red = 0.55, green = 0.75, blue = 0.95, alpha = 1 },
    online       = { red = 0.25, green = 0.85, blue = 0.45, alpha = 1 },
    offline      = { red = 0.95, green = 0.28, blue = 0.22, alpha = 1 },
}

local function color_for_pct(pct)
    if not pct then return C.dim end
    if pct >= 85 then return C.crit end
    if pct >= 60 then return C.warn end
    return C.ok
end

-- ── CPU ─────────────────────────────────────────────────────────────────────

local function refresh_cpu()
    if state.cpu_pending then return end
    state.cpu_pending = true
    hs.host.cpuUsage(0.4, function(result)
        state.cpu_pending = false
        if result and result.overall then
            state.cpu = math.floor(100 - (result.overall.idle or 0))
        end
    end)
end

-- ── RAM ─────────────────────────────────────────────────────────────────────

local function read_ram_pct()
    local f = io.popen("memory_pressure 2>/dev/null | awk '/free percentage/{print 100-$NF}'")
    if not f then return nil end
    local raw = f:read("*a")
    f:close()
    return tonumber(raw:match("%d+"))
end

-- ── GPU ─────────────────────────────────────────────────────────────────────

local function read_gpu_pct()
    local f = io.popen("ioreg -r -d 1 -w 0 -c IOAccelerator 2>/dev/null | grep 'Device Utilization'")
    if not f then return nil end
    local raw = f:read("*a")
    f:close()
    return tonumber(raw:match('"Device Utilization %%"=(%d+)'))
end

-- ── Red ─────────────────────────────────────────────────────────────────────

local function read_net()
    local iface = hs.network.primaryInterfaces()
    if not iface then return nil, nil end

    local f = io.popen("netstat -ib -I " .. iface .. " 2>/dev/null | awk 'NR==2{print $7, $10}'")
    if not f then return nil, nil end
    local raw = f:read("*a")
    f:close()

    local sent, recv = raw:match("(%d+)%s+(%d+)")
    if not sent then return nil, nil end
    sent, recv = tonumber(sent), tonumber(recv)

    local now = os.time()
    if state.net_prev then
        local dt = now - state.net_prev.time
        if dt > 0 then
            local up   = math.max(0, math.floor((sent - state.net_prev.sent) / dt / 1024))
            local down = math.max(0, math.floor((recv - state.net_prev.recv) / dt / 1024))
            state.net_prev = { sent = sent, recv = recv, time = now }
            return up, down
        end
    end
    state.net_prev = { sent = sent, recv = recv, time = now }
    return nil, nil
end

local function fmt_net(kb)
    if not kb then return "—" end
    if kb >= 1024 then return string.format("%.1f MB/s", kb / 1024) end
    if kb >= 100  then return string.format("%d KB/s", kb) end
    return string.format("%d KB/s", kb)
end

-- ── Conectividad ────────────────────────────────────────────────────────────

-- Detecta tipo de interfaz primaria: "wifi", "eth" o nil
local function detect_iface_type()
    local iface = hs.network.primaryInterfaces()
    if not iface then return nil end
    if iface:match("^en") then
        -- en0 suele ser WiFi en MacBook, Ethernet en Mac Mini — verificar via networksetup
        local f = io.popen("networksetup -getinfo Wi-Fi 2>/dev/null | grep 'IP address'")
        if f then
            local out = f:read("*a"); f:close()
            -- Si la IP de wifi coincide con la interfaz primaria → es wifi
            local wifi_ip = out:match("IP address: (%S+)")
            local details = hs.network.interfaceDetails(iface)
            local iface_ip = details and details.IPv4 and details.IPv4.Addresses and details.IPv4.Addresses[1]
            if wifi_ip and iface_ip and wifi_ip == iface_ip then return "wifi" end
        end
        -- Fallback: en0 sin coincidencia wifi → ethernet
        return "eth"
    end
    if iface:match("^utun") or iface:match("^ipsec") then return "vpn" end
    return "eth"
end

-- Detecta si hay VPN activa (interfaz utun con ruta por defecto o similar)
local function detect_vpn()
    local f = io.popen("scutil --nc list 2>/dev/null | grep Connected")
    if f then
        local out = f:read("*a"); f:close()
        if out and out ~= "" then return true end
    end
    -- Fallback: buscar interfaz utun con IP asignada
    for _, iface in ipairs(hs.network.interfaces()) do
        if iface:match("^utun") then
            local d = hs.network.interfaceDetails(iface)
            if d and d.IPv4 then return true end
        end
    end
    return false
end

local function refresh_online()
    local now = os.time()
    if (now - state.last_net) < NET_CHECK_TTL then return end
    state.last_net = now
    state.iface_type = detect_iface_type()
    state.vpn        = detect_vpn()
    -- Ping a 1.1.1.1 — IP directa, sin depender de DNS
    hs.task.new("/sbin/ping", function(code)
        state.online = (code == 0)
    end, { "-c1", "-W1", "-t2", "1.1.1.1" }):start()
end

-- ── Update ──────────────────────────────────────────────────────────────────

function M.update()
    local now = os.time()
    if (now - state.last) < CACHE_TTL then return end
    state.last = now
    refresh_cpu()
    state.ram = read_ram_pct()
    state.gpu = read_gpu_pct()
    state.net_up, state.net_down = read_net()
    refresh_online()
end

-- ── Styledtext helpers ──────────────────────────────────────────────────────

local BASE = { font = { name = ".AppleSystemUIFont", size = 13 }, shadow = {
    offset = { h = 0, w = 0 }, blurRadius = 2, color = { white = 0, alpha = 0.40 }
}}

local function seg(text, color)
    return hs.styledtext.new(text, BASE):setStyle({ color = color }, 1, -1)
end

local function join(parts)
    local result = parts[1]
    for i = 2, #parts do result = result .. parts[i] end
    return result
end

local function pct_seg(label, val)
    local txt = label .. (val and (val .. "%") or "—")
    return seg(txt, color_for_pct(val))
end

local function bat_overlay_seg()
    if not battery.has_battery() then return nil end
    local pct = math.floor(battery.percentage())
    local plugged = battery.is_plugged()
    local icon = plugged and "⚡" or (pct < 20 and "🪫" or "🔋")
    local color = plugged and C.bat_plugged
        or (pct < 20 and C.bat_crit)
        or (pct < 40 and C.bat_low)
        or C.bat_ok
    return seg(icon .. pct .. "%", color)
end

-- ── Overlay row ─────────────────────────────────────────────────────────────

function M.overlay_row()
    M.update()

    local sep = seg("  ", C.dim)

    -- Conectividad: ETH/WIFI coloreado + vpn solo si activa
    local net_segs = {}
    if state.online == nil then
        net_segs = { seg("…", C.dim) }
    else
        local type_lbl = state.iface_type == "wifi" and "≋ WIFI" or "⌁ CABLE"
        local type_color = state.online and C.online or C.offline
        table.insert(net_segs, seg(type_lbl, type_color))
        if state.vpn then
            table.insert(net_segs, seg(" vpn", C.bat_plugged))
        end
    end

    local parts = {
        seg("⬡  ", C.dim),
        pct_seg("CPU ", state.cpu), sep,
        pct_seg("RAM ", state.ram), sep,
        pct_seg("GPU ", state.gpu), sep,
    }
    for _, s in ipairs(net_segs) do table.insert(parts, s) end

    -- Batería solo en MacBook; Mac Mini no muestra nada de energía
    local bat = bat_overlay_seg()
    if bat then
        table.insert(parts, sep)
        table.insert(parts, bat)
    end

    return { label = join(parts), pct = 0 }  -- fondo siempre neutro
end

-- ── Submenú para el menú principal ─────────────────────────────────────────

local utils = require("macspaces.utils")

local function bar(pct, width)
    width = width or 10
    if not pct then return string.rep("▱", width) .. " —" end
    local filled = math.floor((pct / 100) * width)
    return string.rep("▰", filled) .. string.rep("▱", width - filled) .. string.format(" %d%%", pct)
end


function M.build_submenu()
    M.update()
    local items = {}

    table.insert(items, utils.disabled_item("CPU   " .. bar(state.cpu)))
    table.insert(items, utils.disabled_item("RAM   " .. bar(state.ram)))
    table.insert(items, utils.disabled_item("GPU   " .. bar(state.gpu)))

    if battery.has_battery() then
        table.insert(items, { title = "-" })
        local pct = math.floor(battery.percentage())
        local plugged = battery.is_plugged()
        local charging = battery.is_charging()
        local state_str = charging and "Cargando" or (plugged and "Conectado" or "En batería")
        table.insert(items, utils.disabled_item(string.format("Bat   %s  %s", bar(pct), state_str)))
        local tr = hs.battery.timeRemaining()
        if tr and tr > 0 and not plugged then
            table.insert(items, utils.disabled_item(string.format(
                "      %d:%02d restante", math.floor(tr / 60), tr % 60)))
        end
    end

    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Actualizar",
        fn    = function()
            state.last = 0   -- forzar refresh en próximo update()
            state.cpu_pending = false
        end,
    })

    return items
end

function M.net_state()
    return {
        iface_type = state.iface_type,
        vpn        = state.vpn,
        online     = state.online,
        net_up     = state.net_up,
        net_down   = state.net_down,
    }
end

function M.fmt_net(kb) return fmt_net(kb) end

return M

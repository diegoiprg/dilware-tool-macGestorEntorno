-- macspaces/network.lua
-- Información de red: interfaz activa, IP local, IP externa, país, ISP.
-- La IP externa se obtiene de forma asíncrona via ipapi.co (HTTPS gratuito).

local M = {}

local utils = require("macspaces.utils")

local cache = {
    local_info  = nil,
    remote_info = nil,
    fetching    = false,
    last_fetch  = 0,
    ttl         = 60,
}

-- ─────────────────────────────────────────────
-- Información local
-- ─────────────────────────────────────────────

local function get_local_info()
    local info    = {}
    local ifaces  = hs.network.interfaces()
    local active_iface = nil

    if hs.network.primaryInterfaces then
        local primary = hs.network.primaryInterfaces()
        if primary and primary ~= "" then active_iface = primary end
    end

    if not active_iface then
        for _, iface in ipairs(ifaces or {}) do
            local details = hs.network.interfaceDetails(iface)
            if details and details["IPv4"] then
                active_iface = iface
                break
            end
        end
    end

    if active_iface then
        info.interface = active_iface
        if     active_iface:match("^en0")  then info.type = "WiFi"
        elseif active_iface:match("^en")   then info.type = "Ethernet"
        elseif active_iface:match("^utun") or active_iface:match("^ppp") then info.type = "VPN"
        else   info.type = active_iface
        end

        local details = hs.network.interfaceDetails(active_iface)
        if details and details["IPv4"] then
            local addrs = details["IPv4"]["Addresses"]
            if addrs and #addrs > 0 then info.local_ip = addrs[1] end
        end
    end

    local wifi = hs.wifi.currentNetwork and hs.wifi.currentNetwork()
    if wifi then info.ssid = wifi end

    return info
end

-- ─────────────────────────────────────────────
-- Información remota (IP externa) — HTTPS via ipapi.co
-- ─────────────────────────────────────────────

local function normalize_response(data)
    return {
        query       = data.ip,
        country     = data.country_name,
        countryCode = data.country_code,
        regionName  = data.region,
        city        = data.city,
        isp         = data.org or "?",
        org         = data.org or "?",
    }
end

local function fetch_remote_info(on_done)
    if cache.fetching then return end

    local now = os.time()
    if cache.remote_info and (now - cache.last_fetch) < cache.ttl then
        if on_done then on_done() end
        return
    end

    cache.fetching = true
    utils.log("[INFO] network: consultando ipapi.co")

    local url = "https://ipapi.co/json/"

    hs.http.asyncGet(url, nil, function(status, body, _)
        cache.fetching = false
        if status == 200 and body then
            local ok, data = pcall(function() return hs.json.decode(body) end)
            if ok and data and data.ip then
                cache.remote_info = normalize_response(data)
                cache.last_fetch  = os.time()
                utils.log("[OK] network: IP externa obtenida")
            else
                utils.log("[WARN] network: respuesta inválida de ipapi.co")
            end
        else
            utils.log("[WARN] network: no se pudo consultar ipapi.co (status " .. tostring(status) .. ")")
        end
        if on_done then on_done() end
    end)
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────

function M.refresh(on_done)
    cache.local_info = get_local_info()
    fetch_remote_info(on_done)
end

function M.local_info()
    if not cache.local_info then
        cache.local_info = get_local_info()
    end
    return cache.local_info
end

function M.remote_info()
    return cache.remote_info
end

-- ─────────────────────────────────────────────
-- Submenú
-- ─────────────────────────────────────────────

function M.build_submenu(on_update)
    local local_i  = M.local_info()
    local remote_i = M.remote_info()
    local items    = {}

    local type_icon = ({ WiFi = "📶", Ethernet = "🔌", VPN = "🔒" })[local_i.type or ""] or "🌐"

    table.insert(items, utils.disabled_item(type_icon .. "  " .. (local_i.type or "Sin conexión")))

    if local_i.ssid     then table.insert(items, utils.info_item("Red: ",       local_i.ssid))     end
    if local_i.local_ip then table.insert(items, utils.info_item("IP local: ",  local_i.local_ip)) end

    table.insert(items, { title = "-" })

    if remote_i then
        table.insert(items, utils.disabled_item("🌍  IP externa"))
        table.insert(items, utils.info_item("IP: ",       remote_i.query      or "?"))
        table.insert(items, utils.info_item("País: ",     remote_i.country    or "?"))
        table.insert(items, utils.info_item("Región: ",   remote_i.regionName or "?"))
        table.insert(items, utils.info_item("Ciudad: ",   remote_i.city       or "?"))
        table.insert(items, utils.info_item("ISP: ",      remote_i.isp        or "?"))
    else
        table.insert(items, utils.disabled_item("Obteniendo IP externa…"))
    end

    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Actualizar",
        fn    = function()
            cache.remote_info = nil
            cache.local_info  = nil
            M.refresh(on_update)
        end,
    })

    return items
end

return M

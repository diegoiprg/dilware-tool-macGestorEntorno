-- macspaces/vpn.lua
-- Detección de VPN activa: interfaces utun*/ppp*, IP del túnel,
-- información geográfica via ip-api.com (reutiliza caché de network.lua).

local M = {}

local utils = require("macspaces.utils")

-- ─────────────────────────────────────────────
-- Detección de interfaces VPN
-- ─────────────────────────────────────────────

-- Devuelve tabla con las interfaces VPN activas y sus IPs
-- Excluye interfaces utun del sistema (iCloud, Handoff, AirDrop) que usan
-- IPs de link-local (169.254.x.x) o rangos reservados de Apple (100.64.x.x).
-- Solo considera VPN real si la IP es de rango privado estándar o pública.
local function detect_vpn_interfaces()
    local vpn_ifaces = {}
    local ifaces = hs.network.interfaces()
    if not ifaces then return vpn_ifaces end

    for _, iface in ipairs(ifaces) do
        -- utun* = WireGuard, IKEv2, OpenVPN TUN; ppp* = L2TP, PPTP
        if iface:match("^utun") or iface:match("^ppp") then
            local details = hs.network.interfaceDetails(iface)
            if details and details["IPv4"] then
                local addrs = details["IPv4"]["Addresses"]
                local ip = (addrs and #addrs > 0) and addrs[1] or nil

                -- Filtrar IPs del sistema: link-local (169.254.x.x) y
                -- CGNAT de Apple/iCloud (100.64.x.x - 100.127.x.x)
                local is_system = false
                if ip then
                    if ip:match("^169%.254%.") then is_system = true end
                    local a, b = ip:match("^(%d+)%.(%d+)%.")
                    if a == "100" and tonumber(b) >= 64 and tonumber(b) <= 127 then
                        is_system = true
                    end
                end

                if not is_system then
                    table.insert(vpn_ifaces, { interface = iface, ip = ip })
                end
            end
        end
    end

    return vpn_ifaces
end

-- ─────────────────────────────────────────────
-- Caché de información remota de la IP del túnel
-- ─────────────────────────────────────────────

local cache = {
    data      = nil,
    fetching  = false,
    last_ip   = nil,   -- IP consultada; si cambia, se invalida
    last_fetch = 0,
    ttl        = 120,  -- segundos
}

local function fetch_tunnel_info(tunnel_ip, on_done)
    if cache.fetching then return end
    -- Nunca consultar sin IP de túnel: evita exponer la IP real del usuario
    if not tunnel_ip or tunnel_ip == "" then
        if on_done then on_done() end
        return
    end

    local now = os.time()
    -- Reusar caché si la IP no cambió y no expiró
    if cache.data and cache.last_ip == tunnel_ip and (now - cache.last_fetch) < cache.ttl then
        if on_done then on_done() end
        return
    end

    cache.fetching = true
    utils.log("[INFO] vpn: consultando ip-api.com para " .. (tunnel_ip or "?"))

    local url = "http://ip-api.com/json/" .. (tunnel_ip or "") ..
                "?fields=status,query,country,countryCode,regionName,city,isp,org,as,proxy,hosting"

    hs.http.asyncGet(url, nil, function(status, body, _)
        cache.fetching = false
        if status == 200 and body then
            local ok, data = pcall(function() return hs.json.decode(body) end)
            if ok and data and data.status == "success" then
                cache.data       = data
                cache.last_ip    = tunnel_ip
                cache.last_fetch = os.time()
                utils.log("[OK] vpn: info obtenida para " .. (data.query or "?"))
            else
                utils.log("[WARN] vpn: respuesta inválida de ip-api.com")
            end
        else
            utils.log("[WARN] vpn: no se pudo consultar ip-api.com (status " .. tostring(status) .. ")")
        end
        if on_done then on_done() end
    end)
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────

-- Devuelve true si hay al menos una interfaz VPN activa
function M.is_active()
    return #detect_vpn_interfaces() > 0
end

-- Devuelve la lista de interfaces VPN activas
function M.interfaces()
    return detect_vpn_interfaces()
end

-- Refresca la información remota del túnel
-- Solo consulta si hay una IP de túnel válida; evita consultar la IP real del usuario
function M.refresh(on_done)
    local ifaces = detect_vpn_interfaces()
    if #ifaces > 0 and ifaces[1].ip then
        fetch_tunnel_info(ifaces[1].ip, on_done)
    else
        -- Sin VPN activa o sin IP de túnel: limpiar caché y no consultar
        cache.data = nil
        if on_done then on_done() end
    end
end

-- Helper: ítem informativo legible (usa utils.info_item compartido)
local function info_item(label, value)
    return utils.info_item(label, value)
end

-- Construye el submenú de VPN
function M.build_submenu(on_update)
    local ifaces = detect_vpn_interfaces()
    local items  = {}

    if #ifaces == 0 then
        table.insert(items, { title = "🔓  Sin VPN activa", fn = function() end })
        return items
    end

    table.insert(items, {
        title = "🔒  VPN activa (" .. #ifaces .. " interfaz" .. (#ifaces > 1 and "es" or "") .. ")",
        fn    = function() end,
    })
    table.insert(items, { title = "-" })

    for _, iface in ipairs(ifaces) do
        table.insert(items, info_item("Interfaz: ", iface.interface))
        if iface.ip then
            table.insert(items, info_item("IP del túnel: ", iface.ip))
        end
    end

    local info = cache.data
    if info then
        table.insert(items, { title = "-" })
        table.insert(items, { title = "🌍  IP pública via VPN", fn = function() end })
        table.insert(items, info_item("IP: ",       info.query      or "?"))
        table.insert(items, info_item("País: ",     info.country    or "?"))
        table.insert(items, info_item("Región: ",   info.regionName or "?"))
        table.insert(items, info_item("Ciudad: ",   info.city       or "?"))
        table.insert(items, info_item("ISP: ",      info.isp        or "?"))
        table.insert(items, info_item("Operador: ", info.org        or "?"))
    else
        table.insert(items, { title = "-" })
        table.insert(items, { title = "Obteniendo información…", fn = function() end })
    end

    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Actualizar",
        fn    = function()
            cache.data = nil
            -- on_update se pasa como callback de M.refresh; no llamar dos veces
            M.refresh(on_update)
        end,
    })

    return items
end

return M

-- macspaces/menu.lua
-- Construcción y gestión del menú de la barra de estado.

local M = {}

local cfg          = require("macspaces.config")
local profiles     = require("macspaces.profiles")
local browsers     = require("macspaces.browsers")
local audio        = require("macspaces.audio")
local battery      = require("macspaces.battery")
local history      = require("macspaces.history")
local pomodoro     = require("macspaces.pomodoro")
local breaks       = require("macspaces.breaks")
local clipboard    = require("macspaces.clipboard")
local bluetooth    = require("macspaces.bluetooth")
local network      = require("macspaces.network")
local vpn          = require("macspaces.vpn")
local presentation = require("macspaces.presentation")
local launcher     = require("macspaces.launcher")

local menubar = hs.menubar.new()

local function refresh()
    M.build()
end

function M.build()
    local items = {}

    -- ══ Perfiles ══════════════════════════════
    for _, key in ipairs(cfg.profile_order) do
        local profile = cfg.profiles[key]
        if profile then
            local active = profiles.is_active(key)
            local label  = (active and "◉  " or "○  ") .. profile.name
            local action = active and "  —  Desactivar" or "  —  Activar"

            table.insert(items, {
                title = label .. action,
                fn    = function()
                    if active then
                        local st = profiles.get_state(key)
                        if st and st.started_at then
                            history.record_session(key, st.started_at)
                        end
                        profiles.deactivate(key, refresh)
                    else
                        profiles.activate(key, function()
                            if profile.browser then
                                local current = browsers.current()
                                if current ~= profile.browser then
                                    browsers.set_default(profile.browser)
                                end
                            end
                            refresh()
                        end)
                    end
                end,
            })
        end
    end

    -- ══ Entorno ═══════════════════════════════
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Navegador predeterminado",
        menu  = browsers.build_submenu(),
    })
    table.insert(items, {
        title = "Salida de audio",
        menu  = audio.build_submenu(),
    })

    -- ══ Dispositivos ══════════════════════════
    table.insert(items, { title = "-" })

    -- Batería inline (solo MacBook)
    local bat = battery.status_label()
    if bat then
        table.insert(items, { title = bat, fn = function() end })
    end

    -- Bluetooth con conteo inline
    local bt_devices = bluetooth.devices()
    local bt_title   = #bt_devices > 0
        and ("Bluetooth  (" .. #bt_devices .. ")")
        or  "Bluetooth"
    table.insert(items, {
        title = bt_title,
        menu  = bluetooth.build_submenu(),
    })

    -- ══ Red ═══════════════════════════════════
    table.insert(items, { title = "-" })

    -- Red con IP local inline
    local local_i   = network.local_info()
    local net_title = "Red"
    if local_i and local_i.local_ip then
        local type_icon = ({ WiFi = "📶", Ethernet = "🔌", VPN = "🔒" })[local_i.type or ""] or "🌐"
        net_title = "Red  " .. type_icon .. "  " .. local_i.local_ip
    end
    table.insert(items, {
        title = net_title,
        menu  = network.build_submenu(refresh),
    })

    table.insert(items, {
        title = vpn.is_active() and "VPN  🔒" or "VPN",
        menu  = vpn.build_submenu(refresh),
    })

    -- ══ Productividad ═════════════════════════
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Portapapeles",
        menu  = clipboard.build_submenu(refresh),
    })
    table.insert(items, {
        title = "Lanzador",
        menu  = launcher.build_submenu(),
    })

    -- Pomodoro: tiempo restante en el título del ítem padre
    local pom_title = pomodoro.is_active()
        and ("Pomodoro  " .. (pomodoro.time_label() or ""))
        or  "Pomodoro"
    table.insert(items, {
        title = pom_title,
        menu  = pomodoro.build_submenu(refresh),
    })

    table.insert(items, {
        title = breaks.is_enabled() and "Descanso activo  ◉" or "Descanso activo",
        menu  = breaks.build_submenu(refresh),
    })

    -- Modo presentación: acceso rápido si está activo
    local pres_title = presentation.is_active()
        and "🎬  Presentación  —  Desactivar"
        or  "Modo presentación"
    table.insert(items, {
        title = pres_title,
        menu  = presentation.build_submenu(refresh),
    })

    -- ══ Historial ═════════════════════════════
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Historial de hoy",
        menu  = history.build_submenu(),
    })

    -- ══ Sistema ═══════════════════════════════
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Ver registro",
        fn    = function()
            local log_path = os.getenv("HOME") .. "/.hammerspoon/debug.log"
            hs.execute("open " .. log_path)
        end,
    })
    table.insert(items, {
        title = "Recargar configuración",
        fn    = hs.reload,
    })

    menubar:setTitle(cfg.menu_icon)
    menubar:setMenu(items)
end

function M.destroy()
    if menubar then menubar:delete() end
end

return M

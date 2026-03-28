-- macspaces/menu.lua
-- Construcción y gestión del menú de la barra de estado.
-- Usa setMenu(fn) para construir el menú on-demand al abrirse,
-- evitando parpadeos por reconstrucciones mientras está visible.
-- Sigue Apple Human Interface Guidelines para menubar apps.

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
local music        = require("macspaces.music")

local menubar = hs.menubar.new()

-- SF Symbols para Apple HIG
local ICON = {
    profile   = "person.circle",
    browser   = "globe",
    audio     = "speaker.wave.2",
    music     = "music.note",
    battery   = "battery.100",
    bluetooth = "dot.radiowaves.left.and.right",
    network   = "network",
    vpn       = "lock.shield",
    clipboard = "doc.on.clipboard",
    launcher  = "app.badge",
    pomodoro  = "timer",
    breaks    = "figure.stand",
    present   = "theatermasks",
    history   = "clock",
    reload    = "arrow.clockwise",
    log       = "doc.text",
    checkOn   = "checkmark.circle.fill",
    checkOff  = "circle",
}

local function hsicon(name)
    local ok, img = pcall(function()
        return hs.image.imageFromName(name)
    end)
    return ok and img or name
end

-- ─────────────────────────────────────────────
-- Construcción del menú (llamada on-demand por Hammerspoon)
-- ─────────────────────────────────────────────

local function build_items()
    local function refresh() M.build() end

    local items = {}

    -- ══ Perfiles ══════════════════════════════
    for _, key in ipairs(cfg.profile_order) do
        local profile = cfg.profiles[key]
        if profile then
            local active = profiles.is_active(key)
            local check  = active and ICON.checkOn or ICON.checkOff

            table.insert(items, {
                title   = profile.name,
                image   = hsicon(check),
                fn      = function()
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
        title = "Navegador",
        image = hsicon(ICON.browser),
        menu  = browsers.build_submenu(),
    })
    table.insert(items, {
        title = "Audio",
        image = hsicon(ICON.audio),
        menu  = audio.build_submenu(),
    })
    table.insert(items, {
        title = music.display_info(),
        image = hsicon(ICON.music),
        menu  = music.build_submenu(),
    })

    -- ══ Dispositivos ══════════════════════════════
    table.insert(items, { title = "-" })

    local bat = battery.status_label()
    if bat then
        local pct_raw = battery.percentage()
        local pct_str = pct_raw and (tostring(math.floor(pct_raw)) .. "%") or "?%"
        table.insert(items, {
            title   = "Batería",
            image   = hsicon(ICON.battery),
            fn      = function() hs.pasteboard.setContents(pct_str) end,
        })
    end

    local bt_devices = bluetooth.devices()
    local bt_title   = #bt_devices > 0
        and ("Bluetooth (" .. #bt_devices .. ")")
        or  "Bluetooth"
    table.insert(items, {
        title = bt_title,
        image = hsicon(ICON.bluetooth),
        menu  = bluetooth.build_submenu(),
    })

    -- ══ Red ═══════════════════════════════════
    table.insert(items, { title = "-" })

    local local_i = network.local_info()
    if local_i and local_i.local_ip then
        local type_icon = ({
            WiFi = hsicon("wifi"),
            Ethernet = hsicon("cable.connector"),
            VPN = hsicon("lock.shield"),
        })[local_i.type or ""] or hsicon(ICON.network)
        table.insert(items, {
            title = local_i.local_ip,
            image = type_icon,
            menu  = network.build_submenu(refresh),
        })
    else
        table.insert(items, {
            title = "Red",
            image = hsicon(ICON.network),
            menu  = network.build_submenu(refresh),
        })
    end

    if vpn.is_active() then
        table.insert(items, {
            title = "VPN",
            image = hsicon(ICON.vpn),
            menu  = vpn.build_submenu(refresh),
        })
    end

    -- ══ Productividad ══════════════════════════════
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Portapapeles",
        image = hsicon(ICON.clipboard),
        menu  = clipboard.build_submenu(refresh),
    })

    local launcher_apps = (cfg.launcher and cfg.launcher.apps) or {}
    if #launcher_apps > 0 then
        table.insert(items, {
            title = "Lanzador",
            image = hsicon(ICON.launcher),
            menu  = launcher.build_submenu(),
        })
    end

    local pom_title = pomodoro.is_active()
        and ("Pomodoro (" .. (pomodoro.time_label() or "") .. ")")
        or  "Pomodoro"
    table.insert(items, {
        title = pom_title,
        image = hsicon(ICON.pomodoro),
        menu  = pomodoro.build_submenu(refresh),
    })

    table.insert(items, {
        title = breaks.is_enabled() and "Descanso" or "Descanso",
        image = hsicon(ICON.breaks),
        menu  = breaks.build_submenu(refresh),
    })

    local pres_active = presentation.is_active()
    table.insert(items, {
        title = pres_active and "Presentación" or "Presentación",
        image = hsicon(pres_active and ICON.checkOn or ICON.present),
        menu  = presentation.build_submenu(refresh),
    })

    -- ══ Historial ══════════════════════════════
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Historial",
        image = hsicon(ICON.history),
        menu  = history.build_submenu(),
    })

    -- ══ Sistema ═══════════════════════════════
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Registro",
        image = hsicon(ICON.log),
        fn    = function()
            local home     = os.getenv("HOME") or "/tmp"
            local log_path = home .. "/.hammerspoon/debug.log"
            hs.execute("open -a Console " .. log_path)
        end,
    })
    table.insert(items, {
        title = "Recargar",
        image = hsicon(ICON.reload),
        fn    = hs.reload,
    })

    return items
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────

function M.build()
    menubar:setTitle(cfg.menu_icon)
end

function M.init()
    menubar:setTitle(cfg.menu_icon)
    menubar:setMenu(build_items)
end

function M.destroy()
    if menubar then menubar:delete() end
end

return M

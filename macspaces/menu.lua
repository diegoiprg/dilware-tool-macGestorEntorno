-- macspaces/menu.lua
-- Menú principal de barra de estado: perfiles, entorno, dispositivos, red.
-- Pomodoro, descanso y presentación están en focus_menu.lua.

local M = {}

local cfg          = require("macspaces.config")
local profiles     = require("macspaces.profiles")
local browsers     = require("macspaces.browsers")
local audio        = require("macspaces.audio")
local battery      = require("macspaces.battery")
local history      = require("macspaces.history")
local clipboard    = require("macspaces.clipboard")
local bluetooth    = require("macspaces.bluetooth")
local network      = require("macspaces.network")
local vpn          = require("macspaces.vpn")
local launcher     = require("macspaces.launcher")
local pomodoro     = require("macspaces.pomodoro")
local breaks       = require("macspaces.breaks")
local utils        = require("macspaces.utils")

local menubar = hs.menubar.new()
local rebuild_timer = nil

local function load_template_icon()
    local path = (os.getenv("HOME") or "") .. "/.hammerspoon/macspaces_icon.png"
    local f = io.open(path, "r")
    if f then
        f:close()
        local img = hs.image.imageFromPath(path)
        if img then img:setSize({ w = 18, h = 18 }); img:template(true); return img end
    end
    return nil
end

local function hotkey_label(key)
    local binding = cfg.hotkeys and cfg.hotkeys[key]
    if not binding then return "" end
    return "    ⌘⌥" .. binding.key
end

local function build_items()
    local function refresh() M.build() end
    local items = {}

    -- ══ Perfiles ══
    table.insert(items, utils.disabled_item("PERFILES"))
    for _, key in ipairs(cfg.profile_order) do
        local profile = cfg.profiles[key]
        if profile then
            local active = profiles.is_active(key)
            local title = (active and "● " or "○ ") .. profile.name
            if active then
                local st = profiles.get_state(key)
                if st and st.started_at then
                    title = title .. "  ·  " .. utils.format_time(os.time() - st.started_at)
                end
            end
            title = title .. hotkey_label(key)

            table.insert(items, {
                title   = title,
                checked = active,
                fn      = function()
                    if active then
                        local st = profiles.get_state(key)
                        if st and st.started_at then history.record_session(key, st.started_at) end
                        profiles.deactivate(key, refresh)
                    else
                        profiles.activate(key, function()
                            if profile.browser then
                                local current = browsers.current()
                                if current ~= profile.browser then browsers.set_default(profile.browser) end
                            end
                            refresh()
                        end)
                    end
                end,
            })
        end
    end
    table.insert(items, { title = "📊  Historial", menu = history.build_submenu() })

    -- ══ Entorno ══
    table.insert(items, { title = "-" })
    table.insert(items, utils.disabled_item("ENTORNO"))
    table.insert(items, { title = "🌐  Navegador", menu = browsers.build_submenu(refresh) })
    table.insert(items, { title = "🔊  Audio", menu = audio.build_submenu() })

    -- ══ Enfoque ══
    table.insert(items, { title = "-" })
    table.insert(items, utils.disabled_item("ENFOQUE"))
    if pomodoro.is_active() then
        table.insert(items, utils.disabled_item("🍅  ●  " .. (pomodoro.menubar_label() or "")))
        table.insert(items, { title = "     ⏭  Saltar fase", fn = function() pomodoro.skip(); refresh() end })
        table.insert(items, { title = "     ⏹  Detener", fn = function() pomodoro.stop(); refresh() end })
    else
        table.insert(items, { title = "🍅  ▶  Iniciar Pomodoro", fn = function() pomodoro.start(); refresh() end })
    end
    if breaks.is_enabled() then
        local idle = breaks.idle_label()
        local time_part = idle and tostring(idle):match("·%s*(.+)$") or ""
        table.insert(items, utils.disabled_item("◎  ●  Cada " .. cfg.breaks.interval_minutes .. " min  ·  " .. time_part))
        table.insert(items, { title = "     ⏹  Desactivar descanso", fn = function() breaks.disable(refresh) end })
    else
        table.insert(items, { title = "◎  ▶  Activar descanso", fn = function() breaks.enable(refresh) end })
    end

    -- ══ Sistema ══
    table.insert(items, { title = "-" })
    table.insert(items, utils.disabled_item("SISTEMA"))
    local red = {}
    for _, i in ipairs(network.build_submenu(refresh)) do table.insert(red, i) end
    if vpn.is_active() then
        table.insert(red, { title = "-" })
        table.insert(red, utils.disabled_item("🔒  VPN activa"))
        for _, i in ipairs(vpn.build_submenu(refresh)) do table.insert(red, i) end
    end
    table.insert(items, { title = "📶  Red", menu = red })
    local bt_count = #bluetooth.devices()
    local bt_label = "📡  Bluetooth"
    if bt_count > 0 then bt_label = bt_label .. "  (" .. bt_count .. ")" end
    table.insert(items, { title = bt_label, menu = bluetooth.build_submenu() })

    -- ══ Herramientas ══
    table.insert(items, { title = "-" })
    table.insert(items, utils.disabled_item("HERRAMIENTAS"))
    table.insert(items, { title = "📋  Portapapeles", menu = clipboard.build_submenu(refresh) })
    local launcher_apps = (cfg.launcher and cfg.launcher.apps) or {}
    if #launcher_apps > 0 then
        table.insert(items, { title = "🚀  Lanzador", menu = launcher.build_submenu() })
    end

    -- ══ macSpaces ══
    table.insert(items, { title = "-" })
    table.insert(items, { title = "🔄  Recargar", fn = hs.reload })
    table.insert(items, {
        title = "Acerca de macSpaces",
        menu  = {
            utils.disabled_item("macSpaces v" .. cfg.VERSION),
            { title = "-" },
            utils.disabled_item("Diego Iparraguirre"),
            { title = "dilware.net", fn = function() hs.urlevent.openURL("https://dilware.net") end },
        },
    })

    return items
end

function M.build()
    hs.timer.doAfter(0, function() menubar:setMenu(build_items()) end)
end

function M.init()
    local icon = load_template_icon()
    if icon then
        menubar:setIcon(icon); menubar:setTitle("")
    else
        menubar:setTitle(cfg.menu_icon)
    end
    menubar:setMenu(build_items())
    rebuild_timer = hs.timer.doEvery(5, function() menubar:setMenu(build_items()) end)
end

function M.destroy()
    if rebuild_timer then rebuild_timer:stop(); rebuild_timer = nil end
    if menubar then menubar:delete() end
end

return M

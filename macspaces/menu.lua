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
local music        = require("macspaces.music")
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
    for _, key in ipairs(cfg.profile_order) do
        local profile = cfg.profiles[key]
        if profile then
            local active = profiles.is_active(key)
            local title = (active and "● " or "○ ") .. profile.name
            if active then
                local st = profiles.get_state(key)
                if st and st.started_at then
                    title = title .. " — " .. utils.format_time(os.time() - st.started_at)
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

    -- ══ Entorno ══
    table.insert(items, { title = "-" })
    local entorno = {}
    table.insert(entorno, utils.disabled_item("🌐  Navegador"))
    for _, i in ipairs(browsers.build_submenu()) do table.insert(entorno, i) end
    table.insert(entorno, { title = "-" })
    table.insert(entorno, utils.disabled_item("🔊  Audio"))
    for _, i in ipairs(audio.build_submenu()) do table.insert(entorno, i) end
    table.insert(entorno, { title = "-" })
    table.insert(entorno, utils.disabled_item("🎵  Música"))
    for _, i in ipairs(music.build_submenu()) do table.insert(entorno, i) end
    table.insert(items, { title = "🎛  Entorno", menu = entorno })

    -- ══ Dispositivos ══
    local disp = {}
    if battery.has_battery() then
        table.insert(disp, utils.disabled_item("🔋  Batería"))
        for _, i in ipairs(battery.build_submenu()) do table.insert(disp, i) end
        table.insert(disp, { title = "-" })
    end
    local bt_count = #bluetooth.devices()
    table.insert(disp, utils.disabled_item("📡  Bluetooth" .. (bt_count > 0 and (" (" .. bt_count .. ")") or "")))
    for _, i in ipairs(bluetooth.build_submenu()) do table.insert(disp, i) end
    table.insert(items, { title = "📱  Dispositivos", menu = disp })

    -- ══ Red ══
    local red = {}
    table.insert(red, utils.disabled_item("📶  Red"))
    for _, i in ipairs(network.build_submenu(refresh)) do table.insert(red, i) end
    if vpn.is_active() then
        table.insert(red, { title = "-" })
        table.insert(red, utils.disabled_item("🔒  VPN"))
        for _, i in ipairs(vpn.build_submenu(refresh)) do table.insert(red, i) end
    end
    table.insert(items, { title = "🌐  Red", menu = red })

    -- ══ Portapapeles ══
    table.insert(items, { title = "📋  Portapapeles", menu = clipboard.build_submenu(refresh) })

    -- ══ Lanzador ══
    local launcher_apps = (cfg.launcher and cfg.launcher.apps) or {}
    if #launcher_apps > 0 then
        table.insert(items, { title = "🚀  Lanzador", menu = launcher.build_submenu() })
    end

    -- ══ Historial ══
    table.insert(items, { title = "-" })
    table.insert(items, { title = "📊  Historial", menu = history.build_submenu() })

    -- ══ Sistema ══
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "📄  Registro",
        fn    = function() hs.execute("open -a Console " .. (os.getenv("HOME") or "/tmp") .. "/.hammerspoon/debug.log") end,
    })
    table.insert(items, { title = "🔄  Recargar", fn = hs.reload })

    -- ══ Versión ══
    table.insert(items, { title = "-" })
    table.insert(items, utils.disabled_item("macSpaces v" .. cfg.VERSION))

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

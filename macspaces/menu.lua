-- macspaces/menu.lua
-- Menú de barra de estado agrupado en submenús semánticos.
-- UX-03: máximo ~8 ítems de primer nivel.
-- UX-04: emojis consistentes (más compatible con Hammerspoon).
-- UX-01: soporte para template image nativa si existe.

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
local utils        = require("macspaces.utils")

local menubar = hs.menubar.new()

-- ─────────────────────────────────────────────
-- UX-01: Ícono nativo de menubar
-- ─────────────────────────────────────────────

local function load_template_icon()
    local home = os.getenv("HOME") or ""
    local path = home .. "/.hammerspoon/macspaces_icon.png"
    local f = io.open(path, "r")
    if f then
        f:close()
        local img = hs.image.imageFromPath(path)
        if img then
            img:setSize({ w = 18, h = 18 })
            img:template(true)
            return img
        end
    end
    return nil
end

-- ─────────────────────────────────────────────
-- UX-06: Actualizar título de menubar (Pomodoro countdown)
-- ─────────────────────────────────────────────

local function update_menubar_title()
    local pom_label = pomodoro.menubar_label()
    if pom_label then
        menubar:setTitle(pom_label)
    else
        menubar:setTitle(cfg.menu_icon)
    end
end

-- ─────────────────────────────────────────────
-- UX-05: Buscar atajo de teclado para un perfil
-- ─────────────────────────────────────────────

local function hotkey_label(key)
    local binding = cfg.hotkeys and cfg.hotkeys[key]
    if not binding then return "" end
    return "    ⌘⌥" .. binding.key
end

-- ─────────────────────────────────────────────
-- Construcción del menú (on-demand)
-- ─────────────────────────────────────────────

local function build_items()
    local function refresh() M.build() end
    local items = {}

    -- ══ Perfiles (primer nivel, siempre visibles) ══
    for _, key in ipairs(cfg.profile_order) do
        local profile = cfg.profiles[key]
        if profile then
            local active = profiles.is_active(key)

            -- UX-02: Indicador textual claro + tiempo activo + atajo visible
            local title = (active and "● " or "○ ") .. profile.name
            if active then
                local st = profiles.get_state(key)
                if st and st.started_at then
                    local elapsed = os.time() - st.started_at
                    title = title .. " — " .. utils.format_time(elapsed)
                end
            end
            -- UX-05: Atajo visible
            title = title .. hotkey_label(key)

            table.insert(items, {
                title   = title,
                checked = active,
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

    -- ══ Entorno (submenú agrupado) ══
    table.insert(items, { title = "-" })

    local entorno_items = {}
    -- Navegador
    table.insert(entorno_items, utils.disabled_item("🌐  Navegador"))
    for _, item in ipairs(browsers.build_submenu()) do table.insert(entorno_items, item) end
    table.insert(entorno_items, { title = "-" })
    -- Audio
    table.insert(entorno_items, utils.disabled_item("🔊  Audio"))
    for _, item in ipairs(audio.build_submenu()) do table.insert(entorno_items, item) end
    table.insert(entorno_items, { title = "-" })
    -- Música (UX-10: nombre en español)
    table.insert(entorno_items, utils.disabled_item("🎵  Música"))
    for _, item in ipairs(music.build_submenu()) do table.insert(entorno_items, item) end

    table.insert(items, { title = "🎛  Entorno", menu = entorno_items })

    -- ══ Dispositivos (submenú agrupado) ══
    local disp_items = {}
    -- Batería (UX-09: ahora con submenú)
    local bat = battery.status_label()
    if bat then
        table.insert(disp_items, utils.disabled_item("🔋  Batería"))
        for _, item in ipairs(battery.build_submenu()) do table.insert(disp_items, item) end
        table.insert(disp_items, { title = "-" })
    end
    -- Bluetooth
    local bt_devices = bluetooth.devices()
    local bt_label = #bt_devices > 0 and ("📡  Bluetooth (" .. #bt_devices .. ")") or "📡  Bluetooth"
    table.insert(disp_items, utils.disabled_item(bt_label))
    for _, item in ipairs(bluetooth.build_submenu()) do table.insert(disp_items, item) end

    table.insert(items, { title = "📱  Dispositivos", menu = disp_items })

    -- ══ Red (submenú agrupado) ══
    local red_items = {}
    table.insert(red_items, utils.disabled_item("📶  Red"))
    for _, item in ipairs(network.build_submenu(refresh)) do table.insert(red_items, item) end
    if vpn.is_active() then
        table.insert(red_items, { title = "-" })
        table.insert(red_items, utils.disabled_item("🔒  VPN"))
        for _, item in ipairs(vpn.build_submenu(refresh)) do table.insert(red_items, item) end
    end

    table.insert(items, { title = "🌐  Red", menu = red_items })

    -- ══ Productividad (submenú agrupado) ══
    local prod_items = {}
    -- Portapapeles
    table.insert(prod_items, utils.disabled_item("📋  Portapapeles"))
    for _, item in ipairs(clipboard.build_submenu(refresh)) do table.insert(prod_items, item) end
    table.insert(prod_items, { title = "-" })
    -- Pomodoro
    local pom_label = pomodoro.is_active()
        and ("🍅  Pomodoro (" .. (pomodoro.time_label() or "") .. ")")
        or  "🍅  Pomodoro"
    table.insert(prod_items, utils.disabled_item(pom_label))
    for _, item in ipairs(pomodoro.build_submenu(refresh)) do table.insert(prod_items, item) end
    table.insert(prod_items, { title = "-" })
    -- Descanso
    table.insert(prod_items, utils.disabled_item("🧘  Descanso activo"))
    for _, item in ipairs(breaks.build_submenu(refresh)) do table.insert(prod_items, item) end
    table.insert(prod_items, { title = "-" })
    -- Presentación
    table.insert(prod_items, utils.disabled_item("🎬  Presentación"))
    for _, item in ipairs(presentation.build_submenu(refresh)) do table.insert(prod_items, item) end
    -- Lanzador
    local launcher_apps = (cfg.launcher and cfg.launcher.apps) or {}
    if #launcher_apps > 0 then
        table.insert(prod_items, { title = "-" })
        table.insert(prod_items, utils.disabled_item("🚀  Lanzador"))
        for _, item in ipairs(launcher.build_submenu()) do table.insert(prod_items, item) end
    end

    table.insert(items, { title = "⚡  Productividad", menu = prod_items })

    -- ══ Historial ══
    table.insert(items, { title = "-" })
    table.insert(items, { title = "📊  Historial", menu = history.build_submenu() })

    -- ══ Sistema ══
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "📄  Registro",
        fn    = function()
            local log_path = (os.getenv("HOME") or "/tmp") .. "/.hammerspoon/debug.log"
            hs.execute("open -a Console " .. log_path)
        end,
    })
    table.insert(items, { title = "🔄  Recargar", fn = hs.reload })

    return items
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────

function M.build()
    update_menubar_title()
end

function M.init()
    -- UX-01: Intentar cargar template image nativa
    local icon = load_template_icon()
    if icon then
        menubar:setIcon(icon)
        menubar:setTitle("")
    else
        menubar:setTitle(cfg.menu_icon)
    end

    menubar:setMenu(build_items)

    -- UX-06: Inyectar callback de actualización de menubar al Pomodoro
    pomodoro.set_menubar_updater(update_menubar_title)
end

function M.destroy()
    if menubar then menubar:delete() end
end

return M

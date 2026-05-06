-- macspaces/focus_menu.lua
-- Menú independiente de enfoque: Pomodoro, descanso activo, presentación.
-- Controla también el overlay flotante persistente.

local M = {}

local cfg          = require("macspaces.config")
local pomodoro     = require("macspaces.pomodoro")
local breaks       = require("macspaces.breaks")
local presentation = require("macspaces.presentation")
local overlay      = require("macspaces.focus_overlay")
local utils        = require("macspaces.utils")

local menubar = hs.menubar.new()
local rebuild_timer = nil

local function load_focus_icon()
    local path = (os.getenv("HOME") or "") .. "/.hammerspoon/macspaces_focus_icon.png"
    local f = io.open(path, "r")
    if f then
        f:close()
        local img = hs.image.imageFromPath(path)
        if img then img:setSize({ w = 18, h = 18 }); img:template(true); return img end
    end
    return nil
end

local focus_icon = nil  -- se carga en init()

local function set_idle_icon()
    if focus_icon then
        menubar:setIcon(focus_icon); menubar:setTitle("")
    else
        menubar:setTitle(cfg.focus_icon)
    end
end

local function update_title()
    set_idle_icon()
end

local function build_items()
    local function refresh()
        M.build()
        overlay.refresh()
    end
    local items = {}

    -- ══ Pomodoro ══
    table.insert(items, utils.disabled_item("POMODORO"))
    if pomodoro.is_active() then
        local label = pomodoro.menubar_label() or ""
        table.insert(items, utils.disabled_item("●  " .. label))
        table.insert(items, { title = "⏭  Saltar fase", fn = function() pomodoro.skip(); refresh() end })
        table.insert(items, { title = "⏹  Detener", fn = function() pomodoro.stop(); refresh() end })
    else
        table.insert(items, utils.disabled_item("○  Inactivo"))
        table.insert(items, { title = "▶  Iniciar", fn = function() pomodoro.start(); refresh() end })
    end

    -- ══ Descanso ══
    table.insert(items, { title = "-" })
    table.insert(items, utils.disabled_item("DESCANSO"))
    if breaks.is_enabled() then
        local idle = breaks.idle_label()
        local time_part = idle and idle:match("·%s*(.+)$") or ""
        table.insert(items, utils.disabled_item("●  Cada " .. cfg.breaks.interval_minutes .. " min  ·  " .. time_part))
        table.insert(items, { title = "⏹  Desactivar", fn = function() breaks.disable(refresh) end })
    else
        table.insert(items, utils.disabled_item("○  Inactivo"))
        table.insert(items, { title = "▶  Activar", fn = function() breaks.enable(refresh) end })
    end

    return items
end

function M.build()
    update_title()
    hs.timer.doAfter(0, function() menubar:setMenu(build_items()) end)
end

function M.init()
    focus_icon = load_focus_icon()
    update_title()
    menubar:setMenu(build_items())

    pomodoro.set_menubar_updater(function()
        update_title()
        overlay.refresh()
    end)

    -- Arrancar descanso activo si estaba habilitado en config
    breaks.init()

    -- Arrancar el overlay (se muestra solo si hay algo activo)
    overlay.start()

    rebuild_timer = hs.timer.doEvery(5, function()
        update_title()
        menubar:setMenu(build_items())
    end)
end

function M.destroy()
    if rebuild_timer then rebuild_timer:stop(); rebuild_timer = nil end
    overlay.stop()
    if menubar then menubar:delete() end
end

return M

-- macspaces/focus_menu.lua
-- Menú independiente de enfoque: Pomodoro, descanso activo, presentación.
-- Ícono dinámico que refleja el estado actual.

local M = {}

local cfg          = require("macspaces.config")
local pomodoro     = require("macspaces.pomodoro")
local breaks       = require("macspaces.breaks")
local presentation = require("macspaces.presentation")
local utils        = require("macspaces.utils")

local menubar = hs.menubar.new()
local rebuild_timer = nil

-- ─────────────────────────────────────────────
-- Título dinámico del ícono
-- ─────────────────────────────────────────────

local function update_title()
    if pomodoro.is_active() then
        menubar:setTitle(pomodoro.menubar_label() or "🍅")
    elseif presentation.is_active() then
        menubar:setTitle("🎬")
    elseif breaks.is_enabled() then
        menubar:setTitle("🧘")
    else
        menubar:setTitle("🧘")
    end
end

-- ─────────────────────────────────────────────
-- Construcción del menú
-- ─────────────────────────────────────────────

local function build_items()
    local function refresh() M.build() end
    local items = {}

    -- ══ Pomodoro ══
    local pom_label = pomodoro.is_active()
        and ("🍅  Pomodoro — " .. (pomodoro.time_label() or ""))
        or  "🍅  Pomodoro"
    table.insert(items, utils.disabled_item(pom_label))
    for _, i in ipairs(pomodoro.build_submenu(refresh)) do table.insert(items, i) end

    -- ══ Descanso activo ══
    table.insert(items, { title = "-" })
    table.insert(items, utils.disabled_item("🧘  Descanso activo"))
    for _, i in ipairs(breaks.build_submenu(refresh)) do table.insert(items, i) end

    -- ══ Presentación ══
    table.insert(items, { title = "-" })
    table.insert(items, utils.disabled_item("🎬  Presentación"))
    for _, i in ipairs(presentation.build_submenu(refresh)) do table.insert(items, i) end

    return items
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────

function M.build()
    update_title()
    hs.timer.doAfter(0, function()
        menubar:setMenu(build_items())
    end)
end

function M.init()
    update_title()
    menubar:setMenu(build_items())

    -- Inyectar actualizador de título al Pomodoro
    pomodoro.set_menubar_updater(update_title)

    rebuild_timer = hs.timer.doEvery(5, function()
        update_title()
        menubar:setMenu(build_items())
    end)
end

function M.destroy()
    if rebuild_timer then rebuild_timer:stop(); rebuild_timer = nil end
    if menubar then menubar:delete() end
end

return M

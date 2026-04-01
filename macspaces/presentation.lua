-- macspaces/presentation.lua
-- Modo presentación: activa DND, oculta el Dock y limpia la pantalla.

local M = {}

local utils = require("macspaces.utils")
local dnd   = require("macspaces.dnd")
local cfg   = require("macspaces.config")

local state = { active = false, dock_was_hidden = false }

local function dock_is_autohide()
    return hs.execute("defaults read com.apple.dock autohide 2>/dev/null"):match("1") ~= nil
end

local function set_dock_autohide(enabled)
    hs.execute("defaults write com.apple.dock autohide -bool " .. (enabled and "true" or "false"))
    hs.execute("killall Dock")
end

local function activate(on_done)
    if state.active then if on_done then on_done() end; return end
    local pcfg = cfg.presentation or {}

    if pcfg.hide_desktop ~= false or pcfg.hide_dock ~= false then
        local btn = hs.dialog.blockAlert(
            "Activar modo presentación",
            "Se reiniciarán el Dock y el Finder. Guarda tu trabajo.",
            "Continuar", "Cancelar"
        )
        if btn ~= "Continuar" then if on_done then on_done() end; return end
    end

    state.dock_was_hidden = dock_is_autohide()
    if pcfg.hide_dock    ~= false then set_dock_autohide(true) end
    if pcfg.enable_dnd   ~= false then dnd.enable() end
    if pcfg.hide_desktop ~= false then
        hs.execute("defaults write com.apple.finder CreateDesktop -bool false")
        hs.execute("killall Finder")
    end

    state.active = true
    utils.notify("macSpaces", "Modo presentación activado")
    if on_done then on_done() end
end

local function deactivate(on_done)
    if not state.active then if on_done then on_done() end; return end
    local pcfg = cfg.presentation or {}

    if pcfg.hide_dock    ~= false then set_dock_autohide(state.dock_was_hidden) end
    if pcfg.enable_dnd   ~= false then dnd.disable() end
    if pcfg.hide_desktop ~= false then
        hs.execute("defaults write com.apple.finder CreateDesktop -bool true")
        hs.execute("killall Finder")
    end

    state.active = false
    utils.notify("macSpaces", "Modo presentación desactivado")
    if on_done then on_done() end
end

function M.is_active() return state.active end

function M.toggle(on_done)
    if state.active then deactivate(on_done) else activate(on_done) end
end

function M.build_submenu(on_update)
    local items = {}
    local pcfg  = cfg.presentation or {}

    table.insert(items, {
        title = state.active and "🎬  Desactivar presentación" or "🎬  Activar presentación",
        fn    = function() M.toggle(on_update) end,
    })
    table.insert(items, { title = "-" })

    if state.active then
        if pcfg.enable_dnd   ~= false then table.insert(items, utils.disabled_item("✓  No Molestar activo")) end
        if pcfg.hide_dock    ~= false then table.insert(items, utils.disabled_item("✓  Dock oculto")) end
        if pcfg.hide_desktop ~= false then table.insert(items, utils.disabled_item("✓  Escritorio limpio")) end
    else
        if pcfg.enable_dnd   ~= false then table.insert(items, utils.disabled_item("○  No Molestar al activar")) end
        if pcfg.hide_dock    ~= false then table.insert(items, utils.disabled_item("○  Ocultar Dock al activar")) end
        if pcfg.hide_desktop ~= false then table.insert(items, utils.disabled_item("○  Limpiar escritorio al activar")) end
    end
    return items
end

return M

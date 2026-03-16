-- macspaces/presentation.lua
-- Modo presentación: activa DND, oculta el Dock y limpia la pantalla.
-- Restaura el estado original al desactivar.

local M = {}

local utils = require("macspaces.utils")
local dnd   = require("macspaces.dnd")
local cfg   = require("macspaces.config")

-- ─────────────────────────────────────────────
-- Estado interno
-- ─────────────────────────────────────────────

local state = {
    active          = false,
    dock_was_hidden = false,   -- estado previo del Dock
}

-- ─────────────────────────────────────────────
-- Helpers del Dock
-- ─────────────────────────────────────────────

local function dock_is_autohide()
    local out = hs.execute("defaults read com.apple.dock autohide 2>/dev/null")
    return out:match("1") ~= nil
end

local function set_dock_autohide(enabled)
    local val = enabled and "true" or "false"
    hs.execute("defaults write com.apple.dock autohide -bool " .. val)
    hs.execute("killall Dock")
end

-- ─────────────────────────────────────────────
-- Activar / desactivar
-- ─────────────────────────────────────────────

local function activate(on_done)
    if state.active then
        if on_done then on_done() end
        return
    end

    local pcfg = cfg.presentation or {}

    -- Advertencia antes de reiniciar Finder/Dock
    if pcfg.hide_desktop ~= false or pcfg.hide_dock ~= false then
        local btn = hs.dialog.blockAlert(
            "Activar modo presentación",
            "Se reiniciarán el Dock y el Finder. Guarda tu trabajo antes de continuar.",
            "Continuar", "Cancelar"
        )
        if btn ~= "Continuar" then
            if on_done then on_done() end
            return
        end
    end

    -- Guardar estado previo del Dock
    state.dock_was_hidden = dock_is_autohide()

    if pcfg.hide_dock ~= false then
        set_dock_autohide(true)
    end

    if pcfg.enable_dnd ~= false then
        dnd.enable()
    end

    if pcfg.hide_desktop ~= false then
        hs.execute("defaults write com.apple.finder CreateDesktop -bool false")
        hs.execute("killall Finder")
    end

    state.active = true
    utils.log("[INFO] presentation: modo presentación activado")
    utils.notify("macSpaces", "Modo presentación activado")

    if on_done then on_done() end
end

local function deactivate(on_done)
    if not state.active then
        if on_done then on_done() end
        return
    end

    local pcfg = cfg.presentation or {}

    -- Restaurar Dock al estado previo
    if pcfg.hide_dock ~= false then
        set_dock_autohide(state.dock_was_hidden)
    end

    -- Desactivar DND
    if pcfg.enable_dnd ~= false then
        dnd.disable()
    end

    -- Restaurar íconos del escritorio
    if pcfg.hide_desktop ~= false then
        hs.execute("defaults write com.apple.finder CreateDesktop -bool true")
        hs.execute("killall Finder")
    end

    state.active = false
    utils.log("[INFO] presentation: modo presentación desactivado")
    utils.notify("macSpaces", "Modo presentación desactivado")

    if on_done then on_done() end
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────

function M.is_active()
    return state.active
end

function M.toggle(on_done)
    if state.active then
        deactivate(on_done)
    else
        activate(on_done)
    end
end

-- Construye el submenú de presentación
function M.build_submenu(on_update)
    local items = {}
    local pcfg  = cfg.presentation or {}

    local label = state.active
        and "🎬  Modo presentación  —  Desactivar"
        or  "🎬  Modo presentación  —  Activar"

    table.insert(items, {
        title = label,
        fn    = function()
            M.toggle(on_update)
        end,
    })

    table.insert(items, { title = "-" })

    -- Cuando está activo: muestra lo que está aplicado en este momento
    -- Cuando está inactivo: muestra lo que se aplicará al activar
    if state.active then
        if pcfg.enable_dnd   ~= false then table.insert(items, { title = "✓  No Molestar activo",        fn = function() end }) end
        if pcfg.hide_dock    ~= false then table.insert(items, { title = "✓  Dock oculto",               fn = function() end }) end
        if pcfg.hide_desktop ~= false then table.insert(items, { title = "✓  Escritorio limpio",         fn = function() end }) end
    else
        if pcfg.enable_dnd   ~= false then table.insert(items, { title = "○  No Molestar al activar",    fn = function() end }) end
        if pcfg.hide_dock    ~= false then table.insert(items, { title = "○  Ocultar Dock al activar",   fn = function() end }) end
        if pcfg.hide_desktop ~= false then table.insert(items, { title = "○  Limpiar escritorio al activar", fn = function() end }) end
    end

    return items
end

return M

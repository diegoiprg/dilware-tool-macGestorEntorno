-- macspaces/profiles.lua
-- Gestión de espacios virtuales y perfiles de aplicaciones.

local M = {}

local cfg   = require("macspaces.config")
local utils = require("macspaces.utils")

-- Estado en tiempo de ejecución (space_id por perfil)
local state = {}
for key, _ in pairs(cfg.profiles) do
    state[key] = { space_id = nil, started_at = nil }
end

-- ─────────────────────────────────────────────
-- Consultas de estado
-- ─────────────────────────────────────────────

function M.is_active(key)
    return state[key] ~= nil and state[key].space_id ~= nil
end

function M.get_state(key)
    return state[key]
end

-- ─────────────────────────────────────────────
-- Activar perfil
-- ─────────────────────────────────────────────

function M.activate(key, on_done)
    local profile = cfg.profiles[key]
    if not profile then
        utils.log("[ERROR] Perfil desconocido: " .. tostring(key))
        return
    end

    if M.is_active(key) then
        utils.notify("macSpaces", profile.name .. " ya está activo")
        return
    end

    local ok, err = pcall(function() hs.spaces.addSpaceToScreen() end)
    if not ok then
        utils.notify("Error", "No se pudo crear espacio: " .. tostring(err))
        utils.log("[ERROR] addSpaceToScreen: " .. tostring(err))
        return
    end

    hs.timer.doAfter(cfg.delay.short, function()
        local uuid = hs.screen.mainScreen():getUUID()
        local all  = hs.spaces.allSpaces()[uuid]

        if not all or #all == 0 then
            utils.notify("Error", "No se encontraron espacios disponibles")
            utils.log("[ERROR] allSpaces vacío para UUID " .. tostring(uuid))
            return
        end

        local new_space = all[#all]
        state[key].space_id  = new_space
        state[key].started_at = os.time()
        hs.spaces.gotoSpace(new_space)
        utils.log("[INFO] Espacio " .. tostring(new_space) .. " creado para " .. profile.name)

        hs.timer.doAfter(cfg.delay.medium, function()
            for i, app_name in ipairs(profile.apps) do
                hs.timer.doAfter(cfg.delay.app_launch * (i - 1), function()
                    hs.application.launchOrFocus(app_name)
                    hs.timer.doAfter(cfg.delay.app_launch, function()
                        local app = hs.application.get(app_name)
                        if not app then
                            utils.log("[WARN] " .. app_name .. " no encontrada tras lanzamiento")
                            return
                        end
                        local win = app:mainWindow()
                        if win then
                            hs.spaces.moveWindowToSpace(win, new_space)
                            utils.log("[OK] " .. app_name .. " movida a espacio " .. tostring(new_space))
                        else
                            utils.log("[WARN] " .. app_name .. " sin ventana principal aún")
                        end
                    end)
                end)
            end

            utils.notify("macSpaces", profile.name .. " activado")
            if on_done then on_done() end
        end)
    end)
end

-- ─────────────────────────────────────────────
-- Desactivar perfil
-- ─────────────────────────────────────────────

function M.deactivate(key, on_done)
    local profile = cfg.profiles[key]
    if not profile or not state[key] or not state[key].space_id then
        utils.notify("macSpaces", "No hay espacio activo para " .. (profile and profile.name or key))
        return
    end

    local target_space = state[key].space_id
    utils.log("[INFO] Cerrando perfil " .. profile.name .. " (espacio " .. tostring(target_space) .. ")")

    for _, app_name in ipairs(profile.apps) do
        local app = hs.application.get(app_name)
        if app then
            app:kill()
            utils.log("[OK] " .. app_name .. " cerrada")
        end
    end

    hs.timer.doAfter(cfg.delay.medium * 2, function()
        local uuid = hs.screen.mainScreen():getUUID()
        local all  = hs.spaces.allSpaces()[uuid]

        if not all or #all == 0 then
            utils.log("[ERROR] allSpaces vacío al desactivar " .. profile.name)
            state[key].space_id   = nil
            state[key].started_at = nil
            if on_done then on_done() end
            return
        end

        local fallback = all[1]
        for _, win in ipairs(hs.window.allWindows()) do
            local win_spaces = hs.spaces.windowSpaces(win:id())
            if win_spaces and utils.table_contains(win_spaces, target_space) then
                local win_app = win:application()
                if win_app then
                    local app_name = win_app:name()
                    if not utils.table_contains(profile.apps, app_name) then
                        hs.spaces.moveWindowToSpace(win, fallback)
                        utils.log("[OK] Ventana de " .. app_name .. " reubicada")
                    end
                end
            end
        end

        hs.spaces.gotoSpace(fallback)

        hs.timer.doAfter(cfg.delay.medium, function()
            local ok, err = pcall(function() hs.spaces.removeSpace(target_space) end)
            state[key].space_id   = nil
            state[key].started_at = nil

            if ok then
                utils.log("[OK] Espacio " .. tostring(target_space) .. " eliminado")
                utils.notify("macSpaces", profile.name .. " cerrado")
            else
                utils.log("[ERROR] removeSpace: " .. tostring(err))
                utils.notify("macSpaces", profile.name .. " cerrado (limpieza manual puede ser necesaria)")
            end

            if on_done then on_done() end
        end)
    end)
end

return M

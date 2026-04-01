-- macspaces/profiles.lua
-- Gestión de espacios virtuales y perfiles de aplicaciones.

local M = {}

local cfg      = require("macspaces.config")
local utils    = require("macspaces.utils")
local browsers = require("macspaces.browsers")

local state = {}
for _, key in ipairs(cfg.profile_order) do
    state[key] = { space_id = nil, started_at = nil, prev_browser = nil }
end

function M.is_active(key)
    return state[key] ~= nil and state[key].space_id ~= nil
end

function M.get_state(key)
    return state[key]
end

function M.activate(key, on_done)
    local profile = cfg.profiles[key]
    if not profile then return end
    if M.is_active(key) then
        utils.notify("macSpaces", profile.name .. " ya está activo"); return
    end

    -- UX-08: Guardar navegador previo
    if profile.browser then state[key].prev_browser = browsers.current() end

    local ok, err = pcall(function() hs.spaces.addSpaceToScreen() end)
    if not ok then
        utils.notify("Error", "No se pudo crear espacio: " .. tostring(err)); return
    end

    hs.timer.doAfter(cfg.delay.short, function()
        local uuid = hs.screen.mainScreen():getUUID()
        local all  = hs.spaces.allSpaces()[uuid]
        if not all or #all == 0 then return end

        local new_space = all[#all]
        state[key].space_id   = new_space
        state[key].started_at = os.time()
        hs.spaces.gotoSpace(new_space)

        hs.timer.doAfter(cfg.delay.medium, function()
            local total_delay = cfg.delay.app_launch * #profile.apps
            for i, app_name in ipairs(profile.apps) do
                hs.timer.doAfter(cfg.delay.app_launch * (i - 1), function()
                    hs.application.launchOrFocus(app_name)
                    hs.timer.doAfter(cfg.delay.app_launch, function()
                        local app = hs.application.get(app_name)
                        if app then
                            local win = app:mainWindow()
                            if win then hs.spaces.moveWindowToSpace(win, new_space) end
                        end
                    end)
                end)
            end
            hs.timer.doAfter(total_delay, function()
                utils.notify("macSpaces", profile.name .. " activado")
                if on_done then on_done() end
            end)
        end)
    end)
end

function M.deactivate(key, on_done)
    local profile = cfg.profiles[key]
    if not profile or not state[key] or not state[key].space_id then return end

    -- UX-07: Confirmación antes de desactivar
    if profile.confirm_deactivate then
        local btn = hs.dialog.blockAlert(
            "Desactivar " .. profile.name,
            "Se cerrarán las apps del perfil. ¿Continuar?",
            "Continuar", "Cancelar"
        )
        if btn ~= "Continuar" then if on_done then on_done() end; return end
    end

    local target_space  = state[key].space_id
    local prev_browser  = state[key].prev_browser

    for _, app_name in ipairs(profile.apps) do
        local app = hs.application.get(app_name)
        if app then app:kill() end
    end

    hs.timer.doAfter(cfg.delay.medium * 2, function()
        local uuid = hs.screen.mainScreen():getUUID()
        local all  = hs.spaces.allSpaces()[uuid]
        if not all or #all == 0 then
            state[key] = { space_id = nil, started_at = nil, prev_browser = nil }
            if on_done then on_done() end; return
        end

        local fallback = all[1]
        for _, win in ipairs(hs.window.allWindows()) do
            local ws = hs.spaces.windowSpaces(win:id())
            if ws and utils.table_contains(ws, target_space) then
                local wa = win:application()
                if wa and not utils.table_contains(profile.apps, wa:name()) then
                    hs.spaces.moveWindowToSpace(win, fallback)
                end
            end
        end

        hs.spaces.gotoSpace(fallback)

        hs.timer.doAfter(cfg.delay.medium, function()
            pcall(function() hs.spaces.removeSpace(target_space) end)

            -- UX-08: Restaurar navegador previo
            if prev_browser and profile.browser then
                local current = browsers.current()
                if current == profile.browser and prev_browser ~= profile.browser then
                    browsers.set_default(prev_browser)
                end
            end

            state[key] = { space_id = nil, started_at = nil, prev_browser = nil }
            utils.notify("macSpaces", profile.name .. " cerrado")
            if on_done then on_done() end
        end)
    end)
end

return M

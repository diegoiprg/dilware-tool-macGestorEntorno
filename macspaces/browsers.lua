-- macspaces/browsers.lua
-- Gestión del navegador predeterminado del sistema.
-- Usa helper Swift nativo (set_browser) via NSWorkspace.setDefaultApplication.
-- Sin diálogos del SO.

local M = {}

local cfg   = require("macspaces.config")
local utils = require("macspaces.utils")

local HELPER = os.getenv("HOME") .. "/.hammerspoon/set_browser"

function M.display_name(bid)
    return cfg.browser_names[bid]
end

function M.current()
    local output = hs.execute("'" .. HELPER .. "' 2>/dev/null")
    if output then
        local bid = output:match("^%s*(.-)%s*$")
        if bid and #bid > 0 then return bid end
    end
    return nil
end

function M.installed()
    local handlers = hs.urlevent.getAllHandlersForScheme("http")
    if not handlers then return {} end
    local result = {}
    for _, bid in ipairs(handlers) do
        if cfg.browser_names[bid] then table.insert(result, bid) end
    end
    table.sort(result, function(a, b)
        return (cfg.browser_names[a] or a) < (cfg.browser_names[b] or b)
    end)
    return result
end

function M.set_default(bundle_id)
    local name = M.display_name(bundle_id) or bundle_id
    -- Intentar hasta 2 veces (la API a veces falla silenciosamente)
    for i = 1, 2 do
        hs.execute("'" .. HELPER .. "' '" .. bundle_id .. "' 2>/dev/null")
        if M.current() == bundle_id then break end
        if i < 2 then hs.timer.usleep(500000) end  -- 0.5s entre reintentos
    end
    utils.notify("macSpaces", "Navegador: " .. name)
    utils.log("[OK] Navegador cambiado a " .. name .. " (" .. bundle_id .. ")")
end

function M.build_submenu(on_update)
    local installed = M.installed()
    local current   = M.current()

    if #installed == 0 then
        return {{ title = "Sin navegadores detectados", disabled = true }}
    end

    local items = {}
    local current_name = M.display_name(current) or current or "Desconocido"
    table.insert(items, { title = "Actual: " .. current_name, disabled = true })
    table.insert(items, { title = "-" })

    for _, bid in ipairs(installed) do
        table.insert(items, {
            title   = M.display_name(bid),
            checked = (bid == current),
            fn      = function()
                if bid ~= M.current() then
                    M.set_default(bid)
                    if on_update then on_update() end
                end
            end,
        })
    end
    return items
end

return M

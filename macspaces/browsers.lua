-- macspaces/browsers.lua
-- Gestión del navegador predeterminado del sistema.

local M = {}

local cfg   = require("macspaces.config")
local utils = require("macspaces.utils")

-- Devuelve el nombre legible de un bundle ID, o nil si no está en la allowlist
function M.display_name(bundle_id)
    return cfg.browser_names[bundle_id]
end

-- Devuelve solo los navegadores de la allowlist que están instalados
function M.installed()
    local handlers = hs.urlevent.getAllHandlersForScheme("http")
    if not handlers then return {} end

    local result = {}
    for _, bundle_id in ipairs(handlers) do
        if cfg.browser_names[bundle_id] then
            table.insert(result, bundle_id)
        end
    end

    -- Ordenar: activo primero, luego alfabético
    local current = hs.urlevent.getDefaultHandler("http")
    table.sort(result, function(a, b)
        if a == current then return true end
        if b == current then return false end
        return (cfg.browser_names[a] or a) < (cfg.browser_names[b] or b)
    end)

    return result
end

-- Devuelve el bundle ID del navegador predeterminado actual
function M.current()
    return hs.urlevent.getDefaultHandler("http")
end

-- Solicita cambio de navegador predeterminado (muestra diálogo del sistema)
function M.set_default(bundle_id)
    local name = M.display_name(bundle_id) or bundle_id
    hs.urlevent.setDefaultHandler("http", bundle_id)
    utils.log("[OK] Solicitud de cambio de navegador a " .. name .. " (" .. bundle_id .. ")")
end

-- Construye el submenú de selección de navegador
function M.build_submenu()
    local installed = M.installed()
    local current   = M.current()

    if #installed == 0 then
        return {{ title = "Sin navegadores detectados", disabled = true }}
    end

    local items = {}
    for _, bundle_id in ipairs(installed) do
        local name   = M.display_name(bundle_id)
        local active = (bundle_id == current)

        table.insert(items, {
            title   = (active and "◉  " or "○  ") .. name,
            checked = active,
            fn      = function()
                if not active then M.set_default(bundle_id) end
            end,
        })
    end

    return items
end

return M

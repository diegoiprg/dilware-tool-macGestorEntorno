-- macspaces/browsers.lua
-- Gestión del navegador predeterminado del sistema.

local M = {}

local cfg   = require("macspaces.config")
local utils = require("macspaces.utils")

local cached_installed = nil
local cached_current    = nil
local cache_valid       = false

function M.display_name(bundle_id)
    return cfg.browser_names[bundle_id]
end

function M.invalidate_cache()
    cached_installed = nil
    cached_current    = nil
    cache_valid       = false
end

function M.installed()
    if cache_valid and cached_installed then
        return cached_installed
    end

    local handlers = hs.urlevent.getAllHandlersForScheme("http")
    if not handlers then return {} end

    local result = {}
    for _, bundle_id in ipairs(handlers) do
        if cfg.browser_names[bundle_id] then
            table.insert(result, bundle_id)
        end
    end

    table.sort(result, function(a, b)
        return (cfg.browser_names[a] or a) < (cfg.browser_names[b] or b)
    end)

    cached_installed = result
    cache_valid       = true
    return result
end

function M.current()
    if cache_valid and cached_current then
        return cached_current
    end

    local ok, result = pcall(function()
        return hs.urlevent.getDefaultHandler("http")
    end)

    if ok then
        cached_current = result
        cache_valid    = true
        return result
    end
    return nil
end

function M.refresh_cache()
    M.invalidate_cache()
    M.installed()
    M.current()
end

function M.set_default(bundle_id)
    local name = M.display_name(bundle_id) or bundle_id
    hs.urlevent.setDefaultHandler("http", bundle_id)
    M.refresh_cache()
    utils.log("[OK] Solicitud de cambio de navegador a " .. name .. " (" .. bundle_id .. ")")
end

function M.build_submenu()
    local installed = M.installed()
    local current   = M.current()

    if #installed == 0 then
        return {{ title = "Sin navegadores detectados", fn = function() end }}
    end

    local items = {}
    for _, bundle_id in ipairs(installed) do
        local name   = M.display_name(bundle_id)
        local active = current and (bundle_id == current)

        table.insert(items, {
            title   = name,
            checked = active,
            fn      = function()
                M.refresh_cache()
                local new_current = M.current()
                if bundle_id ~= new_current then
                    M.set_default(bundle_id)
                end
            end,
        })
    end

    return items
end

return M

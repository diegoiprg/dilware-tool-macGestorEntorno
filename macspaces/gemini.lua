local M = {}

local CACHE_FILE = os.getenv("HOME") .. "/.gemini/usage_cache.json"
local CACHE_MAX_AGE = 6 * 3600 -- 6 horas
local STALE_THRESHOLD = 10 * 60 -- 10 minutos

local MODEL_DISPLAY = {
    ["gemini-2.5-flash"]              = "flash",
    ["gemini-2.5-flash-lite"]         = "flash-lite",
    ["gemini-2.5-pro"]                = "pro",
    ["gemini-3-pro-preview"]          = "3-pro",
    ["gemini-3-flash-preview"]        = "3-flash",
    ["gemini-3.1-pro-preview"]        = "3.1-pro",
    ["gemini-3.1-flash-lite-preview"] = "3.1-flash-lite",
}

local cache_data = nil
local last_load = 0

function M.fetch()
    local now = os.time()
    if cache_data and (now - last_load) < 60 then
        return cache_data
    end

    local f = io.open(CACHE_FILE, "r")
    if not f then
        cache_data = { models = {}, updated_at = 0, source = "none" }
        return cache_data
    end

    local content = f:read("*all")
    f:close()

    local status, data = pcall(hs.json.decode, content)
    if status and data then
        cache_data = data
        cache_data.source = "cache"
        last_load = now
    else
        cache_data = { models = {}, updated_at = 0, source = "none" }
    end

    return cache_data
end

function M.invalidate()
    cache_data = nil
    last_load = 0
end

function M.has_session()
    local data = M.fetch()
    return data.source == "cache" and data.updated_at > 0 and (os.time() - data.updated_at) < CACHE_MAX_AGE
end

function M.color_for(pct)
    if pct >= 85 then
        return { red = 0.85, green = 0.20, blue = 0.15, alpha = 0.85 }
    elseif pct >= 60 then
        return { red = 0.90, green = 0.65, blue = 0.10, alpha = 0.85 }
    else
        return { red = 0.15, green = 0.50, blue = 0.30, alpha = 0.85 }
    end
end

function M.overlay_rows()
    local data = M.fetch()
    if not data.models or #data.models == 0 then return {} end

    local parts = {}
    local worst = 0
    for _, model in ipairs(data.models) do
        local display = MODEL_DISPLAY[model.model_id] or model.model_id:match("([^%-]+)$") or model.model_id
        table.insert(parts, string.format("%s %d%%", display, model.pct))
        if model.pct > worst then worst = model.pct end
    end

    local label = "✦ Gemini  " .. table.concat(parts, " · ")
    return {{ label = label, pct = worst }}
end

function M.build_submenu()
    local data = M.fetch()
    local menu = {}

    if data.source == "none" then
        table.insert(menu, { title = "Sin datos de Gemini CLI" })
        table.insert(menu, { title = "Abrir AI Studio", fn = function() hs.urlevent.openURL("https://aistudio.google.com/") end })
        return menu
    end

    for _, model in ipairs(data.models) do
        table.insert(menu, { title = string.format("%s: %d%%", MODEL_DISPLAY[model.model_id] or model.model_id, model.pct) })
        table.insert(menu, { title = "  Reset: " .. os.date("%Y-%m-%d %H:%M", model.reset) })
    end

    if #menu > 0 then table.insert(menu, { title = "-" }) end

    local diff = os.time() - data.updated_at
    if data.updated_at > 0 and diff > STALE_THRESHOLD then
        table.insert(menu, { title = "⏸ Dato desactualizado — hace " .. math.floor(diff / 60) .. "m" })
        table.insert(menu, { title = "-" })
    end

    table.insert(menu, { title = "Abrir uso detallado", fn = function() hs.urlevent.openURL("https://aistudio.google.com/") end })
    table.insert(menu, { title = "Actualizar", fn = function() M.invalidate() end })

    return menu
end

return M

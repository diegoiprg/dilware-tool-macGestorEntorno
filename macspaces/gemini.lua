local M = {}

local utils = require("macspaces.utils")

local HOME = os.getenv("HOME") or ""
local CACHE_FILE = HOME .. "/.gemini/usage_cache.json"
local USAGE_SCRIPT = HOME .. "/.hammerspoon/macspaces/gemini-usage.sh"
local CACHE_MAX_AGE = 6 * 3600 -- 6 horas
local STALE_THRESHOLD = 10 * 60 -- 10 minutos
local REFRESH_INTERVAL = 5 * 60 -- 5 minutos

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
local refresh_timer = nil
local refresh_task = nil

-- ── Auto-refresh via script externo ────────────────────────────────────────

local function run_usage_script()
    -- No ejecutar si ya hay una tarea corriendo o el script no existe
    if refresh_task and refresh_task:isRunning() then return end
    local f = io.open(USAGE_SCRIPT, "r")
    if not f then return end
    f:close()

    refresh_task = hs.task.new("/bin/bash", function(exitCode)
        if exitCode == 0 then
            M.invalidate()
        end
        refresh_task = nil
    end, { USAGE_SCRIPT })
    refresh_task:start()
end

function M.start()
    run_usage_script()
    if refresh_timer then refresh_timer:stop() end
    refresh_timer = hs.timer.doEvery(REFRESH_INTERVAL, run_usage_script)
end

function M.stop()
    if refresh_timer then refresh_timer:stop(); refresh_timer = nil end
    if refresh_task and refresh_task:isRunning() then refresh_task:terminate() end
    refresh_task = nil
end

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

-- ── Helpers de UI ──────────────────────────────────────────────────────────

local function bar(pct, width)
    width = width or 8
    local filled = math.floor((pct / 100) * width)
    return string.rep("▰", filled) .. string.rep("▱", width - filled)
end

local function fmt_reset(epoch)
    if not epoch or epoch == 0 then return "—" end
    local remaining = epoch - os.time()
    if remaining <= 0 then return "ahora" end
    local d = math.floor(remaining / 86400)
    local h = math.floor((remaining % 86400) / 3600)
    local m = math.floor((remaining % 3600) / 60)
    if d > 0 then return d .. "d " .. h .. "h " .. m .. "m" end
    if h > 0 then return h .. "h " .. m .. "m" end
    return m .. "m"
end

local function freshness_indicator(updated_at)
    if not updated_at or updated_at == 0 then return "  [⏸]" end
    local age = os.time() - updated_at
    if age < STALE_THRESHOLD then return "  [▶]" end
    local m = math.floor(age / 60)
    if m >= 60 then
        return string.format("  [⏸ %dh%dm]", math.floor(m / 60), m % 60)
    end
    return string.format("  [⏸ %dm]", m)
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
    local items = {}

    if data.source == "none" or not data.models or #data.models == 0 then
        table.insert(items, utils.disabled_item("Sin datos de Gemini CLI"))
        table.insert(items, {
            title = "Abrir AI Studio",
            fn    = function() hs.urlevent.openURL("https://aistudio.google.com/") end,
        })
        return items
    end

    for i, model in ipairs(data.models) do
        local display = MODEL_DISPLAY[model.model_id] or model.model_id
        table.insert(items, utils.disabled_item(string.format("%s   %s %d%%", display, bar(model.pct, 10), model.pct)))
        table.insert(items, utils.disabled_item("     Reset en " .. fmt_reset(model.reset)))
        if i < #data.models then
            table.insert(items, { title = "-" })
        end
    end

    local stale = freshness_indicator(data.updated_at)
    if stale:find("⏸") then
        table.insert(items, { title = "-" })
        local age_text = stale:match("%[⏸ (.-)%]") or ""
        table.insert(items, utils.disabled_item("⏸ Dato desactualizado — hace " .. age_text))
    end

    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Abrir uso detallado",
        fn    = function() hs.urlevent.openURL("https://aistudio.google.com/") end,
    })
    table.insert(items, {
        title = "Actualizar",
        fn    = function() M.invalidate(); run_usage_script() end,
    })

    return items
end

return M

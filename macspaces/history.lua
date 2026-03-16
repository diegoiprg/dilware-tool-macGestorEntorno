-- macspaces/history.lua
-- Registro de sesiones por perfil: duración acumulada del día.

local M = {}

local utils = require("macspaces.utils")
local cfg   = require("macspaces.config")

-- Ruta del archivo de historial (JSON simple)
local home         = os.getenv("HOME") or "/tmp"
local history_path = home .. "/.hammerspoon/macspaces_history.json"

-- Caché en memoria: se invalida al registrar una sesión
local cache = { data = nil, date = nil }

-- ─────────────────────────────────────────────
-- Persistencia
-- ─────────────────────────────────────────────

local function load_data()
    local today = os.date("%Y-%m-%d")
    -- Reusar caché si es del mismo día y no fue invalidado
    if cache.data and cache.date == today then
        return cache.data
    end

    local f = io.open(history_path, "r")
    if not f then
        cache.data = {}
        cache.date = today
        return cache.data
    end
    local content = f:read("*a")
    f:close()
    local ok, data = pcall(function() return hs.json.decode(content) end)
    -- Validar que sea una tabla (no array ni nil)
    if not ok or type(data) ~= "table" then data = {} end
    cache.data = data
    cache.date = today
    return cache.data
end

-- Elimina entradas con más de 30 días de antigüedad
local function prune_old_entries(data)
    local cutoff = os.time() - (30 * 24 * 3600)
    for date_key in pairs(data) do
        -- date_key tiene formato "YYYY-MM-DD"
        local y, m, d = date_key:match("^(%d+)-(%d+)-(%d+)$")
        if y then
            local entry_time = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) })
            if entry_time < cutoff then
                data[date_key] = nil
                utils.log("[INFO] history: entrada antigua eliminada (" .. date_key .. ")")
            end
        end
    end
    return data
end

local function save_data(data)
    -- Invalidar caché al escribir
    cache.data = data
    cache.date = os.date("%Y-%m-%d")

    local ok, encoded = pcall(function() return hs.json.encode(data, true) end)
    if not ok then
        utils.log("[ERROR] history: no se pudo serializar datos")
        return
    end
    local f = io.open(history_path, "w")
    if f then
        f:write(encoded)
        f:close()
    end
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────

-- Registra el cierre de una sesión y acumula la duración
function M.record_session(key, started_at)
    if not started_at then return end

    local duration = os.time() - started_at
    if duration < 10 then return end -- ignorar sesiones de menos de 10 segundos

    local today = os.date("%Y-%m-%d")
    local data  = load_data()

    if not data[today] then data[today] = {} end
    if not data[today][key] then data[today][key] = 0 end

    data[today][key] = data[today][key] + duration
    prune_old_entries(data)
    save_data(data)
    utils.log(string.format("[INFO] Sesión %s registrada: %s", key, utils.format_time(duration)))
end

-- Devuelve el tiempo acumulado hoy para un perfil (en segundos)
function M.today_seconds(key)
    local today = os.date("%Y-%m-%d")
    local data  = load_data()
    return (data[today] and data[today][key]) or 0
end

-- Construye el submenú de historial del día
function M.build_submenu()
    local today = os.date("%Y-%m-%d")
    local data  = load_data()
    local items = {}

    table.insert(items, { title = "Hoy — " .. os.date("%d/%m/%Y"), fn = function() end })
    table.insert(items, { title = "-" })

    local has_data = false
    for _, key in ipairs(cfg.profile_order) do
        local profile = cfg.profiles[key]
        local seconds = (data[today] and data[today][key]) or 0
        if seconds > 0 then
            has_data = true
            local label = utils.format_time(seconds)
            table.insert(items, {
                title = profile.name .. ":  " .. label,
                fn    = function() hs.pasteboard.setContents(label) end,
            })
        end
    end

    if not has_data then
        table.insert(items, { title = "Sin sesiones registradas hoy", fn = function() end })
    end

    return items
end

return M

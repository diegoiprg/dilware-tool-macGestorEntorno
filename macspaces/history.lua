-- macspaces/history.lua
-- Registro de sesiones por perfil: duración acumulada del día.

local M = {}

local utils = require("macspaces.utils")
local cfg   = require("macspaces.config")

-- Ruta del archivo de historial (JSON simple)
local history_path = os.getenv("HOME") .. "/.hammerspoon/macspaces_history.json"

-- ─────────────────────────────────────────────
-- Persistencia
-- ─────────────────────────────────────────────

local function load_data()
    local f = io.open(history_path, "r")
    if not f then return {} end
    local content = f:read("*a")
    f:close()
    local ok, data = pcall(function() return hs.json.decode(content) end)
    return (ok and data) or {}
end

local function save_data(data)
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

    table.insert(items, {
        title    = "Hoy — " .. os.date("%d/%m/%Y"),
        disabled = true,
    })
    table.insert(items, { title = "-" })

    local has_data = false
    for _, key in ipairs(cfg.profile_order) do
        local profile  = cfg.profiles[key]
        local seconds  = (data[today] and data[today][key]) or 0
        if seconds > 0 then
            has_data = true
            table.insert(items, {
                title    = profile.name .. ":  " .. utils.format_time(seconds),
                disabled = true,
            })
        end
    end

    if not has_data then
        table.insert(items, { title = "Sin sesiones registradas hoy", disabled = true })
    end

    return items
end

return M

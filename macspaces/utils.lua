-- macspaces/utils.lua
-- Utilidades compartidas: log, notificaciones, helpers.

local M = {}

local logFilePath = os.getenv("HOME") .. "/.hammerspoon/debug.log"

-- Escribe una línea en el archivo de log
function M.log(msg)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local f = io.open(logFilePath, "a")
    if f then
        f:write(string.format("[%s] %s\n", timestamp, msg))
        f:close()
    end
end

-- Limpia el archivo de log
function M.clear_log()
    local f = io.open(logFilePath, "w")
    if f then f:close() end
end

-- Muestra una notificación del sistema y la registra en el log
function M.notify(title, msg)
    hs.notify.new({ title = title, informativeText = msg }):send()
    M.log(string.format("[NOTIFY] %s — %s", title, msg))
end

-- Verifica si un valor existe en una tabla indexada
function M.table_contains(tbl, item)
    for _, v in ipairs(tbl) do
        if v == item then return true end
    end
    return false
end

-- Formatea segundos como MM:SS
function M.format_time(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end

return M

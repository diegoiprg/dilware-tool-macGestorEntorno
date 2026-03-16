-- macspaces/utils.lua
-- Utilidades compartidas: log, notificaciones, helpers.

local M = {}

local home        = os.getenv("HOME") or "/tmp"
local logFilePath = home .. "/.hammerspoon/debug.log"

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

-- Helper compartido: ítem informativo que copia su valor al portapapeles al hacer clic
function M.info_item(label, value)
    return {
        title = label .. value,
        fn    = function() hs.pasteboard.setContents(value) end,
    }
end

-- Formatea segundos como HH:MM:SS (o MM:SS si menos de una hora)
function M.format_time(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    end
    return string.format("%02d:%02d", m, s)
end

return M

-- macspaces/utils.lua
-- Utilidades compartidas: log, notificaciones, helpers.

local M = {}

local home        = os.getenv("HOME") or "/tmp"
local logFilePath = home .. "/.hammerspoon/debug.log"
local MAX_LOG_SIZE = 1024 * 1024  -- 1 MB

-- Establece permisos 0600 en un archivo
local function set_permissions_600(path)
    os.execute("chmod 600 " .. path .. " 2>/dev/null")
end

-- Rota el log si excede el tamaño máximo
local function rotate_log_if_needed()
    local f = io.open(logFilePath, "r")
    if not f then return end
    local size = f:seek("end")
    f:close()
    if size and size > MAX_LOG_SIZE then
        os.remove(logFilePath .. ".old")
        os.rename(logFilePath, logFilePath .. ".old")
        set_permissions_600(logFilePath .. ".old")
    end
end

-- Ofusca últimos octetos de IPs en el mensaje de log
local function mask_ip(msg)
    -- IPv4: reemplaza último octeto con ***
    return msg:gsub("(%d+%.%d+%.%d+%.)%d+", "%1***")
end

-- Escribe una línea en el archivo de log
function M.log(msg)
    rotate_log_if_needed()
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local f = io.open(logFilePath, "a")
    if f then
        f:write(string.format("[%s] %s\n", timestamp, mask_ip(msg)))
        f:close()
        set_permissions_600(logFilePath)
    end
end

-- Limpia el archivo de log
function M.clear_log()
    local f = io.open(logFilePath, "w")
    if f then f:close() end
    set_permissions_600(logFilePath)
end

-- Muestra una notificación del sistema y la registra en el log
function M.notify(title, msg)
    hs.notify.new({ title = title, informativeText = msg }):send()
    M.log(string.format("[NOTIFY] %s — %s", title, msg))
end

-- Notificación llamativa: sonido del sistema + overlay en pantalla + notificación estándar
function M.alert_notify(title, msg, duration)
    M.notify(title, msg)
    hs.alert.show(title .. "\n" .. msg, { textSize = 26 }, hs.screen.mainScreen(), duration or 4)
    local sound = hs.sound.getByName("Glass")
    if sound then sound:play() end
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

-- Helper: ítem puramente informativo (no accionable)
function M.disabled_item(label)
    return { title = label, disabled = true }
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

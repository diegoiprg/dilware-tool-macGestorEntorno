-- macspaces/battery.lua
-- Información de batería. Solo activo si el dispositivo tiene batería.

local M = {}

-- Devuelve true si el dispositivo tiene batería (MacBook, no Mac mini/iMac)
function M.has_battery()
    local battery = hs.battery
    if not battery then return false end
    local pct = battery.percentage()
    return pct ~= nil and pct > 0
end

-- Devuelve el porcentaje actual de batería
function M.percentage()
    return hs.battery.percentage()
end

-- Devuelve true si está cargando
function M.is_charging()
    return hs.battery.isCharging()
end

-- Devuelve true si está conectado a corriente (cargando o carga completa)
function M.is_plugged()
    return hs.battery.powerSource() == "AC Power"
end

-- Devuelve un string de estado para mostrar en el menú
-- Retorna nil si no hay batería (Mac mini, iMac, etc.)
function M.status_label()
    if not M.has_battery() then return nil end

    local pct = math.floor(M.percentage())
    local icon

    if M.is_plugged() then
        icon = "⚡"
    elseif pct >= 80 then
        icon = "🔋"
    elseif pct >= 40 then
        icon = "🔋"
    elseif pct >= 20 then
        icon = "🪫"
    else
        icon = "🪫"
    end

    local state = M.is_plugged() and " (cargando)" or ""
    return string.format("%s %d%%%s", icon, pct, state)
end

return M

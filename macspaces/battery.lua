-- macspaces/battery.lua
-- Información de batería. Solo activo si el dispositivo tiene batería.

local M = {}

-- Devuelve true si el dispositivo tiene batería (MacBook, no Mac mini/iMac)
-- Usa hs.battery.cycles() como indicador más confiable que el porcentaje
function M.has_battery()
    if not hs.battery then return false end
    -- cycles() devuelve nil en dispositivos sin batería (Mac mini, iMac, Mac Pro)
    local cycles = hs.battery.cycles()
    if cycles ~= nil and cycles > 0 then return true end
    -- Fallback: powerSource devuelve "Battery Power" solo si hay batería en uso
    local source = hs.battery.powerSource()
    return source == "Battery Power"
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
    local alert = ""

    if M.is_plugged() then
        icon = "⚡"
    elseif pct >= 80 then
        icon = "🔋"
    elseif pct >= 40 then
        icon = "🔋"
    elseif pct >= 20 then
        icon  = "🪫"
        alert = "  — Batería baja"
    else
        icon  = "🪫"
        alert = "  — Batería crítica"
    end

    local state = M.is_plugged() and " (cargando)" or ""
    return string.format("%s %d%%%s%s", icon, pct, state, alert)
end

return M

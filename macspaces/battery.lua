-- macspaces/battery.lua
-- Información de batería con submenú detallado.

local M = {}

local utils = require("macspaces.utils")

local cached_has_battery = nil

function M.has_battery()
    if cached_has_battery ~= nil then return cached_has_battery end
    if not hs.battery then cached_has_battery = false; return false end
    local cycles = hs.battery.cycles()
    if cycles ~= nil and cycles > 0 then cached_has_battery = true; return true end
    cached_has_battery = (hs.battery.powerSource() == "Battery Power")
    return cached_has_battery
end

function M.percentage()  return hs.battery.percentage() end
function M.is_charging() return hs.battery.isCharging() end
function M.is_plugged()  return hs.battery.powerSource() == "AC Power" end

function M.status_label()
    if not M.has_battery() then return nil end
    local pct = math.floor(M.percentage())
    local icon, alert = "🔋", ""
    if M.is_plugged() then icon = "⚡"
    elseif pct < 20 then icon = "🪫"; alert = "  — Batería crítica"
    elseif pct < 40 then icon = "🪫"; alert = "  — Batería baja"
    end
    local state = M.is_plugged() and " (cargando)" or ""
    return string.format("%s %d%%%s%s", icon, pct, state, alert)
end

function M.build_submenu()
    if not M.has_battery() then
        return { utils.disabled_item("Sin batería detectada") }
    end
    local items = {}
    local pct = math.floor(M.percentage())
    local pct_str = tostring(pct) .. "%"

    table.insert(items, { title = "🔋  " .. pct_str, fn = function() hs.pasteboard.setContents(pct_str) end })

    local sl = M.is_charging() and "⚡ Cargando" or (M.is_plugged() and "⚡ Conectado" or "🔌 Usando batería")
    table.insert(items, utils.disabled_item(sl))

    local cycles = hs.battery.cycles()
    if cycles then table.insert(items, utils.info_item("Ciclos: ", tostring(cycles))) end

    local tr = hs.battery.timeRemaining()
    if tr and tr > 0 then
        table.insert(items, utils.disabled_item(string.format("⏱  %d:%02d restante", math.floor(tr/60), tr%60)))
    end
    return items
end

return M

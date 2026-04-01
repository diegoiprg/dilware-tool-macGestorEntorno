-- macspaces/breaks.lua
-- Recordatorios de descanso activo para salud postural y visual.
-- Incluye datos educativos basados en estándares (OSHA, AAO, Mayo Clinic).

local M = {}

local cfg   = require("macspaces.config")
local utils = require("macspaces.utils")

local state = {
    enabled       = cfg.breaks.enabled,
    timer         = nil,
    last_break_at = os.time(),
}

-- Mensaje + dato educativo (rotan independientemente para más variedad)
local BREAK_MESSAGES = {
    "Levántate y camina un par de minutos.",
    "Estira el cuello y los hombros.",
    "Descansa la vista: mira algo lejano por 20 segundos.",
    "Toma agua y mueve las muñecas.",
    "Respira profundo y estira la espalda.",
    "Parpadea varias veces y relaja los ojos.",
}

local HEALTH_TIPS = {
    "Regla 20-20-20: cada 20 min, mira a 6m por 20s (AAO).",
    "Estar sentado más de 1h seguida aumenta el riesgo lumbar (OSHA).",
    "Pausas activas cada 45-60 min reducen fatiga muscular (Mayo Clinic).",
    "Parpadeas un 66% menos frente a pantallas, causando ojo seco (AAO).",
    "Microdescansos de 30s cada 20 min mejoran la productividad (Cornell).",
    "Caminar 2 min cada hora reduce el riesgo cardiovascular (AHA).",
}

local msg_index = 0
local tip_index = 0

local function next_message()
    msg_index = (msg_index % #BREAK_MESSAGES) + 1
    tip_index = (tip_index % #HEALTH_TIPS) + 1
    return BREAK_MESSAGES[msg_index] .. "\n" .. HEALTH_TIPS[tip_index]
end

local function stop_timer()
    if state.timer then state.timer:stop(); state.timer = nil end
end

local function start_timer()
    stop_timer()
    state.last_break_at = os.time()
    state.timer = hs.timer.doEvery(cfg.breaks.interval_minutes * 60, function()
        utils.notify("Descanso activo", next_message())
        state.last_break_at = os.time()
    end)
end

function M.seconds_since_break()
    return os.time() - state.last_break_at
end

function M.idle_label()
    if not state.enabled then return nil end
    local remaining = (cfg.breaks.interval_minutes * 60) - M.seconds_since_break()
    if remaining < 0 then remaining = 0 end
    return "☁️ Descanso · " .. utils.format_time(remaining)
end

function M.is_enabled() return state.enabled end

function M.init()
    if state.enabled then start_timer() end
end

function M.enable(on_update)
    state.enabled = true; start_timer()
    utils.notify("macSpaces", "Descanso activo — cada " .. cfg.breaks.interval_minutes .. " min")
    if on_update then on_update() end
end

function M.disable(on_update)
    state.enabled = false; stop_timer()
    if on_update then on_update() end
end

function M.toggle(on_update)
    if state.enabled then M.disable(on_update) else M.enable(on_update) end
end

function M.build_submenu(on_update)
    local items = {}
    local status = state.enabled
        and ("◉  Activo — cada " .. cfg.breaks.interval_minutes .. " min")
        or  "○  Inactivo"
    table.insert(items, utils.disabled_item(status))

    local idle = M.idle_label()
    if idle then table.insert(items, utils.disabled_item(idle)) end

    table.insert(items, { title = "-" })

    if state.enabled then
        table.insert(items, { title = "Desactivar", fn = function() M.disable(on_update) end })
    else
        table.insert(items, { title = "Activar", fn = function() M.enable(on_update) end })
    end

    table.insert(items, { title = "-" })
    for _, mins in ipairs({ 30, 45, 50, 60, 90 }) do
        local current = (cfg.breaks.interval_minutes == mins)
        table.insert(items, {
            title   = (current and "◉  " or "○  ") .. mins .. " minutos",
            checked = current,
            fn      = function()
                cfg.breaks.interval_minutes = mins
                if state.enabled then start_timer(); utils.notify("Descanso activo", "Intervalo: " .. mins .. " min") end
                if on_update then on_update() end
            end,
        })
    end
    return items
end

return M

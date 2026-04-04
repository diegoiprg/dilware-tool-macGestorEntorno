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

-- Mensajes con instrucciones paso a paso + dato educativo de respaldo
local BREAK_MESSAGES = {
    -- Vista
    "Regla 20-20-20 — Ahora:\n1. Busca un punto a 6 metros de distancia.\n2. Enfócate en él durante 20 segundos.\n3. Luego parpadea 10 veces despacio.\nReduces el ojo seco causado por pantallas (AAO).",
    -- Cuello y hombros
    "Estiramiento cervical — Ahora:\n1. Inclina la cabeza hacia el hombro derecho 10s.\n2. Repite al lado izquierdo 10s.\n3. Gira lentamente el cuello en círculos 3 veces.\nAlivia tensión acumulada en trapecio y cervicales (OSHA).",
    -- Muñecas y manos
    "Muñecas y manos — Ahora:\n1. Cierra los puños y ábrelos 10 veces.\n2. Gira las muñecas 5 veces en cada sentido.\n3. Estira los dedos hacia atrás suavemente 10s.\nPreviene el síndrome del túnel carpiano (Mayo Clinic).",
    -- Levantarse
    "Levántate — Ahora:\n1. Ponte de pie lentamente.\n2. Camina al menos 2 minutos (cocina, ventana, lo que sea).\n3. Antes de sentarte, estira los isquiotibiales 15s.\nCaminar 2 min/hora reduce riesgo cardiovascular en 33% (AHA).",
    -- Espalda baja
    "Espalda lumbar — Ahora:\n1. Siéntate al borde de la silla con pies planos en el suelo.\n2. Inclínate suave hacia adelante, deja caer los brazos 15s.\n3. Vuelve erguido y aprieta el abdomen 5s. Repite 3 veces.\nSentarse >1h continua aumenta presión discal L4-L5 (OSHA).",
    -- Respiración
    "Respiración 4-7-8 — Ahora:\n1. Inhala por la nariz contando 4 segundos.\n2. Mantén el aire contando 7 segundos.\n3. Exhala por la boca contando 8 segundos. Repite 3 ciclos.\nActiva el sistema parasimpático y reduce el cortisol (Harvard Med).",
    -- Hidratación
    "Hidratación — Ahora:\n1. Levántate y ve por un vaso de agua (250ml mínimo).\n2. Mientras caminas, estira los brazos por encima de la cabeza.\n3. Bebe el agua de pie antes de volver.\nLa deshidratación leve (1-2%) reduce concentración un 20% (EFSA).",
}

local msg_index = 0

local function next_message()
    msg_index = (msg_index % #BREAK_MESSAGES) + 1
    return BREAK_MESSAGES[msg_index]
end

local function stop_timer()
    if state.timer then state.timer:stop(); state.timer = nil end
end

local function schedule_next()
    stop_timer()
    state.last_break_at = os.time()
    local interval = cfg.breaks.interval_minutes * 60
    local display  = cfg.breaks.break_display_seconds or 15
    state.timer = hs.timer.doAfter(interval, function()
        utils.alert_notify("Descanso activo", next_message(), display)
        -- El siguiente ciclo inicia DESPUÉS de que termine la visualización
        hs.timer.doAfter(display, function()
            if state.enabled then schedule_next() end
        end)
    end)
end

function M.seconds_since_break()
    return os.time() - state.last_break_at
end

function M.idle_label()
    if not state.enabled then return nil end
    local remaining = (cfg.breaks.interval_minutes * 60) - M.seconds_since_break()
    if remaining < 0 then remaining = 0 end
    return "◎ Descanso · " .. utils.format_time(remaining)
end

function M.is_enabled() return state.enabled end

function M.init()
    if state.enabled then schedule_next() end
end

function M.enable(on_update)
    state.enabled = true; schedule_next()
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
                if state.enabled then schedule_next(); utils.notify("Descanso activo", "Intervalo: " .. mins .. " min") end
                if on_update then on_update() end
            end,
        })
    end
    return items
end

return M

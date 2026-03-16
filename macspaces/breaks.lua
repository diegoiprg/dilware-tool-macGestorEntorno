-- macspaces/breaks.lua
-- Recordatorios de descanso activo para salud postural y visual.

local M = {}

local cfg   = require("macspaces.config")
local utils = require("macspaces.utils")

-- ─────────────────────────────────────────────
-- Estado interno
-- ─────────────────────────────────────────────
local state = {
    enabled    = cfg.breaks.enabled,
    timer      = nil,
}

-- Mensajes de descanso rotativos
local BREAK_MESSAGES = {
    "Levántate y camina un par de minutos.",
    "Estira el cuello y los hombros.",
    "Descansa la vista: mira algo lejano por 20 segundos.",
    "Toma agua y mueve las muñecas.",
    "Respira profundo y estira la espalda.",
    "Parpadea varias veces y relaja los ojos.",
}

local message_index = 0

local function next_message()
    message_index = (message_index % #BREAK_MESSAGES) + 1
    return BREAK_MESSAGES[message_index]
end

-- ─────────────────────────────────────────────
-- Control del temporizador
-- ─────────────────────────────────────────────

local function stop_timer()
    if state.timer then
        state.timer:stop()
        state.timer = nil
    end
end

local function start_timer()
    stop_timer()
    local interval = cfg.breaks.interval_minutes * 60
    state.timer = hs.timer.doEvery(interval, function()
        utils.notify("Descanso activo", next_message())
        utils.log("[INFO] Recordatorio de descanso enviado")
    end)
    utils.log(string.format("[INFO] Descanso activo: recordatorio cada %d min", cfg.breaks.interval_minutes))
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────

function M.is_enabled()
    return state.enabled
end

function M.enable(on_update)
    state.enabled   = true
    state.on_update = on_update
    start_timer()
    utils.notify("macSpaces", "Descanso activo activado — cada " .. cfg.breaks.interval_minutes .. " min")
    if on_update then on_update() end
end

function M.disable(on_update)
    state.enabled = false
    stop_timer()
    utils.log("[INFO] Descanso activo desactivado")
    if on_update then on_update() end
end

function M.toggle(on_update)
    if state.enabled then
        M.disable(on_update)
    else
        M.enable(on_update)
    end
end

-- Construye el submenú de descanso activo
function M.build_submenu(on_update)
    local items = {}

    local status = state.enabled
        and ("◉  Activo — cada " .. cfg.breaks.interval_minutes .. " min")
        or  "○  Inactivo"

    table.insert(items, { title = status, fn = function() end })
    table.insert(items, { title = "-" })

    if state.enabled then
        table.insert(items, {
            title = "Desactivar",
            fn    = function() M.disable(on_update) end,
        })
    else
        table.insert(items, {
            title = "Activar",
            fn    = function() M.enable(on_update) end,
        })
    end

    -- Opciones de intervalo
    table.insert(items, { title = "-" })

    for _, mins in ipairs({ 30, 45, 50, 60, 90 }) do
        local current = (cfg.breaks.interval_minutes == mins)
        table.insert(items, {
            title   = (current and "◉  " or "○  ") .. mins .. " minutos",
            checked = current,
            fn      = function()
                cfg.breaks.interval_minutes = mins
                if state.enabled then
                    start_timer()
                    utils.notify("Descanso activo", "Intervalo actualizado a " .. mins .. " min")
                end
                if on_update then on_update() end
            end,
        })
    end

    return items
end

return M

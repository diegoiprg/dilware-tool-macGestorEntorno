-- macspaces/pomodoro.lua
-- Temporizador Pomodoro con DND integrado y ciclos configurables.

local M = {}

local cfg   = require("macspaces.config")
local utils = require("macspaces.utils")
local dnd   = require("macspaces.dnd")

-- ─────────────────────────────────────────────
-- Estado interno
-- ─────────────────────────────────────────────
local state = {
    active        = false,
    phase         = nil,   -- "work" | "short_break" | "long_break"
    cycle         = 0,     -- ciclos de trabajo completados
    seconds_left  = 0,
    timer         = nil,
    on_update     = nil,   -- callback para refrescar el menú
}

-- ─────────────────────────────────────────────
-- Helpers internos
-- ─────────────────────────────────────────────

local function stop_timer()
    if state.timer then
        state.timer:stop()
        state.timer = nil
    end
end

local function notify_phase(phase)
    local messages = {
        work        = "¡A trabajar! " .. cfg.pomodoro.work_minutes .. " min de concentración.",
        short_break = "Pausa corta — " .. cfg.pomodoro.short_break .. " min. Estírate.",
        long_break  = "Pausa larga — " .. cfg.pomodoro.long_break .. " min. Descansa bien.",
    }
    utils.notify("Pomodoro", messages[phase] or phase)
end

local function start_phase(phase)
    state.phase = phase

    local durations = {
        work        = cfg.pomodoro.work_minutes * 60,
        short_break = cfg.pomodoro.short_break  * 60,
        long_break  = cfg.pomodoro.long_break   * 60,
    }

    state.seconds_left = durations[phase] or (cfg.pomodoro.work_minutes * 60)
    notify_phase(phase)

    -- DND: activar en trabajo, desactivar en pausas
    if cfg.pomodoro.enable_dnd then
        if phase == "work" then
            dnd.enable()
        else
            dnd.disable()
        end
    end

    stop_timer()
    state.timer = hs.timer.doEvery(1, function()
        state.seconds_left = state.seconds_left - 1

        if state.on_update then state.on_update() end

        if state.seconds_left <= 0 then
            stop_timer()

            if phase == "work" then
                state.cycle = state.cycle + 1
                utils.log(string.format("[INFO] Pomodoro: ciclo %d completado", state.cycle))

                if state.cycle % cfg.pomodoro.cycles_before_long_break == 0 then
                    start_phase("long_break")
                else
                    start_phase("short_break")
                end
            else
                -- Pausa terminada: iniciar nuevo ciclo de trabajo
                start_phase("work")
            end
        end
    end)
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────

function M.is_active()
    return state.active
end

function M.current_phase()
    return state.phase
end

function M.cycles_completed()
    return state.cycle
end

function M.time_label()
    if not state.active then return nil end
    local phase_labels = {
        work        = "🍅",
        short_break = "☕",
        long_break  = "🛋",
    }
    local icon = phase_labels[state.phase] or "⏱"
    return icon .. " " .. utils.format_time(state.seconds_left)
end

-- Inicia el Pomodoro
function M.start(on_update)
    if state.active then return end
    state.active   = true
    state.cycle    = 0
    state.on_update = on_update
    utils.log("[INFO] Pomodoro iniciado")
    start_phase("work")
end

-- Detiene el Pomodoro completamente
function M.stop()
    if not state.active then return end
    stop_timer()
    state.active       = false
    state.phase        = nil
    state.seconds_left = 0
    state.cycle        = 0
    state.on_update    = nil

    if cfg.pomodoro.enable_dnd then dnd.disable() end
    utils.log("[INFO] Pomodoro detenido")
    utils.notify("Pomodoro", "Temporizador detenido. " .. state.cycle .. " ciclos completados.")
end

-- Salta a la siguiente fase manualmente
function M.skip()
    if not state.active then return end
    stop_timer()
    if state.phase == "work" then
        state.cycle = state.cycle + 1
        if state.cycle % cfg.pomodoro.cycles_before_long_break == 0 then
            start_phase("long_break")
        else
            start_phase("short_break")
        end
    else
        start_phase("work")
    end
end

-- Construye el submenú del Pomodoro
function M.build_submenu(on_update)
    local items = {}

    if state.active then
        -- Estado actual
        local phase_names = {
            work        = "Trabajando",
            short_break = "Pausa corta",
            long_break  = "Pausa larga",
        }
        table.insert(items, {
            title    = (phase_names[state.phase] or "Activo") .. " — " .. utils.format_time(state.seconds_left),
            disabled = true,
        })
        table.insert(items, {
            title    = "Ciclos completados: " .. state.cycle,
            disabled = true,
        })
        table.insert(items, { title = "-" })
        table.insert(items, {
            title = "⏭  Saltar fase",
            fn    = function() M.skip(); if on_update then on_update() end end,
        })
        table.insert(items, {
            title = "⏹  Detener",
            fn    = function() M.stop(); if on_update then on_update() end end,
        })
    else
        table.insert(items, {
            title    = string.format("Ciclo: %d min trabajo / %d min pausa",
                cfg.pomodoro.work_minutes, cfg.pomodoro.short_break),
            disabled = true,
        })
        table.insert(items, { title = "-" })
        table.insert(items, {
            title = "▶  Iniciar Pomodoro",
            fn    = function() M.start(on_update); if on_update then on_update() end end,
        })
    end

    return items
end

return M

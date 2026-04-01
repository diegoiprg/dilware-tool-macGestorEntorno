-- macspaces/pomodoro.lua
-- Temporizador Pomodoro con DND integrado, ciclos configurables y countdown en menubar.

local M = {}

local cfg   = require("macspaces.config")
local utils = require("macspaces.utils")
local dnd   = require("macspaces.dnd")

local state = {
    active        = false,
    phase         = nil,
    cycle         = 0,
    seconds_left  = 0,
    timer         = nil,
}

-- Callback para actualizar la menubar (se inyecta desde menu.lua)
local menubar_update_fn = nil

function M.set_menubar_updater(fn)
    menubar_update_fn = fn
end

local function update_menubar()
    if menubar_update_fn then menubar_update_fn() end
end

local function stop_timer()
    if state.timer then state.timer:stop(); state.timer = nil end
end

local function notify_phase(phase)
    local msgs = {
        work        = "A trabajar — " .. cfg.pomodoro.work_minutes .. " min.",
        short_break = "Pausa corta — " .. cfg.pomodoro.short_break .. " min.",
        long_break  = "Pausa larga — " .. cfg.pomodoro.long_break .. " min.",
    }
    utils.notify("Pomodoro", msgs[phase] or phase)
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

    if cfg.pomodoro.enable_dnd then
        if phase == "work" then dnd.enable() else dnd.disable() end
    end

    stop_timer()
    local tick = 0
    state.timer = hs.timer.doEvery(1, function()
        state.seconds_left = state.seconds_left - 1
        tick = tick + 1

        -- UX-06: Actualizar menubar cada 60s (no cada segundo)
        if tick % 60 == 0 then update_menubar() end

        if state.seconds_left <= 0 then
            stop_timer()
            if phase == "work" then
                state.cycle = state.cycle + 1
                if state.cycle % cfg.pomodoro.cycles_before_long_break == 0 then
                    start_phase("long_break")
                else
                    start_phase("short_break")
                end
            else
                start_phase("work")
            end
            update_menubar()
        end
    end)
    update_menubar()
end

function M.is_active()       return state.active end
function M.current_phase()   return state.phase end
function M.cycles_completed() return state.cycle end

function M.time_label()
    if not state.active then return nil end
    local icons = { work = "🍅", short_break = "☕", long_break = "🌿" }
    return (icons[state.phase] or "⏱") .. " " .. utils.format_time(state.seconds_left)
end

-- UX-06: Etiqueta corta para la menubar
function M.menubar_label()
    if not state.active then return nil end
    local m = math.ceil(state.seconds_left / 60)
    local icons = { work = "🍅", short_break = "☕", long_break = "🌿" }
    return (icons[state.phase] or "⏱") .. " " .. m .. "m"
end

function M.start()
    if state.active then return end
    state.active = true; state.cycle = 0
    start_phase("work")
end

function M.stop()
    if not state.active then return end
    local completed = state.cycle
    stop_timer()
    state.active = false; state.phase = nil; state.seconds_left = 0; state.cycle = 0
    if cfg.pomodoro.enable_dnd then dnd.disable() end
    local s = completed == 1 and "1 ciclo" or (completed .. " ciclos")
    utils.notify("Pomodoro", "Detenido. " .. s .. " completados.")
    update_menubar()
end

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

function M.build_submenu(on_update)
    local items = {}
    if state.active then
        local names = { work = "Trabajando", short_break = "Pausa corta", long_break = "Pausa larga" }
        table.insert(items, utils.disabled_item((names[state.phase] or "Activo") .. " — " .. utils.format_time(state.seconds_left)))
        table.insert(items, utils.disabled_item("Ciclos completados: " .. state.cycle))
        table.insert(items, { title = "-" })
        table.insert(items, { title = "⏭  Saltar fase", fn = function() M.skip(); if on_update then on_update() end end })
        table.insert(items, { title = "⏹  Detener",     fn = function() M.stop(); if on_update then on_update() end end })
    else
        table.insert(items, utils.disabled_item(string.format("Ciclo: %d min / %d min pausa", cfg.pomodoro.work_minutes, cfg.pomodoro.short_break)))
        table.insert(items, { title = "-" })
        table.insert(items, { title = "▶  Iniciar Pomodoro", fn = function() M.start(); if on_update then on_update() end end })
    end
    return items
end

return M

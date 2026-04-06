-- macspaces/focus_overlay.lua
-- Banner flotante unificado con filas coloreadas por estado.
-- Arrastrable para reposicionar durante la sesión.

local M = {}

local pomodoro     = require("macspaces.pomodoro")
local breaks       = require("macspaces.breaks")
local presentation = require("macspaces.presentation")

local canvas   = nil
local timer    = nil
local drag_tap = nil

-- Posición guardada durante la sesión (nil = posición por defecto)
local saved_pos = nil
local drag = { active = false, ox = 0, oy = 0 }

-- ── Constantes visuales ──

local OUTER_PAD  = 5
local ROW_PAD_X  = 10
local ROW_PAD_Y  = 6
local ROW_GAP    = 4
local MARGIN     = 8
local TOP_OFFSET = 30
local FONT_SIZE  = 14
local BG_ALPHA   = 0.80
local CORNER_R   = 8
local ROW_R      = 5

local BG_COLORS = {
    work         = { red = 0.75, green = 0.15, blue = 0.10, alpha = BG_ALPHA },
    short_break  = { red = 0.15, green = 0.55, blue = 0.25, alpha = BG_ALPHA },
    long_break   = { red = 0.15, green = 0.55, blue = 0.25, alpha = BG_ALPHA },
    breaks       = { red = 0.20, green = 0.40, blue = 0.65, alpha = BG_ALPHA },
    breaks_active = { red = 0.15, green = 0.55, blue = 0.25, alpha = BG_ALPHA },
    presentation = { red = 0.45, green = 0.20, blue = 0.60, alpha = BG_ALPHA },
}

local TEXT_STYLE = {
    font  = { name = ".AppleSystemUIFont", size = FONT_SIZE },
    color = { white = 1, alpha = 1 },
}

-- ── Helpers ──

local function measure_text(styled)
    local ok, size = pcall(hs.drawing.getTextDrawingSize, styled)
    if ok and size then return size end
    local len = utf8.len(tostring(styled)) or 12
    return { w = len * (FONT_SIZE * 0.65), h = FONT_SIZE + 6 }
end

local function destroy_canvas()
    if canvas then canvas:delete(); canvas = nil end
end

local function stop_drag_tap()
    if drag_tap then drag_tap:stop(); drag_tap = nil end
    drag.active = false
end

-- ── Entradas activas ──

local function get_entries()
    local entries = {}
    if pomodoro.is_active() then
        table.insert(entries, {
            label = pomodoro.time_label(),
            color = BG_COLORS[pomodoro.current_phase()] or BG_COLORS.work,
        })
    end
    if presentation.is_active() then
        table.insert(entries, { label = "🎬 Presentación", color = BG_COLORS.presentation })
    end
    local idle = breaks.idle_label()
    if idle then
        local color = breaks.is_on_break() and BG_COLORS.breaks_active or BG_COLORS.breaks
        table.insert(entries, { label = idle, color = color })
    end
    return entries
end

-- ── Renderizado ──

local function render(entries)
    destroy_canvas()

    -- Medir todas las filas
    local rows = {}
    local max_w = 0
    for _, entry in ipairs(entries) do
        local styled = hs.styledtext.new(entry.label, TEXT_STYLE)
        local size = measure_text(styled)
        local rw = size.w + ROW_PAD_X * 2
        if rw > max_w then max_w = rw end
        table.insert(rows, { styled = styled, size = size, color = entry.color })
    end

    -- Dimensiones del canvas
    local row_h = rows[1].size.h + ROW_PAD_Y * 2
    local inner_w = max_w
    local inner_h = row_h * #rows + ROW_GAP * (#rows - 1)
    local cw = inner_w + OUTER_PAD * 2
    local ch = inner_h + OUTER_PAD * 2

    -- Posición
    local screen = hs.screen.mainScreen():fullFrame()
    local cx, cy
    if saved_pos then
        cx, cy = saved_pos.x, saved_pos.y
    else
        cx = screen.x + screen.w - cw - MARGIN
        cy = screen.y + screen.h - ch - MARGIN
    end

    canvas = hs.canvas.new({ x = cx, y = cy, w = cw, h = ch })
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces + hs.canvas.windowBehaviors.stationary)
    canvas:level(hs.canvas.windowLevels.floating)
    canvas:clickActivating(false)

    -- Fondo exterior
    canvas[1] = {
        type             = "rectangle",
        fillColor        = { white = 0, alpha = 0.50 },
        strokeColor      = { white = 1, alpha = 0.10 },
        strokeWidth      = 0.5,
        roundedRectRadii = { xRadius = CORNER_R, yRadius = CORNER_R },
        action           = "strokeAndFill",
    }

    -- Filas coloreadas
    local idx = 2
    local ry = OUTER_PAD
    for _, row in ipairs(rows) do
        canvas[idx] = {
            type             = "rectangle",
            frame            = { x = OUTER_PAD, y = ry, w = inner_w, h = row_h },
            fillColor        = row.color,
            roundedRectRadii = { xRadius = ROW_R, yRadius = ROW_R },
            action           = "fill",
        }
        canvas[idx + 1] = {
            type  = "text",
            text  = row.styled,
            frame = { x = OUTER_PAD + ROW_PAD_X, y = ry + ROW_PAD_Y, w = row.size.w, h = row.size.h },
        }
        idx = idx + 2
        ry = ry + row_h + ROW_GAP
    end

    -- Drag: iniciar al hacer mouseDown
    canvas:canvasMouseEvents(true, true, false, false)
    canvas:mouseCallback(function(_, event, _, x, y)
        if event == "mouseDown" then
            drag.active = true
            drag.ox = x
            drag.oy = y
            stop_drag_tap()
            drag_tap = hs.eventtap.new(
                { hs.eventtap.event.types.leftMouseDragged, hs.eventtap.event.types.leftMouseUp },
                function(e)
                    if e:getType() == hs.eventtap.event.types.leftMouseUp then
                        if canvas then
                            local f = canvas:frame()
                            saved_pos = { x = f.x, y = f.y }
                        end
                        drag.active = false
                        if drag_tap then drag_tap:stop() end
                        return false
                    end
                    local mouse = hs.mouse.absolutePosition()
                    if canvas then
                        canvas:topLeft({ x = mouse.x - drag.ox, y = mouse.y - drag.oy })
                    end
                    return false
                end
            )
            drag_tap:start()
        end
    end)

    canvas:show()
end

-- ── Ciclo de actualización ──

local function update()
    if drag.active then return end
    local entries = get_entries()
    if #entries > 0 then
        render(entries)
    else
        destroy_canvas()
    end
end

function M.start()
    update()
    if not timer then timer = hs.timer.doEvery(1, update) end
end

function M.stop()
    if timer then timer:stop(); timer = nil end
    stop_drag_tap()
    destroy_canvas()
end

function M.refresh() update() end

return M

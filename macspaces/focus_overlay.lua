-- macspaces/focus_overlay.lua
-- Banner flotante persistente que muestra el estado de enfoque activo.
-- Muestra: Pomodoro countdown, presentación, o tiempo sin descanso.

local M = {}

local pomodoro     = require("macspaces.pomodoro")
local breaks       = require("macspaces.breaks")
local presentation = require("macspaces.presentation")

local canvas     = nil
local timer      = nil
local last_label = nil

local PADDING_X  = 10
local PADDING_Y  = 6
local MARGIN     = 8
local TOP_OFFSET = 30
local FONT_SIZE  = 14
local BG_ALPHA   = 0.75
local CORNER_R   = 8

local TEXT_STYLE = {
    font  = { name = ".AppleSystemUIFont", size = FONT_SIZE },
    color = { white = 1, alpha = 1 },
}

local function get_label()
    if pomodoro.is_active() then
        return pomodoro.time_label()
    end
    if presentation.is_active() then
        return "🎬 Presentación"
    end
    -- Mostrar tiempo sin descanso si es significativo (> 5 min)
    return breaks.idle_label()
end

local function measure_text(styled)
    local ok, size = pcall(hs.drawing.getTextDrawingSize, styled)
    if ok and size then return size end
    -- Fallback si la API deprecada falla
    local len = utf8.len(tostring(styled)) or 12
    return { w = len * (FONT_SIZE * 0.65), h = FONT_SIZE + 6 }
end

local function destroy_canvas()
    if canvas then canvas:delete(); canvas = nil end
    last_label = nil
end

local function show_label(label)
    if label == last_label and canvas then return end
    last_label = label

    local styled = hs.styledtext.new(label, TEXT_STYLE)
    local size   = measure_text(styled)
    local w = size.w + PADDING_X * 2
    local h = size.h + PADDING_Y * 2

    local screen = hs.screen.mainScreen():frame()
    local x = screen.x + screen.w - w - MARGIN
    local y = screen.y + TOP_OFFSET

    if canvas then
        -- Actualizar en lugar de destruir/recrear
        canvas:frame({ x = x, y = y, w = w, h = h })
        canvas[2] = {
            type  = "text",
            text  = styled,
            frame = { x = PADDING_X, y = PADDING_Y, w = size.w, h = size.h },
        }
    else
        canvas = hs.canvas.new({ x = x, y = y, w = w, h = h })
        canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces + hs.canvas.windowBehaviors.stationary)
        canvas:level(hs.canvas.windowLevels.floating)
        canvas:clickActivating(false)

        canvas[1] = {
            type             = "rectangle",
            fillColor        = { white = 0, alpha = BG_ALPHA },
            strokeColor      = { white = 0.3, alpha = 0.5 },
            strokeWidth      = 0.5,
            roundedRectRadii = { xRadius = CORNER_R, yRadius = CORNER_R },
            action           = "strokeAndFill",
        }

        canvas[2] = {
            type  = "text",
            text  = styled,
            frame = { x = PADDING_X, y = PADDING_Y, w = size.w, h = size.h },
        }

        canvas:show()
    end
end

local function update()
    local label = get_label()
    if label then
        show_label(label)
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
    destroy_canvas()
end

function M.refresh() update() end

return M

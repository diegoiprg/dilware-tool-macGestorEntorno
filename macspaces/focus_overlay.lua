-- macspaces/focus_overlay.lua
-- Banner flotante unificado con filas coloreadas por estado.
-- Arrastrable para reposicionar; posición persiste en disco entre reinicios.

local M = {}

local pomodoro     = require("macspaces.pomodoro")
local breaks       = require("macspaces.breaks")
local presentation = require("macspaces.presentation")
local claude       = require("macspaces.claude")
local gemini       = require("macspaces.gemini")
local sysmon       = require("macspaces.sysmon")

local canvas      = nil
local timer       = nil
local drag_tap    = nil
local last_row_count = 0  -- para detectar cambios estructurales sin recrear

-- Posición guardada durante la sesión (se resetea al recargar Hammerspoon)
local saved_pos = nil  -- { x, y }
local drag = { active = false, ox = 0, oy = 0 }

-- ── Detección de dispositivo ──

local IS_MACBOOK = (hs.host.localizedName() or ""):lower():find("macbook") ~= nil

-- ── Constantes visuales ──

local OUTER_PAD  = 8
local ROW_PAD_X  = 14
local ROW_PAD_Y  = 7
local ROW_GAP    = 3
local MARGIN     = 4
local TOP_OFFSET = 30
local FONT_SIZE  = 13
local BG_ALPHA   = 0.82
local CORNER_R   = 12
local ROW_R      = 8
local SHADOW_R   = 14
local SHADOW_OFF = 3

local BG_COLORS = {
    work          = { red = 0.80, green = 0.18, blue = 0.15, alpha = BG_ALPHA },
    short_break   = { red = 0.18, green = 0.58, blue = 0.30, alpha = BG_ALPHA },
    long_break    = { red = 0.18, green = 0.58, blue = 0.30, alpha = BG_ALPHA },
    breaks        = { red = 0.22, green = 0.42, blue = 0.68, alpha = BG_ALPHA },
    breaks_active = { red = 0.18, green = 0.58, blue = 0.30, alpha = BG_ALPHA },
    presentation  = { red = 0.48, green = 0.22, blue = 0.62, alpha = BG_ALPHA },
    sysmon_ok     = { red = 0.14, green = 0.14, blue = 0.18, alpha = 0.70 },
    sysmon_warn   = { red = 0.60, green = 0.45, blue = 0.08, alpha = BG_ALPHA },
    sysmon_crit   = { red = 0.80, green = 0.18, blue = 0.15, alpha = BG_ALPHA },
}

local TEXT_STYLE = {
    font  = { name = ".AppleSystemUIFont", size = FONT_SIZE },
    color = { white = 1, alpha = 0.95 },
    shadow = {
        offset  = { h = 0, w = 0 },
        blurRadius = 2,
        color   = { white = 0, alpha = 0.40 },
    },
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

    -- AI: recopilar filas y determinar si alguna requiere atención
    local ai_rows = {}
    if claude.has_session() then
        for _, row in ipairs(claude.overlay_rows()) do
            table.insert(ai_rows, { label = row.label, color = claude.color_for(row.pct), pct = row.pct })
        end
    end
    if gemini.has_session() then
        for _, row in ipairs(gemini.overlay_rows()) do
            table.insert(ai_rows, { label = row.label, color = gemini.color_for(row.pct), pct = row.pct })
        end
    end

    -- MacBook + todo verde (<60%): ocultar filas AI para minimizar overlay
    local show_ai = true
    if IS_MACBOOK and #ai_rows > 0 then
        show_ai = false
        for _, r in ipairs(ai_rows) do
            if r.pct >= 60 then show_ai = true; break end
        end
    end

    if show_ai then
        for _, r in ipairs(ai_rows) do
            table.insert(entries, { label = r.label, color = r.color })
        end
    end

    -- Fila base del sistema: siempre visible
    local sys = sysmon.overlay_row()
    local sys_color
    if sys.pct >= 85 then
        sys_color = BG_COLORS.sysmon_crit
    elseif sys.pct >= 60 then
        sys_color = BG_COLORS.sysmon_warn
    else
        sys_color = BG_COLORS.sysmon_ok
    end
    table.insert(entries, { label = sys.label, color = sys_color })

    return entries
end

-- ── Renderizado ──

-- Construye el canvas desde cero (primera vez o cambio estructural).
local function build_canvas(rows, row_h, inner_w, inner_h)
    destroy_canvas()

    local cw = inner_w + OUTER_PAD * 2
    local ch = inner_h + OUTER_PAD * 2
    local shadow_extra = SHADOW_R + SHADOW_OFF
    local total_w = cw + shadow_extra * 2
    local total_h = ch + shadow_extra * 2

    local cx, cy
    if saved_pos then
        cx, cy = saved_pos.x, saved_pos.y
    else
        local scr = hs.screen.primaryScreen()
        if not scr then return end
        local screen = scr:fullFrame()
        cx = screen.x - shadow_extra
        cy = screen.y + screen.h - total_h + shadow_extra
    end

    canvas = hs.canvas.new({ x = cx, y = cy, w = total_w, h = total_h })
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces + hs.canvas.windowBehaviors.stationary)
    canvas:level(hs.canvas.windowLevels.floating)
    canvas:clickActivating(false)

    local ox = shadow_extra
    local oy = shadow_extra

    canvas[1] = {
        type             = "rectangle",
        frame            = { x = ox + SHADOW_OFF, y = oy + SHADOW_OFF, w = cw, h = ch },
        fillColor        = { white = 0, alpha = 0.35 },
        roundedRectRadii = { xRadius = SHADOW_R, yRadius = SHADOW_R },
        action           = "fill",
    }
    canvas[2] = {
        type             = "rectangle",
        frame            = { x = ox, y = oy, w = cw, h = ch },
        fillColor        = { white = 0.08, alpha = 0.70 },
        roundedRectRadii = { xRadius = CORNER_R, yRadius = CORNER_R },
        action           = "fill",
    }
    canvas[3] = {
        type             = "rectangle",
        frame            = { x = ox, y = oy, w = cw, h = ch },
        strokeColor      = { white = 1, alpha = 0.12 },
        strokeWidth      = 0.5,
        roundedRectRadii = { xRadius = CORNER_R, yRadius = CORNER_R },
        action           = "stroke",
    }

    local idx = 4
    local ry = oy + OUTER_PAD
    for _, row in ipairs(rows) do
        canvas[idx] = {
            type             = "rectangle",
            frame            = { x = ox + OUTER_PAD, y = ry, w = inner_w, h = row_h },
            fillColor        = row.color,
            roundedRectRadii = { xRadius = ROW_R, yRadius = ROW_R },
            action           = "fill",
        }
        canvas[idx + 1] = {
            type             = "rectangle",
            frame            = { x = ox + OUTER_PAD + 1, y = ry + 1, w = inner_w - 2, h = row_h * 0.45 },
            fillColor        = { white = 1, alpha = 0.08 },
            roundedRectRadii = { xRadius = ROW_R - 1, yRadius = ROW_R - 1 },
            action           = "fill",
        }
        canvas[idx + 2] = {
            type  = "text",
            text  = row.styled,
            frame = { x = ox + OUTER_PAD + ROW_PAD_X, y = ry + ROW_PAD_Y, w = row.size.w, h = row.size.h },
        }
        idx = idx + 3
        ry = ry + row_h + ROW_GAP
    end

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
    last_row_count = #rows
end

-- Actualiza solo texto y color de filas existentes sin destruir el canvas.
local function patch_canvas(rows)
    local idx = 4
    for _, row in ipairs(rows) do
        canvas[idx].fillColor     = row.color
        canvas[idx + 2].text      = row.styled
        idx = idx + 3
    end
end

local function render(entries)
    -- Medir todas las filas
    local rows = {}
    local max_w = 0
    for _, entry in ipairs(entries) do
        local styled = (type(entry.label) == "userdata")
            and entry.label
            or  hs.styledtext.new(entry.label, TEXT_STYLE)
        local size = measure_text(styled)
        local rw = size.w + ROW_PAD_X * 2
        if rw > max_w then max_w = rw end
        table.insert(rows, { styled = styled, size = size, color = entry.color })
    end

    local row_h   = rows[1].size.h + ROW_PAD_Y * 2
    local inner_w = max_w
    local inner_h = row_h * #rows + ROW_GAP * (#rows - 1)

    -- Reconstruir solo si el canvas no existe o cambió el número de filas
    if not canvas or #rows ~= last_row_count then
        build_canvas(rows, row_h, inner_w, inner_h)
    else
        patch_canvas(rows)
    end
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

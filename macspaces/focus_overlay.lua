-- macspaces/focus_overlay.lua
-- MacBook: "Notch extendido" — fondo negro que se funde con el notch.
--   Fila 1 (visible): CPU % | NOTCH | RAM %
--   Hover → panel con red, batería, Claude, descanso, pomodoro.
-- Mac Mini: banner clásico esquina inferior izquierda.

local M = {}

local pomodoro     = require("macspaces.pomodoro")
local breaks       = require("macspaces.breaks")
local presentation = require("macspaces.presentation")
local claude       = require("macspaces.claude")
local sysmon       = require("macspaces.sysmon")
local battery      = require("macspaces.battery")

-- ── Detección ──

local IS_MACBOOK = (hs.host.localizedName() or ""):lower():find("macbook") ~= nil

-- ── Estado ──

local wing_left    = nil
local wing_right   = nil
local panel        = nil
local timer        = nil
local expanded     = false
local hover_active = false
local collapse_timer = nil
local last_render  = ""

local update  -- forward decl

-- ── Constantes MacBook ──

local NOTCH_W    = 220   -- ancho del notch + margen
local WING_GAP   = 6     -- separación del notch
local WING_FONT  = 14    -- discreto, legible
local WING_H     = 20
local WING_W     = 70    -- ancho de cada ala

-- Panel
local PANEL_FONT = 13
local PANEL_ROW_H = 24
local PANEL_PAD  = 8
local PANEL_GAP  = 3

-- Colores
local C_OK   = { red = 0.30, green = 0.85, blue = 0.50, alpha = 1 }
local C_WARN = { red = 0.95, green = 0.75, blue = 0.15, alpha = 1 }
local C_CRIT = { red = 0.95, green = 0.30, blue = 0.25, alpha = 1 }
local C_DIM  = { red = 0.50, green = 0.50, blue = 0.55, alpha = 1 }
local C_ON   = { red = 0.30, green = 0.85, blue = 0.50, alpha = 1 }
local C_OFF  = { red = 0.50, green = 0.50, blue = 0.55, alpha = 0.5 }
local C_BLUE = { red = 0.40, green = 0.70, blue = 1.00, alpha = 1 }
local C_NET  = { red = 0.40, green = 0.80, blue = 0.95, alpha = 1 }
local C_WHITE = { white = 1, alpha = 0.92 }

local function color_pct(pct)
    if not pct then return C_DIM end
    if pct >= 85 then return C_CRIT end
    if pct >= 60 then return C_WARN end
    return C_OK
end

-- ── Helpers ──

local function seg(text, size, color)
    return hs.styledtext.new(text, {
        font = { name = ".AppleSystemUIFont", size = size or WING_FONT },
        color = color or { white = 1, alpha = 0.95 },
        paragraphStyle = { alignment = "center" },
    })
end

local function measure(st)
    local ok, sz = pcall(hs.drawing.getTextDrawingSize, st)
    if ok and sz then return sz end
    return { w = 60, h = 16 }
end

local function destroy_all()
    if wing_left then wing_left:delete(); wing_left = nil end
    if wing_right then wing_right:delete(); wing_right = nil end
    if panel then panel:delete(); panel = nil end
    last_render = ""
end

-- ── CPU / RAM (cached via sysmon) ──

local cpu_val = 0
local ram_val = 0

local function refresh_metrics()
    sysmon.update()
    -- CPU: suma de todos los procesos / número de cores = uso real
    local f = io.popen("sysctl -n hw.ncpu 2>/dev/null")
    local cores = 1
    if f then cores = tonumber(f:read("*a")) or 1; f:close() end
    local f2 = io.popen("ps -A -o %cpu | awk '{s+=$1} END {printf \"%.0f\", s}' 2>/dev/null")
    if f2 then cpu_val = math.min(100, math.floor((tonumber(f2:read("*a")) or 0) / cores)); f2:close() end
    -- RAM
    local f3 = io.popen("memory_pressure 2>/dev/null | awk '/free percentage/{print 100-$NF}'")
    if f3 then
        local v = f3:read("*a"); f3:close()
        ram_val = tonumber(v:match("%d+")) or 0
    end
end

-- ── MacBook: Wings ──

local function hover_callback(_, event)
    if event == "mouseEnter" then
        hover_active = true
        if collapse_timer then collapse_timer:stop(); collapse_timer = nil end
        if not expanded then expanded = true end
    elseif event == "mouseExit" then
        hover_active = false
        if collapse_timer then collapse_timer:stop() end
        collapse_timer = hs.timer.doAfter(0.8, function()
            if not hover_active then expanded = false; last_render = "" end
        end)
    end
end

local function make_wing(text_st, x, y, w)
    local c = hs.canvas.new({ x = x, y = y, w = w, h = WING_H })
    c:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces + hs.canvas.windowBehaviors.stationary)
    c:level(hs.canvas.windowLevels.popUpMenu)
    c:clickActivating(false)

    -- Fondo pill oscuro para legibilidad sobre cualquier wallpaper
    c[1] = {
        type = "rectangle",
        frame = { x = 0, y = 0, w = w, h = WING_H },
        fillColor = { white = 0.0, alpha = 0.55 },
        roundedRectRadii = { xRadius = 6, yRadius = 6 },
        action = "fill",
    }
    c[2] = {
        type = "text",
        text = text_st,
        frame = { x = 0, y = 2, w = w, h = WING_H - 2 },
    }

    c:canvasMouseEvents(true, true, true, true)
    c:mouseCallback(hover_callback)
    c:show()
    return c
end

-- ── Panel expandido ──

local function seg_panel(text, color)
    return hs.styledtext.new(text, {
        font = { name = ".AppleSystemUIFont", size = PANEL_FONT },
        color = color or { white = 1, alpha = 0.92 },
    })
end

local function join(parts)
    local r = parts[1]
    for i = 2, #parts do r = r .. parts[i] end
    return r
end

local function panel_entries()
    local entries = {}

    -- Fila 1.5: GPU + tráfico de red
    local gpu_pct
    local f = io.popen("ioreg -r -d 1 -w 0 -c IOAccelerator 2>/dev/null | grep 'Device Utilization'")
    if f then local raw = f:read("*a"); f:close(); gpu_pct = tonumber(raw:match('"Device Utilization %%"=(%d+)')) end
    local net = sysmon.net_state()
    local up_val = net.net_up or 0
    local dn_val = net.net_down or 0
    local net_online = net.online ~= false
    local up_color = net_online and C_NET or C_DIM
    local dn_color = net_online and C_NET or C_DIM
    local up_str = sysmon.fmt_net(up_val)
    local dn_str = sysmon.fmt_net(dn_val)
    local gpu_label = join({
        seg_panel("◈ GPU ", C_WHITE),
        seg_panel(gpu_pct and string.format("%d%%", gpu_pct) or "—", color_pct(gpu_pct)),
        seg_panel("   ↑ ", C_WHITE),
        seg_panel(up_str, up_color),
        seg_panel("  ↓ ", C_WHITE),
        seg_panel(dn_str, dn_color),
    })
    table.insert(entries, { label = gpu_label, color = { white = 0.10, alpha = 0.70 } })

    -- Filas: Discos — formato: ▪ NOMBRE · %  · usado de total
    -- Disco del sistema (diskutil reporta en GB base 1000, igual que Apple)
    local df = io.popen("diskutil info / 2>/dev/null | grep -E 'Container Total|Container Free'")
    if df then
        local raw = df:read("*a"); df:close()
        local total_gb = tonumber(raw:match("Container Total Space:%s+([%d%.]+) GB"))
        local free_gb  = tonumber(raw:match("Container Free Space:%s+([%d%.]+) GB"))
        if total_gb and free_gb then
            local used_gb = total_gb - free_gb
            local pct = math.floor((used_gb / total_gb) * 100)
            local lbl = join({
                seg_panel("▪ SISTEMA ", C_WHITE),
                seg_panel("· ", C_DIM),
                seg_panel(pct .. "%", color_pct(pct)),
                seg_panel(string.format(" · %.0f de %.0f GB", used_gb, total_gb), C_DIM),
            })
            table.insert(entries, { label = lbl, color = { white = 0.10, alpha = 0.70 } })
        end
    end
    -- Discos externos en /Volumes (df -H = base 1000, consistente con Apple)
    local df2 = io.popen("df -H 2>/dev/null | grep '/Volumes/' | grep -v '/System/Volumes' | grep -v '.timemachine' | grep -v 'CoreSimulator'")
    if df2 then
        local raw = df2:read("*a"); df2:close()
        for line in raw:gmatch("[^\n]+") do
            local fields = {}
            for w in line:gmatch("%S+") do table.insert(fields, w) end
            if #fields >= 9 then
                local total = fields[2]:gsub("[Gg]i?$", "")
                local used = fields[3]:gsub("[Gg]i?$", "")
                local pct_str = fields[5]:match("(%d+)")
                local pct = tonumber(pct_str) or 0
                local mount = table.concat(fields, " ", 9)
                local name = (mount:match("/Volumes/(.+)") or mount):upper()
                local lbl = join({
                    seg_panel("▪ " .. name .. " ", C_WHITE),
                    seg_panel("· ", C_DIM),
                    seg_panel(pct_str .. "%", color_pct(pct)),
                    seg_panel(" · " .. used .. " de " .. total .. " GB", C_DIM),
                })
                table.insert(entries, { label = lbl, color = { white = 0.10, alpha = 0.70 } })
            end
        end
    end

    -- Fila 2: Red
    local cable_on = net.iface_type == "eth"
    local wifi_on  = net.iface_type == "wifi"
    local vpn_on   = net.vpn
    local net_label = join({
        seg_panel("⌁ CABLE ", C_WHITE),
        seg_panel(cable_on and "●" or "○", cable_on and C_ON or C_OFF),
        seg_panel("   ≋ WIFI ", C_WHITE),
        seg_panel(wifi_on and "●" or "○", wifi_on and C_ON or C_OFF),
        seg_panel("   🔒 VPN ", C_WHITE),
        seg_panel(vpn_on and "●" or "○", vpn_on and C_ON or C_OFF),
    })
    table.insert(entries, { label = net_label, color = { white = 0.10, alpha = 0.70 } })

    -- Fila 3: Batería
    if battery.has_battery() then
        local pct = math.floor(battery.percentage())
        local plugged = battery.is_plugged()
        local ok_cc, cycles = pcall(function() return hs.battery.cycles() end)
        if not ok_cc then cycles = 0 end
        local bat_label = join({
            seg_panel("⚡ CORRIENTE ", C_WHITE),
            seg_panel(plugged and "●" or "○", plugged and C_ON or C_OFF),
            seg_panel("   🔋 ", C_WHITE),
            seg_panel(string.format("%d%%", pct), color_pct(100 - pct)),
            seg_panel(string.format(" · %d ciclos", cycles), C_DIM),
        })
        table.insert(entries, { label = bat_label, color = { white = 0.10, alpha = 0.70 } })
    end

    -- Fila 4: Claude
    if claude.has_session() then
        for _, row in ipairs(claude.overlay_rows()) do
            table.insert(entries, { label = row.label, color = { white = 0.10, alpha = 0.70 } })
        end
    end

    -- Fila 5: Descanso
    local idle = breaks.idle_label()
    if idle then
        -- Formato: "◎ DESCANSO · MM:SS" — label blanco, tiempo con color
        local label_part, time_part = tostring(idle):match("(.+ · )(.+)")
        if label_part and time_part then
            local lbl = join({
                seg_panel(label_part, C_WHITE),
                seg_panel(time_part, C_ON),
            })
            table.insert(entries, { label = lbl, color = { white = 0.10, alpha = 0.70 } })
        else
            table.insert(entries, { label = seg_panel(tostring(idle), C_WHITE), color = { white = 0.10, alpha = 0.70 } })
        end
    end

    -- Fila 6: Pomodoro
    if pomodoro.is_active() then
        -- Formato: "🍅 POMODORO · 24:36 · Ciclo 1/4"
        local raw = tostring(pomodoro.time_label())
        local icon_name, time_str, cycle_str = raw:match("(.+ · )(%d+:%d+)( · .+)")
        if icon_name and time_str then
            local lbl = join({
                seg_panel(icon_name, C_WHITE),
                seg_panel(time_str, C_ON),
                seg_panel(cycle_str or "", C_DIM),
            })
            table.insert(entries, { label = lbl, color = { white = 0.10, alpha = 0.70 } })
        else
            table.insert(entries, { label = seg_panel(raw, C_WHITE), color = { white = 0.10, alpha = 0.70 } })
        end
    end

    if presentation.is_active() then
        table.insert(entries, { label = seg_panel("🎬 PRESENTACIÓN"), color = { white = 0.10, alpha = 0.70 } })
    end

    return entries
end

local function build_panel()
    local entries = panel_entries()
    if #entries == 0 then return nil end

    local scr = hs.screen.primaryScreen()
    if not scr then return nil end
    local screen = scr:fullFrame()
    local visible = scr:frame()
    local menu_bar_h = visible.y - screen.y

    local rows = {}
    local max_w = 0
    for _, e in ipairs(entries) do
        local st = (type(e.label) == "userdata") and e.label
            or seg_panel(tostring(e.label))
        local sz = measure(st)
        if sz.w > max_w then max_w = sz.w end
        table.insert(rows, { styled = st, size = sz, color = e.color })
    end

    local inner_w = max_w + 20
    local ph = PANEL_ROW_H * #rows + PANEL_GAP * (#rows - 1) + PANEL_PAD * 2
    local pw = inner_w + PANEL_PAD * 2
    local px = screen.x + math.floor((screen.w - pw) / 2)
    local py = screen.y + menu_bar_h

    local c = hs.canvas.new({ x = px, y = py, w = pw, h = ph })
    c:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces + hs.canvas.windowBehaviors.stationary)
    c:level(hs.canvas.windowLevels.popUpMenu)
    c:clickActivating(false)

    c[1] = { type = "rectangle", frame = { x = 0, y = 0, w = pw, h = ph },
        fillColor = { white = 0.04, alpha = 0.92 },
        roundedRectRadii = { xRadius = 10, yRadius = 10 }, action = "fill" }
    c[2] = { type = "rectangle", frame = { x = 0, y = 0, w = pw, h = ph },
        strokeColor = { white = 1, alpha = 0.06 }, strokeWidth = 0.5,
        roundedRectRadii = { xRadius = 10, yRadius = 10 }, action = "stroke" }

    local idx = 3
    local ry = PANEL_PAD
    for _, row in ipairs(rows) do
        c[idx] = { type = "rectangle", frame = { x = PANEL_PAD, y = ry, w = inner_w, h = PANEL_ROW_H },
            fillColor = row.color, roundedRectRadii = { xRadius = 5, yRadius = 5 }, action = "fill" }
        c[idx + 1] = { type = "text", text = row.styled,
            frame = { x = PANEL_PAD + 10, y = ry + 4, w = row.size.w + 4, h = row.size.h } }
        idx = idx + 2
        ry = ry + PANEL_ROW_H + PANEL_GAP
    end

    c:canvasMouseEvents(true, true, true, true)
    c:mouseCallback(hover_callback)
    c:show()
    return c
end

-- ── MacBook render ──

local function render_wings()
    refresh_metrics()

    local scr = hs.screen.primaryScreen()
    if not scr then return end
    local screen = scr:fullFrame()
    local visible = scr:frame()
    local menu_bar_h = visible.y - screen.y
    local center_x = screen.x + math.floor(screen.w / 2)
    local wing_y = screen.y + math.floor((menu_bar_h - WING_H) / 2)

    local left_st  = seg(string.format("CPU %d%%", cpu_val), WING_FONT, color_pct(cpu_val))
    local right_st = seg(string.format("RAM %d%%", ram_val), WING_FONT, color_pct(ram_val))

    local fp = string.format("%d:%d:%s", cpu_val, ram_val, expanded and "E" or "C")

    if fp == last_render and wing_left then
        wing_left[2].text = left_st
        wing_right[2].text = right_st
        if expanded then
            if panel then panel:delete() end
            panel = build_panel()
        end
        if not expanded and panel then panel:delete(); panel = nil end
        return
    end
    last_render = fp

    -- Rebuild
    if wing_left then wing_left:delete(); wing_left = nil end
    if wing_right then wing_right:delete(); wing_right = nil end
    if panel then panel:delete(); panel = nil end

    local gap = IS_MACBOOK and NOTCH_W or WING_GAP
    local left_x  = center_x - math.floor(gap / 2) - WING_W
    local right_x = center_x + math.floor(gap / 2)

    wing_left  = make_wing(left_st, left_x, wing_y, WING_W)
    wing_right = make_wing(right_st, right_x, wing_y, WING_W)

    if expanded then panel = build_panel() end
end

-- ── Update ──

update = function()
    render_wings()
end

function M.start()
    update()
    if not timer then timer = hs.timer.doEvery(2, update) end
end

function M.stop()
    if timer then timer:stop(); timer = nil end
    if collapse_timer then collapse_timer:stop(); collapse_timer = nil end
    destroy_all()
end

function M.refresh() update() end

return M

-- macspaces/claude.lua
-- Monitor de uso de Claude Code y Claude.ai
-- Fuente: ~/.claude/usage_cache.json (escrito por statusline.sh)

local M = {}

local utils = require("macspaces.utils")

-- ── Cache ──────────────────────────────────────────────────────────────────
local cache = {
    data     = nil,  -- { five_hour = {pct, reset}, seven_day = {pct, reset}, source }
    last_fetch = 0,
    ttl      = 60,   -- segundos entre refetches
}

-- ── Helpers ────────────────────────────────────────────────────────────────

-- Formatea segundos restantes como "Xh Ym" o "Ym"
local function fmt_reset(epoch)
    if not epoch or epoch == 0 then return "—" end
    local remaining = epoch - os.time()
    if remaining <= 0 then return "ahora" end
    local h = math.floor(remaining / 3600)
    local m = math.floor((remaining % 3600) / 60)
    if h > 0 then return h .. "h " .. m .. "m" end
    return m .. "m"
end

-- Lee ~/.claude/usage_cache.json generado por statusline.sh
local function read_from_claude_code()
    local home = os.getenv("HOME") or ""
    local cache_path = home .. "/.claude/usage_cache.json"

    local f = io.open(cache_path, "r")
    if not f then return nil end
    local raw = f:read("*a")
    f:close()

    if not raw or raw == "" then return nil end

    local ok, data = pcall(hs.json.decode, raw)
    if not ok or not data then return nil end

    -- Ignorar cache con más de 6 horas de antigüedad
    local updated_at = data.updated_at or 0
    if (os.time() - updated_at) > 21600 then return nil end

    local fh = data.five_hour
    if not fh then return nil end

    return {
        five_hour = {
            pct   = fh.pct or 0,
            reset = fh.reset or 0,
        },
        seven_day = {
            pct   = (data.seven_day and data.seven_day.pct) or 0,
            reset = (data.seven_day and data.seven_day.reset) or 0,
        },
        source = "code",
    }
end

-- Fetch principal
function M.fetch()
    local now = os.time()
    if cache.data and (now - cache.last_fetch) < cache.ttl then
        return cache.data
    end

    local data = read_from_claude_code()
    if not data then
        data = { source = "none" }
    end

    cache.data = data
    cache.last_fetch = now
    return data
end

function M.invalidate()
    cache.data = nil
    cache.last_fetch = 0
end

-- ── UI helpers ──────────────────────────────────────────────────────────────

-- Barra de progreso en texto: ▰▰▰▰▱▱▱▱ 74%
local function bar(pct, width)
    width = width or 8
    local filled = math.floor((pct / 100) * width)
    local empty = width - filled
    return string.rep("▰", filled) .. string.rep("▱", empty)
end

-- Color semáforo según porcentaje
function M.color_for(pct)
    if pct >= 85 then
        return { red = 0.85, green = 0.20, blue = 0.15, alpha = 0.85 }  -- rojo
    elseif pct >= 60 then
        return { red = 0.90, green = 0.65, blue = 0.10, alpha = 0.85 }  -- amarillo
    else
        return { red = 0.15, green = 0.50, blue = 0.30, alpha = 0.85 }  -- verde oscuro
    end
end

-- Filas para el overlay: retorna tabla con 1 o 2 entradas { label, pct }
-- minimal=true omite la barra de progreso (para MacBook)
function M.overlay_rows(minimal)
    local d = M.fetch()
    if d.source == "none" or not d.five_hour then
        return {{ label = "✦ Claude  —  sin sesión activa", pct = 0 }}
    end

    local fh = d.five_hour
    local sd = d.seven_day or { pct = 0, reset = 0 }

    local rows = {}
    if minimal then
        table.insert(rows, {
            label = string.format("✦ Claude 5h  %d%%  ↺%s", fh.pct, fmt_reset(fh.reset)),
            pct   = fh.pct,
        })
        if sd.reset and sd.reset > 0 then
            table.insert(rows, {
                label = string.format("✦ Claude 7d  %d%%  ↺%s", sd.pct, fmt_reset(sd.reset)),
                pct   = sd.pct,
            })
        end
    else
        table.insert(rows, {
            label = string.format("✦ Claude 5h  %s %d%%  ↺%s", bar(fh.pct, 8), fh.pct, fmt_reset(fh.reset)),
            pct   = fh.pct,
        })
        if sd.reset and sd.reset > 0 then
            table.insert(rows, {
                label = string.format("✦ Claude 7d  %s %d%%  ↺%s", bar(sd.pct, 8), sd.pct, fmt_reset(sd.reset)),
                pct   = sd.pct,
            })
        end
    end
    return rows
end

-- Compatibilidad: retorna solo la primera fila como string
function M.overlay_label()
    return M.overlay_rows()[1].label
end

-- Construye el submenú para menu.lua
function M.build_submenu()
    local d = M.fetch()
    local items = {}

    if d.source == "none" or not d.five_hour then
        table.insert(items, utils.disabled_item("Sin sesión activa de Claude Code"))
        table.insert(items, {
            title = "Abrir claude.ai/settings/usage",
            fn    = function()
                hs.urlevent.openURL("https://claude.ai/settings/usage")
            end,
        })
        return items
    end

    local fh = d.five_hour
    local sd = d.seven_day or { pct = 0, reset = 0 }

    -- Ventana 5 horas
    table.insert(items, utils.disabled_item(
        string.format("5h   %s %d%%", bar(fh.pct, 10), fh.pct)
    ))
    table.insert(items, utils.disabled_item(
        "     Reset en " .. fmt_reset(fh.reset)
    ))

    -- Ventana 7 días
    if sd.reset and sd.reset > 0 then
        table.insert(items, { title = "-" })
        table.insert(items, utils.disabled_item(
            string.format("7d   %s %d%%", bar(sd.pct, 10), sd.pct)
        ))
        table.insert(items, utils.disabled_item(
            "     Reset en " .. fmt_reset(sd.reset)
        ))
    end

    -- Acciones
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Abrir uso detallado",
        fn    = function()
            hs.urlevent.openURL("https://claude.ai/settings/usage")
        end,
    })
    table.insert(items, {
        title = "Actualizar",
        fn    = function() M.invalidate() end,
    })

    return items
end

return M

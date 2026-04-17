-- macspaces/claude.lua
-- Monitor de uso de Claude Code y Claude.ai
-- Fuente: ~/.claude/usage_cache.json (escrito por statusline.sh)

local M = {}

local utils = require("macspaces.utils")

-- ── Cache ──────────────────────────────────────────────────────────────────

local CACHE_MAX_AGE = 6 * 3600  -- descartar si el archivo tiene más de 6h sin actualizar

local cache = {
    data       = nil,
    last_fetch = 0,
    ttl        = 60,
}

-- ── Helpers ────────────────────────────────────────────────────────────────

local function fmt_reset(epoch)
    if not epoch or epoch == 0 then return "—" end
    local remaining = epoch - os.time()
    if remaining <= 0 then return "ahora" end
    local h = math.floor(remaining / 3600)
    local m = math.floor((remaining % 3600) / 60)
    if h > 0 then return h .. "h " .. m .. "m" end
    return m .. "m"
end

-- Si el epoch de reset ya pasó, la ventana se reinició → pct real es 0
local function adjusted_pct(pct, reset_epoch)
    if reset_epoch and reset_epoch > 0 and reset_epoch <= os.time() then return 0 end
    return pct or 0
end

local function read_from_claude_code()
    local home = os.getenv("HOME") or ""
    local f = io.open(home .. "/.claude/usage_cache.json", "r")
    if not f then return nil end
    local raw = f:read("*a")
    f:close()

    if not raw or raw == "" then return nil end

    local ok, data = pcall(hs.json.decode, raw)
    if not ok or not data then return nil end

    if (os.time() - (data.updated_at or 0)) > CACHE_MAX_AGE then return nil end

    local fh = data.five_hour
    if not fh then return nil end

    return {
        five_hour = { pct = adjusted_pct(fh.pct, fh.reset), reset = fh.reset or 0 },
        seven_day = {
            pct   = adjusted_pct(data.seven_day and data.seven_day.pct, data.seven_day and data.seven_day.reset),
            reset = (data.seven_day and data.seven_day.reset) or 0,
        },
        source = "code",
    }
end

function M.fetch()
    local now = os.time()
    if cache.data and (now - cache.last_fetch) < cache.ttl then
        -- Re-evaluar pct por si el reset epoch pasó durante el TTL del cache
        local d = cache.data
        if d.five_hour then
            d.five_hour.pct = adjusted_pct(d.five_hour.pct, d.five_hour.reset)
        end
        if d.seven_day then
            d.seven_day.pct = adjusted_pct(d.seven_day.pct, d.seven_day.reset)
        end
        return d
    end
    local data = read_from_claude_code() or { source = "none" }
    cache.data = data
    cache.last_fetch = now
    return data
end

function M.invalidate()
    cache.data = nil
    cache.last_fetch = 0
end

function M.has_session()
    local d = M.fetch()
    return d.source ~= "none" and d.five_hour ~= nil
end

-- ── UI helpers ──────────────────────────────────────────────────────────────

local function bar(pct, width)
    width = width or 8
    local filled = math.floor((pct / 100) * width)
    return string.rep("▰", filled) .. string.rep("▱", width - filled)
end

function M.color_for(pct)
    if pct >= 85 then
        return { red = 0.85, green = 0.20, blue = 0.15, alpha = 0.85 }
    elseif pct >= 60 then
        return { red = 0.90, green = 0.65, blue = 0.10, alpha = 0.85 }
    else
        return { red = 0.15, green = 0.50, blue = 0.30, alpha = 0.85 }
    end
end

function M.overlay_rows(minimal)
    local d = M.fetch()
    if d.source == "none" or not d.five_hour then
        return {{ label = "✦ Claude  —  sin sesión activa", pct = 0 }}
    end

    local fh = d.five_hour
    local sd = d.seven_day or { pct = 0, reset = 0 }

    local function row_label(name, pct, reset_epoch)
        if minimal then
            return string.format("✦ Claude %s  %d%%  ↺%s", name, pct, fmt_reset(reset_epoch))
        end
        return string.format("✦ Claude %s  %s %d%%  ↺%s", name, bar(pct, 8), pct, fmt_reset(reset_epoch))
    end

    local rows = {{ label = row_label("5h", fh.pct, fh.reset), pct = fh.pct }}
    if sd.reset and sd.reset > 0 then
        table.insert(rows, { label = row_label("7d", sd.pct, sd.reset), pct = sd.pct })
    end
    return rows
end

function M.overlay_label()
    return M.overlay_rows()[1].label
end

function M.build_submenu()
    local d = M.fetch()
    local items = {}

    if d.source == "none" or not d.five_hour then
        table.insert(items, utils.disabled_item("Sin sesión activa de Claude Code"))
        table.insert(items, {
            title = "Abrir claude.ai/settings/usage",
            fn    = function() hs.urlevent.openURL("https://claude.ai/settings/usage") end,
        })
        return items
    end

    local fh = d.five_hour
    local sd = d.seven_day or { pct = 0, reset = 0 }

    table.insert(items, utils.disabled_item(string.format("5h   %s %d%%", bar(fh.pct, 10), fh.pct)))
    table.insert(items, utils.disabled_item("     Reset en " .. fmt_reset(fh.reset)))

    if sd.reset and sd.reset > 0 then
        table.insert(items, { title = "-" })
        table.insert(items, utils.disabled_item(string.format("7d   %s %d%%", bar(sd.pct, 10), sd.pct)))
        table.insert(items, utils.disabled_item("     Reset en " .. fmt_reset(sd.reset)))
    end

    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Abrir uso detallado",
        fn    = function() hs.urlevent.openURL("https://claude.ai/settings/usage") end,
    })
    table.insert(items, {
        title = "Actualizar",
        fn    = function() M.invalidate() end,
    })

    return items
end

return M

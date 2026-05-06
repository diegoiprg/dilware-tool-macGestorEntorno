-- macspaces/claude.lua
-- Monitor de uso de Claude Code y Claude.ai
-- Fuente: ~/.claude/usage_cache.json (escrito por statusline.sh)

local M = {}

local utils = require("macspaces.utils")

-- ── Cache ──────────────────────────────────────────────────────────────────

local CACHE_MAX_AGE    = 6 * 3600   -- descartar si el archivo tiene más de 6h sin actualizar
local STALE_THRESHOLD  = 10 * 60    -- dato >10min sin actualizar → marcar como stale

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
    local d = math.floor(remaining / 86400)
    local h = math.floor((remaining % 86400) / 3600)
    local m = math.floor((remaining % 3600) / 60)
    if d > 0 then return d .. "d " .. h .. "h " .. m .. "m" end
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

    local function read_quota(key)
        local q = data[key]
        if not q then return nil end
        return { pct = adjusted_pct(q.pct, q.reset), reset = q.reset or 0 }
    end

    return {
        five_hour        = { pct = adjusted_pct(fh.pct, fh.reset), reset = fh.reset or 0 },
        seven_day        = read_quota("seven_day") or { pct = 0, reset = 0 },
        seven_day_sonnet = read_quota("seven_day_sonnet"),
        seven_day_design = read_quota("seven_day_design"),
        daily            = read_quota("daily"),
        updated_at       = data.updated_at or 0,
        source           = "code",
    }
end

-- Indicador de frescura del dato: [▶] fluyendo, [⏸ Xm] pausado
local function freshness_indicator(updated_at)
    if not updated_at or updated_at == 0 then return "  [⏸]" end
    local age = os.time() - updated_at
    if age < STALE_THRESHOLD then return "  [▶]" end
    local m = math.floor(age / 60)
    if m >= 60 then
        return string.format("  [⏸ %dh%dm]", math.floor(m / 60), m % 60)
    end
    return string.format("  [⏸ %dm]", m)
end

function M.fetch()
    local now = os.time()
    if cache.data and (now - cache.last_fetch) < cache.ttl then
        -- Re-evaluar pct por si el reset epoch pasó durante el TTL del cache
        local d = cache.data
        for _, key in ipairs({ "five_hour", "seven_day", "seven_day_sonnet", "seven_day_design", "daily" }) do
            if d[key] then
                d[key].pct = adjusted_pct(d[key].pct, d[key].reset)
            end
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

-- ── Colores semáforo ────────────────────────────────────────────────────────

local C = {
    ok   = { red = 0.25, green = 0.85, blue = 0.45, alpha = 1 },
    warn = { red = 0.95, green = 0.75, blue = 0.10, alpha = 1 },
    crit = { red = 0.95, green = 0.28, blue = 0.22, alpha = 1 },
    dim  = { red = 0.55, green = 0.55, blue = 0.60, alpha = 1 },
}

local ROW_BG = { red = 0.14, green = 0.14, blue = 0.18, alpha = 0.70 }

local function seg(text, color)
    return hs.styledtext.new(text, {
        font   = { name = ".AppleSystemUIFont", size = 13 },
        color  = color,
        shadow = { offset = { h = 0, w = 0 }, blurRadius = 2, color = { white = 0, alpha = 0.40 } },
    })
end

local function color_for_pct(pct)
    if not pct then return C.dim end
    if pct >= 85 then return C.crit end
    if pct >= 60 then return C.warn end
    return C.ok
end

-- ── UI helpers (submenú) ─────────────────────────────────────────────────────

local function bar(pct, width)
    width = width or 8
    local filled = math.floor((pct / 100) * width)
    return string.rep("▰", filled) .. string.rep("▱", width - filled)
end

function M.color_for(pct)
    return color_for_pct(pct)
end

function M.overlay_rows()
    local d = M.fetch()
    if d.source == "none" or not d.five_hour then return {} end

    local fh  = d.five_hour
    local sd  = d.seven_day or { pct = 0, reset = 0 }
    local snt = d.seven_day_sonnet

    local sep = seg("  ", C.dim)

    local parts = {
        seg("✦ CLAUDE  ", { white = 1, alpha = 0.92 }),
        seg(string.format("5h %d%%", fh.pct), color_for_pct(fh.pct)),
    }

    if sd.reset and sd.reset > 0 then
        table.insert(parts, sep)
        table.insert(parts, seg(string.format("7d %d%%", sd.pct), color_for_pct(sd.pct)))
    end

    if snt then
        table.insert(parts, sep)
        table.insert(parts, seg(string.format("snt %d%%", snt.pct), color_for_pct(snt.pct)))
    end

    local label = parts[1]
    for i = 2, #parts do label = label .. parts[i] end

    local pcts = { fh.pct, sd.pct }
    if snt then table.insert(pcts, snt.pct) end

    return {{ label = label, pct = math.max(table.unpack(pcts)), bg = ROW_BG }}
end

local function quota_rows(items, label, q)
    if not q then
        table.insert(items, utils.disabled_item(string.format("%-20s  —  (pendiente)", label)))
        return
    end
    table.insert(items, utils.disabled_item(string.format("%-20s  %s %d%%", label, bar(q.pct, 10), q.pct)))
    table.insert(items, utils.disabled_item("     Reset en " .. fmt_reset(q.reset)))
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

    local stale = freshness_indicator(d.updated_at)

    -- Sesión actual (5h)
    quota_rows(items, "Sesión actual  (5h)", d.five_hour)

    -- Todos los modelos (7d)
    table.insert(items, { title = "-" })
    if d.seven_day and d.seven_day.reset and d.seven_day.reset > 0 then
        quota_rows(items, "Todos los modelos (7d)", d.seven_day)
    else
        table.insert(items, utils.disabled_item("Todos los modelos (7d)  —  sin datos"))
    end

    -- Campos opcionales: se muestran solo cuando Claude Code los emita
    if d.seven_day_sonnet then
        table.insert(items, { title = "-" })
        quota_rows(items, "Solo Sonnet    (7d)", d.seven_day_sonnet)
    end
    if d.seven_day_design then
        table.insert(items, { title = "-" })
        quota_rows(items, "Claude Design  (7d)", d.seven_day_design)
    end
    if d.daily then
        table.insert(items, { title = "-" })
        quota_rows(items, "Rutinas diarias (24h)", d.daily)
    end

    -- Indicador de frescura
    if stale:find("⏸") then
        table.insert(items, { title = "-" })
        local age_text = stale:match("%[⏸ (.-)%]") or ""
        table.insert(items, utils.disabled_item("⏸ Dato desactualizado — hace " .. age_text))
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

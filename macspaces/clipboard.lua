-- macspaces/clipboard.lua
-- Historial del portapapeles: almacena hasta N entradas recientes.
-- Al seleccionar una entrada, la restaura al portapapeles para pegado manual.
-- La búsqueda usa hs.chooser con filtrado nativo por texto.

local M = {}

local cfg   = require("macspaces.config")
local utils = require("macspaces.utils")

-- ─────────────────────────────────────────────
-- Estado interno
-- ─────────────────────────────────────────────
local history = {}
local watcher = nil

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function truncate(str, max)
    if not str then return "" end
    str = str:gsub("[\n\r\t]", " "):gsub("%s+", " ")
    if #str > max then return str:sub(1, max) .. "…" end
    return str
end

local function capture_entry()
    local types = hs.pasteboard.contentTypes()
    if not types or #types == 0 then return end

    local entry = { timestamp = os.time() }

    local text = hs.pasteboard.getContents()
    if text and text ~= "" then
        entry.type    = "text"
        entry.content = text
        entry.label   = truncate(text, 60)
    elseif hs.pasteboard.readImage() then
        local img = hs.pasteboard.readImage()
        entry.type    = "image"
        entry.content = img
        entry.label   = "[Imagen]"
    elseif hs.pasteboard.readURL() then
        local url = hs.pasteboard.readURL()
        entry.type    = "url"
        entry.content = url
        entry.label   = truncate(url, 60)
    else
        entry.type    = "other"
        entry.content = nil
        entry.label   = "[Contenido no previsualizable]"
    end

    -- Evitar duplicados consecutivos
    if #history > 0 and history[1].label == entry.label then return end

    table.insert(history, 1, entry)

    local max = cfg.clipboard and cfg.clipboard.max_entries or 20
    while #history > max do table.remove(history) end

    utils.log("[INFO] Clipboard: entrada capturada (" .. entry.type .. ")")
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────

function M.start(on_change)
    -- hs.pasteboard.watcher es event-driven: solo dispara cuando cambia el portapapeles
    watcher = hs.pasteboard.watcher.new(function()
        capture_entry()
        if on_change then on_change() end
    end)
    watcher:start()
    utils.log("[INFO] Clipboard watcher iniciado")
end

function M.stop()
    if watcher then
        watcher:stop()
        watcher = nil
    end
end

function M.clear()
    history = {}
    utils.log("[INFO] Clipboard: historial limpiado")
end

function M.restore(index)
    local entry = history[index]
    if not entry then return end

    if entry.type == "text" then
        hs.pasteboard.setContents(entry.content)
    elseif entry.type == "image" and entry.content then
        hs.pasteboard.writeObjects(entry.content)
    elseif entry.type == "url" then
        hs.pasteboard.setContents(entry.content)
    end

    utils.log("[OK] Clipboard: entrada " .. index .. " restaurada")
end

-- Abre el chooser con todas las entradas; el usuario filtra escribiendo
function M.open_chooser()
    if #history == 0 then
        utils.notify("macSpaces", "El historial del portapapeles está vacío")
        return
    end

    local icon_map = { text = "📝", image = "🖼️", url = "🔗", other = "📋" }

    local choices = {}
    for i, entry in ipairs(history) do
        table.insert(choices, {
            text    = (icon_map[entry.type] or "📋") .. "  " .. entry.label,
            subText = os.date("%H:%M", entry.timestamp) .. "  ·  " .. (entry.type or ""),
            _index  = i,
        })
    end

    local chooser = hs.chooser.new(function(choice)
        if not choice then return end
        M.restore(choice._index)
        utils.notify("macSpaces", "Portapapeles restaurado")
    end)

    chooser:choices(choices)
    chooser:placeholderText("Buscar en historial…")
    chooser:searchSubText(true)   -- filtra también por subText (hora y tipo)
    chooser:show()
end

-- Construye el submenú del portapapeles
function M.build_submenu(on_update)
    local items = {}
    local max   = cfg.clipboard and cfg.clipboard.max_entries or 20

    table.insert(items, {
        title = string.format("Historial  %d/%d", #history, max),
        fn    = function() end,
    })
    table.insert(items, { title = "-" })

    if #history == 0 then
        table.insert(items, { title = "Sin entradas aún", fn = function() end })
        return items
    end

    -- Búsqueda via chooser nativo
    table.insert(items, {
        title = "🔍  Buscar…",
        fn    = function() M.open_chooser() end,
    })
    table.insert(items, { title = "-" })

    -- Entradas del historial
    local icon_map = { text = "📝", image = "🖼️", url = "🔗", other = "📋" }
    for i, entry in ipairs(history) do
        local time_label = os.date("%H:%M", entry.timestamp)
        local icon = icon_map[entry.type] or "📋"

        table.insert(items, {
            title = string.format("%s  %s  [%s]", icon, entry.label, time_label),
            fn    = function()
                M.restore(i)
                utils.notify("macSpaces", "Portapapeles restaurado")
            end,
        })
    end

    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Limpiar historial",
        fn    = function()
            M.clear()
            if on_update then on_update() end
        end,
    })

    return items
end

return M

-- macspaces/clipboard.lua
-- Historial del portapapeles con blocklist de apps sensibles.

local M = {}

local cfg   = require("macspaces.config")
local utils = require("macspaces.utils")

local history = {}
local watcher = nil

local function truncate(str, max)
    if not str then return "" end
    str = str:gsub("[\n\r\t]", " "):gsub("%s+", " ")
    if #str > max then return str:sub(1, max) .. "…" end
    return str
end

-- SEC-05: Verifica si la app activa está en la blocklist
local function is_ignored_app()
    local ignore = cfg.clipboard and cfg.clipboard.ignore_apps
    if not ignore or #ignore == 0 then return false end
    local app = hs.application.frontmostApplication()
    if not app then return false end
    local name = app:name()
    for _, blocked in ipairs(ignore) do
        if name == blocked then return true end
    end
    return false
end

local function capture_entry()
    if is_ignored_app() then return end
    local types = hs.pasteboard.contentTypes()
    if not types or #types == 0 then return end

    local entry = { timestamp = os.time() }
    local text = hs.pasteboard.getContents()
    if text and text ~= "" then
        entry.type = "text"; entry.content = text; entry.label = truncate(text, 60)
    elseif hs.pasteboard.readImage() then
        entry.type = "image"; entry.content = hs.pasteboard.readImage(); entry.label = "[Imagen]"
    elseif hs.pasteboard.readURL() then
        local url = hs.pasteboard.readURL()
        entry.type = "url"; entry.content = url; entry.label = truncate(url, 60)
    else
        entry.type = "other"; entry.content = nil; entry.label = "[Contenido no previsualizable]"
    end

    if #history > 0 then
        local last = history[1]
        if entry.type == "text" and last.type == "text" and last.label == entry.label then return end
        if entry.type == "image" and last.type == "image" then return end
    end

    table.insert(history, 1, entry)
    local max = cfg.clipboard and cfg.clipboard.max_entries or 20
    while #history > max do table.remove(history) end
end

function M.start(on_change)
    watcher = hs.pasteboard.watcher.new(function()
        capture_entry()
        if on_change then on_change() end
    end)
    watcher:start()
end

function M.stop()  if watcher then watcher:stop(); watcher = nil end end
function M.clear() history = {} end

function M.restore(index)
    local entry = history[index]
    if not entry then return end
    if entry.type == "text" then hs.pasteboard.setContents(entry.content)
    elseif entry.type == "image" and entry.content then hs.pasteboard.writeObjects(entry.content)
    elseif entry.type == "url" then hs.pasteboard.setContents(entry.content)
    end
end

function M.open_chooser()
    if #history == 0 then utils.notify("macSpaces", "Historial vacío"); return end
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
    end)
    chooser:choices(choices)
    chooser:placeholderText("Buscar en historial…")
    chooser:searchSubText(true)
    chooser:show()
end

function M.build_submenu(on_update)
    local items = {}
    local max = cfg.clipboard and cfg.clipboard.max_entries or 20
    table.insert(items, utils.disabled_item(string.format("Historial  %d/%d", #history, max)))
    table.insert(items, { title = "-" })

    if #history == 0 then
        table.insert(items, utils.disabled_item("Sin entradas aún"))
        return items
    end

    table.insert(items, { title = "🔍  Buscar…", fn = function() M.open_chooser() end })
    table.insert(items, { title = "-" })

    local icon_map = { text = "📝", image = "🖼️", url = "🔗", other = "📋" }
    for i, entry in ipairs(history) do
        table.insert(items, {
            title = string.format("%s  %s  [%s]", icon_map[entry.type] or "📋", entry.label, os.date("%H:%M", entry.timestamp)),
            fn = function() M.restore(i) end,
        })
    end

    table.insert(items, { title = "-" })
    table.insert(items, { title = "Limpiar historial", fn = function() M.clear(); if on_update then on_update() end end })
    return items
end

return M

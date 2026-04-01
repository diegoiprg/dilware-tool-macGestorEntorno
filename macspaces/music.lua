-- macspaces/music.lua
-- Control de Apple Music (Music.app) via AppleScript

local M = {}

local utils = require("macspaces.utils")

local MUSIC_BUNDLE_ID = "com.apple.Music"
local cache = { running = nil, playing = nil, track = nil, last_fetch = 0, ttl = 3 }

local function invalidate_cache()
    cache.running = nil; cache.playing = nil; cache.track = nil; cache.last_fetch = 0
end

function M.invalidate_cache() invalidate_cache() end

function M.is_running()
    local now = os.time()
    if cache.running ~= nil and (now - cache.last_fetch) < cache.ttl then return cache.running end
    cache.running = hs.application.get(MUSIC_BUNDLE_ID) ~= nil
    return cache.running
end

local function run_applescript(script)
    return hs.applescript(script)
end

function M.is_playing()
    local now = os.time()
    if cache.playing ~= nil and (now - cache.last_fetch) < cache.ttl then return cache.playing end
    if not M.is_running() then cache.playing = false; cache.last_fetch = now; return false end
    local ok, state = run_applescript('tell application "Music" to if player state is playing then return true\nreturn false')
    cache.playing = (ok and state == true)
    cache.last_fetch = now
    return cache.playing
end

function M.get_current_track()
    local now = os.time()
    if cache.track and (now - cache.last_fetch) < cache.ttl then return cache.track end
    if not M.is_running() then cache.track = nil; cache.last_fetch = now; return nil end

    local ok, track = run_applescript([[
        tell application "Music"
            if player state is stopped then return ""
            set currentTrack to current track
            if currentTrack is missing value then return ""
            return (name of currentTrack) & "|||" & (artist of currentTrack) & "|||" & (album of currentTrack) as text
        end tell
    ]])

    if ok and track and track ~= "" and track ~= "missing value" then
        local name, artist, album = track:match("([^|]+)|||([^|]+)|||(.+)")
        if name then
            cache.track = { name = name, artist = artist or "", album = album or "" }
            cache.last_fetch = now
            return cache.track
        end
    end
    cache.track = nil; cache.last_fetch = now
    return nil
end

function M.play()
    if not M.is_running() then utils.notify("Apple Music", "Abre la app Music primero"); return end
    run_applescript('tell application "Music" to play')
    invalidate_cache()
end

function M.pause()     run_applescript('tell application "Music" to pause');         invalidate_cache() end
function M.next()      run_applescript('tell application "Music" to next track');    invalidate_cache() end
function M.previous()  run_applescript('tell application "Music" to previous track'); invalidate_cache() end

function M.playpause()
    if M.is_playing() then M.pause() else M.play() end
end

function M.build_submenu()
    local items = {}
    local running = M.is_running()
    local playing = running and M.is_playing() or false
    local track = running and M.get_current_track() or nil

    if not running then
        table.insert(items, { title = "Abrir Apple Music", fn = function() hs.application.launchOrFocus("Music") end })
        table.insert(items, { title = "-" })
        table.insert(items, utils.disabled_item("Music.app no está abierto"))
        return items
    end

    if track and track.name ~= "" then
        table.insert(items, { title = "🎵 " .. track.name, fn = function() hs.application.launchOrFocus("Music") end })
        if track.artist ~= "" then table.insert(items, utils.info_item("🎤 ", track.artist)) end
        if track.album ~= "" then table.insert(items, utils.info_item("💿 ", track.album)) end
    else
        table.insert(items, utils.disabled_item("Sin canción"))
    end

    table.insert(items, { title = "-" })
    table.insert(items, { title = playing and "⏸ Pausar" or "▶ Reproducir", fn = M.playpause })
    table.insert(items, { title = "⏭ Siguiente", fn = M.next })
    table.insert(items, { title = "⏮ Anterior",  fn = M.previous })
    table.insert(items, { title = "-" })
    table.insert(items, { title = "Abrir Music.app", fn = function() hs.application.launchOrFocus("Music") end })
    return items
end

return M

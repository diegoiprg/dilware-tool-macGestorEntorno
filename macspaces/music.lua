-- macspaces/music.lua
-- Control de Apple Music (Music.app) via hs.itunes

local M = {}

local utils = require("macspaces.utils")

function M.is_running()
    return hs.itunes.isRunning()
end

function M.is_playing()
    if not M.is_running() then return false end
    local ok, state = pcall(function() return hs.itunes.isPlaying() end)
    return ok and state
end

function M.get_current_track()
    if not M.is_running() then return nil end

    local ok, track = pcall(function()
        return {
            name   = hs.itunes.getCurrentTrack(),
            artist = hs.itunes.getCurrentArtist(),
            album  = hs.itunes.getCurrentAlbum(),
            state  = hs.itunes.getPlayerState(),
        }
    end)

    if ok and track then
        return track
    end
    return nil
end

function M.display_info()
    local track = M.get_current_track()
    if not track or not track.name then
        return "Music"
    end

    local info = track.name
    if track.artist then
        info = info .. " — " .. track.artist
    end
    return info
end

function M.play()
    if not M.is_running() then
        utils.notify("Apple Music", "Abre la app Music primero")
        return
    end
    local ok, err = pcall(function() hs.itunes.play() end)
    if not ok then
        utils.log("[ERROR] Music.play: " .. tostring(err))
    end
end

function M.pause()
    local ok, err = pcall(function() hs.itunes.pause() end)
    if not ok then
        utils.log("[ERROR] Music.pause: " .. tostring(err))
    end
end

function M.playpause()
    if M.is_playing() then
        M.pause()
    else
        M.play()
    end
end

function M.next()
    local ok, err = pcall(function() hs.itunes.next() end)
    if not ok then
        utils.log("[ERROR] Music.next: " .. tostring(err))
    end
end

function M.previous()
    local ok, err = pcall(function() hs.itunes.previous() end)
    if not ok then
        utils.log("[ERROR] Music.previous: " .. tostring(err))
    end
end

function M.build_submenu()
    local items = {}

    local track = M.get_current_track()
    local running = M.is_running()
    local playing = M.is_playing()

    if not running then
        table.insert(items, {
            title = "Abrir Apple Music",
            fn = function()
                hs.application.launchOrFocus("Music")
            end,
        })
        table.insert(items, { title = "-" })
        table.insert(items, { title = "Music.app no está abierto", fn = function() end })
        return items
    end

    if track and track.name then
        local track_info = track.name
        if track.artist then
            track_info = track_info .. "\n" .. track.artist
        end
        if track.album then
            track_info = track_info .. "\n" .. track.album
        end

        table.insert(items, {
            title = track_info,
            fn = function() hs.application.launchOrFocus("Music") end,
        })
    else
        table.insert(items, { title = "Sin canción", fn = function() end })
    end

    table.insert(items, { title = "-" })

    table.insert(items, {
        title = playing and "⏸ Pausar" or "▶ Reproducir",
        fn = M.playpause,
    })

    table.insert(items, {
        title = "⏭ Siguiente",
        fn = M.next,
    })

    table.insert(items, {
        title = "⏮ Anterior",
        fn = M.previous,
    })

    table.insert(items, { title = "-" })

    table.insert(items, {
        title = "Abrir Music.app",
        fn = function() hs.application.launchOrFocus("Music") end,
    })

    return items
end

return M

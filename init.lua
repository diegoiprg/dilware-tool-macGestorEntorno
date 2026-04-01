-- Copyright (C) 2025 - Diego Iparraguirre
-- Software libre bajo GNU General Public License v3.0 o posterior.
-- https://github.com/diegoiprg/dilware-tool-macSpaces

-- ─────────────────────────────────────────────
-- Punto de entrada de macSpaces
-- Carga módulos y arranca el sistema.
-- ─────────────────────────────────────────────

local hs_dir = os.getenv("HOME") .. "/.hammerspoon"
local hs_lua_path = hs_dir .. "/?.lua"
if not package.path:find(hs_lua_path, 1, true) then
    package.path = hs_lua_path .. ";" ..
                   hs_dir .. "/?/init.lua;" ..
                   package.path
end

local utils      = require("macspaces.utils")
local cfg        = require("macspaces.config")
local hotkeys    = require("macspaces.hotkeys")
local clipboard  = require("macspaces.clipboard")
local network    = require("macspaces.network")
local vpn        = require("macspaces.vpn")
local bluetooth  = require("macspaces.bluetooth")
local browsers   = require("macspaces.browsers")
local music      = require("macspaces.music")
local battery    = require("macspaces.battery")
local menu       = require("macspaces.menu")
local focus_menu = require("macspaces.focus_menu")

local ok, err = pcall(function()
    if type(cfg.VERSION) ~= "string" or #cfg.VERSION == 0 then error("VERSION inválida en config") end
    if type(cfg.delay) ~= "table" then error("delay debe ser una tabla") end
    if type(cfg.delay.short) ~= "number" or cfg.delay.short <= 0 then error("delay.short debe ser un número positivo") end
    if type(cfg.profile_order) ~= "table" or #cfg.profile_order == 0 then error("profile_order debe ser una tabla no vacía") end
    if type(cfg.profiles) ~= "table" then error("profiles debe ser una tabla") end
end)

if not ok then
    utils.log("[ERROR] Validación de config falló: " .. tostring(err))
    hs.notify.new({ title = "macSpaces Error", informativeText = "Configuración inválida: " .. tostring(err) }):send()
    return
end

utils.clear_log()
utils.log("[INFO] macSpaces v" .. cfg.VERSION .. " iniciado")

clipboard.start()
network.refresh()
vpn.refresh()
hotkeys.register(function() menu.build() end)
menu.init()
focus_menu.init()

-- Pre-calentar cachés costosos en segundo plano
local function prewarm_caches()
    bluetooth.devices()
    browsers.installed()
    browsers.current()
    battery.has_battery()
    music.is_running()
end

hs.timer.doAfter(1, prewarm_caches)
local prewarm_timer = hs.timer.doEvery(30, prewarm_caches)

-- Limpieza al cerrar, reiniciar o recargar Hammerspoon.
-- Restaura el estado del sistema para que no queden cambios huérfanos.
hs.shutdownCallback = function()
    local pomodoro     = require("macspaces.pomodoro")
    local presentation = require("macspaces.presentation")
    local breaks       = require("macspaces.breaks")

    -- Restaurar estado del sistema (DND, Dock, escritorio)
    if pomodoro.is_active()     then pomodoro.stop() end
    if presentation.is_active() then presentation.toggle() end

    -- Liberar recursos
    focus_menu.destroy()
    menu.destroy()
    clipboard.stop()
    hotkeys.unregister()
    if breaks.is_enabled() then breaks.disable() end
    if prewarm_timer then prewarm_timer:stop() end

    utils.log("[INFO] macSpaces: limpieza completada")
end

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

local utils     = require("macspaces.utils")
local cfg       = require("macspaces.config")
local hotkeys   = require("macspaces.hotkeys")
local clipboard = require("macspaces.clipboard")
local network   = require("macspaces.network")
local vpn       = require("macspaces.vpn")
local menu      = require("macspaces.menu")

local ok, err = pcall(function()
    if type(cfg.VERSION) ~= "string" or #cfg.VERSION == 0 then
        error("VERSION inválida en config")
    end
    if type(cfg.delay) ~= "table" then
        error("delay debe ser una tabla")
    end
    if type(cfg.delay.short) ~= "number" or cfg.delay.short <= 0 then
        error("delay.short debe ser un número positivo")
    end
    if type(cfg.profile_order) ~= "table" or #cfg.profile_order == 0 then
        error("profile_order debe ser una tabla no vacía")
    end
    if type(cfg.profiles) ~= "table" then
        error("profiles debe ser una tabla")
    end
end)

if not ok then
    utils.log("[ERROR] Validación de config falló: " .. tostring(err))
    hs.notify.new({
        title = "macSpaces Error",
        informativeText = "Configuración inválida: " .. tostring(err)
    }):send()
    return
end

utils.clear_log()
-- BUG-01: Versión unificada desde cfg.VERSION (fuente única de verdad)
utils.log("[INFO] macSpaces v" .. cfg.VERSION .. " iniciado")

clipboard.start()
network.refresh()
vpn.refresh()
hotkeys.register(function() menu.build() end)
menu.init()

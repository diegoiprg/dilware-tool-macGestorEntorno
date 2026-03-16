-- Copyright (C) 2025 - Diego Iparraguirre
-- Software libre bajo GNU General Public License v3.0 o posterior.
-- https://github.com/diegoiprg/dilware-tool-macSpaces

-- ─────────────────────────────────────────────
-- Punto de entrada de macSpaces v2.0.0
-- Carga módulos y arranca el sistema.
-- ─────────────────────────────────────────────

-- Agregar la carpeta macspaces/ al path de require de Lua
local hs_dir = os.getenv("HOME") .. "/.hammerspoon"
package.path = hs_dir .. "/?.lua;" ..
               hs_dir .. "/?/init.lua;" ..
               package.path

local utils    = require("macspaces.utils")
local cfg      = require("macspaces.config")
local hotkeys  = require("macspaces.hotkeys")
local menu     = require("macspaces.menu")

-- Limpiar log e iniciar
utils.clear_log()
utils.log("[INFO] macSpaces v" .. cfg.VERSION .. " iniciado")

-- Registrar hotkeys globales
hotkeys.register(function() menu.build() end)

-- Construir menú inicial
menu.build()

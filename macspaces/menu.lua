-- macspaces/menu.lua
-- Construcción y gestión del menú de la barra de estado.

local M = {}

local cfg      = require("macspaces.config")
local profiles = require("macspaces.profiles")
local browsers = require("macspaces.browsers")
local audio    = require("macspaces.audio")
local battery  = require("macspaces.battery")
local history  = require("macspaces.history")
local pomodoro = require("macspaces.pomodoro")
local breaks   = require("macspaces.breaks")

local menubar = hs.menubar.new()

-- ─────────────────────────────────────────────
-- Construcción del menú
-- ─────────────────────────────────────────────

local function refresh()
    M.build()
end

function M.build()
    local items = {}

    -- ── Perfiles ──────────────────────────────
    for _, key in ipairs(cfg.profile_order) do
        local profile = cfg.profiles[key]
        if profile then
            local active  = profiles.is_active(key)
            local label   = (active and "◉  " or "○  ") .. profile.name
            local action  = active and "  —  Cerrar" or "  —  Activar"

            table.insert(items, {
                title = label .. action,
                fn    = function()
                    if active then
                        -- Registrar sesión antes de cerrar
                        local st = profiles.get_state(key)
                        if st and st.started_at then
                            history.record_session(key, st.started_at)
                        end
                        profiles.deactivate(key, refresh)
                    else
                        profiles.activate(key, function()
                            -- Cambiar navegador vinculado al perfil
                            if profile.browser then
                                local current = browsers.current()
                                if current ~= profile.browser then
                                    browsers.set_default(profile.browser)
                                end
                            end
                            refresh()
                        end)
                    end
                end,
            })
        end
    end

    -- ── Pomodoro (tiempo restante si activo) ──
    if pomodoro.is_active() then
        local label = pomodoro.time_label()
        if label then
            table.insert(items, { title = "-" })
            table.insert(items, {
                title    = label .. "  —  Ciclo " .. pomodoro.cycles_completed(),
                disabled = true,
            })
        end
    end

    -- ── Navegador predeterminado ───────────────
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Navegador predeterminado",
        menu  = browsers.build_submenu(),
    })

    -- ── Audio ─────────────────────────────────
    table.insert(items, {
        title = "Salida de audio",
        menu  = audio.build_submenu(),
    })

    -- ── Batería (solo si aplica) ───────────────
    local bat = battery.status_label()
    if bat then
        table.insert(items, {
            title    = bat,
            disabled = true,
        })
    end

    -- ── Pomodoro ──────────────────────────────
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Pomodoro",
        menu  = pomodoro.build_submenu(refresh),
    })

    -- ── Descanso activo ───────────────────────
    table.insert(items, {
        title = "Descanso activo",
        menu  = breaks.build_submenu(refresh),
    })

    -- ── Historial ─────────────────────────────
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Historial de hoy",
        menu  = history.build_submenu(),
    })

    -- ── Utilidades ────────────────────────────
    table.insert(items, { title = "-" })
    table.insert(items, {
        title = "Ver registro",
        fn    = function()
            local log_path = os.getenv("HOME") .. "/.hammerspoon/debug.log"
            hs.execute("open " .. log_path)
        end,
    })
    table.insert(items, {
        title = "Recargar configuración",
        fn    = hs.reload,
    })

    -- Ícono y menú
    menubar:setTitle(cfg.menu_icon)
    menubar:setMenu(items)
end

function M.destroy()
    if menubar then menubar:delete() end
end

return M

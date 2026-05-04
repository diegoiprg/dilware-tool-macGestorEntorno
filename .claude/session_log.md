# Session Log — dilware-tool-macGestorEntorno

> Fuente de verdad de sesión compartida entre Claude Code, Gemini CLI y Kiro.
> Formato: session-log-spec v1.0 — no editar manualmente salvo emergencia.
---
<!-- CHECKPOINT id="20260503-225600-claude" -->
## Checkpoint — 2026-05-03 22:56 | claude | dil-macmini

### Trabajado
- Diagnóstico del parpadeo del banner del overlay: causa raíz = `destroy_canvas()` + recreación completa en cada tick de 1s
- Fix en `focus_overlay.lua`: separación en `build_canvas()` (construcción completa, solo en cambio estructural) y `patch_canvas()` (actualización in-place de color + texto sin destruir el canvas)
- El canvas ahora persiste entre ticks; solo se reconstruye si cambia el número de filas
- Recarga de Hammerspoon aplicada vía `open -g hammerspoon://reload`

### Decisiones
- **patch_canvas en lugar de destroy+rebuild**: el canvas de Hammerspoon soporta mutación directa de propiedades — más eficiente y elimina el parpadeo sin cambiar la lógica de `get_entries()` ni `sysmon`
- **Reconstrucción estructural conservada**: cuando cambia el número de filas (ej. activar Pomodoro), se reconstruye completo — correcto porque cambian frames y posiciones

### Contexto
- Frecuencia de actualización de datos: CPU/RAM/GPU cada 2s (`CACHE_TTL`), red/conectividad cada 10s (`NET_CHECK_TTL`), overlay redibuja cada 1s
- La "info estática" que reportó el usuario es por diseño (2s de cache) — no es un bug
<!-- END CHECKPOINT id="20260503-225600-claude" -->

<!-- SESSION id="20260502-230100-claude" status="closed" -->
## Sesión — 2026-05-02 21:30 → 23:03 | claude | dil-macmini

### Resumen
Sesión enfocada en enriquecer el overlay y el menú de Hammerspoon con métricas del sistema (CPU/RAM/GPU, red, batería) y actualización del módulo de cuotas de Claude para soportar las nuevas cuotas de la plataforma. Se creó el módulo `sysmon.lua` como fuente de verdad de métricas del sistema, integrado en overlay, menú principal y sección RED.

### Decisiones
- **Semáforo por ítem, no por fila**: el color de fondo de la fila sysmon es siempre neutro; cada métrica tiene su propio color — más informativo, menos alarmista
- **Red fuera del banner**: cambia poco en tiempo real, genera ruido; vive solo en el menú RED
- **Batería solo en MacBook**: `has_battery()` como gate; Mac Mini muestra nada
- **`sysmon` como fuente única**: `net_state()` y `fmt_net()` expuestos para que `network.lua` no duplique lógica
- **Cuotas nuevas como pendiente**: Claude Code aún no emite `seven_day_sonnet`, `seven_day_design`, `daily` en el hook de statusline — se muestran como "(pendiente)" y el código ya está listo para recibirlas
- **Íconos ≋/⌁** para WIFI/CABLE — pendiente confirmar render en el banner real

### Cambios
- `macspaces/sysmon.lua`: módulo nuevo — CPU (async), RAM (vm_stat), GPU (ioreg), conectividad (ping 1.1.1.1), tipo conexión (WIFI/CABLE via networksetup), VPN (scutil + utun), batería; styledtext con semáforo por ítem; expone `net_state()`, `fmt_net()`, `build_submenu()`
- `macspaces/claude.lua`: soporte para 5 cuotas; helper `quota_rows()`; campos pendientes marcados con TODO
- `macspaces/focus_overlay.lua`: integración sysmon; fix styledtext userdata; colores sysmon_ok/warn/crit; fila sysmon siempre visible al final
- `macspaces/menu.lua`: sección SISTEMA con ⬡ Monitor y 🔋 Batería
- `macspaces/network.lua`: submenú RED con tipo conexión, VPN, velocidad ↑↓ desde sysmon
- `~/.claude/statusline.sh`: captura automática de campos nuevos cuando Claude Code los emita
- `~/.hammerspoon/macspaces/sysmon.lua`: symlink creado manualmente

### Pendientes
- [ ] Confirmar render de ≋ y ⌁ en el banner (usuario pendiente de reporte)
- [ ] Cuando Claude Code emita las nuevas cuotas: quitar marca "(pendiente)" en `claude.lua`
- [ ] Release: bump semver + changelog + push

### Contexto
- El symlink de `sysmon.lua` se crea manualmente — `install.sh` no lo incluye aún; agregar en próxima sesión
- Detección WIFI/CABLE compara IP de `networksetup -getinfo Wi-Fi` con la IP de la interfaz primaria — funciona en MacBook, en Mac Mini siempre devuelve "cable" (correcto)
- `install.sh` deberá incluir el symlink de sysmon.lua en próxima actualización
<!-- END SESSION id="20260502-230100-claude" status="closed" -->

<!-- CHECKPOINT id="20260423-231627-claude" -->
## Checkpoint — 2026-04-23 23:16 | claude | dil-macmini

### Trabajado
- Repo renombrado en GitHub de `dilware-tool-macGestorEntorno` a `dilware-tool-utilitario`
- Remote local actualizado: `git@github.com:diegoiprg/dilware-tool-utilitario.git`
- `CLAUDE.md` del workspace actualizado con nuevo nombre de repo y carpeta (`tool-utilitario/`)
<!-- END CHECKPOINT id="20260423-231627-claude" -->

<!-- ARCHIVE -->
**v2.14.0** (2026-04-19, kiro): gemini.lua auto-refresh, overlay inferior-izquierda, install.sh reescrito, config_local.lua, fix symlinks. Push a main.
**v2.14.0** (2026-04-19, gemini): sesión interrumpida sin cierre — sin cambios relevantes.
<!-- END ARCHIVE -->

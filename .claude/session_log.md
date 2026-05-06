# Session Log

<!-- SESSION id="20260506-130500-kiro" status="closed" -->
## Sesión — 2026-05-06 13:05 → 13:14 | kiro | dil-macmini

### Resumen
Auditoría de métricas del overlay. RAM tenía bug crítico (vm_stat reportaba ~95-100%), corregido a memory_pressure. CPU, GPU, Red, VPN, Batería verificados correctos. Release v2.15.0.

### Completado
- fix(sysmon): RAM `vm_stat` → `memory_pressure` (de ~95% falso a ~60% real)
- audit: CPU (hs.host.cpuUsage), GPU (ioreg), Red (netstat delta), VPN (scutil), Batería (hs.battery) — todos correctos
- release: v2.15.0 bump + changelog + push

### Decisiones
- `memory_pressure` es la fuente canónica de RAM en macOS (= Activity Monitor)
- Bump minor (2.15.0) por features acumuladas desde 2.14.1

### Pendientes
- [ ] Symlink de `sysmon.lua` en `install.sh`

<!-- END SESSION id="20260506-130500-kiro" status="closed" -->

<!-- SESSION id="20260506-000000-kiro" status="closed" -->
## Sesión — 2026-05-06 00:00 → 00:09 | kiro | dil-macmini

### Resumen
Unificación del overlay: Mac Mini ahora usa el mismo layout de alas en la menu bar que MacBook (sin gap del notch). Fix de discos fantasma en el panel.

### Completado
- feat(overlay): Mac Mini usa layout de alas CPU%|RAM% en menu bar (igual que MacBook, sin gap del notch)
- fix(overlay): filtrar snapshots de Time Machine y volúmenes Xcode Simulator del panel de discos
- refactor(overlay): eliminado render_classic, get_all_entries, drag y variables asociadas — código muerto
- docs(adn): actualizado para reflejar layout unificado (alas en ambos dispositivos)

### Decisiones
- Gap entre alas: 220px (notch) en MacBook vs 6px en Mac Mini — pills prácticamente juntas
- Filtro de discos: `grep -v '.timemachine' | grep -v 'CoreSimulator'`

### Pendientes
- [ ] Release: bump semver + changelog + push (cambios sin commitear)
- [ ] Verificar hover del panel en Mac Mini funciona correctamente con uso prolongado
- [ ] Pendiente de sesión anterior: symlink de `sysmon.lua` en `install.sh`

<!-- END SESSION id="20260506-000000-kiro" status="closed" -->

<!-- SESSION id="20260505-205000-kiro" status="closed" -->
## Sesión — 2026-05-05 20:50 → 21:25 | kiro | dil-macbook

### Resumen
Auditoría del menú y overlay contra Apple HIG + biblia del proyecto. Corrección de documentación desactualizada (2 menús → 1 menú unificado) y dos bugs en el overlay.

### Completado
- Auditoría menú vs Apple HIG: APROBADO — cumple template image, checkmarks, separadores, atajos visibles, submenús
- docs: README, funcional, ux-hig, arquitectura, seguridad, modulos, todo — actualizados a 1 menú unificado + overlay
- docs: eliminadas todas las referencias a `overlay_pos.json` (persistencia no deseada)
- docs: Claude/Gemini documentados como "solo overlay" (sin submenú en menú principal)
- docs: Apple Music documentado como módulo sin presencia en menú
- fix(overlay): `C_NET` no definida — tráfico de red siempre mostraba color dim
- fix(overlay): disco del sistema usaba `df -g` (GiB, solo volumen Data) — cambiado a `diskutil info /` (GB base 1000, container completo, consistente con widget Apple)
- fix(overlay): discos externos cambiados de `df -g` a `df -H` (base 1000)

### Decisiones
- Persistencia de posición del overlay descartada por decisión del usuario — posición en memoria es suficiente
- `C_NET` definida como cyan claro (0.40, 0.80, 0.95) — diferenciada de `C_BLUE`

### Pendientes
- [ ] Verificar overlay tras ⌘R — disco debe mostrar ~287 de 494 GB (58%)
- [ ] Tráfico de red: confirmar que `C_NET` se ve correctamente cuando hay actividad
- [ ] Release pendiente con estos fixes

<!-- END SESSION id="20260505-205000-kiro" status="closed" -->

## SESSION 2026-05-05 14:58–19:57 | Kiro | dil-macbook

### Completado
- fix(profiles): PWAs de Edge no abrían en MacBook — bundle IDs en config_local.lua
- feat(overlay): rediseño completo para MacBook — alas CPU/RAM flanqueando notch + panel hover
- Panel hover: GPU, discos, red, batería, Claude, descanso, pomodoro
- UX unificada: labels blancos, valores con semáforo, separadores gris, MAYÚSCULAS
- feat(menu): unificado en un solo ícono (eliminado menú auxiliar ◎)
- chore: eliminados Música y Presentación del menú (sin uso)
- docs: creado docs/adn.md — biblia del proyecto con estándares UX/UI y SEMVER

### Versión final: 2.16.1

### Pendientes
- Color dinámico de tráfico de red no funciona (datos llegan como 0 por timing de sysmon)
- Verificar overlay en Mac Mini mañana (banner clásico sin cambios)
- Error preexistente en dnd.lua:15 (`hs.host.focus` API cambió) — no bloquea pero aparece al reload — dilware-tool-macGestorEntorno

> Fuente de verdad de sesión compartida entre Claude Code, Gemini CLI y Kiro.
> Formato: session-log-spec v1.0 — no editar manualmente salvo emergencia.
---
<!-- SESSION id="20260505-004200-claude" status="closed" -->
## Sesión — 2026-05-05 00:00 → 00:43 | claude | dil-macmini

### Resumen
Sesión enfocada en el banner overlay y el módulo de cuotas de Claude. Se quitó Gemini del banner (conservado en el menú), se limpió el submenú de Claude, se rediseñó la fila Claude del banner con styledtext coloreado por segmento al estilo sysmon, y se corrigieron dos bugs: color blanco por uso incorrecto de `setStyle`, y texto truncado por `patch_canvas` que no actualizaba frames al cambiar el ancho.

### Decisiones
- **Gemini fuera del banner, no del menú**: quita ruido sin perder el trabajo — reactiva en `focus_overlay.lua` cuando funcione
- **Cuotas opcionales silenciosas**: sin datos del hook = sin fila. Aparecen automáticamente cuando Claude Code las emita
- **Color en constructor styledtext**: `hs.styledtext.new(text, {color=...})` es el patrón correcto; `setStyle()` posterior con rango `-1` es inestable en Hammerspoon
- **Fondo neutro siempre en fila Claude**: estado comunicado por color del texto, no por fondo de la píldora
- **Rebuild canvas por ancho además de por count**: `patch_canvas` no actualiza frames — si el contenido crece el texto queda truncado e invisible; solución: reconstruir cuando `inner_w` cambia

### Cambios
- `macspaces/focus_overlay.lua`: Gemini removido; fila Claude usa `row.bg`; `last_inner_w` como segunda condición de rebuild
- `macspaces/menu.lua`: Gemini conservado (import + ítem)
- `macspaces/claude.lua`: `overlay_rows()` con styledtext segmentado y coloreado; fondo `ROW_BG` neutro; submenú sin filas fijas `(pendiente)`; TODOs eliminados
- `~/.claude/statusline.sh`: comentarios corregidos; captura defensiva de campos opcionales intacta

### Pendientes
- [ ] Confirmar visualmente que colores y texto completo del banner Claude se ven correctamente
- [ ] Cuando Claude Code emita cuotas adicionales: aparecerán automáticamente sin cambios de código
- [ ] Agregar symlink de `sysmon.lua` a `install.sh`
- [ ] Release: bump semver + changelog + push

### Contexto
- Payload real del hook `statusLine` confirmado: solo `five_hour` y `seven_day` emitidos por Claude Code
- El symlink `~/.hammerspoon/macspaces/sysmon.lua` es manual — no está en `install.sh`
- `~/.claude/statusline.sh.bak` existe como backup
<!-- END SESSION id="20260505-004200-claude" status="closed" -->

<!-- SESSION id="20260505-003800-claude" status="closed" -->
## Sesión — 2026-05-03 22:56 → 23:01 | claude | dil-macmini

### Resumen
Fix del parpadeo del banner overlay: separación de `build_canvas()` y `patch_canvas()`.

### Decisiones
- **patch_canvas en lugar de destroy+rebuild**: canvas de Hammerspoon soporta mutación directa — elimina parpadeo
- **Reconstrucción estructural conservada**: solo cuando cambia el número de filas

### Contexto
- CPU/RAM/GPU cada 2s, red cada 10s, overlay redibuja cada 1s — la "info estática" es por diseño
<!-- END SESSION id="20260505-003800-claude" status="closed" -->

<!-- ARCHIVE -->
**v2.14.0** (2026-05-02, claude): sysmon.lua creado con CPU/RAM/GPU/red/batería; integrado en overlay, menú y RED; claude.lua actualizado para nuevas cuotas.
**v2.14.0** (2026-04-23, claude): repo renombrado a dilware-tool-utilitario, remote local actualizado, CLAUDE.md actualizado.
**v2.14.0** (2026-04-19, kiro): gemini.lua auto-refresh, overlay inferior-izquierda, install.sh reescrito, config_local.lua, fix symlinks. Push a main.
**v2.14.0** (2026-04-19, gemini): sesión interrumpida sin cierre — sin cambios relevantes.
<!-- END ARCHIVE -->

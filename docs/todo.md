# TODO — macSpaces v2.6.0

Pendientes consolidados: seguridad, UX/HIG, rendimiento, bugs y mejoras.
Generado: 2026-04-01. Actualizado: 2026-04-01.

---

## ✅ Completados

### BUG-01: Versión inconsistente entre archivos
- **Acción**: `init.lua` ya no tiene versión hardcodeada; usa `cfg.VERSION` como fuente única.
- **Archivos**: `init.lua`, `config.lua`, `README.md` — todos en v2.6.0.

### SEC-01: HTTP sin cifrar para ip-api.com
- **Acción**: migrado a `https://ipapi.co/json/` (HTTPS gratuito) en `network.lua` y `vpn.lua`.
- **Respuesta normalizada** para mantener compatibilidad con el resto del código.

### SEC-02: Instalación `curl | bash` sin verificación
- **Acción**: `README.md` documenta instalación manual como método principal con advertencia en script.

### SEC-03: Log sin permisos restrictivos ni rotación
- **Acción**: `utils.lua` ahora establece permisos `0600`, rota por tamaño (max 1MB), ofusca IPs.

### SEC-04: Historial JSON sin permisos restrictivos
- **Acción**: `history.lua` establece permisos `0600` al crear/escribir.

### SEC-05: Portapapeles captura contenido sensible sin filtro
- **Acción**: `clipboard.lua` filtra por `cfg.clipboard.ignore_apps`. Blocklist en `config.lua`.

### UX-01: Ícono del menú es emoji, no template image
- **Acción**: `menu.lua` busca `~/.hammerspoon/macspaces_icon.png` como template image. Fallback a emoji.
- **Pendiente**: el usuario debe crear/proveer la imagen 18×18pt monocromática.

### UX-02: Sin feedback visual claro de perfil activo
- **Acción**: `menu.lua` usa `checked = true/false` nativo + indicador textual `● / ○` + tiempo activo inline.

### UX-03: Menú demasiado largo
- **Acción**: `menu.lua` reorganizado en submenús semánticos: Entorno, Dispositivos, Red, Productividad, Historial, Sistema. ~8 ítems de primer nivel.

### UX-04: Inconsistencia visual SF Symbols vs emojis
- **Acción**: unificado a emojis en todo el menú (más compatible con Hammerspoon).

### UX-05: Atajos de teclado no visibles en el menú
- **Acción**: `menu.lua` muestra `⌘⌥1` / `⌘⌥2` junto al nombre del perfil.

### UX-06: Pomodoro sin countdown en la menubar
- **Acción**: `pomodoro.lua` expone `menubar_label()` y `set_menubar_updater()`. `menu.lua` actualiza el título cada 60s.

### UX-07: Sin confirmación al desactivar perfil
- **Acción**: `profiles.lua` usa `hs.dialog.blockAlert` si `profile.confirm_deactivate = true`. Configurable en `config.lua`.

### UX-08: Navegador global, no contextual
- **Acción**: `profiles.lua` guarda `prev_browser` al activar y lo restaura al desactivar.

### UX-09: Batería sin submenú
- **Acción**: `battery.lua` tiene `build_submenu()` con porcentaje, estado, ciclos, tiempo restante.

### UX-10: Idioma mezclado en la UI
- **Acción**: "Music" renombrado a "Música" en el menú. UI consistente en español.

### UX-02b: Ítems no accionables parecen clicables
- **Acción**: `utils.disabled_item()` creado. Todos los módulos usan `disabled = true` para ítems informativos; `info_item` para los que copian al portapapeles.

### PERF-01: Demora al abrir el menú
- **Acción**: `vpn.is_active()` cacheado con TTL 10s. Bluetooth TTL aumentado a 120s. `battery.has_battery()` cacheado permanentemente.

### DOCS-01: Sincronizar documentación con código
- **Acción**: `README.md` con versión correcta v2.6.0 y tabla de documentación.

---

## 🟢 Pendientes (baja prioridad / futuro)

### ARCH-01: Coordinación por timers, no por eventos
- **Archivo**: `profiles.lua`
- **Problema**: delays fijos para lanzar/mover apps
- **Acción**: investigar `hs.application.watcher` para detectar cuándo la app está lista

### ARCH-02: Sin hot-reload de config
- **Archivo**: `init.lua`
- **Acción**: evaluar viabilidad de recargar solo `config.lua` sin perder estado

### ARCH-03: Monopantalla
- **Archivo**: `profiles.lua:47`
- **Acción**: documentar limitación; evaluar soporte multi-monitor en versión futura

### ARCH-04: Estado volátil
- **Acción**: persistir estado de Pomodoro y portapapeles en archivo JSON

### SEC-06: Shell commands hardcodeados (bajo riesgo)
- **Acción**: documentar como regla de desarrollo que nunca se concatene input del usuario en `hs.execute()`

### SEC-07: AppleScript sin sandboxing (bajo riesgo)
- **Acción**: mantener scripts mínimos; documentar que no se extienda con input del usuario

---

## 💎 Mejoras "premium" (experiencia de usuario — futuro)

### PREM-01: Menú minimalista y enfocado
- ✅ Implementado en UX-03

### PREM-02: Feedback visual inmediato en perfiles
- ✅ Implementado en UX-02

### PREM-03: Ícono nativo de menubar
- ✅ Parcialmente implementado en UX-01 (falta crear la imagen)

### PREM-04: Transiciones suaves
- Investigar animaciones en notificaciones y feedback sonoro

### PREM-05: Consistencia visual total
- ✅ Implementado en UX-04

### PREM-06: Portapapeles inteligente
- ✅ Blocklist implementado en SEC-05
- Pendiente: auto-expiración configurable

### PREM-07: Historial enriquecido
- Gráfico semanal, exportar CSV, resumen diario via notificación

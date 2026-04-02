# TODO — macSpaces v2.8.0

Pendientes consolidados: seguridad, UX/HIG, rendimiento, bugs y mejoras.
Generado: 2026-04-01. Actualizado: 2026-04-01.

---

## ✅ Completados

### BUG-01: Versión inconsistente entre archivos
- `init.lua` usa `cfg.VERSION` como fuente única.

### SEC-01: HTTP sin cifrar para ip-api.com
- Migrado a `https://ipapi.co/json/` (HTTPS) en `network.lua` y `vpn.lua`.

### SEC-02: Instalación `curl | bash` sin verificación
- `README.md` documenta instalación manual como método principal.

### SEC-03: Log sin permisos restrictivos ni rotación
- `utils.lua`: permisos `0600`, rotación por tamaño (max 1MB), ofuscación de IPs.

### SEC-04: Historial JSON sin permisos restrictivos
- `history.lua`: permisos `0600` al crear/escribir.

### SEC-05: Portapapeles captura contenido sensible sin filtro
- `clipboard.lua` filtra por `cfg.clipboard.ignore_apps`.

### UX-01: Ícono del menú es emoji, no template image
- `menu.lua` busca `~/.hammerspoon/macspaces_icon.png` como template image. Fallback a emoji.

### UX-02: Sin feedback visual claro de perfil activo
- `checked = true/false` nativo + indicador `● / ○` + tiempo activo inline.

### UX-03: Menú demasiado largo
- Menú principal reorganizado en submenús semánticos (~8 ítems de primer nivel).
- Pomodoro, descanso y presentación separados en menú de enfoque independiente.

### UX-04: Inconsistencia visual SF Symbols vs emojis
- Unificado a emojis en todo el menú.

### UX-05: Atajos de teclado no visibles en el menú
- `⌘⌥1` / `⌘⌥2` junto al nombre del perfil.

### UX-06: Pomodoro sin countdown en la menubar
- Countdown visible en el ícono del menú de enfoque (`🍅 23m`).
- Overlay flotante persistente con tiempo restante actualizado cada segundo.

### UX-07: Sin confirmación al desactivar perfil
- `hs.dialog.blockAlert` si `profile.confirm_deactivate = true`.

### UX-08: Navegador global, no contextual
- `profiles.lua` guarda/restaura navegador previo al activar/desactivar.

### UX-09: Batería sin submenú
- `battery.lua` con submenú: porcentaje, estado, ciclos, tiempo restante.

### UX-10: Idioma mezclado en la UI
- UI consistente en español.

### UX-02b: Ítems no accionables parecen clicables
- `utils.disabled_item()` con `disabled = true` en todos los módulos.

### PERF-01: Demora al abrir el menú
- `setMenu(items)` con tabla pre-construida (apertura instantánea).
- Reconstrucción automática cada 5s en segundo plano.
- Pre-calentamiento de cachés costosos cada 30s (bluetooth, browsers, music, battery).
- Cachés con TTL: VPN 10s, Bluetooth 120s, battery permanente.

### PERF-02: Menú de enfoque separado
- `focus_menu.lua`: menú independiente con Pomodoro, descanso activo, presentación.
- `focus_overlay.lua`: banner flotante persistente con estado de enfoque.

### UX-11: Incentivar descanso activo
- Activado por defecto en `config.lua`.
- Tiempo sin descanso visible en overlay (`⏱ 12:34 sin descanso`).
- Datos educativos rotativos en notificaciones (AAO, OSHA, Mayo Clinic, Cornell, AHA).

### UX-12: Tips educativos en Pomodoro
- Datos sobre productividad y neurociencia en cada notificación de fase (Cirillo, Baumeister, Dehaene, DeMarco).

### DOCS-01: Sincronizar documentación con código
- Todos los docs actualizados con estado actual del código.

---

## 🟢 Pendientes (baja prioridad / futuro)

### ARCH-01: Coordinación por timers, no por eventos
- Investigar `hs.application.watcher` para detectar cuándo la app está lista.

### ARCH-02: Sin hot-reload de config
- Evaluar viabilidad de recargar solo `config.lua` sin perder estado.

### ARCH-03: Monopantalla
- Documentar limitación; evaluar soporte multi-monitor.

### ARCH-04: Estado volátil
- Persistir estado de Pomodoro y portapapeles en archivo JSON.

### SEC-06: Shell commands hardcodeados (bajo riesgo)
- Documentar como regla de desarrollo.

### SEC-07: AppleScript sin sandboxing (bajo riesgo)
- Mantener scripts mínimos.

### PREM-04: Transiciones suaves
- Investigar animaciones y feedback sonoro.

### PREM-06: Portapapeles — auto-expiración configurable

### PREM-07: Historial enriquecido
- Gráfico semanal, exportar CSV, resumen diario.

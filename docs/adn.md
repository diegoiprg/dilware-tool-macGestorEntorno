# macSpaces — ADN del Proyecto

Documento rector. Toda modificación al proyecto debe respetar estos estándares.

---

## Identidad

- **Nombre:** macSpaces
- **Propósito:** Gestor de entorno macOS desde la barra de menú
- **Plataforma:** macOS (Hammerspoon + Lua)
- **Licencia:** GPLv3
- **Autor:** Diego Iparraguirre — Dilware

---

## Versionado y Releases

### SEMVER estricto

```
MAJOR.MINOR.PATCH
```

- **MAJOR:** cambio incompatible en config o comportamiento del usuario
- **MINOR:** feature nueva, módulo nuevo, mejora visible
- **PATCH:** fix de bug, ajuste cosmético, corrección de texto

### Archivo de versión

```
macspaces/version.lua → return "X.Y.Z"
```

### Commits

Formato obligatorio:

```
vX.Y.Z — tipo(scope): mensaje
```

Ejemplos:
```
v2.15.0 — feat(overlay): notch extendido con alas CPU/RAM
v2.15.1 — fix(overlay): corregir flicker en hover del panel
v2.14.1 — fix(profiles): bundle IDs para PWAs en MacBook
```

### Flujo de release

1. Implementar cambio
2. Bump `macspaces/version.lua`
3. Commit con formato `vX.Y.Z — tipo(scope): mensaje`
4. Push a GitHub

---

## UX/UI — Estándar Visual

### Principios

1. **Minimalismo funcional** — cada elemento tiene propósito, nada decorativo
2. **Consistencia cromática** — colores comunican estado, no estética
3. **Adaptativo por dispositivo** — MacBook ≠ Mac Mini, cada uno tiene su layout óptimo
4. **No interrumpir** — la información está disponible sin robar foco ni espacio

### Sistema de colores

| Rol | Color | Uso |
|-----|-------|-----|
| OK / activo | Verde `{ 0.30, 0.85, 0.50 }` | <60% uso, servicio activo, conectado |
| Advertencia | Amarillo `{ 0.95, 0.75, 0.15 }` | 60-84% uso |
| Crítico | Rojo `{ 0.95, 0.30, 0.25 }` | ≥85% uso, desconectado, error |
| Neutro / info | Gris `{ 0.55, 0.55, 0.60 }` | Separadores, info secundaria, inactivo |
| Conectividad | Celeste `{ 0.45, 0.70, 0.95 }` | Tráfico de red activo |
| Label / nombre | Blanco `{ 1, 1, 1, 0.92 }` | Nombres de métricas, títulos de fila |

### Regla de color en filas

- **Nombres/labels:** siempre blanco
- **Valores con estado:** color semáforo (verde/amarillo/rojo)
- **Indicadores on/off:** ● verde (on) / ○ gris (off)
- **Separadores (·):** gris
- **Info secundaria (ciclos, GB, timestamps):** gris

### Tipografía

- Font: `.AppleSystemUIFont` (San Francisco nativo)
- Alas del notch (MacBook): 14px
- Panel expandido: 13px
- Banner clásico (Mac Mini): 13px
- Todo en **MAYÚSCULAS** para nombres de módulos: CLAUDE, DESCANSO, POMODORO, SISTEMA, etc.

### Overlay — MacBook (con notch)

```
[CPU %]  ◼NOTCH◼  [RAM %]     ← Fila 1: siempre visible, alas con fondo pill oscuro
         ┌─────────────┐
         │ GPU + red   │      ← Panel expandido (hover)
         │ Discos      │
         │ Conectividad│
         │ Batería     │
         │ Claude      │
         │ Descanso    │
         │ Pomodoro    │
         └─────────────┘
```

### Overlay — Mac Mini (sin notch)

```
      [CPU %][RAM %]           ← Mismo layout, sin gap del notch (pills juntas)
      ┌─────────────┐
      │ GPU + red   │         ← Panel expandido (hover)
      │ Discos      │
      │ Conectividad│
      │ Claude      │
      │ Descanso    │
      │ Pomodoro    │
      └─────────────┘
```

### Comportamiento común (ambos dispositivos)

- Alas: fondo negro 55% opacidad, bordes redondeados 6px
- Panel: fondo negro 92% opacidad, bordes 10px, aparece debajo de las alas
- Hover en cualquier ala → expande panel
- Mouse sale → colapsa después de 0.8s
- Posición: centrado horizontalmente, alineado verticalmente con la menu bar
- MacBook: gap entre alas = ancho del notch (220px)
- Mac Mini: gap entre alas = 6px (pills prácticamente juntas)

### Orden de filas en el panel

1. GPU % · ↑ subida · ↓ bajada
2. Discos (una fila por disco: SISTEMA + externos)
3. Conectividad: CABLE · WIFI · VPN
4. Batería: CORRIENTE · % · ciclos (solo MacBook)
5. Claude cuotas
6. Descanso countdown
7. Pomodoro countdown
8. Presentación (si activa)

### Formato de disco

```
▪ SISTEMA · 56% · 262 de 494 GB
▪ NOMBRE_EXTERNO · 78% · 780 de 1000 GB
```

### Menú principal (ícono ⌘)

Solo contiene lo que **no está en el banner** o requiere **acción del usuario**:

- PERFILES (activar/desactivar)
- ENTORNO (navegador, audio, música)
- SISTEMA (red con acciones, bluetooth)
- HERRAMIENTAS (portapapeles, lanzador)
- Recargar + Acerca de

**No duplicar** info que ya está en el overlay/banner.

---

## Arquitectura

### Principios

- Un módulo = una responsabilidad
- Módulos independientes: si uno falla, los demás siguen
- Config centralizada en `config.lua` + overrides en `config_local.lua`
- `config_local.lua` no va al repo (diferencias por máquina)

### Adaptación por dispositivo

```lua
local IS_MACBOOK = (hs.host.localizedName() or ""):lower():find("macbook") ~= nil
```

Usar para:
- Layout del overlay (alas vs banner clásico)
- Mostrar/ocultar batería
- Nombres de PWAs (bundle IDs en MacBook, nombres en Mac Mini)

### Apps PWA de Edge

Las PWAs de Edge tienen nombres distintos por máquina. Usar `config_local.lua` con formato `"bundleid:com.microsoft.edgemac.app.XXXXX"` cuando el nombre no funciona.

`profiles.lua` soporta ambos formatos:
- `"Microsoft Edge"` → `hs.application.launchOrFocus(name)`
- `"bundleid:com.xxx"` → `hs.application.launchOrFocusByBundleID(bid)`

---

## Código

### Estilo

- Indentación: 4 espacios
- Variables locales siempre
- Forward-declare funciones que se referencian antes de definirse
- `pcall` para operaciones que pueden fallar (batería, IO, red)
- `io.popen` con timeout implícito — no bloquear el main thread >100ms

### Errores comunes a evitar

- `string.format("%d", float)` → usar `math.floor()` primero
- `hs.battery.cycleCount()` no existe → es `hs.battery.cycles()`
- Canvas sin fondo no detecta `mouseEnter` → siempre incluir un rectángulo de fondo
- Destruir canvas durante hover causa flicker → usar flags y dejar que el timer reconstruya
- `tostring(styledtext)` incluye metadata → usar el styledtext directamente

### Performance

- Timer del overlay: 2s (no 1s) para reducir overhead de `io.popen`
- Cache de métricas con TTL (sysmon: 2s, red: 10s)
- No reconstruir canvas si el fingerprint no cambió
- `df -g` en lugar de `df -H` para evitar decimales

---

## Testing manual

Antes de push, verificar:

- [ ] `⌘R` en Hammerspoon — sin errores en consola
- [ ] Overlay visible y legible en la máquina actual
- [ ] Hover expande/colapsa sin flicker (MacBook)
- [ ] Perfiles activan/desactivan correctamente
- [ ] Menú principal abre sin errores

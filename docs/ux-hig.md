# Análisis UX/UI — Apple Human Interface Guidelines — macSpaces v2.6.0

## Contexto

macSpaces es una menubar app (menu extra). Apple HIG define lineamientos específicos para este tipo de aplicaciones en [Menu Bar Extras](https://developer.apple.com/design/human-interface-guidelines/menu-bar-extras) y [Menus](https://developer.apple.com/design/human-interface-guidelines/menus).

---

## Hallazgos

### 🔴 Incumplimientos HIG

#### UX-01: Ícono del menú es un emoji, no una template image

**Archivo**: `config.lua:107`, `menu.lua:186`

```lua
M.menu_icon = "⌘"
menubar:setTitle(cfg.menu_icon)
```

Apple HIG establece que los íconos de menubar deben ser template images (imágenes monocromáticas que se adaptan automáticamente al modo claro/oscuro y al estado activo). Un emoji:
- No se adapta al modo oscuro/claro
- No sigue el estilo visual de los demás íconos del sistema
- Puede renderizarse con tamaño inconsistente según la versión de macOS

**Recomendación**: Usar `menubar:setIcon()` con una template image de 18×18 pt (36×36 px @2x). Hammerspoon soporta `hs.image.imageFromPath()` con `setTemplate(true)`.

---

#### UX-02: Ítems no accionables parecen accionables

**Múltiples archivos**: todos los módulos con `build_submenu()`

```lua
table.insert(items, { title = "Sin entradas aún", fn = function() end })
```

Hay ~30 ítems informativos que usan `fn = function() end` en lugar de `disabled = true`. Según el CHANGELOG (v2.1.3), esto fue intencional para evitar el color gris ilegible de `disabled = true`.

El problema: el usuario no puede distinguir visualmente entre un ítem que hace algo y uno que no. Apple HIG dice que los ítems no interactivos deben ser visualmente distintos.

**Recomendación**: Usar `disabled = true` para ítems puramente informativos. Si el gris es ilegible, es un problema de contraste que se resuelve con formato (ej: prefijo con espacios o indentación), no eliminando la señal visual de estado.

Excepción válida: los ítems `info_item()` que copian al portapapeles al hacer clic sí son accionables y deben mantener `fn`.

---

#### UX-03: Menú excesivamente largo

**Archivo**: `menu.lua`

El menú principal tiene ~16 ítems de primer nivel + 6 separadores. Al abrirse, puede exceder la altura de la pantalla en resoluciones bajas o con Dock visible.

Apple HIG recomienda que los menús sean concisos y que los ítems se agrupen en submenús cuando hay demasiados.

Estructura actual:
```
Personal
Work
─────────
Navegador        →
Audio            →
Music            →
─────────
Batería
Bluetooth        →
─────────
Red              →
VPN              →
─────────
Portapapeles     →
Lanzador         →
Pomodoro         →
Descanso         →
Presentación     →
─────────
Historial        →
─────────
Registro
Recargar
```

**Recomendación**: Agrupar en submenús de segundo nivel:
- **Entorno**: Navegador, Audio, Music
- **Dispositivos**: Batería, Bluetooth
- **Red**: Red, VPN
- **Productividad**: Portapapeles, Pomodoro, Descanso, Presentación, Lanzador

Esto reduciría el menú principal a ~8 ítems.

---

#### UX-04: Inconsistencia visual entre SF Symbols y emojis

**Archivos**: `menu.lua` (SF Symbols) vs submenús de todos los módulos (emojis)

`menu.lua` define una tabla `ICON` con SF Symbols para los ítems de primer nivel:
```lua
local ICON = {
    profile   = "person.circle",
    browser   = "globe",
    ...
}
```

Pero los submenús usan emojis directamente:
```lua
-- pomodoro.lua
local phase_labels = { work = "🍅", short_break = "☕", long_break = "🌿" }

-- network.lua
local type_icon = { WiFi = "📶", Ethernet = "🔌", VPN = "🔒" }

-- bluetooth.lua
return "🎧"  -- auriculares
```

Apple HIG promueve consistencia visual. Mezclar SF Symbols (monocromáticos, adaptativos) con emojis (coloridos, fijos) crea una experiencia visual fragmentada.

**Recomendación**: Elegir un sistema y usarlo consistentemente. SF Symbols es la opción nativa de Apple, pero requiere que Hammerspoon los soporte bien en menús (verificar). Si no, usar emojis consistentemente en todo el menú.

---

### 🟡 Mejoras recomendadas

#### UX-05: Sin atajos de teclado visibles en el menú

Apple HIG recomienda mostrar keyboard equivalents junto a los ítems del menú. Los perfiles tienen atajos (⌘⌥1, ⌘⌥2) pero no se muestran en el menú.

**Recomendación**: Agregar el atajo al título del ítem:
```lua
title = profile.name .. "    ⌘⌥" .. binding.key
```

---

#### UX-06: Pomodoro no muestra tiempo en la menubar

El tiempo restante del Pomodoro solo es visible al abrir el menú. El usuario no puede ver el countdown sin interactuar.

**Recomendación**: Cuando el Pomodoro está activo, mostrar el tiempo restante en el título de la menubar:
```lua
menubar:setTitle("🍅 23:41")
```
Y restaurar el ícono normal al detener.

---

#### UX-07: Desactivar perfil cierra apps sin confirmación

Al hacer clic en un perfil activo, se cierran todas sus apps inmediatamente. Si el usuario tiene trabajo sin guardar, lo pierde.

El modo presentación sí pide confirmación (`hs.dialog.blockAlert`). Los perfiles deberían hacer lo mismo.

**Recomendación**: Agregar confirmación antes de cerrar apps, al menos cuando hay ventanas con contenido no guardado (si es detectable) o siempre como opción configurable.

---

#### UX-08: Cambio de navegador es global, no contextual

Al activar un perfil, el navegador predeterminado cambia para todo el sistema. Si el usuario tiene ambos perfiles activos (técnicamente posible), el último en activarse gana.

Esto puede confundir al usuario que espera que el cambio sea solo para el contexto del perfil.

**Recomendación**: Documentar claramente este comportamiento. Considerar restaurar el navegador anterior al desactivar el perfil.

---

#### UX-09: Batería no tiene submenú, inconsistente con otros ítems

Batería es un ítem simple que copia el porcentaje al hacer clic. Todos los demás ítems de la sección "Dispositivos" (Bluetooth) tienen submenú. Esto rompe la expectativa del usuario.

**Recomendación**: Convertir Batería en submenú con: porcentaje, estado de carga, ciclos de batería, tiempo restante estimado.

---

#### UX-10: Textos en español e inglés mezclados

- Ítems del menú: español ("Navegador", "Portapapeles", "Descanso")
- Nombres de perfiles: inglés ("Personal", "Work")
- Submenú Music: inglés ("Music")
- Notificaciones: español ("macSpaces", "Modo presentación activado")
- Fases Pomodoro: español ("Trabajando", "Pausa corta")

**Recomendación**: Definir una política clara. Sugerencia: UI en español, nombres propios de apps/perfiles en inglés (es lo natural en macOS).

---

### 🟢 Buenas prácticas ya implementadas

| Práctica | Detalle |
|---|---|
| ✅ Menú on-demand | Evita parpadeo y reconstrucciones innecesarias |
| ✅ Confirmación en modo presentación | Antes de reiniciar Dock/Finder |
| ✅ Checkmarks en selección | Navegador y audio muestran el activo |
| ✅ Separadores semánticos | Agrupación visual por categoría |
| ✅ Submenús para contenido extenso | Red, VPN, Bluetooth, etc. |
| ✅ Feedback via notificaciones | Acciones importantes notifican al usuario |
| ✅ Ítems copiables | IPs, tiempos y porcentajes se copian al portapapeles |
| ✅ Ocultamiento condicional | VPN solo aparece si está activa, Batería solo en MacBook, Lanzador solo si hay apps |

---

## Resumen de prioridades

| # | Hallazgo | Impacto | Esfuerzo |
|---|---|---|---|
| UX-01 | Ícono emoji → template image | Alto | Bajo |
| UX-02 | Ítems no accionables sin señal visual | Alto | Bajo |
| UX-03 | Menú demasiado largo | Medio | Medio |
| UX-04 | Emojis vs SF Symbols inconsistente | Medio | Alto |
| UX-05 | Atajos no visibles en menú | Bajo | Bajo |
| UX-06 | Pomodoro sin countdown en menubar | Medio | Bajo |
| UX-07 | Sin confirmación al desactivar perfil | Medio | Bajo |
| UX-08 | Navegador global, no contextual | Bajo | Medio |
| UX-09 | Batería sin submenú | Bajo | Bajo |
| UX-10 | Idioma mezclado | Bajo | Bajo |

# Análisis de Seguridad — macSpaces v2.6.0

## Resumen ejecutivo

macSpaces opera con los privilegios de Hammerspoon (Accesibilidad + Automatización), lo que le da acceso amplio al sistema. La mayoría de operaciones son locales y de bajo riesgo, pero hay áreas que requieren atención.

---

## Hallazgos

### 🔴 Crítico

#### S-01: ✅ RESUELTO — Consultas HTTP sin cifrar a ip-api.com

**Archivos**: `network.lua`, `vpn.lua` — migrado a `https://ipapi.co/json/`

```lua
local url = "https://ipapi.co/json/"  -- migrado a HTTPS
```

**Resuelto en v2.6.0**: migrado de `http://ip-api.com` a `https://ipapi.co/json/` (HTTPS gratuito). Las consultas ahora viajan cifradas.

---

#### S-02: Instalación via `curl | bash`

**Archivo**: `README.md`, `install.sh`

```bash
curl -sL https://raw.githubusercontent.com/...install.sh | bash
```

Este patrón ejecuta código remoto sin verificación de integridad. Un ataque MITM (man-in-the-middle) o compromiso del repositorio podría inyectar código malicioso.

**Recomendación**:
1. Documentar instalación manual como alternativa principal (clonar → copiar).
2. Si se mantiene `curl | bash`, agregar verificación de checksum.
3. Considerar firmar releases con GPG.

---

### 🟡 Medio

#### S-03: Log contiene datos sensibles sin protección

**Archivo**: `utils.lua`

El archivo `debug.log` registra:
- Direcciones IP (local y externa)
- Nombres de dispositivos Bluetooth
- Nombres de apps abiertas/cerradas
- Timestamps de actividad

El log se escribe sin permisos restrictivos y no tiene rotación ni límite de tamaño. Se limpia solo al reiniciar Hammerspoon.

**Recomendación**:
1. Establecer permisos `0600` al crear el archivo.
2. Implementar rotación o límite de tamaño.
3. No registrar IPs completas en el log (ofuscar últimos octetos).

---

#### S-04: Historial JSON sin permisos restrictivos

**Archivo**: `history.lua`

`macspaces_history.json` contiene patrones de uso (qué perfiles se usan, cuándo y por cuánto tiempo). Se crea con los permisos por defecto del sistema.

**Recomendación**: Establecer permisos `0600` al crear/escribir el archivo.

---

#### S-05: Portapapeles almacena contenido sensible

**Archivo**: `clipboard.lua`

El historial del portapapeles captura todo lo que se copia, incluyendo potencialmente:
- Contraseñas copiadas de gestores de contraseñas
- Tokens de autenticación
- Datos personales

No hay mecanismo para:
- Excluir apps específicas (ej: 1Password, Keychain)
- Auto-expirar entradas sensibles
- Cifrar el historial en memoria

**Recomendación**:
1. Agregar allowlist/blocklist de apps cuyo contenido no se captura.
2. Implementar auto-expiración configurable.
3. Documentar claramente que el historial es en memoria y se pierde al recargar.

---

#### S-06: Ejecución de comandos shell

**Archivos**: `presentation.lua`, `bluetooth.lua`, `dnd.lua`

Se ejecutan comandos via `hs.execute()`:
- `defaults write/read ...`
- `killall Dock`, `killall Finder`, `killall NotificationCenter`
- `ioreg -r -k ...`

Los comandos están hardcodeados (no hay inyección de input del usuario), pero la superficie de ataque existe si un módulo futuro concatena input sin sanitizar.

**Recomendación**: Mantener la práctica actual de comandos hardcodeados. Documentar como regla de desarrollo que nunca se debe concatenar input del usuario en `hs.execute()`.

---

#### S-07: AppleScript sin sandboxing

**Archivo**: `music.lua`

Los scripts de AppleScript se ejecutan con los privilegios completos de Hammerspoon. Actualmente solo controlan Music.app, pero el patrón permite ejecutar cualquier AppleScript.

**Recomendación**: Mantener los scripts mínimos y documentar que no se debe extender este patrón con input del usuario.

---

### 🟢 Bajo

#### S-08: Versión inconsistente entre archivos

- `init.lua`: v2.4.0
- `config.lua`: v2.6.0
- `README.md`: v2.5.0
- `CHANGELOG.md`: v2.6.0

No es un riesgo de seguridad directo, pero dificulta la trazabilidad y verificación de integridad.

**Recomendación**: Unificar la versión en un solo lugar (`config.lua`) y que los demás archivos la referencien o se actualicen en el mismo commit.

---

## Permisos requeridos

| Permiso | Uso | Riesgo |
|---|---|---|
| Accesibilidad | Mover ventanas, crear espacios, hotkeys globales | Alto (acceso completo a UI) |
| Automatización | AppleScript para Music.app | Medio |
| Red | Consultas a ipapi.co (HTTPS) | Bajo (solo lectura) |

## Superficie de ataque

```
┌─────────────────────────────────────────┐
│            Vectores de entrada          │
├─────────────────────────────────────────┤
│ 1. config.lua (editable por usuario)    │ → Validado al inicio
│ 2. ipapi.co (respuesta HTTPS)           │ → JSON parseado con pcall
│ 3. ioreg (salida de proceso)            │ → Parseado con regex
│ 4. Portapapeles (contenido del sistema) │ → Filtrado por blocklist de apps
│ 5. install.sh (código remoto)           │ → Sin verificación
└─────────────────────────────────────────┘
```

## Recomendaciones priorizadas

1. 🔴 Migrar de HTTP a HTTPS para consultas de IP externa
2. 🔴 Ofrecer instalación manual como método principal
3. 🟡 Permisos `0600` para log e historial
4. 🟡 Blocklist de apps para el portapapeles
5. 🟡 Rotación/límite del archivo de log
6. 🟢 Unificar versión en todos los archivos

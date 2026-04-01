# Seguridad — macSpaces v2.7.0

## Modelo de amenazas

macSpaces se ejecuta dentro de Hammerspoon con los mismos permisos del usuario. No tiene superficie de red propia, pero realiza llamadas HTTP salientes y ejecuta comandos del sistema.

---

## Mitigaciones implementadas

### SEC-01: Comunicaciones HTTPS

Todas las llamadas a APIs externas usan HTTPS:
- `https://ipapi.co/json/` para IP externa y geolocalización
- Migrado desde `http://ip-api.com` (HTTP sin cifrar)

### SEC-02: Instalación segura

- Método manual documentado como principal en README
- Script `install.sh` con advertencia explícita sobre `curl | bash`

### SEC-03: Log seguro

- Permisos `0600` al crear `debug.log`
- Rotación automática al superar 1MB
- IPs ofuscadas en el log (últimos octetos reemplazados)

### SEC-04: Historial seguro

- `macspaces_history.json` con permisos `0600`
- Limpieza automática de entradas > 30 días

### SEC-05: Portapapeles filtrado

- Blocklist de apps sensibles en `cfg.clipboard.ignore_apps`
- Contenido de apps en la blocklist no se captura en el historial

### SEC-06: Comandos del sistema (bajo riesgo)

- Todos los comandos `hs.execute()` usan strings estáticos
- No se concatena input del usuario en comandos shell
- Regla de desarrollo: nunca interpolar variables de usuario en `hs.execute()`

### SEC-07: AppleScript (bajo riesgo)

- Scripts mínimos y estáticos (solo control de Music.app)
- No se extiende con input del usuario

---

## Superficie de ataque

| Vector | Riesgo | Mitigación |
|---|---|---|
| API ipapi.co | Bajo | HTTPS, datos no sensibles (IP pública) |
| Log en disco | Bajo | Permisos 0600, IPs ofuscadas, rotación |
| Historial JSON | Bajo | Permisos 0600, solo duraciones |
| Portapapeles | Medio | Blocklist de apps, solo en memoria |
| Shell commands | Bajo | Strings estáticos, sin interpolación |
| AppleScript | Bajo | Scripts estáticos, solo Music.app |
| Config.lua | N/A | Archivo local, editado manualmente por el usuario |

---

## Datos almacenados

| Dato | Ubicación | Sensibilidad | Protección |
|---|---|---|---|
| Sesiones de trabajo | `macspaces_history.json` | Baja | Permisos 0600 |
| Log de depuración | `debug.log` | Baja | Permisos 0600, IPs ofuscadas, rotación 1MB |
| Portapapeles | Memoria | Media | Blocklist, no persiste |
| Estado de perfiles | Memoria | Ninguna | No persiste |

---

## Recomendaciones para el usuario

1. No agregar datos sensibles a `config.lua` (contraseñas, tokens)
2. Revisar `cfg.clipboard.ignore_apps` y agregar apps que manejen datos sensibles
3. No extender los scripts AppleScript con input externo
4. Mantener Hammerspoon actualizado para parches de seguridad

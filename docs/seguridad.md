# Seguridad — macSpaces v2.11.0

## Tabla de contenido

- [Modelo de amenazas](#modelo-de-amenazas)
- [Mitigaciones implementadas](#mitigaciones-implementadas)
- [Superficie de ataque](#superficie-de-ataque)
- [Datos almacenados](#datos-almacenados)
- [Recomendaciones para el usuario](#recomendaciones-para-el-usuario)

---

## Modelo de amenazas

macSpaces se ejecuta dentro de Hammerspoon con los mismos permisos del usuario activo en macOS. No tiene proceso propio ni daemon. Realiza llamadas HTTP salientes, ejecuta comandos del sistema y lee archivos locales. El vector principal de riesgo es la cadena de confianza: código Lua local + APIs externas + comandos del sistema.

---

## Mitigaciones implementadas

### SEC-01: Comunicaciones HTTPS

Todas las llamadas a APIs externas usan HTTPS:
- `https://ipapi.co/json/` para IP externa y geolocalización (`network.lua`)
- `https://ipapi.co/{ip}/json/` para geolocalización del túnel VPN (`vpn.lua`)

No hay comunicaciones HTTP sin cifrar.

### SEC-02: Instalación segura

- Método manual documentado como opción principal en README
- Script `install.sh` incluye advertencia explícita sobre los riesgos de `curl | bash`
- `install.sh` usa `set -euo pipefail` para abortar ante errores

### SEC-03: Log seguro

- Permisos `0600` aplicados con `chmod 600` al crear y al escribir `debug.log`
- Rotación automática al superar 1MB (el archivo anterior se mueve a `debug.log.old`)
- IPs ofuscadas en el log: el último octeto de toda dirección IPv4 se reemplaza por `***`

### SEC-04: Historial seguro

- `macspaces_history.json` creado y escrito con permisos `0600`
- Solo almacena duración de sesiones (segundos por perfil por día), sin contenido sensible
- Limpieza automática de entradas con más de 30 días

### SEC-05: Portapapeles filtrado

- `cfg.clipboard.ignore_apps` define apps cuyo contenido copiado no se captura
- Lista por defecto: 1Password, Keychain Access, Bitwarden, LastPass, Dashlane, KeePassXC
- La verificación se hace contra el nombre de la app frontal al momento de la copia

### SEC-06: Comandos del sistema sin interpolación de usuario

- Todos los comandos en `hs.execute()` usan strings estáticos o variables de sistema (`HOME`, rutas fijas)
- No se interpola input del usuario en comandos shell
- Regla de desarrollo: prohibido concatenar variables de sesión o datos externos en `hs.execute()`

### SEC-07: AppleScript mínimo y estático

- Scripts de AppleScript son literales estáticos (no construidos dinámicamente)
- Solo controlan `Music.app` (play, pause, siguiente, anterior, estado)
- No se extienden con input del usuario ni datos externos

### SEC-08: Limpieza al cerrar (`hs.shutdownCallback`)

Al apagar, reiniciar o recargar Hammerspoon se restaura el estado del sistema:
- DND desactivado si Pomodoro o Presentación lo habían activado
- Dock restaurado a su estado previo al modo presentación
- Íconos del escritorio restaurados (`CreateDesktop = true`)
- Timers, watchers, menubars, overlay y hotkeys liberados para evitar duplicados al recargar

### SEC-09: Archivo Claude de solo lectura

- `~/.claude/usage_cache.json` es leído pero nunca modificado por macSpaces
- Si el archivo tiene más de 6 horas de antigüedad, se ignora para evitar mostrar datos desactualizados

---

## Superficie de ataque

| Vector | Riesgo | Mitigación |
|---|---|---|
| API ipapi.co | Bajo | HTTPS, datos no sensibles (IP pública), TTL limita frecuencia |
| Log en disco | Bajo | Permisos 0600, IPs ofuscadas, rotación automática |
| Historial JSON | Bajo | Permisos 0600, solo duraciones numéricas |
| Portapapeles | Medio | Blocklist de apps sensibles, solo en memoria, no persiste |
| Shell commands | Bajo | Strings estáticos, sin interpolación de input externo |
| AppleScript | Bajo | Scripts estáticos, solo Music.app |
| Config.lua | N/A | Archivo local, editado manualmente por el usuario |
| usage_cache.json | Bajo | Solo lectura, generado por proceso confiable del usuario |
| Helper Swift | Bajo | Binario compilado desde fuente en el repositorio |

---

## Datos almacenados

| Dato | Ubicación | Sensibilidad | Protección |
|---|---|---|---|
| Sesiones de trabajo | `~/.hammerspoon/macspaces_history.json` | Baja | Permisos 0600 |
| Log de depuración | `~/.hammerspoon/debug.log` | Baja | Permisos 0600, IPs ofuscadas, rotación 1MB |
| Posición del overlay | `~/.hammerspoon/overlay_pos.json` | Ninguna | Sin restricción (no contiene datos sensibles) |
| Portapapeles | Memoria RAM | Media | Blocklist, no persiste entre recargas |
| Estado de perfiles | Memoria RAM | Ninguna | No persiste |
| Estado de Pomodoro | Memoria RAM | Ninguna | No persiste |

---

## Recomendaciones para el usuario

1. No agregar credenciales, tokens ni contraseñas en `config.lua`
2. Revisar y ampliar `cfg.clipboard.ignore_apps` según las apps de gestión de contraseñas utilizadas
3. No modificar los scripts AppleScript para incorporar input externo
4. Mantener Hammerspoon actualizado para recibir parches de seguridad del runtime
5. Revisar el código de `install.sh` antes de ejecutarlo con `curl | bash`
6. Si se comparte el equipo, considerar que `debug.log` puede contener nombres de redes WiFi y parcialmente IPs locales

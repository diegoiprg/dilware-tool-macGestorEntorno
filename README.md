# Gestor de entorno macOS — macSpaces

![Versión](https://img.shields.io/badge/versión-v2.11.4-6366f1?style=flat-square)
![Licencia](https://img.shields.io/badge/licencia-GPLv3-a855f7?style=flat-square)
![Plataforma](https://img.shields.io/badge/plataforma-macOS-222?style=flat-square&logo=apple&logoColor=white)

Tu entorno de trabajo, organizado con un clic.

---

## Tabla de contenido

- [Que es](#que-es)
- [Que puedes hacer](#que-puedes-hacer)
- [Dos menús, un propósito](#dos-menús-un-propósito)
- [Módulos](#módulos)
- [Perfiles incluidos](#perfiles-incluidos)
- [Para quien es](#para-quien-es)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Documentación](#documentación)
- [Sobre este proyecto](#sobre-este-proyecto)
- [Autor](#autor)

---

## Que es

Una herramienta gratuita para macOS que centraliza en un solo ícono de barra de menú el control de tu entorno de trabajo: espacios virtuales, navegador, audio, red, portapapeles, productividad y más.

Funciona en segundo plano, sin ventanas extra ni configuraciones complicadas. Todo desde la barra de menú.

## Que puedes hacer

- Activar un perfil de trabajo con un clic y abrir automáticamente todas sus apps en un espacio dedicado
- Cerrar el perfil y que se limpie todo: apps cerradas, espacio eliminado, navegador restaurado
- Cambiar el navegador predeterminado del sistema sin abrir Preferencias del Sistema
- Cambiar el dispositivo de salida de audio al instante
- Controlar Apple Music: play/pause, siguiente, anterior, y ver canción actual
- Ver el estado de batería directamente en el menú (solo en MacBook)
- Consultar los dispositivos Bluetooth conectados con su nivel de batería
- Ver información de tu red: tipo de conexión, IP local, IP externa, país e ISP
- Detectar si estás conectado a una VPN con información del túnel y su geolocalización
- Mantener un historial del portapapeles con hasta 20 entradas y restaurar cualquiera con un clic
- Usar Pomodoro con ciclos configurables, DND automático y countdown flotante en pantalla
- Recibir recordatorios de descanso activo con datos de salud (activado por defecto)
- Entrar en modo presentación: No Molestar, Dock oculto y escritorio limpio con un solo clic
- Lanzar tus apps favoritas desde un acceso rápido configurable
- Ver el tiempo acumulado por perfil durante el día
- Activar perfiles con atajos de teclado (⌘⌥1 / ⌘⌥2)
- Personalizar todo editando un solo archivo: `macspaces/config.lua`

## Dos menús, un propósito

macSpaces presenta dos íconos en la barra de menú:

| Ícono | Propósito | Contenido |
|-------|-----------|-----------|
| ⌘ | Gestión del entorno | Perfiles, navegador, audio, música, dispositivos, red, portapapeles, Claude |
| ◎ | Gestión del enfoque | Pomodoro, descanso activo, modo presentación |

El ícono de enfoque muestra el ícono configurado (por defecto ◎). Un overlay flotante en la esquina inferior derecha muestra countdowns en tiempo real con filas coloreadas por estado. Es arrastrable para reposicionar, y la posición se persiste en disco entre reinicios de Hammerspoon.

El overlay también muestra el uso de rate limits de Claude Code en dos filas independientes (ventana de 5 horas y ventana de 7 días), con color semáforo (verde / amarillo / rojo) y tiempo hasta el reset. Esta información se lee desde `~/.claude/usage_cache.json`, generado automáticamente por `statusline.sh` del proyecto [dil-ia-config](https://github.com/diegoiprg/dil-ia-config). En MacBook, el formato es compacto (sin barra de progreso) para evitar solapamiento.

## Módulos

El proyecto está compuesto por los siguientes módulos Lua, cada uno con responsabilidad única:

| Módulo | Responsabilidad |
|--------|-----------------|
| `config.lua` | Tabla de configuración central; parámetros de perfiles, delays, pomodoro, breaks, overlay |
| `utils.lua` | Utilidades compartidas: log, notificaciones, `alert_notify()`, `format_time()`, ítems de menú |
| `profiles.lua` | Activación y desactivación de perfiles: espacios virtuales, lanzamiento de apps, navegador vinculado |
| `browsers.lua` | Cambio de navegador predeterminado del sistema via helper Swift nativo (`set_browser.swift`) |
| `audio.lua` | Listado y cambio de dispositivo de salida de audio |
| `music.lua` | Control de Apple Music: play/pause, anterior, siguiente, canción actual |
| `battery.lua` | Estado de batería en menú (solo MacBook); nivel, estado de carga, tiempo restante |
| `bluetooth.lua` | Dispositivos Bluetooth conectados con nivel de batería |
| `network.lua` | Información de red: tipo de conexión, IP local, IP externa, país e ISP |
| `vpn.lua` | Detección de VPN activa, dirección del túnel y geolocalización |
| `clipboard.lua` | Historial de portapapeles (hasta 20 entradas), restauración con un clic |
| `pomodoro.lua` | Ciclos Pomodoro configurables, DND automático, transiciones con `alert_notify()`, reinicio tras suspensión |
| `breaks.lua` | Recordatorios de descanso activo con mensajes paso a paso, countdown, reinicio tras suspensión |
| `presentation.lua` | Modo presentación: DND, Dock oculto, escritorio limpio |
| `launcher.lua` | Accesos rápidos configurables a apps favoritas |
| `history.lua` | Tiempo acumulado por perfil durante el día |
| `hotkeys.lua` | Atajos de teclado globales (⌘⌥1 / ⌘⌥2) para activar perfiles |
| `dnd.lua` | Wrapper de Do Not Disturb: activar, desactivar, consultar estado |
| `claude.lua` | Monitoreo de rate limits de Claude Code via `~/.claude/usage_cache.json`; filas de overlay con barra `▰▱` y color semáforo |
| `focus_overlay.lua` | Overlay flotante con countdowns en tiempo real; arrastrable, posición persistente en disco, modo compacto automático en MacBook |
| `focus_menu.lua` | Menú de enfoque (ícono ◎): acceso a Pomodoro, breaks, modo presentación |
| `menu.lua` | Menú principal (ícono ⌘): integra todos los módulos de entorno |

## Perfiles incluidos

| Perfil | Apps | Navegador vinculado |
|--------|------|---------------------|
| Personal | Safari | Safari |
| Work | Outlook PWA, Teams PWA, OneDrive, Edge | Microsoft Edge |

## Para quien es

- Personas que trabajan con múltiples contextos en su Mac y quieren cambiar entre ellos sin fricción
- Usuarios que buscan organizar su entorno sin apps de pago ni configuraciones complejas
- Cualquiera que quiera tener su Mac bajo control desde un solo lugar

## Requisitos

- macOS con Mission Control habilitado
- [Hammerspoon](https://www.hammerspoon.org) instalado
- Permisos de Accesibilidad y Automatización para Hammerspoon

## Instalación

### Método manual (recomendado)

```bash
# 1. Clonar el repositorio
git clone https://github.com/diegoiprg/dilware-tool-macGestorEntorno.git ~/dilware-tool-macGestorEntorno

# 2. Copiar archivos a Hammerspoon
cp ~/dilware-tool-macGestorEntorno/init.lua ~/.hammerspoon/init.lua
cp -r ~/dilware-tool-macGestorEntorno/macspaces ~/.hammerspoon/macspaces

# 3. Abrir Hammerspoon y presionar ⌘R para recargar
```

### Script de instalación

> Ejecutar scripts remotos con `curl | bash` implica confiar en el contenido del repositorio. Revisa el código antes de ejecutar.

```bash
curl -sL https://raw.githubusercontent.com/diegoiprg/dilware-tool-macGestorEntorno/main/install.sh | bash
```

Después abre Hammerspoon y presiona ⌘R para recargar. El ícono ⌘ aparecerá en tu barra de menú.

## Documentación

| Documento | Descripción |
|-----------|-------------|
| [Funcional](docs/funcional.md) | Que hace cada módulo desde la perspectiva del usuario |
| [Técnico](docs/tecnico.md) | Arquitectura, API de módulos, dependencias |
| [Configuración](docs/configuracion.md) | Guía de todos los parámetros de config.lua |
| [Uso](docs/uso.md) | Guía de instalación y uso diario |
| [UX/HIG](docs/ux-hig.md) | Decisiones de experiencia de usuario |
| [Seguridad](docs/seguridad.md) | Modelo de amenazas y mitigaciones |
| [Arquitectura](docs/arquitectura.md) | Diagrama de módulos y relaciones |
| [TODO](docs/todo.md) | Pendientes y mejoras futuras |

---

## Sobre este proyecto

Esta herramienta es parte de **Dilware**, una colección de proyectos de software libre creados con ayuda de inteligencia artificial bajo mi supervisión y dirección técnica. El objetivo es que sean útiles para la mayor cantidad de personas posible.

Conoce todos mis proyectos en [dilware.net](https://dilware.net).

## Autor

**Diego Iparraguirre** — Gestor de Proyectos & Arquitecto de Soluciones

[![Dilware](https://img.shields.io/badge/Dilware-dilware.net-6366f1?style=flat-square)](https://dilware.net)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-diegoiprg-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/diegoiprg/)
[![GitHub](https://img.shields.io/badge/GitHub-diegoiprg-222?style=flat-square&logo=github&logoColor=white)](https://github.com/diegoiprg)

---

Software libre bajo licencia [GPLv3](./LICENSE).

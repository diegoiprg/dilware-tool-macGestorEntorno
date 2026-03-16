# ⌘ macSpaces — Gestor de Espacios para macOS

![Versión](https://img.shields.io/badge/versión-v2.2.0-6366f1?style=flat-square)
![Licencia](https://img.shields.io/badge/licencia-GPLv3-a855f7?style=flat-square)
![Plataforma](https://img.shields.io/badge/plataforma-macOS-222?style=flat-square&logo=apple&logoColor=white)

Tu entorno de trabajo, organizado con un clic.

---

## ¿Qué es?

Una herramienta gratuita para macOS que centraliza en un solo ícono de barra de menú el control de tu entorno de trabajo: espacios virtuales, navegador, audio, red, portapapeles, productividad y más.

Funciona en segundo plano, sin ventanas extra ni configuraciones complicadas. Todo desde la barra de menú.

## ¿Qué puedo hacer?

- Activar un perfil de trabajo con un clic y abrir automáticamente todas sus apps en un espacio dedicado
- Cerrar el perfil y que se limpie todo: apps cerradas, espacio eliminado
- Cambiar el navegador predeterminado del sistema sin abrir Preferencias del Sistema
- Cambiar el dispositivo de salida de audio al instante
- Ver el estado de batería directamente en el menú (solo en MacBook)
- Consultar los dispositivos Bluetooth conectados con su nivel de batería
- Ver información de tu red: tipo de conexión, IP local, IP externa, país e ISP
- Detectar si estás conectado a una VPN con información del túnel y su geolocalización
- Mantener un historial del portapapeles con hasta 20 entradas y restaurar cualquiera con un clic
- Usar Pomodoro con ciclos configurables y No Molestar automático durante el trabajo
- Activar recordatorios de descanso activo para cuidar tu postura y vista
- Entrar en modo presentación: No Molestar, Dock oculto y escritorio limpio con un solo clic
- Lanzar tus apps favoritas desde un acceso rápido configurable
- Ver el tiempo acumulado por perfil durante el día
- Activar perfiles con atajos de teclado (⌘⌥1 / ⌘⌥2)
- Personalizar todo editando un solo archivo: `macspaces/config.lua`

## Perfiles incluidos

| Perfil | Apps | Navegador vinculado |
|--------|------|---------------------|
| Personal | Safari | Safari |
| Work | Outlook, Teams, Edge | Microsoft Edge |

## ¿Para quién es?

- Personas que trabajan con múltiples contextos en su Mac y quieren cambiar entre ellos sin fricción
- Usuarios que buscan organizar su entorno sin apps de pago ni configuraciones complejas
- Cualquiera que quiera tener su Mac bajo control desde un solo lugar

## Requisitos

- macOS con Mission Control habilitado
- [Hammerspoon](https://www.hammerspoon.org) instalado
- Permisos de Accesibilidad y Automatización para Hammerspoon

## Instalación

```bash
curl -sL https://raw.githubusercontent.com/diegoiprg/dilware-tool-macSpaces/main/install.sh | bash
```

Después abre Hammerspoon y presiona ⌘R para recargar. El ícono ⌘ aparecerá en tu barra de menú.

---

## Sobre este proyecto

Esta herramienta es parte de **Dilware**, una colección de proyectos de software libre creados con ayuda de inteligencia artificial bajo mi supervisión y dirección técnica. El objetivo es que sean útiles para la mayor cantidad de personas posible.

Conoce todos mis proyectos en el [Portafolio Dilware](https://diegoiprg.github.io/diegoiprg-portafolio/).

## Autor

**Diego Iparraguirre** — Ingeniero de Sistemas

[![LinkedIn](https://img.shields.io/badge/LinkedIn-diegoiprg-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/diegoiprg/)
[![GitHub](https://img.shields.io/badge/GitHub-diegoiprg-222?style=flat-square&logo=github&logoColor=white)](https://github.com/diegoiprg)

---

Software libre bajo licencia [GPLv3](./LICENSE).

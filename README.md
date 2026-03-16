# ⌘ macSpaces — Gestor de Espacios para macOS

![Versión](https://img.shields.io/badge/versión-v2.0.0-6366f1?style=flat-square)
![Licencia](https://img.shields.io/badge/licencia-GPLv3-a855f7?style=flat-square)
![Plataforma](https://img.shields.io/badge/plataforma-macOS-222?style=flat-square&logo=apple&logoColor=white)

Organiza tu Mac con un clic. Crea espacios de trabajo con las apps que necesitas, cambia tu navegador y audio, y cuida tu productividad con Pomodoro y recordatorios de descanso.

---

## ¿Qué es?

Una herramienta gratuita para macOS que gestiona espacios virtuales (Mission Control) con perfiles predefinidos, y centraliza en un solo ícono de barra de menú el control de tu entorno de trabajo.

Funciona desde la barra de menú de macOS, sin ventanas extra ni configuraciones complicadas.

## ¿Qué puedo hacer?

- Crear un espacio de trabajo con un clic y abrir automáticamente las apps del perfil
- Cerrar un perfil y que se cierren sus apps y se elimine el espacio
- Cambiar el navegador predeterminado del sistema desde el menú (solo muestra navegadores reales)
- Cambiar el dispositivo de salida de audio sin abrir Preferencias del Sistema
- Activar perfiles con atajos de teclado (⌘⌥1 / ⌘⌥2)
- Ver el tiempo acumulado por perfil en el día
- Usar Pomodoro con ciclos configurables y No Molestar automático
- Activar recordatorios de descanso activo con intervalo configurable
- Ver el estado de batería en la barra de menú (solo en MacBook)
- Personalizar todo editando un solo archivo: `macspaces/config.lua`

## Perfiles incluidos

| Perfil | Apps | Navegador vinculado |
|--------|------|---------------------|
| Personal | Safari | Safari |
| Work | Outlook, Teams, Edge | Microsoft Edge |

## ¿Para quién es?

- Personas que trabajan con múltiples contextos en su Mac (trabajo, personal, estudio)
- Usuarios que quieren organizar sus espacios sin apps de pago
- Cualquiera que busque automatizar su flujo de trabajo en macOS

## Requisitos

- macOS con Mission Control habilitado
- [Hammerspoon](https://www.hammerspoon.org) instalado
- Permisos de Accesibilidad y Automatización para Hammerspoon

## Instalación rápida

```bash
curl -sL https://raw.githubusercontent.com/diegoiprg/dilware-tool-macSpaces/main/install.sh | bash
```

Después, abre Hammerspoon y presiona ⌘R para recargar.

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

#!/usr/bin/env bash
# Instalador de macSpaces (dilware-tool-macSpaces)
# https://github.com/diegoiprg/dilware-tool-macSpaces

set -euo pipefail

REPO_URL="https://github.com/diegoiprg/dilware-tool-macSpaces.git"
REPO_DIR="${HOME}/dilware-tool-macSpaces"
HS_DIR="${HOME}/.hammerspoon"

echo "⌘ Instalando macSpaces..."

# Verificar dependencia: git
if ! command -v git &>/dev/null; then
  echo "✗ git no está instalado. Instálalo con: xcode-select --install"
  exit 1
fi

# Verificar que Hammerspoon haya sido ejecutado al menos una vez
if [ ! -d "${HS_DIR}" ]; then
  echo "✗ No se encontró ~/.hammerspoon"
  echo "  Instala Hammerspoon desde https://www.hammerspoon.org y ábrelo al menos una vez."
  exit 1
fi

# Clonar o actualizar el repositorio
if [ ! -d "${REPO_DIR}/.git" ]; then
  echo "→ Clonando repositorio..."
  git clone "${REPO_URL}" "${REPO_DIR}"
else
  echo "→ Actualizando repositorio..."
  # fetch --dry-run puede fallar sin red; se envuelve para no abortar con set -e
  if (git -C "${REPO_DIR}" fetch --dry-run 2>/dev/null); then
    # pull --ff-only falla si hay cambios locales; informar al usuario
    if ! git -C "${REPO_DIR}" pull --ff-only 2>/dev/null; then
      echo "  ⚠ No se pudo actualizar: hay cambios locales en ${REPO_DIR}"
      echo "  Continúa con la versión local. Para actualizar: git -C ${REPO_DIR} stash && bash install.sh"
    fi
  else
    echo "  (sin acceso a red, usando versión local)"
  fi
fi

# Respaldar init.lua existente
if [ -f "${HS_DIR}/init.lua" ]; then
  cp "${HS_DIR}/init.lua" "${HS_DIR}/init.lua.bak"
  echo "→ Respaldo guardado: init.lua.bak"
fi

# Respaldar carpeta macspaces/ existente (con timestamp para no sobreescribir)
if [ -d "${HS_DIR}/macspaces" ]; then
  bak_dir="${HS_DIR}/macspaces.bak"
  if [ -d "${bak_dir}" ]; then
    mv "${bak_dir}" "${bak_dir}.$(date +%Y%m%d%H%M%S)"
    echo "→ Respaldo anterior renombrado con timestamp"
  fi
  cp -r "${HS_DIR}/macspaces" "${bak_dir}"
  echo "→ Respaldo guardado: macspaces.bak/"
fi

# Copiar archivos
echo "→ Copiando init.lua..."
cp "${REPO_DIR}/init.lua" "${HS_DIR}/init.lua"

echo "→ Copiando módulos macspaces/..."
cp -r "${REPO_DIR}/macspaces" "${HS_DIR}/macspaces"

# Compilar helper nativo para cambio de navegador predeterminado
echo "→ Compilando set_browser..."
if swiftc "${HS_DIR}/macspaces/set_browser.swift" -o "${HS_DIR}/set_browser" 2>/dev/null; then
  echo "✓ set_browser compilado"
else
  echo "⚠ No se pudo compilar set_browser (requiere Xcode CLI tools)"
fi

echo "✓ Instalación completa."
echo "  Abre Hammerspoon y presiona ⌘R para recargar."

#!/bin/bash
# ─────────────────────────────────────────────────────────────
# macSpaces Installer
# Detecta automáticamente si se ejecuta desde un clon local
# (→ symlinks) o via curl|bash (→ descarga y copia).
# Uso: bash install.sh [--dry-run]
# ─────────────────────────────────────────────────────────────

set -euo pipefail

VERSION="2.14.0"
REPO_URL="https://github.com/diegoiprg/dilware-tool-macGestorEntorno"
RAW_URL="https://raw.githubusercontent.com/diegoiprg/dilware-tool-macGestorEntorno/main"
DEST="$HOME/.hammerspoon"
DRY_RUN=false

# ── Colores ──

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── Helpers ──

info()  { echo -e "${CYAN}▸${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
fail()  { echo -e "${RED}✗${NC} $1"; exit 1; }

run() {
    if $DRY_RUN; then
        echo -e "  ${YELLOW}[dry-run]${NC} $*"
    else
        "$@"
    fi
}

# ── Argumentos ──

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --help|-h)
            echo "Uso: bash install.sh [--dry-run]"
            echo "  --dry-run  Previsualizar sin aplicar cambios"
            exit 0 ;;
    esac
done

# ── Detección de modo ──

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_MODE=false

if [ -f "$SCRIPT_DIR/init.lua" ] && [ -d "$SCRIPT_DIR/macspaces" ]; then
    LOCAL_MODE=true
fi

echo ""
echo -e "${BOLD}macSpaces v${VERSION} — Instalador${NC}"
if $DRY_RUN; then echo -e "${YELLOW}Modo dry-run: no se aplicarán cambios${NC}"; fi
if $LOCAL_MODE; then
    info "Modo local detectado → symlinks desde $SCRIPT_DIR"
else
    info "Modo remoto → descarga desde GitHub"
fi
echo ""

# ── 1. Xcode CLI Tools ──

if xcode-select -p &>/dev/null; then
    ok "Xcode CLI Tools instalado"
else
    info "Instalando Xcode CLI Tools..."
    run xcode-select --install 2>/dev/null || true
    warn "Acepta el diálogo de instalación y vuelve a ejecutar el instalador"
    exit 0
fi

# ── 2. Homebrew ──

if command -v brew &>/dev/null; then
    ok "Homebrew instalado"
else
    info "Instalando Homebrew..."
    if $DRY_RUN; then
        echo -e "  ${YELLOW}[dry-run]${NC} curl ... | bash (Homebrew)"
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
fi

# ── 3. Hammerspoon ──

if [ -d "/Applications/Hammerspoon.app" ]; then
    ok "Hammerspoon instalado"
else
    info "Instalando Hammerspoon..."
    run brew install --cask hammerspoon
fi

# ── 4. Preparar directorios ──

run mkdir -p "$DEST"
run mkdir -p "$DEST/macspaces"
run mkdir -p "$DEST/Spoons"

# ── 5. Funciones de instalación ──

# Instala un archivo como symlink (local) o copia (remoto).
# Elimina el destino previo (archivo regular o symlink) antes de crear.
install_as_link() {
    local rel_path="$1" dst="$2"
    if $DRY_RUN; then
        echo -e "  ${YELLOW}[dry-run]${NC} ln -sf $SCRIPT_DIR/$rel_path → $dst"
        ok "symlink: $(basename "$dst")"
        return
    fi
    rm -f "$dst"
    ln -sf "$SCRIPT_DIR/$rel_path" "$dst"
    ok "symlink: $(basename "$dst")"
}

install_as_copy() {
    local src="$1" dst="$2"
    if $DRY_RUN; then
        echo -e "  ${YELLOW}[dry-run]${NC} cp $(basename "$src") → $dst"
        ok "copiado: $(basename "$dst")"
        return
    fi
    cp "$src" "$dst"
    ok "copiado: $(basename "$dst")"
}

install_as_download() {
    local url="$1" dst="$2"
    if $DRY_RUN; then
        echo -e "  ${YELLOW}[dry-run]${NC} curl → $(basename "$dst")"
        ok "descargado: $(basename "$dst")"
        return
    fi
    curl -sL "$url" -o "$dst"
    ok "descargado: $(basename "$dst")"
}

# Instala un archivo según el modo (local → symlink, remoto → descarga)
install_file() {
    local rel_path="$1" dst="$2"
    if $LOCAL_MODE; then
        install_as_link "$rel_path" "$dst"
    else
        install_as_download "$RAW_URL/$rel_path" "$dst"
    fi
}

# ── 6. Instalar archivos ──

# Lista completa de módulos Lua (excepto config.lua que va aparte)
LUA_MODULES=(
    audio battery bluetooth breaks browsers claude clipboard
    config dnd focus_menu focus_overlay gemini history hotkeys
    launcher menu music network pomodoro presentation
    profiles utils version vpn
)

# Archivos shell
SH_FILES=(gemini-usage)

# init.lua → raíz de Hammerspoon
install_file "init.lua" "$DEST/init.lua"

# macspaces/*.lua → symlinks/descargas
for mod in "${LUA_MODULES[@]}"; do
    install_file "macspaces/${mod}.lua" "$DEST/macspaces/${mod}.lua"
done

# macspaces/*.sh → symlinks/descargas + permisos de ejecución
for sh in "${SH_FILES[@]}"; do
    install_file "macspaces/${sh}.sh" "$DEST/macspaces/${sh}.sh"
    $DRY_RUN || chmod +x "$DEST/macspaces/${sh}.sh"
done

# set_browser.swift → symlink/descarga (fuente para compilación)
install_file "macspaces/set_browser.swift" "$DEST/macspaces/set_browser.swift"

# bt_devices.swift → siempre copia (archivo auxiliar de runtime)
if $LOCAL_MODE; then
    install_as_copy "$SCRIPT_DIR/bt_devices.swift" "$DEST/bt_devices.swift"
else
    install_as_download "$RAW_URL/bt_devices.swift" "$DEST/bt_devices.swift"
fi

# config_local.lua → plantilla para overrides del usuario (solo si no existe)
if [ ! -f "$DEST/macspaces/config_local.lua" ]; then
    if $DRY_RUN; then
        echo -e "  ${YELLOW}[dry-run]${NC} crear config_local.lua (plantilla)"
    else
        cat > "$DEST/macspaces/config_local.lua" << 'EOF'
-- Overrides locales de macSpaces.
-- Los valores aquí sobreescriben los defaults de config.lua.
-- Solo incluye lo que quieras cambiar.

local M = {}

-- Ejemplo:
-- M.pomodoro = { work_minutes = 50 }
-- M.breaks = { interval_minutes = 60 }

return M
EOF
        chmod 600 "$DEST/macspaces/config_local.lua"
    fi
    ok "config_local.lua creado (personalizable)"
else
    ok "config_local.lua preservado (ya existe)"
fi

# ── 7. Compilar helper Swift ──

info "Compilando set_browser..."
if $DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} swiftc set_browser.swift → set_browser"
    ok "set_browser compilado"
else
    swiftc "$DEST/macspaces/set_browser.swift" -o "$DEST/set_browser" 2>/dev/null \
        && ok "set_browser compilado" \
        || warn "No se pudo compilar set_browser (se compilará al iniciar Hammerspoon)"
fi

# ── 8. Lanzar Hammerspoon ──

if ! pgrep -q Hammerspoon; then
    info "Lanzando Hammerspoon..."
    run open -a Hammerspoon
else
    ok "Hammerspoon ya está corriendo — recarga con ⌘R"
fi

# ── Resumen ──

echo ""
echo -e "${BOLD}${GREEN}Instalación completada${NC}"
echo ""
if $LOCAL_MODE; then
    echo -e "  Los archivos son symlinks a ${CYAN}$SCRIPT_DIR${NC}"
    echo -e "  Los cambios en el repo se reflejan al instante."
fi
echo ""
echo "  Permisos necesarios en Ajustes del Sistema → Privacidad y Seguridad:"
echo "    • Accesibilidad → Hammerspoon ✓"
echo "    • Automatización → Hammerspoon ✓"
echo ""

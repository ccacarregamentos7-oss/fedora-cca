#!/usr/bin/env bash
# ============================================================================
# vscode-setup.sh — Configuração completa do VS Code para CCA Carregamentos
# Instala extensões, copia configurações e snippets
# ============================================================================
set -uo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✔]${NC} $*"; }
warn()    { echo -e "${YELLOW}[⚠]${NC} $*"; }
error()   { echo -e "${RED}[✘]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
VSCODE_USER_DIR="$HOME/.config/Code/User"

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           VS CODE SETUP — CCA CARREGAMENTOS                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================================
# VERIFICAR SE VS CODE ESTÁ INSTALADO
# ============================================================================
if ! command -v code &> /dev/null; then
    error "VS Code não encontrado. Instale primeiro:"
    echo "  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc"
    echo "  sudo dnf install code"
    exit 1
fi

info "VS Code encontrado: $(code --version | head -1)"

# ============================================================================
# EXTENSÕES BASE — ESSENCIAIS PARA DESENVOLVIMENTO
# ============================================================================
BASE_EXTENSIONS=(
    # AI / Copilot
    "github.copilot-chat"

    # Tema e Ícones
    "catppuccin.catppuccin-vsc"
    "catppuccin.catppuccin-vsc-icons"
    "pkief.material-icon-theme"

    # TypeScript / JavaScript
    "esbenp.prettier-vscode"
    "dbaeumer.vscode-eslint"
    "bradlc.vscode-tailwindcss"
    "yoavbls.pretty-ts-errors"
    "wix.vscode-import-cost"
    "christian-kohler.path-intellisense"
    "christian-kohler.npm-intellisense"
    "formulahendry.auto-rename-tag"

    # React / Frontend
    "dsznajder.es7-react-js-snippets"

    # Python
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-python.black-formatter"
    "ms-python.isort"
    "ms-python.debugpy"

    # Git
    "eamodio.gitlens"
    "mhutchie.git-graph"
    "donjayamanne.githistory"
    "github.vscode-pull-request-github"

    # Database
    "ms-ossdata.vscode-pgsql"
    "mtxr.sqltools"
    "mtxr.sqltools-driver-pg"
    "cweijan.vscode-database-client2"

    # Docker / Containers
    "ms-azuretools.vscode-docker"

    # Remote / SSH
    "ms-vscode-remote.remote-ssh"
    "ms-vscode-remote.remote-ssh-edit"
    "ms-vscode-remote.vscode-remote-extensionpack"

    # Produtividade
    "usernamehw.errorlens"
    "gruntfuggly.todo-tree"
    "alefragnani.project-manager"
    "streetsidesoftware.code-spell-checker"
    "streetsidesoftware.code-spell-checker-portuguese-brazilian"
    "aaron-bond.better-comments"
    "naumovs.color-highlight"
    "yzhang.markdown-all-in-one"
    "mikestead.dotenv"
    "formulahendry.code-runner"
    "oderwat.indent-rainbow"
    "ritwickdey.liveserver"

    # API / HTTP
    "rangav.vscode-thunder-client"

    # Shell
    "foxundermoon.shell-format"

    # YAML
    "redhat.vscode-yaml"

    # Prisma
    "prisma.prisma"

    # Jupyter
    "ms-toolsai.jupyter"
    "ms-toolsai.jupyter-keymap"
    "ms-toolsai.jupyter-renderers"

    # Language Pack
    "ms-ceintl.vscode-language-pack-pt-br"

    # PowerShell (para Windows compat)
    "ms-vscode.powershell"
)

# ============================================================================
# INSTALAR EXTENSÕES
# ============================================================================
info "Instalando ${#BASE_EXTENSIONS[@]} extensões..."
echo ""

installed=0
failed=0

for ext in "${BASE_EXTENSIONS[@]}"; do
    if code --list-extensions | grep -qi "^${ext}$"; then
        echo -e "  ${GREEN}●${NC} $ext (já instalado)"
    else
        echo -ne "  ${YELLOW}○${NC} $ext ... "
        if code --install-extension "$ext" --force &> /dev/null; then
            echo -e "${GREEN}OK${NC}"
            ((installed++))
        else
            echo -e "${RED}FALHOU${NC}"
            ((failed++))
        fi
    fi
done

echo ""
success "Instaladas: $installed novas | Falhou: $failed"

# ============================================================================
# COPIAR CONFIGURAÇÕES
# ============================================================================
info "Copiando configurações..."

mkdir -p "$VSCODE_USER_DIR/snippets"
mkdir -p "$VSCODE_USER_DIR/tasks"

# settings.json
if [[ -f "$REPO_DIR/dotfiles/vscode/settings.json" ]]; then
    cp "$REPO_DIR/dotfiles/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
    success "settings.json copiado"
fi

# keybindings.json
if [[ -f "$REPO_DIR/dotfiles/vscode/keybindings.json" ]]; then
    cp "$REPO_DIR/dotfiles/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
    success "keybindings.json copiado"
fi

# snippets
if [[ -d "$REPO_DIR/dotfiles/vscode/snippets" ]]; then
    cp "$REPO_DIR/dotfiles/vscode/snippets/"*.json "$VSCODE_USER_DIR/snippets/" 2>/dev/null
    success "Snippets copiados"
fi

# tasks.json (global)
if [[ -f "$REPO_DIR/dotfiles/vscode/tasks/tasks.json" ]]; then
    cp "$REPO_DIR/dotfiles/vscode/tasks/tasks.json" "$VSCODE_USER_DIR/tasks/tasks.json"
    success "tasks.json copiado"
fi

# ============================================================================
# CONFIGURAR PROJECT MANAGER
# ============================================================================
info "Configurando projetos CCA..."

PROJECTS_FILE="$HOME/.config/Code/User/globalStorage/alefragnani.project-manager/projects.json"
mkdir -p "$(dirname "$PROJECTS_FILE")"

if [[ ! -f "$PROJECTS_FILE" ]]; then
    cat > "$PROJECTS_FILE" << 'EOF'
[
  {"name": "📱 Aplicativo Celular", "rootPath": "/home/coconai/git/aplicativo-celular", "tags": ["cca", "mobile"]},
  {"name": "👥 Sistema RH", "rootPath": "/home/coconai/git/sistema-rh-cca", "tags": ["cca", "erp"]},
  {"name": "💰 Financeiro", "rootPath": "/home/coconai/git/financeiro-cca", "tags": ["cca", "python"]},
  {"name": "🌐 Website", "rootPath": "/home/coconai/git/cca-website", "tags": ["cca", "web"]},
  {"name": "🤖 Zap Bot", "rootPath": "/home/coconai/git/cca-zap-bot", "tags": ["cca", "bot"]},
  {"name": "🖥️ Cargo Flight Board", "rootPath": "/home/coconai/git/cargoflightboard", "tags": ["cca", "dashboard"]},
  {"name": "🔧 Config CCA", "rootPath": "/home/coconai/git/config-cca", "tags": ["cca", "infra"]},
  {"name": "🐧 Fedora CCA", "rootPath": "/home/coconai/git/fedora-cca", "tags": ["cca", "dotfiles"]},
  {"name": "🖧 Servidor Local", "rootPath": "/home/coconai/git/servidor-local-dev", "tags": ["cca", "infra"]},
  {"name": "📂 Portal CCA", "rootPath": "/home/coconai/git/portal-cca", "tags": ["cca", "web"]},
  {"name": "🔌 Rede MikroTik", "rootPath": "/home/coconai/git/rede-mikrotik", "tags": ["cca", "network"]},
  {"name": "🧠 Memory Bank", "rootPath": "/home/coconai/git/memory-bank-cca", "tags": ["cca", "ai"]},
  {"name": "📝 Docs CCA", "rootPath": "/home/coconai/git/docs-cca", "tags": ["cca", "docs"]},
  {"name": "🔗 Shared CCA", "rootPath": "/home/coconai/git/shared-cca", "tags": ["cca", "lib"]},
  {"name": "📜 Scripts CCA", "rootPath": "/home/coconai/git/scripts-cca", "tags": ["cca", "python"]},
  {"name": "⚙️ Automação CCA", "rootPath": "/home/coconai/git/automacao-cca", "tags": ["cca", "meta"]},
  {"name": "📦 CCA Work", "rootPath": "/home/coconai/git/cca-work", "tags": ["cca", "meta"]},
  {"name": "💸 Planejamento Caixa", "rootPath": "/home/coconai/git/projeto-planejamento-caixa", "tags": ["cca", "finance"]}
]
EOF
    success "Projetos configurados no Project Manager"
else
    warn "projects.json já existe, mantendo configuração atual"
fi

# ============================================================================
# RESUMO
# ============================================================================
echo ""
echo -e "${CYAN}${BOLD}═══ Setup Completo ═══${NC}"
echo ""
echo -e "  ${GREEN}●${NC} $(code --list-extensions | wc -l) extensões instaladas"
echo -e "  ${GREEN}●${NC} Tema: Catppuccin Mocha"
echo -e "  ${GREEN}●${NC} Ícones: Catppuccin"
echo -e "  ${GREEN}●${NC} ${#BASE_EXTENSIONS[@]} extensões essenciais verificadas"
echo -e "  ${GREEN}●${NC} 18 projetos CCA no Project Manager"
echo ""
echo -e "${YELLOW}Reinicie o VS Code para aplicar todas as alterações.${NC}"
echo ""

#!/usr/bin/env bash
# ============================================================
#  backup.sh — Backup de configurações para fedora-cca repo
#  Uso: ./scripts/backup.sh
#  Coleta configs atuais e atualiza o repo
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}═══ Backup de Configs — Fedora CCA ═══${NC}"
echo ""
echo "Repo: $REPO_DIR"
echo "Data: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ─── 1. Dotfiles ────────────────────────────────────────────
info "Copiando dotfiles..."

# Zshrc
if [[ -f "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$REPO_DIR/dotfiles/zshrc"
    ok "~/.zshrc"
fi

# Gitconfig
if [[ -f "$HOME/.gitconfig" ]]; then
    cp "$HOME/.gitconfig" "$REPO_DIR/dotfiles/gitconfig"
    ok "~/.gitconfig"
fi

# ─── 2. VS Code ─────────────────────────────────────────────
info "Copiando configs VS Code..."

VSCODE_DIR="$HOME/.config/Code/User"
DOTFILES_VSCODE="$REPO_DIR/dotfiles/vscode"

mkdir -p "$DOTFILES_VSCODE"

# Settings
if [[ -f "$VSCODE_DIR/settings.json" ]]; then
    cp "$VSCODE_DIR/settings.json" "$DOTFILES_VSCODE/settings.json"
    ok "VS Code settings.json"
fi

# Keybindings
if [[ -f "$VSCODE_DIR/keybindings.json" ]]; then
    cp "$VSCODE_DIR/keybindings.json" "$DOTFILES_VSCODE/keybindings.json"
    ok "VS Code keybindings.json"
fi

# Extensions
code --list-extensions > "$DOTFILES_VSCODE/extensions.txt" 2>/dev/null || true
TOTAL_EXT=$(wc -l < "$DOTFILES_VSCODE/extensions.txt")
ok "VS Code extensões ($TOTAL_EXT)"

# Prompts / Instructions
PROMPTS_DIR="$VSCODE_DIR/prompts"
if [[ -d "$PROMPTS_DIR" ]] && ls "$PROMPTS_DIR"/*.md &>/dev/null; then
    mkdir -p "$DOTFILES_VSCODE/prompts"
    cp "$PROMPTS_DIR"/*.md "$DOTFILES_VSCODE/prompts/"
    ok "VS Code prompts/instructions"
fi

# ─── 3. GNOME ───────────────────────────────────────────────
info "Exportando configs GNOME..."
mkdir -p "$REPO_DIR/gnome"

if command -v dconf &>/dev/null; then
    dconf dump /org/gnome/ > "$REPO_DIR/gnome/dconf-dump.ini"
    GNOME_LINES=$(wc -l < "$REPO_DIR/gnome/dconf-dump.ini")
    ok "GNOME dconf ($GNOME_LINES linhas)"
fi

# Lista de extensões GNOME
if command -v gnome-extensions &>/dev/null; then
    gnome-extensions list --enabled > "$REPO_DIR/gnome/extensions-enabled.txt" 2>/dev/null || true
    ok "Lista extensões GNOME"
fi

# ─── 4. Docker ──────────────────────────────────────────────
info "Copiando config Docker..."
mkdir -p "$REPO_DIR/docker"

if [[ -f "/etc/docker/daemon.json" ]]; then
    sudo cp /etc/docker/daemon.json "$REPO_DIR/docker/daemon.json" 2>/dev/null || \
        cp /etc/docker/daemon.json "$REPO_DIR/docker/daemon.json" 2>/dev/null || true
    ok "Docker daemon.json"
fi

# ─── 5. Systemd custom units ────────────────────────────────
info "Verificando serviços customizados..."
mkdir -p "$REPO_DIR/systemd"

# Copiar units customizados do user
USER_UNITS="$HOME/.config/systemd/user"
if [[ -d "$USER_UNITS" ]]; then
    cp "$USER_UNITS"/*.{service,timer} "$REPO_DIR/systemd/" 2>/dev/null || true
    ok "Systemd user units"
else
    warn "Sem units customizados em $USER_UNITS"
fi

# ─── 6. Lista de pacotes ────────────────────────────────────
info "Coletando pacotes instalados..."
mkdir -p "$REPO_DIR/docs"

rpm -qa | grep -iE "docker|tailscale|scrcpy|android|nodejs|code|zsh|gnome-tweaks|nvidia|cockpit|pm2|git-lfs" | sort \
    > "$REPO_DIR/docs/pacotes-instalados.txt"
TOTAL_PKG=$(wc -l < "$REPO_DIR/docs/pacotes-instalados.txt")
ok "Pacotes relevantes ($TOTAL_PKG)"

# Lista completa separada
rpm -qa --qf '%{NAME}\n' | sort > "$REPO_DIR/docs/pacotes-todos.txt"
TOTAL_ALL=$(wc -l < "$REPO_DIR/docs/pacotes-todos.txt")
ok "Todos os pacotes ($TOTAL_ALL)"

# ─── 7. Info do sistema ─────────────────────────────────────
info "Coletando info do sistema..."
cat > "$REPO_DIR/docs/sistema-info.txt" <<EOF
# Info do Sistema — $(date '+%Y-%m-%d %H:%M:%S')

OS:       $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
Kernel:   $(uname -r)
Hostname: $(hostname)
User:     $(whoami)
Shell:    $SHELL
Desktop:  ${XDG_CURRENT_DESKTOP:-N/A}

CPU:      $(lscpu | grep 'Model name' | sed 's/.*: *//')
RAM:      $(free -h | awk '/Mem:/ {print $2}')
GPU:      $(lspci | grep -i nvidia | head -1 | sed 's/.*: //' 2>/dev/null || echo "N/A")
Disk:     $(df -h / | awk 'NR==2 {print $2, "total,", $3, "usado,", $4, "livre"}')

Docker:   $(docker --version 2>/dev/null || echo "N/A")
Node:     $(node --version 2>/dev/null || echo "N/A")
pnpm:     $(pnpm --version 2>/dev/null || echo "N/A")
Git:      $(git --version 2>/dev/null || echo "N/A")
EOF
ok "sistema-info.txt"

# ─── 8. Git status ──────────────────────────────────────────
echo ""
info "Verificando mudanças no repo..."
cd "$REPO_DIR"
echo ""

if git diff --quiet && git diff --cached --quiet; then
    ok "Nenhuma mudança detectada"
else
    echo -e "${YELLOW}Mudanças detectadas:${NC}"
    git status --short
    echo ""
    echo -e "  Para commitar: ${CYAN}cd $REPO_DIR && git add -A && git commit -m 'backup: $(date +%Y-%m-%d)'${NC}"
fi

# ─── Resumo ─────────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══ Backup Completo! ═══${NC}"
echo ""
echo -e "  Arquivos atualizados em: ${CYAN}$REPO_DIR${NC}"
echo -e "  Para commit e push:"
echo -e "  ${CYAN}cd $REPO_DIR${NC}"
echo -e "  ${CYAN}git add -A && git commit -m 'backup: $(date +%Y-%m-%d)' && git push${NC}"
echo ""

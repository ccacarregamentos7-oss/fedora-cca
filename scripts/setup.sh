#!/usr/bin/env bash
# ============================================================
#  setup.sh — Setup inicial completo do Fedora CCA
#  Uso: sudo ./scripts/setup.sh   (ou sem sudo para etapas de user)
# ============================================================
set -euo pipefail

# ─── Cores ───────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()  { echo -e "${RED}[ERRO]${NC}  $*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# ─── Verificar se é Fedora ───────────────────────────────────
if ! grep -qi fedora /etc/os-release 2>/dev/null; then
    fail "Este script é para Fedora. Distro detectada: $(grep ^ID= /etc/os-release)"
fi

FEDORA_VERSION=$(rpm -E %fedora)
info "Fedora $FEDORA_VERSION detectado"

# ─── 1. Atualizar sistema ───────────────────────────────────
info "Atualizando sistema..."
sudo dnf upgrade -y --refresh
ok "Sistema atualizado"

# ─── 2. Repos extras ────────────────────────────────────────
info "Habilitando RPM Fusion..."
sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm" \
    2>/dev/null || warn "RPM Fusion já habilitado"
ok "RPM Fusion configurado"

# ─── 3. Pacotes essenciais do sistema ───────────────────────
info "Instalando pacotes base..."
sudo dnf install -y \
    zsh \
    git \
    git-lfs \
    curl \
    wget \
    htop \
    btop \
    neofetch \
    unzip \
    jq \
    ripgrep \
    fd-find \
    bat \
    eza \
    fzf \
    tmux \
    gnome-tweaks \
    dconf-editor \
    cockpit \
    cockpit-podman \
    util-linux-user
ok "Pacotes base instalados"

# ─── 4. Zsh como shell padrão ───────────────────────────────
if [[ "$SHELL" != *zsh* ]]; then
    info "Configurando Zsh como shell padrão..."
    chsh -s "$(which zsh)" "$USER"
    ok "Zsh configurado (relogar para ativar)"
else
    ok "Zsh já é o shell padrão"
fi

# ─── 5. Oh My Zsh ───────────────────────────────────────────
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Instalando Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "Oh My Zsh instalado"
else
    ok "Oh My Zsh já instalado"
fi

# ─── 6. Plugins Zsh ─────────────────────────────────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    info "Instalando zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    info "Instalando zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi
ok "Plugins Zsh configurados"

# ─── 7. NVM + Node.js ───────────────────────────────────────
if [[ ! -d "$HOME/.nvm" ]]; then
    info "Instalando NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 22
    nvm alias default 22
    ok "NVM + Node.js 22 instalados"
else
    ok "NVM já instalado"
fi

# ─── 8. pnpm ────────────────────────────────────────────────
if ! command -v pnpm &>/dev/null; then
    info "Instalando pnpm..."
    npm install -g pnpm
    ok "pnpm instalado"
else
    ok "pnpm já instalado ($(pnpm --version))"
fi

# ─── 9. Docker ──────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
    info "Instalando Docker..."
    sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    ok "Docker instalado (relogar para grupo docker)"
else
    ok "Docker já instalado ($(docker --version | cut -d' ' -f3 | tr -d ','))"
fi

# ─── 10. Tailscale ──────────────────────────────────────────
if ! command -v tailscale &>/dev/null; then
    info "Instalando Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    sudo systemctl enable --now tailscaled
    ok "Tailscale instalado — executar: sudo tailscale up"
else
    ok "Tailscale já instalado ($(tailscale version | head -1))"
fi

# ─── 11. VS Code ────────────────────────────────────────────
if ! command -v code &>/dev/null; then
    info "Instalando VS Code..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    cat <<EOF | sudo tee /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    sudo dnf install -y code
    ok "VS Code instalado"
else
    ok "VS Code já instalado"
fi

# ─── 12. Extensões VS Code ──────────────────────────────────
EXTENSIONS_FILE="$REPO_DIR/dotfiles/vscode/extensions.txt"
if [[ -f "$EXTENSIONS_FILE" ]]; then
    info "Instalando extensões VS Code..."
    while IFS= read -r ext; do
        [[ -z "$ext" || "$ext" =~ ^# ]] && continue
        code --install-extension "$ext" --force 2>/dev/null || warn "Falhou: $ext"
    done < "$EXTENSIONS_FILE"
    ok "Extensões VS Code instaladas"
fi

# ─── 13. Android SDK (para Capacitor) ───────────────────────
if [[ ! -d "$HOME/Android/Sdk" ]]; then
    info "Instalando Android SDK (cmdline-tools)..."
    sudo dnf install -y android-tools
    mkdir -p "$HOME/Android/Sdk/cmdline-tools"
    CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    wget -q "$CMDLINE_URL" -O /tmp/cmdline-tools.zip
    unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-extract
    mv /tmp/cmdline-tools-extract/cmdline-tools "$HOME/Android/Sdk/cmdline-tools/latest"
    rm -rf /tmp/cmdline-tools.zip /tmp/cmdline-tools-extract
    ok "Android SDK instalado"
else
    ok "Android SDK já instalado"
fi

# ─── 14. Scrcpy ─────────────────────────────────────────────
if ! command -v scrcpy &>/dev/null; then
    info "Instalando Scrcpy..."
    sudo dnf install -y scrcpy
    ok "Scrcpy instalado"
else
    ok "Scrcpy já instalado ($(scrcpy --version 2>&1 | head -1))"
fi

# ─── 15. GitHub CLI ─────────────────────────────────────────
if ! command -v gh &>/dev/null; then
    info "Instalando GitHub CLI..."
    sudo dnf install -y gh
    ok "GitHub CLI instalado"
else
    ok "GitHub CLI já instalado ($(gh --version | head -1))"
fi

# ─── 16. Aplicar dotfiles ───────────────────────────────────
info "Aplicando dotfiles..."

# Zshrc
if [[ -f "$REPO_DIR/dotfiles/zshrc" ]]; then
    cp "$REPO_DIR/dotfiles/zshrc" "$HOME/.zshrc"
    ok "~/.zshrc aplicado"
fi

# Gitconfig
if [[ -f "$REPO_DIR/dotfiles/gitconfig" ]]; then
    cp "$REPO_DIR/dotfiles/gitconfig" "$HOME/.gitconfig"
    ok "~/.gitconfig aplicado"
fi

# VS Code settings
if [[ -f "$REPO_DIR/dotfiles/vscode/settings.json" ]]; then
    mkdir -p "$HOME/.config/Code/User"
    cp "$REPO_DIR/dotfiles/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
    ok "VS Code settings aplicado"
fi

# Docker daemon.json
if [[ -f "$REPO_DIR/docker/daemon.json" ]]; then
    sudo mkdir -p /etc/docker
    sudo cp "$REPO_DIR/docker/daemon.json" /etc/docker/daemon.json
    sudo systemctl restart docker 2>/dev/null || true
    ok "Docker daemon.json aplicado"
fi

# GNOME dconf
if [[ -f "$REPO_DIR/gnome/dconf-dump.ini" ]]; then
    warn "Para restaurar configs GNOME: dconf load /org/gnome/ < gnome/dconf-dump.ini"
fi

# ─── 17. Habilitar serviços ─────────────────────────────────
info "Habilitando serviços..."
sudo systemctl enable --now cockpit.socket 2>/dev/null || true
sudo systemctl enable --now docker 2>/dev/null || true
sudo systemctl enable --now tailscaled 2>/dev/null || true
ok "Serviços habilitados"

# ─── 18. Clonar repos CCA ───────────────────────────────────
info "Verificando repos CCA em ~/git/..."
mkdir -p "$HOME/git"

CCA_REPOS=(
    aplicativo-celular
    automacao-cca
    cargoflightboard
    cca-website
    cca-work
    cca-zap-bot
    config-cca
    docs-cca
    financeiro-cca
    logs-cca
    memory-bank-cca
    portal-cca
    projeto-planejamento-caixa
    rede-mikrotik
    scripts-cca
    servidor-local-dev
    shared-cca
    sistema-rh-cca
)

for repo in "${CCA_REPOS[@]}"; do
    if [[ ! -d "$HOME/git/$repo" ]]; then
        info "Clonando $repo..."
        git clone "git@github.com:ccacarregamentos7-oss/$repo.git" "$HOME/git/$repo" 2>/dev/null || \
            warn "Falhou ao clonar $repo"
    else
        ok "$repo já existe"
    fi
done

# ─── Resumo ─────────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup Fedora CCA — Completo!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}Próximos passos:${NC}"
echo -e "  1. Fazer logout e login (para zsh + grupo docker)"
echo -e "  2. ${YELLOW}tailscale up${NC} — conectar à VPN"
echo -e "  3. ${YELLOW}gh auth login${NC} — autenticar GitHub"
echo -e "  4. Testar: ${YELLOW}docker ps && node -v && pnpm -v${NC}"
echo ""

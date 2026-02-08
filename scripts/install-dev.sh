#!/usr/bin/env bash
# ============================================================
#  install-dev.sh — Ferramentas extras de desenvolvimento
#  Uso: ./scripts/install-dev.sh
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }

echo -e "${CYAN}═══ Ferramentas de Dev Extras — CCA ═══${NC}"
echo ""

# ─── 1. Ferramentas CLI modernas ────────────────────────────
info "Instalando ferramentas CLI..."
sudo dnf install -y \
    ripgrep \
    fd-find \
    bat \
    eza \
    fzf \
    jq \
    yq \
    httpie \
    tldr \
    tokei \
    delta \
    lazygit \
    2>/dev/null || true
ok "Ferramentas CLI"

# ─── 2. DBeaver (gerenciador de banco) ──────────────────────
if ! command -v dbeaver &>/dev/null && ! flatpak list 2>/dev/null | grep -q dbeaver; then
    info "Instalando DBeaver via Flatpak..."
    flatpak install -y flathub io.dbeaver.DBeaverCommunity 2>/dev/null || \
        warn "Falha ao instalar DBeaver — instalar manualmente"
else
    ok "DBeaver já instalado"
fi

# ─── 3. Insomnia / Bruno (API testing) ──────────────────────
if ! flatpak list 2>/dev/null | grep -q bruno; then
    info "Instalando Bruno (API Client) via Flatpak..."
    flatpak install -y flathub com.usebruno.Bruno 2>/dev/null || \
        warn "Falha ao instalar Bruno"
else
    ok "Bruno já instalado"
fi

# ─── 4. Ferramentas de rede ─────────────────────────────────
info "Instalando ferramentas de rede..."
sudo dnf install -y \
    nmap \
    mtr \
    iperf3 \
    net-tools \
    bind-utils \
    traceroute \
    2>/dev/null || true
ok "Ferramentas de rede"

# ─── 5. Python extras (para financeiro-cca) ─────────────────
info "Instalando Python dev tools..."
sudo dnf install -y \
    python3-pip \
    python3-devel \
    python3-virtualenv \
    2>/dev/null || true

pip install --user --upgrade \
    pandas \
    openpyxl \
    requests \
    python-dotenv \
    black \
    ruff \
    2>/dev/null || true
ok "Python tools"

# ─── 6. Capacitor/Android dev ───────────────────────────────
info "Verificando Android dev tools..."
if command -v adb &>/dev/null; then
    ok "ADB disponível ($(adb version | head -1))"
else
    warn "ADB não encontrado — instalar android-tools: sudo dnf install android-tools"
fi

if command -v scrcpy &>/dev/null; then
    ok "Scrcpy disponível ($(scrcpy --version 2>&1 | head -1))"
else
    warn "Scrcpy não encontrado — sudo dnf install scrcpy"
fi

# ─── 7. Fontes para desenvolvimento ─────────────────────────
info "Verificando fontes de dev..."
if ! fc-list | grep -qi "JetBrains" 2>/dev/null; then
    info "Instalando JetBrains Mono..."
    sudo dnf install -y jetbrains-mono-fonts-all 2>/dev/null || \
        warn "JetBrains Mono não disponível no repo"
else
    ok "JetBrains Mono já instalada"
fi

if ! fc-list | grep -qi "FiraCode" 2>/dev/null; then
    info "Instalando Fira Code..."
    sudo dnf install -y fira-code-fonts 2>/dev/null || true
else
    ok "Fira Code já instalada"
fi

# ─── 8. Ferramentas de monitoramento ────────────────────────
info "Instalando ferramentas de monitoramento..."
sudo dnf install -y \
    htop \
    btop \
    iotop \
    sysstat \
    2>/dev/null || true
ok "Ferramentas de monitoramento"

# ─── 9. Global npm packages ─────────────────────────────────
if command -v npm &>/dev/null; then
    info "Instalando pacotes npm globais..."
    npm install -g \
        typescript \
        tsx \
        @types/node \
        pm2 \
        drizzle-kit \
        wrangler \
        2>/dev/null || true
    ok "npm globals"
fi

# ─── Resumo ─────────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══ Ferramentas de Dev instaladas! ═══${NC}"
echo ""
echo -e "  Destaques instalados:"
echo -e "  - ${CYAN}lazygit${NC}    — UI para git no terminal"
echo -e "  - ${CYAN}delta${NC}      — Diff colorido bonito"
echo -e "  - ${CYAN}ripgrep${NC}    — Busca ultra-rápida"
echo -e "  - ${CYAN}bat${NC}        — cat com syntax highlight"
echo -e "  - ${CYAN}DBeaver${NC}    — Gerenciador de banco (Flatpak)"
echo -e "  - ${CYAN}Bruno${NC}      — Cliente API (Flatpak)"
echo ""

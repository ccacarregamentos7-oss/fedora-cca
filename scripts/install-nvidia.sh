#!/usr/bin/env bash
# ============================================================
#  install-nvidia.sh — Driver NVIDIA proprietário + CUDA
#  Requer RPM Fusion habilitado (setup.sh faz isso)
#  Uso: sudo ./scripts/install-nvidia.sh
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()  { echo -e "${RED}[ERRO]${NC}  $*"; exit 1; }

echo -e "${CYAN}═══ NVIDIA Driver + CUDA — Fedora CCA ═══${NC}"
echo ""

# ─── Verificar GPU NVIDIA ────────────────────────────────────
if ! lspci | grep -i nvidia &>/dev/null; then
    fail "Nenhuma GPU NVIDIA detectada!"
fi

GPU_MODEL=$(lspci | grep -i nvidia | head -1 | sed 's/.*: //')
info "GPU detectada: $GPU_MODEL"

# ─── Verificar RPM Fusion ───────────────────────────────────
if ! dnf repolist | grep -q rpmfusion-nonfree; then
    fail "RPM Fusion Nonfree não habilitado! Execute setup.sh primeiro."
fi
ok "RPM Fusion Nonfree habilitado"

# ─── 1. Instalar driver NVIDIA via akmod ────────────────────
info "Instalando driver NVIDIA (akmod)..."
sudo dnf install -y \
    akmod-nvidia \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-cuda \
    xorg-x11-drv-nvidia-cuda-libs \
    xorg-x11-drv-nvidia-libs
ok "Driver NVIDIA instalado"

# ─── 2. Aguardar compilação do módulo ───────────────────────
info "Aguardando compilação do módulo kernel (pode demorar ~5min)..."
sudo akmods --force
sudo dracut --force
ok "Módulo kernel compilado"

# ─── 3. CUDA Toolkit ────────────────────────────────────────
info "Instalando CUDA toolkit..."
sudo dnf install -y \
    xorg-x11-drv-nvidia-cuda \
    nvidia-persistenced \
    nvidia-settings \
    nvidia-modprobe
ok "CUDA toolkit instalado"

# ─── 4. NVIDIA Container Toolkit (para Docker + GPU) ────────
if command -v docker &>/dev/null; then
    info "Instalando NVIDIA Container Toolkit..."
    if ! rpm -q nvidia-container-toolkit &>/dev/null; then
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
            sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
        sudo dnf install -y nvidia-container-toolkit
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
        ok "NVIDIA Container Toolkit instalado"
    else
        ok "NVIDIA Container Toolkit já instalado"
    fi
fi

# ─── 5. Verificação ─────────────────────────────────────────
echo ""
info "Verificando instalação..."

if command -v nvidia-smi &>/dev/null; then
    echo ""
    nvidia-smi
    echo ""
    ok "nvidia-smi funcionando!"
else
    warn "nvidia-smi não disponível — reboot necessário"
fi

# ─── Verificar módulo carregado ──────────────────────────────
if lsmod | grep -q nvidia; then
    ok "Módulo nvidia carregado no kernel"
else
    warn "Módulo nvidia NÃO carregado — reinicie o sistema!"
fi

# ─── Resumo ─────────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══ NVIDIA Setup Completo! ═══${NC}"
echo ""
echo -e "  Driver: akmod-nvidia (compila automaticamente em updates de kernel)"
echo -e "  GPU: $GPU_MODEL"
echo ""
echo -e "  ${YELLOW}⚠️  REBOOT NECESSÁRIO se é a primeira instalação!${NC}"
echo -e "  ${CYAN}sudo reboot${NC}"
echo ""
echo -e "  Após reboot, verificar com:"
echo -e "  ${CYAN}nvidia-smi${NC}"
echo -e "  ${CYAN}glxinfo | grep 'OpenGL renderer'${NC}"
echo ""

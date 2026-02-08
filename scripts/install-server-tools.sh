#!/usr/bin/env bash
# ============================================================
#  install-server-tools.sh — Ferramentas avançadas de servidor/rede
#  Transforma o notebook em estação de gerenciamento pro
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }

echo -e "${CYAN}═══ Server & Network Management Tools — CCA ═══${NC}"
echo ""

# ─── 1. Apps GUI (Flatpak) ──────────────────────────────────
info "Instalando apps GUI via Flatpak..."

# Podman Desktop — gerenciamento de containers
flatpak install -y flathub io.podman_desktop.PodmanDesktop 2>/dev/null && ok "Podman Desktop" || ok "Podman Desktop já instalado"

# Mission Center — monitor de performance
flatpak install -y flathub io.missioncenter.MissionCenter 2>/dev/null && ok "Mission Center" || ok "Mission Center já instalado"

# DBeaver — gerenciamento de banco
flatpak install -y flathub io.dbeaver.DBeaverCommunity 2>/dev/null && ok "DBeaver" || ok "DBeaver já instalado"

# WinBox — MikroTik
flatpak install -y flathub com.mikrotik.WinBox 2>/dev/null && ok "WinBox" || ok "WinBox já instalado"

echo ""

# ─── 2. Remmina + plugins ───────────────────────────────────
info "Instalando Remmina com plugins..."
sudo dnf install -y \
    remmina \
    remmina-plugins-rdp \
    remmina-plugins-vnc \
    remmina-plugins-exec \
    2>/dev/null || true
ok "Remmina + RDP/VNC/Exec"

# ─── 3. Ferramentas de rede ─────────────────────────────────
info "Instalando ferramentas de rede..."
sudo dnf install -y \
    nmap \
    mtr \
    iperf3 \
    net-tools \
    bind-utils \
    traceroute \
    whois \
    tcpdump \
    wireshark-cli \
    ethtool \
    socat \
    2>/dev/null || true
ok "Ferramentas de rede"

# ─── 4. Ansible ─────────────────────────────────────────────
info "Instalando Ansible..."
sudo dnf install -y ansible sshpass 2>/dev/null || true
ok "Ansible + sshpass"

# ─── 5. Cockpit (admin web) ─────────────────────────────────
info "Instalando Cockpit completo..."
sudo dnf install -y \
    cockpit \
    cockpit-podman \
    cockpit-machines \
    cockpit-networkmanager \
    cockpit-storaged \
    cockpit-selinux \
    2>/dev/null || true
sudo systemctl enable --now cockpit.socket 2>/dev/null || true
ok "Cockpit (https://localhost:9090)"

# ─── 6. Monitoramento de hardware ───────────────────────────
info "Instalando monitores de hardware..."
sudo dnf install -y \
    btop \
    nvtop \
    iotop-c \
    sysstat \
    lm_sensors \
    smartmontools \
    hdparm \
    2>/dev/null || true
ok "btop, nvtop, iotop, sensors, smartctl"

# ─── 7. Ferramentas de DNS/certificado ──────────────────────
info "Instalando ferramentas de DNS e TLS..."
sudo dnf install -y \
    certbot \
    openssl \
    2>/dev/null || true
ok "certbot + openssl"

# ─── 8. Ferramentas de log ──────────────────────────────────
info "Instalando ferramentas de log..."
sudo dnf install -y \
    lnav \
    multitail \
    2>/dev/null || true
ok "lnav + multitail"

# ─── Resumo ─────────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══ Server Tools Instalados! ═══${NC}"
echo ""
echo -e "  ${BOLD}GUI Apps:${NC}"
echo -e "    ${CYAN}Podman Desktop${NC}  — Containers visual"
echo -e "    ${CYAN}Remmina${NC}         — RDP/VNC/SSH remoto"
echo -e "    ${CYAN}DBeaver${NC}         — Banco de dados"
echo -e "    ${CYAN}Mission Center${NC}  — Performance"
echo -e "    ${CYAN}WinBox${NC}          — MikroTik"
echo ""
echo -e "  ${BOLD}Terminal:${NC}"
echo -e "    ${CYAN}nmap${NC}  ${CYAN}mtr${NC}  ${CYAN}tcpdump${NC}  ${CYAN}wireshark-cli${NC}"
echo -e "    ${CYAN}btop${NC}  ${CYAN}nvtop${NC}  ${CYAN}lnav${NC}  ${CYAN}ansible${NC}"
echo ""
echo -e "  ${BOLD}Web Admin:${NC}"
echo -e "    ${CYAN}Cockpit${NC}     — https://localhost:9090"
echo -e "    ${CYAN}Portainer${NC}   — https://localhost:9443"
echo -e "    ${CYAN}Grafana${NC}     — http://localhost:3000"
echo ""
echo -e "  Use ${CYAN}cca-admin${NC} para o painel centralizado!"
echo ""

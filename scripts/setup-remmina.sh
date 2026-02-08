#!/usr/bin/env bash
# ============================================================
#  setup-remmina.sh — Configurar conexões Remmina para CCA
#  Cria perfis pré-configurados para todos os servidores
# ============================================================
set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }

REMMINA_DIR="$HOME/.local/share/remmina"
mkdir -p "$REMMINA_DIR"

create_ssh_profile() {
    local name="$1" host="$2" user="${3:-root}" port="${4:-22}"
    local filename="cca-${name,,}.remmina"

    cat > "$REMMINA_DIR/$filename" <<EOF
[remmina]
name=CCA - ${name}
protocol=SSH
server=${host}:${port}
username=${user}
group=CCA Carregamentos
colordepth=32
ssh_tunnel_enabled=0
EOF
    ok "SSH: $name ($host)"
}

create_vnc_profile() {
    local name="$1" host="$2" port="${3:-5900}"
    local filename="cca-vnc-${name,,}.remmina"

    cat > "$REMMINA_DIR/$filename" <<EOF
[remmina]
name=CCA VNC - ${name}
protocol=VNC
server=${host}:${port}
group=CCA Carregamentos
colordepth=32
quality=2
EOF
    ok "VNC: $name ($host)"
}

create_web_profile() {
    local name="$1" url="$2"
    local filename="cca-web-${name,,}.remmina"

    cat > "$REMMINA_DIR/$filename" <<EOF
[remmina]
name=CCA Web - ${name}
protocol=HTTP
server=${url}
group=CCA Carregamentos
EOF
    ok "Web: $name ($url)"
}

echo -e "${CYAN}═══ Configurando Remmina — CCA ═══${NC}"
echo ""

info "Criando perfis SSH..."
create_ssh_profile "Dev Server (LXC 200)" "192.168.50.200" "root"
create_ssh_profile "Proxmox (Hypervisor)" "192.168.50.100" "root"
create_ssh_profile "Produção (DO)"        "138.197.46.13"  "root"
create_ssh_profile "Home Assistant"        "192.168.50.101" "root"
create_ssh_profile "Zap Bot"              "192.168.50.102" "root"
create_ssh_profile "MikroTik"             "192.168.50.1"   "admin"

info "Criando perfis SSH via Tailscale..."
create_ssh_profile "Dev Tailscale"     "100.83.114.49"   "root"
create_ssh_profile "Proxmox Tailscale" "100.109.148.37"  "root"

echo ""
info "Criando perfis Web (referência)..."
create_web_profile "Proxmox UI"    "https://192.168.50.100:8006"
create_web_profile "Cockpit"       "https://localhost:9090"
create_web_profile "Grafana"       "http://localhost:3000"
create_web_profile "Portainer"     "https://localhost:9443"
create_web_profile "Home Assistant" "http://192.168.50.101:8123"

echo ""
ok "Perfis Remmina criados em $REMMINA_DIR"
echo -e "  Abrir Remmina: ${CYAN}remmina &${NC}"
echo ""

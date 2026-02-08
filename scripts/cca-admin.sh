#!/usr/bin/env bash
# ============================================================
#  cca-admin.sh — Painel de Gerenciamento CCA
#  Centro de controle do notebook para toda a infra CCA.
#
#  Uso: cca-admin [comando]
#  Sem argumentos abre o menu interativo.
# ============================================================
set -uo pipefail

# ─── Cores ───────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

# ─── Infra CCA — IPs e Hosts ────────────────────────────────
PROXMOX_IP="192.168.50.100"
DEV_SERVER_IP="192.168.50.200"
HA_IP="192.168.50.101"
PROD_IP="138.197.46.13"
NOTEBOOK_IP="192.168.50.10"
ZAP_BOT_IP="192.168.50.102"

TAILSCALE_PROXMOX="100.109.148.37"
TAILSCALE_DEV="100.83.114.49"
TAILSCALE_NOTE="100.125.175.35"

MIKROTIK_IP="192.168.50.1"
CELULAR_IP="192.168.50.20"

# ─── Helpers ─────────────────────────────────────────────────
info()    { echo -e "  ${CYAN}●${NC} $*"; }
ok()      { echo -e "  ${GREEN}✔${NC} $*"; }
fail_msg(){ echo -e "  ${RED}✘${NC} $*"; }
warn()    { echo -e "  ${YELLOW}⚠${NC} $*"; }
header()  { echo -e "\n${BOLD}${BLUE}═══ $* ═══${NC}\n"; }
divider() { echo -e "${DIM}  ─────────────────────────────────────────${NC}"; }

check_host() {
    local name="$1" ip="$2"
    if ping -c1 -W1 "$ip" &>/dev/null; then
        ok "${GREEN}${name}${NC} ($ip) — online"
        return 0
    else
        fail_msg "${RED}${name}${NC} ($ip) — offline"
        return 1
    fi
}

check_port() {
    local name="$1" ip="$2" port="$3"
    if timeout 2 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null; then
        ok "${name} :${port} — aberta"
        return 0
    else
        fail_msg "${name} :${port} — fechada"
        return 1
    fi
}

ssh_cmd() {
    local host="$1"; shift
    ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "root@${host}" "$@" 2>/dev/null
}

# ═════════════════════════════════════════════════════════════
#  COMANDOS
# ═════════════════════════════════════════════════════════════

# ─── STATUS: Visão geral de toda a infra ────────────────────
cmd_status() {
    header "Status Geral da Infra CCA"

    echo -e "  ${BOLD}Rede Local (192.168.50.x)${NC}"
    divider
    check_host "Proxmox (Hypervisor)" "$PROXMOX_IP"
    check_host "Dev Server (LXC 200)" "$DEV_SERVER_IP"
    check_host "Home Assistant (100)"  "$HA_IP"
    check_host "Zap Bot (101)"         "$ZAP_BOT_IP"
    check_host "MikroTik (Router)"     "$MIKROTIK_IP"
    check_host "Celular S24"           "$CELULAR_IP"

    echo ""
    echo -e "  ${BOLD}Produção / Cloud${NC}"
    divider
    check_host "Produção (DigitalOcean)" "$PROD_IP"

    echo ""
    echo -e "  ${BOLD}VPN Tailscale${NC}"
    divider
    local ts_status
    ts_status=$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null || echo "unknown")
    if [[ "$ts_status" == "Running" ]]; then
        ok "Tailscale: ${GREEN}Conectado${NC} ($TAILSCALE_NOTE)"
    else
        fail_msg "Tailscale: ${RED}$ts_status${NC}"
    fi

    echo ""
    echo -e "  ${BOLD}Serviços Dev Server (192.168.50.200)${NC}"
    divider
    check_port "PostgreSQL"    "$DEV_SERVER_IP" 5432
    check_port "API CCA"       "$DEV_SERVER_IP" 3001
    check_port "Grafana"       "localhost"       3000
    check_port "Loki"          "localhost"       3100
    check_port "Portainer"     "localhost"       9443
    check_port "Cockpit (Note)" "localhost"      9090

    echo ""
    echo -e "  ${BOLD}Notebook Local${NC}"
    divider
    local cpu_usage mem_total mem_used gpu_temp
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' 2>/dev/null || echo "?")
    mem_total=$(free -h | awk '/Mem:/{print $2}')
    mem_used=$(free -h | awk '/Mem:/{print $3}')
    gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo "?")
    info "CPU: ${cpu_usage}% | RAM: ${mem_used}/${mem_total} | GPU: ${gpu_temp}°C"
    info "Kernel: $(uname -r)"
    info "Uptime: $(uptime -p | sed 's/up //')"

    # Docker local
    local containers_running
    containers_running=$(docker ps -q 2>/dev/null | wc -l)
    info "Docker containers rodando: $containers_running"

    echo ""
}

# ─── SERVICES: Status dos serviços no dev server ─────────────
cmd_services() {
    header "Serviços no Dev Server (192.168.50.200)"

    echo -e "  ${BOLD}PM2 Processes${NC}"
    divider
    ssh_cmd "$DEV_SERVER_IP" "pm2 list" 2>/dev/null || fail_msg "Não foi possível conectar ao dev server"

    echo ""
    echo -e "  ${BOLD}PostgreSQL Databases${NC}"
    divider
    ssh_cmd "$DEV_SERVER_IP" "sudo -u postgres psql -c \"SELECT datname, pg_size_pretty(pg_database_size(datname)) as size FROM pg_database WHERE datistemplate = false ORDER BY pg_database_size(datname) DESC;\"" 2>/dev/null || fail_msg "Não foi possível listar bancos"

    echo ""
    echo -e "  ${BOLD}Disk Usage${NC}"
    divider
    ssh_cmd "$DEV_SERVER_IP" "df -h / | tail -1" 2>/dev/null || fail_msg "Sem acesso"

    echo ""
    echo -e "  ${BOLD}RAM${NC}"
    divider
    ssh_cmd "$DEV_SERVER_IP" "free -h | head -2" 2>/dev/null || fail_msg "Sem acesso"
}

# ─── DOCKER: Containers locais ──────────────────────────────
cmd_docker() {
    header "Docker / Podman — Containers Locais"

    echo -e "  ${BOLD}Docker Containers${NC}"
    divider
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || fail_msg "Docker não acessível"

    echo ""
    echo -e "  ${BOLD}Podman Containers${NC}"
    divider
    podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || info "Nenhum container Podman"

    echo ""
    echo -e "  ${BOLD}Docker Volumes${NC}"
    divider
    docker volume ls --format "table {{.Name}}\t{{.Driver}}" 2>/dev/null || true

    echo ""
    echo -e "  ${BOLD}Docker Networks${NC}"
    divider
    docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" 2>/dev/null || true
}

# ─── NETWORK: Scan e diagnóstico de rede ─────────────────────
cmd_network() {
    header "Diagnóstico de Rede"

    echo -e "  ${BOLD}Interfaces Locais${NC}"
    divider
    ip -br addr show | grep -v "^lo" | while read -r iface state addr rest; do
        if [[ "$state" == "UP" ]]; then
            ok "$iface — $addr"
        else
            fail_msg "$iface — $state"
        fi
    done

    echo ""
    echo -e "  ${BOLD}DNS Resolução${NC}"
    divider
    info "Google: $(dig +short google.com @8.8.8.8 | head -1 || echo 'falhou')"
    info "Gateway: $(ip route | grep default | awk '{print $3}')"

    echo ""
    echo -e "  ${BOLD}Tailscale Peers${NC}"
    divider
    tailscale status 2>/dev/null | head -15 || fail_msg "Tailscale não conectado"

    echo ""
    echo -e "  ${BOLD}Portas Abertas neste Note${NC}"
    divider
    ss -tlnp 2>/dev/null | grep LISTEN | awk '{print $4}' | sort -u | while read -r addr; do
        info "$addr"
    done
}

# ─── SCAN: Nmap da rede local ────────────────────────────────
cmd_scan() {
    header "Scan da Rede 192.168.50.0/24"
    warn "Executando nmap (pode demorar ~30s)..."
    echo ""
    sudo nmap -sn 192.168.50.0/24 2>/dev/null | grep -E "scan report|MAC Address" | \
        sed 's/Nmap scan report for /  ● /' | sed 's/MAC Address: /    MAC: /'
    echo ""
    ok "Scan completo"
}

# ─── DB: Acesso rápido aos bancos ────────────────────────────
cmd_db() {
    header "Bancos de Dados CCA"

    echo -e "  ${BOLD}Dev (192.168.50.200)${NC}"
    divider
    ssh_cmd "$DEV_SERVER_IP" "sudo -u postgres psql -c \"
        SELECT datname as banco,
               pg_size_pretty(pg_database_size(datname)) as tamanho,
               numbackends as conexoes
        FROM pg_stat_database
        WHERE datname NOT IN ('template0','template1','postgres')
        ORDER BY pg_database_size(datname) DESC;
    \"" 2>/dev/null || fail_msg "Sem acesso ao PostgreSQL dev"

    echo ""
    echo -e "  ${BOLD}Acessar DBeaver${NC}"
    divider
    info "flatpak run io.dbeaver.DBeaverCommunity &"
    info "Ou: cca-admin open dbeaver"
}

# ─── DEPLOY: Status de deploy ────────────────────────────────
cmd_deploy() {
    header "Status de Deploy"

    echo -e "  ${BOLD}Produção (138.197.46.13)${NC}"
    divider
    ssh_cmd "$PROD_IP" "pm2 list" 2>/dev/null || fail_msg "Sem acesso SSH à produção"

    echo ""
    echo -e "  ${BOLD}Dev Server (192.168.50.200)${NC}"
    divider
    ssh_cmd "$DEV_SERVER_IP" "pm2 list" 2>/dev/null || fail_msg "Sem acesso ao dev server"

    echo ""
    echo -e "  ${BOLD}Git Status dos Repos${NC}"
    divider
    for repo_dir in ~/git/*/; do
        repo_name=$(basename "$repo_dir")
        if [[ -d "$repo_dir/.git" ]]; then
            local ahead behind
            cd "$repo_dir"
            git fetch -q 2>/dev/null || true
            ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "?")
            behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "?")
            if [[ "$ahead" == "0" && "$behind" == "0" ]]; then
                ok "$repo_name — sincronizado"
            else
                warn "$repo_name — ↑${ahead} ↓${behind}"
            fi
            cd - >/dev/null
        fi
    done
}

# ─── PROXMOX: Status do hypervisor ──────────────────────────
cmd_proxmox() {
    header "Proxmox VE ($PROXMOX_IP)"

    echo -e "  ${BOLD}VMs e Containers${NC}"
    divider
    ssh_cmd "$PROXMOX_IP" "qm list 2>/dev/null; pct list 2>/dev/null" || \
        fail_msg "Sem acesso SSH ao Proxmox"

    echo ""
    echo -e "  ${BOLD}Recursos${NC}"
    divider
    ssh_cmd "$PROXMOX_IP" "free -h | head -2; echo ''; df -h / | tail -1" || true

    echo ""
    echo -e "  ${BOLD}Acesso Web${NC}"
    divider
    info "Proxmox: https://$PROXMOX_IP:8006"
}

# ─── OPEN: Abrir aplicativos de gerenciamento ────────────────
cmd_open() {
    local app="${1:-menu}"

    case "$app" in
        podman|pd)
            info "Abrindo Podman Desktop..."
            flatpak run io.podman_desktop.PodmanDesktop &>/dev/null &
            ;;
        remmina|rdp)
            info "Abrindo Remmina..."
            remmina &>/dev/null &
            ;;
        dbeaver|db)
            info "Abrindo DBeaver..."
            flatpak run io.dbeaver.DBeaverCommunity &>/dev/null &
            ;;
        mission|mc|monitor)
            info "Abrindo Mission Center..."
            flatpak run io.missioncenter.MissionCenter &>/dev/null &
            ;;
        cockpit|ck)
            info "Abrindo Cockpit no browser..."
            xdg-open "https://localhost:9090" &>/dev/null &
            ;;
        proxmox|pve)
            info "Abrindo Proxmox no browser..."
            xdg-open "https://$PROXMOX_IP:8006" &>/dev/null &
            ;;
        grafana|graf)
            info "Abrindo Grafana no browser..."
            xdg-open "http://localhost:3000" &>/dev/null &
            ;;
        portainer|port)
            info "Abrindo Portainer no browser..."
            xdg-open "https://localhost:9443" &>/dev/null &
            ;;
        winbox|mikrotik)
            info "Abrindo WinBox..."
            flatpak run com.mikrotik.WinBox &>/dev/null &
            ;;
        nvtop|gpu)
            nvtop
            ;;
        btop|top)
            btop
            ;;
        *)
            echo -e "  Apps disponíveis:"
            echo -e "  ${CYAN}podman${NC}    — Podman Desktop"
            echo -e "  ${CYAN}remmina${NC}   — Acesso remoto RDP/VNC"
            echo -e "  ${CYAN}dbeaver${NC}   — Gerenciador de banco"
            echo -e "  ${CYAN}mission${NC}   — Monitor de performance"
            echo -e "  ${CYAN}cockpit${NC}   — Painel web do note"
            echo -e "  ${CYAN}proxmox${NC}   — Painel web Proxmox"
            echo -e "  ${CYAN}grafana${NC}   — Dashboard monitoramento"
            echo -e "  ${CYAN}portainer${NC} — Docker web UI"
            echo -e "  ${CYAN}winbox${NC}    — MikroTik WinBox"
            echo -e "  ${CYAN}nvtop${NC}     — Monitor GPU NVIDIA"
            echo -e "  ${CYAN}btop${NC}      — Monitor sistema"
            ;;
    esac
}

# ─── CONNECT: SSH rápido ─────────────────────────────────────
cmd_connect() {
    local target="${1:-menu}"

    case "$target" in
        dev|200)     ssh root@"$DEV_SERVER_IP" ;;
        proxmox|pve) ssh root@"$PROXMOX_IP" ;;
        prod)        ssh root@"$PROD_IP" ;;
        ha)          ssh root@"$HA_IP" ;;
        zap|bot)     ssh root@"$ZAP_BOT_IP" ;;
        mikrotik|mk) ssh admin@"$MIKROTIK_IP" ;;
        *)
            echo -e "  Destinos disponíveis:"
            echo -e "  ${CYAN}dev${NC}       — Dev Server (LXC 200)"
            echo -e "  ${CYAN}proxmox${NC}   — Proxmox Hypervisor"
            echo -e "  ${CYAN}prod${NC}      — Produção DigitalOcean"
            echo -e "  ${CYAN}ha${NC}        — Home Assistant"
            echo -e "  ${CYAN}zap${NC}       — Zap Bot Server"
            echo -e "  ${CYAN}mikrotik${NC}  — MikroTik Router"
            ;;
    esac
}

# ─── BACKUP: Sync rápido de configs ──────────────────────────
cmd_backup() {
    header "Backup de Configs"
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -x "$script_dir/backup.sh" ]]; then
        "$script_dir/backup.sh"
    else
        fail_msg "backup.sh não encontrado em $script_dir"
    fi
}

# ─── HELP ────────────────────────────────────────────────────
cmd_help() {
    echo ""
    echo -e "${BOLD}${BLUE}  CCA Admin — Painel de Gerenciamento${NC}"
    echo -e "${DIM}  Centro de controle para toda a infra CCA Carregamentos${NC}"
    echo ""
    echo -e "  ${BOLD}Diagnóstico${NC}"
    echo -e "    ${CYAN}status${NC}      Visão geral de toda a infra (ping, portas, recursos)"
    echo -e "    ${CYAN}services${NC}    PM2, PostgreSQL, disk no dev server"
    echo -e "    ${CYAN}network${NC}     Interfaces, DNS, Tailscale, portas abertas"
    echo -e "    ${CYAN}scan${NC}        Nmap scan da rede 192.168.50.0/24"
    echo -e "    ${CYAN}docker${NC}      Containers Docker/Podman locais"
    echo -e "    ${CYAN}proxmox${NC}     Status do hypervisor Proxmox"
    echo -e "    ${CYAN}db${NC}          Bancos de dados e tamanhos"
    echo -e "    ${CYAN}deploy${NC}      Status de deploy prod/dev + git sync"
    echo ""
    echo -e "  ${BOLD}Aplicativos${NC}"
    echo -e "    ${CYAN}open [app]${NC}  Abrir app (podman/remmina/dbeaver/mission/cockpit/...)"
    echo ""
    echo -e "  ${BOLD}Conexão${NC}"
    echo -e "    ${CYAN}ssh [host]${NC}  SSH rápido (dev/proxmox/prod/ha/zap/mikrotik)"
    echo ""
    echo -e "  ${BOLD}Manutenção${NC}"
    echo -e "    ${CYAN}backup${NC}      Backup das configs do note para o repo"
    echo -e "    ${CYAN}help${NC}        Este menu"
    echo ""
    echo -e "  ${DIM}Exemplos:${NC}"
    echo -e "    cca-admin status"
    echo -e "    cca-admin open dbeaver"
    echo -e "    cca-admin ssh dev"
    echo -e "    cca-admin scan"
    echo ""
}

# ═════════════════════════════════════════════════════════════
#  MENU INTERATIVO
# ═════════════════════════════════════════════════════════════
cmd_menu() {
    clear
    echo ""
    echo -e "${BOLD}${BLUE}  ╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}  ║     CCA Admin — Centro de Controle           ║${NC}"
    echo -e "${BOLD}${BLUE}  ║     Fedora Workstation · coconai (Ellon)      ║${NC}"
    echo -e "${BOLD}${BLUE}  ╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Diagnóstico${NC}"
    echo -e "    ${CYAN}1)${NC} Status geral da infra"
    echo -e "    ${CYAN}2)${NC} Serviços dev server"
    echo -e "    ${CYAN}3)${NC} Rede e conectividade"
    echo -e "    ${CYAN}4)${NC} Scan nmap rede local"
    echo -e "    ${CYAN}5)${NC} Docker / Podman"
    echo -e "    ${CYAN}6)${NC} Proxmox hypervisor"
    echo -e "    ${CYAN}7)${NC} Bancos de dados"
    echo -e "    ${CYAN}8)${NC} Status deploy (prod + dev)"
    echo ""
    echo -e "  ${BOLD}Abrir Aplicativos${NC}"
    echo -e "    ${MAGENTA}p)${NC} Podman Desktop"
    echo -e "    ${MAGENTA}r)${NC} Remmina (acesso remoto)"
    echo -e "    ${MAGENTA}d)${NC} DBeaver (banco de dados)"
    echo -e "    ${MAGENTA}m)${NC} Mission Center (monitor)"
    echo -e "    ${MAGENTA}g)${NC} Grafana (dashboard)"
    echo -e "    ${MAGENTA}w)${NC} WinBox (MikroTik)"
    echo -e "    ${MAGENTA}c)${NC} Cockpit (web admin)"
    echo ""
    echo -e "  ${BOLD}Conexão SSH${NC}"
    echo -e "    ${GREEN}s1)${NC} Dev Server (200)"
    echo -e "    ${GREEN}s2)${NC} Proxmox"
    echo -e "    ${GREEN}s3)${NC} Produção"
    echo ""
    echo -e "    ${DIM}b) Backup configs  |  h) Help  |  q) Sair${NC}"
    echo ""

    read -rp "  Escolha: " choice

    case "$choice" in
        1)  cmd_status ;;
        2)  cmd_services ;;
        3)  cmd_network ;;
        4)  cmd_scan ;;
        5)  cmd_docker ;;
        6)  cmd_proxmox ;;
        7)  cmd_db ;;
        8)  cmd_deploy ;;
        p)  cmd_open podman ;;
        r)  cmd_open remmina ;;
        d)  cmd_open dbeaver ;;
        m)  cmd_open mission ;;
        g)  cmd_open grafana ;;
        w)  cmd_open winbox ;;
        c)  cmd_open cockpit ;;
        s1) cmd_connect dev ;;
        s2) cmd_connect proxmox ;;
        s3) cmd_connect prod ;;
        b)  cmd_backup ;;
        h)  cmd_help ;;
        q)  echo "  Até mais!"; exit 0 ;;
        *)  warn "Opção inválida: $choice" ;;
    esac

    echo ""
    read -rp "  [Enter para voltar ao menu, q para sair] " again
    [[ "$again" != "q" ]] && cmd_menu
}

# ═════════════════════════════════════════════════════════════
#  MAIN — Roteamento de comandos
# ═════════════════════════════════════════════════════════════
main() {
    local cmd="${1:-menu}"
    shift 2>/dev/null || true

    case "$cmd" in
        status)             cmd_status ;;
        services|svc)       cmd_services ;;
        docker|containers)  cmd_docker ;;
        network|net)        cmd_network ;;
        scan|nmap)          cmd_scan ;;
        db|database)        cmd_db ;;
        deploy)             cmd_deploy ;;
        proxmox|pve)        cmd_proxmox ;;
        open)               cmd_open "$@" ;;
        ssh|connect)        cmd_connect "$@" ;;
        backup)             cmd_backup ;;
        help|-h|--help)     cmd_help ;;
        menu)               cmd_menu ;;
        *)                  warn "Comando desconhecido: $cmd"; cmd_help ;;
    esac
}

main "$@"

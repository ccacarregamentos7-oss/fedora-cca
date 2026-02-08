#!/usr/bin/env bash
# ============================================================================
# cca-theme — Gerenciador de Temas Visuais do GNOME
# Grupo CCA Carregamentos — Fedora 43
# ============================================================================
set -uo pipefail

# ---------------------------------------------------------------------------
# Cores do terminal
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

# ---------------------------------------------------------------------------
# Caminhos
# ---------------------------------------------------------------------------
WALLPAPER_DIR="/usr/share/backgrounds"
CUSTOM_WALLPAPER_DIR="$HOME/Imagens/wallpapers"
THEMES_DIR="$HOME/.themes"
ICONS_DIR="$HOME/.local/share/icons"
CURSORS_DIR="$HOME/.icons"

# ---------------------------------------------------------------------------
# Extensões necessárias
# ---------------------------------------------------------------------------
REQUIRED_EXTENSIONS=(
    "user-theme@gnome-shell-extensions.gcampax.github.com"
    "dash-to-dock@micxgx.gmail.com"
    "blur-my-shell@aunetx"
)

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              🎨  CCA THEME MANAGER  🎨                     ║"
    echo "║          Personalização Visual — GNOME Desktop              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✔]${NC} $*"; }
warn()    { echo -e "${YELLOW}[⚠]${NC} $*"; }
error()   { echo -e "${RED}[✘]${NC} $*"; }

gset() {
    gsettings set "$@" 2>/dev/null
}

gget() {
    gsettings get "$@" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Verificar e habilitar extensões
# ---------------------------------------------------------------------------
ensure_extensions() {
    local current
    current=$(gget org.gnome.shell enabled-extensions)
    local need_update=false

    for ext in "${REQUIRED_EXTENSIONS[@]}"; do
        if [[ "$current" != *"$ext"* ]]; then
            need_update=true
            break
        fi
    done

    if $need_update; then
        info "Habilitando extensões necessárias..."
        local ext_list="["
        # Manter extensões existentes
        for ext in "background-logo@fedorahosted.org" "appindicatorsupport@rgcjonas.gmail.com" "${REQUIRED_EXTENSIONS[@]}"; do
            ext_list+="'$ext', "
        done
        ext_list="${ext_list%, }]"
        gset org.gnome.shell enabled-extensions "$ext_list"
        success "Extensões habilitadas"
    fi
}

# ============================================================================
# PRESETS DE TEMAS
# ============================================================================

# ---------------------------------------------------------------------------
# 🌙 Catppuccin Mocha — Tema dark elegante, tons quentes
# ---------------------------------------------------------------------------
apply_catppuccin_mocha() {
    info "Aplicando ${MAGENTA}Catppuccin Mocha${NC} (Dark Elegante)..."

    # Preferência escuro
    gset org.gnome.desktop.interface color-scheme 'prefer-dark'
    gset org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default'
    gset org.gnome.shell.extensions.user-theme name 'catppuccin-mocha-blue-standard+default'

    # Ícones e cursores
    gset org.gnome.desktop.interface icon-theme 'Tela-blue-dark'
    gset org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
    gset org.gnome.desktop.interface cursor-size 24

    # Fontes
    gset org.gnome.desktop.interface font-name 'Cantarell 11'
    gset org.gnome.desktop.interface document-font-name 'Cantarell 11'
    gset org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
    gset org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Bold 11'

    # Cor de destaque
    gset org.gnome.desktop.interface accent-color 'blue'

    # Wallpaper
    gset org.gnome.desktop.background picture-uri "file://${WALLPAPER_DIR}/gnome/adwaita-d.jxl"
    gset org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER_DIR}/gnome/adwaita-d.jxl"
    gset org.gnome.desktop.background picture-options 'zoom'

    # Tela de bloqueio
    gset org.gnome.desktop.screensaver picture-uri "file://${WALLPAPER_DIR}/gnome/blobs-d.svg"

    # Dash to Dock — estilo flutuante, translúcido
    configure_dock "mocha"

    # Blur My Shell
    configure_blur "dark"

    success "Catppuccin Mocha aplicado!"
}

# ---------------------------------------------------------------------------
# 🌊 Catppuccin Frappé — Tema dark suave, tons frios
# ---------------------------------------------------------------------------
apply_catppuccin_frappe() {
    info "Aplicando ${BLUE}Catppuccin Frappé${NC} (Dark Suave)..."

    gset org.gnome.desktop.interface color-scheme 'prefer-dark'
    gset org.gnome.desktop.interface gtk-theme 'catppuccin-frappe-blue-standard+default'
    gset org.gnome.shell.extensions.user-theme name 'catppuccin-frappe-blue-standard+default'

    gset org.gnome.desktop.interface icon-theme 'Tela-nord-dark'
    gset org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'
    gset org.gnome.desktop.interface cursor-size 24

    gset org.gnome.desktop.interface font-name 'Cantarell 11'
    gset org.gnome.desktop.interface document-font-name 'Cantarell 11'
    gset org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
    gset org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Bold 11'

    gset org.gnome.desktop.interface accent-color 'teal'

    gset org.gnome.desktop.background picture-uri "file://${WALLPAPER_DIR}/fedora-workstation/mermaid_dark.webp"
    gset org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER_DIR}/fedora-workstation/mermaid_dark.webp"
    gset org.gnome.desktop.background picture-options 'zoom'

    gset org.gnome.desktop.screensaver picture-uri "file://${WALLPAPER_DIR}/gnome/morphogenesis-d.svg"

    configure_dock "frappe"
    configure_blur "dark"

    success "Catppuccin Frappé aplicado!"
}

# ---------------------------------------------------------------------------
# ☀️ Catppuccin Latte — Tema claro, clean e profissional
# ---------------------------------------------------------------------------
apply_catppuccin_latte() {
    info "Aplicando ${YELLOW}Catppuccin Latte${NC} (Claro Profissional)..."

    gset org.gnome.desktop.interface color-scheme 'prefer-light'
    gset org.gnome.desktop.interface gtk-theme 'catppuccin-latte-blue-standard+default'
    gset org.gnome.shell.extensions.user-theme name 'catppuccin-latte-blue-standard+default'

    gset org.gnome.desktop.interface icon-theme 'Tela-blue'
    gset org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
    gset org.gnome.desktop.interface cursor-size 24

    gset org.gnome.desktop.interface font-name 'Cantarell 11'
    gset org.gnome.desktop.interface document-font-name 'Cantarell 11'
    gset org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
    gset org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Bold 11'

    gset org.gnome.desktop.interface accent-color 'blue'

    gset org.gnome.desktop.background picture-uri "file://${WALLPAPER_DIR}/fedora-workstation/glasscurtains_light.webp"
    gset org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER_DIR}/fedora-workstation/glasscurtains_dark.webp"
    gset org.gnome.desktop.background picture-options 'zoom'

    gset org.gnome.desktop.screensaver picture-uri "file://${WALLPAPER_DIR}/gnome/adwaita-l.jxl"

    configure_dock "latte"
    configure_blur "light"

    success "Catppuccin Latte aplicado!"
}

# ---------------------------------------------------------------------------
# 🧛 Dracula — Tema dark clássico, tons roxos
# ---------------------------------------------------------------------------
apply_dracula() {
    info "Aplicando ${MAGENTA}Dracula${NC} (Dark Clássico)..."

    gset org.gnome.desktop.interface color-scheme 'prefer-dark'
    gset org.gnome.desktop.interface gtk-theme 'Dracula'
    gset org.gnome.shell.extensions.user-theme name 'Dracula'

    gset org.gnome.desktop.interface icon-theme 'Tela-dracula-dark'
    gset org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Amber'
    gset org.gnome.desktop.interface cursor-size 24

    gset org.gnome.desktop.interface font-name 'Cantarell 11'
    gset org.gnome.desktop.interface document-font-name 'Cantarell 11'
    gset org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
    gset org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Bold 11'

    gset org.gnome.desktop.interface accent-color 'purple'

    gset org.gnome.desktop.background picture-uri "file://${WALLPAPER_DIR}/fedora-workstation/futurecity_dark.webp"
    gset org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER_DIR}/fedora-workstation/futurecity_dark.webp"
    gset org.gnome.desktop.background picture-options 'zoom'

    gset org.gnome.desktop.screensaver picture-uri "file://${WALLPAPER_DIR}/gnome/drool-d.svg"

    configure_dock "dracula"
    configure_blur "dark"

    success "Dracula aplicado!"
}

# ---------------------------------------------------------------------------
# 🏢 CCA Corporate — Tema profissional da empresa
# ---------------------------------------------------------------------------
apply_cca_corporate() {
    info "Aplicando ${GREEN}CCA Corporate${NC} (Profissional)..."

    gset org.gnome.desktop.interface color-scheme 'prefer-dark'
    gset org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default'
    gset org.gnome.shell.extensions.user-theme name 'catppuccin-mocha-blue-standard+default'

    gset org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    gset org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
    gset org.gnome.desktop.interface cursor-size 24

    gset org.gnome.desktop.interface font-name 'Cantarell 11'
    gset org.gnome.desktop.interface document-font-name 'Cantarell 11'
    gset org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
    gset org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Bold 11'

    gset org.gnome.desktop.interface accent-color 'green'

    gset org.gnome.desktop.background picture-uri "file://${WALLPAPER_DIR}/fedora-workstation/montclair_dark.webp"
    gset org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER_DIR}/fedora-workstation/montclair_dark.webp"
    gset org.gnome.desktop.background picture-options 'zoom'

    gset org.gnome.desktop.screensaver picture-uri "file://${WALLPAPER_DIR}/gnome/pixels-d.jxl"

    configure_dock "corporate"
    configure_blur "dark"

    success "CCA Corporate aplicado!"
}

# ---------------------------------------------------------------------------
# 🔥 Cyberpunk — Tema neon vibrante
# ---------------------------------------------------------------------------
apply_cyberpunk() {
    info "Aplicando ${RED}Cyberpunk${NC} (Neon Vibrante)..."

    gset org.gnome.desktop.interface color-scheme 'prefer-dark'
    gset org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default'
    gset org.gnome.shell.extensions.user-theme name 'catppuccin-mocha-blue-standard+default'

    gset org.gnome.desktop.interface icon-theme 'Tela-orange-dark'
    gset org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Amber'
    gset org.gnome.desktop.interface cursor-size 24

    gset org.gnome.desktop.interface font-name 'Cantarell 11'
    gset org.gnome.desktop.interface document-font-name 'Cantarell 11'
    gset org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
    gset org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Bold 11'

    gset org.gnome.desktop.interface accent-color 'orange'

    gset org.gnome.desktop.background picture-uri "file://${WALLPAPER_DIR}/gnome/lcd-rainbow-d.jxl"
    gset org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER_DIR}/gnome/lcd-rainbow-d.jxl"
    gset org.gnome.desktop.background picture-options 'zoom'

    gset org.gnome.desktop.screensaver picture-uri "file://${WALLPAPER_DIR}/gnome/neogeo-d.jxl"

    configure_dock "cyberpunk"
    configure_blur "dark"

    success "Cyberpunk aplicado!"
}

# ---------------------------------------------------------------------------
# 🌿 Forest — Tema dark, tons verdes naturais
# ---------------------------------------------------------------------------
apply_forest() {
    info "Aplicando ${GREEN}Forest${NC} (Green Nature)..."

    gset org.gnome.desktop.interface color-scheme 'prefer-dark'
    gset org.gnome.desktop.interface gtk-theme 'catppuccin-frappe-blue-standard+default'
    gset org.gnome.shell.extensions.user-theme name 'catppuccin-frappe-blue-standard+default'

    gset org.gnome.desktop.interface icon-theme 'Tela-green-dark'
    gset org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
    gset org.gnome.desktop.interface cursor-size 24

    gset org.gnome.desktop.interface font-name 'Cantarell 11'
    gset org.gnome.desktop.interface document-font-name 'Cantarell 11'
    gset org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
    gset org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Bold 11'

    gset org.gnome.desktop.interface accent-color 'green'

    gset org.gnome.desktop.background picture-uri "file://${WALLPAPER_DIR}/fedora-workstation/petals_dark.webp"
    gset org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER_DIR}/fedora-workstation/petals_dark.webp"
    gset org.gnome.desktop.background picture-options 'zoom'

    gset org.gnome.desktop.screensaver picture-uri "file://${WALLPAPER_DIR}/gnome/morphogenesis-d.svg"

    configure_dock "forest"
    configure_blur "dark"

    success "Forest aplicado!"
}

# ---------------------------------------------------------------------------
# ⚪ Adwaita Clean — GNOME padrão otimizado
# ---------------------------------------------------------------------------
apply_adwaita() {
    info "Aplicando ${WHITE}Adwaita Clean${NC} (GNOME Padrão)..."

    gset org.gnome.desktop.interface color-scheme 'prefer-dark'
    gset org.gnome.desktop.interface gtk-theme 'Adwaita'
    gset org.gnome.shell.extensions.user-theme name ''

    gset org.gnome.desktop.interface icon-theme 'Adwaita'
    gset org.gnome.desktop.interface cursor-theme 'Adwaita'
    gset org.gnome.desktop.interface cursor-size 24

    gset org.gnome.desktop.interface font-name 'Cantarell 11'
    gset org.gnome.desktop.interface document-font-name 'Cantarell 11'
    gset org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'
    gset org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Bold 11'

    gset org.gnome.desktop.interface accent-color 'blue'

    gset org.gnome.desktop.background picture-uri "file://${WALLPAPER_DIR}/gnome/adwaita-l.jxl"
    gset org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER_DIR}/gnome/adwaita-d.jxl"
    gset org.gnome.desktop.background picture-options 'zoom'

    gset org.gnome.desktop.screensaver picture-uri "file://${WALLPAPER_DIR}/gnome/adwaita-d.jxl"

    configure_dock "adwaita"
    configure_blur "dark"

    success "Adwaita Clean aplicado!"
}

# ============================================================================
# CONFIGURAÇÃO DASH TO DOCK
# ============================================================================
configure_dock() {
    local preset="${1:-mocha}"
    local schema="org.gnome.shell.extensions.dash-to-dock"

    # Verificar se o schema existe
    if ! gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.dash-to-dock"; then
        warn "Dash to Dock não disponível — pule (precisa reiniciar GNOME Shell)"
        return
    fi

    # Configurações comuns a todos os presets
    gset $schema dock-position 'BOTTOM'
    gset $schema dock-fixed false
    gset $schema autohide true
    gset $schema intellihide true
    gset $schema extend-height false
    gset $schema height-fraction 0.9
    gset $schema dash-max-icon-size 48
    gset $schema show-apps-at-top false
    gset $schema show-trash false
    gset $schema show-mounts false
    gset $schema animate-show-apps true
    gset $schema click-action 'focus-minimize-or-previews'
    gset $schema scroll-action 'cycle-windows'
    gset $schema custom-theme-shrink true
    gset $schema disable-overview-on-startup true
    gset $schema running-indicator-style 'DOTS'

    case "$preset" in
        mocha|corporate)
            gset $schema transparency-mode 'DYNAMIC'
            gset $schema background-opacity 0.6
            gset $schema custom-background-color true
            gset $schema background-color 'rgb(30,30,46)'
            gset $schema running-indicator-dominant-color true
            ;;
        frappe|forest)
            gset $schema transparency-mode 'DYNAMIC'
            gset $schema background-opacity 0.65
            gset $schema custom-background-color true
            gset $schema background-color 'rgb(48,52,70)'
            gset $schema running-indicator-dominant-color true
            ;;
        latte)
            gset $schema transparency-mode 'DYNAMIC'
            gset $schema background-opacity 0.75
            gset $schema custom-background-color true
            gset $schema background-color 'rgb(230,233,239)'
            gset $schema running-indicator-dominant-color false
            ;;
        dracula)
            gset $schema transparency-mode 'DYNAMIC'
            gset $schema background-opacity 0.6
            gset $schema custom-background-color true
            gset $schema background-color 'rgb(40,42,54)'
            gset $schema running-indicator-dominant-color true
            ;;
        cyberpunk)
            gset $schema transparency-mode 'FIXED'
            gset $schema background-opacity 0.5
            gset $schema custom-background-color true
            gset $schema background-color 'rgb(20,20,30)'
            gset $schema running-indicator-dominant-color true
            ;;
        adwaita)
            gset $schema transparency-mode 'DEFAULT'
            gset $schema background-opacity 0.8
            gset $schema custom-background-color false
            gset $schema running-indicator-dominant-color false
            ;;
    esac

    info "  Dock configurado: bottom, autohide, 48px ícones"
}

# ============================================================================
# CONFIGURAÇÃO BLUR MY SHELL
# ============================================================================
configure_blur() {
    local mode="${1:-dark}"
    local schema="org.gnome.shell.extensions.blur-my-shell"

    # Verificar se o schema existe
    if ! gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.blur-my-shell"; then
        warn "Blur My Shell não disponível — pule (precisa reiniciar GNOME Shell)"
        return
    fi

    # Blur do painel superior
    gset ${schema}.panel blur true
    gset ${schema}.panel pipeline 'pipeline_default'

    # Blur da overview
    gset ${schema}.overview blur true
    gset ${schema}.overview pipeline 'pipeline_default'

    # Blur do lockscreen
    gset ${schema}.lockscreen blur true
    gset ${schema}.lockscreen pipeline 'pipeline_default'

    # Blur do dash-to-dock
    gset ${schema}.dash-to-dock blur true
    gset ${schema}.dash-to-dock pipeline 'pipeline_default'

    if [[ "$mode" == "light" ]]; then
        gset ${schema}.panel brightness 0.75
        gset ${schema}.overview brightness 0.8
    else
        gset ${schema}.panel brightness 0.55
        gset ${schema}.overview brightness 0.6
    fi

    info "  Blur configurado: painel, overview, dock, lockscreen"
}

# ============================================================================
# CONFIGURAÇÕES EXTRAS DO GNOME
# ============================================================================
apply_gnome_tweaks() {
    info "Aplicando ajustes gerais do GNOME..."

    # Botões da janela (minimizar + fechar)
    gset org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,close'

    # Clique no touchpad
    gset org.gnome.desktop.peripherals.touchpad tap-to-click true
    gset org.gnome.desktop.peripherals.touchpad natural-scroll true

    # Hot corner desligado
    gset org.gnome.desktop.interface enable-hot-corners false

    # Relógio com segundos e data
    gset org.gnome.desktop.interface clock-show-seconds true
    gset org.gnome.desktop.interface clock-show-weekday true
    gset org.gnome.desktop.interface clock-format '24h'

    # Workspaces dinâmicos
    gset org.gnome.mutter dynamic-workspaces true

    # Atalhos de janela
    gset org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
    gset org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"

    # Night light (redução de luz azul)
    gset org.gnome.settings-daemon.plugins.color night-light-enabled true
    gset org.gnome.settings-daemon.plugins.color night-light-temperature 3500

    # Animações
    gset org.gnome.desktop.interface enable-animations true

    success "Ajustes gerais aplicados"
}

# ============================================================================
# STATUS ATUAL
# ============================================================================
show_current() {
    echo -e "\n${BOLD}═══ Configuração Visual Atual ═══${NC}\n"

    local gtk_theme icon_theme cursor_theme color_scheme accent font mono_font wallpaper shell_theme

    gtk_theme=$(gget org.gnome.desktop.interface gtk-theme | tr -d "'")
    icon_theme=$(gget org.gnome.desktop.interface icon-theme | tr -d "'")
    cursor_theme=$(gget org.gnome.desktop.interface cursor-theme | tr -d "'")
    color_scheme=$(gget org.gnome.desktop.interface color-scheme | tr -d "'")
    accent=$(gget org.gnome.desktop.interface accent-color | tr -d "'")
    font=$(gget org.gnome.desktop.interface font-name | tr -d "'")
    mono_font=$(gget org.gnome.desktop.interface monospace-font-name | tr -d "'")
    wallpaper=$(gget org.gnome.desktop.background picture-uri-dark | tr -d "'")
    shell_theme=$(gget org.gnome.shell.extensions.user-theme name 2>/dev/null | tr -d "'")

    printf "  ${CYAN}%-20s${NC} %s\n" "GTK Theme:" "$gtk_theme"
    printf "  ${CYAN}%-20s${NC} %s\n" "Shell Theme:" "${shell_theme:-Adwaita (padrão)}"
    printf "  ${CYAN}%-20s${NC} %s\n" "Icon Theme:" "$icon_theme"
    printf "  ${CYAN}%-20s${NC} %s\n" "Cursor Theme:" "$cursor_theme"
    printf "  ${CYAN}%-20s${NC} %s\n" "Color Scheme:" "$color_scheme"
    printf "  ${CYAN}%-20s${NC} %s\n" "Accent Color:" "$accent"
    printf "  ${CYAN}%-20s${NC} %s\n" "Font:" "$font"
    printf "  ${CYAN}%-20s${NC} %s\n" "Mono Font:" "$mono_font"
    printf "  ${CYAN}%-20s${NC} %s\n" "Wallpaper:" "$(basename "$wallpaper")"

    echo -e "\n${BOLD}═══ Extensões Ativas ═══${NC}\n"
    local exts
    exts=$(gget org.gnome.shell enabled-extensions)
    echo "$exts" | tr ',' '\n' | sed "s/\[//;s/\]//;s/'//g;s/^ //" | while read -r ext; do
        [[ -n "$ext" ]] && printf "  ${GREEN}●${NC} %s\n" "$ext"
    done

    echo ""
}

# ============================================================================
# LISTAR PRESETS
# ============================================================================
list_presets() {
    echo -e "\n${BOLD}═══ Presets Disponíveis ═══${NC}\n"
    echo -e "  ${MAGENTA}1)${NC} ${BOLD}mocha${NC}      — 🌙 Catppuccin Mocha (Dark elegante, tons quentes)"
    echo -e "  ${BLUE}2)${NC} ${BOLD}frappe${NC}     — 🌊 Catppuccin Frappé (Dark suave, tons frios)"
    echo -e "  ${YELLOW}3)${NC} ${BOLD}latte${NC}      — ☀️  Catppuccin Latte (Claro profissional)"
    echo -e "  ${MAGENTA}4)${NC} ${BOLD}dracula${NC}    — 🧛 Dracula (Dark clássico, tons roxos)"
    echo -e "  ${GREEN}5)${NC} ${BOLD}corporate${NC}  — 🏢 CCA Corporate (Profissional, green accent)"
    echo -e "  ${RED}6)${NC} ${BOLD}cyberpunk${NC}  — 🔥 Cyberpunk (Neon vibrante, orange accent)"
    echo -e "  ${GREEN}7)${NC} ${BOLD}forest${NC}     — 🌿 Forest (Green nature)"
    echo -e "  ${WHITE}8)${NC} ${BOLD}adwaita${NC}    — ⚪ Adwaita Clean (GNOME padrão otimizado)"
    echo ""
}

# ============================================================================
# LISTAR RECURSOS DISPONÍVEIS
# ============================================================================
list_assets() {
    echo -e "\n${BOLD}═══ Recursos Instalados ═══${NC}\n"

    echo -e "  ${CYAN}GTK Themes:${NC}"
    ls "$THEMES_DIR" 2>/dev/null | while read -r t; do printf "    • %s\n" "$t"; done

    echo -e "\n  ${CYAN}Icon Themes:${NC}"
    ls "$ICONS_DIR" 2>/dev/null | while read -r t; do printf "    • %s\n" "$t"; done
    ls /usr/share/icons/ 2>/dev/null | grep -iE 'papirus' | while read -r t; do printf "    • %s (sistema)\n" "$t"; done

    echo -e "\n  ${CYAN}Cursor Themes:${NC}"
    ls "$CURSORS_DIR" 2>/dev/null | grep -iE 'bibata' | while read -r t; do printf "    • %s\n" "$t"; done

    echo -e "\n  ${CYAN}Wallpapers (Fedora):${NC}"
    ls "$WALLPAPER_DIR"/fedora-workstation/ 2>/dev/null | while read -r t; do printf "    • %s\n" "$t"; done

    echo -e "\n  ${CYAN}Wallpapers (GNOME):${NC}"
    ls "$WALLPAPER_DIR"/gnome/ 2>/dev/null | grep -E '\-d\.' | while read -r t; do printf "    • %s\n" "$t"; done

    echo ""
}

# ============================================================================
# PERSONALIZAÇÃO INDIVIDUAL
# ============================================================================
set_individual() {
    local setting="$1"
    local value="$2"

    case "$setting" in
        gtk)
            gset org.gnome.desktop.interface gtk-theme "$value"
            gset org.gnome.shell.extensions.user-theme name "$value"
            success "GTK + Shell theme → $value"
            ;;
        icons)
            gset org.gnome.desktop.interface icon-theme "$value"
            success "Icon theme → $value"
            ;;
        cursor)
            gset org.gnome.desktop.interface cursor-theme "$value"
            success "Cursor theme → $value"
            ;;
        accent)
            gset org.gnome.desktop.interface accent-color "$value"
            success "Accent color → $value"
            ;;
        wallpaper)
            if [[ "$value" == /* ]]; then
                gset org.gnome.desktop.background picture-uri "file://$value"
                gset org.gnome.desktop.background picture-uri-dark "file://$value"
            else
                # Buscar nos diretórios de wallpaper
                local found=""
                for dir in "$WALLPAPER_DIR"/gnome "$WALLPAPER_DIR"/fedora-workstation "$CUSTOM_WALLPAPER_DIR"; do
                    if [[ -f "$dir/$value" ]]; then
                        found="$dir/$value"
                        break
                    fi
                done
                if [[ -n "$found" ]]; then
                    gset org.gnome.desktop.background picture-uri "file://$found"
                    gset org.gnome.desktop.background picture-uri-dark "file://$found"
                else
                    error "Wallpaper não encontrado: $value"
                    return 1
                fi
            fi
            success "Wallpaper → $value"
            ;;
        dark|light)
            if [[ "$setting" == "dark" ]]; then
                gset org.gnome.desktop.interface color-scheme 'prefer-dark'
            else
                gset org.gnome.desktop.interface color-scheme 'prefer-light'
            fi
            success "Color scheme → $setting"
            ;;
        *)
            error "Configuração desconhecida: $setting"
            echo "  Opções: gtk, icons, cursor, accent, wallpaper, dark, light"
            return 1
            ;;
    esac
}

# ============================================================================
# MENU INTERATIVO
# ============================================================================
interactive_menu() {
    banner
    show_current

    while true; do
        echo -e "${BOLD}═══ Menu ═══${NC}"
        echo -e "  ${CYAN}1${NC}) Aplicar preset de tema"
        echo -e "  ${CYAN}2${NC}) Personalizar item individual"
        echo -e "  ${CYAN}3${NC}) Aplicar ajustes GNOME (fontes, atalhos, etc.)"
        echo -e "  ${CYAN}4${NC}) Ver configuração atual"
        echo -e "  ${CYAN}5${NC}) Listar recursos disponíveis"
        echo -e "  ${CYAN}0${NC}) Sair"
        echo ""
        read -rp "Escolha: " choice

        case "$choice" in
            1)
                list_presets
                read -rp "Nome do preset (ou número): " preset
                case "$preset" in
                    1|mocha)     apply_catppuccin_mocha ;;
                    2|frappe)    apply_catppuccin_frappe ;;
                    3|latte)     apply_catppuccin_latte ;;
                    4|dracula)   apply_dracula ;;
                    5|corporate) apply_cca_corporate ;;
                    6|cyberpunk) apply_cyberpunk ;;
                    7|forest)    apply_forest ;;
                    8|adwaita)   apply_adwaita ;;
                    *) error "Preset desconhecido: $preset" ;;
                esac
                ;;
            2)
                echo -e "\n  ${CYAN}Opções:${NC} gtk, icons, cursor, accent, wallpaper, dark, light"
                read -rp "  Item: " item
                read -rp "  Valor: " val
                set_individual "$item" "$val"
                ;;
            3)
                apply_gnome_tweaks
                ;;
            4)
                show_current
                ;;
            5)
                list_assets
                ;;
            0|q|quit|exit)
                echo -e "\n${GREEN}Até mais! 🎨${NC}\n"
                break
                ;;
            *)
                error "Opção inválida"
                ;;
        esac
        echo ""
    done
}

# ============================================================================
# HELP
# ============================================================================
show_help() {
    banner
    echo "Uso: cca-theme <comando> [argumentos]"
    echo ""
    echo -e "${BOLD}Presets:${NC}"
    echo "  cca-theme mocha          Catppuccin Mocha (dark, tons quentes)"
    echo "  cca-theme frappe         Catppuccin Frappé (dark, tons frios)"
    echo "  cca-theme latte          Catppuccin Latte (claro, profissional)"
    echo "  cca-theme dracula        Dracula (dark, tons roxos)"
    echo "  cca-theme corporate      CCA Corporate (profissional, verde)"
    echo "  cca-theme cyberpunk      Cyberpunk (neon, vibrante)"
    echo "  cca-theme forest         Forest (natureza, verde escuro)"
    echo "  cca-theme adwaita        Adwaita (GNOME padrão)"
    echo ""
    echo -e "${BOLD}Individual:${NC}"
    echo "  cca-theme set gtk <nome>          Trocar tema GTK"
    echo "  cca-theme set icons <nome>        Trocar ícones"
    echo "  cca-theme set cursor <nome>       Trocar cursor"
    echo "  cca-theme set accent <cor>        Trocar cor destaque"
    echo "  cca-theme set wallpaper <arquivo> Trocar wallpaper"
    echo "  cca-theme set dark                Modo escuro"
    echo "  cca-theme set light               Modo claro"
    echo ""
    echo -e "${BOLD}Outros:${NC}"
    echo "  cca-theme status         Ver configuração atual"
    echo "  cca-theme list           Listar presets disponíveis"
    echo "  cca-theme assets         Listar recursos instalados"
    echo "  cca-theme tweaks         Aplicar ajustes gerais GNOME"
    echo "  cca-theme menu           Menu interativo"
    echo "  cca-theme help           Esta ajuda"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    local cmd="${1:-menu}"

    # Garantir extensões ativas
    ensure_extensions

    case "$cmd" in
        # Presets
        mocha)      apply_catppuccin_mocha ;;
        frappe)     apply_catppuccin_frappe ;;
        latte)      apply_catppuccin_latte ;;
        dracula)    apply_dracula ;;
        corporate)  apply_cca_corporate ;;
        cyberpunk)  apply_cyberpunk ;;
        forest)     apply_forest ;;
        adwaita)    apply_adwaita ;;

        # Comandos
        set)
            shift
            if [[ $# -lt 1 ]]; then
                error "Uso: cca-theme set <item> [valor]"
                return 1
            fi
            local item="$1"
            local value="${2:-}"
            if [[ "$item" == "dark" || "$item" == "light" ]]; then
                set_individual "$item" ""
            elif [[ -z "$value" ]]; then
                error "Uso: cca-theme set $item <valor>"
                return 1
            else
                set_individual "$item" "$value"
            fi
            ;;
        status|current)
            show_current
            ;;
        list|presets)
            list_presets
            ;;
        assets|resources)
            list_assets
            ;;
        tweaks)
            apply_gnome_tweaks
            ;;
        menu|interactive)
            interactive_menu
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            error "Comando desconhecido: $cmd"
            show_help
            return 1
            ;;
    esac
}

main "$@"

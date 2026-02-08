# Fedora CCA — Setup & Dotfiles

> Configurações, scripts de setup e otimizações do notebook de desenvolvimento Fedora do Ellon (CCA Carregamentos).

---

## 💻 Hardware

| Componente | Especificação |
|------------|---------------|
| **Notebook** | (i5-13420H) |
| **CPU** | Intel Core i5-13420H (8C/12T) |
| **RAM** | 32GB DDR5 |
| **GPU** | NVIDIA GeForce RTX 3050 6GB |
| **SSD** | 475GB NVMe |

## 🐧 Sistema

| Item | Valor |
|------|-------|
| **OS** | Fedora 43 (Forty Three) |
| **Kernel** | 6.18.x |
| **DE** | GNOME |
| **Shell** | Zsh |
| **Hostname** | fedora |

## 📂 Estrutura

```
fedora-cca/
├── dotfiles/           # Arquivos de configuração do sistema
│   ├── zshrc           # Config do Zsh
│   ├── gitconfig       # Config global do Git
│   └── vscode/         # Settings do VS Code
├── scripts/            # Scripts de automação e setup
│   ├── setup.sh        # Setup inicial do Fedora
│   ├── install-dev.sh  # Instalar ferramentas de dev
│   ├── install-nvidia.sh # Driver NVIDIA + CUDA
│   └── backup.sh       # Backup de configs
├── gnome/              # Configs e extensões GNOME
│   └── dconf-dump.ini  # Dump das configs GNOME
├── docker/             # Docker configs
│   └── daemon.json     # Config do Docker daemon
├── systemd/            # Serviços e timers customizados
└── docs/               # Documentação
```

## 🚀 Setup Rápido (novo Fedora)

```bash
# Clonar repo
git clone git@github.com:ccacarregamentos7-oss/fedora-cca.git ~/git/fedora-cca

# Executar setup completo
cd ~/git/fedora-cca
chmod +x scripts/setup.sh
./scripts/setup.sh
```

## 📦 Pacotes Instalados

### Dev Essenciais
- Node.js 22 (via nvm)
- pnpm
- Git, GitHub CLI
- Docker, Docker Compose
- VS Code (com extensões CCA)
- Android Studio + SDK

### Ferramentas
- Scrcpy (espelhamento Android)
- Tailscale VPN
- zsh + oh-my-zsh
- Cockpit (porta 9090)

### NVIDIA
- Driver proprietário
- CUDA Toolkit

---

## 🔗 Repos Relacionados

- [servidor-local-dev](https://github.com/ccacarregamentos7-oss/servidor-local-dev) — Proxmox + monitoramento
- [config-cca](https://github.com/ccacarregamentos7-oss/config-cca) — Setup multi-máquinas
- [automacao-cca](https://github.com/ccacarregamentos7-oss/automacao-cca) — Orquestrador de repos

---

_Mantido por: coconai (Ellon) — CCA Carregamentos_

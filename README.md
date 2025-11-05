# 🚀 Dotfiles

**Production-grade, modular, cross-platform dotfiles** using **GNU Stow** + **Ansible** for automated development environment setup.

[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue)](https://github.com/Bliz243/.dotfiles)
[![Shell](https://img.shields.io/badge/shell-zsh-green)](https://www.zsh.org/)
[![License](https://img.shields.io/badge/license-MIT-orange)](LICENSE)

## ✨ What Makes This Special

- 🔗 **GNU Stow Integration** - Edit configs once, changes apply immediately
- 🤖 **Ansible Automation** - Consistent setup across all machines
- 📦 **Modular Design** - Load only what you need
- 🔐 **Security First** - No secrets in version control
- 🖥️ **Multi-Machine Support** - Mac, Linux, WSL2 (servers skip GUI tools)
- 📚 **Simple & Practical** - YAGNI principle, no overengineering
- ⚡ **Performance Optimized** - Fast shell startup

## 🎯 Quick Start

### One Command Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Bliz243/.dotfiles/main/scripts/bootstrap.sh | bash
```

### Or Manual Installation

```bash
git clone https://github.com/Bliz243/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make install
```

That's it! See [docs/INSTALL.md](docs/INSTALL.md) for detailed instructions.

## 🛠️ What's Included

### Core Tools

| Tool | Description |
|------|-------------|
| **Zsh** | Shell with Oh My Zsh + modular config |
| **Neovim** | Modern editor with LSP support |
| **Tmux** | Terminal multiplexer with vim bindings |
| **Starship** | Fast, customizable prompt |
| **Alacritty** | GPU-accelerated terminal |
| **Git** | Version control with 50+ aliases |

### Modern CLI Tools

| Tool | Replaces | Description |
|------|----------|-------------|
| **eza** | ls | Modern ls with git integration |
| **bat** | cat | Cat with syntax highlighting |
| **fd** | find | Fast, user-friendly find |
| **ripgrep** | grep | Blazingly fast grep |
| **fzf** | - | Fuzzy finder for everything |
| **zoxide** | cd | Smart directory jumping |

### Developer Experience

- 🎨 **Full LSP Support** - TypeScript, Python, Go, Docker, etc.
- 🔍 **Fuzzy Everything** - Files, buffers, history, processes
- 🧠 **Smart Navigation** - Jump to frequently used directories
- ✨ **Syntax Highlighting** - Everywhere (files, man pages, git)
- 🚀 **Auto-completion** - Intelligent command suggestions
- 📝 **20+ Neovim Plugins** - Carefully curated for productivity

## 📁 Repository Structure

```
.dotfiles/
├── stow/                      # Stowable packages (GNU Stow)
│   ├── zsh/
│   │   ├── .zshrc            # Main loader
│   │   └── .zsh/             # Modular configuration
│   │       ├── 00-env.zsh    # Environment variables
│   │       ├── 01-options.zsh # Shell options
│   │       ├── 02-aliases.zsh # Aliases
│   │       ├── 03-functions.zsh # Functions
│   │       ├── 04-plugins.zsh # Oh My Zsh
│   │       ├── 05-tools.zsh  # Modern CLI tools
│   │       ├── 06-prompt.zsh # Starship
│   │       ├── 07-tmux.zsh   # Auto-attach
│   │       └── 99-local.zsh.example # Local overrides
│   ├── nvim/                 # Neovim (382 lines!)
│   ├── git/                  # Git config + aliases
│   ├── tmux/                 # Tmux config
│   ├── starship/             # Starship prompt
│   └── alacritty/            # Alacritty terminal
├── ansible/                   # System provisioning
│   ├── setup-new-machine.yml # Main playbook
│   └── roles/                # Modular roles
├── scripts/                   # Management scripts
│   ├── bootstrap.sh          # One-command install
│   ├── stow.sh               # Stow packages (with auto-backup)
│   ├── unstow.sh             # Remove symlinks
│   ├── restow.sh             # Refresh symlinks
│   └── update.sh             # Update everything
├── docs/                      # Documentation
│   ├── INSTALL.md
│   ├── TROUBLESHOOTING.md
│   └── ...
├── config/                    # Templates
│   ├── .gitconfig.local.example
│   └── .env.example
├── Makefile                   # Unified interface
└── README.md                  # This file
```

## 🎓 Usage

### Daily Commands

```bash
make help       # Show all available commands
make install    # Full installation (auto-detects machine type)
make stow       # Symlink dotfiles (with auto-backup)
make sync       # Pull latest changes and restow
make push       # Commit and push changes (interactive)
make update     # Update everything
```

### Machine Type Detection

Installation automatically detects your machine type:
- **Workstation** (Mac/WSL): Installs all tools including GUI apps
- **Server** (Linux headless): Skips GUI tools (Alacritty, fonts) for faster setup

No prompts needed - just `make install` and go!

### Stow Management

```bash
# Stow all packages
./scripts/stow.sh

# Stow specific packages
./scripts/stow.sh zsh git nvim

# Remove symlinks
./scripts/unstow.sh

# Refresh symlinks (after changes)
./scripts/restow.sh
```

### Customization

Edit configs directly - changes apply immediately:

```bash
# Edit zsh configuration
vim ~/.dotfiles/stow/zsh/.zsh/02-aliases.zsh

# Edit neovim configuration
vim ~/.dotfiles/stow/nvim/.config/nvim/init.vim

# Changes are LIVE! No need to reinstall!
```

### Machine-Specific Settings

```bash
# Create local zsh config (gitignored)
cp ~/.zsh/99-local.zsh.example ~/.zsh/99-local.zsh
vim ~/.zsh/99-local.zsh

# Create local git config (gitignored)
cp config/.gitconfig.local.example ~/.gitconfig.local
vim ~/.gitconfig.local
```

## 🔑 Key Features Deep Dive

### Modular Zsh Configuration

Instead of one huge `.zshrc`, configs are split into focused modules. Benefits:
- Easy to find and edit specific configs
- Can disable modules by renaming
- Clean, maintainable organization

### GNU Stow Magic

**Problem with copying**: Edit `.dotfiles/zsh/.zshrc` → nothing happens until you re-run install

**Solution with Stow**: Configs are symlinked, so edits apply instantly!

```bash
~/.zshrc -> ~/.dotfiles/stow/zsh/.zshrc
```

## 🚀 Multi-Machine Workflow

Perfect for managing dotfiles across Mac, WSL2, and Linux servers:

### Setup on New Machine

```bash
git clone https://github.com/Bliz243/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make install    # Auto-detects workstation vs server
```

### Sync Changes Across Machines

```bash
# On Machine A: Made config changes
vim ~/.dotfiles/stow/zsh/.zsh/02-aliases.zsh
make push       # Commits and pushes to git (interactive)

# On Machine B: Get those changes
make sync       # Pulls and restows automatically
```

### Update Everything

```bash
make update
```

Updates: Dotfiles, Oh My Zsh, Neovim plugins, Starship, Rust tools, System packages

### Auto-Backup

Stow automatically backs up existing configs before creating symlinks:
```bash
make stow
# ℹ Backing up existing configs to: /home/user/.dotfiles-backup-20231105-143022
# ✓ Backed up 3 item(s)
```

## 📝 Documentation

- [Installation Guide](docs/INSTALL.md) - Detailed setup instructions
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues & fixes

## 💡 Philosophy

This dotfiles setup follows the **YAGNI principle** (You Aren't Gonna Need It):

- ✅ **Simple over complex** - One command to install, no complicated wizards
- ✅ **Practical over perfect** - Built for actual daily use, not theoretical scenarios
- ✅ **Fast over feature-rich** - Servers skip GUI tools, saving 10-15 minutes
- ✅ **Maintainable over clever** - No over-engineered scripts you'll never use

**Result**: ~500 lines of code that do exactly what's needed, nothing more.

## 📄 License

MIT License - Use freely!

---

**⭐ If this helped you, consider starring the repo!**

# Installation Guide

Complete installation instructions for the dotfiles.

## Quick Start

### One-Command Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Bliz243/.dotfiles/main/scripts/bootstrap.sh | bash
```

This will:
1. Clone the repository
2. Install dependencies
3. Run Ansible playbook
4. Stow all dotfiles
5. Run health check

### Manual Installation

If you prefer step-by-step installation:

#### 1. Clone the Repository

```bash
git clone https://github.com/Bliz243/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

#### 2. Run Installation

```bash
make install
```

Or individually:

```bash
./install.sh          # Install system packages and tools
./scripts/stow.sh     # Symlink dotfiles
```

#### 3. Restart Shell

```bash
exec zsh
```

## Prerequisites

### Required

- **Git** - Version control
- **Sudo access** - For package installation

### Optional (will be installed)

- GNU Stow
- Zsh
- Neovim
- Tmux
- Modern CLI tools

## Platform-Specific Notes

### macOS

Requires [Homebrew](https://brew.sh/):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Linux

Supported distributions:
- Ubuntu/Debian (apt)
- Arch Linux (pacman)
- Fedora/RHEL (dnf)

## Post-Installation

### 1. Set Git User Info

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

Or copy the template:

```bash
cp config/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
```

### 2. Customize Local Settings

```bash
cp stow/zsh/.zsh/99-local.zsh.example ~/.zsh/99-local.zsh
$EDITOR ~/.zsh/99-local.zsh
```

### 3. Install Neovim Plugins

```bash
nvim +PlugInstall +qall
```

### 4. Verify Installation

```bash
make health
```

## Selective Installation

### Install Specific Packages Only

```bash
# Only stow zsh and git configs
./scripts/stow.sh zsh git

# Only run specific Ansible roles
ansible-playbook ansible/setup-new-machine.yml --tags zsh,git
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

## Next Steps

- Read the main [README.md](../README.md) for features
- Check [USAGE.md](USAGE.md) for daily usage tips
- Customize your setup!

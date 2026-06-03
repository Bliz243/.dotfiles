#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Dotfiles Installation Script
# ─────────────────────────────────────────────
# Usage:
#   ./scripts/install.sh           # Interactive - asks local or remote
#   ./scripts/install.sh --local   # Local machine (WSL/Desktop) - Ctrl+A prefix
#   ./scripts/install.sh --remote  # Remote server (VPS) - Ctrl+B prefix
# ─────────────────────────────────────────────

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ─────────────────────────────────────────────
# Parse arguments
# ─────────────────────────────────────────────
MACHINE_TYPE=""

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --local)
        MACHINE_TYPE="local"
        shift
        ;;
      --remote|--vps|--server)
        MACHINE_TYPE="remote"
        shift
        ;;
      --help|-h)
        echo "Usage: ./scripts/install.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --local     Configure for local machine (WSL/Desktop)"
        echo "              Uses Ctrl+A prefix, always auto-attach tmux"
        echo ""
        echo "  --remote    Configure for remote server (VPS)"
        echo "              Uses Ctrl+B prefix, auto-attach only in SSH sessions"
        echo ""
        echo "  --help      Show this help message"
        echo ""
        echo "If no option is provided, the script will ask interactively."
        exit 0
        ;;
      *)
        warn "Unknown option: $1"
        shift
        ;;
    esac
  done
}

detect_machine_type() {
  if [[ -n "$MACHINE_TYPE" ]]; then
    return
  fi

  echo ""
  echo -e "${BLUE}What type of machine is this?${NC}"
  echo ""
  echo "  1) Local machine (WSL, Desktop, Laptop)"
  echo "     - Tmux prefix: Ctrl+A"
  echo "     - Auto-attach: Always"
  echo ""
  echo "  2) Remote server (VPS, Cloud, SSH-only)"
  echo "     - Tmux prefix: Ctrl+B"
  echo "     - Auto-attach: Only in SSH sessions"
  echo ""
  read -p "Select [1/2]: " -n 1 -r
  echo ""

  case "$REPLY" in
    1) MACHINE_TYPE="local" ;;
    2) MACHINE_TYPE="remote" ;;
    *) MACHINE_TYPE="local"; warn "Invalid selection, defaulting to local" ;;
  esac
}

echo "========================================"
echo "  Dotfiles Installation"
echo "========================================"
echo ""

# ─────────────────────────────────────────────
# Detect OS
# ─────────────────────────────────────────────
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
  elif [[ -f /etc/os-release ]]; then
    OS="linux"
    . /etc/os-release
    DISTRO="$ID"
  else
    error "Unsupported operating system"
  fi
  info "Detected OS: $OS${DISTRO:+ ($DISTRO)}"
}

# ─────────────────────────────────────────────
# Install packages - macOS
# ─────────────────────────────────────────────
install_macos() {
  info "Installing packages via Homebrew..."

  # Install Homebrew if not present
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"
  fi

  # Install packages
  brew install \
    zsh git curl stow tmux \
    eza bat fd ripgrep fzf zoxide \
    neovim gh

  # Install Nerd Font for terminal
  info "Installing JetBrainsMono Nerd Font..."
  brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || warn "Font install failed - install manually from nerdfonts.com"
}

# ─────────────────────────────────────────────
# Install packages - Linux (Ubuntu/Debian)
# ─────────────────────────────────────────────
# Acquire sudo up front so the install doesn't hang on a password prompt mid-run.
ensure_sudo() {
  if ! sudo -n true 2>/dev/null; then
    info "Administrator (sudo) access is required to install packages."
    sudo -v || error "Could not obtain sudo access. Re-run once sudo is available."
  fi
}

install_linux() {
  info "Installing packages via apt..."

  ensure_sudo

  sudo apt update
  sudo apt install -y \
    zsh git curl stow \
    fzf ripgrep fd-find \
    build-essential \
    libevent-dev ncurses-dev bison \
    chromium-browser

  # bat (called batcat on Ubuntu, create symlink)
  if ! command -v bat &>/dev/null; then
    sudo apt install -y bat
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
  fi

  # eza
  install_eza_linux

  # zoxide
  install_zoxide_linux

  # tmux 3.4+ (apt version is outdated)
  install_tmux_linux

  # Neovim 0.11.2+ (required by LazyVim)
  install_neovim_linux

  # Nerd Font for terminal
  install_font_linux

  # GitHub CLI
  install_gh_linux

  # lazygit (used by Neovim/LazyVim git workflow)
  install_lazygit_linux

  # win32yank for clipboard (WSL only; no-op elsewhere)
  install_win32yank_wsl
}

install_eza_linux() {
  if command -v eza &>/dev/null; then
    info "eza already installed"
    return
  fi

  info "Installing eza..."
  # Try apt first (newer Ubuntu versions)
  if sudo apt install -y eza 2>/dev/null; then
    return
  fi

  # Otherwise install from official repo
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo apt update
  sudo apt install -y eza
}

install_zoxide_linux() {
  if command -v zoxide &>/dev/null; then
    info "zoxide already installed"
    return
  fi

  info "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

install_tmux_linux() {
  TMUX_REQUIRED="3.4"

  # Check if tmux is already installed and is 3.4+
  if command -v tmux &>/dev/null; then
    TMUX_VERSION=$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -1)
    if [[ "$(printf '%s\n' "$TMUX_REQUIRED" "$TMUX_VERSION" | sort -V | head -1)" == "$TMUX_REQUIRED" ]]; then
      info "tmux $TMUX_VERSION already installed"
      return
    fi
    warn "tmux $TMUX_VERSION found, but $TMUX_REQUIRED+ required. Upgrading..."
  fi

  info "Installing tmux $TMUX_REQUIRED from source..."
  TMUX_VERSION="3.4"

  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  (
    cd "$tmpdir"
    curl -LO "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
    tar -xzf "tmux-${TMUX_VERSION}.tar.gz"
    cd "tmux-${TMUX_VERSION}"
    ./configure
    make -j"$(nproc)"
    sudo make install
  )

  info "tmux $TMUX_VERSION installed successfully"
}

install_neovim_linux() {
  # LazyVim requires Neovim >= 0.11.2 (older versions hang on a "press any key" prompt).
  NVIM_REQUIRED="0.11.2"

  # Check if an adequate nvim is already installed
  if command -v nvim &>/dev/null; then
    NVIM_VERSION=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [[ -n "$NVIM_VERSION" ]] && \
       [[ "$(printf '%s\n' "$NVIM_REQUIRED" "$NVIM_VERSION" | sort -V | head -1)" == "$NVIM_REQUIRED" ]]; then
      info "Neovim $NVIM_VERSION already installed"
      return
    fi
    warn "Neovim ${NVIM_VERSION:-unknown} found, but $NVIM_REQUIRED+ required. Upgrading..."
  fi

  info "Installing Neovim..."
  NVIM_VERSION="0.12.2"

  # Detect architecture
  local ARCH
  case "$(uname -m)" in
    x86_64|amd64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
    *) warn "Unsupported architecture $(uname -m) for Neovim binary"; return ;;
  esac

  # Download and install
  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  (
    cd "$tmpdir"
    curl -LO "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-${ARCH}.tar.gz"
    sudo rm -rf "/opt/nvim-linux-${ARCH}"
    sudo tar -xzf "nvim-linux-${ARCH}.tar.gz" -C /opt/
    sudo ln -sf "/opt/nvim-linux-${ARCH}/bin/nvim" /usr/local/bin/nvim
  )
}

install_font_linux() {
  FONT_DIR="$HOME/.local/share/fonts"
  FONT_NAME="JetBrainsMono"

  # Check if font already installed
  if fc-list | grep -qi "JetBrainsMono"; then
    info "JetBrainsMono Nerd Font already installed"
    return
  fi

  info "Installing JetBrainsMono Nerd Font..."

  mkdir -p "$FONT_DIR"

  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  (
    cd "$tmpdir"
    # Download from Nerd Fonts releases
    curl -fLo "JetBrainsMono.zip" \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    # Extract to fonts directory
    unzip -o JetBrainsMono.zip -d "$FONT_DIR/JetBrainsMono" >/dev/null 2>&1
  )

  # Refresh font cache
  fc-cache -fv "$FONT_DIR" >/dev/null 2>&1

  info "JetBrainsMono Nerd Font installed"
}

install_gh_linux() {
  if command -v gh &>/dev/null; then
    info "GitHub CLI already installed"
    return
  fi

  info "Installing GitHub CLI..."

  # Add GitHub CLI repository
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install -y gh
}

install_lazygit_linux() {
  if command -v lazygit &>/dev/null; then
    info "lazygit already installed"
    return
  fi

  info "Installing lazygit..."

  local arch
  case "$(uname -m)" in
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) warn "Unsupported architecture $(uname -m) for lazygit"; return ;;
  esac

  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  (
    cd "$tmpdir"
    local ver
    ver="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
      | grep -oE '"tag_name": *"v[^"]+"' | head -1 | grep -oE '[0-9.]+')"
    if [[ -z "$ver" ]]; then
      warn "Could not determine lazygit version; skipping"
      exit 0
    fi
    curl -fsSLo lazygit.tar.gz \
      "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${ver}_Linux_${arch}.tar.gz"
    tar -xzf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
  )
}

install_win32yank_wsl() {
  # WSL only: clipboard provider so Neovim can reach the Windows clipboard.
  grep -qi microsoft /proc/version 2>/dev/null || return 0

  if command -v win32yank.exe &>/dev/null; then
    info "win32yank already installed"
    return
  fi

  info "Installing win32yank (WSL clipboard)..."
  mkdir -p "$HOME/.local/bin"

  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  (
    cd "$tmpdir"
    curl -fsSLo win32yank.zip \
      "https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip"
    unzip -o win32yank.zip win32yank.exe -d "$HOME/.local/bin" >/dev/null
    chmod +x "$HOME/.local/bin/win32yank.exe"
  )
}

# ─────────────────────────────────────────────
# Stow dotfiles
# ─────────────────────────────────────────────
stow_dotfiles() {
  info "Stowing dotfiles..."

  DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
  cd "$DOTFILES_DIR"

  # Backup suffix with timestamp
  BACKUP_SUFFIX=".backup-$(date +%Y%m%d-%H%M%S)"

  # Files/directories that might conflict with stow
  CONFLICT_FILES=".zshrc .tmux.conf .gitconfig .gitignore_global .zshrc.local.example"
  CONFLICT_DIRS=".config/nvim .config/alacritty .config/starship.toml .zsh"

  # Backup conflicting files (not symlinks)
  for file in $CONFLICT_FILES; do
    if [[ -f "$HOME/$file" ]] && [[ ! -L "$HOME/$file" ]]; then
      warn "Backing up existing $file to $file$BACKUP_SUFFIX"
      mv "$HOME/$file" "$HOME/$file$BACKUP_SUFFIX"
    fi
  done

  # Backup conflicting directories (not symlinks)
  for dir in $CONFLICT_DIRS; do
    if [[ -d "$HOME/$dir" ]] && [[ ! -L "$HOME/$dir" ]]; then
      warn "Backing up existing $dir to $dir$BACKUP_SUFFIX"
      mv "$HOME/$dir" "$HOME/$dir$BACKUP_SUFFIX"
    fi
  done

  # Stow dotfiles (ignore patterns defined in .stow-local-ignore)
  if ! stow . --target="$HOME" --restow; then
    error "Stow failed. Check for conflicting files in $HOME"
  fi
}

# ─────────────────────────────────────────────
# Post-install setup
# ─────────────────────────────────────────────
post_install() {
  info "Running post-install setup..."

  # Set zsh as default shell
  if [[ "$SHELL" != */zsh ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)" || warn "Could not change shell. Run: chsh -s \$(which zsh)"
  fi

  # Install tmux plugin manager and plugins
  if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    info "Installing tmux plugin manager..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi
  info "Installing tmux plugins..."
  ~/.tmux/plugins/tpm/bin/install_plugins || warn "Tmux plugin install had issues - press C-a + I in tmux"

  # Create local config based on machine type
  if [[ ! -f ~/.zshrc.local ]] || [[ -n "$MACHINE_TYPE" ]]; then
    info "Configuring for ${MACHINE_TYPE:-local} machine..."

    if [[ "$MACHINE_TYPE" == "remote" ]]; then
      cat > ~/.zshrc.local << 'EOF'
# Remote server configuration (VPS)
# Uses Ctrl+B to avoid conflicts when SSH-ing from local machine

export MACHINE_TYPE="remote"
export TMUX_PREFIX="C-b"
TMUX_AUTO_ATTACH="ssh-only"
EOF
      info "Created ~/.zshrc.local with remote settings (Ctrl+B prefix)"
    else
      cat > ~/.zshrc.local << 'EOF'
# Local machine configuration (WSL/Desktop)
# Uses Ctrl+A as tmux prefix

export MACHINE_TYPE="local"
export TMUX_PREFIX="C-a"
TMUX_AUTO_ATTACH="true"
EOF
      info "Created ~/.zshrc.local with local settings (Ctrl+A prefix)"
    fi
  fi

  # Sync Neovim plugins (Lazy! runs synchronously and exits when done)
  info "Syncing Neovim plugins (this may take a few minutes)..."
  nvim --headless "+Lazy! sync" +qa || warn "Neovim plugin sync had issues - run :Lazy sync manually"

  # Claude Code configuration (symlinks for global config)
  setup_claude_config

  # Optional Claude Code installation
  setup_claude_code

  # Codex CLI configuration (symlinks for global config + skills)
  setup_codex_config

  # Optional workmux installation
  setup_workmux

  # Optional GitHub/SSH setup
  setup_github
}

# ─────────────────────────────────────────────
# Claude Config Setup (Symlinks for global config)
# ─────────────────────────────────────────────
setup_claude_config() {
  info "Setting up Claude Code configuration..."

  CLAUDE_DIR="$HOME/.claude"
  DOTFILES_CLAUDE="$HOME/.dotfiles/.claude"

  # Skip if dotfiles claude config doesn't exist
  if [[ ! -d "$DOTFILES_CLAUDE" ]]; then
    warn "No Claude config in dotfiles, skipping"
    return
  fi

  # Create directories if needed
  mkdir -p "$CLAUDE_DIR/hooks"
  mkdir -p "$CLAUDE_DIR/config"
  mkdir -p "$CLAUDE_DIR/skills"
  mkdir -p "$CLAUDE_DIR/agents"

  # Remove dangling symlinks left by skills/agents that were deleted from dotfiles
  find "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents" -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null || true

  # Helper to symlink with backup
  link_claude_file() {
    local src="$1"
    local dest="$2"

    if [[ -e "$dest" ]] && [[ ! -L "$dest" ]]; then
      local backup="${dest}.backup-$(date +%Y%m%d-%H%M%S)"
      mv "$dest" "$backup"
      warn "Backed up: $dest → $backup"
    fi

    ln -sf "$src" "$dest"
  }

  # Symlink individual files
  # AGENTS.md is the canonical instructions; CLAUDE.md is a @AGENTS.md shim. Both must be linked.
  [[ -f "$DOTFILES_CLAUDE/AGENTS.md" ]] && link_claude_file "$DOTFILES_CLAUDE/AGENTS.md" "$CLAUDE_DIR/AGENTS.md"
  [[ -f "$DOTFILES_CLAUDE/CLAUDE.md" ]] && link_claude_file "$DOTFILES_CLAUDE/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  [[ -f "$DOTFILES_CLAUDE/settings.json" ]] && link_claude_file "$DOTFILES_CLAUDE/settings.json" "$CLAUDE_DIR/settings.json"
  [[ -f "$DOTFILES_CLAUDE/statusline.js" ]] && link_claude_file "$DOTFILES_CLAUDE/statusline.js" "$CLAUDE_DIR/statusline.js"

  # Symlink hooks
  for hook in "$DOTFILES_CLAUDE/hooks/"*.js; do
    [[ -f "$hook" ]] || continue
    link_claude_file "$hook" "$CLAUDE_DIR/hooks/$(basename "$hook")"
  done

  # Symlink config files
  for config in "$DOTFILES_CLAUDE/config/"*; do
    [[ -e "$config" ]] || continue
    link_claude_file "$config" "$CLAUDE_DIR/config/$(basename "$config")"
  done

  # Symlink skills (as directories)
  for skill in "$DOTFILES_CLAUDE/skills/"*/; do
    [[ -d "$skill" ]] || continue
    local skill_name=$(basename "$skill")
    link_claude_file "$skill" "$CLAUDE_DIR/skills/$skill_name"
  done

  # Symlink agents
  for agent in "$DOTFILES_CLAUDE/agents/"*.md; do
    [[ -f "$agent" ]] || continue
    link_claude_file "$agent" "$CLAUDE_DIR/agents/$(basename "$agent")"
  done

  info "Claude Code configuration linked"
}

# ─────────────────────────────────────────────
# Claude Code Installation (Optional)
# ─────────────────────────────────────────────
setup_claude_code() {
  local claude_installed=false

  # Check if already installed
  if command -v claude &>/dev/null; then
    info "Claude Code already installed"
    claude_installed=true
  else
    echo ""
    echo -e "${BLUE}Would you like to install Claude Code?${NC}"
    echo "Claude Code is Anthropic's AI coding assistant CLI."
    echo ""
    read -p "Install Claude Code? [y/N]: " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      info "Skipping Claude Code. Install later: curl -fsSL https://claude.ai/install.sh | bash"
      return
    fi

    info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash

    if command -v claude &>/dev/null; then
      info "Claude Code installed successfully"
      claude_installed=true
    else
      warn "Claude Code installation may have failed. Try manually:"
      echo "  curl -fsSL https://claude.ai/install.sh | bash"
      return
    fi
  fi

  # Remind about superpowers plugin
  if [[ "$claude_installed" == true ]] && [[ ! -d ~/.claude/plugins/marketplaces/superpowers-marketplace ]]; then
    echo ""
    info "To complete setup, install superpowers from within Claude Code:"
    echo ""
    echo "  1. Start Claude Code:  claude"
    echo "  2. Add marketplace:    /plugin marketplace add obra/superpowers-marketplace"
    echo "  3. Install plugin:     /plugin install superpowers@superpowers-marketplace"
    echo ""
  fi
}

# ─────────────────────────────────────────────
# Codex Config Setup (Symlinks for global config + skills)
# ─────────────────────────────────────────────
setup_codex_config() {
  info "Setting up Codex CLI configuration..."

  CODEX_DIR="$HOME/.codex"
  AGENTS_DIR="$HOME/.agents/skills"
  DOTFILES_CODEX="$HOME/.dotfiles/.codex"

  # Skip if dotfiles codex config doesn't exist
  if [[ ! -d "$DOTFILES_CODEX" ]]; then
    warn "No Codex config in dotfiles, skipping"
    return
  fi

  # Create directories if needed
  mkdir -p "$CODEX_DIR"
  mkdir -p "$AGENTS_DIR"

  # Remove dangling symlinks left by skills that were deleted from dotfiles
  find "$AGENTS_DIR" -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null || true

  # Helper to symlink with backup
  link_codex_file() {
    local src="$1"
    local dest="$2"

    if [[ -e "$dest" ]] && [[ ! -L "$dest" ]]; then
      local backup="${dest}.backup-$(date +%Y%m%d-%H%M%S)"
      mv "$dest" "$backup"
      warn "Backed up: $dest → $backup"
    fi

    ln -sf "$src" "$dest"
  }

  # Single source of truth: Codex reads the canonical AGENTS.md from the Claude tree.
  [[ -f "$DOTFILES_CLAUDE/AGENTS.md" ]] && link_codex_file "$DOTFILES_CLAUDE/AGENTS.md" "$CODEX_DIR/AGENTS.md"

  # Symlink custom skills into ~/.agents/skills/
  for skill in "$DOTFILES_CODEX/skills/"*/; do
    [[ -d "$skill" ]] || continue
    local skill_name=$(basename "$skill")
    link_codex_file "$skill" "$AGENTS_DIR/$skill_name"
  done

  # Install superpowers if not already cloned
  if [[ ! -d "$CODEX_DIR/superpowers" ]]; then
    info "Cloning superpowers for Codex..."
    if git clone https://github.com/obra/superpowers.git "$CODEX_DIR/superpowers" 2>/dev/null; then
      info "Superpowers cloned"
    else
      warn "Failed to clone superpowers. Install manually: git clone https://github.com/obra/superpowers.git ~/.codex/superpowers"
    fi
  fi

  # Symlink superpowers skills
  if [[ -d "$CODEX_DIR/superpowers/skills" ]]; then
    link_codex_file "$CODEX_DIR/superpowers/skills" "$AGENTS_DIR/superpowers"
  fi

  # config.toml is machine-specific (project trust paths, MCP IPs) so it is COPIED from the
  # template on first install and never overwritten — TOML can't be merged like a symlink.
  if [[ ! -f "$CODEX_DIR/config.toml" ]] && [[ -f "$DOTFILES_CODEX/config.toml.example" ]]; then
    cp "$DOTFILES_CODEX/config.toml.example" "$CODEX_DIR/config.toml"
    info "Created ~/.codex/config.toml from template (edit it for projects + MCP servers)"
  fi

  info "Codex CLI configuration linked"
}

# ─────────────────────────────────────────────
# Workmux Installation (Optional)
# ─────────────────────────────────────────────
setup_workmux() {
  # Check if already installed
  if command -v workmux &>/dev/null; then
    info "Workmux already installed"
    return
  fi

  echo ""
  echo -e "${BLUE}Would you like to install workmux?${NC}"
  echo "Workmux manages git worktrees + tmux for parallel AI agent development."
  echo ""
  read -p "Install workmux? [y/N]: " -n 1 -r
  echo ""

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Skipping workmux. Install later: curl -fsSL https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh | bash"
    return
  fi

  info "Installing workmux..."
  curl -fsSL https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh | bash

  if command -v workmux &>/dev/null; then
    info "Workmux installed successfully"
    echo ""
    echo "  Quick start:"
    echo "    wm add feature-name    # Create worktree + tmux window"
    echo "    wm merge               # Merge and cleanup"
    echo "    wm dashboard           # Monitor all agents"
    echo ""
    echo "  Copy template config to your project:"
    echo "    cp ~/.dotfiles/.workmux.yaml.example /path/to/project/.workmux.yaml"
    echo ""
  else
    warn "Workmux installation may have failed. Try manually:"
    echo "  curl -fsSL https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh | bash"
  fi
}

# ─────────────────────────────────────────────
# GitHub/SSH Setup (Interactive)
# ─────────────────────────────────────────────
setup_github() {
  # Skip if gh not installed
  if ! command -v gh &>/dev/null; then
    warn "GitHub CLI not installed, skipping GitHub setup"
    return
  fi

  # Ask if user wants to set up GitHub
  echo ""
  echo -e "${BLUE}Would you like to set up GitHub authentication?${NC}"
  echo "This will configure git identity, SSH keys, and GitHub auth."
  echo ""
  read -p "Set up GitHub now? [y/N]: " -n 1 -r
  echo ""

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Skipping. Run later with: ~/.dotfiles/scripts/setup-github.sh"
    return
  fi

  echo ""

  # Step 1: Git identity (needed for SSH key comment)
  github_setup_identity

  # Step 2: SSH key
  github_setup_ssh_key

  # Step 3: SSH config
  github_setup_ssh_config

  # Step 4: GitHub authentication (gh will offer to upload our SSH key)
  github_setup_auth

  # Step 5: Verify SSH works
  github_verify_ssh

  # Step 6: Switch remote to SSH
  github_switch_remote
}

github_setup_identity() {
  local GIT_LOCAL="$HOME/.gitconfig.local"

  info "Step 1: Git Identity"

  # Check existing
  if [[ -f "$GIT_LOCAL" ]] && grep -q "name = " "$GIT_LOCAL" 2>/dev/null; then
    echo "  Current:"
    grep -E "name|email" "$GIT_LOCAL" | sed 's/^/    /'
    read -p "  Keep this? [Y/n]: " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Nn]$ ]] && return 0
  fi

  # Get name
  local CURRENT_NAME=$(git config user.name 2>/dev/null || echo "")
  read -p "  Your name${CURRENT_NAME:+ [$CURRENT_NAME]}: " GIT_NAME
  GIT_NAME="${GIT_NAME:-$CURRENT_NAME}"

  # Get email
  local CURRENT_EMAIL=$(git config user.email 2>/dev/null || echo "")
  echo ""
  echo "  Tip: Use GitHub noreply for privacy:"
  echo -e "    ${BLUE}<username>@users.noreply.github.com${NC}"
  echo ""
  read -p "  Your email${CURRENT_EMAIL:+ [$CURRENT_EMAIL]}: " GIT_EMAIL
  GIT_EMAIL="${GIT_EMAIL:-$CURRENT_EMAIL}"

  if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
    warn "Name and email required"
    return 1
  fi

  # Use git config -f to handle special characters in name/email safely
  git config -f "$GIT_LOCAL" user.name "$GIT_NAME"
  git config -f "$GIT_LOCAL" user.email "$GIT_EMAIL"

  export GIT_USER_EMAIL="$GIT_EMAIL"
  info "Saved to $GIT_LOCAL"
  echo ""
}

github_setup_ssh_key() {
  local SSH_DIR="$HOME/.ssh"
  local SSH_KEY="$SSH_DIR/id_ed25519"

  info "Step 2: SSH Key"

  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  if [[ -f "$SSH_KEY" ]]; then
    echo "  Key exists: $SSH_KEY"
    echo "  Fingerprint: $(ssh-keygen -lf "$SSH_KEY" 2>/dev/null | awk '{print $2}')"
    echo ""
    return 0
  fi

  local EMAIL="${GIT_USER_EMAIL:-$(git config user.email 2>/dev/null)}"
  EMAIL="${EMAIL:-user@$(hostname)}"

  ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""
  info "SSH key generated"
  echo ""
}

github_setup_ssh_config() {
  local SSH_CONFIG="$HOME/.ssh/config"

  info "Step 3: SSH Config"

  if [[ -f "$SSH_CONFIG" ]] && grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    echo "  GitHub config already exists"
    echo ""
    return 0
  fi

  cat >> "$SSH_CONFIG" << 'EOF'

# GitHub
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  IdentitiesOnly yes
EOF

  chmod 600 "$SSH_CONFIG"
  info "SSH config updated"
  echo ""
}

github_setup_auth() {
  info "Step 4: GitHub Authentication"

  if gh auth status &>/dev/null; then
    echo "  Already authenticated"
    gh auth setup-git 2>/dev/null || true
    echo ""
    return 0
  fi

  echo ""
  echo "─────────────────────────────────────────────"
  if [[ "$MACHINE_TYPE" == "remote" ]] || [[ -n "$SSH_CONNECTION" ]]; then
    echo -e "${YELLOW}Remote machine detected${NC}"
    echo ""
    echo "  1. A one-time code will be shown"
    echo "  2. On any device, visit:"
    echo -e "     ${BLUE}https://github.com/login/device${NC}"
    echo "  3. Enter the code to authenticate"
  else
    echo "A browser will open for authentication."
    echo "If it doesn't, copy the URL shown."
  fi
  echo ""
  echo "When asked about SSH key, select your existing key"
  echo "and choose to upload it to GitHub."
  echo "─────────────────────────────────────────────"
  echo ""

  gh auth login -h github.com -p ssh
  gh auth setup-git

  info "GitHub authentication complete"
  echo ""
}

github_verify_ssh() {
  info "Step 5: Verify SSH Connection"

  local OUTPUT
  OUTPUT=$(ssh -T git@github.com 2>&1) || true

  if echo "$OUTPUT" | grep -q "successfully authenticated\|Hi "; then
    info "SSH connection working!"
    echo "$OUTPUT" | grep "Hi " | sed 's/^/  /'
  else
    warn "SSH test inconclusive. If 'Permission denied', ensure key was uploaded."
  fi
  echo ""
}

github_switch_remote() {
  info "Step 6: Configure Git Remote"

  if [[ ! -d ".git" ]]; then
    return
  fi

  local CURRENT=$(git remote get-url origin 2>/dev/null || echo "")

  if [[ "$CURRENT" == git@* ]]; then
    echo "  Already using SSH: $CURRENT"
    echo ""
    return
  fi

  if [[ "$CURRENT" == https://github.com/* ]]; then
    local SSH_URL=$(echo "$CURRENT" | sed 's|https://github.com/|git@github.com:|')
    echo "  Current: $CURRENT"
    echo "  SSH:     $SSH_URL"
    read -p "  Switch to SSH? [Y/n]: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      git remote set-url origin "$SSH_URL"
      info "Remote updated"
    fi
  fi
  echo ""
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
main() {
  parse_args "$@"
  detect_machine_type
  detect_os

  case "$OS" in
    macos) install_macos ;;
    linux) install_linux ;;
  esac

  stow_dotfiles
  post_install

  echo ""
  echo "========================================"
  echo -e "  ${GREEN}Installation complete!${NC}"
  echo "========================================"
  echo ""

  # Show configuration summary
  if [[ "$MACHINE_TYPE" == "remote" ]]; then
    echo -e "Configured as: ${BLUE}Remote server${NC}"
    echo "  - Tmux prefix: Ctrl+B"
    echo "  - Auto-attach: SSH sessions only"
    PREFIX_KEY="C-b"
  else
    echo -e "Configured as: ${BLUE}Local machine${NC}"
    echo "  - Tmux prefix: Ctrl+A"
    echo "  - Auto-attach: Always"
    PREFIX_KEY="C-a"
  fi

  echo ""
  echo "Next steps:"
  echo "  1. Restart your terminal or run: exec zsh"
  echo "  2. In tmux, press ${PREFIX_KEY} + I to install plugins"
  echo "  3. Open nvim and wait for plugins to install"
  echo ""
}

main "$@"

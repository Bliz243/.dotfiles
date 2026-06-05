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

# Repo root + shared symlink/stow helpers (stow_dotfiles, relink_claude_config, etc.)
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$DOTFILES_DIR/scripts/lib/links.sh"

# ─────────────────────────────────────────────
# Parse arguments
# ─────────────────────────────────────────────
MACHINE_TYPE=""
# CI/non-interactive: skips optional + interactive steps (claude/workmux/github/chsh)
# so the installer itself can be exercised in the Docker test. Default off.
CI="${CI:-0}"

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
      --ci|--non-interactive)
        CI=1
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
        echo "  --ci        Non-interactive: install core only, skip optional/"
        echo "              interactive steps (Claude/workmux/GitHub/chsh). Used by tests."
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
    neovim gh \
    node bun

  # Install Nerd Font for terminal
  info "Installing JetBrainsMono Nerd Font..."
  brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || warn "Font install failed - install manually from nerdfonts.com"

  # Alacritty terminal (config is stowed from .config/alacritty)
  info "Installing Alacritty..."
  brew install --cask alacritty 2>/dev/null || warn "Alacritty install failed - install manually from alacritty.org"
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
    zsh git curl wget stow unzip gnupg ca-certificates \
    fzf ripgrep fd-find \
    build-essential fontconfig \
    libevent-dev ncurses-dev bison

  # chromium for playwright-cli browser automation — optional, and the package name/availability
  # varies across Ubuntu releases (snap stub on newer ones), so never let it abort the install.
  sudo apt install -y chromium-browser 2>/dev/null \
    || sudo apt install -y chromium 2>/dev/null \
    || warn "chromium not installed (optional; only needed for playwright-cli)"

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

  # Node.js (system LTS) — required by Mason for the npm-based LSP servers
  install_node_linux

  # bun — default JS package manager for projects
  install_bun_linux

  # Alacritty terminal (local/desktop only; pointless + heavy on a headless VPS or CI)
  install_alacritty_linux
}

install_alacritty_linux() {
  # GUI terminal — config is stowed from .config/alacritty. Skip on headless/remote/CI.
  [[ "$CI" == "1" || "$MACHINE_TYPE" == "remote" ]] && return 0
  if command -v alacritty &>/dev/null; then
    info "Alacritty already installed"
    return
  fi
  info "Installing Alacritty..."
  # Available in apt universe on 24.04+; on older releases it needs a PPA/cargo, so never fatal.
  sudo apt install -y alacritty 2>/dev/null \
    || warn "Alacritty not installed (not in apt on this release) — install manually or via cargo"
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

  info "Installing latest stable Neovim..."

  # Detect architecture
  local ARCH
  case "$(uname -m)" in
    x86_64|amd64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
    *) warn "Unsupported architecture $(uname -m) for Neovim binary"; return ;;
  esac

  # Download and install — the rolling "stable" release always points at the latest
  # stable Neovim (currently 0.12.x), so no manual version bumps are needed.
  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  (
    cd "$tmpdir"
    curl -LO "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${ARCH}.tar.gz"
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

  # Refresh font cache (non-fatal — a cache refresh failure shouldn't abort the install)
  fc-cache -fv "$FONT_DIR" >/dev/null 2>&1 || true

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

install_node_linux() {
  # System Node (LTS) exists purely to feed Mason: the LSP servers for the enabled
  # lang extras (typescript, tailwind, json, yaml, docker, basedpyright) are npm
  # packages Mason installs via `npm`. Project JS uses bun, so a single LTS is ideal.
  # NodeSource (not Ubuntu's apt) provides a current LTS, always on PATH for any
  # process — including post_install's headless `Lazy! sync`.
  if command -v node &>/dev/null; then
    info "Node already installed ($(node -v))"
    return
  fi

  info "Installing Node.js LTS (NodeSource)..."
  ensure_sudo
  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  # Download then run (not piped to a shell) so the setup is auditable.
  if curl -fsSL https://deb.nodesource.com/setup_lts.x -o "$tmpdir/nodesource.sh" \
    && sudo -E bash "$tmpdir/nodesource.sh" \
    && sudo apt install -y nodejs; then
    info "Node $(node -v) / npm $(npm -v) installed"
  else
    warn "Node install failed — Mason LSP servers (ts/tailwind/json/yaml/docker/python) won't install"
  fi
}

install_bun_linux() {
  # bun: default JS package manager for projects. ~/.bun/bin is already on PATH via .zshrc.
  if command -v bun &>/dev/null || [[ -x "$HOME/.bun/bin/bun" ]]; then
    info "bun already installed"
    return
  fi

  info "Installing bun..."
  local arch="x64"
  case "$(uname -m)" in aarch64 | arm64) arch="aarch64" ;; esac
  mkdir -p "$HOME/.bun/bin"

  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  if curl -fsSLo "$tmpdir/bun.zip" \
      "https://github.com/oven-sh/bun/releases/latest/download/bun-linux-${arch}.zip" \
    && unzip -o "$tmpdir/bun.zip" -d "$tmpdir" >/dev/null; then
    mv "$tmpdir"/bun-linux-*/bun "$HOME/.bun/bin/bun"
    chmod +x "$HOME/.bun/bin/bun"
    info "bun $("$HOME/.bun/bin/bun" --version) installed"
  else
    warn "bun install failed — install manually from https://bun.sh"
  fi
}

# stow_dotfiles() is provided by scripts/lib/links.sh

# ─────────────────────────────────────────────
# Post-install setup
# ─────────────────────────────────────────────
post_install() {
  info "Running post-install setup..."

  # Set zsh as default shell (skipped in CI — chsh prompts for a password)
  if [[ "$CI" != "1" && "$SHELL" != */zsh ]]; then
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
  relink_claude_config
}

# ─────────────────────────────────────────────
# Claude Code Installation (Optional)
# ─────────────────────────────────────────────
setup_claude_code() {
  [[ "$CI" == "1" ]] && { info "CI: skipping Claude Code install"; return; }

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

  [[ -d "$DOTFILES_DIR/.codex" ]] || { warn "No Codex config in dotfiles, skipping"; return; }

  # Bootstrap: clone superpowers once (network); relinking is handled by the lib.
  local codex_dir="$HOME/.codex"
  if [[ ! -d "$codex_dir/superpowers" ]]; then
    info "Cloning superpowers for Codex..."
    mkdir -p "$codex_dir"
    if git clone https://github.com/obra/superpowers.git "$codex_dir/superpowers" 2>/dev/null; then
      info "Superpowers cloned"
    else
      warn "Failed to clone superpowers. Install manually: git clone https://github.com/obra/superpowers.git ~/.codex/superpowers"
    fi
  fi

  relink_codex_config
}

# ─────────────────────────────────────────────
# Workmux Installation (Optional)
# ─────────────────────────────────────────────
setup_workmux() {
  [[ "$CI" == "1" ]] && { info "CI: skipping workmux install"; return; }

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
  [[ "$CI" == "1" ]] && { info "CI: skipping GitHub setup"; return; }

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

  # Single source of truth: delegate to the standalone GitHub/SSH setup script.
  bash "$DOTFILES_DIR/scripts/setup-github.sh"
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

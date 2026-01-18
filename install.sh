#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Dotfiles Installation Script
# ─────────────────────────────────────────────

echo "========================================"
echo "  Dotfiles Installation"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

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
    neovim
}

# ─────────────────────────────────────────────
# Install packages - Linux (Ubuntu/Debian)
# ─────────────────────────────────────────────
install_linux() {
  info "Installing packages via apt..."

  sudo apt update
  sudo apt install -y \
    zsh git curl stow tmux \
    fzf ripgrep fd-find \
    build-essential

  # bat (called batcat on Ubuntu, create symlink)
  if ! command -v bat &>/dev/null; then
    sudo apt install -y bat
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
  fi

  # eza
  install_eza_linux

  # zoxide
  install_zoxide_linux

  # Neovim 0.11+
  install_neovim_linux
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

install_neovim_linux() {
  # Check if nvim is already installed and is 0.11+
  if command -v nvim &>/dev/null; then
    NVIM_VERSION=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
    NVIM_MAJOR=$(echo "$NVIM_VERSION" | cut -d. -f1)
    NVIM_MINOR=$(echo "$NVIM_VERSION" | cut -d. -f2)
    if [[ "$NVIM_MAJOR" -gt 0 ]] || [[ "$NVIM_MAJOR" -eq 0 && "$NVIM_MINOR" -ge 11 ]]; then
      info "Neovim $NVIM_VERSION already installed"
      return
    fi
    warn "Neovim $NVIM_VERSION found, but 0.11+ required. Upgrading..."
  fi

  info "Installing Neovim 0.11+..."
  NVIM_VERSION="0.11.0"

  # Download and install
  cd /tmp
  curl -LO "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
  sudo rm -rf /opt/nvim-linux-x86_64
  sudo tar -xzf nvim-linux-x86_64.tar.gz -C /opt/
  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  rm nvim-linux-x86_64.tar.gz
  cd - >/dev/null
}

# ─────────────────────────────────────────────
# Stow dotfiles
# ─────────────────────────────────────────────
stow_dotfiles() {
  info "Stowing dotfiles..."

  DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
  cd "$DOTFILES_DIR"

  # Remove conflicting files/symlinks
  for file in .zshrc .tmux.conf .gitconfig; do
    if [[ -f "$HOME/$file" ]] && [[ ! -L "$HOME/$file" ]]; then
      warn "Backing up existing $file to $file.backup"
      mv "$HOME/$file" "$HOME/$file.backup"
    fi
  done

  # Stow with ignore patterns
  stow . --target="$HOME" --restow \
    --ignore='install.sh' \
    --ignore='README.md' \
    --ignore='LICENSE' \
    --ignore='test' \
    --ignore='docs'
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

  # Install tmux plugin manager
  if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    info "Installing tmux plugin manager..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi

  # Create local config templates
  if [[ ! -f ~/.zsh/99-local.zsh ]]; then
    cp ~/.zsh/99-local.zsh.example ~/.zsh/99-local.zsh 2>/dev/null || true
  fi

  # Sync Neovim plugins
  info "Syncing Neovim plugins (this may take a moment)..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Neovim plugin sync had issues - run :Lazy sync manually"
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
main() {
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
  echo "Next steps:"
  echo "  1. Restart your terminal or run: exec zsh"
  echo "  2. In tmux, press C-a + I to install plugins"
  echo "  3. Open nvim and wait for plugins to install"
  echo ""
}

main "$@"

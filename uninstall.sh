#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Dotfiles Uninstall Script
# ─────────────────────────────────────────────

echo "========================================"
echo "  Dotfiles Uninstall"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ─────────────────────────────────────────────
# Confirmation
# ─────────────────────────────────────────────
confirm() {
  echo "This will remove all dotfile symlinks from your home directory."
  echo "Your backup files (*.backup-*) will NOT be deleted."
  echo ""
  read -p "Are you sure? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
}

# ─────────────────────────────────────────────
# Unstow dotfiles
# ─────────────────────────────────────────────
unstow_dotfiles() {
  info "Removing dotfile symlinks..."

  DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
  cd "$DOTFILES_DIR"

  if ! stow -D . --target="$HOME"; then
    warn "Some symlinks could not be removed"
  fi

  info "Symlinks removed"
}

# ─────────────────────────────────────────────
# Optional: Remove installed components
# ─────────────────────────────────────────────
remove_components() {
  echo ""
  read -p "Also remove TPM and Neovim plugins? (y/N) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Removing tmux plugins..."
    rm -rf ~/.tmux/plugins

    info "Removing Neovim plugins and data..."
    rm -rf ~/.local/share/nvim
    rm -rf ~/.local/state/nvim
    rm -rf ~/.cache/nvim

    info "Removing zinit..."
    rm -rf ~/.local/share/zinit
  fi
}

# ─────────────────────────────────────────────
# Show backup files
# ─────────────────────────────────────────────
show_backups() {
  echo ""
  info "Looking for backup files..."

  BACKUPS=$(find "$HOME" -maxdepth 2 -name "*.backup-*" 2>/dev/null || true)

  if [[ -n "$BACKUPS" ]]; then
    echo "Found backup files you can restore:"
    echo "$BACKUPS"
    echo ""
    echo "To restore a backup:"
    echo "  mv ~/.zshrc.backup-YYYYMMDD-HHMMSS ~/.zshrc"
  else
    echo "No backup files found."
  fi
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
main() {
  confirm
  unstow_dotfiles
  remove_components
  show_backups

  echo ""
  echo "========================================"
  echo -e "  ${GREEN}Uninstall complete!${NC}"
  echo "========================================"
  echo ""
  echo "Your shell is still set to zsh. To change it back:"
  echo "  chsh -s /bin/bash"
  echo ""
}

main "$@"

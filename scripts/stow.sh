#!/bin/bash

# Stow Script - Symlinks all dotfiles packages using GNU Stow
# Usage: ./scripts/stow.sh [package1 package2 ...] or ./scripts/stow.sh (for all)

set -e

# Auto-detect dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
STOW_DIR="$DOTFILES_DIR/stow"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    print_error "GNU Stow is not installed!"
    print_info "Install it with:"
    echo "  macOS:   brew install stow"
    echo "  Ubuntu:  sudo apt install stow"
    echo "  Arch:    sudo pacman -S stow"
    exit 1
fi

# Change to stow directory
cd "$STOW_DIR"

# Simple backup of existing configs (YAGNI - just the main ones)
backup_existing() {
    local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    local backed_up=0

    # Only backup if files exist and aren't already symlinks
    for file in .zshrc .tmux.conf .gitconfig; do
        if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
            if [ $backed_up -eq 0 ]; then
                mkdir -p "$backup_dir"
                print_info "Backing up existing configs to: $backup_dir"
            fi
            cp "$HOME/$file" "$backup_dir/"
            ((backed_up++))
        fi
    done

    # Backup config directories
    for dir in .config/nvim .config/alacritty; do
        if [ -d "$HOME/$dir" ] && [ ! -L "$HOME/$dir" ]; then
            if [ $backed_up -eq 0 ]; then
                mkdir -p "$backup_dir"
                print_info "Backing up existing configs to: $backup_dir"
            fi
            cp -r "$HOME/$dir" "$backup_dir/"
            ((backed_up++))
        fi
    done

    if [ $backed_up -gt 0 ]; then
        echo "$backup_dir" > "$DOTFILES_DIR/.last-backup"
        print_success "Backed up $backed_up item(s)"
    fi
}

print_header "🔗 Stowing Dotfiles"

# Backup existing configs before stowing
backup_existing

# If arguments provided, stow only those packages
if [ $# -gt 0 ]; then
    PACKAGES=("$@")
else
    # Otherwise, stow all packages
    PACKAGES=($(ls -d */ | sed 's#/##'))
fi

# Stow each package
for package in "${PACKAGES[@]}"; do
    if [ -d "$package" ]; then
        print_info "Stowing $package..."
        if stow -v -t "$HOME" "$package" 2>&1; then
            print_success "$package stowed successfully"
        else
            print_error "Failed to stow $package"
        fi
    else
        print_warning "Package '$package' not found, skipping"
    fi
done

print_header "✨ Stowing Complete!"
print_info "All symlinks have been created"
print_info "Changes to files in $STOW_DIR will now be immediately reflected"

echo ""

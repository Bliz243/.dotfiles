#!/bin/bash

# Stow Script - Symlinks all dotfiles packages using GNU Stow
# Usage: ./scripts/stow.sh [package1 package2 ...] or ./scripts/stow.sh (for all)

set -e

DOTFILES_DIR="$HOME/.dotfiles"
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

print_header "🔗 Stowing Dotfiles"

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

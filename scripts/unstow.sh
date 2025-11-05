#!/bin/bash

# Unstow Script - Removes all dotfiles symlinks created by GNU Stow
# Usage: ./scripts/unstow.sh [package1 package2 ...] or ./scripts/unstow.sh (for all)

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
    exit 1
fi

# Change to stow directory
cd "$STOW_DIR"

print_header "🔓 Unstowing Dotfiles"

# If arguments provided, unstow only those packages
if [ $# -gt 0 ]; then
    PACKAGES=("$@")
else
    # Otherwise, unstow all packages
    PACKAGES=($(ls -d */ | sed 's#/##'))
fi

# Unstow each package
for package in "${PACKAGES[@]}"; do
    if [ -d "$package" ]; then
        print_info "Unstowing $package..."
        if stow -D -v -t "$HOME" "$package" 2>&1; then
            print_success "$package unstowed successfully"
        else
            print_error "Failed to unstow $package"
        fi
    else
        print_warning "Package '$package' not found, skipping"
    fi
done

print_header "✨ Unstowing Complete!"
print_info "All symlinks have been removed"

echo ""

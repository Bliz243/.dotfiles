#!/bin/bash

# Health Check Script - Validates the entire dotfiles setup
# Usage: ./scripts/health-check.sh

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

ERRORS=0
WARNINGS=0
CHECKS=0

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS++))
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
    ((CHECKS++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
    ((CHECKS++))
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_header "🏥 Dotfiles Health Check"

# Check 1: Repository status
print_info "Checking repository status..."
cd "$DOTFILES_DIR"
if [ -d ".git" ]; then
    print_success "Git repository is initialized"

    # Check for uncommitted changes
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        print_success "No uncommitted changes"
    else
        print_warning "You have uncommitted changes"
    fi
else
    print_error "Not a git repository"
fi

# Check 2: Required tools
print_header "🔧 Required Tools"

tools=("git" "stow" "zsh" "nvim" "tmux")
for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        version=$(command "$tool" --version 2>&1 | head -n1)
        print_success "$tool is installed: $version"
    else
        print_error "$tool is not installed"
    fi
done

# Check 3: Optional modern CLI tools
print_header "⚡ Modern CLI Tools"

modern_tools=("eza" "bat" "fd" "rg" "fzf" "zoxide" "starship")
for tool in "${modern_tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        print_success "$tool is installed"
    else
        print_warning "$tool is not installed (optional)"
    fi
done

# Check 4: Symlinks validation
print_header "🔗 Symlink Validation"

dotfiles=(
    "$HOME/.zshrc"
    "$HOME/.config/nvim/init.vim"
    "$HOME/.tmux.conf"
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"
)

for dotfile in "${dotfiles[@]}"; do
    if [ -L "$dotfile" ]; then
        target=$(readlink "$dotfile")
        if [ -e "$dotfile" ]; then
            print_success "$dotfile → $target (valid)"
        else
            print_error "$dotfile → $target (broken symlink)"
        fi
    elif [ -e "$dotfile" ]; then
        print_warning "$dotfile exists but is not a symlink"
    else
        print_warning "$dotfile does not exist"
    fi
done

# Check 5: Shell configuration
print_header "🐚 Shell Configuration"

if [ -f "$HOME/.zshrc" ]; then
    print_success ".zshrc exists"

    # Check for modular config directory
    if [ -d "$HOME/.zsh" ]; then
        print_success ".zsh directory exists"

        # Count module files
        module_count=$(find "$HOME/.zsh" -name "*.zsh" -not -name "99-local.zsh" | wc -l)
        print_info "Found $module_count configuration modules"
    else
        print_warning ".zsh directory not found (modular config not set up)"
    fi
else
    print_error ".zshrc not found"
fi

# Check 6: Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    print_success "Oh My Zsh is installed"

    # Check for zsh-autosuggestions
    if [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        print_success "zsh-autosuggestions plugin is installed"
    else
        print_warning "zsh-autosuggestions plugin not found"
    fi
else
    print_warning "Oh My Zsh is not installed"
fi

# Check 7: Neovim configuration
print_header "📝 Neovim Configuration"

if [ -f "$HOME/.config/nvim/init.vim" ]; then
    print_success "init.vim exists"

    # Check for vim-plug
    if [ -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ]; then
        print_success "vim-plug is installed"
    else
        print_warning "vim-plug not found"
    fi

    # Check for plugins directory
    if [ -d "$HOME/.local/share/nvim/plugged" ]; then
        plugin_count=$(ls -1 "$HOME/.local/share/nvim/plugged" | wc -l)
        print_success "$plugin_count Neovim plugins installed"
    else
        print_warning "No Neovim plugins found"
    fi
else
    print_error "init.vim not found"
fi

# Check 8: Shell startup time
print_header "⚡ Performance"

if command -v zsh &> /dev/null; then
    print_info "Measuring shell startup time..."
    startup_time=$(time zsh -i -c exit 2>&1 | grep real | awk '{print $2}')
    print_info "Zsh startup time: $startup_time"

    # Parse time and warn if slow
    if [[ $startup_time =~ ([0-9]+)\.([0-9]+) ]]; then
        seconds=${BASH_REMATCH[1]}
        if [ "$seconds" -gt 1 ]; then
            print_warning "Shell startup is slow (> 1s). Consider profiling with zprof."
        else
            print_success "Shell startup time is good"
        fi
    fi
fi

# Check 9: Directory structure
print_header "📁 Directory Structure"

required_dirs=(
    "$DOTFILES_DIR/stow"
    "$DOTFILES_DIR/scripts"
    "$DOTFILES_DIR/ansible"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_success "$dir exists"
    else
        print_error "$dir not found"
    fi
done

# Check 10: Stow packages
print_info "Checking stow packages..."
if [ -d "$STOW_DIR" ]; then
    package_count=$(ls -1d "$STOW_DIR"/*/ 2>/dev/null | wc -l)
    print_success "Found $package_count stow packages"
else
    print_error "Stow directory not found"
fi

# Summary
print_header "📊 Health Check Summary"

echo ""
echo -e "Total checks: ${BLUE}$CHECKS${NC}"
echo -e "Passed: ${GREEN}$((CHECKS - ERRORS - WARNINGS))${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "Errors: ${RED}$ERRORS${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_success "All checks passed! Your dotfiles are in perfect health! 🎉"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    print_warning "Health check completed with warnings. Everything should work but some optional features may be missing."
    exit 0
else
    print_error "Health check found critical issues. Please address the errors above."
    exit 1
fi

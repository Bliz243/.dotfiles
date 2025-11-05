#!/bin/bash

# Dotfiles Update Script
# Updates all tools and configurations

set -e

# Auto-detect dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

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

# Check if we're in the dotfiles directory
if [ ! -d "$DOTFILES_DIR" ]; then
    print_error "Dotfiles directory not found at $DOTFILES_DIR"
    exit 1
fi

cd "$DOTFILES_DIR"

print_header "🚀 Updating Dotfiles"

# Update dotfiles repository
print_info "Updating dotfiles repository..."
if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
    print_success "Dotfiles repository updated"
else
    print_warning "Could not update dotfiles repository (may already be up to date)"
fi

# Update Oh My Zsh
print_header "📦 Updating Oh My Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    print_info "Updating Oh My Zsh..."
    if command -v omz &> /dev/null; then
        omz update --unattended
        print_success "Oh My Zsh updated"
    else
        print_warning "omz command not found, skipping"
    fi
else
    print_warning "Oh My Zsh not installed, skipping"
fi

# Update zsh-autosuggestions plugin
print_info "Updating zsh-autosuggestions..."
if [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    cd "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    git pull
    cd "$DOTFILES_DIR"
    print_success "zsh-autosuggestions updated"
else
    print_warning "zsh-autosuggestions not installed, skipping"
fi

# Update Neovim plugins
print_header "🔌 Updating Neovim Plugins"
if command -v nvim &> /dev/null; then
    print_info "Updating vim-plug..."
    nvim +PlugUpgrade +qall 2>/dev/null || true

    print_info "Updating Neovim plugins..."
    nvim +PlugUpdate +qall 2>/dev/null || true
    print_success "Neovim plugins updated"

    print_info "Updating CoC extensions..."
    nvim +CocUpdate +qall 2>/dev/null || true
    print_success "CoC extensions updated"
else
    print_warning "Neovim not installed, skipping plugin updates"
fi

# Update Starship
print_header "⭐ Updating Starship"
if command -v starship &> /dev/null; then
    print_info "Updating Starship prompt..."
    if command -v curl &> /dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y > /dev/null 2>&1
        print_success "Starship updated"
    else
        print_warning "curl not found, skipping Starship update"
    fi
else
    print_warning "Starship not installed, skipping"
fi

# Update Rust tools (if cargo is available)
print_header "🦀 Updating Rust Tools"
if command -v cargo &> /dev/null; then
    print_info "Updating Rust toolchain..."
    if command -v rustup &> /dev/null; then
        rustup update > /dev/null 2>&1
        print_success "Rust toolchain updated"
    fi

    print_info "Checking for cargo tool updates..."
    tools=("eza" "bat" "fd-find" "ripgrep" "zoxide")
    for tool in "${tools[@]}"; do
        if command -v "${tool%%-*}" &> /dev/null; then
            print_info "  Updating $tool..."
            cargo install "$tool" --force > /dev/null 2>&1 || print_warning "  Failed to update $tool"
        fi
    done
    print_success "Cargo tools checked for updates"
else
    print_warning "Cargo not installed, skipping Rust tools update"
fi

# Update package manager packages
print_header "📦 Updating System Packages"
print_info "Checking system package manager..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &> /dev/null; then
        print_info "Updating Homebrew packages..."
        brew update > /dev/null 2>&1
        brew upgrade > /dev/null 2>&1
        print_success "Homebrew packages updated"
    fi
elif command -v apt-get &> /dev/null; then
    print_info "Updating apt packages..."
    sudo apt-get update > /dev/null 2>&1
    sudo apt-get upgrade -y > /dev/null 2>&1
    print_success "apt packages updated"
elif command -v pacman &> /dev/null; then
    print_info "Updating pacman packages..."
    sudo pacman -Syu --noconfirm > /dev/null 2>&1
    print_success "pacman packages updated"
elif command -v dnf &> /dev/null; then
    print_info "Updating dnf packages..."
    sudo dnf upgrade -y > /dev/null 2>&1
    print_success "dnf packages updated"
else
    print_warning "No known package manager found, skipping system package updates"
fi

# Re-run Ansible playbook (optional)
print_header "🔧 Ansible Playbook"
read -p "$(echo -e ${YELLOW}?${NC} Do you want to re-run the Ansible playbook? [y/N] )" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Running Ansible playbook..."
    cd "$DOTFILES_DIR"
    if command -v ansible-playbook &> /dev/null; then
        ansible-playbook ansible/setup-new-machine.yml
        print_success "Ansible playbook completed"
    else
        print_error "Ansible not installed"
    fi
fi

# Reload shell configuration
print_header "🔄 Reloading Configuration"
print_info "To apply all updates, reload your shell configuration:"
echo -e "  ${GREEN}source ~/.zshrc${NC}  # or restart your terminal"

print_header "✨ Update Complete!"
print_success "All updates completed successfully"
print_info "Don't forget to restart your terminal or run: exec zsh"

echo ""

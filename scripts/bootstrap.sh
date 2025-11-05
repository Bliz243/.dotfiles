#!/bin/bash

# Bootstrap Script - One-command installation of dotfiles
# Usage: curl -fsSL https://raw.githubusercontent.com/USERNAME/.dotfiles/main/scripts/bootstrap.sh | bash
# Or: ./scripts/bootstrap.sh

set -e

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Bliz243/.dotfiles.git}"
DOTFILES_DIR="$HOME/.dotfiles"

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

print_header "🚀 Dotfiles Bootstrap"

# Detect OS
print_info "Detecting operating system..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    print_info "Detected macOS"
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    print_info "Detected $PRETTY_NAME"
else
    print_error "Unsupported operating system"
    exit 1
fi

# Check if dotfiles directory already exists
if [ -d "$DOTFILES_DIR" ]; then
    print_warning "Dotfiles directory already exists at $DOTFILES_DIR"
    read -p "Do you want to remove it and start fresh? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Backing up existing dotfiles to $DOTFILES_DIR.backup"
        mv "$DOTFILES_DIR" "$DOTFILES_DIR.backup.$(date +%Y%m%d-%H%M%S)"
    else
        print_info "Using existing dotfiles directory"
        cd "$DOTFILES_DIR"
        git pull
    fi
else
    # Clone the repository
    print_header "📦 Cloning Dotfiles Repository"
    if command -v git &> /dev/null; then
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        print_success "Repository cloned successfully"
    else
        print_error "Git is not installed. Installing git first..."
        # Install git based on OS
        case $OS in
            macos)
                if command -v brew &> /dev/null; then
                    brew install git
                else
                    print_error "Homebrew not found. Please install Homebrew first."
                    exit 1
                fi
                ;;
            ubuntu|debian)
                sudo apt-get update && sudo apt-get install -y git
                ;;
            arch|manjaro)
                sudo pacman -Sy --noconfirm git
                ;;
            fedora|rhel|centos)
                sudo dnf install -y git
                ;;
            *)
                print_error "Unsupported OS for automatic git installation"
                exit 1
                ;;
        esac
        # Try cloning again
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        print_success "Repository cloned successfully"
    fi
fi

cd "$DOTFILES_DIR"

# Install GNU Stow
print_header "🔧 Installing GNU Stow"
if command -v stow &> /dev/null; then
    print_success "GNU Stow is already installed"
else
    print_info "Installing GNU Stow..."
    case $OS in
        macos)
            brew install stow
            ;;
        ubuntu|debian)
            sudo apt-get update && sudo apt-get install -y stow
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm stow
            ;;
        fedora|rhel|centos)
            sudo dnf install -y stow
            ;;
        *)
            print_error "Unsupported OS for automatic stow installation"
            exit 1
            ;;
    esac
    print_success "GNU Stow installed successfully"
fi

# Run main installation
print_header "📦 Running Main Installation"
if [ -f "$DOTFILES_DIR/install.sh" ]; then
    bash "$DOTFILES_DIR/install.sh"
else
    print_error "install.sh not found"
    exit 1
fi

# Stow dotfiles
print_header "🔗 Stowing Dotfiles"
if [ -f "$DOTFILES_DIR/scripts/stow.sh" ]; then
    bash "$DOTFILES_DIR/scripts/stow.sh"
    print_success "Dotfiles stowed successfully"
else
    print_error "stow.sh script not found"
fi

# Run health check
print_header "🏥 Running Health Check"
if [ -f "$DOTFILES_DIR/scripts/health-check.sh" ]; then
    bash "$DOTFILES_DIR/scripts/health-check.sh"
fi

# Final steps
print_header "✨ Installation Complete!"
echo ""
print_info "Your dotfiles have been successfully installed!"
echo ""
print_info "Next steps:"
echo "  1. Restart your terminal or run: exec zsh"
echo "  2. Review your configuration in $DOTFILES_DIR"
echo "  3. Customize ~/.zsh/99-local.zsh for machine-specific settings"
echo "  4. Set your git user info: git config --global user.name 'Your Name'"
echo "  5. Set your git email: git config --global user.email 'your@email.com'"
echo ""
print_info "Useful commands:"
echo "  make health     # Run health check"
echo "  make update     # Update everything"
echo "  make stow       # Re-stow packages"
echo ""
print_success "Enjoy your optimized development environment! 🎉"
echo ""

#!/bin/bash

# Dotfiles Installation Script
# This script sets up the system and installs necessary tools
# Actual dotfiles symlinking is handled by GNU Stow (see scripts/stow.sh)

set -e

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

print_header "🚀 Dotfiles Installation"

# Detect the Operating System and Distribution
OS="$(uname -s)"
DISTRO=""

if [ "$OS" == "Linux" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    fi
fi

print_info "Detected OS: $OS"
print_info "Detected Distro: $DISTRO"

# Detect machine type (server vs workstation)
print_header "🖥️  Machine Type Detection"

if [ -n "$DISPLAY" ] || [ -n "$WSL_DISTRO_NAME" ] || [ "$OS" == "Darwin" ]; then
    MACHINE_TYPE="workstation"
    print_info "Detected: Workstation (GUI environment)"
else
    MACHINE_TYPE="server"
    print_info "Detected: Server (headless)"
fi

# Allow override with simple prompt (keep it YAGNI)
read -p "Install as (w)orkstation or (s)erver? [default: $MACHINE_TYPE]: " choice
case $choice in
    w|W|workstation) MACHINE_TYPE="workstation" ;;
    s|S|server) MACHINE_TYPE="server" ;;
esac

print_success "Installing as: $MACHINE_TYPE"
echo "$MACHINE_TYPE" > "$DOTFILES_DIR/.machine-type"

# Function to install Git and Ansible on macOS
install_mac() {
    print_header "📦 macOS Setup"

    # Install Xcode Command Line Tools
    if ! xcode-select -p &>/dev/null; then
        print_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        # Wait until the tools are installed
        until xcode-select -p &>/dev/null; do
            sleep 5
        done
        print_success "Xcode Command Line Tools installed"
    else
        print_success "Xcode Command Line Tools already installed"
    fi

    # Install Homebrew if not already installed
    if ! command -v brew &>/dev/null; then
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        print_success "Homebrew installed"
    else
        print_success "Homebrew already installed"
    fi

    # Install Git if not installed
    if ! command -v git &>/dev/null; then
        print_info "Installing Git..."
        brew install git
        print_success "Git installed"
    else
        print_success "Git already installed"
    fi

    # Install Ansible
    if ! command -v ansible &>/dev/null; then
        print_info "Installing Ansible..."
        brew install ansible
        print_success "Ansible installed"
    else
        print_success "Ansible already installed"
    fi

    # Install GNU Stow
    if ! command -v stow &>/dev/null; then
        print_info "Installing GNU Stow..."
        brew install stow
        print_success "GNU Stow installed"
    else
        print_success "GNU Stow already installed"
    fi
}

# Function to install Git and Ansible on Debian/Ubuntu
install_debian() {
    print_header "📦 Debian/Ubuntu Setup"

    print_info "Updating package lists..."
    sudo apt-get update

    # Install Git
    if ! command -v git &>/dev/null; then
        print_info "Installing Git..."
        sudo apt-get install -y git
        print_success "Git installed"
    else
        print_success "Git already installed"
    fi

    # Install Ansible
    if ! command -v ansible &>/dev/null; then
        print_info "Installing Ansible..."
        sudo apt-get install -y ansible
        print_success "Ansible installed"
    else
        print_success "Ansible already installed"
    fi

    # Install GNU Stow
    if ! command -v stow &>/dev/null; then
        print_info "Installing GNU Stow..."
        sudo apt-get install -y stow
        print_success "GNU Stow installed"
    else
        print_success "GNU Stow already installed"
    fi
}

# Function to install Git and Ansible on Arch Linux
install_arch() {
    print_header "📦 Arch Linux Setup"

    print_info "Updating package database..."
    sudo pacman -Sy

    # Install Git
    if ! command -v git &>/dev/null; then
        print_info "Installing Git..."
        sudo pacman -S --noconfirm git
        print_success "Git installed"
    else
        print_success "Git already installed"
    fi

    # Install Ansible
    if ! command -v ansible &>/dev/null; then
        print_info "Installing Ansible..."
        sudo pacman -S --noconfirm ansible
        print_success "Ansible installed"
    else
        print_success "Ansible already installed"
    fi

    # Install GNU Stow
    if ! command -v stow &>/dev/null; then
        print_info "Installing GNU Stow..."
        sudo pacman -S --noconfirm stow
        print_success "GNU Stow installed"
    else
        print_success "GNU Stow already installed"
    fi
}

# Function to install Git and Ansible on Fedora/RHEL/CentOS
install_fedora() {
    print_header "📦 Fedora/RHEL/CentOS Setup"

    # Install Git
    if ! command -v git &>/dev/null; then
        print_info "Installing Git..."
        sudo dnf install -y git
        print_success "Git installed"
    else
        print_success "Git already installed"
    fi

    # Install Ansible
    if ! command -v ansible &>/dev/null; then
        print_info "Installing Ansible..."
        sudo dnf install -y ansible
        print_success "Ansible installed"
    else
        print_success "Ansible already installed"
    fi

    # Install GNU Stow
    if ! command -v stow &>/dev/null; then
        print_info "Installing GNU Stow..."
        sudo dnf install -y stow
        print_success "GNU Stow installed"
    else
        print_success "GNU Stow already installed"
    fi
}

# Install dependencies based on OS/Distribution
case "$OS" in
    Darwin)
        install_mac
        ;;
    Linux)
        case "$DISTRO" in
            ubuntu|debian)
                install_debian
                ;;
            arch|manjaro)
                install_arch
                ;;
            fedora|rhel|centos)
                install_fedora
                ;;
            *)
                print_error "Unsupported Linux distribution: $DISTRO"
                exit 1
                ;;
        esac
        ;;
    *)
        print_error "Unsupported operating system: $OS"
        exit 1
        ;;
esac

# Run Ansible Playbook
print_header "🤖 Running Ansible Playbook"
cd "$DOTFILES_DIR/ansible"

# Pass machine type to Ansible (servers skip GUI tools)
if [ "$MACHINE_TYPE" = "server" ]; then
    print_info "Server installation: skipping GUI tools (Alacritty, fonts)"
    if ansible-playbook setup-new-machine.yml --skip-tags "gui,fonts"; then
        print_success "Ansible playbook completed successfully"
    else
        print_error "Ansible playbook failed"
        print_info "Check the output above for errors"
        exit 1
    fi
else
    print_info "Workstation installation: installing all tools"
    if ansible-playbook setup-new-machine.yml; then
        print_success "Ansible playbook completed successfully"
    else
        print_error "Ansible playbook failed"
        print_info "Check the output above for errors"
        exit 1
    fi
fi

print_header "✨ Installation Complete!"
echo ""
print_info "Next steps:"
echo "  1. Symlink dotfiles: make stow"
echo "  2. Restart your terminal or run: exec zsh"
echo "  3. Run health check: make health"
echo "  4. Customize local settings:"
echo "     - ~/.zsh/99-local.zsh"
echo "     - ~/.gitconfig.local"
echo ""
print_success "Enjoy your optimized development environment! 🎉"
echo ""

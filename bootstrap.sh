#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Detect the Operating System and Distribution
OS="$(uname -s)"
DISTRO=""

if [ "$OS" == "Linux" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    fi
fi

echo "Detected OS: $OS"
echo "Detected Distro: $DISTRO"

# Function to install Git and Ansible on macOS
install_mac() {
    # Install Xcode Command Line Tools
    if ! xcode-select -p &>/dev/null; then
        echo "Installing Xcode Command Line Tools..."
        xcode-select --install
        # Wait until the tools are installed
        until xcode-select -p &>/dev/null; do
            sleep 5
        done
    fi

    # Install Homebrew
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install Git and Ansible
    echo "Installing Git and Ansible..."
    brew install git ansible
}

# Function to install Git and Ansible on Debian/Ubuntu
install_debian() {
    echo "Updating package list..."
    sudo apt update

    echo "Installing Git and Ansible..."
    sudo apt install -y git ansible
}

# Function to install Git and Ansible on Arch Linux
install_arch() {
    echo "Updating package list..."
    sudo pacman -Syu --noconfirm

    echo "Installing Git and Ansible..."
    sudo pacman -S --noconfirm git ansible
}

# Function to install Git and Ansible on Fedora/RHEL
install_fedora() {
    echo "Updating package list..."
    sudo dnf makecache

    echo "Installing Git and Ansible..."
    sudo dnf install -y git ansible
}

# Install Git and Ansible based on OS
if [ "$OS" == "Darwin" ]; then
    install_mac
elif [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ]; then
    install_debian
elif [ "$DISTRO" == "arch" ]; then
    install_arch
elif [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "rhel" ]; then
    install_fedora
else
    echo "Unsupported OS or distribution."
    exit 1
fi

# Clone the dotfiles repository
if [ ! -d "$HOME/.dotfiles" ]; then
    echo "Cloning dotfiles repository..."
    git clone https://github.com/yourusername/dotfiles.git "$HOME/.dotfiles"
else
    echo "Dotfiles repository already exists. Pulling latest changes..."
    git -C "$HOME/.dotfiles" pull
fi

cd "$HOME/.dotfiles"

# Install Ansible roles and collections if required
if [ -f "ansible/requirements.yml" ]; then
    echo "Installing Ansible roles and collections..."
    ansible-galaxy install -r ansible/requirements.yml
fi

# Run the Ansible playbook
echo "Running Ansible playbook..."
ansible-playbook -i ansible/inventories/hosts ansible/setup-new-machine.yml

echo "Setup complete!"

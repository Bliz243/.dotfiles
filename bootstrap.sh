#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Initialize variables
TAGS=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --tags)
            TAGS="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
    esac
done

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

# [Rest of your install functions...]

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

# Run the Ansible playbook with tags if provided
echo "Running Ansible playbook..."

ansible-playbook -i ansible/inventories/hosts ansible/setup-new-machine.yml

echo "Setup complete!"

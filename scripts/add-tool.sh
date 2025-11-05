#!/bin/bash

# Add Tool Script - Quickly scaffold a new tool for dotfiles
# Usage: ./scripts/add-tool.sh <tool-name>

set -e

# Auto-detect dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# Check arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <tool-name>"
    echo "Example: $0 direnv"
    exit 1
fi

TOOL_NAME=$1

print_info "Adding tool: $TOOL_NAME"
echo ""

# 1. Create Ansible role
ROLE_DIR="$DOTFILES_DIR/ansible/roles/$TOOL_NAME"
if [ -d "$ROLE_DIR" ]; then
    print_warning "Ansible role already exists: $ROLE_DIR"
else
    mkdir -p "$ROLE_DIR/tasks"

    cat > "$ROLE_DIR/tasks/main.yml" <<EOF
---
# Install $TOOL_NAME

- name: Install $TOOL_NAME (macOS)
  homebrew:
    name: $TOOL_NAME
    state: present
  when: ansible_os_family == "Darwin"
  tags: [$TOOL_NAME]

- name: Install $TOOL_NAME (Debian/Ubuntu)
  apt:
    name: $TOOL_NAME
    state: present
  when: ansible_os_family == "Debian"
  become: yes
  tags: [$TOOL_NAME]

- name: Install $TOOL_NAME (Arch)
  pacman:
    name: $TOOL_NAME
    state: present
  when: ansible_os_family == "Archlinux"
  become: yes
  tags: [$TOOL_NAME]

- name: Install $TOOL_NAME (Fedora/RHEL)
  dnf:
    name: $TOOL_NAME
    state: present
  when: ansible_os_family == "RedHat"
  become: yes
  tags: [$TOOL_NAME]
EOF

    print_success "Created Ansible role: $ROLE_DIR"
fi

# 2. Add to playbook
PLAYBOOK="$DOTFILES_DIR/ansible/setup-new-machine.yml"
if grep -q "- $TOOL_NAME" "$PLAYBOOK"; then
    print_warning "Tool already in playbook"
else
    # Add before tmux (last line)
    sed -i "/- tmux/i\\    - $TOOL_NAME" "$PLAYBOOK"
    print_success "Added $TOOL_NAME to playbook"
fi

# 3. Ask about config files
echo ""
read -p "Does $TOOL_NAME need config files in stow/? (y/n) " needs_config

if [[ $needs_config =~ ^[Yy]$ ]]; then
    STOW_DIR="$DOTFILES_DIR/stow/$TOOL_NAME"
    mkdir -p "$STOW_DIR"

    echo ""
    print_info "Where should configs go?"
    echo "  1. Home directory (~/.${TOOL_NAME}rc)"
    echo "  2. .config directory (~/.config/$TOOL_NAME/)"
    read -p "Choice (1/2): " config_choice

    case $config_choice in
        1)
            touch "$STOW_DIR/.${TOOL_NAME}rc"
            print_success "Created: $STOW_DIR/.${TOOL_NAME}rc"
            ;;
        2)
            mkdir -p "$STOW_DIR/.config/$TOOL_NAME"
            touch "$STOW_DIR/.config/$TOOL_NAME/config"
            print_success "Created: $STOW_DIR/.config/$TOOL_NAME/config"
            ;;
    esac

    print_info "Edit config files in: $STOW_DIR"
fi

# 4. Ask about zsh integration
echo ""
read -p "Add zsh integration module? (y/n) " needs_zsh

if [[ $needs_zsh =~ ^[Yy]$ ]]; then
    # Find next number
    NEXT_NUM=$(ls "$DOTFILES_DIR/stow/zsh/.zsh/" | grep -E '^[0-9]{2}-' | tail -1 | cut -d- -f1)
    NEXT_NUM=$((10#$NEXT_NUM + 1))

    ZSH_MODULE="$DOTFILES_DIR/stow/zsh/.zsh/$(printf "%02d" $NEXT_NUM)-${TOOL_NAME}.zsh"

    cat > "$ZSH_MODULE" <<EOF
# $TOOL_NAME integration

if command -v $TOOL_NAME &>/dev/null; then
    # Add your aliases, functions, or initialization here
    # eval "\$($TOOL_NAME init zsh)"  # If tool has shell integration
fi
EOF

    print_success "Created zsh module: $ZSH_MODULE"
    print_info "Edit to add aliases, functions, or initialization"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "Tool $TOOL_NAME added successfully!"
echo ""
print_info "Next steps:"
echo "  1. Edit Ansible role: $ROLE_DIR/tasks/main.yml"
[ -d "$STOW_DIR" ] && echo "  2. Add configs: $STOW_DIR"
[ -f "$ZSH_MODULE" ] && echo "  3. Configure zsh: $ZSH_MODULE"
echo "  4. Install: make install (or ansible-playbook ansible/setup-new-machine.yml)"
[ -d "$STOW_DIR" ] && echo "  5. Stow configs: make stow"
echo ""

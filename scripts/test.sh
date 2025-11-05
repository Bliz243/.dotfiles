#!/bin/bash

# Test Script - Validates syntax and configuration before deployment
# Usage: ./scripts/test.sh

set -e

DOTFILES_DIR="$HOME/.dotfiles"
STOW_DIR="$DOTFILES_DIR/stow"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ERRORS=0
TESTS=0

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS++))
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
    ((TESTS++))
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_header "🧪 Running Dotfiles Tests"

# Test 1: Shell script syntax
print_info "Testing shell script syntax..."

shell_scripts=$(find "$DOTFILES_DIR" -name "*.sh" -type f)
for script in $shell_scripts; do
    if bash -n "$script" 2>/dev/null; then
        print_success "$(basename $script) syntax is valid"
    else
        print_error "$(basename $script) has syntax errors"
    fi
done

# Test 2: Zsh configuration syntax
print_info "Testing zsh configuration..."

if [ -f "$STOW_DIR/zsh/.zshrc" ]; then
    if zsh -n "$STOW_DIR/zsh/.zshrc" 2>/dev/null; then
        print_success ".zshrc syntax is valid"
    else
        print_error ".zshrc has syntax errors"
    fi
fi

# Test modular zsh configs
if [ -d "$STOW_DIR/zsh/.zsh" ]; then
    for config in "$STOW_DIR/zsh/.zsh"/*.zsh; do
        if [ -f "$config" ]; then
            if zsh -n "$config" 2>/dev/null; then
                print_success "$(basename $config) syntax is valid"
            else
                print_error "$(basename $config) has syntax errors"
            fi
        fi
    done
fi

# Test 3: Neovim configuration
print_info "Testing Neovim configuration..."

if [ -f "$STOW_DIR/nvim/.config/nvim/init.vim" ]; then
    if command -v nvim &> /dev/null; then
        if nvim --headless -c "source $STOW_DIR/nvim/.config/nvim/init.vim" -c "quit" 2>/dev/null; then
            print_success "init.vim loads without errors"
        else
            print_warning "init.vim may have issues (check plugins)"
        fi
    else
        print_warning "Neovim not installed, skipping vim config test"
    fi
else
    print_error "init.vim not found"
fi

# Test 4: Git configuration
print_info "Testing Git configuration..."

if [ -f "$STOW_DIR/git/.gitconfig" ]; then
    if git config -f "$STOW_DIR/git/.gitconfig" --list &>/dev/null; then
        print_success ".gitconfig is valid"
    else
        print_error ".gitconfig has syntax errors"
    fi
else
    print_error ".gitconfig not found"
fi

# Test 5: Tmux configuration
print_info "Testing tmux configuration..."

if [ -f "$STOW_DIR/tmux/.tmux.conf" ]; then
    if command -v tmux &> /dev/null; then
        # Tmux doesn't have a built-in syntax checker, so we just check if file exists
        print_success ".tmux.conf exists and is readable"
    else
        print_warning "Tmux not installed, skipping tmux config test"
    fi
else
    print_error ".tmux.conf not found"
fi

# Test 6: Stow packages structure
print_info "Validating stow package structure..."

if [ -d "$STOW_DIR" ]; then
    packages=$(ls -1d "$STOW_DIR"/*/ 2>/dev/null)
    if [ -n "$packages" ]; then
        for package in $packages; do
            package_name=$(basename "$package")
            print_success "Package '$package_name' found"
        done
    else
        print_error "No stow packages found"
    fi
else
    print_error "Stow directory not found"
fi

# Test 7: Check for common issues
print_info "Checking for common issues..."

# Check for large files
large_files=$(find "$DOTFILES_DIR" -type f -size +1M 2>/dev/null)
if [ -n "$large_files" ]; then
    print_warning "Found large files (>1MB) in repository:"
    echo "$large_files"
else
    print_success "No large files found"
fi

# Check for potential secrets
secret_patterns=("password" "api_key" "secret" "token" "sk-")
for pattern in "${secret_patterns[@]}"; do
    results=$(grep -r -i "$pattern" "$DOTFILES_DIR" --exclude-dir=.git --exclude="*.md" --exclude="test.sh" --exclude="health-check.sh" 2>/dev/null || true)
    if [ -n "$results" ]; then
        print_warning "Found potential secret pattern '$pattern' in files"
    fi
done

# Test 8: Ansible syntax
print_info "Testing Ansible playbooks..."

if [ -d "$DOTFILES_DIR/ansible" ]; then
    if command -v ansible-playbook &> /dev/null; then
        playbooks=$(find "$DOTFILES_DIR/ansible" -name "*.yml" -o -name "*.yaml")
        for playbook in $playbooks; do
            if ansible-playbook --syntax-check "$playbook" &>/dev/null; then
                print_success "$(basename $playbook) syntax is valid"
            else
                print_error "$(basename $playbook) has syntax errors"
            fi
        done
    else
        print_warning "Ansible not installed, skipping playbook tests"
    fi
fi

# Summary
print_header "📊 Test Summary"

echo ""
echo -e "Total tests: ${BLUE}$TESTS${NC}"
echo -e "Passed: ${GREEN}$((TESTS - ERRORS))${NC}"
echo -e "Failed: ${RED}$ERRORS${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    print_success "All tests passed! ✨"
    exit 0
else
    print_error "Some tests failed. Please fix the errors above before deploying."
    exit 1
fi

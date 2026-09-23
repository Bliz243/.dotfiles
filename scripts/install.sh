#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Dotfiles Installation Script
# ─────────────────────────────────────────────
# Usage:
#   ./scripts/install.sh           # Interactive - asks local or remote
#   ./scripts/install.sh --local   # Local machine (WSL/Desktop) - Ctrl+A prefix
#   ./scripts/install.sh --remote  # Remote server (VPS) - Ctrl+B prefix
# ─────────────────────────────────────────────

# Repo root, shared helpers (ui, stow/symlinks), package installers, agent tooling
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$DOTFILES_DIR/scripts/lib/ui.sh"
source "$DOTFILES_DIR/scripts/lib/links.sh"
source "$DOTFILES_DIR/scripts/lib/packages.sh"
source "$DOTFILES_DIR/scripts/lib/agents.sh"

# ─────────────────────────────────────────────
# Parse arguments
# ─────────────────────────────────────────────
MACHINE_TYPE=""
# CI/non-interactive: skips optional + interactive steps (claude/workmux/github/chsh)
# so the installer itself can be exercised in the Docker test. Default off.
CI="${CI:-0}"

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --local)
        MACHINE_TYPE="local"
        shift
        ;;
      --remote|--vps|--server)
        MACHINE_TYPE="remote"
        shift
        ;;
      --ci|--non-interactive)
        CI=1
        shift
        ;;
      --help|-h)
        echo "Usage: ./scripts/install.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --local     Configure for local machine (WSL/Desktop)"
        echo "              Uses Ctrl+A prefix, always auto-attach tmux"
        echo ""
        echo "  --remote    Configure for remote server (VPS)"
        echo "              Uses Ctrl+B prefix, auto-attach only in SSH sessions"
        echo ""
        echo "  --ci        Non-interactive: install core only, skip optional/"
        echo "              interactive steps (Claude/workmux/GitHub/chsh). Used by tests."
        echo ""
        echo "  --help      Show this help message"
        echo ""
        echo "If no option is provided, the script will ask interactively."
        exit 0
        ;;
      *)
        warn "Unknown option: $1"
        shift
        ;;
    esac
  done
}

detect_machine_type() {
  if [[ -n "$MACHINE_TYPE" ]]; then
    return
  fi

  echo ""
  echo -e "${BLUE}What type of machine is this?${NC}"
  echo ""
  echo "  1) Local machine (WSL, Desktop, Laptop)"
  echo "     - Tmux prefix: Ctrl+A"
  echo "     - Auto-attach: Always"
  echo ""
  echo "  2) Remote server (VPS, Cloud, SSH-only)"
  echo "     - Tmux prefix: Ctrl+B"
  echo "     - Auto-attach: Only in SSH sessions"
  echo ""
  read -p "Select [1/2]: " -n 1 -r
  echo ""

  case "$REPLY" in
    1) MACHINE_TYPE="local" ;;
    2) MACHINE_TYPE="remote" ;;
    *) MACHINE_TYPE="local"; warn "Invalid selection, defaulting to local" ;;
  esac
}

echo "========================================"
echo "  Dotfiles Installation"
echo "========================================"
echo ""

# ─────────────────────────────────────────────
# Detect OS
# ─────────────────────────────────────────────
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
  elif [[ -f /etc/os-release ]]; then
    OS="linux"
    . /etc/os-release
    DISTRO="$ID"
  else
    error "Unsupported operating system"
  fi
  info "Detected OS: $OS${DISTRO:+ ($DISTRO)}"
}

# ─────────────────────────────────────────────
# Post-install setup
# ─────────────────────────────────────────────
post_install() {
  info "Running post-install setup..."

  # Set zsh as default shell (skipped in CI — chsh prompts for a password)
  if [[ "$CI" != "1" && "$SHELL" != */zsh ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)" || warn "Could not change shell. Run: chsh -s \$(which zsh)"
  fi

  # Install tmux plugin manager and plugins
  if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    info "Installing tmux plugin manager..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi
  info "Installing tmux plugins..."
  ~/.tmux/plugins/tpm/bin/install_plugins || warn "Tmux plugin install had issues - press C-a + I in tmux"

  # Machine-specific shell config: created once, never overwritten (it holds this
  # machine's own settings, e.g. TMUX_SESSION)
  if [[ -f ~/.zshrc.local ]]; then
    local configured
    configured="$(sed -n 's/^export MACHINE_TYPE="\([a-z]*\)"/\1/p' ~/.zshrc.local)"
    if [[ -n "$configured" && "$configured" != "$MACHINE_TYPE" ]]; then
      # shellcheck disable=SC2088  # literal ~ for display
      warn "~/.zshrc.local is set up for a $configured machine; left unchanged. Delete it and re-run to switch to $MACHINE_TYPE."
    else
      info "Keeping existing ~/.zshrc.local"
    fi
  elif [[ "$MACHINE_TYPE" == "remote" ]]; then
    cat > ~/.zshrc.local << 'EOF'
# Remote server configuration (VPS)
# Uses Ctrl+B to avoid conflicts when SSH-ing from local machine

export MACHINE_TYPE="remote"
export TMUX_PREFIX="C-b"
TMUX_AUTO_ATTACH="ssh-only"
EOF
    info "Created ~/.zshrc.local with remote settings (Ctrl+B prefix)"
  else
    cat > ~/.zshrc.local << 'EOF'
# Local machine configuration (WSL/Desktop)
# Uses Ctrl+A as tmux prefix

export MACHINE_TYPE="local"
export TMUX_PREFIX="C-a"
TMUX_AUTO_ATTACH="true"
EOF
    info "Created ~/.zshrc.local with local settings (Ctrl+A prefix)"
  fi

  # Sync Neovim plugins (Lazy! runs synchronously and exits when done)
  info "Syncing Neovim plugins (this may take a few minutes)..."
  nvim --headless "+Lazy! sync" +qa || warn "Neovim plugin sync had issues - run :Lazy sync manually"

  # Pre-push check that keeps secrets and private data out of this public repo
  enable_repo_hooks

  # Claude Code configuration (symlinks for global config)
  setup_claude_config

  # Optional Claude Code installation
  setup_claude_code

  # Optional Codex CLI installation
  setup_codex_cli

  # Codex CLI configuration (symlinks for global config + skills)
  setup_codex_config

  # Third-party agent skills (installed, never vendored into this public repo)
  setup_agent_skills

  # Optional workmux installation
  setup_workmux

  # Optional GitHub/SSH setup
  setup_github
}

# ─────────────────────────────────────────────
# GitHub/SSH Setup (Interactive)
# ─────────────────────────────────────────────
setup_github() {
  [[ "$CI" == "1" ]] && { info "CI: skipping GitHub setup"; return; }

  # Skip if gh not installed
  if ! command -v gh &>/dev/null; then
    warn "GitHub CLI not installed, skipping GitHub setup"
    return
  fi

  # Ask if user wants to set up GitHub
  echo ""
  echo -e "${BLUE}Would you like to set up GitHub authentication?${NC}"
  echo "This will configure git identity, SSH keys, and GitHub auth."
  echo ""
  read -p "Set up GitHub now? [y/N]: " -n 1 -r
  echo ""

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Skipping. Run later with: ~/.dotfiles/scripts/setup-github.sh"
    return
  fi

  # Single source of truth: delegate to the standalone GitHub/SSH setup script.
  bash "$DOTFILES_DIR/scripts/setup-github.sh"
}


# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
main() {
  parse_args "$@"
  detect_machine_type
  detect_os

  case "$OS" in
    macos) install_macos ;;
    linux) install_linux ;;
  esac

  stow_dotfiles
  post_install

  echo ""
  echo "========================================"
  echo -e "  ${GREEN}Installation complete!${NC}"
  echo "========================================"
  echo ""

  # Show configuration summary
  if [[ "$MACHINE_TYPE" == "remote" ]]; then
    echo -e "Configured as: ${BLUE}Remote server${NC}"
    echo "  - Tmux prefix: Ctrl+B"
    echo "  - Auto-attach: SSH sessions only"
  else
    echo -e "Configured as: ${BLUE}Local machine${NC}"
    echo "  - Tmux prefix: Ctrl+A"
    echo "  - Auto-attach: Always"
  fi

  echo ""
  echo "Next step: restart your terminal or run: exec zsh"
  echo ""
}

main "$@"

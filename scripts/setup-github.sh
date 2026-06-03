#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# GitHub/SSH Setup Script
# ─────────────────────────────────────────────
# Sets up Git identity, SSH keys, and GitHub authentication.
# Can be run standalone or called from install.sh.
# ─────────────────────────────────────────────

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Track if we're on a remote machine
IS_REMOTE="${SSH_CONNECTION:+true}"

echo "========================================"
echo "  GitHub & SSH Setup"
echo "========================================"
echo ""

# ─────────────────────────────────────────────
# Prerequisites
# ─────────────────────────────────────────────
check_prerequisites() {
  if ! command -v gh &>/dev/null; then
    error "GitHub CLI (gh) not installed.

Install it first:
  macOS:  brew install gh
  Ubuntu: See https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
  fi

  if ! command -v git &>/dev/null; then
    error "Git not installed."
  fi
}

# ─────────────────────────────────────────────
# Step 1: Git Identity
# ─────────────────────────────────────────────
setup_git_identity() {
  local GIT_LOCAL="$HOME/.gitconfig.local"

  echo -e "${BLUE}Step 1: Git Identity${NC}"
  echo ""

  # Check existing config
  if [[ -f "$GIT_LOCAL" ]] && grep -q "name = " "$GIT_LOCAL" 2>/dev/null; then
    info "Current identity:"
    grep -E "name|email" "$GIT_LOCAL" | sed 's/^/  /'
    echo ""
    read -p "Keep this identity? [Y/n]: " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Nn]$ ]] && return 0
  fi

  # Get name
  local CURRENT_NAME=$(git config user.name 2>/dev/null || echo "")
  read -p "Your name${CURRENT_NAME:+ [$CURRENT_NAME]}: " GIT_NAME
  GIT_NAME="${GIT_NAME:-$CURRENT_NAME}"

  # Get email with privacy tip
  local CURRENT_EMAIL=$(git config user.email 2>/dev/null || echo "")
  echo ""
  echo "Tip: Use GitHub's noreply email for privacy:"
  echo -e "  ${BLUE}<username>@users.noreply.github.com${NC}"
  echo ""
  read -p "Your email${CURRENT_EMAIL:+ [$CURRENT_EMAIL]}: " GIT_EMAIL
  GIT_EMAIL="${GIT_EMAIL:-$CURRENT_EMAIL}"

  if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
    error "Name and email are required"
  fi

  # Save to gitconfig.local
  cat > "$GIT_LOCAL" << EOF
[user]
	name = $GIT_NAME
	email = $GIT_EMAIL
EOF

  # Export for use in SSH key generation
  export GIT_USER_EMAIL="$GIT_EMAIL"

  info "Saved to $GIT_LOCAL"
  echo ""
}

# ─────────────────────────────────────────────
# Step 2: SSH Key
# ─────────────────────────────────────────────
setup_ssh_key() {
  local SSH_DIR="$HOME/.ssh"
  local SSH_KEY="$SSH_DIR/id_ed25519"

  echo -e "${BLUE}Step 2: SSH Key${NC}"
  echo ""

  # Create .ssh directory with correct permissions
  if [[ ! -d "$SSH_DIR" ]]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
  fi

  # Check for existing key
  if [[ -f "$SSH_KEY" ]]; then
    info "SSH key exists: $SSH_KEY"
    echo "  Fingerprint: $(ssh-keygen -lf "$SSH_KEY" 2>/dev/null | awk '{print $2}')"
    echo ""
    return 0
  fi

  # Generate new key
  info "Generating SSH key..."
  local EMAIL="${GIT_USER_EMAIL:-$(git config user.email 2>/dev/null)}"
  EMAIL="${EMAIL:-user@$(hostname)}"

  ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""

  info "SSH key generated"
  echo ""
}

# ─────────────────────────────────────────────
# Step 3: SSH Config
# ─────────────────────────────────────────────
setup_ssh_config() {
  local SSH_CONFIG="$HOME/.ssh/config"

  echo -e "${BLUE}Step 3: SSH Config${NC}"
  echo ""

  # Check if GitHub config already exists
  if [[ -f "$SSH_CONFIG" ]] && grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    info "GitHub SSH config already exists"
    echo ""
    return 0
  fi

  # Add GitHub-specific SSH config
  info "Adding GitHub SSH configuration..."

  cat >> "$SSH_CONFIG" << 'EOF'

# GitHub
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  IdentitiesOnly yes
EOF

  chmod 600 "$SSH_CONFIG"
  info "SSH config updated"
  echo ""
}

# ─────────────────────────────────────────────
# Step 4: GitHub Authentication
# ─────────────────────────────────────────────
setup_gh_auth() {
  echo -e "${BLUE}Step 4: GitHub Authentication${NC}"
  echo ""

  # Check if already authenticated
  if gh auth status &>/dev/null; then
    info "Already authenticated with GitHub"
    gh auth status 2>&1 | grep -E "Logged in|Token" | head -2 | sed 's/^/  /'
    echo ""

    # Ensure git is configured to use gh
    gh auth setup-git 2>/dev/null || true

    # Still need to check if SSH key is uploaded (handled in next step)
    return 0
  fi

  # Show instructions based on environment
  echo "─────────────────────────────────────────────"
  if [[ -n "$IS_REMOTE" ]]; then
    echo -e "${YELLOW}Remote machine detected${NC}"
    echo ""
    echo "  1. A one-time code will be shown"
    echo "  2. On any device, visit:"
    echo ""
    echo -e "     ${BLUE}https://github.com/login/device${NC}"
    echo ""
    echo "  3. Enter the code to authenticate"
    echo "  4. When asked about SSH key, choose to upload it"
  else
    echo "A browser will open for authentication."
    echo "If it doesn't, copy the URL shown."
    echo "When asked about SSH key, choose to upload it."
  fi
  echo "─────────────────────────────────────────────"
  echo ""

  # Authenticate with SSH protocol
  # gh will find our SSH key and offer to upload it
  gh auth login -h github.com -p ssh

  # Configure git to use gh for HTTPS (fallback)
  gh auth setup-git

  info "GitHub authentication complete"
  echo ""
}

# ─────────────────────────────────────────────
# Step 5: Verify SSH Connection (and fix if needed)
# ─────────────────────────────────────────────
verify_ssh() {
  echo -e "${BLUE}Step 5: Verify SSH Connection${NC}"
  echo ""

  info "Testing SSH connection to GitHub..."

  # ssh -T returns exit code 1 even on success, so check output
  local OUTPUT
  OUTPUT=$(ssh -T git@github.com 2>&1) || true

  if echo "$OUTPUT" | grep -q "successfully authenticated\|Hi "; then
    info "SSH connection working!"
    echo "$OUTPUT" | grep "Hi " | sed 's/^/  /'
    echo ""
    return 0
  fi

  # SSH failed - try to fix it
  warn "SSH connection failed: $OUTPUT"
  echo ""

  # Check if key exists
  if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
    error "No SSH key found. Run setup again."
    return 1
  fi

  # Try to add the key to GitHub
  info "Attempting to add SSH key to GitHub..."
  echo ""

  # Need admin:public_key scope
  echo "Refreshing GitHub auth to add SSH key permissions..."
  gh auth refresh -h github.com -s admin:public_key || {
    warn "Could not refresh auth. Add key manually at https://github.com/settings/keys"
    echo ""
    echo "Your public key:"
    cat ~/.ssh/id_ed25519.pub
    return 1
  }

  # Add the key
  local KEY_TITLE="$(hostname)-$(date +%Y%m%d)"
  gh ssh-key add ~/.ssh/id_ed25519.pub --title "$KEY_TITLE" || {
    warn "Could not add key. It may already exist on GitHub."
  }

  # Test again
  echo ""
  info "Testing SSH connection again..."
  OUTPUT=$(ssh -T git@github.com 2>&1) || true

  if echo "$OUTPUT" | grep -q "successfully authenticated\|Hi "; then
    info "SSH connection working!"
    echo "$OUTPUT" | grep "Hi " | sed 's/^/  /'
  else
    warn "SSH still not working. Check https://github.com/settings/keys"
  fi
  echo ""
}

# ─────────────────────────────────────────────
# Step 6: Switch Remote to SSH
# ─────────────────────────────────────────────
switch_to_ssh_remote() {
  local DOTFILES_DIR="$HOME/.dotfiles"

  echo -e "${BLUE}Step 6: Configure Git Remote${NC}"
  echo ""

  # Check if we're in a git repo
  if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    info "No dotfiles repo found, skipping remote config"
    return 0
  fi

  cd "$DOTFILES_DIR"
  local CURRENT=$(git remote get-url origin 2>/dev/null || echo "")

  if [[ -z "$CURRENT" ]]; then
    info "No origin remote configured"
    return 0
  fi

  # Already SSH
  if [[ "$CURRENT" == git@* ]]; then
    info "Already using SSH: $CURRENT"
    echo ""
    return 0
  fi

  # Convert HTTPS to SSH
  if [[ "$CURRENT" == https://github.com/* ]]; then
    local SSH_URL=$(echo "$CURRENT" | sed 's|https://github.com/|git@github.com:|')

    echo "  Current: $CURRENT"
    echo "  SSH:     $SSH_URL"
    echo ""
    read -p "Switch to SSH? [Y/n]: " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      git remote set-url origin "$SSH_URL"
      info "Remote updated to SSH"
    fi
  fi
  echo ""
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
main() {
  check_prerequisites

  setup_git_identity
  setup_ssh_key
  setup_ssh_config
  setup_gh_auth
  verify_ssh
  switch_to_ssh_remote

  echo "========================================"
  echo -e "  ${GREEN}Setup complete!${NC}"
  echo "========================================"
  echo ""
  echo "You can now:"
  echo "  • Clone: git clone git@github.com:user/repo.git"
  echo "  • Push/pull without entering passwords"
  echo ""
}

main "$@"

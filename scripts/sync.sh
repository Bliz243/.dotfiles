#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Dotfiles sync — idempotent "apply my changes" command.
# ─────────────────────────────────────────────
# Run after pulling/editing dotfiles to apply only what changed:
#   ./scripts/sync.sh           # restow + relink + plugin sync
#   ./scripts/sync.sh --pull    # git pull --ff-only first
#
# Pure config edits are already live via stow symlinks — this is for new files,
# new skills, or new plugins. It does NOT install system packages (run install.sh
# for those); it never needs sudo.
# ─────────────────────────────────────────────

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$DOTFILES_DIR/scripts/lib/ui.sh"
source "$DOTFILES_DIR/scripts/lib/links.sh"

if [[ "${1:-}" == "--pull" ]]; then
  info "Pulling latest dotfiles..."
  git -C "$DOTFILES_DIR" pull --ff-only || error "git pull failed (resolve manually, then re-run)"
fi

stow_dotfiles
relink_claude_config
relink_codex_config

# Sync editor/multiplexer plugins (both idempotent, no-op if nothing changed)
if command -v nvim &>/dev/null; then
  info "Syncing Neovim plugins..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Neovim plugin sync had issues — run :Lazy sync manually"
fi
if [[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]]; then
  info "Syncing tmux plugins..."
  "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null || warn "tmux plugin sync had issues — press prefix + I in tmux"
fi

info "Sync complete. (New system packages? Run scripts/install.sh.)"

# ~/.zshrc - Main zsh configuration
# Loads modular configs from ~/.zsh/

# ─────────────────────────────────────────────
# Essential Environment
# ─────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
export VISUAL="$EDITOR"

# Disable terminal XOFF/XON flow control so Ctrl-S / Ctrl-Q reach nvim/tmux
[[ $- == *i* ]] && stty -ixon 2>/dev/null

# XDG Base Directories (used by many tools)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Load machine-specific config FIRST (sets TMUX_PREFIX, etc.)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Load all zsh config files in order
for file in ~/.zsh/*.zsh(N); do
  source "$file"
done

# Node is installed system-wide (NodeSource LTS) for editor/LSP tooling; project JS
# uses bun (below). No nvm — install.sh provisions both.

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# zoxide (smarter cd) — initialized LAST so its shell hooks stay after the tmux
# precmd/preexec hooks and PATH setup (avoids the _ZO_DOCTOR ordering warning).
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
  # Wrapper: fall back to builtin cd when zoxide internals aren't available
  # (Claude Code's shell snapshots capture cd but not __zoxide_z)
  cd() {
    if (( $+functions[__zoxide_z] )); then
      __zoxide_z "$@"
    else
      builtin cd "$@"
    fi
  }
fi

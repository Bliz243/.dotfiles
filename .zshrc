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

# Agent shells (Claude Code, Codex) snapshot this config for their commands, which
# assume standard ls/cat/cd behavior: interactive replacements check this flag.
[[ -n "${CLAUDECODE:-}${CODEX_THREAD_ID:-}${AI_AGENT:-}" ]] && _agent_shell=1

# Load all zsh config files in order
for file in ~/.zsh/*.zsh(N); do
  source "$file"
done

# Node is installed system-wide (NodeSource, pinned major in install.sh) for editor/LSP
# tooling and Vite/SvelteKit subprocesses; project JS uses bun (below). No nvm — a
# shell-function version manager isn't visible to Mason's non-interactive npm spawns.

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# zoxide (smarter cd) — initialized LAST so its shell hooks stay after the tmux
# precmd/preexec hooks and PATH setup (avoids the _ZO_DOCTOR ordering warning).
if [[ -z "${_agent_shell:-}" ]] && command -v zoxide &>/dev/null; then
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

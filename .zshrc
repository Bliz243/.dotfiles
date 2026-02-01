# ~/.zshrc - Main zsh configuration
# Loads modular configs from ~/.zsh/

# ─────────────────────────────────────────────
# Essential Environment
# ─────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
export VISUAL="$EDITOR"

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

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

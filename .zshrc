# ~/.zshrc - Main zsh configuration
# Loads modular configs from ~/.zsh/

# Set PATH early so plugins can find tools
export PATH="$HOME/.local/bin:$PATH"

# Load machine-specific config FIRST (sets TMUX_PREFIX, etc.)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Load all zsh config files in order
for file in ~/.zsh/*.zsh(N); do
  source "$file"
done

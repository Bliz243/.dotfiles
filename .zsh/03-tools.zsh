# ============================================================================
# Oh My Zsh Configuration
# ============================================================================

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="gozilla"

# Plugins
# Note: zsh-autosuggestions needs to be installed: see ansible/roles/zsh/tasks/main.yml
plugins=(
  git
  github
  brew
  zsh-autosuggestions
  kubectl
  docker
  sudo
  colored-man-pages
  command-not-found
  extract
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh
# ============================================================================
# Modern CLI Tools Setup (with fallbacks)
# ============================================================================

# eza (modern replacement for ls)
if command -v eza &> /dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza --icons --group-directories-first -l"
  alias la="eza --icons --group-directories-first -la"
  alias lt="eza --icons --tree --level=2"
  alias l="eza --icons --group-directories-first -lah"
elif command -v exa &> /dev/null; then
  alias ls="exa --icons --group-directories-first"
  alias ll="exa --icons --group-directories-first -l"
  alias la="exa --icons --group-directories-first -la"
  alias lt="exa --icons --tree --level=2"
  alias l="exa --icons --group-directories-first -lah"
else
  alias ls="ls --color=auto"
  alias ll="ls -lh"
  alias la="ls -lAh"
  alias l="ls -lah"
fi

# bat (better cat)
if command -v bat &> /dev/null; then
  alias cat="bat --style=auto"
  alias bcat="/bin/cat"  # Original cat if needed
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
elif command -v batcat &> /dev/null; then
  # Ubuntu/Debian uses 'batcat' instead of 'bat'
  alias bat="batcat"
  alias cat="batcat --style=auto"
  alias bcat="/bin/cat"
fi

# fd (better find)
if command -v fd &> /dev/null; then
  alias find="fd"
fi

# ripgrep (better grep)
if command -v rg &> /dev/null; then
  alias grep="rg"
  alias bgrep="/bin/grep"  # Original grep if needed
else
  alias grep="grep --color=auto"
fi

# zoxide (smart cd)
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
  # Use 'z' for zoxide, keep 'cd' as regular cd
  alias j="z"  # Jump to directory
  alias ji="zi"  # Interactive directory jump
fi

# fzf (fuzzy finder)
if command -v fzf &> /dev/null; then
  # Setup fzf key bindings and fuzzy completion
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

  # Use fd with fzf if available
  if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi

  # Better fzf styling
  export FZF_DEFAULT_OPTS="
    --height 40%
    --layout=reverse
    --border
    --inline-info
    --color=fg:#d0d0d0,bg:#121212,hl:#5f87af
    --color=fg+:#d0d0d0,bg+:#262626,hl+:#5fd7ff
    --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff
    --color=marker:#87ff00,spinner:#af5fff,header:#87afaf
  "

  # Useful fzf functions
  # cd into directory
  function fcd() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git | fzf --preview 'tree -C {} | head -50') && cd "$dir"
  }

  # Open file in editor
  function fvim() {
    local file
    file=$(fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}') && nvim "$file"
  }

  # Kill process
  function fkill() {
    local pid
    pid=$(ps aux | sed 1d | fzf -m | awk '{print $2}')
    [ -n "$pid" ] && echo "$pid" | xargs kill -${1:-9}
  }
fi
# ============================================================================
# Auto-attach to tmux (conditional)
# ============================================================================

# Only auto-attach tmux if:
# - Not already in tmux
# - Not in VSCode integrated terminal
# - Not in SSH with X11 forwarding
# - Terminal is interactive
# - TMUX_AUTO_ATTACH is not set to "false"
if [[ -z "$TMUX" ]] && \
   [[ -z "$VSCODE_INJECTION" ]] && \
   [[ -z "$TERM_PROGRAM" ]] && \
   [[ "$TMUX_AUTO_ATTACH" != "false" ]] && \
   [[ $- == *i* ]] && \
   command -v tmux &> /dev/null; then

  # Try to attach to 'default' session, create if it doesn't exist
  tmux attach -t default 2>/dev/null || tmux new -s default
fi

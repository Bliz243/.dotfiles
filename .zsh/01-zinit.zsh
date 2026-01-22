# Zinit bootstrap and plugin configuration

# ─────────────────────────────────────────────
# Tmux Auto-attach
# ─────────────────────────────────────────────
# Auto-attach for all interactive terminals:
# - Not already in tmux
# - Not in VS Code, JetBrains, or other IDEs
# - Set TMUX_AUTO_ATTACH=false in 99-local.zsh to disable
if [[ $- == *i* ]] && \
   [[ -z "$TMUX" ]] && \
   [[ -z "$VSCODE_RESOLVING_ENVIRONMENT" ]] && \
   [[ "$TERM_PROGRAM" != "vscode" ]] && \
   [[ -z "$INTELLIJ_ENVIRONMENT_READER" ]] && \
   [[ "$TMUX_AUTO_ATTACH" != "false" ]]; then
  tmux attach -t default 2>/dev/null || tmux new -s default
fi

# ─────────────────────────────────────────────
# Zinit Installation
# ─────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# ─────────────────────────────────────────────
# Prompt - Context-aware
# ─────────────────────────────────────────────
# In tmux: minimal (context in status bar)
# Outside tmux: show path and git branch

# Git branch function
_git_branch() {
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  [[ -n "$branch" ]] && echo " %F{magenta}${branch}%f"
}

# Smart prompt based on environment
if [[ -n "$TMUX" ]]; then
  # In tmux: minimal
  PROMPT='❯ '
else
  # Outside tmux: show context
  setopt PROMPT_SUBST
  PROMPT='%F{blue}%~%f$(_git_branch) ❯ '
fi
RPROMPT=''

# ─────────────────────────────────────────────
# Essential Plugins
# ─────────────────────────────────────────────

# Syntax highlighting (must be loaded before autosuggestions)
zinit light zsh-users/zsh-syntax-highlighting

# Fish-like autosuggestions
zinit light zsh-users/zsh-autosuggestions

# Additional completions
zinit light zsh-users/zsh-completions

# fzf-powered tab completion
zinit light Aloxaf/fzf-tab

# ─────────────────────────────────────────────
# Completion System
# ─────────────────────────────────────────────
autoload -Uz compinit
compinit
zinit cdreplay -q

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# ─────────────────────────────────────────────
# Shell Options
# ─────────────────────────────────────────────
setopt AUTO_CD              # cd by typing directory name
setopt AUTO_PUSHD           # Push directories onto stack
setopt PUSHD_IGNORE_DUPS    # Don't push duplicates
setopt HIST_IGNORE_ALL_DUPS # Remove older duplicate entries
setopt HIST_REDUCE_BLANKS   # Remove superfluous blanks
setopt SHARE_HISTORY        # Share history between sessions
setopt EXTENDED_HISTORY     # Add timestamps to history

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# ─────────────────────────────────────────────
# Key Bindings
# ─────────────────────────────────────────────
bindkey -e  # Emacs-style keybindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Aliases and shell functions

# ─────────────────────────────────────────────
# Modern CLI Replacements (with fallbacks)
# ─────────────────────────────────────────────

# eza (ls replacement)
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -la --icons --group-directories-first'
  alias la='eza -a --icons --group-directories-first'
  alias lt='eza --tree --icons --level=2'
  alias tree='eza --tree --icons'
else
  alias ls='ls --color=auto'
  alias ll='ls -la'
  alias la='ls -a'
fi

# bat (cat replacement)
if command -v bat &>/dev/null; then
  alias cat='bat --style=auto'
elif command -v batcat &>/dev/null; then
  alias cat='batcat --style=auto'
  alias bat='batcat'
fi

# fd (find replacement)
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  alias fd='fdfind'
fi

# zoxide (smarter cd)
# Replaces cd with zoxide - works normally for explicit paths,
# adds smart matching for partial directory names
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# fzf - load key bindings and completion
if command -v fzf &>/dev/null; then
  # Linux (apt)
  [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  # macOS Homebrew (Apple Silicon)
  [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  # macOS Homebrew (Intel)
  [[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]] && source /usr/local/opt/fzf/shell/key-bindings.zsh
  # User install
  [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
fi

# ─────────────────────────────────────────────
# Editor
# ─────────────────────────────────────────────
alias v='nvim'
alias vim='nvim'
alias vi='nvim'
alias e='$EDITOR'

# ─────────────────────────────────────────────
# Claude Code
# ─────────────────────────────────────────────
alias ccd='CLAUDE_GUARD=1 claude --dangerously-skip-permissions'

# ─────────────────────────────────────────────
# Git Shortcuts
# ─────────────────────────────────────────────
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gds='git diff --staged'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull'
alias gl='git log --oneline -20'
alias glo='git log --oneline --graph --all'
alias gb='git branch'
alias gco='git checkout'
alias gsw='git switch'
alias gst='git stash'
alias gstp='git stash pop'
alias gcp='git cherry-pick'
alias grb='git rebase'
alias grbi='git rebase -i'

# ─────────────────────────────────────────────
# Docker
# ─────────────────────────────────────────────
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs -f'
alias dprune='docker system prune -af'

# ─────────────────────────────────────────────
# Kubernetes (if available)
# ─────────────────────────────────────────────
if command -v kubectl &>/dev/null; then
  alias k='kubectl'
  alias kgp='kubectl get pods'
  alias kgs='kubectl get services'
  alias kgd='kubectl get deployments'
  alias kctx='kubectl config current-context'
  alias kns='kubectl config set-context --current --namespace'
fi

# ─────────────────────────────────────────────
# Directory Navigation
# ─────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# ─────────────────────────────────────────────
# Common Shortcuts
# ─────────────────────────────────────────────
alias c='clear'
alias h='history'
alias q='exit'
alias reload='source ~/.zshrc'

# Better defaults
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias mkdir='mkdir -pv'
alias wget='wget -c'

# ─────────────────────────────────────────────
# Safety
# ─────────────────────────────────────────────
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# ─────────────────────────────────────────────
# System Info
# ─────────────────────────────────────────────
alias myip='curl -s ifconfig.me'
alias localip="hostname -I 2>/dev/null | awk '{print \$1}' || ipconfig getifaddr en0"
alias ports='netstat -tulanp 2>/dev/null || lsof -i -P'

# ─────────────────────────────────────────────
# Utility Functions
# ─────────────────────────────────────────────

# Create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.tar.xz)  tar xJf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.tbz2)    tar xjf "$1" ;;
      *.tgz)     tar xzf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.Z)       uncompress "$1" ;;
      *.7z)      7z x "$1" ;;
      *.rar)     unrar x "$1" ;;
      *)         echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Quick file backup
backup() {
  cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}
}

# Quick HTTP server in current directory
serve() {
  local port="${1:-8000}"
  python3 -m http.server "$port"
}

# Weather
weather() {
  curl -s "wttr.in/${1:-}"
}

# Cheat sheet
cheat() {
  curl -s "cheat.sh/$1"
}

# Initialize Claude Code in current project
claude-init() {
  local target="${1:-.}/.claude"

  # Check if superpowers marketplace is installed
  if [[ ! -d ~/.claude/plugins/marketplaces/superpowers-marketplace ]]; then
    echo "Warning: superpowers not installed"
    echo "The template uses superpowers:brainstorming and superpowers:debugging skills."
    echo ""
    echo "Install from within Claude Code:"
    echo "  /plugin marketplace add obra/superpowers-marketplace"
    echo "  /plugin install superpowers@superpowers-marketplace"
    echo ""
    read -p "Continue anyway? [y/N]: " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && return 1
  fi

  if [[ -d "$target" ]]; then
    echo "Warning: $target already exists"
    read -p "Overwrite? [y/N]: " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && return 1
    rm -rf "$target"
  fi

  cp -r ~/.dotfiles/.claude-template "$target"
  echo "Initialized .claude in ${1:-.}"
  echo "  - agents/code-review.md"
  echo "  - config/skill-rules.json"
  echo "  - statusline.js"
  echo ""
  echo "Customize config/skill-rules.json for project-specific rules."
}

# ─────────────────────────────────────────────
# Tmux Integration
# ─────────────────────────────────────────────

# Set tmux pane title to current command or directory
if [[ -n "$TMUX" ]]; then
  # Set pane title via escape sequence
  _tmux_set_title() {
    printf '\033]2;%s\033\\' "$1"
  }

  # Before command runs: show the command
  preexec() {
    _tmux_set_title "${1[1,40]}"
  }

  # After command finishes: show current directory
  precmd() {
    local dir="${PWD##*/}"  # Last component of path
    [[ "$PWD" == "$HOME" ]] && dir="~"
    [[ -z "$dir" ]] && dir="/"
    _tmux_set_title "$dir"
  }
fi

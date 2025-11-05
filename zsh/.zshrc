# ============================================================================
# ZSH Configuration
# ============================================================================

# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && . "$HOME/.fig/shell/zshrc.pre.zsh"

# ============================================================================
# Performance Optimization - Start Profiling (optional)
# ============================================================================
# Uncomment to profile zsh startup time:
# zmodload zsh/zprof

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
# Environment Variables
# ============================================================================

export TERM="xterm-256color"
export TERM_FONT="JetBrainsMonoNL Nerd Font"
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"

# Set language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# History configuration
export HISTSIZE=100000
export SAVEHIST=100000
export HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Better directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

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
# Basic Aliases
# ============================================================================

# Editor aliases
alias vim="nvim"
alias vi="nvim"
alias v="nvim"

# Config quick access
alias zshconfig="$EDITOR ~/.zshrc"
alias ohmyzsh="$EDITOR ~/.oh-my-zsh"
alias vimconfig="$EDITOR ~/.config/nvim/init.vim"
alias tmuxconfig="$EDITOR ~/.tmux.conf"

# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"  # Go back to previous directory

# Common shortcuts
alias c="clear"
alias h="history"
alias q="exit"

# Safety aliases
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# Better defaults
alias df="df -h"
alias du="du -h"
alias free="free -h"
alias mkdir="mkdir -pv"
alias wget="wget -c"  # Resume downloads by default

# Git aliases (in addition to oh-my-zsh git plugin)
alias g="git"
alias gs="git status"
alias ga="git add"
alias gaa="git add --all"
alias gc="git commit -m"
alias gca="git commit --amend"
alias gp="git push"
alias gpl="git pull"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gd="git diff"
alias gl="git log --oneline --graph --decorate"
alias gll="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Docker aliases
alias d="docker"
alias dc="docker-compose"
alias dps="docker ps"
alias dpsa="docker ps -a"
alias di="docker images"
alias dex="docker exec -it"
alias dlog="docker logs -f"
alias dprune="docker system prune -af"

# Kubernetes aliases (if kubectl is available)
if command -v kubectl &> /dev/null; then
  alias k="kubectl"
  alias kgp="kubectl get pods"
  alias kgs="kubectl get services"
  alias kgd="kubectl get deployments"
  alias kctx="kubectl config current-context"
  alias kns="kubectl config set-context --current --namespace"
fi

# Python aliases
alias py="python3"
alias python="python3"
alias pip="pip3"
alias venv="python3 -m venv"
alias activate="source venv/bin/activate"

# System info
alias myip="curl -s ifconfig.me"
alias localip="hostname -I | awk '{print \$1}'"
alias ports="netstat -tulanp"

# Disk usage
alias ducks="du -chs * | sort -rh | head -11"  # Top 10 largest directories

# ============================================================================
# Useful Functions
# ============================================================================

# Create directory and cd into it
function mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract any archive
function extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"    ;;
      *.tar.gz)    tar xzf "$1"    ;;
      *.bz2)       bunzip2 "$1"    ;;
      *.rar)       unrar x "$1"    ;;
      *.gz)        gunzip "$1"     ;;
      *.tar)       tar xf "$1"     ;;
      *.tbz2)      tar xjf "$1"    ;;
      *.tgz)       tar xzf "$1"    ;;
      *.zip)       unzip "$1"      ;;
      *.Z)         uncompress "$1" ;;
      *.7z)        7z x "$1"       ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Show colormap
function colormap() {
  for i in {0..255}; do
    print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}
  done
}

# Quick file backup
function backup() {
  cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}
}

# Display current git branch in prompt (if not using starship)
function git_branch() {
  git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Weather
function weather() {
  curl -s "wttr.in/${1:-}"
}

# Cheat sheet
function cheat() {
  curl -s "cheat.sh/$1"
}

# ============================================================================
# Distro Detection for Starship Prompt
# ============================================================================

LFILE="/etc/*-release"
MFILE="/System/Library/CoreServices/SystemVersion.plist"

if [[ -f $LFILE ]]; then
  _distro=$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }')
elif [[ -f $MFILE ]]; then
  _distro="macos"
fi

case $_distro in
    *kali*)                  ICON="ﴣ";;
    *arch*)                  ICON="";;
    *debian*)                ICON="";;
    *raspbian*)              ICON="";;
    *ubuntu*)                ICON="";;
    *elementary*)            ICON="";;
    *fedora*)                ICON="";;
    *coreos*)                ICON="";;
    *gentoo*)                ICON="";;
    *mageia*)                ICON="";;
    *centos*)                ICON="";;
    *opensuse*|*tumbleweed*) ICON="";;
    *sabayon*)               ICON="";;
    *slackware*)             ICON="";;
    *linuxmint*)             ICON="";;
    *alpine*)                ICON="";;
    *aosc*)                  ICON="";;
    *nixos*)                 ICON="";;
    *devuan*)                ICON="";;
    *manjaro*)               ICON="";;
    *rhel*)                  ICON="";;
    *macos*)                 ICON="";;
    *)                       ICON="";;
esac

export STARSHIP_DISTRO="$ICON "

# ============================================================================
# Starship Prompt
# ============================================================================

if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
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

# ============================================================================
# Performance Optimization - End Profiling (optional)
# ============================================================================
# Uncomment if you enabled zprof at the top:
# zprof

# ============================================================================
# Local Configuration
# ============================================================================

# Source local zshrc if it exists (for machine-specific settings)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

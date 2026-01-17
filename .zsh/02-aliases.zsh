# ============================================================================
# Aliases
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
# Functions
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

# Reload shell configuration
function reload() {
  echo "♻️  Reloading shell configuration..."
  source ~/.zshrc
  echo "✓ Shell configuration reloaded!"
}

# Quick directory tree view
function tre() {
  tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX
}

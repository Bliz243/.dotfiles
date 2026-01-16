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

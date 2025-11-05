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

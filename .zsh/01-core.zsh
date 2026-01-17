# ============================================================================
# Environment Variables
# ============================================================================

# Terminal settings
export TERM="xterm-256color"
export TERM_FONT="JetBrainsMonoNL Nerd Font"

# Default editors
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"

# Language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# History configuration
export HISTSIZE=100000
export SAVEHIST=100000
export HISTFILE=~/.zsh_history
# ============================================================================
# Shell Options
# ============================================================================

# History options
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
# ============================================================================
# Starship Prompt
# ============================================================================

# Distro Detection for Starship
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

# Initialize Starship
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

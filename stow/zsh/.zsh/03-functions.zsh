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

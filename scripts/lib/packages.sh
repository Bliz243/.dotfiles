#!/usr/bin/env bash
# System package installers (apt/Homebrew and per-tool downloads), sourced by install.sh.
# Needs ui.sh (info/warn/error) and the install.sh globals CI and MACHINE_TYPE.

# ─────────────────────────────────────────────
# Install packages - macOS
# ─────────────────────────────────────────────
install_macos() {
  info "Installing packages via Homebrew..."

  # Install Homebrew if not present
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"
  fi

  # Install packages
  brew install \
    zsh git curl stow tmux \
    eza bat fd ripgrep fzf zoxide \
    neovim gh gitleaks \
    node bun

  # Install Nerd Font for terminal
  info "Installing JetBrainsMono Nerd Font..."
  brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || warn "Font install failed - install manually from nerdfonts.com"

  # Alacritty terminal (config is stowed from .config/alacritty)
  info "Installing Alacritty..."
  brew install --cask alacritty 2>/dev/null || warn "Alacritty install failed - install manually from alacritty.org"
}

# ─────────────────────────────────────────────
# Install packages - Linux (Ubuntu/Debian)
# ─────────────────────────────────────────────
# Acquire sudo up front so the install doesn't hang on a password prompt mid-run.
ensure_sudo() {
  if ! sudo -n true 2>/dev/null; then
    info "Administrator (sudo) access is required to install packages."
    sudo -v || error "Could not obtain sudo access. Re-run once sudo is available."
  fi
}

run_remote_installer() {
  local url="$1"
  local shell_bin="$2"
  local label="$3"

  local tmpdir; tmpdir="$(mktemp -d)"

  (
    trap 'rm -rf "$tmpdir"' EXIT
    curl -fsSLo "$tmpdir/install.sh" "$url"
    "$shell_bin" "$tmpdir/install.sh"
  )

  info "$label installer completed"
}

install_linux() {
  info "Installing packages via apt..."

  ensure_sudo

  sudo apt update
  sudo apt install -y \
    zsh git curl wget stow unzip gnupg ca-certificates \
    fzf ripgrep fd-find \
    build-essential fontconfig \
    libevent-dev ncurses-dev bison \
    bubblewrap  # Codex CLI's Linux sandbox

  # bat (called batcat on Ubuntu, create symlink)
  if ! command -v bat &>/dev/null; then
    sudo apt install -y bat
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
  fi

  # eza
  install_eza_linux

  # zoxide
  install_zoxide_linux

  # tmux 3.4+ (apt version is outdated)
  install_tmux_linux

  # Neovim 0.11.2+ (required by LazyVim)
  install_neovim_linux

  # Nerd Font for terminal
  install_font_linux

  # GitHub CLI
  install_gh_linux

  # lazygit (used by Neovim/LazyVim git workflow)
  install_lazygit_linux

  # gitleaks (secret scanner used by scripts/check-public.js)
  install_gitleaks_linux

  # win32yank for clipboard (WSL only; no-op elsewhere)
  install_win32yank_wsl

  # Node.js (system LTS) — required by Mason for the npm-based LSP servers
  install_node_linux

  # bun — default JS package manager for projects
  install_bun_linux

  # Alacritty terminal (local/desktop only; pointless + heavy on a headless VPS or CI)
  install_alacritty_linux
}

install_alacritty_linux() {
  # GUI terminal — config is stowed from .config/alacritty. Skip on headless/remote/CI.
  [[ "$CI" == "1" || "$MACHINE_TYPE" == "remote" ]] && return 0
  if command -v alacritty &>/dev/null; then
    info "Alacritty already installed"
    return
  fi
  info "Installing Alacritty..."
  # Available in apt universe on 24.04+; on older releases it needs a PPA/cargo, so never fatal.
  sudo apt install -y alacritty 2>/dev/null \
    || warn "Alacritty not installed (not in apt on this release) — install manually or via cargo"
}

install_eza_linux() {
  if command -v eza &>/dev/null; then
    info "eza already installed"
    return
  fi

  info "Installing eza..."
  # Try apt first (newer Ubuntu versions)
  if sudo apt install -y eza 2>/dev/null; then
    return
  fi

  # Otherwise install from official repo
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo apt update
  sudo apt install -y eza
}

install_zoxide_linux() {
  if command -v zoxide &>/dev/null; then
    info "zoxide already installed"
    return
  fi

  info "Installing zoxide..."
  run_remote_installer "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh" sh "zoxide"
}

install_tmux_linux() {
  local required="3.4" version
  tmux_ok() {
    command -v tmux &>/dev/null || return 1
    version="$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -1)"
    [[ "$(printf '%s\n' "$required" "$version" | sort -V | head -1)" == "$required" ]]
  }

  tmux_ok || sudo apt install -y tmux >/dev/null 2>&1 || true
  if tmux_ok; then
    info "tmux $version installed"
    return
  fi

  # Older releases ship tmux < 3.4: build the pinned version from source.
  warn "tmux ${version:-not found} from apt is older than $required. Building $required from source..."
  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir:-}"; trap - RETURN' RETURN
  (
    cd "$tmpdir" || exit
    curl -fsSLO "https://github.com/tmux/tmux/releases/download/${required}/tmux-${required}.tar.gz"
    tar -xzf "tmux-${required}.tar.gz"
    cd "tmux-${required}" || exit
    ./configure
    make -j"$(nproc)"
    sudo make install
  )
  info "tmux $required installed from source"
}

install_neovim_linux() {
  # LazyVim requires Neovim >= 0.11.2 (older versions hang on a "press any key" prompt).
  NVIM_REQUIRED="0.11.2"

  # Check if an adequate nvim is already installed
  if command -v nvim &>/dev/null; then
    NVIM_VERSION=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [[ -n "$NVIM_VERSION" ]] && \
       [[ "$(printf '%s\n' "$NVIM_REQUIRED" "$NVIM_VERSION" | sort -V | head -1)" == "$NVIM_REQUIRED" ]]; then
      info "Neovim $NVIM_VERSION already installed"
      return
    fi
    warn "Neovim ${NVIM_VERSION:-unknown} found, but $NVIM_REQUIRED+ required. Upgrading..."
  fi

  info "Installing latest stable Neovim..."

  # Detect architecture
  local ARCH
  case "$(uname -m)" in
    x86_64|amd64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
    *) warn "Unsupported architecture $(uname -m) for Neovim binary"; return ;;
  esac

  # Download and install — the rolling "stable" release always points at the latest
  # stable Neovim (currently 0.12.x), so no manual version bumps are needed.
  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir:-}"; trap - RETURN' RETURN
  (
    cd "$tmpdir" || exit
    curl -LO "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${ARCH}.tar.gz"
    sudo rm -rf "/opt/nvim-linux-${ARCH}"
    sudo tar -xzf "nvim-linux-${ARCH}.tar.gz" -C /opt/
    sudo ln -sf "/opt/nvim-linux-${ARCH}/bin/nvim" /usr/local/bin/nvim
  )
}

install_font_linux() {
  FONT_DIR="$HOME/.local/share/fonts"

  # Check if font already installed. Not `grep -q`: it exits on the first match, SIGPIPEs
  # fc-list (often >64 KB of output), and pipefail then reports the font as missing.
  if fc-list | grep -i "JetBrainsMono" >/dev/null; then
    info "JetBrainsMono Nerd Font already installed"
    return
  fi

  info "Installing JetBrainsMono Nerd Font..."

  mkdir -p "$FONT_DIR"

  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir:-}"; trap - RETURN' RETURN
  (
    cd "$tmpdir" || exit
    # Download from Nerd Fonts releases
    curl -fLo "JetBrainsMono.zip" \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    # Extract to fonts directory
    unzip -o JetBrainsMono.zip -d "$FONT_DIR/JetBrainsMono" >/dev/null 2>&1
  )

  # Refresh font cache (non-fatal — a cache refresh failure shouldn't abort the install)
  fc-cache -fv "$FONT_DIR" >/dev/null 2>&1 || true

  info "JetBrainsMono Nerd Font installed"
}

install_gh_linux() {
  if command -v gh &>/dev/null; then
    info "GitHub CLI already installed"
    return
  fi

  info "Installing GitHub CLI..."

  # Add GitHub CLI repository
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install -y gh
}

# Latest release version of a GitHub repo (e.g. 1.2.3), read from the releases/latest redirect.
# No API call, so no rate limit (the unauthenticated API allows 60 requests an hour per IP, shared on CI runners).
latest_release_version() {
  local url
  url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest")" || return 0
  if [[ "$url" == */tag/v* ]]; then echo "${url##*/tag/v}"; fi
}

install_lazygit_linux() {
  if command -v lazygit &>/dev/null; then
    info "lazygit already installed"
    return
  fi

  info "Installing lazygit..."

  local arch
  case "$(uname -m)" in
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) warn "Unsupported architecture $(uname -m) for lazygit"; return ;;
  esac

  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir:-}"; trap - RETURN' RETURN
  (
    cd "$tmpdir" || exit
    local ver
    ver="$(latest_release_version jesseduffield/lazygit)"
    if [[ -z "$ver" ]]; then
      warn "Could not determine lazygit version; skipping"
      exit 0
    fi
    curl -fsSLo lazygit.tar.gz \
      "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${ver}_Linux_${arch}.tar.gz"
    tar -xzf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
  )
}

install_gitleaks_linux() {
  if command -v gitleaks &>/dev/null; then
    info "gitleaks already installed"
    return
  fi

  info "Installing gitleaks..."
  local arch
  case "$(uname -m)" in
    x86_64|amd64) arch="x64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) warn "Unsupported architecture $(uname -m) for gitleaks"; return ;;
  esac

  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir:-}"; trap - RETURN' RETURN
  (
    cd "$tmpdir" || exit
    local ver
    ver="$(latest_release_version gitleaks/gitleaks)"
    if [[ -z "$ver" ]]; then
      warn "Could not determine gitleaks version; skipping"
      exit 0
    fi
    curl -fsSLo gitleaks.tar.gz \
      "https://github.com/gitleaks/gitleaks/releases/download/v${ver}/gitleaks_${ver}_linux_${arch}.tar.gz"
    tar -xzf gitleaks.tar.gz gitleaks
    mkdir -p "$HOME/.local/bin"
    install gitleaks "$HOME/.local/bin/gitleaks"
  )
}

install_win32yank_wsl() {
  # WSL only: clipboard provider so Neovim can reach the Windows clipboard. Check WSL's own
  # markers, not /proc/version: Docker containers on a WSL2 kernel report "microsoft" too.
  [[ -n "${WSL_DISTRO_NAME:-}" || -e /proc/sys/fs/binfmt_misc/WSLInterop ]] || return 0

  if command -v win32yank.exe &>/dev/null; then
    info "win32yank already installed"
    return
  fi

  info "Installing win32yank (WSL clipboard)..."
  mkdir -p "$HOME/.local/bin"

  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir:-}"; trap - RETURN' RETURN
  (
    cd "$tmpdir" || exit
    curl -fsSLo win32yank.zip \
      "https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip"
    unzip -o win32yank.zip win32yank.exe -d "$HOME/.local/bin" >/dev/null
    chmod +x "$HOME/.local/bin/win32yank.exe"
  )
}

install_node_linux() {
  # System Node exists purely to feed Mason: the LSP servers for the enabled lang
  # extras (typescript, tailwind, json, yaml, docker, basedpyright) are npm packages
  # Mason installs via `npm`. Project JS uses bun, so a single system Node is ideal.
  # NodeSource keeps it on PATH for every process — including post_install's headless
  # `Lazy! sync` and Vite/SvelteKit subprocesses that need a modern Node. No nvm: a
  # shell-function version manager isn't visible to Mason's non-interactive npm spawns.
  # Resolve the latest LTS major at run time (odd/current majors churn too much for
  # Mason's native deps) so the target never goes stale; the guard below upgrades an
  # older install in place. Falls back to a pinned floor when offline.
  # Fetch before parsing: piping curl into `grep -m1` kills curl with SIGPIPE (exit 23),
  # which aborts the install under pipefail.
  local index target_major
  index="$(curl -fsSL --max-time 10 https://nodejs.org/dist/index.json 2>/dev/null)" || index=""
  target_major="$(grep -m1 '"lts":"[A-Z]' <<<"$index" | grep -oE '"version":"v[0-9]+' | grep -oE '[0-9]+')" || true
  [[ "$target_major" =~ ^[0-9]+$ ]] || target_major=24

  if command -v node &>/dev/null; then
    local current; current="$(node -v)"; current="${current#v}"
    if (( ${current%%.*} >= target_major )); then
      info "Node already current ($(node -v))"
      return
    fi
    info "Node $(node -v) is below v${target_major} — upgrading..."
  else
    info "Installing Node.js ${target_major} (NodeSource)..."
  fi

  ensure_sudo
  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir:-}"; trap - RETURN' RETURN
  # Download then run (not piped to a shell) so the setup is auditable.
  if curl -fsSL "https://deb.nodesource.com/setup_${target_major}.x" -o "$tmpdir/nodesource.sh" \
    && sudo -E bash "$tmpdir/nodesource.sh" \
    && sudo apt install -y nodejs; then
    info "Node $(node -v) / npm $(npm -v) installed"
  else
    warn "Node install failed — Mason LSP servers (ts/tailwind/json/yaml/docker/python) won't install"
  fi
}

install_bun_linux() {
  # bun: default JS package manager for projects. ~/.bun/bin is already on PATH via .zshrc.
  local bun_bin
  bun_bin="$(command -v bun 2>/dev/null || echo "$HOME/.bun/bin/bun")"
  if [[ -x "$bun_bin" ]]; then
    info "bun $("$bun_bin" --version) installed — checking for updates..."
    "$bun_bin" upgrade || warn "bun self-upgrade failed — run 'bun upgrade' manually"
    return
  fi

  info "Installing bun..."
  local arch="x64"
  case "$(uname -m)" in aarch64 | arm64) arch="aarch64" ;; esac
  mkdir -p "$HOME/.bun/bin"

  local tmpdir; tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir:-}"; trap - RETURN' RETURN
  if curl -fsSLo "$tmpdir/bun.zip" \
      "https://github.com/oven-sh/bun/releases/latest/download/bun-linux-${arch}.zip" \
    && unzip -o "$tmpdir/bun.zip" -d "$tmpdir" >/dev/null; then
    mv "$tmpdir"/bun-linux-*/bun "$HOME/.bun/bin/bun"
    chmod +x "$HOME/.bun/bin/bun"
    info "bun $("$HOME/.bun/bin/bun" --version) installed"
  else
    warn "bun install failed — install manually from https://bun.sh"
  fi
}

# Dotfiles

Cross-platform dotfiles for macOS and Linux (Ubuntu/WSL2/VPS). Uses GNU Stow for symlink management.

## Quick Install

```bash
git clone https://github.com/Bliz243/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# For local machine (WSL/Desktop) - uses Ctrl+A
./install.sh --local

# For remote server (VPS) - uses Ctrl+B
./install.sh --remote

# Or run without flags to be asked interactively
./install.sh
```

The install script handles:
- Installing dependencies (zsh, neovim 0.11+, tmux 3.4+, modern CLI tools)
- Stowing dotfiles to home directory
- Setting zsh as default shell
- Installing tmux plugin manager (TPM)
- Syncing Neovim plugins
- Optional: Claude Code installation
- Optional: Workmux installation
- Optional: GitHub/SSH authentication setup

## Post-Install Setup

The install script automatically configures `~/.zshrc.local` based on your choice (`--local` or `--remote`).

### 1. Restart Shell

```bash
exec zsh
```

### 2. Install Tmux Plugins

In tmux, press your prefix key + `I`:
- Local (Ctrl+A): `C-a I`
- Remote (Ctrl+B): `C-b I`

### 3. Verify Neovim

Open nvim and plugins will auto-install. Run `:Mason` to verify LSP servers.

### Manual Configuration (Optional)

To change settings later, edit `~/.zshrc.local`:

```bash
# Local machine (WSL/Desktop)
export TMUX_PREFIX="C-a"
TMUX_AUTO_ATTACH="true"

# Remote server (VPS)
export TMUX_PREFIX="C-b"
TMUX_AUTO_ATTACH="ssh-only"
```

## GitHub & SSH Setup

The install script offers to configure GitHub authentication with SSH keys:

1. **Git identity** - Sets your name/email in `~/.gitconfig.local`
2. **SSH key** - Generates ed25519 key if none exists
3. **SSH config** - Adds GitHub-specific settings
4. **GitHub auth** - Authenticates via `gh` CLI and uploads your SSH key
5. **Remote switch** - Converts dotfiles remote from HTTPS to SSH

### On a VPS/Remote Server

When running on a remote machine (detected via SSH connection), the script shows a device code:

```
Remote machine detected

  1. A one-time code will be shown
  2. On any device, visit: https://github.com/login/device
  3. Enter the code to authenticate
```

### Run Setup Later

If you skip during install, run the standalone script anytime:

```bash
~/.dotfiles/setup-github.sh
```

## Claude Code

[Claude Code](https://claude.ai/code) is Anthropic's AI coding assistant CLI. The install script offers to install it.

Install manually:
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

## Workmux

[Workmux](https://github.com/raine/workmux) manages git worktrees + tmux windows for parallel AI agent development. The install script offers to install it.

Install manually:
```bash
curl -fsSL https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh | bash
```

### Quick Start

```bash
wm add feature-name     # Create worktree + tmux window with Claude agent
wm merge                # Merge branch and cleanup everything
wm dashboard            # Monitor all running agents
```

### Project Configuration

Copy the template to your project:
```bash
cp ~/.dotfiles/.workmux.yaml.example /path/to/project/.workmux.yaml
```

The template includes:
- Two-pane layout (Claude agent + shell)
- pnpm + Prisma post-create hooks
- .env and .claude/ file copying for worktrees

## What's Included

| Tool | Description |
|------|-------------|
| **Zsh + Zinit** | Fast shell with lazy-loaded plugins |
| **Minimal prompt** | Context-aware (minimal in tmux, full outside) |
| **Tmux** | Terminal multiplexer with Catppuccin theme, configurable prefix |
| **Neovim** | Modern editor with LSP, completion, Telescope |
| **Modern CLI** | eza, bat, fd, ripgrep, fzf, zoxide |

## Multi-Machine Setup

When using the same dotfiles on multiple machines (e.g., WSL + VPS), configure different tmux prefixes to avoid conflicts:

| Machine | TMUX_PREFIX | TMUX_AUTO_ATTACH | Theme |
|---------|-------------|------------------|-------|
| Local (WSL) | `C-a` | `true` | Mocha (darker) |
| Remote (VPS) | `C-b` | `ssh-only` | Macchiato (lighter) |

This way:
- `Ctrl+A` always controls your local tmux
- `Ctrl+B` always controls your VPS tmux
- Visual theme difference helps identify which tmux you're in

## Structure

```
.dotfiles/
├── install.sh              # Installation script
├── uninstall.sh            # Uninstall script
├── setup-github.sh         # Standalone GitHub/SSH setup
├── .zshrc                  # Shell config (sources .zsh/*.zsh)
├── .zshrc.local.example    # Template for machine-specific config
├── .zsh/
│   ├── 01-zinit.zsh        # Zinit plugins + prompt + tmux auto-attach
│   └── 02-aliases.zsh      # Aliases and functions
├── .tmux.conf              # Tmux config (configurable prefix, Catppuccin)
├── .config/
│   ├── nvim/               # Neovim (lazy.nvim, LSP, etc.)
│   ├── alacritty/          # Terminal emulator config
│   └── starship.toml       # Starship prompt (used outside tmux)
├── .gitconfig              # Git configuration
└── .gitignore_global       # Global gitignore
```

## Shell Features

| Feature | Description |
|---------|-------------|
| **Smart cd** | Uses zoxide - `cd projects` jumps to most-used "projects" dir |
| **Ctrl+R** | fzf-powered history search (much better than default) |
| **Colorized man** | Man pages rendered with syntax highlighting via bat |
| **Tab completion** | fzf-powered with directory previews |
| **Autosuggestions** | Fish-like command suggestions as you type |

## Key Bindings

### Tmux

Prefix is configurable: `C-a` (default) or `C-b` (set via `TMUX_PREFIX`)

| Key | Action |
|-----|--------|
| `prefix c` | New window |
| `prefix x` | Kill pane |
| `prefix \|` | Split horizontal |
| `prefix -` | Split vertical |
| `prefix h/j/k/l` | Navigate panes (vim-style) |
| `prefix R` | Reload config |
| `Shift+Left/Right` | Switch windows (no prefix) |
| `Alt+Left/Right` | Navigate panes (no prefix) |
| `Shift+Click` | Bypass tmux for terminal selection |

### Neovim

Leader key: `Space`

| Key | Action |
|-----|--------|
| `<leader>w` | Save file |
| `<leader>q` | Quit |
| `<leader>ff` | Find files (Telescope) |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>fh` | Help tags |
| `<C-p>` | Find files |
| `-` | File explorer (Oil) |
| `Tab` / `S-Tab` | Next/prev buffer |
| `<leader>bd` | Delete buffer |
| `<leader>cf` | Format buffer |
| `gcc` | Comment line |
| `gc` (visual) | Comment selection |

### Neovim LSP

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Find references |
| `gi` | Go to implementation |
| `K` | Hover documentation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code actions |
| `<leader>e` | Show diagnostic |
| `[d` / `]d` | Prev/next diagnostic |

## Language Support (LSP)

Out of the box, Neovim supports:

| Language | Server |
|----------|--------|
| Lua | lua_ls |
| TypeScript/JavaScript | ts_ls |
| Tailwind CSS | tailwindcss |
| HTML | html |
| CSS | cssls |
| Python | pyright |
| Bash | bashls |
| YAML | yamlls |
| Docker | dockerls |
| Terraform | terraformls |
| Go | gopls |

Add more by editing `~/.config/nvim/lua/config/lsp.lua`.

## Local Overrides

Machine-specific configs (not tracked in git):

| File | Purpose |
|------|---------|
| `~/.zshrc.local` | Shell settings, TMUX_PREFIX, PATH, aliases |
| `~/.gitconfig.local` | Git user settings (included via .gitconfig) |

## Testing

```bash
cd ~/.dotfiles/test
docker compose build
docker compose run --rm test
```

Tests verify:
- No CRLF line endings
- Zsh loads without errors
- Neovim version >= 0.11
- Tmux starts correctly
- All symlinks exist
- Modern CLI tools installed

## Update

```bash
cd ~/.dotfiles
git pull
stow . --restow
```

## Uninstall

```bash
cd ~/.dotfiles
./uninstall.sh
```

This removes symlinks and optionally cleans up plugins.

## Troubleshooting

### Zsh won't load or shows errors

```bash
# Check for syntax errors
zsh -n ~/.zshrc

# Run interactively to see errors
zsh -i -c 'exit'
```

### Neovim plugins fail to install

```bash
# Clear plugin cache and reinstall
rm -rf ~/.local/share/nvim/lazy
nvim --headless "+Lazy! sync" +qa
```

### Tmux shows errors on start

```bash
# Test config file
tmux -f ~/.tmux.conf new-session -d && echo "OK" && tmux kill-session
```

### Stow fails with conflicts

```bash
# Check for conflicting files
stow --simulate . --target="$HOME"

# Backup and remove conflicts manually, then re-stow
```

### SHIFT+Select doesn't copy text

SHIFT+click/drag bypasses tmux and uses terminal selection. Make sure:
1. `set -g mouse on` is in tmux config
2. Terminal supports mouse (Alacritty, iTerm2, Windows Terminal)

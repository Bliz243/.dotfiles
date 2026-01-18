# Dotfiles

Cross-platform dotfiles for macOS, Ubuntu (WSL2 + VPS). Uses GNU Stow for symlink management.

## Quick Install

```bash
git clone https://github.com/Bliz243/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The install script handles:
- Installing dependencies (zsh, neovim 0.11+, tmux, modern CLI tools)
- Stowing dotfiles to home directory
- Setting zsh as default shell
- Installing tmux plugin manager
- Syncing Neovim plugins

## Manual Install

```bash
# Clone
git clone https://github.com/Bliz243/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install dependencies (Ubuntu)
sudo apt install zsh tmux stow git curl fzf ripgrep fd-find bat
# For Neovim 0.11+, see install.sh

# Install dependencies (macOS)
brew install zsh tmux stow neovim eza bat fd ripgrep fzf zoxide

# Stow dotfiles
stow .

# Set zsh as default shell
chsh -s $(which zsh)
```

## What's Included

| Tool | Description |
|------|-------------|
| **Zsh + Zinit** | Fast shell with lazy-loaded plugins |
| **Pure prompt** | Minimal prompt (context info in tmux bar) |
| **Tmux** | Terminal multiplexer with Catppuccin theme |
| **Neovim** | Modern editor with LSP, completion, telescope |
| **Modern CLI** | eza, bat, fd, ripgrep, fzf, zoxide |

## Structure

```
.dotfiles/
├── install.sh              # Installation script
├── .zshrc                  # Shell config (sources .zsh/*.zsh)
├── .zsh/
│   ├── 01-zinit.zsh        # Zinit plugins + Pure prompt
│   ├── 02-aliases.zsh      # Aliases and functions
│   └── 99-local.zsh.example
├── .tmux.conf              # Tmux config (C-a prefix, Catppuccin)
├── .config/
│   ├── nvim/               # Neovim (lazy.nvim, LSP, etc.)
│   └── alacritty/          # Terminal emulator
├── .gitconfig              # Git configuration
└── .gitignore_global       # Global gitignore
```

## Key Bindings

### Tmux (prefix: C-a)
| Key | Action |
|-----|--------|
| `C-a c` | New window |
| `C-a x` | Kill pane |
| `C-a \|` | Split horizontal |
| `C-a -` | Split vertical |
| `C-a h/j/k/l` | Navigate panes |
| `Shift+Left/Right` | Switch windows |

### Neovim (leader: Space)
| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `-` | File explorer (Oil) |
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover docs |
| `<leader>ca` | Code actions |

## Local Overrides

Machine-specific configs (gitignored):

```bash
~/.zsh/99-local.zsh     # Shell customizations
~/.gitconfig.local      # Git settings (included via .gitconfig)
```

## Testing

```bash
cd ~/.dotfiles/test
docker compose build
docker compose run --rm test
```

## Post-Install

1. **Restart terminal** or run `exec zsh`
2. **Tmux**: Press `C-a + I` to install plugins
3. **Neovim**: Open and wait for plugins to install, then `:Mason` to verify LSP servers

## Update

```bash
cd ~/.dotfiles
git pull
stow . --restow
```

# Dotfiles Redesign

## Overview

Cross-platform dotfiles setup for macOS, Ubuntu (WSL2 + VPS), with future NixOS support in mind.

## Goals

- Same terminal experience across all machines
- Minimalist but functional setup
- Easy installation via single script + stow
- Docker-based testing to catch issues before deployment

## Target Environments

- macOS (travel laptop)
- Ubuntu 24.04 on WSL2 (Windows desktop)
- Ubuntu 24.04 on Hetzner VPS
- Future: NixOS (separate project)

## Tool Choices

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Shell | Zsh + Zinit | Faster plugin loading than Oh My Zsh |
| Prompt | Pure | Minimal `❯`, context info in tmux status bar |
| Terminal | Alacritty | Cross-platform, GPU-accelerated (GUI only) |
| Multiplexer | Tmux + Catppuccin | C-a prefix, vim-style navigation |
| Editor | Neovim 0.11+ | ~15 plugins, comfortable IDE for quick edits |
| Symlinks | GNU Stow | Simple, well-understood |

## Directory Structure

```
.dotfiles/
├── install.sh                    # Main installation script
├── .stow-local-ignore            # Files stow should skip
├── README.md
│
├── test/
│   ├── Dockerfile                # Ubuntu 24.04 test environment
│   ├── docker-compose.yml
│   └── test.sh                   # Automated smoke tests
│
├── .zshrc                        # Main zsh entry point
├── .zsh/
│   ├── 01-zinit.zsh              # Zinit bootstrap + plugins
│   ├── 02-aliases.zsh            # Aliases and functions
│   └── 99-local.zsh.example      # Machine-specific template
│
├── .config/
│   ├── nvim/
│   │   ├── init.lua              # Bootstrap lazy.nvim + base settings
│   │   └── lua/plugins/
│   │       ├── init.lua          # Plugin specs (~15 plugins)
│   │       └── lsp.lua           # LSP server configurations
│   │
│   └── alacritty/
│       └── alacritty.toml        # Terminal config
│
├── .tmux.conf                    # Tmux configuration
├── .gitconfig                    # Git configuration
└── .gitignore_global
```

## Shell Configuration

### Zinit Plugins

- `sindresorhus/pure` - Minimal prompt
- `zsh-users/zsh-autosuggestions` - Fish-like suggestions
- `zsh-users/zsh-syntax-highlighting` - Command highlighting
- `zsh-users/zsh-completions` - Additional completions
- `Aloxaf/fzf-tab` - fzf-powered tab completion

### Modern CLI Tools

With fallbacks for systems without them installed:

- `eza` - ls replacement
- `bat` - cat replacement
- `fd` - find replacement
- `ripgrep` - grep replacement
- `fzf` - fuzzy finder
- `zoxide` - cd replacement

## Tmux Configuration

- **Prefix**: `C-a`
- **Pane navigation**: `h/j/k/l` (vim-style)
- **Window navigation**: `Shift+Left/Right`
- **Splits**: `|` horizontal, `-` vertical
- **Theme**: Catppuccin Mocha
- **Status bar**: Directory on right side
- **Integration**: vim-tmux-navigator for seamless nvim switching

## Neovim Configuration

### Plugins (~15 total)

**Core:**
- catppuccin/nvim - Colorscheme (mocha)
- nvim-treesitter - Syntax highlighting
- nvim-lspconfig + mason - LSP management
- nvim-cmp - Completion

**Navigation:**
- telescope.nvim - Fuzzy finder
- oil.nvim - File explorer
- vim-tmux-navigator - Tmux integration

**Editing:**
- nvim-autopairs - Auto-close brackets
- Comment.nvim - Toggle comments
- conform.nvim - Format on save

**UI:**
- lualine.nvim - Status line
- gitsigns.nvim - Git indicators
- which-key.nvim - Keybind help

### LSP Servers (via Mason)

- lua_ls (Lua)
- ts_ls (TypeScript/JavaScript)
- tailwindcss (Tailwind CSS)
- html, cssls (HTML/CSS)
- pyright (Python)
- bashls (Bash)
- yamlls (YAML)
- dockerls (Docker)
- terraformls (Terraform)
- gopls (Go)

### Key Mappings

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `-` | Open file explorer |
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover documentation |
| `<leader>ca` | Code actions |
| `<leader>rn` | Rename symbol |

## Installation

```bash
git clone <repo> ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Install Script Order

1. Detect OS (macOS vs Linux)
2. Install packages via brew/apt
3. Install modern CLI tools (eza, bat, zoxide, etc.)
4. Install Neovim 0.11+ (from GitHub releases on Linux)
5. Run `stow .` to symlink dotfiles
6. Install tmux plugin manager (TPM)
7. Sync Neovim plugins via Lazy

## Testing

```bash
cd .dotfiles/test
docker compose build
docker compose run --rm test
```

### Test Validations

1. Shell loads without errors: `zsh -i -c 'exit'`
2. Neovim plugins install: `nvim --headless "+Lazy! sync" +qa`
3. Neovim health check passes
4. Tmux starts correctly
5. No CRLF line endings in any file

## Local Overrides

- `.zsh/99-local.zsh` - Machine-specific shell config (gitignored)
- `.gitconfig.local` - Machine-specific git config (included via include.path)

## Future Work

- NixOS configuration in separate `nix/` directory
- Home Manager integration for declarative package management

# Dotfiles

Cross-platform dotfiles for macOS and Linux (Ubuntu/WSL2/VPS). Uses GNU Stow for symlink management.

## Quick Install

```bash
git clone https://github.com/Bliz243/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# For local machine (WSL/Desktop) - uses Ctrl+A
./scripts/install.sh --local

# For remote server (VPS) - uses Ctrl+B
./scripts/install.sh --remote

# Or run without flags to be asked interactively
./scripts/install.sh
```

The install script handles:
- Installing dependencies (zsh, neovim 0.11.2+, tmux 3.4+, modern CLI tools)
- Node.js LTS (NodeSource — required by Mason for LSP servers) + bun (JS package manager)
- Stowing dotfiles to home directory
- Setting zsh as default shell
- Installing tmux plugin manager (TPM)
- Syncing Neovim plugins
- gitleaks and the repo's pre-push check (see [Public Repo Safety](#public-repo-safety))
- Agent config links, third-party skills, and playwright-cli (browser automation for agents)
- Optional: Claude Code and Codex CLI installation
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
~/.dotfiles/scripts/setup-github.sh
```

## Agent Config (Claude Code + Codex)

The install script offers to install [Claude Code](https://claude.ai/code) and the [Codex CLI](https://developers.openai.com/codex/cli). Their config lives in `agents/` and is symlinked into place by `scripts/install.sh` and `scripts/sync.sh`:

| Source | Linked to | Purpose |
|--------|-----------|---------|
| `agents/AGENTS.md` | `~/.claude/AGENTS.md`, `~/.codex/AGENTS.md` | Global instructions shared by both tools |
| `agents/skills/*` | `~/.claude/skills/`, `~/.agents/skills/` | Skills shared by both tools |
| `agents/claude/*` | `~/.claude/` | `CLAUDE.md` (imports `AGENTS.md`), settings, status line, hooks |
| `agents/codex/*` | `~/.codex/`, `~/.agents/skills/` | `config.toml` template (copied once, never overwritten), Codex-only skills |

Third-party skills (shadcn-svelte, playwright-cli) are installed with the [skills CLI](https://github.com/vercel-labs/skills) rather than committed; update them with `bunx skills update -g`. The `playwright-cli` command itself (`@playwright/cli`) is installed globally with bun, with Chromium only.

Claude Code starts in auto mode: a classifier reviews risky actions instead of prompting for each one. Auth, history, memory, and machine-specific settings stay in `~/.claude` and `~/.codex` and are never committed.

Install manually:
```bash
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

## Public Repo Safety

This repository is public. `scripts/check-public.js` fails when tracked files or new commits contain secrets (via [gitleaks](https://github.com/gitleaks/gitleaks)), email addresses, IP addresses, home-directory paths, or private terms. It runs:
- before every push, from `.githooks/pre-push` (`install.sh` and `dotsync` set `core.hooksPath`), over the commits being pushed
- in CI on every push and pull request, over the full history

Private terms (project names, hosts, usernames) live outside the repo in `~/.config/dotfiles/private-terms`, one per line, so the list itself stays private. Public placeholders that only look sensitive go in the `allow` pattern in the script.

```bash
node scripts/check-public.js    # working tree + full history
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
- bun post-create hook (with an optional Prisma line)
- .env and .claude/ file copying for worktrees

## What's Included

| Tool | Description |
|------|-------------|
| **Zsh + Zinit** | Fast shell with lazy-loaded plugins |
| **Minimal prompt** | Context-aware (minimal in tmux, full outside) |
| **Tmux** | Terminal multiplexer with Catppuccin theme, configurable prefix |
| **Neovim** | LazyVim with LSP, completion, formatting, linting |
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
├── scripts/                # Setup scripts
│   ├── install.sh          # Installation script
│   ├── sync.sh             # Re-apply after pulling or editing (restow + relink)
│   ├── uninstall.sh        # Uninstall script
│   ├── setup-github.sh     # Standalone GitHub/SSH setup
│   ├── check-public.js     # Public-repo check (secrets, emails, IPs, paths, private terms)
│   └── lib/                # ui.sh, links.sh, packages.sh, agents.sh
├── .githooks/pre-push      # Runs check-public.js on pushed commits
├── .github/workflows/      # CI: lint, public-repo check, Docker install test
├── test/                   # Docker install test + test.sh assertions
├── AGENTS.md               # Instructions for agents working on this repo
├── agents/                 # Claude Code + Codex config (linked, not stowed)
│   ├── AGENTS.md           # Global instructions for both tools
│   ├── skills/             # Shared skills
│   ├── claude/             # Claude Code: CLAUDE.md, settings, status line, hooks
│   └── codex/              # Codex: config.toml template, Codex-only skills
├── .zshrc                  # Shell config (sources .zsh/*.zsh)
├── .zshrc.local.example    # Template for machine-specific config
├── .zsh/
│   ├── 01-zinit.zsh        # Zinit plugins + prompt + tmux auto-attach
│   └── 02-aliases.zsh      # Aliases and functions
├── .tmux.conf              # Tmux config (configurable prefix, Catppuccin)
├── .config/
│   ├── nvim/               # Neovim (LazyVim)
│   └── alacritty/          # Terminal emulator config
├── .gitconfig              # Git configuration
└── .gitignore_global       # Global gitignore
```

## Shell Features

| Feature | Description |
|---------|-------------|
| **Smart cd** | Uses zoxide - `cd projects` jumps to most-used "projects" dir (agent shells keep the builtin) |
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

[LazyVim keymaps](https://www.lazyvim.org/keymaps) apply (leader is `Space`; press it to list every binding), plus these from `lua/config/keymaps.lua` and `lua/plugins/`:

| Key | Action |
|-----|--------|
| `-` | File explorer (Oil) |
| `Tab` / `S-Tab` | Next/prev buffer |
| `<C-d>` / `<C-u>` | Half page down/up, centered |
| `<leader>xq` / `<leader>xc` | Open/close quickfix |
| `<leader>xd` | Diagnostics to quickfix |
| `<leader>H` / `<leader>h` | Harpoon: add file / menu (also `<leader>ma` / `<leader>mm`) |
| `<leader>1`–`9` | Harpoon: jump to file |
| `<leader>gg` | Lazygit |

## Language Support (LSP)

Neovim runs [LazyVim](https://www.lazyvim.org). Language support (LSP servers, Treesitter
parsers, and formatters) comes from LazyVim **extras**, enabled in
`~/.config/nvim/lua/config/lazy.lua`: TypeScript, Python, Docker, YAML, Terraform,
Tailwind, JSON, Svelte, Markdown, plus Prettier formatting and ESLint linting. Prettier
formats Svelte files only in projects that have `prettier-plugin-svelte`.

Add or remove languages with `:LazyExtras` inside Neovim, or by editing the `extras` imports
in `lua/config/lazy.lua`. Mason installs the servers automatically on first launch.

## Local Overrides

Machine-specific configs (not tracked in git):

| File | Purpose |
|------|---------|
| `~/.zshrc.local` | Shell settings, TMUX_PREFIX, PATH, aliases |
| `~/.gitconfig.local` | Git user settings (included via .gitconfig) |

## Testing

The Docker image runs the **real `scripts/install.sh --ci`** on a clean Ubuntu 24.04,
then `test.sh` asserts the result — so the harness exercises the actual installer, not a copy.

```bash
cd ~/.dotfiles/test
docker compose build      # runs install.sh --local --ci inside the image
docker compose run --rm test
```

Tests verify:
- No CRLF line endings
- Zsh loads without errors
- Neovim >= 0.11.2 + LazyVim installs and config loads cleanly
- Tmux starts correctly
- All symlinks exist
- Modern CLI tools installed (eza, bat, fd, fzf, rg, zoxide)
- Node + npm (for Mason LSP servers) and bun installed
- Agent config linked for Claude Code and Codex (never stowed into `~`); settings parse, hook and status line run
- Agent shells (Claude Code, Codex) get the standard `ls`/`cat`/`cd`/`mkdir` and no tmux attach

CI (`.github/workflows/checks.yml`) runs this Docker test, shellcheck, and the public-repo check on every push and weekly.

## Update

```bash
dotsync    # = ~/.dotfiles/scripts/sync.sh --pull: pull, restow, relink agent config, sync plugins
```

## Uninstall

```bash
cd ~/.dotfiles
./scripts/uninstall.sh
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

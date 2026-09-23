# Dotfiles

zsh, tmux, Neovim (LazyVim), Alacritty, git, and shared Claude Code + Codex config for macOS, Ubuntu/WSL2, and servers.

```bash
git clone https://github.com/Bliz243/.dotfiles.git ~/.dotfiles
~/.dotfiles/scripts/install.sh --local   # --remote on a server (tmux prefix C-b instead of C-a)
```

- `dotsync` pulls and re-applies everything: dotfiles, agent config, plugins.
- Machine-specific settings go in `~/.zshrc.local` and `~/.gitconfig.local`, never in this repo.
- `scripts/setup-github.sh` sets up git identity, an SSH key, and `gh` auth.
- This repo is public. A pre-push hook and CI run `scripts/check-public.js`; list private names in `~/.config/dotfiles/private-terms`.
- Test the installer on clean Ubuntu 24.04: `cd test && docker compose build && docker compose run --rm test`

Layout and rules for changing this repo are in [AGENTS.md](AGENTS.md).

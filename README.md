# Dotfiles

Minimal dotfiles using GNU Stow.

## Install

```bash
git clone https://github.com/Bliz243/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && stow .
chsh -s $(which zsh)
```

## Dependencies

```bash
# Ubuntu/Debian
sudo apt install zsh tmux neovim stow fzf ripgrep
curl -sS https://starship.rs/install.sh | sh

# macOS
brew install zsh tmux neovim stow fzf ripgrep starship
```

## Structure

```
.zshrc              # Shell config (sources .zsh/*.zsh)
.zsh/               # Modular zsh configs
.gitconfig          # Git config
.gitignore_global   # Global gitignore
.tmux.conf          # Tmux config
.config/
├── nvim/           # Neovim
├── starship.toml   # Prompt
└── alacritty/      # Terminal (optional)
```

## Local Overrides

```bash
~/.zsh/99-local.zsh   # Machine-specific shell config
~/.gitconfig.local    # Machine-specific git config
```

## Update

```bash
cd ~/.dotfiles && git pull
```

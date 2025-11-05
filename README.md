# 🚀 Dotfiles

A comprehensive, cross-platform dotfiles setup using Ansible for automated provisioning of development environments.

## ✨ Features

### 🛠️ Core Tools
- **Shell**: Zsh with Oh My Zsh, custom plugins, and intelligent history
- **Terminal**: Alacritty with optimized configuration
- **Multiplexer**: tmux with sensible defaults and vim-like keybindings
- **Editor**: Neovim with extensive plugins and LSP support
- **Prompt**: Starship with custom theming and distro detection
- **Fonts**: JetBrains Mono Nerd Font (auto-downloaded during setup)

### 🔧 Modern CLI Tools
- **eza/exa**: Modern replacement for `ls` with icons and git integration
- **bat**: Better `cat` with syntax highlighting
- **fd**: Faster and more user-friendly `find`
- **ripgrep (rg)**: Blazingly fast grep alternative
- **fzf**: Fuzzy finder for files, history, and processes
- **zoxide**: Smart directory jumping based on frecency

### 🎨 Developer Experience
- **Git**: Comprehensive aliases and configuration
- **LSP Support**: Full language server protocol support via coc.nvim
- **Fuzzy Finding**: Integrated fzf for files, buffers, and commands
- **Smart Navigation**: zoxide for intelligent directory switching
- **Auto-completion**: zsh-autosuggestions for command suggestions
- **Syntax Highlighting**: bat for file previews and man pages

### 🔐 Security Features
- Secrets excluded from version control
- Machine-specific configurations via local override files
- Safe defaults for git and shell operations

## 🚀 Quick Start

### Prerequisites
- **Git** (will be installed if missing)
- **Ansible** (will be installed if missing)
- **Sudo access** (for package installation)

### Installation

1. **Clone the repository**:
```bash
git clone https://github.com/your-username/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2. **Run the installation script**:
```bash
./install.sh
```

The script will:
- Detect your operating system (macOS, Ubuntu, Debian, Arch, Fedora, etc.)
- Install required dependencies (git, ansible)
- Run the Ansible playbook to configure your system
- Download and install fonts
- Set up all tools and configurations

3. **Restart your terminal** or source your shell config:
```bash
exec zsh
# or
source ~/.zshrc
```

## 📁 Structure

```
.dotfiles/
├── ansible/                    # Ansible automation
│   ├── setup-new-machine.yml  # Main playbook
│   ├── ansible.cfg            # Ansible configuration
│   └── roles/                 # Modular role-based setup
│       ├── common/            # Common packages and tools
│       ├── zsh/               # Zsh shell configuration
│       ├── fonts/             # Font installation
│       ├── starship/          # Starship prompt
│       ├── nvim/              # Neovim editor
│       ├── tmux/              # tmux multiplexer
│       └── alacritty/         # Alacritty terminal
├── zsh/                       # Zsh configuration files
│   └── .zshrc                 # Main zsh config
├── nvim/                      # Neovim configuration
│   └── init.vim               # Neovim config (380+ lines)
├── tmux/                      # tmux configuration
│   └── .tmux.conf             # tmux config
├── starship/                  # Starship prompt config
│   └── starship.toml          # Prompt configuration
├── alacritty/                 # Alacritty terminal config
│   └── alacritty.toml         # Terminal config
├── git/                       # Git configuration
│   ├── .gitconfig             # Git settings and aliases
│   └── .gitignore_global      # Global gitignore patterns
├── vscode/                    # VS Code settings
│   ├── settings.json          # Editor settings
│   └── keybinds.json          # Keybindings
├── install.sh                 # Main installation script
└── README.md                  # This file
```

## ⚙️ Configuration Details

### Shell (Zsh)

The zsh configuration includes:
- **Oh My Zsh** with useful plugins
- **Conditional tmux auto-attach** (won't interfere with VSCode or SSH)
- **Modern CLI tools integration** with fallbacks to standard commands
- **Intelligent history** (100k lines, deduplication, shared across sessions)
- **fzf integration** for fuzzy finding files, directories, and processes
- **zoxide integration** for smart directory navigation
- **Comprehensive aliases** for git, docker, kubernetes, and more

**Disable tmux auto-attach**:
```bash
export TMUX_AUTO_ATTACH=false
```

**Key aliases**:
```bash
# Navigation
z <dir>          # Jump to directory (zoxide)
fcd              # Fuzzy cd
fvim             # Fuzzy find and open file

# Modern replacements
ls/ll/la         # eza with icons (fallback to exa/ls)
cat              # bat with syntax highlighting
grep             # ripgrep (rg)
find             # fd

# Git shortcuts
gs               # git status
ga               # git add
gc               # git commit -m
gp               # git push
gl               # git log --oneline --graph
```

### Editor (Neovim)

Comprehensive Neovim setup with:
- **20+ plugins** including coc.nvim for LSP support
- **Gruvbox color scheme** (hard contrast)
- **Airline statusline** with git integration
- **NERDTree** file explorer
- **fzf.vim** for fuzzy finding
- **vim-fugitive** for git operations
- **Language support** via coc extensions (TypeScript, Python, Go, Docker, etc.)
- **Auto-pairs**, indent guides, and whitespace management
- **Extensive keybindings** with space as leader key

**Key mappings**:
```vim
<Space>         " Leader key
<C-n>           " Toggle NERDTree
<C-p>           " Fuzzy find files
<Space>f        " Ripgrep search
gd              " Go to definition
gr              " Find references
K               " Show documentation
<Space>rn       " Rename symbol
```

### Terminal (Alacritty)

- **Tokyo Night color scheme**
- **JetBrains Mono Nerd Font**
- **95% opacity** for modern aesthetics
- **10,000 line scrollback**
- **Optimized for performance**

### Multiplexer (tmux)

- **Prefix: Ctrl+a** (instead of Ctrl+b)
- **50,000 line history**
- **Vim-style pane navigation** (h/j/k/l)
- **Mouse support enabled**
- **Vi mode** for copy operations
- **Intuitive split keybindings** (| and -)

### Git

Includes **50+ git aliases** for common operations:
```bash
git st           # Status (short)
git cm           # Commit with message
git co           # Checkout
git l            # Pretty log graph
git unstage      # Unstage files
git cleanup      # Delete merged branches
```

Full configuration includes:
- Better diff algorithms
- Automatic pruning of remote branches
- Rebase by default on pull
- Colorized output

## 🔧 Customization

### Local Configuration Files

Create these files for machine-specific settings (they're gitignored):

- `~/.zshrc.local` - Local zsh configuration
- `~/.gitconfig.local` - Local git settings (name, email)

Example `~/.gitconfig.local`:
```ini
[user]
    name = Your Name
    email = your.email@example.com

[github]
    user = your-github-username
```

### Modifying Configurations

All configuration files are in their respective directories. After modifying:

1. **For zsh**: `source ~/.zshrc` or restart terminal
2. **For neovim**: `:source $MYVIMRC` or restart nvim
3. **For tmux**: `tmux source ~/.tmux.conf` (or `<prefix>:source-file ~/.tmux.conf`)

To re-run the full setup:
```bash
cd ~/.dotfiles
ansible-playbook ansible/setup-new-machine.yml
```

## 🆘 Troubleshooting

### Fonts not displaying correctly

1. Ensure JetBrains Mono Nerd Font is installed:
```bash
fc-list | grep JetBrains
```

2. Manually download from [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts/releases/latest)

### Oh My Zsh or plugins missing

```bash
# Reinstall Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
```

### Neovim plugins not working

```bash
# Reinstall vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Then in nvim:
:PlugInstall
```

### Modern CLI tools not installed

If tools like `eza`, `bat`, `fd`, etc. aren't available:

**Option 1: Install via package manager**
```bash
# Ubuntu/Debian
sudo apt install eza bat fd-find ripgrep fzf zoxide

# macOS
brew install eza bat fd ripgrep fzf zoxide

# Arch
sudo pacman -S eza bat fd ripgrep fzf zoxide
```

**Option 2: Install via cargo (if Rust is installed)**
```bash
cargo install eza bat fd-find ripgrep zoxide
```

The zshrc will automatically fallback to standard commands if modern tools aren't available.

### Permission denied errors

Make sure install script is executable:
```bash
chmod +x ~/.dotfiles/install.sh
```

## 🔄 Updating

To update dotfiles and tools:

```bash
cd ~/.dotfiles
git pull
./install.sh  # Re-run setup
```

To update just Neovim plugins:
```bash
nvim +PlugUpdate +qall
```

To update Oh My Zsh:
```bash
omz update
```

## 🌟 Highlights

### Performance Optimizations
- Lazy loading for shell initialization
- Optimized font caching
- Efficient plugin loading
- Fast startup times (< 1s for zsh)

### Developer-Friendly
- Extensive documentation in config files
- Sensible defaults that just work
- Easy to customize and extend
- Works across multiple platforms

### Modern & Maintained
- Uses latest versions of tools
- Regular updates via Ansible
- Community-driven plugin selection
- Security-first approach

## 📝 Supported Platforms

- ✅ **macOS** (via Homebrew)
- ✅ **Ubuntu/Debian** (via apt)
- ✅ **Arch Linux** (via pacman)
- ✅ **Fedora/RHEL** (via dnf)
- ✅ **Other Linux distros** (with package manager adaptation)

## 🤝 Contributing

Feel free to fork and customize for your own use! If you find bugs or have suggestions:

1. Open an issue
2. Submit a pull request
3. Share your improvements

## 📄 License

MIT License - feel free to use and modify as needed.

## 🙏 Acknowledgments

Built with inspiration from the dotfiles community and these excellent projects:
- [Oh My Zsh](https://ohmyz.sh/)
- [Neovim](https://neovim.io/)
- [Starship](https://starship.rs/)
- [Alacritty](https://alacritty.org/)
- [fzf](https://github.com/junegunn/fzf)
- And many more amazing open-source tools!

---

**Made with ❤️ for the command line**

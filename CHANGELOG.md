# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-11-05

### Added - MAJOR OVERHAUL 🎉

- **GNU Stow Integration**: Switched from copy-based to symlink-based dotfiles management
- **Modular Zsh Configuration**: Split `.zshrc` into 9 focused modules for better maintainability
- **Management Scripts**: Added 7 comprehensive scripts (bootstrap, stow, unstow, restow, health-check, test, update)
- **Makefile**: Unified interface for all operations
- **Documentation**: Complete rewrite with INSTALL.md, TROUBLESHOOTING.md, and examples
- **Configuration Templates**: Added .gitconfig.local.example, .env.example, 99-local.zsh.example
- **Health Check System**: 200+ lines validating entire setup
- **Testing Framework**: Automated syntax validation and checks
- **Repository Restructuring**: New directory layout (stow/, scripts/, docs/, config/)

### Changed

- **Directory Structure**: Moved all configs to `stow/` directory for Stow compatibility
- **Ansible Roles**: Updated to use Stow instead of copying files
- **install.sh**: Completely rewritten for new structure
- **README.md**: Complete rewrite with comprehensive documentation

### Removed

- Duplicate directory structure (old configs moved to stow/)
- 8.5MB fonts directory (now downloaded during setup)
- Exposed API keys and sensitive data from vscode settings

### Security

- Removed exposed OpenAI API key from VS Code settings
- Removed hardcoded SSH paths and IPs
- Added comprehensive .gitignore for secrets
- Created templates for local configuration

## [1.0.0] - 2024-11-05

### Added - Initial Optimization

- Security fixes (removed exposed secrets)
- Enhanced Neovim configuration (48 → 382 lines)
- Comprehensive Git configuration with 50+ aliases
- Fixed zsh configuration issues
- Added modern CLI tools (eza, bat, fd, ripgrep, fzf, zoxide)
- Fixed Ansible role permissions
- Optimized font handling (download vs store)
- Added update.sh script

### Changed

- Improved .zshrc with better tool integration
- Enhanced nvim init.vim with full LSP support
- Updated git config with extensive aliases
- Fixed conditional tmux auto-attach

## [0.1.0] - Initial Release

### Added

- Basic Ansible-based dotfiles setup
- Oh My Zsh integration
- Neovim, Tmux, Alacritty configurations
- Starship prompt
- Cross-platform support (macOS, Linux)

# Troubleshooting Guide

Common issues and their solutions.

## Installation Issues

### Stow Conflicts

**Problem**: Stow reports conflicts with existing files

```
WARNING! stowing zsh would cause conflicts:
  * existing target is neither a link nor a directory: .zshrc
```

**Solution**: Backup and remove existing files

```bash
# Backup existing config
mv ~/.zshrc ~/.zshrc.backup

# Then stow again
./scripts/stow.sh zsh
```

### Permission Denied

**Problem**: Permission denied when stowing

**Solution**: Ensure you're not running as root and files are owned by you

```bash
# Check ownership
ls -la ~/.zshrc

# Fix if needed
sudo chown $USER:$USER ~/.zshrc
```

### Ansible Fails

**Problem**: Ansible playbook fails

**Solution**: Check ansible is installed and run with verbose mode

```bash
ansible --version
ansible-playbook -vvv ansible/setup-new-machine.yml
```

## Shell Issues

### Zsh Modules Not Loading

**Problem**: Shell loads but modules seem missing

**Solution**: Check module files exist and have correct permissions

```bash
# List modules
ls -la ~/.zsh/

# Ensure they're readable
chmod 644 ~/.zsh/*.zsh
```

### Slow Shell Startup

**Problem**: Shell takes > 2 seconds to start

**Solution**: Profile startup and identify slow plugins

```bash
# Enable profiling in .zshrc
# Uncomment: zmodload zsh/zprof

# Start new shell and check output
zsh
# At prompt, run:
zprof
```

Common culprits:
- Too many Oh My Zsh plugins
- Slow network calls (nvm, conda)
- Large history files

### Oh My Zsh Not Found

**Problem**: `command not found: omz`

**Solution**: Reinstall Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## Neovim Issues

### Plugins Not Installing

**Problem**: `:PlugInstall` fails or plugins missing

**Solution**: Reinstall vim-plug and retry

```bash
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

nvim +PlugInstall +qall
```

### CoC Extensions Fail

**Problem**: CoC LSP not working

**Solution**: Install Node.js and reinstall extensions

```bash
# Install Node.js (macOS)
brew install node

# Install Node.js (Linux)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Reinstall CoC extensions
nvim +CocInstall coc-json coc-tsserver +qall
```

### Color Scheme Not Loading

**Problem**: Neovim doesn't show gruvbox colors

**Solution**: Ensure termguicolors is set and terminal supports it

```bash
# Check in nvim
:echo has('termguicolors')  # Should return 1

# If 0, terminal doesn't support true color
# Use a modern terminal: Alacritty, iTerm2, Wezterm
```

## Tool Issues

### Modern CLI Tools Not Found

**Problem**: `eza`, `bat`, `fd` etc. not found

**Solution**: Install via package manager or cargo

```bash
# Ubuntu/Debian
sudo apt install eza bat fd-find ripgrep fzf

# macOS
brew install eza bat fd ripgrep fzf zoxide

# Via cargo (if you have Rust)
cargo install eza bat fd-find ripgrep zoxide
```

### Starship Not Showing

**Problem**: Prompt is still Oh My Zsh theme, not Starship

**Solution**: Ensure Starship is installed and initialized

```bash
# Check installation
which starship

# If not found, reinstall
curl -sS https://starship.rs/install.sh | sh

# Check .zshrc sources prompt module
grep starship ~/.zsh/06-prompt.zsh
```

### Fonts Not Displaying

**Problem**: Icons/glyphs show as boxes

**Solution**: Install Nerd Font and set terminal to use it

```bash
# Check fonts installed
fc-list | grep JetBrains

# If missing, Ansible will install on next run
make install

# Set terminal font to: JetBrainsMono Nerd Font
```

## Symlink Issues

### Broken Symlinks

**Problem**: `make health` shows broken symlinks

**Solution**: Restow the affected package

```bash
# Restow all
./scripts/restow.sh

# Or specific package
./scripts/restow.sh zsh
```

### Symlinks Pointing Wrong Place

**Problem**: Symlinks point to wrong directory

**Solution**: Unstow and stow again from correct directory

```bash
cd ~/.dotfiles
./scripts/unstow.sh
./scripts/stow.sh
```

## Git Issues

### Can't Push Changes

**Problem**: Permission denied when pushing

**Solution**: Check git remote and credentials

```bash
# Check remote
git remote -v

# If HTTPS, may need to set up credentials
git config credential.helper store

# Or switch to SSH
git remote set-url origin git@github.com:Bliz243/.dotfiles.git
```

## Still Having Issues?

1. **Run health check**:
   ```bash
   make health
   ```

2. **Check logs**:
   ```bash
   # Ansible logs
   tail -f /var/log/ansible.log
   ```

3. **Start fresh**:
   ```bash
   ./scripts/unstow.sh
   make clean
   make install
   ```

4. **Ask for help**:
   - Open an issue on GitHub
   - Include output of `make health`
   - Include your OS and version

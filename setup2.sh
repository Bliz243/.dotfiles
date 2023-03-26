#!/bin/bash

# Install zsh-pluggins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Install font-logos
wget -O font-logos.zip https://github.com/lukas-w/font-logos/archive/refs/heads/master.zip
unzip font-logos.zip
sudo mkdir -p /usr/local/share/fonts
sudo cp font-logos-master/*.ttf /usr/local/share/fonts
rm -rf font-logos.zip font-logos-master
sudo fc-cache -f -v

# Install JetBrains Mono font
sudo cp JetBrainsMono-font/*.ttf /usr/local/share/fonts
sudo fc-cache -f -v

# Install starship
curl -fsSL https://starship.rs/install.sh | bash

# Install exa
wget -O exa-linux-x86_64-v0.10.1.zip https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip
unzip exa-linux-x86_64-v0.10.1.zip
sudo mv exa-linux-x86_64 /usr/local/bin/exa
rm exa-linux-x86_64-v0.10.1.zip

# Symlink .zshrc and starship.toml to the home directory
ln -sf "$(pwd)/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$(pwd)/starship.toml" "$HOME/.config/starship.toml"
mkdir -p "$HOME/.config/Code/User"
ln -sf "$(pwd)/vscode/settings.json" "$HOME/.config/Code/User/settings.json"

if [ -f vscode-extensions.txt ]; then
  while read -r extension; do
    code --install-extension "$extension"
  done < vscode-extensions.txt
fi

# Change the default shell to zsh
chsh -s $(which zsh)

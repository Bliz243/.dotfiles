#!/bin/bash

# Detect the operating system
OS_NAME=$(uname)

# Install common tools
install_common() {
  # Install JetBrains Mono font
  sudo cp JetBrainsMono-font/*.ttf /usr/local/share/fonts
  sudo fc-cache -f -v

  # Install starship
  curl -fsSL https://starship.rs/install.sh | sh

  # Install oh-my-zsh
  yes Y | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # Install zsh-plugins
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
}

if [ "$OS_NAME" = "Linux" ]; then
  # Assume Ubuntu/Debian for now

  # Install Zsh
  sudo apt update
  sudo apt install -y zsh

  # Install Visual Studio Code
  sudo apt install -y apt-transport-https
  curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
  echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
  sudo apt update
  sudo apt install -y code

  # Install font-logos
  wget -O font-logos.zip https://github.com/lukas-w/font-logos/archive/refs/heads/master.zip
  unzip font-logos.zip
  sudo mkdir -p /usr/local/share/fonts
  sudo cp font-logos-master/*.ttf /usr/local/share/fonts
  rm -rf font-logos.zip font-logos-master
  sudo fc-cache -f -v

  install_common

  # Install exa
  sudo apt update
  sudo apt install -y unzip
  EXA_VERSION=$(curl -s "https://api.github.com/repos/ogham/exa/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
  curl -Lo exa.zip "https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-v${EXA_VERSION}.zip"
  sudo unzip -q exa.zip bin/exa -d /usr/local
  rm -rf exa.zip

  # Configure symlinks
  mkdir -p "$HOME/.config/Code/User"
  ln -sf "$(pwd)/vscode/settings.json" "$HOME/.config/Code/User/settings.json"

elif [ "$OS_NAME" = "Darwin" ]; then
  # macOS setup

  # Install Homebrew if not installed
  if ! command -v brew >/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Install Zsh
  brew install zsh

  # Install Visual Studio Code
  brew install --cask visual-studio-code

  # Install font-logos
  wget -O font-logos.zip https://github.com/lukas-w/font-logos/archive/refs/heads/master.zip
  unzip font-logos.zip
  cp font-logos-master/*.ttf ~/Library/Fonts/
  rm -rf font-logos.zip font-logos-master

  install_common

  # Install exa
  brew install exa

  # Configure symlinks
  mkdir -p "$HOME/Library/Application Support/Code/User"
  ln -sf "$(pwd)/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

else
  echo "Unsupported operating system: $OS_NAME"
  exit 1
fi

# Symlink .zshrc and starship.toml to the home directory
ln -sf "$(pwd)/zsh/.zshrc" "$HOME/.zshrc"
cp $pwd/sharship.toml $HOME/.config

if [ -f vscode-extensions.txt ]; then
  while read -r extension; do
    code --install-extension "$extension"
  done < vscode-extensions.txt
fi

# Change the default shell to zsh
chsh -s $(which zsh)


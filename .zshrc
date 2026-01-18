# ~/.zshrc - Main zsh configuration
# Loads modular configs from ~/.zsh/

# Load all zsh config files in order
for file in ~/.zsh/*.zsh(N); do
  source "$file"
done

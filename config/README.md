# Configuration Templates

This directory contains templates and examples for machine-specific configurations.

## Files

### .gitconfig.local.example
Template for local Git configuration. Copy to `~/.gitconfig.local` and customize with your:
- Name and email
- GitHub username
- Machine-specific settings

### .env.example
Template for environment variables. Add sensitive data here (never commit real secrets!).

## Usage

```bash
# Copy templates to your home directory
cp config/.gitconfig.local.example ~/.gitconfig.local

# Edit with your information
$EDITOR ~/.gitconfig.local

# For shell-specific local config, use:
$EDITOR ~/.zsh/99-local.zsh
```

## Security Note

**NEVER** commit files containing:
- API keys or tokens
- Passwords
- SSH keys
- Personal information

All `.local` and `.env` files are gitignored by default.

# ============================================================================
# Main ZSH Configuration File
# ============================================================================
# This file loads modular configuration from ~/.zsh/
# Each module handles a specific aspect of the shell configuration

# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && . "$HOME/.fig/shell/zshrc.pre.zsh"

# ============================================================================
# Performance Profiling (optional)
# ============================================================================
# Uncomment to profile zsh startup time:
# zmodload zsh/zprof

# ============================================================================
# Load Modular Configuration
# ============================================================================

# Source all configuration files in order
for config_file in ~/.zsh/*.zsh(N); do
  source "$config_file"
done

# Source local configuration if it exists (gitignored, machine-specific)
[[ -f ~/.zsh/99-local.zsh ]] && source ~/.zsh/99-local.zsh

# ============================================================================
# Performance Profiling Output (optional)
# ============================================================================
# Uncomment if you enabled zprof at the top:
# zprof

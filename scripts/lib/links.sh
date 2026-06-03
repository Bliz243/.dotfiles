#!/usr/bin/env bash
# Shared symlink/stow helpers used by both install.sh and sync.sh.
#
# Requires the sourcing script to provide:
#   - info(), warn(), error()   logging functions
#   - DOTFILES_DIR              absolute path to the dotfiles repo root
#
# All functions here are idempotent and safe to run repeatedly.

# Symlink $1 -> $2, backing up a pre-existing real (non-symlink) destination.
link_file() {
  local src="$1" dest="$2"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    local backup="${dest}.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$dest" "$backup"
    warn "Backed up: $dest → $backup"
  fi
  # -n/--no-dereference: if $dest is already a symlink to a dir, replace it instead of
  # creating the new link *inside* that dir (the classic `ln -sf` footgun on re-runs).
  ln -sfn "$src" "$dest"
}

# Delete dangling symlinks (target no longer exists) directly under each given dir.
# Used so skills/agents removed from the repo don't leave stale links behind.
cleanup_dangling_symlinks() {
  local dir
  for dir in "$@"; do
    [[ -d "$dir" ]] || continue
    find "$dir" -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
  done
}

# Stow the repo's dotfiles into $HOME, backing up conflicting real files/dirs first.
stow_dotfiles() {
  info "Stowing dotfiles..."
  cd "$DOTFILES_DIR" || error "Cannot cd to $DOTFILES_DIR"

  local backup_suffix=".backup-$(date +%Y%m%d-%H%M%S)"
  local conflict_files=".zshrc .tmux.conf .gitconfig .gitignore_global .zshrc.local.example"
  local conflict_dirs=".config/nvim .config/alacritty .zsh"
  local item

  for item in $conflict_files; do
    if [[ -f "$HOME/$item" && ! -L "$HOME/$item" ]]; then
      warn "Backing up existing $item to $item$backup_suffix"
      mv "$HOME/$item" "$HOME/$item$backup_suffix"
    fi
  done

  for item in $conflict_dirs; do
    if [[ -d "$HOME/$item" && ! -L "$HOME/$item" ]]; then
      warn "Backing up existing $item to $item$backup_suffix"
      mv "$HOME/$item" "$HOME/$item$backup_suffix"
    fi
  done

  stow . --target="$HOME" --restow || error "Stow failed. Check for conflicting files in $HOME"
}

# Relink Claude Code config into ~/.claude (idempotent).
relink_claude_config() {
  local dotfiles_claude="$DOTFILES_DIR/.claude"
  local claude_dir="$HOME/.claude"

  [[ -d "$dotfiles_claude" ]] || { warn "No Claude config in dotfiles, skipping"; return; }

  mkdir -p "$claude_dir/hooks" "$claude_dir/config" "$claude_dir/skills" "$claude_dir/agents"
  cleanup_dangling_symlinks "$claude_dir/skills" "$claude_dir/agents"

  # AGENTS.md is canonical; CLAUDE.md is a @AGENTS.md shim. Both must be linked.
  [[ -f "$dotfiles_claude/AGENTS.md" ]]    && link_file "$dotfiles_claude/AGENTS.md"    "$claude_dir/AGENTS.md"
  [[ -f "$dotfiles_claude/CLAUDE.md" ]]    && link_file "$dotfiles_claude/CLAUDE.md"    "$claude_dir/CLAUDE.md"
  [[ -f "$dotfiles_claude/settings.json" ]] && link_file "$dotfiles_claude/settings.json" "$claude_dir/settings.json"
  [[ -f "$dotfiles_claude/statusline.js" ]] && link_file "$dotfiles_claude/statusline.js" "$claude_dir/statusline.js"

  local f
  for f in "$dotfiles_claude/hooks/"*.js;  do [[ -f "$f" ]] && link_file "$f" "$claude_dir/hooks/$(basename "$f")";  done
  for f in "$dotfiles_claude/config/"*;    do [[ -e "$f" ]] && link_file "$f" "$claude_dir/config/$(basename "$f")"; done
  for f in "$dotfiles_claude/skills/"*/;   do [[ -d "$f" ]] && link_file "$f" "$claude_dir/skills/$(basename "$f")"; done
  for f in "$dotfiles_claude/agents/"*.md; do [[ -f "$f" ]] && link_file "$f" "$claude_dir/agents/$(basename "$f")"; done

  info "Claude Code configuration linked"
}

# Relink Codex config into ~/.codex and ~/.agents/skills (idempotent).
# Does NOT clone superpowers (that is a one-time bootstrap step in install.sh).
relink_codex_config() {
  local dotfiles_codex="$DOTFILES_DIR/.codex"
  local dotfiles_claude="$DOTFILES_DIR/.claude"
  local codex_dir="$HOME/.codex"
  local agents_dir="$HOME/.agents/skills"

  [[ -d "$dotfiles_codex" ]] || { warn "No Codex config in dotfiles, skipping"; return; }

  mkdir -p "$codex_dir" "$agents_dir"
  cleanup_dangling_symlinks "$agents_dir"

  # Single source of truth: Codex reads the canonical AGENTS.md from the Claude tree.
  [[ -f "$dotfiles_claude/AGENTS.md" ]] && link_file "$dotfiles_claude/AGENTS.md" "$codex_dir/AGENTS.md"

  local skill
  for skill in "$dotfiles_codex/skills/"*/; do
    [[ -d "$skill" ]] && link_file "$skill" "$agents_dir/$(basename "$skill")"
  done

  # superpowers skills (cloned by install.sh bootstrap)
  [[ -d "$codex_dir/superpowers/skills" ]] && link_file "$codex_dir/superpowers/skills" "$agents_dir/superpowers"

  # config.toml is machine-specific (project paths, MCP IPs): copy from template once, never overwrite.
  if [[ ! -f "$codex_dir/config.toml" && -f "$dotfiles_codex/config.toml.example" ]]; then
    cp "$dotfiles_codex/config.toml.example" "$codex_dir/config.toml"
    info "Created ~/.codex/config.toml from template (edit it for projects + MCP servers)"
  fi

  info "Codex CLI configuration linked"
}

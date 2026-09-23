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
    local backup
    backup="${dest}.backup-$(date +%Y%m%d-%H%M%S)"
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

  local backup_suffix
  backup_suffix=".backup-$(date +%Y%m%d-%H%M%S)"
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

# Link every skill directory found in the given source dirs into $1.
link_skills() {
  local dest="$1" src skill
  shift
  for src in "$@"; do
    for skill in "$src/"*/; do
      if [[ -d "$skill" ]]; then link_file "${skill%/}" "$dest/$(basename "$skill")"; fi
    done
  done
}

# Relink Claude Code config into ~/.claude (idempotent).
# agents/ holds what every agent shares (AGENTS.md, skills/); agents/claude/ is Claude-only.
relink_claude_config() {
  local agents_src="$DOTFILES_DIR/agents"
  local claude_src="$agents_src/claude"
  local claude_dir="$HOME/.claude"

  [[ -d "$claude_src" ]] || { warn "No Claude config in dotfiles, skipping"; return; }

  mkdir -p "$claude_dir/hooks" "$claude_dir/config" "$claude_dir/skills" "$claude_dir/agents"
  cleanup_dangling_symlinks "$claude_dir/skills" "$claude_dir/agents" "$claude_dir/hooks" "$claude_dir/config"

  # CLAUDE.md imports @~/.claude/AGENTS.md, so both must be linked.
  link_file "$agents_src/AGENTS.md"     "$claude_dir/AGENTS.md"
  link_file "$claude_src/CLAUDE.md"     "$claude_dir/CLAUDE.md"
  link_file "$claude_src/settings.json" "$claude_dir/settings.json"
  link_file "$claude_src/statusline.js" "$claude_dir/statusline.js"

  local f
  for f in "$claude_src/hooks/"*.js;  do [[ -f "$f" ]] && link_file "$f" "$claude_dir/hooks/$(basename "$f")";  done
  for f in "$claude_src/config/"*;    do [[ -e "$f" ]] && link_file "$f" "$claude_dir/config/$(basename "$f")"; done
  for f in "$claude_src/agents/"*.md; do [[ -f "$f" ]] && link_file "$f" "$claude_dir/agents/$(basename "$f")"; done
  link_skills "$claude_dir/skills" "$agents_src/skills" "$claude_src/skills"

  info "Claude Code configuration linked"
}

# Relink Codex config into ~/.codex and ~/.agents/skills (idempotent).
relink_codex_config() {
  local agents_src="$DOTFILES_DIR/agents"
  local codex_src="$agents_src/codex"
  local codex_dir="$HOME/.codex"
  local skills_dir="$HOME/.agents/skills"

  [[ -d "$codex_src" ]] || { warn "No Codex config in dotfiles, skipping"; return; }

  mkdir -p "$codex_dir" "$skills_dir"
  cleanup_dangling_symlinks "$skills_dir"

  link_file "$agents_src/AGENTS.md" "$codex_dir/AGENTS.md"
  link_skills "$skills_dir" "$agents_src/skills" "$codex_src/skills"

  # config.toml is machine-specific (project paths, MCP IPs): copy from template once, never overwrite.
  if [[ ! -f "$codex_dir/config.toml" && -f "$codex_src/config.toml.example" ]]; then
    cp "$codex_src/config.toml.example" "$codex_dir/config.toml"
    info "Created ~/.codex/config.toml from template (edit it for projects + MCP servers)"
  fi

  info "Codex CLI configuration linked"
}

# Use the repo's tracked hooks (.githooks/pre-push blocks pushing secrets or private data).
enable_repo_hooks() {
  git -C "$DOTFILES_DIR" config core.hooksPath .githooks
  info "Git hooks enabled (.githooks)"
}

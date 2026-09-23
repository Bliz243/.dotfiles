#!/usr/bin/env bash
# Agent tooling (Claude Code, Codex, skills, workmux), sourced by install.sh.
# Needs ui.sh, links.sh, packages.sh (run_remote_installer), and the install.sh globals
# CI and DOTFILES_DIR.

# ─────────────────────────────────────────────
# Claude Config Setup (Symlinks for global config)
# ─────────────────────────────────────────────
setup_claude_config() {
  info "Setting up Claude Code configuration..."
  relink_claude_config
}

# ─────────────────────────────────────────────
# Claude Code Installation (Optional)
# ─────────────────────────────────────────────
setup_claude_code() {
  [[ "$CI" == "1" ]] && { info "CI: skipping Claude Code install"; return; }

  if command -v claude &>/dev/null; then
    info "Claude Code already installed"
  else
    echo ""
    echo -e "${BLUE}Would you like to install Claude Code?${NC}"
    echo "Claude Code is Anthropic's AI coding assistant CLI."
    echo ""
    read -p "Install Claude Code? [y/N]: " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      info "Skipping Claude Code. Install later: curl -fsSL https://claude.ai/install.sh | bash"
      return
    fi

    info "Installing Claude Code..."
    run_remote_installer "https://claude.ai/install.sh" bash "Claude Code"

    if command -v claude &>/dev/null; then
      info "Claude Code installed successfully"
    else
      warn "Claude Code installation may have failed. Try manually:"
      echo "  curl -fsSL https://claude.ai/install.sh | bash"
      return
    fi
  fi
}

# ─────────────────────────────────────────────
# Codex CLI Installation (Optional)
# ─────────────────────────────────────────────
setup_codex_cli() {
  [[ "$CI" == "1" ]] && { info "CI: skipping Codex CLI install"; return; }

  # Already installed: keep it current via the built-in self-updater
  if command -v codex &>/dev/null; then
    info "Codex CLI already installed ($(codex --version 2>/dev/null)) — checking for updates..."
    codex update || warn "codex update failed — update manually with: codex update"
    return
  fi

  echo ""
  echo -e "${BLUE}Would you like to install the Codex CLI?${NC}"
  echo "Codex is OpenAI's AI coding agent CLI (requires a ChatGPT plan)."
  echo ""
  read -p "Install Codex CLI? [y/N]: " -n 1 -r
  echo ""

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Skipping Codex CLI. Install later: curl -fsSL https://chatgpt.com/codex/install.sh | sh"
    return
  fi

  info "Installing Codex CLI (official installer)..."
  CODEX_NON_INTERACTIVE=1 run_remote_installer "https://chatgpt.com/codex/install.sh" sh "Codex CLI"

  if command -v codex &>/dev/null; then
    info "Codex CLI installed: $(codex --version 2>/dev/null)"
  else
    warn "Codex CLI install may have failed (or its bin dir isn't on PATH yet). Try manually:"
    echo "  curl -fsSL https://chatgpt.com/codex/install.sh | sh"
  fi
}

# ─────────────────────────────────────────────
# Codex Config Setup (Symlinks for global config + skills)
# ─────────────────────────────────────────────
setup_codex_config() {
  info "Setting up Codex CLI configuration..."

  [[ -d "$DOTFILES_DIR/agents/codex" ]] || { warn "No Codex config in dotfiles, skipping"; return; }

  relink_codex_config
}

# ─────────────────────────────────────────────
# Third-party Agent Skills + Playwright CLI
# ─────────────────────────────────────────────
# Skills are installed with the skills CLI into ~/.agents/skills (Codex) and linked into
# ~/.claude/skills, never vendored into this public repo. Update with: bunx skills update -g
THIRD_PARTY_SKILLS=(
  "huntabyte/shadcn-svelte shadcn-svelte"
  "microsoft/playwright-cli playwright-cli"
)

setup_agent_skills() {
  [[ "$CI" == "1" ]] && { info "CI: skipping third-party agent skills"; return; }

  local bun_bin
  bun_bin="$(command -v bun 2>/dev/null || echo "$HOME/.bun/bin/bun")"
  [[ -x "$bun_bin" ]] || { warn "bun not found, skipping third-party agent skills"; return; }

  info "Installing third-party agent skills..."
  local entry repo skill
  for entry in "${THIRD_PARTY_SKILLS[@]}"; do
    read -r repo skill <<< "$entry"
    "$bun_bin" x --bun skills@latest add "$repo" --skill "$skill" \
      --global --agent claude-code codex --yes >/dev/null \
      || warn "$skill skill install failed. Retry: bunx skills add $repo --skill $skill -g -a claude-code codex -y"
  done

  # The playwright-cli skill drives this CLI; Playwright downloads its own browser
  # (~/.cache/ms-playwright), so no system Chromium is needed.
  "$bun_bin" add --global @playwright/cli@latest >/dev/null \
    && "$HOME/.bun/bin/playwright-cli" install-browser chromium --with-deps >/dev/null \
    || warn "playwright-cli setup failed. Retry: bun add -g @playwright/cli && playwright-cli install-browser chromium --with-deps"
}

# ─────────────────────────────────────────────
# Workmux Installation (Optional)
# ─────────────────────────────────────────────
setup_workmux() {
  [[ "$CI" == "1" ]] && { info "CI: skipping workmux install"; return; }

  # Check if already installed
  if command -v workmux &>/dev/null; then
    info "Workmux already installed"
    return
  fi

  echo ""
  echo -e "${BLUE}Would you like to install workmux?${NC}"
  echo "Workmux manages git worktrees + tmux for parallel AI agent development."
  echo ""
  read -p "Install workmux? [y/N]: " -n 1 -r
  echo ""

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Skipping workmux. Install later: curl -fsSL https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh | bash"
    return
  fi

  info "Installing workmux..."
  run_remote_installer "https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh" bash "workmux"

  if command -v workmux &>/dev/null; then
    info "Workmux installed successfully"
    echo ""
    echo "  Quick start:"
    echo "    wm add feature-name    # Create worktree + tmux window"
    echo "    wm merge               # Merge and cleanup"
    echo "    wm dashboard           # Monitor all agents"
    echo ""
    echo "  Copy template config to your project:"
    echo "    cp ~/.dotfiles/.workmux.yaml.example /path/to/project/.workmux.yaml"
    echo ""
  else
    warn "Workmux installation may have failed. Try manually:"
    echo "  curl -fsSL https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh | bash"
  fi
}

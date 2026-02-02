# Claude Configuration Portability Design

**Status:** Active
**Date:** 2026-02-02

## Goal

Make Claude Code configuration reproducible across all machines (laptops, VPS, etc.) via dotfiles/stow, while keeping machine-specific and runtime data local.

## Architecture

### What Gets Stowed (Global Config)

```
~/.dotfiles/.claude/
├── settings.json              # Global hooks + statusline
├── statusline.js              # Universal status line
├── hooks/
│   ├── skill-monitor.js       # Skill activation + token warnings
│   └── command-guard.js       # Dangerous command confirmation
├── config/
│   └── skill-rules.json       # Base workflow triggers
├── skills/
│   └── ultra-frontend/
│       └── SKILL.md           # Distinctive UI design skill
└── agents/
    └── code-review.md         # Generic code reviewer
```

### What Stays Local (Not Stowed)

- `~/.claude/.credentials.json` - auth tokens
- `~/.claude/settings.local.json` - machine-specific permissions
- `~/.claude/history.jsonl` - command history
- `~/.claude/plugins/` - plugin-managed
- `~/.claude/cache/`, `projects/`, `debug/`, etc. - runtime data

### Project-Level Extensions

Projects can extend global config with:
- `.claude/config/skill-rules.json` - project-specific skill triggers
- `.claude/skills/` - domain-specific skills
- `.claude/agents/` - project-specific reviewers
- `.claude/settings.local.json` - project permissions

## Components

### 1. Global Settings (`settings.json`)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "node ~/.claude/hooks/command-guard.js" }]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [{ "type": "command", "command": "node ~/.claude/hooks/skill-monitor.js" }]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "node ~/.claude/statusline.js"
  }
}
```

### 2. Command Guard (`hooks/command-guard.js`)

Intercepts dangerous commands, asks for confirmation:
- `rm -rf` with any path
- `git push --force`
- `git reset --hard`
- `DROP DATABASE/TABLE`
- `TRUNCATE`
- `DELETE FROM` without WHERE

Returns `decision: "ask"` so user can approve if intentional.

### 3. Skill Monitor (`hooks/skill-monitor.js`)

- Injects ultrathink
- Loads global skill-rules.json
- Loads project skill-rules.json (if exists)
- Merges rules (project extends global)
- Triggers appropriate skills based on prompt

### 4. Base Skill Rules (`config/skill-rules.json`)

Triggers for:
- `superpowers:brainstorming` - design before coding
- `superpowers:debugging` - structured debugging
- `explore-agent` - use subagent for exploration
- `ultra-frontend` - UI/component/styling work

### 5. Ultra Frontend Skill

Distinctive, production-grade frontend interfaces. Avoids generic AI aesthetics.

### 6. Code Review Agent

Generic code reviewer for bugs, security issues, LLM slop.

## Installation

Custom handling in `install.sh`:

```bash
setup_claude_config() {
  # Create directories
  mkdir -p ~/.claude/{hooks,config,skills,agents}

  # Symlink individual files (with backup)
  ln -sf ~/.dotfiles/.claude/settings.json ~/.claude/settings.json
  ln -sf ~/.dotfiles/.claude/statusline.js ~/.claude/statusline.js
  # ... etc
}
```

Stow ignores `.claude/` entirely - we handle it specially to preserve runtime data.

## Usage

1. Install dotfiles: `./install.sh`
2. Run Claude with `--dangerously-skip-permissions` (or `ccd` alias)
3. Command guard asks confirmation for dangerous commands
4. Statusline shows context usage, git info everywhere
5. Base skills trigger globally
6. Projects extend with their own rules/skills

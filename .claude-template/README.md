# Claude Code Project Template

Standardized `.claude` configuration for consistent AI-assisted development across projects.

## Prerequisites

Install the **superpowers** plugin (one-time, from within Claude Code):

```bash
# 1. Start Claude Code
claude

# 2. Add the marketplace
/plugin marketplace add obra/superpowers-marketplace

# 3. Install the plugin
/plugin install superpowers@superpowers-marketplace

# 4. Verify (should see /superpowers:* commands)
/help
```

This provides `superpowers:brainstorming`, `superpowers:debugging`, and other workflow skills.

## Quick Start

Copy this template to your project:

```bash
claude-init   # alias defined in ~/.zsh/02-aliases.zsh
# or manually:
cp -r ~/.dotfiles/.claude-template /path/to/project/.claude
```

## What's Included

### Status Line
Shows context usage, git branch, and uncommitted files in Claude Code's status bar.

### Agents

| Agent | Purpose |
|-------|---------|
| `code-review` | Review completed code for bugs, security issues, and best practices |

### Skill Rules

| Rule | Type | Purpose |
|------|------|---------|
| `superpowers:brainstorming` | suggest | Design before coding |
| `superpowers:debugging` | suggest | Structured debugging approach |
| `explore-agent` | suggest | Use subagents to preserve context |
| `review-agents` | remind | Consider review after implementation |

## Customization

### Add Project-Specific Agents

Create new files in `.claude/agents/`:

```markdown
---
name: my-agent
description: When to use this agent
model: inherit
---

Your agent instructions here...
```

### Add Project-Specific Rules

Edit `.claude/config/skill-rules.json` to add rules specific to your project.

## Structure

```
.claude/
├── agents/
│   └── code-review.md      # Generic code review agent
├── config/
│   └── skill-rules.json    # Activation rules
├── settings.json           # Claude Code settings
├── statusline.js           # Status bar script
└── README.md               # This file
```

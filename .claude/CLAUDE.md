@AGENTS.md

## Claude Code
- Hooks (`command-guard`, `skill-monitor`), `statusline.js`, and skill activation rules (`config/skill-rules.json`) live in `~/.dotfiles/.claude/` and are symlinked into `~/.claude/` by `scripts/install.sh`. Edit the dotfiles copy, never the `~/.claude/` symlink target.
- `settings.local.json` and `state/` are machine-specific and gitignored.

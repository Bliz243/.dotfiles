# Dotfiles

Personal dotfiles for WSL/Ubuntu and remote Linux servers: zsh, tmux, Neovim (LazyVim), Alacritty, git, and the global Claude Code and Codex config. This repository is public.

## Layout
- Top-level dotfiles are stowed into `~` with GNU stow; `.stow-local-ignore` lists what isn't.
- `agents/` is symlinked into place by `scripts/lib/links.sh`, never stowed: `agents/AGENTS.md` → `~/.claude/AGENTS.md` and `~/.codex/AGENTS.md`; `agents/skills/` → `~/.claude/skills/` and `~/.agents/skills/`; `agents/claude/` → `~/.claude/` (`CLAUDE.md` is only an `@~/.claude/AGENTS.md` import); `agents/codex/config.toml.example` is copied once to `~/.codex/config.toml`.
- `scripts/install.sh` sets up a machine and `scripts/sync.sh` (the `dotsync` alias) re-applies; helpers live in `scripts/lib/`.

## Checks
- CI runs shellcheck, syntax checks, `scripts/check-public.js`, and the Docker install test on every push; the pre-push hook runs `check-public.js`.
- Locally, check only what you changed: `shellcheck -x -S warning <script>`, `zsh -n <file>`, `node --check <file>`. Run the Docker test (`cd test && docker compose build && docker compose run --rm test`, about 10 minutes, in the background) only for installer changes.
- Verify agent config statically: resolve the symlinks, parse the JSON, run the status line with sample input. Never start `claude -p` or `codex exec` sessions to check it; settings load only in a new session.

## Rules
- Public repo: no secrets, machine-specific values (IPs, paths, allow lists), or project-specific content. Private names the check should block go in the untracked `~/.config/dotfiles/private-terms`.
- Third-party skills (shadcn-svelte, playwright-cli) are installed by `install.sh` with the skills CLI, never copied in. Update them with `bunx skills update -g`.
- Machine-specific state stays out of the repo: `~/.claude`, `~/.codex`, `~/.zshrc.local`, `~/.gitconfig.local`.
- Never stow `AGENTS.md`: `~/AGENTS.md` would apply to every project under `~`.
- Agent shells load this zsh config. Anything that changes a standard command (eza, bat, zoxide, flag-adding aliases) goes inside `if [[ -z "${_agent_shell:-}" ]]`.
- Scripts are idempotent; `--ci` skips interactive and optional steps.
- Bash runs under `set -euo pipefail`. End functions with `if … fi`, not a failing `[[ … ]] && …`. Clean temp dirs with `trap 'rm -rf "${tmpdir:-}"; trap - RETURN' RETURN`. Capture large output (curl, `fc-list`) in a variable instead of piping it into `grep -q`, `grep -m1`, or `head`.
- Node comes from NodeSource because Mason needs it; project JavaScript uses bun. Neovim must be 0.11.2 or newer; `lazy-lock.json` is committed.

## Decisions
- Claude Code runs in auto mode with hard limits in `permissions.deny`; it replaced a regex command-guard hook.
- No prompt hooks, workflow plugins, or mandatory TDD (skill-monitor, superpowers, quality-loop, the codex plugin): skills trigger from their descriptions, and those layers multiplied checks without better results.
- The `claude-md-management` plugin stays disabled because it edits the `CLAUDE.md` import shim.

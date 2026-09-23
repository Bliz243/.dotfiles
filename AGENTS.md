# Dotfiles

Personal dotfiles for a local WSL/Ubuntu machine and remote Linux servers: zsh, tmux, Neovim (LazyVim), Alacritty, git, and the global config for Claude Code and Codex. This repository is public.

## Layout
- Top-level dotfiles (`.zshrc`, `.zsh/`, `.tmux.conf`, `.config/`, `.gitconfig`, `.gitignore_global`) are stowed into `~` with GNU stow. `.stow-local-ignore` lists everything that isn't.
- `agents/` holds agent config. `scripts/lib/links.sh` symlinks it into place; it is never stowed.
  - `agents/AGENTS.md`: global instructions for both tools, linked to `~/.claude/AGENTS.md` and `~/.codex/AGENTS.md`.
  - `agents/skills/`: skills for both tools, linked into `~/.claude/skills/` and `~/.agents/skills/`.
  - `agents/claude/`: `CLAUDE.md` (imports `@~/.claude/AGENTS.md`), `settings.json`, `statusline.js`, `hooks/`, `config/`, linked into `~/.claude/`.
  - `agents/codex/`: `config.toml.example` (copied once to `~/.codex/config.toml`, never overwritten) and Codex-only skills.
- `scripts/`: `install.sh` (full setup), `sync.sh` (restow, relink, plugin sync; the `dotsync` alias runs it with `--pull`), `uninstall.sh`, `setup-github.sh`, `check-public.js`. `scripts/lib/`: `ui.sh` (logging), `links.sh` (stow and symlinks), `packages.sh` (system packages and tools), `agents.sh` (Claude Code, Codex, skills, workmux).
- `test/`: Docker harness that runs the real `install.sh --local --ci` on Ubuntu 24.04, then `test.sh` asserts the result.
- `.githooks/pre-push` runs `check-public.js` on the pushed commits; `install.sh` and `sync.sh` set `core.hooksPath`. `.github/workflows/checks.yml` runs lint, the public-repo check, and the Docker test in CI.

## Commands
- Apply changes: `scripts/sync.sh`
- Full test (needs Docker): `cd test && docker compose build && docker compose run --rm test`
- Public-repo check: `node scripts/check-public.js` (private terms come from the untracked `~/.config/dotfiles/private-terms`)
- Quick checks: `bash -n scripts/*.sh scripts/lib/*.sh test/test.sh`, `shellcheck -x -S warning` on the same files, `zsh -n .zshrc .zsh/*.zsh`, `node --check` on `agents/claude/statusline.js` and `agents/claude/hooks/*.js`

## Rules
- Public repo: no secrets, no machine-specific values (IPs, trusted paths, permission allow lists), and nothing specific to one project (repo names, internal processes). `check-public.js` enforces this before every push and in CI; GitHub secret scanning and push protection are on.
- Third-party skills (shadcn-svelte, playwright-cli) are installed by `install.sh` with the skills CLI, never copied into the repo. Update them with `bunx skills update -g`.
- Machine-specific and runtime state stays out of the repo: `~/.claude`, `~/.codex`, `~/.zshrc.local`, `~/.gitconfig.local`. Never symlink it back in here.
- `AGENTS.md` must never be stowed: `~/AGENTS.md` would become instructions for every project under `~`.
- Agent shells (Claude Code, Codex) load this zsh config. Anything that changes a standard command (eza for `ls`, bat for `cat`, zoxide for `cd`, flag-adding aliases) goes inside `if [[ -z "${_agent_shell:-}" ]]`; `.zshrc` sets `_agent_shell` from `CLAUDECODE`, `CODEX_THREAD_ID`, or `AI_AGENT`.
- Scripts are idempotent and safe to re-run. `--ci` skips interactive and optional steps; the Docker test depends on it.
- Bash runs under `set -euo pipefail`. A function whose last command is a failed `[[ … ]] && …` returns non-zero and aborts the caller, so use `if … fi` there. Clean temp dirs with `trap 'rm -rf "${tmpdir:-}"; trap - RETURN' RETURN`; a plain RETURN trap leaks into later functions under `set -u`. Don't pipe large output (curl, `fc-list`) into a reader that exits early (`grep -q`, `grep -m1`, `head`): the writer dies of SIGPIPE and pipefail fails the pipeline. Capture it in a variable first.
- Node is installed system-wide from NodeSource because Mason's LSP servers need it; project JavaScript uses bun. Neovim must be 0.11.2 or newer, and `lazy-lock.json` is committed.

## Decisions
- Claude Code runs in auto mode, with hard limits in `permissions.deny`. It replaced a regex command-guard hook that produced false positives and auto-approved every command it didn't match.
- The `skill-monitor` hook stays for project-level `.claude/config/skill-rules.json` (project invariants such as money and clock rules). The global rules file is empty because skill descriptions already trigger skills natively.
- The `claude-md-management` plugin is disabled: it edits `CLAUDE.md`, which here is only an import shim for `AGENTS.md`.
- The superpowers plugin is retired: harness-native plan mode, review, and worktrees replaced it, and its mandatory TDD made results worse.

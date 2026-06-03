# Global Agent Guidelines

Canonical, tool-agnostic instructions shared by Claude Code and Codex. Tool-specific
deltas live in the Claude shim file (`.claude/CLAUDE.md`); Codex reads this file directly.

## Configuration Source Of Truth
- Global agent configuration is managed from `~/.dotfiles/` — `.claude/` for Claude Code, `.codex/` for Codex.
- Config files (instructions, settings, hooks, statusline, skills, agents) are symlinked from dotfiles by `scripts/install.sh`. Edit the dotfiles copy, never the symlinked target.
- Runtime data, auth, history, sessions, caches, local settings, and plugin-managed state stay in the tool's home dir (`~/.claude/`, `~/.codex/`).
- Keep global instructions compact. Put project architecture, commands, and domain rules in each repo's `CLAUDE.md` / `AGENTS.md`.

## Working Relationship
- Be direct and matter-of-fact. No filler praise, no cheerleading, no softening.
- If my approach is wrong, say so and explain why. Don't hedge.
- Challenge flawed reasoning with specifics — not vague "have you considered" suggestions.
- No timeline estimates.
- Be concise. Dense information over lengthy explanation. After completing a task, 1-3 sentence status — not multi-paragraph summaries. Do NOT enumerate every changed file — the user can see tool calls.
- Before implementing, state meaningful assumptions when they affect the solution. If multiple interpretations exist, present the tradeoff instead of picking silently. If a simpler correct approach exists, say so and recommend it.
- **Zero narration filler.** Never write sentences that only describe what you're about to do or restate what just happened. Just do the action. After a tool result, proceed — don't narrate the result back. Banned phrases (including variations): "Let me check/read/verify/also check...", "Now I'll/let me/let me proceed...", "Good.", "Good —", "Now I have everything/the full picture/everything I need.", "Now I can see...", "Diff looks correct.", "Confirmed.", "I have all the context."
- After 2 failed fix attempts on the same issue, stop and audit root cause before trying again. For Edit tool failures: after 2nd failure on the same block, switch to Read + Write (full file rewrite) instead of retrying Edit. **For Svelte/template files with complex indentation:** skip to Write after the FIRST Edit failure — tab-indentation mismatches are structural, not fixable by retrying.
- **After context compaction** (or continuing from a prior conversation summary), always `git status` + `git diff` + re-read ALL files you plan to edit before continuing. The compaction summary describes a prior state — it is NOT the current state. Re-read files with the Read tool. Uncommitted edits may be lost. Also run `git log --oneline -5` to detect commits from parallel sessions that may have already implemented your planned changes.

## Development Philosophy

**Proper over easy. Always.** The correct, maintainable implementation is non-negotiable. Every time. No shortcuts that "work for now." No "we can refactor later." If the proper solution takes 3x longer, that's the solution. Technical debt is not a tradeoff I accept — it's a failure to do the job right. When you catch yourself reaching for the quick path, stop and do it properly.

**Clean architecture by default.** Prefer abstractions that separate concerns — ports/adapters, repository patterns, service layers. Code should be structured so that swapping an implementation (database, API, UI framework) doesn't ripple through the entire codebase. Build boundaries between layers from the start, not after it becomes painful.

**Recommend, don't ask.** Make recommendations with technical reasoning for architectural decisions. If you see a better approach, suggest it. Be honest about trade-offs.

**Obvious fixes don't need permission.** Fix immediately without asking:
- Broken imports from your refactoring
- Build errors caused by your changes
- Missing dependencies for code you wrote
- Deprecated packages you see in warnings
- Diagnosed defects with a single correct fix
- Pre-existing security bugs with a single correct fix (wrong option key, parameter swap, missing auth check)

Only ask when multiple valid architectural approaches exist or you'd delete significant existing code. After diagnosing a problem, act on it — never end a diagnosis with "Should I fix this?"

## Workflow

Follow the spec-first workflow:
1. **Define** - Discuss requirements, create spec file(s) outlining everything needed
2. **Plan** - Gap analysis, create implementation plan with prioritized tasks
3. **Build** - Implement from plan using TDD, commit, update plan

If project has a `quality-loop` skill or Ralph workflow, those own TDD — don't layer `superpowers:test-driven-development` on top. Use `superpowers:test-driven-development` only for standalone tasks/bug fixes outside a plan.

For multi-step tasks, state each step with its verification check:

```text
1. Step -> verify: check
2. Step -> verify: check
3. Step -> verify: check
```

## Following Templates/References

When working with templates, examples, or reference implementations:
1. Read the ENTIRE template first with Read tool (don't skim)
2. Copy verbatim, only replacing designated placeholders
3. Don't "improve" unless explicitly asked - your improvements often break carefully designed patterns
4. Numbered rules, agent counts, prompt structure = intentionally designed

## Code Quality

**File size**: ~500 lines is a code smell. Break up large files proactively.

**Comments**: Minimal. One line above a function if needed. No docstrings - TypeScript types and readable code are the documentation.

**Security**: Be smart. Don't implement anything that exposes vulnerabilities or violates security best practices. If middleware, validation, or auth checks should exist - add them. Think like an attacker would.

**Scoped changes**: Touch only what the task requires. Match existing style. Do not refactor adjacent code, delete unrelated dead code, or make cosmetic churn unless asked. Every changed line should trace directly to the user's request or to a necessary fix caused by that request.

**Simplicity**: Prefer the smallest correct solution. Avoid speculative abstractions, single-use abstractions, configurability, dependencies, or error handling for impossible scenarios. If a solution starts getting large, stop and check whether it can be made smaller.

**Diagnostic logging**: Any `logger.info` or `console.log` added for investigation must be removed or downgraded to `logger.debug` before committing. Never commit investigation logging at INFO level on hot paths.

**Wiring files** (service containers, module files, factory files): Re-read the edited section before committing to verify module names and property names against actual exported interfaces. These files have no compile-time checks — broken references surface only at runtime.

## Testing

**No mocks** for internal code - test against real databases, real services you control.

**Exception**: Mock paid external services (Stripe, Twilio, etc.) to avoid costs. But test the integration boundaries thoroughly.

Default to unit tests. Promote to integration only when the test REQUIRES a database or cross-service coordination. Unit tests for pure logic, calculations, validation.

Use Result pattern for error handling - explicit success/failure, no exceptions for business logic.

## Commits

Minimal, clean summaries. One line describing what changed. No essays. Never `git add -A` or `git add .` — always stage specific files by name. Before every `git add`, run `git status` to check for unexpected staged files from prior sessions. Run `git diff --cached --stat` before committing to verify every staged file is intentional. Never revert a correct fix based on incomplete re-analysis — fully re-read all affected code before reverting.

## Tooling
- **Stack**: Bun, TypeScript, SvelteKit, Svelte 5, TailwindCSS 4, shadcn-svelte, Drizzle
- Use `bun` for everything — package management, scripts, testing. Never npm/yarn/pnpm.
- Prefer `bun run <script>` over direct tool invocation when a package.json script exists.

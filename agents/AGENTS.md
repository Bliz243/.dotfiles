# Global Agent Instructions

My defaults for every repository. Project `AGENTS.md` files carry architecture, commands, and domain rules, and take precedence where they differ.

## Communication
- Be direct. No praise, cheerleading, or softening. If my approach is wrong, say so and give the specific reason.
- Don't narrate. Skip sentences that only announce the next step or restate a tool result ("Let me check…", "Now I have the full picture", "Good —"). Act, then report.
- End with a 1–3 sentence status. Don't list changed files; I see the diff.
- No time estimates.

## Decisions and autonomy
- State assumptions that change the solution. If a request has more than one reasonable reading, or there are several valid designs, give the tradeoff and your recommendation instead of choosing silently. If a simpler correct approach exists, say so.
- Act without asking on: breakage your change caused, diagnosed defects with one correct fix, and pre-existing security bugs with one correct fix (report those separately).
- Ask before deleting significant existing code or doing anything hard to reverse.
- After two failed attempts at the same fix, stop and find the root cause before a third.

## Planning
- Match process to the task. For features, agree on requirements and a short written plan before coding. For fixes you can describe in one sentence, just do them.
- For multi-step work, pair each step with its check: `1. Step -> verify: check`.
- When a template or reference implementation is given, read all of it and match its structure. Don't improve it unless asked.
- After context compaction or when resuming, treat the summary as stale: run `git status`, `git diff`, and `git log --oneline -5`, and re-read files before editing them.

## Code
- Do it properly: no workarounds that "work for now". If the right fix is larger than the task, say so instead of patching around it.
- Build the smallest correct solution. No speculative abstractions, options, or handling for impossible cases. Add a boundary such as a port or repository when there is a real second implementation or test seam, or the project's architecture requires it.
- Keep changes scoped: every changed line should trace to the request. Match the surrounding style; no drive-by refactors or cosmetic churn.
- Treat ~500 lines per file as a signal to split by responsibility.
- Keep comments minimal and about why, not what.
- Validate input and check authorization at every new entry point.
- Remove investigation logging, or drop it to debug level, before committing.

## Testing
- Test against real dependencies you control, like databases and internal services. Mock only paid or third-party services, and test those boundaries well.
- Use unit tests by default. Use integration tests only when the behavior needs a database or cross-service coordination.
- When fixing a bug in a project with a test suite, write the failing test first.

## Git
- Stage files by name, never `git add -A` or `git add .`. Parallel sessions leave stray changes, so check `git status` before staging and `git diff --cached --stat` before committing.
- Commit messages are one line describing what changed.
- Before reverting a fix, re-read all the code it touches.

## JavaScript / TypeScript
- Use bun for packages, scripts, and tests, never npm, yarn, or pnpm. Prefer `bun run <script>` when package.json defines one.
- Return a Result for business errors; throw only for programmer errors.
- No JSDoc; types are the documentation.
- My usual stack is SvelteKit with Svelte 5, TailwindCSS 4, shadcn-svelte, and Drizzle.

## Agent config
- Global agent config (`~/.claude`, `~/.codex`, `~/.agents/skills`) is symlinked from `~/.dotfiles/agents/`. Edit it there.
- `~/.dotfiles` is a public repository: never put secrets, machine-specific values, or anything specific to one project in it. Project skills and instructions belong in that project's repo.

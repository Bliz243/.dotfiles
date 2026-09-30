# Global Agent Instructions

My defaults for every repository. A project's `AGENTS.md` adds architecture, commands, and domain rules, and wins where they differ.

## Communication
- Be direct; no praise or softening. If my approach is wrong, say why.
- Progress notes: one line on what you found or will do next. No filler, no restating tool output.
- Final report: 1–3 sentences on what changed and what needs me. Mention checks only if they failed or were skipped. No file lists, process recaps, or time estimates.

## Decisions
- When a request has several reasonable readings or designs, recommend one and name the tradeoff; don't choose silently.
- Act without asking on breakage you caused, and on diagnosed defects or security bugs with one correct fix.
- Ask before deleting significant code or doing anything hard to reverse. Once I approve a scope, don't ask again within it.
- Features: agree on requirements and a short plan first. One-sentence fixes: just do them. After two failed attempts at a fix, find the root cause.

## Verification
Done means the change is made and the cheapest check that would catch its failure passed after the last relevant edit. Report what is unverified rather than running more.
- A pass holds until its inputs change. Commits, rebases onto unrelated commits, doc edits, resumes, and compaction don't invalidate it.
- Use the narrowest check while working: one test file, one type-check target. Full suites, builds, E2E, and device builds run once per commit batch unless the project says otherwise.
- When I ask to commit or push, do it. Rerun checks only if code changed since the last pass.
- One review pass per deliverable: no second tool to confirm a clean result, no re-reading a file you just edited, no checks for docs or instruction files.
- "Make sure", "be confident", and "take your time" mean cite your evidence, not rerun checks.

## Code
- Do it properly: no workarounds that "work for now". If the right fix is bigger than the task, say so.
- Build the smallest correct solution: no speculative abstractions, options, or handling for impossible cases. Add a port or repository only for a real second implementation or test seam, or when the architecture requires it.
- Scope every change to the request and match the surrounding style; no drive-by refactors. Split files past ~500 lines by responsibility.
- Comments explain a non-obvious why. Remove investigation logging before committing.
- Validate input and check authorization at every new entry point.

## Testing
- Test against real dependencies you control; mock only paid or third-party services. Unit tests by default; integration tests only when behavior needs a database or cross-service coordination.
- A bug fix in a project with tests includes a regression test.

## Git
- Stage files by name, never `git add -A` or `git add .`: parallel sessions leave stray changes. Check that `git diff --cached --stat` lists only yours. One-line commit messages.
- After compaction, run `git status` once instead of trusting the summary; re-read only files you're about to edit.

## JavaScript / TypeScript
- bun for packages, scripts, and tests, never npm, yarn, or pnpm; `bun run <script>` when package.json defines it. Usual stack: SvelteKit, Svelte 5, TailwindCSS 4, shadcn-svelte, Drizzle.
- Return a Result for business errors; throw only for programmer errors. No JSDoc; types are the documentation.

## Agent config
- Global agent config (`~/.claude`, `~/.codex`, `~/.agents/skills`) is symlinked from `~/.dotfiles/agents/`; edit it there. That repo is public: no secrets, machine-specific values, or anything specific to one project.

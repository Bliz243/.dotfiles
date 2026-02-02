# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Tech Stack

- **Framework:** SvelteKit 2, Svelte 5 (runes)
- **Database:** PostgreSQL, Prisma ORM
- **Testing:** Vitest (unit/integration), Playwright (E2E)
- **Styling:** Tailwind CSS, shadcn-svelte
- **Package Manager:** bun

## Development Philosophy

**Simple over complex.** Follow existing patterns. When unsure, find a similar implementation and match it.

**Honest over agreeable.** If something seems wrong, raise it with technical reasoning. Don't just agree.

**Before implementing anything:**
1. Check `specs/` for requirements
2. Search codebase for similar patterns
3. Follow reference implementations

## Specifications

**IMPORTANT:** Before implementing any feature, consult the specifications in `specs/README.md`.

- **Assume NOT implemented.** Specs describe intent; code describes reality.
- **Check the codebase first.** Search actual code before concluding something exists or doesn't.
- **Use specs as guidance.** Follow the design patterns and architecture defined in relevant specs.

## Reference Implementations

| Type | Location | Description |
|------|----------|-------------|
| Backend | `{{SOURCE_DIR}}/lib/server/...` | (Add your reference domain) |
| Frontend | `{{SOURCE_DIR}}/lib/features/...` | (Add your reference feature) |

Study these before implementing new code. Match their patterns.

## Commands

### Development
- **Install:** `bun install`
- **Dev server:** `bun run dev`
- **Build:** `bun run build`
- **Preview:** `bun run preview`

### Validation
Run after implementing to get immediate feedback:
- **Tests:** `bun run test`
- **Test (watch):** `bun run test:watch`
- **Typecheck:** `bun run check`
- **Lint:** `bun run lint`
- **Format:** `bun run format`

### Database
- **Generate:** `bunx prisma generate`
- **Migrate (dev):** `bunx prisma migrate dev`
- **Push:** `bunx prisma db push`
- **Studio:** `bunx prisma studio`

## Deployment

(Add deployment instructions as you learn them)

- **Deploy:** `git push origin main`
- **Check status:** (add command)
- **View logs:** (add command)

### Verifying Deployment
1. Check deployed version matches commit
2. Check service restarted
3. Check health endpoint

## Architecture

```
{{SOURCE_DIR}}/
├── lib/
│   ├── server/         # Backend code
│   │   └── domains/    # Domain modules
│   ├── features/       # Frontend features
│   └── components/     # Shared UI components
├── routes/             # SvelteKit routes
└── ...
```

(Expand with your actual structure)

## Svelte 5 (NOT Svelte 4)

**Always use Svelte 5 runes syntax. Never use Svelte 4 patterns.**

| Category | ✅ Svelte 5 | ❌ Svelte 4 (DO NOT USE) |
|----------|-------------|--------------------------|
| **State** | `let count = $state(0);` | `let count = 0;` |
| **Derived** | `const doubled = $derived(count * 2);` | `$: doubled = count * 2;` |
| **Effects** | `$effect(() => { ... });` | `$: { ... }` |
| **Props** | `let { foo, bar } = $props();` | `export let foo;` |
| **Events** | `onclick={handler}` | `on:click={handler}` |
| **Custom events** | Pass callback props: `onsave={fn}` | `createEventDispatcher` |
| **Slots** | `{@render children()}` | `<slot />` |

## Code Quality

**File size:** ~500 lines is a code smell. Break up large files.

**Comments:** Minimal. 1-2 lines max. Explain WHAT or WHY, not HOW. No docstrings.

**Naming:** Names tell WHAT, not HOW.
- ❌ `ZodValidator`, `PrismaRepository`
- ✅ `Validator`, `Repository`

**Security:** Be smart. Don't implement anything that exposes vulnerabilities. If middleware, validation, or auth checks should exist - add them.

## Testing

**No mocks** for internal code - test against real databases, real services you control.

**Exception:** Mock paid external services (Stripe, Twilio, etc.) to avoid costs.

**Result pattern** for error handling - explicit success/failure, no exceptions for business logic.

## Common Pitfalls

(Add gotchas and mistakes to avoid as you discover them)

- ❌ ...
- ❌ ...

## Troubleshooting

### Common Issues

(Add troubleshooting steps as you learn them)

**Issue:** ...
**Solution:** ...

### Logs

- **Server logs:** (add command)
- **Database logs:** (add command)

## Operational Notes

(Add learnings about how to run/debug the project here)

## Development Workflow

1. **Define** - Create specs in `specs/` for new features
2. **Plan** - Run `./loop.sh plan` to generate implementation plan
3. **Build** - Implement with TDD (`superpowers:test-driven-development`)
4. **Review** - Review changes before committing

For UI work, use `ultra-frontend` skill.

## Key Files

| File | Purpose |
|------|---------|
| `specs/README.md` | Specification index and guide |
| `IMPLEMENTATION_PLAN.md` | Current task list |
| `PROMPT_plan.md` | Planning mode prompt |
| `PROMPT_build.md` | Building mode prompt |

## Remember

1. **Specs first** - Check specs before implementing
2. **Search before creating** - Similar code probably exists
3. **Follow references** - Match existing patterns
4. **TDD** - Tests first, then implementation
5. **Keep it simple** - Don't over-engineer

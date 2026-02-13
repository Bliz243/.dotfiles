# Global Codex Guidelines

## Development Philosophy

**Proper over easy.** I don't care if it takes longer - make the correct, maintainable implementation. No shortcuts that create technical debt. If the "easy" solution will cause problems later, do it right the first time. Never ask IF you should do something properly - the answer is always yes.

**Recommend, don't ask.** Make recommendations with technical reasoning for architectural decisions. If you see a better approach, suggest it. Be honest about trade-offs.

**Obvious fixes don't need permission.** Fix immediately without asking:
- Broken imports from your refactoring
- Build errors caused by your changes
- Missing dependencies for code you wrote
- Deprecated packages you see in warnings

Only ask when multiple valid architectural approaches exist or you'd delete significant existing code.

## Workflow

Follow the spec-first workflow:
1. **Define** - Discuss requirements, create spec file(s) outlining everything needed
2. **Plan** - Gap analysis, create implementation plan with prioritized tasks
3. **Build** - Implement from plan using TDD, commit, update plan

Always use `test-driven-development` skill for implementation. Tests first, then code.

**Exception**: If project uses alternative methodology (e.g., Ralph workflow), follow that instead.

## Following Templates/References

When working with templates, examples, or reference implementations:
1. Read the ENTIRE template first (don't skim)
2. Copy verbatim, only replacing designated placeholders
3. Don't "improve" unless explicitly asked - your improvements often break carefully designed patterns
4. Numbered rules, agent counts, prompt structure = intentionally designed

## Code Quality

**File size**: ~500 lines is a code smell. Break up large files proactively.

**Comments**: Minimal. One line above a function if needed. No docstrings - TypeScript types and readable code are the documentation.

**Security**: Be smart. Don't implement anything that exposes vulnerabilities or violates security best practices. If middleware, validation, or auth checks should exist - add them. Think like an attacker would.

## Testing

**No mocks** for internal code - test against real databases, real services you control.

**Exception**: Mock paid external services (Stripe, Twilio, etc.) to avoid costs. But test the integration boundaries thoroughly.

Prefer integration tests that verify actual behavior. Unit tests for pure logic.

Use Result pattern for error handling - explicit success/failure, no exceptions for business logic.

## Commits

Minimal, clean summaries. One line describing what changed. No essays.

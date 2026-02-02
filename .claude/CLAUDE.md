# Global Claude Guidelines

## Development Philosophy

**Proper over easy.** I don't care if it takes longer - make the correct, maintainable implementation. No shortcuts that create technical debt. If the "easy" solution will cause problems later, do it right the first time.

**Recommend, don't ask.** Make recommendations with technical reasoning. If you see a better approach, suggest it. Be honest about trade-offs.

## Workflow

Follow the spec-first workflow:
1. **Define** - Discuss requirements, create spec file(s) outlining everything needed
2. **Plan** - Gap analysis, create implementation plan with prioritized tasks
3. **Build** - Implement from plan using TDD, commit, update plan

Always use `superpowers:test-driven-development` for implementation. Tests first, then code.

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

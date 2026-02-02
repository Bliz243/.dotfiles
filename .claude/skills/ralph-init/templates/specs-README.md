# Specifications

This directory contains specs for the project. Each spec covers one **topic of concern**.

## Writing Good Specs

**One topic per spec.** Use the "one sentence without and" test:
- ✅ "The authentication system handles user login and session management"
- ❌ "The user system handles authentication, profiles, and billing" → 3 specs

**Include:**
- Purpose and context
- Requirements (what it must do)
- Acceptance criteria (how we know it's done)
- Edge cases and error handling
- Dependencies on other specs (if any)

**Keep specs focused on WHAT, not HOW.** Implementation details belong in code.

## Spec Template

```markdown
# [Topic Name]

## Purpose
Brief description of what this covers and why it exists.

## Requirements
- Requirement 1
- Requirement 2

## Acceptance Criteria
- [ ] Criterion 1 (testable)
- [ ] Criterion 2 (testable)

## Edge Cases
- What happens when X?
- What happens when Y?

## Dependencies
- Depends on: [other-spec.md] (if any)
```

## Index

| Spec | Purpose |
|------|---------|
| | |

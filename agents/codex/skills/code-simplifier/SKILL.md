---
name: code-simplifier
description: Simplifies recently changed code for clarity and consistency without changing behavior. Use when asked to simplify, clean up, or tidy code.
---

Simplify the code changed in this session (or the scope the user names) without changing what it does.

- Follow the project's `AGENTS.md` and the style of the surrounding code; don't impose other conventions.
- Remove unnecessary nesting, indirection, duplication, dead code, and comments that restate the code.
- Prefer explicit code over clever one-liners; replace nested ternaries with `if`/`else` or `switch`.
- Keep abstractions that separate real concerns; don't merge unrelated logic to save lines.
- Leave untouched code alone, and don't rename or reorder things just for taste.
- Run the narrowest check that covers the edited code once at the end, and list what you changed in one or two sentences.

# Claude Code Hooks Architecture Review

Last Updated: 2026-02-03

## Executive Summary

The hooks architecture demonstrates solid foundational design with config-driven extensibility and appropriate fail-safe behaviors. However, there are meaningful opportunities to improve separation of concerns and reduce implicit coupling between modules that communicate via filesystem state.

**Overall Assessment:** Well-structured but with architectural debt in cross-module coordination.

---

## Architecture Overview

```
settings.json                    # Hook configuration
    |
    +-- statusline.js            # Display (reads state)
    |       |
    +-- hooks/command-guard.js   # PreToolUse: blocks dangerous commands (writes state)
    |       |
    +-- hooks/skill-monitor.js   # UserPromptSubmit: skill activation, bypass, warnings
            |
    +-- lib/shared.js            # Constants and utilities
    |
    +-- config/skill-rules.json  # Declarative skill triggers
```

**State Files (implicit coupling):**
- `~/.claude/state/guard-bypass` - Written by skill-monitor, consumed by command-guard
- `~/.claude/state/last-blocked.json` - Written by command-guard, read by statusline
- `<project>/.claude/state/session-warnings.json` - Written/read by skill-monitor only

---

## Critical Issues

None identified. The architecture is sound and secure.

---

## Important Improvements

### 1. Duplicated State Path Definitions (Tight Coupling)

**Files affected:** `/home/jacob/.dotfiles/.claude/hooks/command-guard.js`, `/home/jacob/.dotfiles/.claude/hooks/skill-monitor.js`, `/home/jacob/.dotfiles/.claude/statusline.js`

Three files independently define the same state paths:

```javascript
// command-guard.js (lines 40-42)
const stateDir = path.join(os.homedir(), '.claude', 'state');
const bypassTokenPath = path.join(stateDir, 'guard-bypass');
const lastBlockedPath = path.join(stateDir, 'last-blocked.json');

// skill-monitor.js (lines 50-52)
const stateDir = path.join(homeDir, '.claude', 'state');
const bypassTokenPath = path.join(stateDir, 'guard-bypass');
const lastBlockedPath = path.join(stateDir, 'last-blocked.json');

// statusline.js (line 66)
const blockedPath = path.join(os.homedir(), '.claude', 'state', 'last-blocked.json');
```

**Risk:** Changing a path in one file but not others breaks the implicit contract silently.

**Recommendation:** Consolidate into `lib/shared.js`:

```javascript
const STATE_PATHS = {
  dir: path.join(os.homedir(), '.claude', 'state'),
  bypass: path.join(os.homedir(), '.claude', 'state', 'guard-bypass'),
  lastBlocked: path.join(os.homedir(), '.claude', 'state', 'last-blocked.json')
};
```

### 2. Duplicated TTL Constant

**File:** `/home/jacob/.dotfiles/.claude/hooks/command-guard.js`

`command-guard.js` defines its own `BYPASS_TTL_MS = 30000` (line 45) despite `shared.js` already exporting this constant.

```javascript
// command-guard.js line 45
const BYPASS_TTL_MS = 30000;

// shared.js line 12
const BYPASS_TTL_MS = 30000;
```

**Recommendation:** Import from shared.js to maintain single source of truth.

### 3. Bypass Token Handling Belongs Elsewhere

**File:** `/home/jacob/.dotfiles/.claude/hooks/skill-monitor.js` (lines 48-70)

The bypass token creation logic in `skill-monitor.js` is conceptually wrong:

- "Skill Monitor" suggests monitoring skill activations
- Bypass token handling is about command-guard coordination
- This creates hidden coupling between two hooks

**Recommendation:** Either:
1. Move bypass handling to `lib/shared.js` as a utility (preferred)
2. Create `lib/bypass.js` for cross-hook coordination
3. Document clearly why it lives in skill-monitor (if there's a good reason)

### 4. skill-monitor.js Has Too Many Responsibilities (~300 lines, 6+ concerns)

**File:** `/home/jacob/.dotfiles/.claude/hooks/skill-monitor.js`

Current responsibilities:
1. Bypass token creation (lines 48-70)
2. Config loading and merging (lines 72-103)
3. Skill matching logic (lines 105-148)
4. Skill output generation (lines 150-208)
5. Token monitoring with warnings (lines 210-288)
6. Session warning state management (lines 212-230)

This violates single-responsibility principle. While the file isn't huge, the mental model required to understand it is complex.

**Recommendation:** Consider splitting:
- Bypass handling -> `lib/shared.js` or `lib/bypass.js`
- Skill matching/output -> keep in skill-monitor.js (its core purpose)
- Token monitoring -> could be separate hook or embedded module

### 5. Inconsistent State Storage Location

**Files:** `/home/jacob/.dotfiles/.claude/hooks/skill-monitor.js`

Session warnings stored in project directory:
```javascript
const statePath = path.join(projectDir, '.claude/state/session-warnings.json');
```

But bypass/blocked state stored in home directory:
```javascript
const stateDir = path.join(homeDir, '.claude', 'state');
```

**Why this matters:** Session state tied to transcript_path but stored relative to project. If the project changes during a session, the warning state becomes orphaned.

**Recommendation:** Either:
1. All session state in home directory (consistent)
2. Document the intentional split and reasoning

---

## Minor Suggestions

### 1. Inconsistent Bypass Token Storage

The bypass token writes content (`Date.now()`) but checks validity via file mtime:

```javascript
// skill-monitor.js writes content
fs.writeFileSync(bypassTokenPath, String(Date.now()));

// command-guard.js checks mtime
const stat = fs.statSync(bypassTokenPath);
const ageMs = Date.now() - stat.mtimeMs;
```

Both work, but it's inconsistent. The content is ignored.

**Recommendation:** Either use an empty file (touch semantic) or read the content for TTL check.

### 2. Git Command in statusline.js Could Fail Silently

**File:** `/home/jacob/.dotfiles/.claude/statusline.js` (lines 114-120)

The detached HEAD fallback silently catches errors:

```javascript
try {
  result.branch = '@' + execSync('git rev-parse --short HEAD', {...}).trim();
} catch { result.branch = '@detached'; }
```

This is fine for display, but if git is broken, the user gets no indication.

### 3. No State Cleanup Mechanism

State files can accumulate over time:
- `last-blocked.json` stays forever after TTL
- `session-warnings.json` files in old projects never cleaned

**Recommendation:** Consider adding cleanup on hook startup or documenting manual cleanup.

### 4. Missing Documentation of State File Contracts

No documentation exists for:
- What each state file contains
- Who writes vs. reads
- TTL behaviors
- Expected format

**Recommendation:** Add a comment block in `shared.js` or a `STATE.md` file documenting contracts.

---

## Architecture Considerations

### What Works Well

1. **Config-driven skill activation** - Adding skills requires no code changes
2. **Fail-safe defaults** - Commands allowed if parsing/config fails
3. **Early exit patterns** - Hooks exit quickly when not applicable
4. **Environment awareness** - Proper CI/remote machine detection
5. **Single git call** - statusline.js uses `--porcelain=v2` efficiently
6. **Declarative security rules** - command-guard patterns are readable

### What Could Be Better

1. **Implicit coupling** - Three files coordinate via filesystem without explicit contract
2. **Mixed responsibilities** - skill-monitor does too much
3. **Undocumented state flow** - New maintainer won't understand bypass flow

### Data Flow Diagram

```
User types "yert"
    |
    v
skill-monitor.js (UserPromptSubmit)
    |
    +-- Creates ~/.claude/state/guard-bypass
    |
    v
Claude retries command
    |
    v
command-guard.js (PreToolUse)
    |
    +-- Reads guard-bypass, deletes it (one-time)
    +-- Clears last-blocked.json
    |
    v
Command executes
    |
    v
statusline.js
    |
    +-- Reads last-blocked.json (now cleared)
    +-- Shows "No Block"
```

This flow works but is undocumented and spread across 3 files.

---

## Next Steps

1. **Consolidate state paths** into `lib/shared.js`
2. **Remove duplicated BYPASS_TTL_MS** from command-guard.js
3. **Consider moving bypass logic** out of skill-monitor.js
4. **Add state contract documentation** (comment block or STATE.md)
5. **Decide on consistent state location** (home vs project directory)

---

## Files Reviewed

| File | Lines | Assessment |
|------|-------|------------|
| `/home/jacob/.dotfiles/.claude/lib/shared.js` | 88 | Good - could be expanded |
| `/home/jacob/.dotfiles/.claude/statusline.js` | 187 | Good - well-focused |
| `/home/jacob/.dotfiles/.claude/hooks/command-guard.js` | 179 | Good but has duplicated constants |
| `/home/jacob/.dotfiles/.claude/hooks/skill-monitor.js` | 297 | Fair - too many responsibilities |
| `/home/jacob/.dotfiles/.claude/settings.json` | 54 | Good |
| `/home/jacob/.dotfiles/.claude/config/skill-rules.json` | 84 | Good - clean declarative config |

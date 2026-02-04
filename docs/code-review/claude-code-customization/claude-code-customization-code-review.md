# Claude Code Customization Architecture Review

**Last Updated: 2026-02-03**

## Executive Summary

The `.claude/` directory implements a comprehensive customization layer for Claude Code with three main components: a status line, two hooks (command guard and skill monitor), and configuration-driven skill activation. The architecture is generally clean with good separation at the file level, but has some code duplication and one significant gap in the bypass flow.

**Overall Assessment: Good foundation with room for refinement**

---

## Architecture Overview

```
.claude/
  settings.json         # Main config: plugins, permissions, hooks, statusline
  settings.local.json   # Project-specific permission overrides
  CLAUDE.md             # Global instructions for Claude
  statusline.js         # Two-line status display
  hooks/
    command-guard.js    # PreToolUse hook: dangerous command detection
    skill-monitor.js    # UserPromptSubmit hook: skill activation, token monitoring
  config/
    skill-rules.json    # Configuration-driven skill triggers
  state/
    session-warnings.json    # Per-session token warning state
    (last-blocked.json)      # Written by command-guard, read by statusline
    (guard-bypass)           # Token file for "yert" bypass
  agents/
    code-review.md      # Agent definition
  skills/
    */SKILL.md          # Skill definitions
```

### Data Flow

```
settings.json
    |
    +---> hooks/command-guard.js (PreToolUse:Bash)
    |         |
    |         +---> writes: state/last-blocked.json
    |         +---> reads:  state/guard-bypass (bypass token)
    |
    +---> hooks/skill-monitor.js (UserPromptSubmit)
    |         |
    |         +---> reads:  config/skill-rules.json
    |         +---> writes: state/session-warnings.json
    |
    +---> statusline.js
              |
              +---> reads: transcript_path (token usage)
              +---> reads: state/last-blocked.json (block status)
              +---> reads: docs/designs/*.md (active work)
```

---

## Critical Issues

### 1. Incomplete Bypass Flow

**Severity: CRITICAL**

**Location:** `/home/jacob/.dotfiles/.claude/hooks/command-guard.js:165-171`

**Issue:** The "yert" bypass mechanism is incomplete. When a MEDIUM severity command is blocked, the message tells users to "Say 'yert' to proceed", but there is no code anywhere that creates the `~/.claude/state/guard-bypass` token file when the user says "yert".

**Current flow:**
1. User runs command via `ccd` alias (sets CLAUDE_GUARD=1)
2. Guard blocks MEDIUM command, displays "Say 'yert' to proceed"
3. User says "yert"
4. **Nothing happens** - no code creates the bypass token
5. User must manually run: `touch ~/.claude/state/guard-bypass`

**Expected flow:**
1. User says "yert"
2. Some mechanism creates the bypass token
3. Claude retries the command (or user re-requests)
4. Guard sees token, allows command, deletes token

**Recommendation:** Add a skill or hook that:
- Triggers on user saying "yert" (case-insensitive)
- Creates the bypass token file
- Optionally instructs Claude to retry the blocked command

```javascript
// Example: skill-rules.json entry
"yert-bypass": {
  "type": "system",
  "enforcement": "block",
  "promptTriggers": {
    "patterns": ["^\\s*yert\\s*$"]
  },
  "activation": {
    "action": "createBypassToken"
  }
}
```

Or simpler: Add to skill-monitor.js to detect "yert" and create the token.

---

## Important Improvements

### 2. Code Duplication: Active Work Detection

**Severity: IMPORTANT**

**Locations:**
- `/home/jacob/.dotfiles/.claude/statusline.js:107-134` (`getActiveWork`)
- `/home/jacob/.dotfiles/.claude/hooks/skill-monitor.js:180-207` (`getActiveWork`)

**Issue:** Nearly identical functions in both files for detecting active design docs and ad-hoc work. Changes must be made in two places.

**Recommendation:** Extract to a shared utility module:

```javascript
// .claude/lib/active-work.js
module.exports = function getActiveWork(projectDir) {
  // ... shared implementation
};
```

### 3. Code Duplication: Token Parsing

**Severity: IMPORTANT**

**Locations:**
- `/home/jacob/.dotfiles/.claude/statusline.js:42-67` (`getContextUsage`)
- `/home/jacob/.dotfiles/.claude/hooks/skill-monitor.js:210-231` (`getTokenUsage`)

**Issue:** Nearly identical logic for parsing transcript files and extracting token usage. The only difference is return value (null vs 0 when no data).

**Recommendation:** Extract to shared module with consistent interface.

### 4. Hardcoded Constants

**Severity: IMPORTANT**

**Locations:**
- `/home/jacob/.dotfiles/.claude/statusline.js:27` (`CONTEXT_LIMIT = 160000`)
- `/home/jacob/.dotfiles/.claude/hooks/skill-monitor.js:274` (`const limit = 160000`)

**Issue:** Magic number duplicated. If context limit changes, must update multiple files.

**Recommendation:** Create a shared constants file or config:

```javascript
// .claude/lib/constants.js
module.exports = {
  CONTEXT_LIMIT: 160000,
  BLOCKED_TTL_MS: 30000,
  BYPASS_TTL_MS: 30000
};
```

### 5. skill-monitor.js Does Too Much

**Severity: IMPORTANT**

**Location:** `/home/jacob/.dotfiles/.claude/hooks/skill-monitor.js`

**Issue:** This 319-line file handles four distinct responsibilities:
1. Ultrathink injection (line 255)
2. Skill activation from config (lines 75-177)
3. Session orientation/active work detection (lines 179-270)
4. Token monitoring with tiered warnings (lines 272-310)

This violates single responsibility and makes the file harder to maintain.

**Recommendation:** Consider one of:

**Option A - Composition pattern:**
```javascript
// skill-monitor.js becomes orchestrator
const ultrathink = require('./hooks/lib/ultrathink');
const skillActivation = require('./hooks/lib/skill-activation');
const sessionOrientation = require('./hooks/lib/session-orientation');
const tokenMonitor = require('./hooks/lib/token-monitor');

let context = ultrathink.inject();
context += skillActivation.process(prompt, config);
context += sessionOrientation.detect(projectDir);
context += tokenMonitor.check(transcriptPath);
```

**Option B - Multiple hooks:**
Register separate hooks in settings.json for each responsibility. This is more modular but adds overhead.

I recommend Option A for now.

---

## Minor Suggestions

### 6. State Directory Path Consistency

**Severity: MINOR**

**Issue:** State paths are constructed differently:
- `command-guard.js`: `path.join(os.homedir(), '.claude', 'state', ...)`
- `skill-monitor.js`: `path.join(projectDir, '.claude/state', ...)`

The first is global (~/.claude), the second is project-local. This is intentional but could be clearer.

**Recommendation:** Add comments clarifying the distinction, or use named constants:
```javascript
const GLOBAL_STATE_DIR = path.join(os.homedir(), '.claude', 'state');
const PROJECT_STATE_DIR = path.join(projectDir, '.claude', 'state');
```

### 7. Silent Error Handling

**Severity: MINOR**

**Locations:** Multiple empty catch blocks throughout all files.

**Issue:** While silent failures are appropriate for hooks (don't break the workflow), debugging becomes difficult.

**Recommendation:** Consider optional debug logging when `DEBUG=1` or similar:
```javascript
} catch (e) {
  if (process.env.CLAUDE_DEBUG) console.error('getActiveWork:', e.message);
}
```

### 8. Regex Pattern Maintainability

**Severity: MINOR**

**Location:** `/home/jacob/.dotfiles/.claude/hooks/command-guard.js:85-151`

**Issue:** Some regex patterns are complex and hard to read at a glance. The rm pattern on line 87 is particularly dense.

**Recommendation:** Add inline comments for complex patterns:
```javascript
// Matches rm with both recursive (-r/-R/--recursive) AND force (-f/--force) flags
{ pattern: /rm\s+(-[rRfF]{2,}|(?=.*(-r|-R|--recursive))(?=.*(-f|--force)))/i, ... }
```

### 9. Missing Tests

**Severity: MINOR**

**Issue:** No test files for any of the hooks or statusline. These are critical security/workflow components.

**Recommendation:** Add basic tests, even if just integration tests that verify:
- command-guard blocks expected patterns
- command-guard allows safe commands
- skill-monitor produces valid JSON output
- statusline handles missing data gracefully

---

## Architecture Considerations

### What Works Well

1. **Configuration-driven skill activation** - Adding new skills requires only JSON changes, no code modifications to skill-monitor.js.

2. **Clean hook interface** - JSON in, JSON out. Easy to understand and test.

3. **Layered configuration** - Global settings.json + local settings.local.json is a good pattern.

4. **Two-tier severity** - HIGH (block completely) vs MEDIUM (bypassable) is practical.

5. **TTL-based state** - Using file mtime for bypass tokens and blocked state aging is simple and effective.

6. **CI skip** - Properly skips hooks in CI environments.

### Potential Future Improvements

1. **Structured logging** - A simple logger that can be enabled for debugging hooks.

2. **Hook composition** - Framework for composing multiple small hooks rather than one large one.

3. **State manager** - Centralized state management instead of ad-hoc file reads/writes.

4. **Schema validation** - Validate skill-rules.json structure on load.

---

## Summary of Recommendations

| Priority | Issue | Effort |
|----------|-------|--------|
| CRITICAL | Complete bypass flow ("yert" token creation) | Low |
| IMPORTANT | Extract shared utilities (active work, token parsing) | Medium |
| IMPORTANT | Centralize constants | Low |
| IMPORTANT | Consider splitting skill-monitor.js | Medium |
| MINOR | Add debug logging option | Low |
| MINOR | Add basic tests | Medium |
| MINOR | Document regex patterns | Low |

---

## Next Steps

Please review the findings and approve which changes to implement before I proceed with any fixes.

The most impactful quick wins would be:
1. Fixing the bypass flow (critical for usability)
2. Extracting shared utilities (reduces maintenance burden)
3. Adding a constants file (low effort, high value)

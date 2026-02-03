#!/usr/bin/env node
/**
 * command-guard.js - Dangerous command confirmation
 *
 * Runs on PreToolUse for Bash tool.
 * Catches dangerous patterns before execution when using --dangerously-skip-permissions.
 * Based on cc-safe patterns: https://github.com/anthropics/cc-safe
 */

const fs = require('fs');
const { getStatePaths } = require('../lib/shared');

// Only run guard when CLAUDE_GUARD=1 (set by ccd alias for --dangerously-skip-permissions)
// Skip on remote machines (disposable VPS)
if (process.env.CLAUDE_GUARD !== '1' || process.env.MACHINE_TYPE === 'remote') {
  console.log(JSON.stringify({ decision: "allow" }));
  process.exit(0);
}

let input = {};
try {
  input = JSON.parse(fs.readFileSync(0, 'utf8'));
} catch (e) {
  console.log(JSON.stringify({ decision: "allow" }));
  process.exit(0);
}

const tool = input.tool_name || '';
const toolInput = input.tool_input || {};

if (tool !== 'Bash') {
  console.log(JSON.stringify({ decision: "allow" }));
  process.exit(0);
}

const command = toolInput.command || '';

// Session-scoped state paths (prevents cross-worktree bypass leakage)
const { stateDir, bypassTokenPath, lastBlockedPath } = getStatePaths();

// Bypass token validity
const BYPASS_TTL_MS = 30000;

// Check if valid bypass token exists (doesn't consume it)
function hasValidBypassToken() {
  try {
    const stat = fs.statSync(bypassTokenPath);
    return (Date.now() - stat.mtimeMs) < BYPASS_TTL_MS;
  } catch (e) {
    return false;
  }
}

// Consume bypass token (one-time use)
function consumeBypassToken() {
  try { fs.unlinkSync(bypassTokenPath); } catch (e) {}
  try { fs.unlinkSync(lastBlockedPath); } catch (e) {}
}

// Helper to write blocked state for statusline
function writeBlockedState(severity, label, cmd) {
  try {
    fs.mkdirSync(stateDir, { recursive: true });
    fs.writeFileSync(lastBlockedPath, JSON.stringify({
      severity,
      label,
      command: cmd.substring(0, 100),
      timestamp: Date.now()
    }));
  } catch (e) {}
}

// Commands inside containers are generally safe
const isContainerCommand = /^(docker|podman|kubectl)\s+(exec|run)\s/.test(command) &&
  !/--privileged/.test(command) &&
  !/-v\s+\/:\//i.test(command);

if (isContainerCommand) {
  console.log(JSON.stringify({ decision: "allow" }));
  process.exit(0);
}

// HIGH severity - critical security risks
const highPatterns = [
  // File destruction - recursive + force is critical
  { pattern: /rm\s+(-[rRfF]{2,}|(?=.*(-r|-R|--recursive))(?=.*(-f|--force)))/i, label: "recursive force delete" },

  // Permission disasters
  { pattern: /chmod\s+777/i, label: "world-writable permissions" },
  { pattern: /chmod\s+(-R|--recursive)/i, label: "recursive permission change" },

  // Remote code execution - pipes to shell/interpreters
  { pattern: /curl\s+.*\|\s*(\w*sh|python|perl|ruby|node)\b/i, label: "curl pipe to shell" },
  { pattern: /wget\s+.*\|\s*(\w*sh|python|perl|ruby|node)\b/i, label: "wget pipe to shell" },

  // Shell -c execution (can hide dangerous commands)
  { pattern: /\b(bash|sh|zsh|dash)\s+-c\s/i, label: "shell -c execution" },

  // Disk destruction
  { pattern: /\bdd\s+if=/i, label: "raw disk operation" },
  { pattern: /\bmkfs\b/i, label: "filesystem format" },
  { pattern: /\bfdisk\b/i, label: "disk partitioning" },
  { pattern: />\s*\/dev\/sd/i, label: "direct device write" },

  // Git history destruction
  { pattern: /git\s+push\s+.*--force(?!-with-lease)/i, label: "force push" },
  { pattern: /git\s+push\s+-f\b/i, label: "force push" },

  // Database destruction
  { pattern: /DROP\s+(DATABASE|SCHEMA|TABLE)/i, label: "SQL DROP" },
  { pattern: /TRUNCATE\s+(TABLE\s+)?\w/i, label: "SQL TRUNCATE" },
  { pattern: /DELETE\s+FROM\s+\w+\s*(;|$)/i, label: "DELETE without WHERE" },

  // Dangerous find/xargs patterns
  { pattern: /find\s+.*-delete/i, label: "find -delete" },
  { pattern: /xargs\s+.*rm\s/i, label: "xargs rm" },
];

// MEDIUM severity - potentially dangerous but bypassable
const mediumPatterns = [
  // Force delete (non-recursive)
  { pattern: /rm\s+.*(-f|--force)/i, label: "force delete" },

  // Git dangers
  { pattern: /git\s+reset\s+--hard/i, label: "hard reset" },
  { pattern: /git\s+clean\s+-[fd]{2,}/i, label: "git clean force" },
  { pattern: /git\s+push\s+.*--force-with-lease/i, label: "force push (with lease)" },

  // Package publishing (accidental publish)
  { pattern: /npm\s+publish/i, label: "npm publish" },
  { pattern: /yarn\s+publish/i, label: "yarn publish" },
  { pattern: /pnpm\s+publish/i, label: "pnpm publish" },
  { pattern: /twine\s+upload/i, label: "PyPI publish" },
  { pattern: /gem\s+push/i, label: "RubyGems publish" },
  { pattern: /cargo\s+publish/i, label: "crates.io publish" },

  // Container escapes
  { pattern: /docker\s+run\s+.*--privileged/i, label: "privileged container" },
  { pattern: /docker\s+run\s+.*-v\s+\/:\//i, label: "root mount container" },

  // Code injection
  { pattern: /\beval\s+/i, label: "eval execution" },

  // Sudo with dangerous commands
  { pattern: /sudo\s+rm/i, label: "sudo rm" },
  { pattern: /sudo\s+chmod/i, label: "sudo chmod" },
  { pattern: /sudo\s+chown\s+-R/i, label: "sudo recursive chown" },
  { pattern: /sudo\s+dd\b/i, label: "sudo dd" },
  { pattern: /sudo\s+mkfs/i, label: "sudo mkfs" },
];

// Check HIGH severity - bypassable with "yert"
for (const { pattern, label } of highPatterns) {
  if (pattern.test(command)) {
    if (hasValidBypassToken()) {
      consumeBypassToken();
      console.log(JSON.stringify({ decision: "allow" }));
      process.exit(0);
    }
    writeBlockedState('HIGH', label, command);
    console.log(JSON.stringify({
      decision: "block",
      message: `[HIGH] Blocked: ${label}\n\nCommand: ${command}\n\nSay "yert" to proceed.`
    }));
    process.exit(0);
  }
}

// Check MEDIUM severity - bypassable with "yert"
for (const { pattern, label } of mediumPatterns) {
  if (pattern.test(command)) {
    if (hasValidBypassToken()) {
      consumeBypassToken();
      console.log(JSON.stringify({ decision: "allow" }));
      process.exit(0);
    }
    writeBlockedState('MEDIUM', label, command);
    console.log(JSON.stringify({
      decision: "block",
      message: `[MEDIUM] Blocked: ${label}\n\nCommand: ${command}\n\nSay "yert" to proceed.`
    }));
    process.exit(0);
  }
}

// Allow everything else
console.log(JSON.stringify({ decision: "allow" }));

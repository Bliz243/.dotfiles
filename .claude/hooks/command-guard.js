#!/usr/bin/env node
/**
 * command-guard.js - Dangerous command confirmation
 *
 * Runs on PreToolUse for Bash tool.
 * Catches dangerous patterns before execution when using --dangerously-skip-permissions.
 * Based on cc-safe patterns: https://github.com/anthropics/cc-safe
 */

const fs = require('fs');

// Skip all checks on remote machines (disposable VPS, etc.)
// Or when user explicitly says "bypass" to override a block
if (process.env.MACHINE_TYPE === 'remote' || process.env.GUARD_BYPASS === '1') {
  console.log(JSON.stringify({ decision: "allow" }));
  process.exit(0);
}

let input = {};
try {
  input = JSON.parse(fs.readFileSync(0, 'utf-8'));
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
  // File destruction - recursive + force is critical (blocks rm -rf, rm -r -f, etc.)
  { pattern: /rm\s+(-[rRfF]{2,}|(?=.*(-r|-R|--recursive))(?=.*(-f|--force)))/i, label: "recursive force delete" },

  // Permission disasters
  { pattern: /chmod\s+777/i, label: "world-writable permissions" },
  { pattern: /chmod\s+(-R|--recursive)/i, label: "recursive permission change" },

  // Remote code execution - catch sh, bash, zsh, dash, ksh, fish, and interpreters
  { pattern: /curl\s+.*\|\s*(\w*sh|python|perl|ruby|node)\b/i, label: "curl pipe to shell" },
  { pattern: /wget\s+.*\|\s*(\w*sh|python|perl|ruby|node)\b/i, label: "wget pipe to shell" },

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
  { pattern: /DELETE\s+FROM\s+\S+\s*(;|$)/i, label: "DELETE without WHERE" },
];

// MEDIUM severity - potentially dangerous
const mediumPatterns = [
  // Force delete (non-recursive) - common in scripts but worth confirming
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

// Check HIGH severity (block - run manually if needed)
for (const { pattern, label } of highPatterns) {
  if (pattern.test(command)) {
    console.log(JSON.stringify({
      decision: "block",
      message: `[HIGH] Blocked: ${label}\n\nCommand: ${command}\n\nRun manually if intentional.`
    }));
    process.exit(0);
  }
}

// Check MEDIUM severity (block - say "bypass" to proceed)
for (const { pattern, label } of mediumPatterns) {
  if (pattern.test(command)) {
    console.log(JSON.stringify({
      decision: "block",
      message: `[MEDIUM] Blocked: ${label}\n\nCommand: ${command}\n\nSay "bypass" to proceed.`
    }));
    process.exit(0);
  }
}

// Allow everything else
console.log(JSON.stringify({ decision: "allow" }));

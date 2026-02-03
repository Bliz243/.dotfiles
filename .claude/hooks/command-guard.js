#!/usr/bin/env node
/**
 * command-guard.js - Dangerous command confirmation
 *
 * Runs on PreToolUse for Bash tool.
 * Catches dangerous patterns before execution when using --dangerously-skip-permissions.
 * Based on cc-safe patterns: https://github.com/anthropics/cc-safe
 */

const fs = require('fs');
const path = require('path');
const { getStatePaths } = require('../lib/shared');

// Bypass token validity - 30 seconds gives user time to retry without rushing
const BYPASS_TTL_MS = 30000;

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

  // Process substitution to shell (bypasses pipe detection)
  { pattern: /\b(bash|sh|zsh|dash|source)\s+<\s*\(\s*(curl|wget)\b/i, label: "process substitution to shell" },
  { pattern: /(?:^|\s)\.\s+<\s*\(\s*(curl|wget)\b/i, label: "dot-source process substitution" },

  // Shell -c execution (can hide dangerous commands)
  { pattern: /\b(bash|sh|zsh|dash)\s+-c\s/i, label: "shell -c execution" },

  // Disk destruction
  { pattern: /\bdd\s+if=/i, label: "raw disk operation" },
  { pattern: /\bmkfs\b/i, label: "filesystem format" },
  { pattern: /\bfdisk\b/i, label: "disk partitioning" },
  { pattern: />\s*\/dev\/sd/i, label: "direct device write" },

  // Git history destruction (force push without lease)
  { pattern: /git\s+push\b.*\s--force(?!-with-lease)\b/i, label: "force push" },
  { pattern: /git\s+push\b.*\s-[a-zA-Z]*f/i, label: "force push" },

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

  // Container escapes (any runtime)
  { pattern: /(docker|podman|nerdctl)\s+run\s+.*--privileged/i, label: "privileged container" },
  { pattern: /(docker|podman|nerdctl)\s+run\s+.*-v\s+\/:\//i, label: "root mount container" },
  { pattern: /(docker|podman|nerdctl)\s+run\s+.*--cap-add[=\s]+(SYS_ADMIN|ALL)/i, label: "dangerous capabilities" },
  { pattern: /(docker|podman|nerdctl)\s+run\s+.*--security-opt[=\s]+(seccomp[=:]unconfined|apparmor[=:]unconfined)/i, label: "disabled security" },

  // Code injection
  { pattern: /\beval\s+/i, label: "eval execution" },

  // Sudo with dangerous commands
  { pattern: /sudo\s+rm/i, label: "sudo rm" },
  { pattern: /sudo\s+chmod/i, label: "sudo chmod" },
  { pattern: /sudo\s+chown\s+-R/i, label: "sudo recursive chown" },
  { pattern: /sudo\s+dd\b/i, label: "sudo dd" },
  { pattern: /sudo\s+mkfs/i, label: "sudo mkfs" },
];

// Export patterns for testing
module.exports = { highPatterns, mediumPatterns };

// Only run guard logic when executed directly (not when required for testing)
if (require.main === module) {
  runGuard();
}

function runGuard() {
  // Global error handler - fail open to avoid blocking user
  process.on('uncaughtException', () => {
    console.log(JSON.stringify({ decision: "allow" }));
    process.exit(0);
  });

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

  /**
   * Atomically consume bypass token if valid.
   * Uses rename to prevent TOCTOU race conditions - if two processes try to consume,
   * only one rename will succeed.
   */
  function tryConsumeBypassToken() {
    const consumedPath = path.join(stateDir, `consumed-${Date.now()}-${process.pid}`);
    try {
      // Atomic rename - only one process can succeed
      fs.renameSync(bypassTokenPath, consumedPath);

      // Check if token was still valid (within TTL)
      const stat = fs.statSync(consumedPath);
      const isValid = (Date.now() - stat.mtimeMs) < BYPASS_TTL_MS;

      // Clean up consumed token and blocked state
      try { fs.unlinkSync(consumedPath); } catch (e) {}
      if (isValid) {
        try { fs.unlinkSync(lastBlockedPath); } catch (e) {}
      }

      return isValid;
    } catch (e) {
      // ENOENT = token doesn't exist or already consumed by another process
      return false;
    }
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

  // Commands inside containers are generally safe (unless using escape vectors)
  const containerCmdMatch = /^(docker|podman|kubectl|nerdctl|crictl)\s+(exec|run)\s/.test(command);
  const hasEscapeVector = /--privileged/.test(command) ||
    /-v\s+\/:\//i.test(command) ||
    /--cap-add[=\s]+(SYS_ADMIN|ALL)/i.test(command) ||
    /--security-opt[=\s]+(seccomp[=:]unconfined|apparmor[=:]unconfined)/i.test(command);
  const isContainerCommand = containerCmdMatch && !hasEscapeVector;

  if (isContainerCommand) {
    console.log(JSON.stringify({ decision: "allow" }));
    process.exit(0);
  }

  /**
   * Check command against pattern list and handle blocking/bypass
   */
  function checkPatterns(patterns, severity) {
    for (const { pattern, label } of patterns) {
      if (pattern.test(command)) {
        if (tryConsumeBypassToken()) {
          console.log(JSON.stringify({ decision: "allow" }));
          process.exit(0);
        }
        writeBlockedState(severity, label, command);
        console.log(JSON.stringify({
          decision: "block",
          message: `[${severity}] Blocked: ${label}\n\nCommand: ${command}\n\nSay "yert" to proceed.`
        }));
        process.exit(0);
      }
    }
  }

  // Check patterns in order of severity
  checkPatterns(highPatterns, 'HIGH');
  checkPatterns(mediumPatterns, 'MEDIUM');

  // Allow everything else
  console.log(JSON.stringify({ decision: "allow" }));
}

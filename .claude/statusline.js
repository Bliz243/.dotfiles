#!/usr/bin/env node
/**
 * statusline.js - Status line for Claude Code
 *
 * Single line: Context | Block | Git info
 * Claude Code only uses the FIRST line of stdout
 */

const fs = require('fs');
const { execSync } = require('child_process');

const { getStatePaths, getActiveWork } = require('./lib/shared');

// How long to show "Blocked" status after a command is blocked (matches bypass TTL)
const BLOCKED_TTL_MS = 30000;

// ANSI colors
const colors = {
  green: '\x1b[38;5;114m',
  orange: '\x1b[38;5;215m',
  red: '\x1b[38;5;203m',
  gray: '\x1b[38;5;242m',
  lGray: '\x1b[38;5;250m',
  purple: '\x1b[38;5;183m',
  reset: '\x1b[0m'
};

// Read stdin JSON from Claude Code
let data = {};
try {
  data = JSON.parse(fs.readFileSync(0, 'utf8'));
} catch {
  data = {};
}

const cwd = data.cwd || data.workspace?.current_dir || process.cwd();

// ===== CONTEXT USAGE (using Claude Code's provided data) =====
function formatContextBar(contextWindow) {
  // Use Claude's pre-calculated percentage (accounts for system prompts, caching, etc.)
  const pct = contextWindow?.used_percentage ?? 0;
  const pctInt = Math.min(Math.floor(pct), 100);

  const filled = Math.min(Math.floor(pctInt / 10), 10);
  const empty = 10 - filled;

  let barColor = colors.green;
  if (pctInt >= 80) barColor = colors.red;
  else if (pctInt >= 50) barColor = colors.orange;

  return `${barColor}${'█'.repeat(filled)}${colors.gray}${'░'.repeat(empty)}${colors.reset} ` +
         `${colors.lGray}${pct.toFixed(0)}%${colors.reset}`;
}

// ===== BLOCKED STATE =====
// Guard is only active when CLAUDE_GUARD=1 and not on remote machines
function isGuardActive() {
  return process.env.CLAUDE_GUARD === '1' && process.env.MACHINE_TYPE !== 'remote';
}

function getBlockedState(projectDir) {
  if (!isGuardActive()) return null;

  const { lastBlockedPath } = getStatePaths(projectDir);
  try {
    const content = JSON.parse(fs.readFileSync(lastBlockedPath, 'utf8'));
    if (typeof content.timestamp !== 'number') return null;
    if (Date.now() - content.timestamp < BLOCKED_TTL_MS) return content;
  } catch { /* ignore */ }
  return null;
}

// ===== GIT INFO (single process call) =====
function getGitInfo(dir) {
  const result = { branch: null, ahead: 0, behind: 0, uncommitted: 0 };

  try {
    const output = execSync('git status --porcelain=v2 -b', {
      cwd: dir,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    });

    for (const line of output.split('\n')) {
      if (line.startsWith('# branch.head ')) {
        result.branch = line.slice(14);
        if (result.branch === '(detached)') {
          try {
            result.branch = '@' + execSync('git rev-parse --short HEAD', {
              cwd: dir, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe']
            }).trim();
          } catch { result.branch = '@detached'; }
        }
      } else if (line.startsWith('# branch.ab ')) {
        const match = line.match(/\+(\d+) -(\d+)/);
        if (match) {
          result.ahead = parseInt(match[1], 10);
          result.behind = parseInt(match[2], 10);
        }
      } else if (line.startsWith('1 ') || line.startsWith('2 ') || line.startsWith('? ')) {
        result.uncommitted++;
      }
    }
  } catch { /* Not a git repo */ }

  return result;
}

// ===== MAIN =====
function main() {
  const parts = [];

  // Context bar (using Claude Code's provided context_window data)
  parts.push(formatContextBar(data.context_window));

  // Guard status (only show when guard is active)
  if (isGuardActive()) {
    const blocked = getBlockedState(cwd);
    if (blocked) {
      parts.push(`${colors.red}Blocked${colors.reset}`);
    } else {
      parts.push(`${colors.green}OK${colors.reset}`);
    }
  }

  // Git info
  const git = getGitInfo(cwd);
  if (git.branch) {
    let gitStr = `${colors.lGray}${git.branch}${colors.reset}`;
    if (git.uncommitted > 0) {
      gitStr += `${colors.orange} +${git.uncommitted}${colors.reset}`;
    }
    if (git.ahead > 0) gitStr += `${colors.orange} ↑${git.ahead}${colors.reset}`;
    if (git.behind > 0) gitStr += `${colors.orange} ↓${git.behind}${colors.reset}`;
    parts.push(gitStr);
  }

  // Active work (compact)
  const activeWork = getActiveWork(cwd);
  if (activeWork.designDoc) {
    parts.push(`${colors.purple}${activeWork.designDoc}${colors.reset}`);
  } else if (activeWork.adHoc) {
    parts.push(`${colors.purple}ad-hoc${colors.reset}`);
  }

  // Single line output - Claude Code only uses first line
  console.log(parts.join(' | '));
}

main();

#!/usr/bin/env node
/**
 * statusline.js - Status line for Claude Code
 *
 * Line 1: Context usage | Block status | Active work
 * Line 2: Uncommitted files | Upstream status | Git branch
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

const {
  CONTEXT_LIMIT,
  getStatePaths,
  getTokenUsage,
  getActiveWork
} = require('./lib/shared');

// Local constants (only used by statusline)
const CONTEXT_MIN_DISPLAY = 17000;
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

// Read stdin
let data = {};
try {
  data = JSON.parse(fs.readFileSync(0, 'utf8'));
} catch {
  data = {};
}

const cwd = data.cwd || process.cwd();
const transcriptPath = data.transcript_path || null;

// ===== CONTEXT USAGE =====
function formatContextBar(tokens) {
  const displayTokens = tokens && tokens > CONTEXT_MIN_DISPLAY ? tokens : CONTEXT_MIN_DISPLAY;
  const pct = (displayTokens / CONTEXT_LIMIT) * 100;
  const pctInt = Math.min(Math.floor(pct), 100);

  const filled = Math.min(Math.floor(pctInt / 10), 10);
  const empty = 10 - filled;

  let barColor = colors.green;
  if (pctInt >= 80) barColor = colors.red;
  else if (pctInt >= 50) barColor = colors.orange;

  const formattedTokens = `${Math.floor(displayTokens / 1000)}k`;
  const formattedLimit = `${Math.floor(CONTEXT_LIMIT / 1000)}k`;

  return `${colors.lGray}󱃖 ${barColor}${'█'.repeat(filled)}${colors.gray}${'░'.repeat(empty)}${colors.reset} ` +
         `${colors.lGray}${pct.toFixed(1)}% (${formattedTokens}/${formattedLimit})${colors.reset}`;
}

// ===== BLOCKED STATE =====
function getBlockedState(projectDir) {
  const { lastBlockedPath } = getStatePaths(projectDir);
  try {
    const content = JSON.parse(fs.readFileSync(lastBlockedPath, 'utf8'));
    if (typeof content.timestamp !== 'number') return null;
    const ageMs = Date.now() - content.timestamp;
    if (ageMs < BLOCKED_TTL_MS) {
      return content;
    }
  } catch { /* ignore */ }
  return null;
}

function formatBlocked(blocked) {
  if (!blocked) return `${colors.green}No Block${colors.reset}`;
  return `${colors.red}Blocked${colors.reset}`;
}

// ===== ACTIVE WORK =====
function formatActiveWork(activeWork) {
  if (activeWork.designDoc) {
    return `${colors.purple}󰈙 ${activeWork.designDoc}${colors.reset}`;
  }
  if (activeWork.adHoc) {
    return `${colors.purple}󰈙 ad-hoc${colors.reset}`;
  }
  return null;
}

// ===== GIT INFO (single process call) =====
function getGitInfo(dir) {
  const result = { branch: null, ahead: 0, behind: 0, uncommitted: 0 };

  try {
    // Single git call for all info: branch, upstream, and file status
    // Use cwd option instead of -C flag to avoid command injection
    const output = execSync('git status --porcelain=v2 -b', {
      cwd: dir,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    });

    for (const line of output.split('\n')) {
      // Branch info: # branch.head <name>
      const branchPrefix = '# branch.head ';
      if (line.startsWith(branchPrefix)) {
        result.branch = line.slice(branchPrefix.length);
        if (result.branch === '(detached)') {
          // Get short commit hash for detached HEAD
          try {
            result.branch = '@' + execSync('git rev-parse --short HEAD', {
              cwd: dir,
              encoding: 'utf8',
              stdio: ['pipe', 'pipe', 'pipe']
            }).trim();
          } catch { result.branch = '@detached'; }
        }
      }
      // Upstream ahead/behind: # branch.ab +<ahead> -<behind>
      else if (line.startsWith('# branch.ab ')) {
        const match = line.match(/\+(\d+) -(\d+)/);
        if (match) {
          result.ahead = parseInt(match[1], 10);
          result.behind = parseInt(match[2], 10);
        }
      }
      // Changed files: lines starting with 1 or 2 (ordinary/renamed)
      else if (line.startsWith('1 ') || line.startsWith('2 ')) {
        result.uncommitted++;
      }
      // Untracked: lines starting with ?
      else if (line.startsWith('? ')) {
        result.uncommitted++;
      }
    }
  } catch {
    // Not a git repo or git not available
  }

  return result;
}

// ===== MAIN =====
function main() {
  // Context bar
  const tokens = getTokenUsage(transcriptPath);
  const contextBar = formatContextBar(tokens);

  // Blocked state
  const blocked = getBlockedState(cwd);
  const blockedStr = formatBlocked(blocked);

  // Active work
  const activeWork = getActiveWork(cwd);
  const activeWorkStr = formatActiveWork(activeWork);

  // Git info (single call)
  const git = getGitInfo(cwd);

  // Line 1: Context | Block status | Active work (if any)
  const line1Parts = [contextBar, blockedStr];
  if (activeWorkStr) line1Parts.push(activeWorkStr);
  console.log(line1Parts.join(' | '));

  // Line 2: Uncommitted | Upstream | Branch
  const line2Parts = [];
  line2Parts.push(`${colors.orange}✎ ${git.uncommitted}${colors.reset}`);

  const upstreamParts = [];
  if (git.ahead > 0) upstreamParts.push(`↑${git.ahead}`);
  if (git.behind > 0) upstreamParts.push(`↓${git.behind}`);
  if (upstreamParts.length > 0) {
    line2Parts.push(`${colors.orange}${upstreamParts.join(' ')}${colors.reset}`);
  }

  if (git.branch) {
    line2Parts.push(`${colors.lGray}󰘬 ${git.branch}${colors.reset}`);
  }

  console.log(line2Parts.join(' | '));
}

main();

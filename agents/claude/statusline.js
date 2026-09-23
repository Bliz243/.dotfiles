#!/usr/bin/env node
/**
 * statusline.js - Status line for Claude Code
 *
 * Single line: Model effort | Context | Rate limits | Git info
 * Claude Code only uses the FIRST line of stdout
 */

const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');
const { execFileSync, spawn } = require('child_process');

// git status takes seconds on large repos (Unity on /mnt/c). Repos slower than
// SLOW_GIT_MS are refreshed by a detached process that outlives this run, since
// Claude Code cancels an in-flight status line when the next update arrives.
const GIT_CACHE_TTL_MS = 5000;
const SLOW_GIT_MS = 500;
const GIT_REFRESH_TIMEOUT_MS = 30000;

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

function readInput() {
  try {
    return JSON.parse(fs.readFileSync(0, 'utf8'));
  } catch {
    return {};
  }
}

function levelColor(pct, neutral) {
  if (pct >= 80) return colors.red;
  if (pct >= 50) return colors.orange;
  return neutral;
}

// ===== MODEL =====
function formatModel(data) {
  const name = data.model?.display_name;
  if (!name) return null;
  const effort = data.effort?.level;
  return `${colors.purple}${name}${colors.reset}` + (effort ? ` ${colors.gray}${effort}${colors.reset}` : '');
}

// ===== CONTEXT USAGE =====
// Measured against the auto-compact point rather than the raw window: with
// autoCompactWindow set, compaction fires long before the window is full.
// Managed settings and the --autocompact flag aren't visible to this script.
function readAutoCompactWindow(projectDir) {
  const fromEnv = Number(process.env.CLAUDE_CODE_AUTO_COMPACT_WINDOW);
  if (fromEnv > 0) return fromEnv;

  const files = [
    path.join(projectDir, '.claude', 'settings.local.json'),
    path.join(projectDir, '.claude', 'settings.json'),
    path.join(os.homedir(), '.claude', 'settings.json')
  ];
  for (const file of files) {
    try {
      const value = Number(JSON.parse(fs.readFileSync(file, 'utf8')).autoCompactWindow);
      if (value > 0) return value;
    } catch { /* missing or invalid */ }
  }
  return null;
}

function formatContextBar(contextWindow, projectDir) {
  const size = contextWindow?.context_window_size || 200000;
  const used = contextWindow?.total_input_tokens ?? Math.floor((contextWindow?.used_percentage ?? 0) * size / 100);
  const limit = Math.min(readAutoCompactWindow(projectDir) || size, size);
  const pct = Math.min(used / limit * 100, 100);

  const filled = Math.min(Math.floor(pct / 10), 10);
  const barColor = levelColor(pct, colors.green);

  return `${barColor}${'█'.repeat(filled)}${colors.gray}${'░'.repeat(10 - filled)}${colors.reset} ` +
         `${colors.lGray}${pct.toFixed(0)}% (${Math.floor(used / 1000)}k/${Math.floor(limit / 1000)}k)${colors.reset}`;
}

// ===== RATE LIMITS (Pro/Max only) =====
function formatReset(epochSeconds) {
  const date = new Date(epochSeconds * 1000);
  const time = date.toTimeString().slice(0, 5);
  if (date.toDateString() === new Date().toDateString()) return time;
  return `${date.toLocaleDateString('en-GB', { weekday: 'short' })} ${time}`;
}

function formatRateLimits(rateLimits) {
  const parts = [];
  for (const [key, label] of [['five_hour', '5h'], ['seven_day', '7d']]) {
    const window = rateLimits?.[key];
    if (typeof window?.used_percentage !== 'number') continue;

    const pct = Math.round(window.used_percentage);
    const reset = pct >= 80 && window.resets_at ? ` ↻${formatReset(window.resets_at)}` : '';
    parts.push(`${levelColor(pct, colors.lGray)}${label} ${pct}%${reset}${colors.reset}`);
  }
  return parts.length ? parts.join(' ') : null;
}

// ===== GIT INFO =====
function gitCachePaths(dir) {
  const key = crypto.createHash('md5').update(path.resolve(dir)).digest('hex').slice(0, 12);
  const base = path.join(os.tmpdir(), `claude-statusline-git-${key}`);
  return { cacheFile: `${base}.json`, lockFile: `${base}.lock` };
}

function readGitStatus(dir, timeout) {
  const output = execFileSync('git', ['status', '--porcelain=v2', '-b'], {
    cwd: dir,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'ignore'],
    env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' },
    timeout
  });

  const result = { branch: null, ahead: 0, behind: 0, uncommitted: 0 };
  let oid = null;
  for (const line of output.split('\n')) {
    if (line.startsWith('# branch.oid ')) {
      oid = line.slice(13);
    } else if (line.startsWith('# branch.head ')) {
      result.branch = line.slice(14);
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
  if (result.branch === '(detached)') result.branch = oid && oid !== '(initial)' ? '@' + oid.slice(0, 7) : '@detached';
  return result;
}

// Throws only on timeout; a non-repo directory caches as null.
function writeGitCache(dir, cacheFile, timeout) {
  const start = Date.now();
  let info = null;
  try {
    info = readGitStatus(dir, timeout);
  } catch (e) {
    if (e.code === 'ETIMEDOUT') throw e;
  }
  fs.writeFileSync(cacheFile, JSON.stringify({ at: Date.now(), ms: Date.now() - start, info }));
  return info;
}

function startGitRefresh(dir, cacheFile, lockFile) {
  try {
    fs.writeFileSync(lockFile, String(Date.now()), { flag: 'wx' });
  } catch {
    const lockedAt = fs.statSync(lockFile, { throwIfNoEntry: false })?.mtimeMs ?? 0;
    if (Date.now() - lockedAt < GIT_REFRESH_TIMEOUT_MS) return;
    fs.writeFileSync(lockFile, String(Date.now()));
  }
  spawn(process.execPath, [__filename, '--refresh-git', dir, cacheFile, lockFile], {
    detached: true,
    stdio: 'ignore'
  }).unref();
}

function refreshGitCache(dir, cacheFile, lockFile) {
  try {
    writeGitCache(dir, cacheFile, GIT_REFRESH_TIMEOUT_MS);
  } catch { /* keep the previous cache */ } finally {
    try { fs.unlinkSync(lockFile); } catch { /* already gone */ }
  }
}

function getGitInfo(dir) {
  const { cacheFile, lockFile } = gitCachePaths(dir);
  let cached = null;
  try { cached = JSON.parse(fs.readFileSync(cacheFile, 'utf8')); } catch { /* no cache yet */ }

  if (cached && Date.now() - cached.at < GIT_CACHE_TTL_MS) return cached.info;
  if (!cached || cached.ms < SLOW_GIT_MS) {
    try {
      return writeGitCache(dir, cacheFile, SLOW_GIT_MS);
    } catch { /* slow repo: refresh in the background */ }
  }
  try { startGitRefresh(dir, cacheFile, lockFile); } catch { /* tmp not writable */ }
  return cached ? cached.info : null;
}

function formatGit(git) {
  let gitStr = `${colors.lGray}${git.branch}${colors.reset}`;
  if (git.uncommitted > 0) gitStr += `${colors.orange} +${git.uncommitted}${colors.reset}`;
  if (git.ahead > 0) gitStr += `${colors.orange} ↑${git.ahead}${colors.reset}`;
  if (git.behind > 0) gitStr += `${colors.orange} ↓${git.behind}${colors.reset}`;
  return gitStr;
}

// ===== MAIN =====
function main() {
  const data = readInput();
  const cwd = data.workspace?.current_dir || data.cwd || process.cwd();
  const projectDir = data.workspace?.project_dir || cwd;

  const parts = [
    formatModel(data),
    formatContextBar(data.context_window, projectDir),
    formatRateLimits(data.rate_limits)
  ];
  const git = getGitInfo(cwd);
  if (git?.branch) parts.push(formatGit(git));

  // Single line output - Claude Code only uses first line
  console.log(parts.filter(Boolean).join(' | '));
}

if (process.argv[2] === '--refresh-git') {
  refreshGitCache(process.argv[3], process.argv[4], process.argv[5]);
} else {
  main();
}

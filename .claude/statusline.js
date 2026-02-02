#!/usr/bin/env node
/**
 * statusline.js - Universal status line for Claude Code
 *
 * Displays:
 * Line 1: Context % | Active work indicator
 * Line 2: Uncommitted files | Upstream status | Git branch
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ANSI colors
const green = '\x1b[38;5;114m';
const orange = '\x1b[38;5;215m';
const red = '\x1b[38;5;203m';
const gray = '\x1b[38;5;242m';
const lGray = '\x1b[38;5;250m';
const purple = '\x1b[38;5;183m';
const reset = '\x1b[0m';

// Read stdin
let data = {};
try {
  data = JSON.parse(fs.readFileSync(0, 'utf-8'));
} catch {
  data = {};
}

const cwd = data.cwd || process.cwd();
const transcriptPath = data.transcript_path || null;

// ===== CONTEXT USAGE =====
function getContextUsage(tp) {
  if (!tp || !fs.existsSync(tp)) return null;

  try {
    const lines = fs.readFileSync(tp, 'utf-8').split('\n');
    let usage = null;

    for (const line of lines) {
      if (!line.trim()) continue;
      try {
        const d = JSON.parse(line);
        if (!d.isSidechain && d.message?.usage) {
          usage = d.message.usage;
        }
      } catch { /* ignore */ }
    }

    if (usage) {
      return (usage.input_tokens || 0) +
             (usage.cache_read_input_tokens || 0) +
             (usage.cache_creation_input_tokens || 0);
    }
  } catch { /* ignore */ }

  return null;
}

function formatContextBar(tokens) {
  const limit = 160000;
  const minDisplay = 17000;

  const displayTokens = tokens && tokens > minDisplay ? tokens : minDisplay;
  const pct = (displayTokens / limit) * 100;
  const pctInt = Math.min(Math.floor(pct), 100);

  // Progress bar (10 blocks)
  const filled = Math.min(Math.floor(pctInt / 10), 10);
  const empty = 10 - filled;

  // Color based on percentage
  let barColor = green;
  if (pctInt >= 80) barColor = red;
  else if (pctInt >= 50) barColor = orange;

  const formattedTokens = `${Math.floor(displayTokens / 1000)}k`;
  const formattedLimit = `${Math.floor(limit / 1000)}k`;

  return `${lGray}󱃖 ${barColor}${'█'.repeat(filled)}${gray}${'░'.repeat(empty)}${reset} ` +
         `${lGray}${pct.toFixed(1)}% (${formattedTokens}/${formattedLimit})${reset}`;
}

// ===== ACTIVE WORK =====
function getActiveWork(projectDir) {
  const result = { designDoc: null, adHoc: false };

  // Check for active design docs
  const designsDir = path.join(projectDir, 'docs/designs');
  if (fs.existsSync(designsDir)) {
    try {
      const docs = fs.readdirSync(designsDir).filter(f => f.endsWith('.md'));
      for (const doc of docs) {
        const content = fs.readFileSync(path.join(designsDir, doc), 'utf8');
        if (/Status:\s*(Active|In Progress|Exploring)/i.test(content)) {
          result.designDoc = doc.replace('.md', '');
          break;
        }
      }
    } catch { /* ignore */ }
  }

  // Check for active_work.md with real content
  const awPath = path.join(projectDir, 'docs/active_work.md');
  if (fs.existsSync(awPath)) {
    try {
      const content = fs.readFileSync(awPath, 'utf8');
      result.adHoc = content.includes('## Current Focus') &&
                     !/## Current Focus\n\n?\[/.test(content);
    } catch { /* ignore */ }
  }

  return result;
}

function formatActiveWork(activeWork) {
  if (activeWork.designDoc) {
    return `${purple}󰈙 ${activeWork.designDoc}${reset}`;
  }
  if (activeWork.adHoc) {
    return `${purple}󰈙 ad-hoc${reset}`;
  }
  return `${gray}󰈙 none${reset}`;
}

// ===== GIT INFO =====
function getGitBranch(cwd) {
  try {
    const branch = execSync(`git -C "${cwd}" branch --show-current`,
                           { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();
    if (branch) return branch;

    // Detached HEAD
    const commit = execSync(`git -C "${cwd}" rev-parse --short HEAD`,
                           { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();
    return `@${commit}`;
  } catch {
    return null;
  }
}

function getUpstreamStatus(cwd) {
  try {
    const ahead = parseInt(execSync(`git -C "${cwd}" rev-list --count @{u}..HEAD`,
                                    { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] }).trim());
    const behind = parseInt(execSync(`git -C "${cwd}" rev-list --count HEAD..@{u}`,
                                     { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] }).trim());

    const parts = [];
    if (ahead > 0) parts.push(`↑${ahead}`);
    if (behind > 0) parts.push(`↓${behind}`);

    return parts.length > 0 ? parts.join(' ') : null;
  } catch {
    return null;
  }
}

function getUncommittedCount(cwd) {
  try {
    const unstaged = execSync(`git -C "${cwd}" diff --name-only`,
                             { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();
    const staged = execSync(`git -C "${cwd}" diff --cached --name-only`,
                           { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();

    const unstagedCount = unstaged ? unstaged.split('\n').length : 0;
    const stagedCount = staged ? staged.split('\n').length : 0;

    return unstagedCount + stagedCount;
  } catch {
    return 0;
  }
}

// ===== MAIN =====
function main() {
  const projectDir = cwd;

  // Context bar
  const tokens = getContextUsage(transcriptPath);
  const contextBar = formatContextBar(tokens);

  // Active work
  const activeWork = getActiveWork(projectDir);
  const activeWorkStr = formatActiveWork(activeWork);

  // Git info
  const branch = getGitBranch(cwd);
  const branchStr = branch ? `${lGray}󰘬 ${branch}${reset}` : '';

  // Line 1: Context | Active work
  const line1Parts = [contextBar, activeWorkStr];
  console.log(line1Parts.join(' | '));

  // Git info
  const uncommitted = getUncommittedCount(cwd);
  const uncommittedStr = `${orange}✎ ${uncommitted}${reset}`;
  const upstream = getUpstreamStatus(cwd);
  const upstreamStr = upstream ? `${orange}${upstream}${reset}` : '';

  // Line 2: Uncommitted | Upstream | Branch
  const line2Parts = [uncommittedStr];
  if (upstreamStr) line2Parts.push(upstreamStr);
  if (branchStr) line2Parts.push(branchStr);
  console.log(line2Parts.join(' | '));
}

main();

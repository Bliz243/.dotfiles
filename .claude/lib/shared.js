/**
 * shared.js - Shared utilities for Claude hooks
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const os = require('os');

// Shared constants
const CONTEXT_LIMIT = 160000;
const STATE_DIR = path.join(os.homedir(), '.claude', 'state');

/**
 * Generate a session key from the working directory
 * Used to scope state files per-worktree
 * @param {string} cwd - Working directory (defaults to process.cwd())
 * @returns {string} - 8-character hex hash
 */
function getSessionKey(cwd = process.cwd()) {
  // Normalize path to handle trailing slashes and relative components
  const normalized = path.resolve(cwd);
  return crypto.createHash('md5').update(normalized).digest('hex').slice(0, 8);
}

/**
 * Get paths for session-scoped state files
 * @param {string} cwd - Working directory
 * @returns {object} - { stateDir, bypassTokenPath, lastBlockedPath }
 */
function getStatePaths(cwd = process.cwd()) {
  const sessionKey = getSessionKey(cwd);
  return {
    stateDir: STATE_DIR,
    bypassTokenPath: path.join(STATE_DIR, `guard-bypass-${sessionKey}`),
    lastBlockedPath: path.join(STATE_DIR, `last-blocked-${sessionKey}.json`)
  };
}

/**
 * Get token usage from transcript file
 * @param {string} transcriptPath - Path to transcript JSONL file
 * @returns {number|null} - Total tokens used, or null if unavailable
 */
function getTokenUsage(transcriptPath) {
  if (!transcriptPath || !fs.existsSync(transcriptPath)) return null;

  try {
    const lines = fs.readFileSync(transcriptPath, 'utf8').split('\n');
    let usage = null;

    for (const line of lines) {
      if (!line.trim()) continue;
      try {
        const d = JSON.parse(line);
        if (!d.isSidechain && d.message?.usage) {
          usage = d.message.usage;
        }
      } catch { /* ignore parse errors */ }
    }

    if (usage) {
      const toNum = (v) => Number(v) || 0;
      return toNum(usage.input_tokens) +
             toNum(usage.output_tokens) +
             toNum(usage.cache_read_input_tokens) +
             toNum(usage.cache_creation_input_tokens);
    }
  } catch { /* ignore */ }

  return null;
}

module.exports = {
  CONTEXT_LIMIT,
  STATE_DIR,
  getSessionKey,
  getStatePaths,
  getTokenUsage
};

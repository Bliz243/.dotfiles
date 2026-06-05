/**
 * shared.js - Shared utilities for Claude hooks
 */

const path = require('path');
const crypto = require('crypto');
const os = require('os');

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

module.exports = {
  STATE_DIR,
  getSessionKey,
  getStatePaths
};

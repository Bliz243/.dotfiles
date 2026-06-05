#!/usr/bin/env node
/**
 * shared.test.js - Tests for shared utilities
 *
 * Run with: node lib/shared.test.js
 */

const assert = require('assert');
const path = require('path');
const os = require('os');

const {
  STATE_DIR,
  getSessionKey,
  getStatePaths
} = require('./shared');

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`✓ ${name}`);
    passed++;
  } catch (e) {
    console.log(`✗ ${name}`);
    console.log(`  ${e.message}`);
    failed++;
  }
}

// STATE_DIR
test('STATE_DIR points to ~/.claude/state', () => {
  const expected = path.join(os.homedir(), '.claude', 'state');
  assert.strictEqual(STATE_DIR, expected);
});

// getSessionKey
test('getSessionKey returns 8-char hex string', () => {
  const key = getSessionKey('/some/path');
  assert.strictEqual(key.length, 8);
  assert.match(key, /^[0-9a-f]{8}$/);
});

test('getSessionKey is deterministic', () => {
  const key1 = getSessionKey('/test/path');
  const key2 = getSessionKey('/test/path');
  assert.strictEqual(key1, key2);
});

test('getSessionKey differs for different paths', () => {
  const key1 = getSessionKey('/path/one');
  const key2 = getSessionKey('/path/two');
  assert.notStrictEqual(key1, key2);
});

test('getSessionKey normalizes paths', () => {
  const key1 = getSessionKey('/test/path/');
  const key2 = getSessionKey('/test/path');
  assert.strictEqual(key1, key2);
});

// getStatePaths
test('getStatePaths returns correct structure', () => {
  const paths = getStatePaths('/test/dir');
  assert.strictEqual(paths.stateDir, STATE_DIR);
  assert.ok(paths.bypassTokenPath.includes('guard-bypass-'));
  assert.ok(paths.lastBlockedPath.includes('last-blocked-'));
  assert.ok(paths.lastBlockedPath.endsWith('.json'));
});

test('getStatePaths includes session key in filenames', () => {
  const sessionKey = getSessionKey('/test/dir');
  const paths = getStatePaths('/test/dir');
  assert.ok(paths.bypassTokenPath.includes(sessionKey));
  assert.ok(paths.lastBlockedPath.includes(sessionKey));
});

// Summary
console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);

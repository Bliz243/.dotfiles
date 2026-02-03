#!/usr/bin/env node
/**
 * shared.test.js - Tests for shared utilities
 *
 * Run with: node lib/shared.test.js
 */

const assert = require('assert');
const path = require('path');
const fs = require('fs');
const os = require('os');

const {
  CONTEXT_LIMIT,
  STATE_DIR,
  getSessionKey,
  getStatePaths,
  getTokenUsage,
  getActiveWork
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

// CONTEXT_LIMIT
test('CONTEXT_LIMIT is 160000', () => {
  assert.strictEqual(CONTEXT_LIMIT, 160000);
});

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

// getTokenUsage
test('getTokenUsage returns null for missing file', () => {
  const result = getTokenUsage('/nonexistent/file.jsonl');
  assert.strictEqual(result, null);
});

test('getTokenUsage returns null for empty path', () => {
  const result = getTokenUsage('');
  assert.strictEqual(result, null);
});

test('getTokenUsage returns null for null path', () => {
  const result = getTokenUsage(null);
  assert.strictEqual(result, null);
});

// Test type coercion helper used in getTokenUsage
test('Number() coercion handles strings correctly', () => {
  const toNum = (v) => Number(v) || 0;
  assert.strictEqual(toNum("123"), 123);
  assert.strictEqual(toNum(456), 456);
  assert.strictEqual(toNum(null), 0);
  assert.strictEqual(toNum(undefined), 0);
  assert.strictEqual(toNum("invalid"), 0);
});

// getActiveWork
test('getActiveWork returns correct structure for nonexistent dir', () => {
  const result = getActiveWork('/nonexistent/project');
  assert.deepStrictEqual(result, { designDoc: null, adHoc: false });
});

// Summary
console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);

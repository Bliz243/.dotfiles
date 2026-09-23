#!/usr/bin/env node
// Guards this public repo. Fails when tracked files, or the commits about to be pushed,
// contain secrets, email addresses, IP addresses, home-directory paths, or private terms.
// Private terms (project names, hosts, usernames) are read from an untracked file, so the
// list itself never becomes public: ${XDG_CONFIG_HOME:-~/.config}/dotfiles/private-terms
//
// Usage: node scripts/check-public.js [<git log revision args>]
//   no args: scan tracked files as they are in the working tree, plus all history for secrets
//   args:    also scan every line the selected commits add (the pre-push hook passes the
//            pushed range, e.g. `old..new` or `new --not --remotes`)
const { execFileSync, spawnSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const revArgs = process.argv.slice(2);
const inCI = Boolean(process.env.CI);
const git = (...args) => execFileSync('git', args, { cwd: repo, encoding: 'utf8', maxBuffer: 1 << 28 });

// Public placeholders and protocol constants that look sensitive but aren't.
const allow = /@example\.(com|org|net)$|@users\.noreply\.github\.com$|^git@github\.com$|^127\.0\.0\.1$|^0\.0\.0\.0$|^\/home\/(testuser|you|user)$|^\/Users\/\*$/;

const escapeRegex = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const termsFile = path.join(process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config'), 'dotfiles', 'private-terms');
const terms = fs.existsSync(termsFile)
  ? fs.readFileSync(termsFile, 'utf8').split('\n').map(t => t.trim()).filter(t => t && !t.startsWith('#'))
  : [];

const checks = [
  ['email', /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g],
  ['ip-address', /\b(?:\d{1,3}\.){3}\d{1,3}\b/g],
  ['home-path', /\/home\/[a-z_][a-z0-9_-]*|\/Users\/[^/\s"'`]+|C:\\\\?Users\\\\?[^\\\s"']+/g],
];
if (terms.length) checks.push(['private-term', new RegExp(terms.map(escapeRegex).join('|'), 'gi')]);

const findings = [];
// CI logs are public: show only enough of a match to locate it.
const show = value => (inCI ? `${value.slice(0, 3)}…` : value);

function scan(where, text) {
  for (const [label, re] of checks) {
    for (const match of text.matchAll(re)) {
      if (!allow.test(match[0])) findings.push(`${where}  ${label}: ${show(match[0])}`);
    }
  }
}

// Tracked files as they are now: what the next commit publishes.
for (const file of git('ls-files', '-z').split('\0').filter(Boolean)) {
  const abs = path.join(repo, file);
  if (!fs.existsSync(abs) || fs.lstatSync(abs).isSymbolicLink()) continue;
  const content = fs.readFileSync(abs);
  if (content.includes(0)) continue;
  content.toString('utf8').split('\n').forEach((line, i) => scan(`${file}:${i + 1}`, line));
}

// Lines added by the commits being pushed, including ones a later commit removed.
if (revArgs.length) {
  let commit = '';
  let file = '';
  for (const line of git('log', '-p', '--unified=0', '--no-color', '--format=commit %h', ...revArgs).split('\n')) {
    if (line.startsWith('commit ')) commit = line.slice(7);
    else if (line.startsWith('+++ ')) file = line.slice(6);
    else if (line.startsWith('+')) scan(`${commit}:${file}`, line.slice(1));
  }
}

// Secrets across history (or just the pushed commits) with gitleaks.
const gitleaksArgs = ['git', '--no-banner', '--redact', '--log-level', 'warn', repo];
if (revArgs.length) gitleaksArgs.splice(1, 0, '--log-opts', revArgs.join(' '));
const gitleaks = spawnSync('gitleaks', gitleaksArgs, { encoding: 'utf8' });
if (gitleaks.error) {
  if (inCI) findings.push('gitleaks: not installed');
  else console.warn('check-public: gitleaks not installed, secret scan skipped (scripts/install.sh installs it)');
} else if (gitleaks.status !== 0) {
  const output = `${gitleaks.stdout}\n${gitleaks.stderr}`.replace(/\x1b\[[0-9;]*m/g, '').trim();
  findings.push(`gitleaks: ${output.split('\n').slice(-3).join(' | ')} (run gitleaks git -v for details)`);
}

if (findings.length) {
  console.error(`check-public: ${findings.length} finding(s) that must not be public:\n  ${findings.join('\n  ')}`);
  console.error('\nRemove them. If a value is a public placeholder, add it to `allow` in scripts/check-public.js.');
  process.exit(1);
}
console.log(`check-public: clean${terms.length ? '' : ' (no private-terms file: generic checks only)'}`);

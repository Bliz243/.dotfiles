#!/usr/bin/env node
// Extract recent Claude Code and Codex sessions for one project as plain-text transcripts.
// Usage: node extract-sessions.js [project-dir] [out-dir] [max-per-tool]
const fs = require('fs');
const os = require('os');
const path = require('path');

const [projectArg, outArg, maxArg] = process.argv.slice(2);
const project = path.resolve(projectArg || process.cwd());
const outDir = outArg || fs.mkdtempSync(path.join(os.tmpdir(), 'agent-review-'));
const max = Number(maxArg) || 15;
const home = os.homedir();

function walk(dir, out = []) {
  let entries = [];
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return out; }
  for (const entry of entries) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(p, out);
    else if (entry.name.endsWith('.jsonl')) out.push(p);
  }
  return out;
}

const newestFirst = files => files
  .map(f => [f, fs.statSync(f).mtimeMs])
  .sort((a, b) => b[1] - a[1])
  .map(([f]) => f);

const parseLines = text => text.split('\n').flatMap(line => {
  try { return line ? [JSON.parse(line)] : []; } catch { return []; }
});

// Codex puts session_meta on the first line; read only that to filter by cwd.
function firstLine(file) {
  const fd = fs.openSync(file, 'r');
  try {
    const chunk = Buffer.alloc(1 << 20);
    const n = fs.readSync(fd, chunk, 0, chunk.length, 0);
    const text = chunk.subarray(0, n).toString('utf8');
    const newline = text.indexOf('\n');
    return newline < 0 ? text : text.slice(0, newline);
  } finally {
    fs.closeSync(fd);
  }
}

// Harness-injected context (instructions, environment, command wrappers) isn't conversation.
const isInjected = text => /^\s*<[a-z_-]+[\s>]/i.test(text) || text.includes('# AGENTS.md instructions for');

const textsOf = content => (typeof content === 'string' ? [content] : (content || [])
  .filter(c => ['text', 'input_text', 'output_text'].includes(c.type))
  .map(c => c.text))
  .filter(t => t && t.trim() && !isInjected(t));

const transcripts = [];

// Claude Code: ~/.claude/projects/<project path with / and . replaced by ->/*.jsonl
const claudeDir = path.join(home, '.claude', 'projects', project.replace(/[\/.]/g, '-'));
const claudeFiles = fs.existsSync(claudeDir)
  ? fs.readdirSync(claudeDir).filter(f => f.endsWith('.jsonl')).map(f => path.join(claudeDir, f))
  : [];
for (const file of newestFirst(claudeFiles).slice(0, max)) {
  const lines = parseLines(fs.readFileSync(file, 'utf8')).flatMap(entry =>
    entry.type === 'user' || entry.type === 'assistant'
      ? textsOf(entry.message?.content).map(t => `${entry.type.toUpperCase()}: ${t}`)
      : []);
  transcripts.push(['claude', file, lines]);
}

// Codex: ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl, kept when the session ran in this project
let codexCount = 0;
for (const file of newestFirst(walk(path.join(home, '.codex', 'sessions')))) {
  if (codexCount >= max) break;
  let cwd = '';
  try { cwd = JSON.parse(firstLine(file)).payload?.cwd || ''; } catch { continue; }
  if (cwd !== project && !cwd.startsWith(project + path.sep)) continue;

  const lines = parseLines(fs.readFileSync(file, 'utf8')).flatMap(entry => {
    const item = entry.payload;
    return entry.type === 'response_item' && item?.type === 'message' && ['user', 'assistant'].includes(item.role)
      ? textsOf(item.content).map(t => `${item.role.toUpperCase()}: ${t}`)
      : [];
  });
  transcripts.push(['codex', file, lines]);
  codexCount++;
}

fs.mkdirSync(outDir, { recursive: true });
for (const [tool, file, lines] of transcripts) {
  if (!lines.length) continue;
  const out = path.join(outDir, `${tool}-${path.basename(file, '.jsonl')}.txt`);
  fs.writeFileSync(out, lines.join('\n\n') + '\n');
  console.log(`${(fs.statSync(out).size / 1024).toFixed(0).padStart(6)} KB  ${out}`);
}
console.log(`\nTranscripts in ${outDir}`);

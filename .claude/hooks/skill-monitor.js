#!/usr/bin/env node
/**
 * skill-monitor.js - Config-driven skill activation hook
 *
 * Hook responsibilities:
 * - Ultrathink injection
 * - Session orientation (detect active work)
 * - Token monitoring with tiered warnings
 * - Skill activation from skill-rules.json (blocking, suggestions, reminders)
 *
 * Loads rules from:
 * 1. ~/.claude/config/skill-rules.json (global base)
 * 2. <project>/.claude/config/skill-rules.json (project extensions)
 *
 * Adding new skills = update skill-rules.json, no code changes here.
 */

// Global error handler - prevent hook crashes from breaking workflow
process.on('uncaughtException', () => {
  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'UserPromptSubmit',
      additionalContext: '[[ ultrathink ]]\n\n'
    }
  }));
  process.exit(0);
});

const fs = require('fs');
const path = require('path');
const os = require('os');

const {
  CONTEXT_LIMIT,
  STATE_DIR,
  getSessionKey,
  getStatePaths,
  getTokenUsage
} = require('../lib/shared');

// Skip in CI environments
if (process.env.CI || process.env.GITHUB_ACTIONS) {
  console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: 'UserPromptSubmit', additionalContext: '' } }));
  process.exit(0);
}

// Parse stdin input
let input = {};
try {
  input = JSON.parse(fs.readFileSync(0, 'utf-8'));
} catch (e) {
  // Silent fail - might be empty
}

const prompt = input.prompt || '';
const transcriptPath = input.transcript_path || '';
const projectDir = process.cwd();
const homeDir = os.homedir();

// Session-scoped state paths (prevents cross-worktree bypass leakage)
const { stateDir, bypassTokenPath } = getStatePaths(projectDir);

// ===== BYPASS TOKEN HANDLING =====
// When user starts message with "yert", create bypass token for command-guard
// Matches: "yert", "yert just delete it", "yert let's continue"
if (/^\s*yert\b/i.test(prompt)) {
  try {
    fs.mkdirSync(stateDir, { recursive: true });
    fs.writeFileSync(bypassTokenPath, String(Date.now()));
    // Token created - continue processing the rest of the prompt
  } catch (e) {
    // Continue with normal flow if bypass creation fails
  }
}

// ===== CONFIG LOADING =====
function loadSkillRules(configPath) {
  try {
    return JSON.parse(fs.readFileSync(configPath, 'utf-8'));
  } catch (e) {
    return { skills: {} };
  }
}

function mergeSkillRules(global, project) {
  // Project rules extend/override global rules
  return {
    ...global,
    skills: {
      ...(global.skills || {}),
      ...(project.skills || {})
    },
    referenceImplementations: {
      ...(global.referenceImplementations || {}),
      ...(project.referenceImplementations || {})
    },
    reviewAgents: {
      ...(global.reviewAgents || {}),
      ...(project.reviewAgents || {})
    }
  };
}

// Load and merge configs
const globalConfig = loadSkillRules(path.join(homeDir, '.claude/config/skill-rules.json'));
const projectConfig = loadSkillRules(path.join(projectDir, '.claude/config/skill-rules.json'));
const config = mergeSkillRules(globalConfig, projectConfig);

// ===== GENERIC SKILL MATCHING =====
function matchesSkill(prompt, skill) {
  const pl = prompt.toLowerCase();

  // Check keywords (exact substring match, case-insensitive)
  if (skill.promptTriggers?.keywords) {
    if (skill.promptTriggers.keywords.some(k => pl.includes(k.toLowerCase()))) {
      return true;
    }
  }

  // Check patterns (regex match)
  if (skill.promptTriggers?.patterns) {
    for (const p of skill.promptTriggers.patterns) {
      try {
        if (new RegExp(p, 'i').test(prompt)) return true;
      } catch (e) {
        console.error(`[skill-monitor] Invalid regex pattern "${p}": ${e.message}`);
      }
    }
  }

  return false;
}

// ===== PROCESS ALL SKILLS =====
const VALID_ENFORCEMENT = ['block', 'suggest', 'remind'];

function processSkills(prompt, config) {
  const matched = { block: [], suggest: [], remind: [] };

  for (const [name, skill] of Object.entries(config.skills || {})) {
    if (matchesSkill(prompt, skill)) {
      const enforcement = skill.enforcement || 'suggest';
      if (VALID_ENFORCEMENT.includes(enforcement)) {
        matched[enforcement].push({ name, ...skill });
      } else {
        console.error(`[skill-monitor] Invalid enforcement "${enforcement}" for skill "${name}"`);
      }
    }
  }

  // Sort by priority within each category
  const priorityOrder = { critical: 0, high: 1, medium: 2, low: 3 };
  for (const category of ['block', 'suggest', 'remind']) {
    matched[category].sort((a, b) =>
      (priorityOrder[a.priority] || 3) - (priorityOrder[b.priority] || 3)
    );
  }

  return matched;
}

// ===== GENERATE OUTPUT =====
function generateSkillOutput(matched) {
  let output = '';

  // Blocking skills (highest priority)
  if (matched.block.length > 0) {
    output += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
    output += 'BLOCKING SKILL ACTIVATION REQUIRED\n';
    output += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
    output += 'MANDATORY 3-STEP SEQUENCE (do this BEFORE any implementation):\n\n';

    for (const skill of matched.block) {
      const criteria = skill.activation?.criteria || 'relevant functionality';
      output += `Skill: ${skill.name}\n`;
      output += `  Step 1 - EVALUATE: Does this task involve ${criteria}?\n`;
      output += '           Answer: [YES/NO] because ___\n';
      output += `  Step 2 - ACTIVATE: If YES -> Invoke Skill(${skill.activation?.skill || skill.name}) NOW\n`;
      output += `  Step 3 - COMMIT: State "I have activated ${skill.name} and will follow its rules."\n\n`;
    }

    output += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
  }

  // Suggestions (workflow skills)
  if (matched.suggest.length > 0) {
    output += 'SKILL SUGGESTIONS:\n';

    // Deduplicate by skill name (some skills might match multiple patterns)
    const seen = new Set();
    for (const skill of matched.suggest) {
      const skillKey = skill.activation?.skill || skill.name;
      if (seen.has(skillKey)) continue;
      seen.add(skillKey);

      const icon = skill.activation?.icon || '*';
      const skillName = skill.activation?.skill;
      const message = skill.activation?.message || skill.description;

      if (skillName) {
        output += `   ${icon} Consider \`${skillName}\` - ${message}\n`;
      } else {
        output += `   ${icon} ${message}\n`;
      }
    }
    output += '\n';
  }

  // Reminders
  if (matched.remind.length > 0) {
    output += 'REMINDERS:\n';
    for (const skill of matched.remind) {
      const message = skill.activation?.message || skill.description;
      output += `   ${message}\n`;
    }
    output += '\n';
  }

  return output;
}

// ===== TOKEN MONITORING =====

function getWarningStatePath() {
  const sessionKey = getSessionKey(projectDir);
  return path.join(STATE_DIR, `session-warnings-${sessionKey}.json`);
}

function getWarningState() {
  try {
    return JSON.parse(fs.readFileSync(getWarningStatePath(), 'utf-8'));
  } catch (e) {
    return { warned_70: false, warned_80: false, warned_90: false, session_id: null };
  }
}

function setWarningState(state) {
  try {
    if (!fs.existsSync(STATE_DIR)) {
      fs.mkdirSync(STATE_DIR, { recursive: true });
    }
    fs.writeFileSync(getWarningStatePath(), JSON.stringify(state, null, 2));
  } catch (e) { /* ignore */ }
}

// ===== MAIN =====
// Start with ultrathink
let context = '[[ ultrathink ]]\n\n';

// Process skills
const matched = processSkills(prompt, config);

// Generate skill output (blocking -> suggestions -> reminders)
context += generateSkillOutput(matched);

// Token monitoring
const tokens = getTokenUsage(transcriptPath) || 0;
const pct = tokens > 0 ? (tokens / CONTEXT_LIMIT) * 100 : 0;

const sessionId = transcriptPath ? path.basename(transcriptPath, '.jsonl') : null;
let warningState = getWarningState();
if (sessionId && warningState.session_id !== sessionId) {
  warningState = { warned_70: false, warned_80: false, warned_90: false, session_id: sessionId };
  setWarningState(warningState);
}

// Tiered warnings
let warningsToShow = [];

if (pct >= 70 && !warningState.warned_70) {
  warningsToShow.push({ level: 70, label: '[70% PREP]', message: 'Good checkpoint to save progress.' });
  warningState.warned_70 = true;
}

if (pct >= 80 && !warningState.warned_80) {
  warningsToShow.push({ level: 80, label: '[80% HIGH]', message: 'Context getting full. Consider /compact soon.' });
  warningState.warned_80 = true;
}

if (pct >= 90 && !warningState.warned_90) {
  warningsToShow.push({ level: 90, label: '[90% CRITICAL]', message: 'Context nearly full! Run /compact now.' });
  warningState.warned_90 = true;
}

if (warningsToShow.length > 0) {
  const highest = warningsToShow[warningsToShow.length - 1];
  context += `${highest.label} ${highest.message}\n`;
  if (warningsToShow.length > 1) {
    context += `   (Jumped from <${warningsToShow[0].level}% to ${Math.floor(pct)}%)\n`;
  }
  context += '\n';
  setWarningState(warningState);
}

// Output the hook response
console.log(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'UserPromptSubmit',
    additionalContext: context
  }
}));

#!/usr/bin/env node
/**
 * cumulus — CLI orchestrator for the cumulus-sdd framework.
 *
 * Subcommands:
 *   init            Inject the framework (agents + templates) and docs/sdd/ into the current project.
 *   new <story-id>  Interactively instantiate a story spec from the story template.
 *   verify          Validate that every docs/sdd/*.md conforms to required headers and has criteria.
 */

import { Command } from 'commander';
import inquirer from 'inquirer';
import fs from 'fs-extra';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Package root = parent of bin/. Holds agents/ and templates/.
const PKG_ROOT = path.resolve(__dirname, '..');
const AGENTS_SRC = path.join(PKG_ROOT, 'agents');
const TEMPLATES_SRC = path.join(PKG_ROOT, 'templates');

// Target project layout (relative to the current working directory).
const CWD = process.cwd();
const FRAMEWORK_DIR = path.join(CWD, '.cumulus-sdd');
const SDD_DIR = path.join(CWD, 'docs', 'sdd');

const C = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
};
const log = (msg) => console.log(`${C.blue}${C.bold}[cumulus]${C.reset} ${msg}`);
const ok = (msg) => console.log(`  ${C.green}OK${C.reset}   ${msg}`);
const warn = (msg) => console.log(`  ${C.yellow}WARN${C.reset} ${msg}`);
const failLine = (msg) => console.log(`  ${C.red}FAIL${C.reset} ${msg}`);
const die = (msg) => {
  console.error(`${C.red}${C.bold}[cumulus] error:${C.reset} ${msg}`);
  process.exit(1);
};

// ── init ────────────────────────────────────────────────────────────────────
async function cmdInit() {
  log(`Initializing cumulus-sdd in ${CWD}`);

  if (path.resolve(FRAMEWORK_DIR) === path.resolve(PKG_ROOT)) {
    die('refusing to init onto the framework source itself — run this inside a target project.');
  }

  for (const [label, src, dest] of [
    ['agents', AGENTS_SRC, path.join(FRAMEWORK_DIR, 'agents')],
    ['templates', TEMPLATES_SRC, path.join(FRAMEWORK_DIR, 'templates')],
  ]) {
    if (!(await fs.pathExists(src))) {
      die(`missing framework source: ${src}`);
    }
    await fs.ensureDir(dest);
    await fs.copy(src, dest, { overwrite: true });
    ok(`.cumulus-sdd/${label}/`);
  }

  await fs.ensureDir(SDD_DIR);
  const gitkeep = path.join(SDD_DIR, '.gitkeep');
  if (!(await fs.pathExists(gitkeep))) await fs.writeFile(gitkeep, '');
  ok('docs/sdd/');

  log('Done. Next: `cumulus new <story-id>` to create your first story.');
}

// ── new <story-id> ──────────────────────────────────────────────────────────
async function cmdNew(rawId) {
  const id = String(rawId || '').trim();
  if (!/^[A-Za-z0-9._-]+$/.test(id)) {
    die(`invalid story id '${rawId}' — use letters, digits, dot, dash, underscore only.`);
  }

  const templatePath = path.join(TEMPLATES_SRC, 'story-template.md');
  const localTemplate = path.join(FRAMEWORK_DIR, 'templates', 'story-template.md');
  const chosenTemplate = (await fs.pathExists(localTemplate)) ? localTemplate : templatePath;
  if (!(await fs.pathExists(chosenTemplate))) {
    die(`story template not found (looked in ${localTemplate} and ${templatePath}). Run \`cumulus init\` first.`);
  }

  await fs.ensureDir(SDD_DIR);
  const outPath = path.join(SDD_DIR, `story-${id}.md`);
  if (await fs.pathExists(outPath)) {
    die(`story already exists: ${path.relative(CWD, outPath)}`);
  }

  let answers;
  if (process.stdin.isTTY) {
    answers = await inquirer.prompt([
      { type: 'input', name: 'title', message: 'Story title:', validate: (v) => (v.trim() ? true : 'Title is required') },
      { type: 'input', name: 'intent', message: 'Intent (1–2 sentences):', default: '' },
      { type: 'input', name: 'codeMap', message: 'Primary file to touch (path):', default: '' },
    ]);
  } else {
    // Non-interactive (CI / piped): fall back to defaults derived from the id.
    warn('no TTY detected — using defaults; edit the story to fill in details.');
    answers = { title: id, intent: '', codeMap: '' };
  }

  const today = new Date().toISOString().slice(0, 10);
  let body = await fs.readFile(chosenTemplate, 'utf8');
  body = body
    .replace(/STORY-<ID>/g, `STORY-${id}`)
    .replace(/created: YYYY-MM-DD/g, `created: ${today}`)
    .replace(/# Story <ID>: <TITLE>/g, `# Story ${id}: ${answers.title.trim()}`);

  if (answers.intent.trim()) {
    body = body.replace(
      /## Intent\n<One or two sentences\. What this unit of work delivers\.>/,
      `## Intent\n${answers.intent.trim()}`
    );
  }
  if (answers.codeMap.trim()) {
    body = body.replace(
      /- `<path>` — <role \/ why relevant>/,
      `- \`${answers.codeMap.trim()}\` — <role / why relevant>`
    );
  }

  await fs.writeFile(outPath, body);
  log(`Created ${path.relative(CWD, outPath)}`);
  log('Feed ONLY this file to your coding agent to keep context minimal.');
}

// ── verify ──────────────────────────────────────────────────────────────────
const REQUIRED_HEADERS = ['# ', '## Acceptance Criteria'];
const CHECKBOX_RE = /^- \[( |x|X)\] .+/m;

async function cmdVerify() {
  log(`Verifying specs in ${path.relative(CWD, SDD_DIR) || SDD_DIR}`);
  if (!(await fs.pathExists(SDD_DIR))) {
    die(`docs/sdd not found — run \`cumulus init\` first.`);
  }

  const entries = (await fs.readdir(SDD_DIR)).filter((f) => f.endsWith('.md')).sort();
  if (entries.length === 0) {
    warn('no .md specs found in docs/sdd/.');
    log('Verify result: nothing to check.');
    return;
  }

  let failures = 0;
  for (const file of entries) {
    const full = path.join(SDD_DIR, file);
    const content = await fs.readFile(full, 'utf8');
    const problems = [];

    if (!/^---\n[\s\S]*?\n---/.test(content)) problems.push('missing YAML frontmatter');
    if (!/^# .+/m.test(content)) problems.push('missing H1 title');
    if (!/^## Acceptance Criteria/m.test(content)) problems.push('missing "## Acceptance Criteria" section');
    if (!CHECKBOX_RE.test(content)) problems.push('no acceptance-criteria checkboxes ("- [ ]" / "- [x]")');

    const unchecked = (content.match(/^- \[ \] /gm) || []).length;
    const checked = (content.match(/^- \[[xX]\] /gm) || []).length;

    if (problems.length === 0) {
      ok(`${file} — ${checked} done / ${unchecked} open`);
    } else {
      failures += 1;
      failLine(`${file} — ${problems.join('; ')}`);
    }
  }

  console.log();
  if (failures > 0) {
    die(`${failures} spec(s) failed verification.`);
  }
  log(`Verify result: all ${entries.length} spec(s) conform.`);
}

// ── program ─────────────────────────────────────────────────────────────────
const program = new Command();
program
  .name('cumulus')
  .description('cumulus-sdd — token-efficient spec-driven development for multi-agent AI workflows.')
  .version('0.1.0');

program
  .command('init')
  .description('Inject .cumulus-sdd/ (agents + templates) and docs/sdd/ into the current project.')
  .action(async () => {
    try { await cmdInit(); } catch (e) { die(e.message); }
  });

program
  .command('new')
  .argument('<story-id>', 'identifier for the story, e.g. 001 or auth-login')
  .description('Instantiate a new story spec from the story template (interactive).')
  .action(async (storyId) => {
    try { await cmdNew(storyId); } catch (e) { die(e.message); }
  });

program
  .command('verify')
  .description('Validate that every docs/sdd/*.md has required headers and acceptance-criteria checkboxes.')
  .action(async () => {
    try { await cmdVerify(); } catch (e) { die(e.message); }
  });

program.parseAsync(process.argv);

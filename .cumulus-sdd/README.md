# cumulus-sdd

Ultra-lightweight, **token-efficient Specification-Driven Development (SDD)**
framework for multi-agent AI coding workflows. It turns loose prompts into
small, versioned Markdown specs under `docs/sdd/` **before** any code is
generated — so each coding agent loads only the one spec it needs, not the
whole repo.

> Directory name is `.cumulus-sdd/`. The npm package/command is `cumulus`
> (npm package names cannot start with a dot).

## Why

LLM coding agents degrade as context grows. `cumulus-sdd` keeps context tiny by
splitting work into a pipeline of narrow artifacts, each produced by a
single-purpose agent persona:

```
idea → brief.md → prd.md → arch.md → story-<id>.md → code → tests
       analyst    (PM)     architect   (slice)      developer  qa
```

Feed a coding agent **one** `story-<id>.md` at a time. That file names the exact
files it may touch (`Code Map`) and the criteria it must satisfy — nothing else
enters context.

## Layout

```
.cumulus-sdd/
├── agents/       # single-purpose agent personas (telegraphic, token-frugal)
│   ├── analyst.md    # idea      → brief.md
│   ├── architect.md  # prd.md    → arch.md (component contracts)
│   ├── developer.md  # story.md  → code (touches only authorized files)
│   └── qa.md         # story.md  → tests from acceptance criteria
├── templates/    # spec schemas with explicit headers + criteria checkboxes
│   ├── brief-template.md
│   ├── prd-template.md
│   ├── arch-template.md
│   └── story-template.md
├── bin/
│   └── cumulus.js   # CLI orchestrator (ESM)
├── docs/sdd/        # generated specs live here (.gitkeep placeholder)
├── package.json
└── README.md
```

## Install

```bash
# from the framework directory
cd .cumulus-sdd
npm install
npm link          # exposes the `cumulus` command globally (optional)
```

Or run without linking:

```bash
node .cumulus-sdd/bin/cumulus.js <command>
```

## CLI

### `cumulus init`
Injects the framework (`agents/` + `templates/`) into the current project's
`.cumulus-sdd/` and creates `docs/sdd/`.

```bash
cd my-project
cumulus init
```

### `cumulus new <story-id>`
Interactively instantiates a story spec from `story-template.md` into
`docs/sdd/story-<id>.md`.

```bash
cumulus new 001
cumulus new auth-login
```

### `cumulus verify`
Validates every `docs/sdd/*.md`: YAML frontmatter, an H1 title, an
`## Acceptance Criteria` section, and at least one criteria checkbox
(`- [ ]` / `- [x]`). Exits non-zero if any spec fails — CI-friendly.

```bash
cumulus verify
```

## Workflow

1. **Init** — `cumulus init` in your project.
2. **Brief** — hand `agents/analyst.md` + your idea to an AI; save output as
   `docs/sdd/brief.md` (schema: `templates/brief-template.md`).
3. **PRD** — expand the brief into `docs/sdd/prd.md`
   (schema: `templates/prd-template.md`).
4. **Architecture** — run `agents/architect.md` over `prd.md` to produce
   `docs/sdd/arch.md` (component contracts).
5. **Slice** — `cumulus new <id>` per unit of work; fill each story's
   `Code Map`, `Boundaries`, and `Acceptance Criteria`.
6. **Implement** — give a coding agent (Copilot / Claude Code) **only**
   `agents/developer.md` + one `story-<id>.md`. It edits only the files the
   story authorizes.
7. **Test** — give `agents/qa.md` + the same story to generate assertions from
   the acceptance criteria.
8. **Verify** — `cumulus verify` before commit.

## Using with Copilot / Claude Code (minimal context)

Attach exactly two files to the session:

- the relevant **agent persona** (`agents/developer.md` or `agents/qa.md`)
- the single **story** (`docs/sdd/story-<id>.md`)

Do **not** attach the whole `docs/sdd/` tree — the story's `Code Map` is the
only pointer the agent needs. This keeps token usage flat regardless of overall
project size.

## Requirements

- Node.js >= 16
- Dependencies: `commander`, `inquirer`, `fs-extra`

## License

MIT

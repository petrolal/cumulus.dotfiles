---
type: story
id: STORY-<ID>
status: draft
created: YYYY-MM-DD
source: docs/sdd/arch.md
---

# Story <ID>: <TITLE>

## Intent
<One or two sentences. What this unit of work delivers.>

## Context
<Minimum background the developer needs. Keep tiny — this is the whole point.>

## Code Map
<!-- Only files this story is allowed to read/modify. Keeps agent context minimal. -->
- `<path>` — <role / why relevant>

## Boundaries
**Always:** <invariant rules for this change>
**Never:** <forbidden changes / out of scope>

## Tasks
- [ ] `<path>` — <action> — <rationale>

## Acceptance Criteria
- [ ] Given <precondition>, when <action>, then <expected result>
- [ ] <criterion 2>

## Verification
<!-- Exact command(s) or steps to prove the criteria pass. -->
- <command or manual step>

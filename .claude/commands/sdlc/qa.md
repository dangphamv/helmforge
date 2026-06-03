---
description: Phase 6 · qa-engineer: tests + bug filing
argument-hint: <feature>
---

Run ONLY the QA phase (qa-engineer) for $ARGUMENTS, then STOP.

Standard flow: … → `/sdlc:build` → **`/sdlc:qa`** → `/sdlc:deploy` → `/sdlc:review`. Step 6.

## Recommended predecessor
`/sdlc:build` (an implementation PR should exist).

## Steps
1. Spawn `qa-engineer` → Playwright Agents + axe-core against the PR; add/adjust tests; file real bugs as issues (via the `vcs.provider`).
2. Verify acceptance scenarios from `acceptance.feature` pass; coverage gate per CLAUDE.md.
3. `checkpoint-resume`: update pipeline-state (current_phase: qa).

## Stop here
Tell the user: "QA done (<N passed / bugs filed>). Run **`/sdlc:deploy`** then **`/sdlc:review`**."

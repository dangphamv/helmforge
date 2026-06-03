---
name: checkpoint-resume
description: Make every agent's work resumable at the deliverable level, so interrupting mid-agent (Ctrl-C, crash, maxTurns, context limit) loses minimal progress. Apply to all agents and to /sdlc, /resume. Pattern: write each deliverable to its final path the moment it's done, record it in pipeline-state.yaml, and on (re)start skip what already exists.
---

# Checkpoint & resume — never redo finished work

You cannot rewind an LLM's in-flight reasoning. What you CAN do is make re-running an agent cheap: persist each deliverable as soon as it's complete, so a re-spawned agent continues from the gap instead of starting over. This turns "I stopped halfway" into "resume from the last saved artifact."

## The rule for every agent

1. **Declare your deliverables** up front (your Output Contract already lists them).
2. **Write each deliverable to its FINAL path the moment it is complete** — do not buffer everything to the end of the turn. A crash after deliverable 3 of 5 should leave 3 on disk.
3. **After each deliverable, update `docs/specs/<ticket>/pipeline-state.yaml`**: add it under `artifacts`, advance `phase_progress`. (One small write; cheap.)
4. **On (re)start, read state + check disk FIRST.** For each planned deliverable, if a valid one already exists, SKIP it. Resume at the first missing/incomplete one. Never regenerate completed deliverables (wastes quota and risks diverging from earlier decisions).
5. **For one big deliverable** (e.g. a large implementation), checkpoint with WIP commits (`wip: <area>` on the feature branch) and/or a `progress.md` note, so a resume reads the branch + notes and continues rather than rewriting.

## pipeline-state.yaml (sub-phase granularity)

```yaml
ticket: ACME-123
mode: standard
tier: standard
status: in_progress          # in_progress | paused | failed | done
last_completed_phase: spec   # phase-level (between agents)
current_phase: implement     # the phase an agent is mid-way through
phase_progress:              # deliverable-level WITHIN current_phase
  agent: backend-engineer
  done: [migration, module-skeleton]      # deliverables already on disk
  next: service-logic                       # where to resume
  wip_commit: "a1b2c3d"                     # last checkpoint commit, if any
artifacts:
  requirements: docs/specs/ACME-123/requirements.md
  openapi: api/openapi.yaml
  migration: packages/db/prisma/migrations/2026..._add_x
branch: feat/ACME-123-...
updated: 2026-06-02T10:00:00Z
```

## How /sdlc:resume uses this

- Phase-level: skip phases ≤ `last_completed_phase`.
- Within `current_phase`: re-spawn `phase_progress.agent`; it reads `phase_progress.done` + checks disk, skips those, resumes at `phase_progress.next`.
- Bound retries (≤ `ci.max_fix_attempts`-style); if the same step fails twice, escalate to the human rather than burning quota.

## What survives an interruption

| You stopped… | On /sdlc:resume |
|---|---|
| Between agents (phase boundary) | Continue at next phase; all prior artifacts kept |
| Mid-agent, after some deliverables written | Re-spawn that agent; it skips written deliverables, continues at `next` |
| Mid-deliverable (e.g. half a service) | Re-spawn agent; reads WIP commit/notes + partial file, completes it (the only case with some rework — kept small by frequent writes) |

## Honest limits

- A deliverable that was only half-written and not committed may be partly redone — frequent writes/commits shrink this window but don't eliminate it.
- The orchestrator (the /sdlc or /sdlc:resume session) must itself persist state to disk after each phase; if the orchestrator's own context is lost mid-phase, recovery relies on the artifacts + pipeline-state already written.

## Anti-patterns
- ❌ Buffering all deliverables and writing them only at the end of the turn
- ❌ Regenerating artifacts that already exist on resume
- ❌ Not updating pipeline-state after each deliverable (resume can't tell what's done)
- ❌ One giant uncommitted change with no WIP checkpoints

---
description: Resume a paused or interrupted pipeline from saved state
argument-hint: [ticket]
---

Resume an SDLC pipeline that was paused (for a human checkpoint/clarification) or that failed mid-run (an agent crashed, hit maxTurns, or produced unusable output). $ARGUMENTS is the ticket id/slug (or empty → find the most recently updated pipeline state).

## How resume works

The pipeline records progress in `docs/specs/<ticket>/pipeline-state.yaml` after each phase. This command reads it and continues from the last COMPLETED phase — it does not redo finished work or re-spend tokens on phases already done.

### 1. Locate state
- If $ARGUMENTS names a ticket → read `docs/specs/<ticket>/pipeline-state.yaml`.
- Else → scan `docs/specs/*/pipeline-state.yaml`, pick the most recently updated with `status: paused | failed | in_progress`.
- If no state file exists → tell the human there's nothing to resume; suggest `/sdlc` or `/sdlc:quick`.

### 2. Read what's done
The state file looks like:
```yaml
ticket: ACME-123
mode: standard        # standard | lite | large | init
tier: standard
status: failed        # in_progress | paused | failed | done
last_completed_phase: spec        # phase-level (between agents)
current_phase: implement          # phase an agent is mid-way through
phase_progress:                   # deliverable-level WITHIN current_phase
  agent: backend-engineer
  done: [migration, module-skeleton]   # already on disk — skip on resume
  next: service-logic                   # resume here
  wip_commit: "a1b2c3d"                 # last checkpoint commit, if any
artifacts:
  product-brief: docs/specs/ACME-123/product-brief.md
  requirements: docs/specs/ACME-123/requirements.md
  story-spec: docs/specs/ACME-123/US-031-spec.md
  openapi: api/openapi.yaml
failure:
  phase: implement
  agent: backend-engineer
  reason: "hit maxTurns" | "tests failed" | "ambiguous spec" | "crashed" | "interrupted"
  attempts: 1
branch: feat/ACME-123-...
```

### 3. Decide and continue
- **Paused for human** (checkpoint/clarification): confirm the human's input is now available (e.g. UX bundle ready, clarifying question answered), then continue from `last_completed_phase + 1`.
- **Failed or interrupted mid-agent:** read `phase_progress` (per the `checkpoint-resume` skill). Re-spawn `phase_progress.agent` and tell it: the deliverables in `phase_progress.done` already exist on disk — verify + SKIP them, resume at `phase_progress.next`. If a `wip_commit` exists, base on it. This recovers an interruption WITHIN an agent, not just between phases — finished deliverables are never redone.
  - If `failure.reason` is fixable (transient crash / maxTurns / context limit): continue as above (increment `attempts`).
  - If `attempts` ≥ 2 on the same step: STOP and escalate to the human.
  - If `failure.reason` is "ambiguous spec" / a real blocker: STOP, surface the specific question, keep `status: paused`.
- Only spawn agents that are ACTIVE and belong to the remaining phases for this `mode`/`tier`.

### 4. Keep the state current
After each resumed phase, update `pipeline-state.yaml` (`last_completed_phase`, `status`, `artifacts`). On success set `status: done`. This keeps the pipeline resumable again if it breaks later.

## Rules
- Never restart from scratch if state exists — that wastes quota and may diverge from earlier decisions.
- Never exceed `budget.max_agents_per_ticket` across the whole ticket (count prior + resumed agent runs).
- If state is corrupt/contradicts the repo (e.g. branch gone), report it and ask the human before proceeding.

## Example
```
/sdlc:resume ACME-123
/sdlc:resume            # resume the most recent unfinished pipeline
```

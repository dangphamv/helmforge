---
description: Phase 2 · project-manager: breakdown, DAG, tier & budget
argument-hint: <feature>
---

Run ONLY the Plan phase (project-manager) for $ARGUMENTS, then STOP.

Standard flow: PO `/sdlc:vision` → **PM `/sdlc:plan`** → BA `/sdlc:brd` → UX `/sdlc:design` → `/sdlc:build` → `/sdlc:qa` → `/sdlc:deploy` → `/sdlc:review`. This is step 2.

## Recommended predecessor
`/sdlc:vision` (a `product-brief.md` should exist). **Order-flexible:** if no brief exists, proceed from $ARGUMENTS as the brief and note that assumption.

## Scope
Single feature OR epic/MVP. For an MVP, plan across all the briefs/stories: a milestone plan + dependency graph between stories (Depends/Blocks).

## Steps
1. Read `product-brief.md`(s) + `CLAUDE.md`.
2. Spawn `project-manager` → `docs/specs/<id>/plan.md` + `tasks.yaml` (T-shirt sizes, DAG, risks). It also recommends the pipeline tier + budget (see `.helmforge/pipeline.config.yaml`) and, for an MVP, the story sequence.
3. `checkpoint-resume`: write incrementally; update pipeline-state (current_phase: plan, last_completed_phase: vision).

## Stop here
Tell the user: "Plan done. Review `plan.md`/`tasks.yaml`, then run **`/sdlc:brd`** (business-analyst) to write the detailed requirements."

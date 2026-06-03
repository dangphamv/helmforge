---
description: Phase 1 · product-owner: value, scope, KPIs
argument-hint: <feature or MVP>
---

Run ONLY the Vision phase (product-owner) for $ARGUMENTS, then STOP.

Standard project flow (this kit follows it): **PO `/sdlc:vision` → PM `/sdlc:plan` → BA `/sdlc:brd` → UX `/sdlc:design` → Engineers `/sdlc:build` → QA `/sdlc:qa` → DevOps `/sdlc:deploy` → Reviewer `/sdlc:review`**. This command is step 1.

## Scope
- A single feature/ticket, OR an epic/MVP (a set of stories). For an MVP, accept a list/description of the stories and produce a brief per story (or one consolidated brief with per-story value/scope).

## Steps
1. Read `CLAUDE.md` (+ `docs/brd/` if it exists) for context.
2. Spawn `product-owner` per its contract → `docs/specs/<ticket-or-epic>/product-brief.md` (value, KPI, scope Must/Should/Won't, kill criteria). For an MVP, one brief per story.
3. Follow `checkpoint-resume`: write each brief as it's done; update `docs/specs/<id>/pipeline-state.yaml` (mode: phase, current_phase: vision).
4. If the request is ambiguous → STOP and ask, don't invent scope.

## Stop here
Do NOT continue to planning/requirements. Tell the user: "Vision done. Review `product-brief.md`, then run **`/sdlc:plan`** (project-manager)." This is the standard next step.

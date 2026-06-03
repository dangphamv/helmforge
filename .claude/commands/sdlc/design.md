---
description: Phase 4 · ux-ui-designer: UX spec + accessibility
argument-hint: <feature>
---

Run ONLY the Design phase (ux-ui-designer) for $ARGUMENTS, then STOP.

Standard flow: PO `/sdlc:vision` → PM `/sdlc:plan` → BA `/sdlc:brd` → **UX `/sdlc:design`** → `/sdlc:build` → `/sdlc:qa` → `/sdlc:deploy` → `/sdlc:review`. Step 4.

## Active-agents gate
If `ux-ui-designer` is disabled (e.g. backend-only or API/mobile repo with no web UI) → say so and skip; suggest `/sdlc:build`.

## Recommended predecessor
`/sdlc:brd` (`requirements.md` + `acceptance.feature` + `openapi.yaml` should exist). Order-flexible: run from the story spec if present.

## Steps
1. Read the BRD/story specs + `openapi.yaml` + `acceptance.feature`.
2. Spawn `ux-ui-designer` per its contract → `docs/specs/<id>/ux-spec.md` + `wcag-audit.md` (uses the `ui-ux-pro-max` etc. skills; verifies accessibility). Honor any human checkpoint it defines.
3. `checkpoint-resume`: write incrementally; update pipeline-state (current_phase: design).

## Stop here
Tell the user: "Design done. Review `ux-spec.md`/`wcag-audit.md`, then run **`/sdlc:build`**."

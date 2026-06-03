---
description: Phase 3 · business-analyst: requirements, BRD, acceptance, API, schema
argument-hint: <feature or MVP>
---

Run ONLY the BRD / requirements phase (business-analyst) for $ARGUMENTS, then STOP.

Standard flow: PO `/sdlc:vision` → PM `/sdlc:plan` → **BA `/sdlc:brd`** → UX `/sdlc:design` → `/sdlc:build` → `/sdlc:qa` → `/sdlc:deploy` → `/sdlc:review`. This is step 3 — the BRD is the BA's output, AFTER planning (standard order).

## Recommended predecessors
`/sdlc:vision` + `/sdlc:plan` (`product-brief.md` + `plan.md` should exist). **Order-flexible:** run from whatever exists — from the brief alone if there's no plan yet; from $ARGUMENTS if neither exists (note the assumption). You do NOT need PM to have run if the user is driving phases manually.

## Scope (MVP-aware)
Single feature OR **the whole MVP/epic**. For an MVP, iterate over every story and produce the full BRD before stopping — this is the "spec-first" path: complete the BRD, review, then bring in design/build.

## Steps (per story, following the `brd-authoring` + `living-brd` skills)
1. Read available `product-brief.md` / `plan.md` / `CLAUDE.md` / existing `docs/brd/`.
2. Spawn `business-analyst`. Per story it produces:
   - `docs/specs/<id>/<US-ID>-spec.md` — consolidated, human-readable story spec (INVEST, testable+measurable, scope IN/OUT, mermaid user-flow, NFR checklist, errors/edge cases, assumptions/risks), LINKING canonical artifacts (anti-drift).
   - `requirements.md`, `acceptance.feature` (Gherkin), `api/openapi.yaml`, schema diff.
   - **Living BRD updated**: append/merge into `docs/brd/requirements.yaml` with GLOBAL IDs (`.helmforge/scripts/brd.sh next-id`), status, Depends/Blocks; then `.helmforge/scripts/brd.sh report` + `validate`.
3. `checkpoint-resume`: write each artifact immediately; update pipeline-state after each (so a mid-MVP interruption resumes per story/artifact).

## Stop here
Tell the user: "BRD complete for <scope>. Review `docs/brd/brd.md` + the story specs, then run **`/sdlc:design`** (UX) and/or **`/sdlc:build`**." Do not start design/implementation.

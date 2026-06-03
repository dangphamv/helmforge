---
description: Resolve spec ambiguities before build — asks you, folds answers back
argument-hint: <feature>
---

Surface and resolve ambiguities in the spec for $ARGUMENTS BEFORE design/implementation, then STOP. Borrowed from spec-driven development: cheaper to clarify now than to rebuild later.

Standard flow position: after **`/sdlc:brd`**, before **`/sdlc:design`** / **`/sdlc:build`**. (Optional but recommended for anything non-trivial.)

## Recommended predecessor
`/sdlc:brd` (a BRD / story spec should exist). Order-flexible: can also run after `/sdlc:vision` to clarify scope early. Runs from whatever spec artifacts exist.

## What it does
1. Read the available artifacts: `product-brief.md`, `plan.md`, `<US-ID>-spec.md`, `requirements.md`, `acceptance.feature`, `api/openapi.yaml`, `docs/brd/requirements.yaml`.
2. Spawn `business-analyst` (and `product-owner` if the ambiguity is about business scope/value) to hunt for:
   - Underspecified requirements (vague verbs, missing limits/units, "fast/secure" with no target)
   - Missing NFRs (auth, rate limit, p95, a11y, data retention, cost ceilings)
   - Undefined edge/error cases, empty/loading/permission states
   - Conflicting or duplicate requirements; unstated assumptions that change the design
   - Ambiguous acceptance criteria (not testable as written)
   - Scope gaps (no explicit OUT-of-scope; unclear MVP boundary)
3. **Ask the human a SHORT, prioritized list of questions** — only the ones whose answers would change the design or implementation (aim for ≤7; group the rest as "assumed unless you say otherwise"). Use concrete options where possible.
4. **STOP and wait** for the human's answers (set `pipeline-state.yaml` status: paused, current_phase: clarify).

## After the human answers
5. Fold the answers back into the canonical artifacts: update `requirements.md` / `<US-ID>-spec.md` (tighten statements, add NFRs/edge cases, set scope), update `acceptance.feature`, and the living BRD (`.helmforge/scripts/brd.sh report` + `validate`). Record resolved assumptions in the spec's Assumptions section.
6. `checkpoint-resume`: write each update immediately; update pipeline-state.

## Stop here
Tell the user: "Clarifications folded into the spec. Review, then run **`/sdlc:design`** and/or **`/sdlc:build`**." Do not start implementation.

## Scope
Single feature OR whole MVP/epic (clarify across all stories before building any).

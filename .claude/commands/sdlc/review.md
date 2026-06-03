---
description: Phase 8 · code-reviewer: OWASP/perf/spec + constitution gate
argument-hint: <feature>
---

Run ONLY the Review phase (code-reviewer) for $ARGUMENTS, then STOP.

Standard flow: … → `/sdlc:deploy` → **`/sdlc:review`** (final gate). Step 8.

## Steps
1. Spawn `code-reviewer` → OWASP 2025 + performance + spec-coverage review against the PR and the BRD/acceptance.
2. Decision: APPROVE or REQUEST_CHANGES (loop back to `/sdlc:build` for the relevant engineer if changes needed — count against budget).
3. On APPROVE + CI green: flip this feature's requirements in `docs/brd/requirements.yaml` to `status: shipped` (record `pr`), run `.helmforge/scripts/brd.sh report`; set pipeline-state status: done.

## Stop here
Tell the user: "Review <APPROVED/CHANGES>. A human merges after green + their review." Report the BRD IDs shipped.

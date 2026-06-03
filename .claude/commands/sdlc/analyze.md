---
description: Read-only cross-artifact coverage & consistency gate before build (borrowed from spec-kit /analyze)
argument-hint: <feature or ticket>
---

Run a **read-only** cross-artifact coverage and consistency check for $ARGUMENTS, then STOP. Borrowed from spec-kit's `/analyze`: verify every requirement traces forward to acceptance → task → test, and that the canonical artifacts don't contradict each other — BEFORE writing code, when fixing is cheap.

**Invariant: this command NEVER modifies a file.** It emits a findings report and an optional remediation plan. Any fix is applied later by `/sdlc:brd` / `/sdlc:clarify` / `/sdlc:build`, only after the human approves. If you catch yourself wanting to edit an artifact, STOP — that's a different command.

Standard flow position: after **`/sdlc:brd`** (and **`/sdlc:design`** if there's a UI), before **`/sdlc:build`**. Optional but recommended for `standard`/`large`; skip for trivial/small.

## Recommended predecessor
`/sdlc:brd` — the BRD, `acceptance.feature`, `openapi.yaml`, schema, and `tasks.yaml` should exist. Order-flexible: run from whatever is present and report what's missing as a gap.

## What it does
1. Read the canonical artifacts (do NOT re-derive — read them as-is):
   - `docs/brd/requirements.yaml` (living BRD — the requirements SoT), `requirements.md`, `<US-ID>-spec.md`
   - `acceptance.feature`, `api/openapi.yaml` (API contract SoT), `prisma/schema.prisma` (schema SoT)
   - `tasks.yaml`, `ux-spec.md`, `constitution.md`
2. Spawn `business-analyst` in **read-only mode** (and `project-manager` for the task-coverage axis) to build a forward-traceability matrix and find gaps. Run `.helmforge/scripts/brd.sh validate` and fold its output in.
3. Check these axes and assign each finding a severity (🔴 blocks build / 🟡 should-fix / 🟢 ok):

   **Coverage (the core spec-kit check):**
   - Every BRD `FR-*`/`NFR-*` for this ticket → has ≥1 acceptance scenario? (uncovered requirement = 🔴)
   - Every acceptance scenario → maps to ≥1 task in `tasks.yaml`? (untasked scenario = 🔴)
   - Every task → traces back to a requirement/scenario? (orphan task = 🟡 — scope creep or missing requirement)
   - Every `openapi.yaml` path/operation → demanded by some requirement? (undemanded endpoint = 🟡)
   - Every Prisma model/field added → consumed by an API or requirement? (dead column = 🟡)

   **Consistency (no contradictions between SoTs):**
   - `acceptance.feature` status codes / error codes ↔ `openapi.yaml` responses match?
   - Field names/types: `openapi.yaml` ↔ `schema.prisma` ↔ shared Zod contracts agree?
   - BRD statement ↔ acceptance scenario don't contradict; no duplicate requirements with different wording.

   **Quality / well-formedness:**
   - Acceptance scenarios are testable as written (declarative, no UI verbs, concrete data).
   - NFRs have measurable targets (p95, rate limit, payload cap) — not "fast/secure".
   - **UI-facing FRs carry the responsive + error/empty-state scenarios** (the gate FE/QA/reviewer now enforce — flag if missing here so it's caught before build, not at review).

   **Constitution compliance** (like spec-kit checks `constitution.md`): spec-before-code traceability, destructive-migration expand-and-contract plan present, auth stated per endpoint, dependency discipline. A violation = 🔴.

   **BRD hygiene:** no `shipped` requirement missing `pr`/`acceptance`; statuses sane; `brd.sh validate` clean.

4. Emit the report (below). Offer a remediation plan but **do not apply it**.
5. STOP. Set `pipeline-state.yaml` current_phase: analyze; do not change requirement statuses.

## Report format
```markdown
# Analyze: <feature> — <date>
Tier: <t>  ·  Artifacts read: <list>  ·  brd.sh validate: <PASS|N problems>

## Coverage matrix
| Requirement | Acceptance | Task | Test (if PR exists) | Status |
|-------------|-----------|------|---------------------|--------|
| FR-AUTH-014 | ✅ 2 scen | ✅ T-3 | — (pre-build) | 🟢 |
| FR-AUTH-015 | ❌ none   | ❌    | —                   | 🔴 uncovered |

## Findings
🔴 Blocking (N): <id — what's missing — which command fixes it>
🟡 Should-fix (N): <...>
🟢 Verified (N): <one line each on what passed>

## Remediation plan (NOT applied)
1. <command to run, e.g. `/sdlc:brd` to add acceptance for FR-AUTH-015>
2. ...
```

## Stop here
Tell the user one of:
- **"Analyze: 0 blocking. Safe to `/sdlc:build`."** (🟢) — or —
- **"Analyze: N blocking gaps. Run `/sdlc:brd`/`/sdlc:clarify` to close them, then re-run `/sdlc:analyze`."** (🔴)

Never start implementation. Never edit an artifact.

## Scope
Single feature OR a whole MVP/epic (analyze coverage across all stories before building any).

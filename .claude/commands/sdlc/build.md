---
description: Phase 5 · engineers implement (honors [P] parallel tasks)
argument-hint: <feature>
---

Run ONLY the Build/implementation phase for $ARGUMENTS, then STOP (no QA/deploy/review).

Standard flow: … → BA `/sdlc:brd` → UX `/sdlc:design` → **Engineers `/sdlc:build`** → `/sdlc:qa` → `/sdlc:deploy` → `/sdlc:review`. Step 5.

## Which engineers (ACTIVE + stack-aware)
Spawn only ACTIVE engineers that fit the work + `.helmforge/stack.config.yaml`:
- web → `frontend-engineer` (reads its framework) ; API/data → `backend-engineer` (incl. `next-api`/Supabase co-located mode) ; mobile → `mobile-engineer` ; AI feature → `ai-engineer`.
- FE + BE may run in parallel; FE waits for `/sdlc:design` output if a UI is involved. In co-located `next-api` mode, respect the FE/BE ownership split.
- **Use the `[P]` / `parallel: true` markers in `tasks.yaml`**: spawn engineers concurrently for tasks marked parallel (disjoint `files` scopes, dependencies met); run sequentially otherwise. This is how the kit safely parallelizes without merge conflicts.

## Recommended predecessors
`/sdlc:brd` (always), `/sdlc:design` (if a web UI). Order-flexible: implement from `openapi.yaml`/contracts if design isn't ready, but flag missing UX.

## Steps
1. Run `.helmforge/scripts/preflight.sh` (baseline must be green per `.helmforge/pipeline.config.yaml`); STOP if the baseline is broken.
2. Follow **brownfield discipline** (match existing conventions; minimal diff; impact analysis) on existing repos.
3. Each engineer implements per its contract + tests, opens a PR/MR via the configured `vcs.provider`.
4. `checkpoint-resume`: write deliverables incrementally + `wip:` commits; update pipeline-state after each (interruptions resume per deliverable).

## Stop here
Tell the user: "Implementation PR(s) open. Run **`/sdlc:qa`** then **`/sdlc:deploy`** then **`/sdlc:review`** — or `/sdlc` to auto-run the rest."

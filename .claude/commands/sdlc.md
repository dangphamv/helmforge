---
description: Run the full standard SDLC flow end-to-end (PO -> PM -> BA -> Design -> Build -> QA -> Deploy -> Review) with triage, budget and CI-loop
argument-hint: <ticket or feature description>
---

You will orchestrate the SDLC pipeline for the ticket described in $ARGUMENTS.

## Active agents only (repo profile)

Before spawning any agent, check which agents are ACTIVE: only files present in `.claude/agents/*.md` exist. Agents in `.claude/agents-disabled/` are intentionally OFF for this repo (e.g. a frontend-only repo disables `backend-engineer`; a backend-only repo disables `ux-ui-designer` and `frontend-engineer`). See `.helmforge/agents.config.yaml` and the "Active Agents" block in CLAUDE.md.

Rules:
- NEVER spawn an agent whose file is not in `.claude/agents/`. Skip that phase silently.
- If `backend-engineer` is disabled → skip the API implementation branch; the BA spec then describes the external API this repo consumes (client contract), not an API to build.
- If `ux-ui-designer` and `frontend-engineer` are disabled → skip design + web implementation; treat this as an API/service repo.
- If `mobile-engineer` is active (repo declares `mobile.framework: flutter|react-native` in .helmforge/stack.config.yaml) → run it in the implementation phase, parallel with backend-engineer. It consumes the same API contract. A mobile-only repo has FE web disabled and mobile active.
- If `ai-engineer` is active (repo declares `ai.framework: vercel-ai-sdk|mastra|langgraph`) → run it in the implementation phase for any AI feature (chatbot, multi-agent, RAG). It owns the streaming API, agents/tools, RAG, evals, and AI guardrails; frontend-engineer wires the chat UI; it consumes the same contracts. Treat its eval set as a required deliverable.
- If only one of FE-web / mobile / BE is active, run it alone (no parallel branch).
- If only one of FE/BE is active, run it alone (no parallel branch).
- Always keep `code-reviewer` as the final gate if it is active.

## Pipeline (strict order, with parallel branches)

### Phase 0 — Triage, budget & baseline (do this FIRST, every run)

Read `.helmforge/pipeline.config.yaml`. Then:

1. **Triage the ticket into a tier** using the `tiers` rubric: `trivial` (<~15 LOC, 1 file, no API/DB change), `small` (<~150 LOC, clear contract), `standard` (normal feature), `large` (architecture/security/payments/multi-system). Override: respect `--tier <name>` in $ARGUMENTS if given.
   - If `trivial` or `small` → tell the human this is better served by `/sdlc:quick` (1–3 agents) and ask whether to proceed lite here or escalate. Don't run the full 12-agent pipeline on a typo.
2. **Pick the agent set** for the tier (from `tiers`, intersected with ACTIVE agents). Lower tiers skip product-owner/project-manager/ux as appropriate.
3. **Budget check.** Estimate agents needed. If it exceeds `budget.confirm_if_agents_over` → print the estimate (which agents, why) and ASK the human to confirm before spending. Never exceed `budget.max_agents_per_ticket` — STOP and escalate if the plan would. Apply `budget.effort_by_tier` to the agents you spawn (cheaper effort for lower tiers).
   - Honest note: this right-sizes the pipeline and asks before big spends; it cannot hard-cap tokens. The real ceiling is the Max plan usage — surface `/cost` in the final summary.
4. **Initialize state** (`docs/specs/<ticket>/pipeline-state.yaml`): ticket, mode, tier, status: in_progress, last_completed_phase: none, current_phase, an empty `phase_progress` + `artifacts` map, branch. **UPDATE it after every phase AND after each deliverable an agent writes** (deliverable-level granularity per the `checkpoint-resume` skill) so `/sdlc:resume` can recover mid-agent, not just between phases. Tell each spawned agent to follow `checkpoint-resume`: write each deliverable to disk immediately and record it.
5. **Preflight** (if `preflight.run_before_implement`): run `.helmforge/scripts/preflight.sh`. If it exits 2 (baseline broken — build/test fail unrelated to this ticket) and `preflight.block_on_broken_baseline` → STOP and report to the human; do not build on a broken base (the agent couldn't tell its bugs from pre-existing ones). Exit 3 (unknown) → proceed but each engineer self-verifies build/test for this stack.

### Phases 1–8 — run the standard flow in order

`/sdlc` orchestrates the per-phase commands in the **standard real-project order**. Each phase's behavior is defined ONCE in its own command file (the single source of truth) — run them in this sequence rather than re-describing them here:

1. **`/sdlc:vision`** — product-owner → `product-brief.md`. If PO posts clarifying questions → STOP, wait for the human.
2. **`/sdlc:plan`** — project-manager → `plan.md` + `tasks.yaml` (DAG, risks, tier/budget recommendation). XL task / cyclic DAG → escalate.
3. **`/sdlc:brd`** — business-analyst → `<US-ID>-spec.md` + `requirements.md` + `acceptance.feature` + `openapi.yaml` + schema diff, and updates the living BRD (global IDs). Destructive migration → expand-and-contract plan. Opens the spec PR/MR.
   - *Optional (recommended for `standard`/`large`):* run **`/sdlc:clarify`** after `/sdlc:brd` — if the spec has material ambiguities, surface a short prioritized question list to the human and fold answers back before design/build. Skip for trivial/small.
4. **`/sdlc:design`** — ux-ui-designer → `ux-spec.md` + `wcag-audit.md` (skip if disabled). May define a human checkpoint (e.g. Claude Design bundle) — honor it.
5. **`/sdlc:build`** — ACTIVE engineers (FE/BE/mobile/ai) implement per `.helmforge/stack.config.yaml` + tests, open PR/MR. FE waits for `/sdlc:design`; BE/mobile/ai run in parallel where independent. In `next-api` co-located mode, respect the FE/BE ownership split.
6. **`/sdlc:qa`** — qa-engineer → Playwright + axe-core, tests, files real bugs.
7. **`/sdlc:deploy`** — devops-engineer → preview deploy, migration safety, env alignment, **CI gate & auto-fix** (bounded by `ci.max_fix_attempts`; never auto-merge).
8. **`/sdlc:review`** — code-reviewer (final gate) → OWASP 2025 + perf + spec-coverage. APPROVE / REQUEST_CHANGES (loop back to `/sdlc:build`, counts against budget). On APPROVE + CI green → flip the feature's BRD requirements to `status: shipped`, `.helmforge/scripts/brd.sh report`, pipeline-state status: done.

Orchestration rules:
- Skip any phase whose agent is disabled (see "Active agents" above). Lower tiers skip phases per `tiers` (e.g. `small` skips vision/plan/design).
- Run from the artifacts each phase produces — don't re-derive. Apply `budget.effort_by_tier` and keep the running agent count under `budget.max_agents_per_ticket`.
- Update `pipeline-state.yaml` after every phase AND every deliverable (so `/sdlc:resume` recovers mid-agent).
- The only difference between `/sdlc` and running the phase commands by hand is automation: `/sdlc` chains all phases with triage + budget + CI-loop; the phase commands let a human drive one step at a time and review between.

## Rules
- If any agent STOPS for clarification → set `pipeline-state.yaml` status: paused, post the specific question on the originating ticket/PR, and wait. `/sdlc:resume <ticket>` continues when answered.
- If an agent FAILS (crash / maxTurns / unusable output) → record it in `pipeline-state.yaml` (failure.phase/agent/reason/attempts) with status: failed. `/sdlc:resume` retries that phase once (≤ `ci.max_fix_attempts`-style bound), else escalates. Do NOT restart the whole pipeline.
- Open PRs/MRs and post comments via the configured `vcs.provider` (github | gitlab | bitbucket | azure-devops). GitHub uses the github MCP; others use the provider CLI (`glab`, etc.) + git. If the provider has no API integration available, push the branch and print the PR-create URL for the human.
- Each agent commits in its own commit(s) with a `Co-authored-by:` line referencing the agent name.
- Honor the Phase 0 budget: never exceed `budget.max_agents_per_ticket` (count loop-backs and CI fixes). Halt and report if exceeded.
- All artifacts live under `docs/specs/<ticket-id>/`; never overwrite a previous agent's artifact — append/iterate. Keep `pipeline-state.yaml` current after every phase.
- The pipeline ends when code-reviewer APPROVES and CI is green (success), or when it pauses/fails awaiting the human.

## Output (when pipeline ends)
Post a final summary comment on the originating ticket / PR:
- Ticket / Epic · Tier (and whether budget confirmation was requested)
- PR(s)/MR(s) opened (via the configured provider)
- Agents that ran + their handoff messages
- CI status (green / fixed after N attempts / escalated)
- Total token usage (from `/cost`) and wall-clock time
- **⚠️ Human actions required** (if any) — from `docs/human-actions/`, each with what to do, time, guide link
- **BRD updated:** requirements added/changed in `docs/brd/` (list the global IDs, e.g. `FR-AUTH-014`, with their status)
- Status: ✅ APPROVED + CI green ready to merge / 🔁 Changes requested / ⏸ Paused for human / ⛔ Halted (budget/baseline)

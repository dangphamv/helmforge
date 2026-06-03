---
description: Greenfield setup (run once): scaffold + skeleton + CLAUDE.md + BRD
argument-hint: <product description>
---

You will bootstrap a BRAND-NEW project from zero based on the description in $ARGUMENTS. This is greenfield — there is no existing codebase. Build a working full-stack skeleton plus the first real feature.

## Active agents only (repo profile)

Only spawn agents whose file exists in `.claude/agents/*.md`. Agents in `.claude/agents-disabled/` are OFF for this repo (see `.helmforge/agents.config.yaml`). For a frontend-only init, `backend-engineer` is skipped and the skeleton is web-only; for a backend-only init, `ux-ui-designer` + `frontend-engineer` are skipped and the skeleton is api-only. Adjust the walking skeleton accordingly (e.g. backend-only → `/healthz` JSON endpoint + DB round-trip, no web page).

## Pipeline (greenfield SETUP, then hand off to the phase flow)

`/sdlc:init` is a SETUP command (run once), not a replacement for the phase flow. It does the greenfield foundation (vision → roadmap → scaffold + skeleton), then hands the FIRST feature to the standard flow (`/sdlc` or the per-phase commands) so there's no duplicated pipeline logic.

### Phase A — Vision (product-owner)
Spawn `product-owner`. Produce `docs/specs/init/product-brief.md`: target users, core job-to-be-done, MVP scope (Must vs Won't-yet), primary launch metric. If the vision is too vague to scope an MVP → STOP and ask.

### Phase B — Roadmap (project-manager)
Spawn `project-manager`. Produce `docs/specs/init/plan.md`: phase the build (Skeleton → first vertical slice → later), pick the FIRST real feature (usually auth/onboarding), greenfield risks.

### Phase C — Foundation (solution-architect) — the heart of init
Spawn `solution-architect` (greenfield scaffold mode). Produce:
- Stack ADRs (0001–0005)
- Scaffolded monorepo (apps/web + apps/api + packages/*) per the `greenfield-scaffold` skill, matching `.helmforge/stack.config.yaml`
- Walking skeleton: `/healthz` → API → DB → render, tested + CI green
- Complete `CLAUDE.md` with conventions (+ checkpointing + requirements-source-of-truth sections)
- **Living BRD initialized:** `.helmforge/scripts/brd.sh init "<product>"` → `docs/brd/` (registered in CLAUDE.md)
- **Constitution:** ensure `constitution.md` exists (or run `/sdlc:constitution` to author the project's non-negotiable principles); register it in CLAUDE.md
- Human-action guides for hosting/DB/domain accounts
- A "chore: project skeleton" PR
**Quality gate:** `pnpm install && pnpm dev` starts web + api; `/healthz` round-trips to the DB; CI green. Do NOT hand off until the skeleton works.

### Phase D — Hand off the FIRST feature to the standard flow
The foundation is ready. Now run the FIRST real feature through the normal flow instead of a bespoke pipeline:
- Either run **`/sdlc <first-feature>`** (auto: PO→PM→BA→Design→Build→QA→Deploy→Review), or drive it phase-by-phase: **`/sdlc:brd` → `/sdlc:design` → `/sdlc:build` → `/sdlc:qa` → `/sdlc:deploy` → `/sdlc:review`** (vision/plan for it may already be covered by Phases A–B).
- The design phase here also establishes the design system (tokens, base components) since it's the first feature.
- Implement ONLY the first vertical slice — not ten features.

## Rules
- **Setup, not duplication.** Phases A–C are greenfield-specific setup; the actual feature work reuses the phase commands (single source of truth). Don't re-describe the build pipeline here.
- **Skeleton before features.** Phase C's walking skeleton MUST work before Phase D. No exceptions.
- **One feature, not ten.** First vertical slice only.
- **Human actions surfaced, not hidden.** Every third-party account/key → a guide in `docs/human-actions/` + a fail-fast code stub.
- **Deploy the skeleton.** A preview URL must work before init is considered done.
- If any phase STOPS for clarification → pause for the human. Honor `.helmforge/pipeline.config.yaml` budget.

## Output (when init ends)
Post a final summary:
- Repo + skeleton PR + preview URL
- Stack chosen (link ADR-0001) · Living BRD initialized
- First feature status (or "ready — run `/sdlc <feature>`")
- **⚠️ Human actions required** — numbered list from `docs/human-actions/README.md`
- Next steps: "Foundation ready. Use `/sdlc <ticket>` (or `/sdlc:vision`→…→`/sdlc:review`) for each new feature."

## Not redundant with /sdlc:onboard or the phase commands
- `/sdlc:init` = greenfield SETUP (scaffold a new repo). `/sdlc:onboard` = brownfield SETUP (analyze an existing repo). These are one-time, orthogonal to feature work.
- `/sdlc` + the phase commands (`/sdlc:vision`…`/sdlc:review`) = ongoing FEATURE work, reused by both setup commands.

## Example
```
/sdlc:init A SaaS for small gyms to manage memberships, class bookings, and
billing. MVP: member signup, class schedule, book/cancel a class. Mobile-first.
```

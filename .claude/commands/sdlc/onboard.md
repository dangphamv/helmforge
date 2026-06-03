---
description: Brownfield setup (run once): analyze an existing repo
argument-hint: [focus area]
---

Onboard the kit to an EXISTING repository so the agents understand it before adding features. Use this once on a brownfield repo (before your first /sdlc), or after a big change to refresh the picture. Argument $ARGUMENTS may narrow the focus (e.g. "focus on the billing module").

This does NOT write features. It analyzes the repo and writes down the truth so every later /sdlc run inherits accurate context.

## Pipeline

### Phase 1 — Analyze (solution-architect, brownfield mode)
Spawn `solution-architect` in brownfield-audit mode (NOT greenfield scaffold). Using the `codebase-analysis` skill, it performs the full analysis pass:
- Orient (README, manifests, CI, monorepo?), map structure, extract conventions ACTUALLY in use, find tests/CI, build a dependency/impact picture, surface risk/danger zones.
- It must DETECT, not assume: stack, package manager, ORM, db, framework.

### Phase 2 — Write the truth
The architect produces/updates:
- `.helmforge/stack.config.yaml` — set to DETECTED values (framework/orm/db/pm). Then it triggers skill-sync conceptually (tell the human to run `.helmforge/configure-agents.sh --sync-skills` if values changed).
- `CLAUDE.md` — generated from REALITY (actual commands, real structure, observed conventions, observed footguns, danger zones). If a CLAUDE.md already exists, MERGE: keep human-authored sections, update the detected/structure/conventions sections. Never silently overwrite human notes.
- `docs/architecture-map.md` — directory map, data flow, conventions table, test strategy, danger zones (low/no coverage areas).
- **Seed the living BRD** (do NOT back-fill): run `.helmforge/scripts/brd.sh init "<product>"` to create `docs/brd/requirements.yaml` + `brd.md`. Add a one-line product overview and may list detected modules as context comments, but do NOT invent requirement records for existing code. From the next `/sdlc` onward, each feature you build appends its requirements with global IDs (append-as-you-go). See `living-brd` skill.
- **Constitution:** ensure `constitution.md` exists (copy the default if missing) and is registered in CLAUDE.md. Tune its articles to match what the existing repo actually enforces (e.g. its real test/coverage + a11y posture) rather than imposing stricter rules the codebase doesn't meet yet — note any aspiration vs current-state gaps.

### Phase 3 — Document the API surface (business-analyst, if a backend/API exists)
If the repo exposes an API, spawn `business-analyst` to reverse-engineer the current surface into `api/openapi.yaml` (document what EXISTS, marking gaps). Skip if there's no API or one already exists and is current.

### Phase 4 — Report
Post a summary:
- Detected stack + suggested `.helmforge/stack.config.yaml` + agent profile (e.g. "this looks frontend-only → consider `.helmforge/configure-agents.sh --profile frontend`").
- Structure type (layer-based / feature-based / mixed) and the rule "match this, don't refactor".
- Test coverage picture + danger zones.
- Anything ambiguous that needs a human decision.
- "Ready for /sdlc. The agents will now follow the conventions documented in CLAUDE.md and match the existing structure."

## Rules

- READ-ONLY on source: this command analyzes and writes docs/config only; it does NOT change application code.
- The existing repo's conventions WIN over the kit's greenfield defaults (see `codebase-analysis` skill). Do not propose migrating the structure unless the human asks.
- If the repo is large, focus the analysis (entry points + the area in $ARGUMENTS) and say the map is partial.
- If a CLAUDE.md exists, merge — never clobber human-authored guidance.
- Recommend the right agent profile + stack.config based on what was detected; let the human confirm.

## After /sdlc:onboard

The human reviews CLAUDE.md + architecture-map.md, runs `.helmforge/configure-agents.sh --profile <suggested>` and `--sync-skills` if needed, then works features via the standard flow: **`/sdlc <ticket>`** (auto), or drive it phase-by-phase — **`/sdlc:vision` → `/sdlc:plan` → `/sdlc:brd` → `/sdlc:design` → `/sdlc:build` → `/sdlc:qa` → `/sdlc:deploy` → `/sdlc:review`** — reviewing between steps. From then on, the agents read CLAUDE.md, follow existing conventions, do impact analysis, and keep diffs minimal (brownfield discipline).

`/sdlc:onboard` is a SETUP command (run once on an existing repo). It is NOT redundant with `/sdlc:init` (that's greenfield setup) or the phase commands (ongoing feature work) — it's the brownfield setup layer they build on.

## Example

```
/sdlc:onboard
# or, focused:
/sdlc:onboard Focus on the orders + checkout modules; I'll be adding a refund flow there.
```

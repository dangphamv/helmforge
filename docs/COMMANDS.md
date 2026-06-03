# Commands map

The kit follows the **standard real-project flow: PO → PM → BA → Design → Build → QA → DevOps → Review.** There are three kinds of command.

> **Naming:** all kit commands live under the `sdlc:` namespace (files in `.claude/commands/sdlc/`), so they group together in the `/` menu and never collide with other tools' commands. Type **`/sdlc`** to see the whole family. The bare **`/sdlc <ticket>`** runs everything automatically; **`/sdlc:<phase>`** runs one phase. Each command shows a description + argument hint in the menu.

## 1. Per-phase commands (run ONE phase, then stop — manual control)

| Command | Phase | Agent | Recommended predecessor |
|---|---|---|---|
| `/sdlc:vision` | Vision (value, scope, KPI) | product-owner | — |
| `/sdlc:plan` | Plan (breakdown, DAG, risks, tier) | project-manager | `/sdlc:vision` |
| `/sdlc:brd` | Requirements / BRD (spec, acceptance, API, schema, living-BRD) | business-analyst | `/sdlc:plan` |
| `/sdlc:clarify` | Resolve spec ambiguities (asks the human, folds answers back) | business-analyst (+PO) | `/sdlc:brd` |
| `/sdlc:design` | UX/UI + accessibility | ux-ui-designer | `/sdlc:brd` |
| `/sdlc:build` | Implementation | frontend/backend/mobile/ai engineers | `/sdlc:brd` (+`/sdlc:design` for web) |
| `/sdlc:qa` | Tests + bug filing | qa-engineer | `/sdlc:build` |
| `/sdlc:deploy` | Preview deploy + CI gate/auto-fix | devops-engineer | `/sdlc:build` |
| `/sdlc:review` | OWASP + perf + spec review (final gate) | code-reviewer | all |

Each phase command: runs one phase, is **order-flexible** (proceeds from whatever upstream artifacts exist — so you can run `/sdlc:brd` before `/sdlc:plan` if you want), is ACTIVE-agent + stack aware, updates `pipeline-state.yaml` (so `/sdlc:resume` works), and STOPS telling you the next step. `/sdlc:vision`, `/sdlc:plan`, `/sdlc:brd` accept an **MVP/epic scope** (multiple stories) — e.g. build the entire BRD first, review, then `/sdlc:design` + `/sdlc:build`.

## 2. Orchestrators (run several phases)

| Command | Does |
|---|---|
| `/sdlc <ticket>` | Runs the WHOLE flow in standard order (the 8 phases above) with triage, budget, CI-loop. The phase commands are its single source of truth — it chains them; it doesn't redefine them. |
| `/sdlc:quick <ticket>` | Lite path (1–3 agents) for trivial/small changes — skips vision/plan/design. |
| `/sdlc:resume [ticket]` | Continues a paused/failed pipeline from `pipeline-state.yaml` (deliverable-level, mid-agent). |
| `/sdlc:constitution [amendment]` | Create/amend `constitution.md` — the non-negotiable principles `code-reviewer` enforces. Governance, not feature work. |

## 3. Setup commands (run ONCE per repo — NOT redundant)

| Command | When | Does |
|---|---|---|
| `/sdlc:init <desc>` | New empty repo (greenfield) | Vision → roadmap → scaffold + walking skeleton + ADRs + CLAUDE.md + living-BRD init, then hands the first feature to `/sdlc` / the phase flow. |
| `/sdlc:onboard` | Existing repo (brownfield) | Analyzes the repo → CLAUDE.md + architecture-map + stack.config + living-BRD seed (append-as-you-go), then hands off to `/sdlc` / the phase flow. |

**Why setup commands aren't redundant:** they do project SETUP (scaffold a new repo, or learn an existing one) — a different layer from feature work. The phase commands and `/sdlc` do the ongoing feature work and are *reused* by both setup commands after setup completes.

## Two ways to work a feature

- **Auto:** `/sdlc Add forgot-password flow` → runs PO→PM→BA→Design→Build→QA→Deploy→Review.
- **Manual (spec-first):** `/sdlc:vision` → review → `/sdlc:plan` → review → `/sdlc:brd` (whole MVP) → review the BRD → `/sdlc:design` → `/sdlc:build` → `/sdlc:qa` → `/sdlc:deploy` → `/sdlc:review`. Same agents, you drive the pace and review between steps.

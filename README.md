# 🏭 HelmForge — 9 Agents + skills.sh Powered

> Spec-Driven, multi-agent SDLC for **Claude Code**: PO → PM → BA → Design → Build → QA → Deploy → Review, with a living BRD, a project constitution, and per-phase slash commands under the `sdlc:` namespace.

## 🚀 Install

**Requirements:** Claude Code + bash (macOS/Linux, or WSL/Git Bash on Windows). The default stack needs Node 20+ / pnpm.

```bash
# 1) Via npx (recommended) — install into the current repo, interactive
npx helmforge init

#    Non-interactive (CI / one-liner):
npx helmforge init . --yes --fe nextjs --be next-api --ai vercel-ai-sdk --vcs github

# 2) Or run straight from GitHub, no npm publish needed
npx github:dangphamv/helmforge init

# 3) Or curl | bash (no Node)
curl -fsSL https://raw.githubusercontent.com/dangphamv/helmforge/main/install.sh | bash

# 4) Or manually
git clone https://github.com/dangphamv/helmforge.git
cd your-repo && bash /path/to/helmforge/setup.sh
```

After installing, open Claude Code in the repo:
```
/sdlc:init <product description>   # new project (greenfield)
/sdlc:onboard                      # existing repo (brownfield)
/sdlc <ticket>                     # run the full pipeline for one feature
```
Type `/sdlc` to see the whole command family. Details: [`docs/COMMANDS.md`](docs/COMMANDS.md).

> ℹ️ `setup.sh` is the bootstrap (it installs `.claude/` + commands into the repo), so it runs from the terminal/CLI, not as a slash command. Slash commands only exist after install. `npx helmforge init` is just a thin wrapper that calls `setup.sh` with `--target` set to your repo.

---

## ⭐ Anti-AI-Slop: outputs that read like a real expert, not like AI

Every agent loads the `expert-voice` skill **first**. It bans all the AI tells:
- ❌ Opener clichés ("I'd be happy to...", "Certainly!", "Let me walk you through...")
- ❌ Hedge padding ("It's worth noting that...", "You might want to consider...")
- ❌ Hollow words (leverage, robust, scalable, seamless, comprehensive, intuitive)
- ❌ Marketing-speak (world-class, production-ready without SLOs, state-of-the-art)
- ❌ Closer clichés ("In summary...", "Let me know if you have any questions")
- ❌ Symmetric 3-bullet lists where prose flows

Outputs must have:
- ✅ **Specifics**: numbers + units + names + versions + file paths + error codes
- ✅ **Owned trade-offs**: pick a side, name what you gave up
- ✅ **Calibrated confidence**: strong claims with evidence; admit real uncertainty
- ✅ **Restraint**: cut padding; silence where AI would over-explain

**Before/after — a PR description from frontend-engineer:**

❌ AI default:
> *This PR implements a robust forgot password flow leveraging Next.js Server Actions and Prisma to ensure a seamless user experience. The implementation follows industry best practices for security.*

✅ Expert voice:
> Adds /forgot-password and /reset-password/[token]. Server Action validates with Zod schema from packages/contracts. Token: SHA-256 of 32 random bytes, 30-min TTL, single-use (DB-enforced via used_at). Rate limit 3/hour/email — own bucket, separate from /login's 5/min/IP. No account enumeration: identical 200 response for valid/invalid email. Lighthouse: a11y 98, perf 92. Route JS: 142KB (under 170KB budget).

Each agent also has its own `# Voice — Role-Specific Anti-Slop` section with rules + examples for that role (a PO writes differently from a PM, which differs from a Reviewer).

---

## What's in this kit?

| | Count | Source |
|---|---|---|
| **Agents** | 10 specialists, ~250 lines each | Local `.claude/agents/*.md` |
| **External skills** (from skills.sh) | 27 | Installed via `npx skills add` |
| **Local skills** (project-specific) | 10 | Bundled in `.claude/skills/` |
| **Hooks** | 2 (block-dangerous, protect-secrets) | Bundled in `.claude/hooks/` |

## Three operating modes

| Mode | Command | When |
|---|---|---|
| **Init a new project** | `/sdlc:init <description>` | Empty repo, build from zero — `solution-architect` scaffolds the skeleton + ADRs + conventions, then implements the first feature |
| **Implement a feature** | `/sdlc <ticket>` | Add a feature to an existing codebase |
| **Fix a bug** | `/sdlc <ticket>` / `@claude` | Fix a defect |

**Human-action guides:** when a task depends on something a human must do (sign up for an account, get an API key, configure DNS), the agent generates step-by-step instructions at `docs/human-actions/`, stubs the code to fail fast, and surfaces it in the PR. See `.claude/skills/human-action-guide/SKILL.md`.

## Pipeline

```
You create a ticket / @claude mention
         ↓
1. 🟣 product-owner       → product-brief.md
                              skills: to-prd, brainstorming, marketing-psychology
2. 🔵 project-manager     → plan.md + tasks.yaml
                              skills: writing-plans, dispatching-parallel-agents,
                                      subagent-driven-development, to-issues
3. 🔷 business-analyst    → openapi.yaml + schema.prisma + acceptance.feature
                              skills: to-prd, openapi-3.1, prisma-6-migration
4. 🌸 ux-ui-designer      → prototypes/<feature>/ + ux-spec.md
                              skills: ui-ux-pro-max ⭐, frontend-design,
                                      web-design-guidelines, impeccable,
                                      wcag-2.2-aa, design-tokens
5a. 🟠 frontend-engineer  → Next.js + tests
                              skills: vercel-react-best-practices,
                                      next-best-practices, vercel-composition-patterns,
                                      shadcn, prototype
5b. 🟢 backend-engineer   → NestJS + Prisma + tests
                              skills: supabase-postgres-best-practices,
                                      nestjs-11-module, prisma-6-migration
6. 🟡 qa-engineer         → Playwright + axe-core
                              skills: webapp-testing, tdd,
                                      systematic-debugging, playwright-agents
7. ⚪ devops-engineer     → preview + Sentry + migration gates
                              skills: github-actions-docs,
                                      secure-linux-web-hosting, handoff
8. 🔴 code-reviewer       → OWASP 2025 review → APPROVE
                              skills: grill-me, grill-with-docs, diagnose,
                                      improve-codebase-architecture,
                                      requesting-code-review, owasp-top10-2025
         ↓
PR ready for you to merge
```

## Setup

### 🚀 Fastest way — interactive script (recommended)

```bash
tar -xzf helmforge.tar.gz
cd helmforge
./setup.sh
```

`setup.sh` asks step by step and configures things for you:
- **Auto-detects** whether the project is NEW (greenfield) or EXISTING — you confirm or change it
- Asks for project name, description, package prefix (`@<slug>`), default branch
- For existing projects: **reads package.json** to guess the stack + package manager, which you confirm
- Copies `.claude/` + `.github/` + `.helmforge/` (auto-backs up if they already exist)
- **Generates CLAUDE.md** from your inputs (no more `🔴 EDIT THIS` placeholders)
- Asks whether to run `.helmforge/install-skills.sh` (27 skills) now
- Asks whether to configure MCP servers now (GitHub PAT, Context7 key, Playwright...) — paste a key and the script runs `claude mcp add`
- Prints the next step (`/sdlc:init` for greenfield, `/sdlc` for existing)

For an existing project that already has a `CLAUDE.md`, the script lets you choose: backup-and-overwrite / keep-as-is / append the SDLC section at the end.

---

### Manual way (if you want step-by-step control)

#### Step 1 — Install Claude Code
```bash
npm install -g @anthropic-ai/claude-code@latest
claude --version    # ≥ v2.1.100
claude              # OAuth login
```

#### Step 2 — Copy the starter kit into your project
```bash
cd /path/to/your-project
tar -xzf helmforge.tar.gz
cp -r helmforge/.claude .
cp -r helmforge/.github .
cp -r helmforge/.helmforge .
cp helmforge/CLAUDE.md.template ./CLAUDE.md   # then edit the 🔴 EDIT THIS lines
cp helmforge/constitution.md .
chmod +x .claude/hooks/*.sh .helmforge/*.sh .helmforge/scripts/*.sh
```

#### Step 3 — Install external skills from skills.sh
```bash
.helmforge/install-skills.sh
```

This script runs `npx skills add ...` for 27 skills:
- **Product/PM/Marketing**: `to-prd`, `brainstorming`, `marketing-psychology`, `writing-plans`, `to-issues`, `dispatching-parallel-agents`, `subagent-driven-development`
- **Design**: `ui-ux-pro-max` ⭐ (193K installs, 50+ styles, 161 palettes), `frontend-design`, `web-design-guidelines`, `impeccable`
- **Frontend**: `vercel-react-best-practices` (440K installs), `next-best-practices`, `vercel-composition-patterns`, `shadcn`, `prototype`
- **Backend**: `supabase-postgres-best-practices`
- **QA**: `webapp-testing`, `tdd`, `systematic-debugging`
- **DevOps**: `github-actions-docs`, `secure-linux-web-hosting`, `handoff`
- **Review**: `grill-me`, `grill-with-docs`, `diagnose`, `improve-codebase-architecture`, `requesting-code-review`

⚠️ **Security**: each skill has an audit status (Socket / Snyk / Gen Agent Trust Hub) — see the script `.helmforge/install-skills.sh`. Note: the `ui-ux-pro-max` skill fails the Agent Trust Hub audit but passes Socket + Snyk. Review the SKILL.md after install if your project is sensitive.

### Step 4 — Install MCP servers
```bash
# Core (required)
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  -H "Authorization: Bearer $GITHUB_PAT"
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp \
  --api-key $CONTEXT7_KEY
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking

# Engineering (FE/BE/QA)
claude mcp add postgres -- docker run -i --rm crystaldba/postgres-mcp-pro:latest \
  --connection-uri "$DATABASE_URL" --access-mode=restricted
claude mcp add playwright -- npx @playwright/mcp@latest
cd /your/project && npx playwright init-agents --loop=claude

# Production (DevOps)
claude mcp add --transport http vercel https://mcp.vercel.com
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp

```

### Step 5 — Edit CLAUDE.md for your project
Open `CLAUDE.md` and edit the `🔴 EDIT THIS` lines to match your real stack.

### Step 6 — Set up GitHub Actions (optional)
```bash
claude setup-token
# Copy the output sk-ant-oat01-...
# GitHub → Settings → Secrets → Actions → CLAUDE_CODE_OAUTH_TOKEN
```

## Enable/disable agents by repo type (frontend-only / backend-only)

Not every repo needs all 10 agents. A pure Next.js repo doesn't need `backend-engineer`; a pure NestJS repo doesn't need `ux-ui-designer` + `frontend-engineer`. Control this with `.helmforge/agents.config.yaml` + the `.helmforge/configure-agents.sh` script.

```bash
# Show current status
.helmforge/configure-agents.sh --status

# Set a profile (sticky — written to .helmforge/agents.config.yaml)
.helmforge/configure-agents.sh --profile frontend    # DISABLE backend-engineer
.helmforge/configure-agents.sh --profile backend     # DISABLE ux-ui-designer + frontend-engineer
.helmforge/configure-agents.sh --profile fullstack   # enable all 10

# Pick agents yourself
.helmforge/configure-agents.sh --interactive
```

Mechanism: ACTIVE agents live in `.claude/agents/`; disabled agents move to `.claude/agents-disabled/`, so Claude Code **won't call** them. The `/sdlc` and `/sdlc:init` commands are taught to run only ACTIVE agents (e.g. backend-only → the skeleton has just API + DB, no web pages).

| Profile | Enabled | Disabled |
|---|---|---|
| `fullstack` | all 10 | — |
| `frontend` | 9 | `backend-engineer` |
| `backend` | 8 | `ux-ui-designer`, `frontend-engineer` |
| `custom` | per `.helmforge/agents.config.yaml` | up to you |

You can also edit `.helmforge/agents.config.yaml` directly (set `profile: custom` then toggle each `true/false` flag), then run `.helmforge/configure-agents.sh`. On each run, the "Active Agents" block in CLAUDE.md updates itself.

`setup.sh` also asks for this profile at install time (pre-suggested based on the stack detected from package.json).

## Usage

### Full pipeline
```bash
claude
> /sdlc Add forgot password flow. Users click "Forgot password?" on /login, enter email, receive reset link valid 30min, set new password. Rate limit 3/hour per email.
```

### Run one specific agent
```bash
> Use the ux-ui-designer subagent to design a dashboard for tracking subscription revenue.
> (Agent will pull ui-ux-pro-max product-type "Dashboard" pattern, choose palette + typography)
```

### Trigger from a GitHub Issue
1. Create an issue describing the ticket
2. Comment `@claude /sdlc implement this`
3. A PR opens automatically

## File layout

```
your-project/
├── CLAUDE.md                                 ← 🔴 EDIT for your project
├── constitution.md                           ← non-negotiable principles (code-reviewer enforces)
├── .helmforge/                               ← all kit machinery (hidden)
│   ├── agents.config.yaml · stack.config.yaml · pipeline.config.yaml
│   ├── configure-agents.sh · install-skills.sh
│   ├── scripts/ (preflight.sh, brd.sh)
│   └── ci-templates/
├── .claude/
│   ├── settings.json                         ← hooks + permission rules
│   ├── agents/                               ← agent definitions (10 active + mobile/ai optional)
│   │   ├── product-owner.md       🟣
│   │   ├── project-manager.md     🔵
│   │   ├── business-analyst.md    🔷
│   │   ├── ux-ui-designer.md      🌸
│   │   ├── frontend-engineer.md   🟠
│   │   ├── backend-engineer.md    🟢
│   │   ├── mobile-engineer.md     🟦 (Flutter/RN — off by default, enabled via .helmforge/stack.config.yaml)
│   │   ├── qa-engineer.md         🟡
│   │   ├── devops-engineer.md     ⚪
│   │   └── code-reviewer.md       🔴
│   ├── skills/                               ← local skills (project-specific)
│   │   ├── expert-voice/           ← ⭐ anti-AI-slop voice guide (loaded by ALL agents)
│   │   ├── wcag-2.2-aa/            ← WCAG checklist
│   │   ├── owasp-top10-2025/       ← security review checklist
│   │   ├── openapi-3.1/            ← API contract conventions
│   │   ├── nestjs-11-module/       ← NestJS patterns
│   │   ├── prisma-6-migration/     ← expand-contract safety
│   │   ├── design-tokens/          ← Tailwind v4 OKLCH tokens
│   │   ├── playwright-agents/      ← Playwright 1.56 Agents
│   │   └── ... + external skills from skills.sh
│   ├── hooks/
│   │   ├── block-dangerous.sh
│   │   └── protect-secrets.sh
│   └── commands/
│       ├── sdlc.md                           ← /sdlc orchestrator
│       └── sdlc/                             ← /sdlc:vision … /sdlc:review, init, onboard, etc.
└── .github/workflows/
    └── claude.yml
```

## Local vs external skills strategy

**Local skills (10)** — project-specific, override-able, focused on safety + voice:
- `expert-voice` ⭐ — anti-AI-slop style guide; loaded FIRST by every agent. Bans hedge padding, hollow words ("leverage/robust/scalable"), symmetric bullets, mirror-the-prompt openers. Outputs read like a senior practitioner.
- `wcag-2.2-aa` — full 86-SC accessibility checklist
- `owasp-top10-2025` — security review checklist with 2025 changes (A02 → #2, A03/A10 new)
- `openapi-3.1` — API contract conventions for THIS project
- `nestjs-11-module` — NestJS module patterns
- `prisma-6-migration` — expand-and-contract safety patterns
- `design-tokens` — Tailwind v4 @theme + OKLCH conventions
- `playwright-agents` — Playwright 1.56 planner/generator/healer specifics

**External skills (27)** — general expertise from skills.sh, maintained by domain experts. Browse all at https://www.skills.sh

Strategy: external skills provide industry best practices; local skills enforce project-specific rules. Both load together when an agent runs.

## Multi-framework: FE/BE/Mobile are not locked to Next.js + NestJS

`frontend-engineer`, `backend-engineer` and `mobile-engineer` read `.helmforge/stack.config.yaml` to learn the framework, then pull docs via Context7 + apply the matching idioms. The engineering discipline (types, tests, structure, expert-voice, perf budget) stays the same; only the framework primitives change.

```yaml
# .helmforge/stack.config.yaml
frontend:
  framework: nextjs    # nextjs|nuxt|sveltekit|remix|react-router-7|angular|astro|react-vite|none
backend:
  framework: nestjs    # nestjs|express|fastify|hono|django|fastapi|rails|go-gin|spring-boot|laravel|none
  language: typescript # typescript|python|ruby|go|java|php
mobile:
  framework: none      # flutter|react-native|none
```

| Layer | Frameworks supported out of the box (Context7 docs + idioms) |
|---|---|
| **Web** (frontend-engineer 🟠) | Next.js (default), Nuxt, SvelteKit, Remix/React Router 7, Angular, Astro, React+Vite |
| **API** (backend-engineer 🟢) | NestJS (default), Express, Fastify, Hono, Django, FastAPI, Rails, Go (Gin/Echo), Spring Boot, Laravel — **or API inside Next.js** (`next-api`), Nuxt (`nuxt-server`), SvelteKit, Remix |
| **Mobile** (mobile-engineer 🟦) | Flutter (Dart), React Native (Expo) |
| **AI features** (ai-engineer 🟩) | Vercel AI SDK 6 (chatbot/streaming), Mastra (multi-agent/RAG/eval), LangGraph — provider: Anthropic/OpenAI/Google/Gateway |

Change stacks: edit `.helmforge/stack.config.yaml` + the `## Stack` section in CLAUDE.md to match, then:

```bash
.helmforge/configure-agents.sh --sync-skills
```

This rewrites the `skills:` block of FE/BE/mobile to match the framework — **dropping irrelevant skills** (e.g. a Django repo no longer loads `nestjs-11-module`/`prisma-6-migration`; a Nuxt repo doesn't load React skills). It only keeps skills that actually exist (local or in the installer), so no broken references; for a framework without a dedicated skill, the agent pulls docs via Context7. `setup.sh` and every `.helmforge/configure-agents.sh` run also sync automatically. If a dedicated skill exists on skills.sh (e.g. `vue-best-practices`, `django`), install it and it'll be kept on the next sync.

### 🟦 Mobile agent (Flutter / React Native)

`mobile-engineer` is **OFF** by default (most repos have no mobile). It **auto-enables** when `.helmforge/stack.config.yaml` sets `mobile.framework: flutter` or `react-native`, then you run `.helmforge/configure-agents.sh`. For an "API + mobile, no web" repo: set `frontend.framework: none` + `mobile.framework: flutter`, profile `backend` → the pipeline is PO/PM/BA/architect/backend/mobile/qa/devops/reviewer.

Mobile-engineer handles: navigation (go_router / Expo Router), state (Riverpod/BLoC or Zustand/Redux), offline cache, push, secure token storage, permission flows, store-release human-action guides, tests (widget/integration or Jest+RNTL/Maestro), 60fps profiling + cold start.

### 🟩 Next.js fullstack + Supabase (API inside Next.js, no separate service)

A very common shape: a single Next.js app, the API is route handlers + Server Actions, data via Supabase (Postgres + Auth + Storage + RLS). Config:

```yaml
# .helmforge/stack.config.yaml
frontend: { framework: nextjs, ui_kit: shadcn }
backend:  { framework: next-api, language: typescript, orm: supabase-js, database: supabase }
```

```bash
.helmforge/configure-agents.sh --profile fullstack   # both agents work in the one Next.js repo
```

Clear division so they don't collide: **frontend-engineer** does UI + Server Components (read); **backend-engineer** does Server Actions (write) + route handlers (`app/api/*`) + Supabase schema/RLS/migrations + auth (`@supabase/ssr`). They meet at typed action signatures + Zod contracts. Supabase keys become a human-action guide (`docs/human-actions/<id>-supabase.md`). Want an ORM instead of supabase-js directly: set `orm: drizzle` or `prisma`.

### 🟩 AI features for end-users (chatbot, multi-agent, RAG)

**Important distinction:** the kit's SDLC agents (PO, FE, BE...) are **build-time** tools — they run inside Claude Code to WRITE your app's code. The chatbot/multi-agent you want for **end-users** is a **runtime feature** in your app, using an LLM API + a runtime framework. The kit *builds* that feature; it isn't *itself* that feature.

`ai-engineer` (🟩) is the agent that builds the AI runtime. It's **OFF** by default and auto-enables when:

```yaml
# .helmforge/stack.config.yaml
ai:
  framework: vercel-ai-sdk   # chatbot/streaming | mastra (multi-agent/RAG/eval) | langgraph | none
  provider: anthropic        # anthropic | openai | google | gateway
  features: "chat,rag"       # chat | agents | rag | extraction
```

It handles: streaming route (`app/api/chat/route.ts`), tool calling (Zod, RLS-scoped), agent loop / multi-agent workflow, RAG via **Supabase pgvector**, structured output (`generateObject`+Zod), **evals** (an eval set runs in CI), and guardrails (loop bounds, token/cost logging, prompt-injection defense, rate limits). The LLM key becomes a human-action guide that reminds you to set a spend cap. `frontend-engineer` handles the chat UI (`useChat`).

2026 recommendation: **Vercel AI SDK 6** for chatbot/in-app AI; **Mastra** (TS-native, built on the AI SDK, pgvector, evals included) for multi-agent/workflow/RAG — a good match for the Next.js + Supabase stack.

## Commands & the standard flow (PO → PM → BA → …)

The kit follows the **standard real-project flow: PO → PM → BA → Design → Build → QA → DevOps → Review.** There are 3 kinds of command (details: `docs/COMMANDS.md`). All live under the `sdlc:` namespace — type **`/sdlc`** to see the group in the menu; **`/sdlc <ticket>`** runs everything automatically, **`/sdlc:<phase>`** runs one phase.

**Per-phase (run one phase then stop — manual control):**

| Command | Phase | Agent |
|---|---|---|
| `/sdlc:vision` | Vision / scope / KPI | product-owner |
| `/sdlc:plan` | Plan / DAG / risk / tier | project-manager |
| `/sdlc:brd` | Requirements / BRD / acceptance / API / schema | business-analyst |
| `/sdlc:clarify` | Resolve spec ambiguities (asks the human, folds back) | business-analyst (+PO) |
| `/sdlc:design` | UX/UI + a11y | ux-ui-designer |
| `/sdlc:build` | Implementation | FE/BE/mobile/ai |
| `/sdlc:qa` | Test + bugs | qa-engineer |
| `/sdlc:deploy` | Deploy + CI gate/auto-fix | devops-engineer |
| `/sdlc:review` | OWASP + perf + spec (final gate) | code-reviewer |

Each command runs one phase, is **order-flexible** (proceeds from whatever artifacts exist — you can run `/sdlc:brd` before `/sdlc:plan`), is ACTIVE-agent + stack aware, updates `pipeline-state.yaml` (resumable), and STOPS telling you the next step. `/sdlc:vision`, `/sdlc:plan`, `/sdlc:brd` accept an **MVP/epic scope** (multiple stories) — build the whole BRD, review, then `/sdlc:design` + `/sdlc:build`.

**Orchestrator:** `/sdlc <ticket>` runs the WHOLE flow in standard order (the 8 phases above) + triage/budget/CI-loop — **the phase commands are the single source of truth; /sdlc just chains them, it doesn't redefine them**. `/sdlc:quick` = lite (1-3 agents). `/sdlc:resume` = continue an interrupted pipeline.

**Setup (run once per repo — NOT redundant):** `/sdlc:init` (greenfield: scaffold + skeleton + CLAUDE.md + BRD init → hands off to the phase flow), `/sdlc:onboard` (brownfield: analyze the repo → CLAUDE.md/architecture-map/BRD seed → hand off). They do SETUP (a different layer), then **reuse** the phase commands for feature work — so no overlap.

**Governance:** `/sdlc:constitution` creates/amends `constitution.md` — the non-negotiable principles (spec-before-code, tests required, OWASP/WCAG baseline, perf/cost budgets, brownfield-match, human gates). Every agent reads it; `code-reviewer` **enforces it as a gate** (a violation = request-changes). Unlike `CLAUDE.md` (conventions/how), this is "the law".

**2 ways to work a feature:** auto `/sdlc Add forgot-password`; or manual spec-first: `/sdlc:vision`→`/sdlc:plan`→`/sdlc:brd` (whole MVP) → review the BRD → `/sdlc:design`→`/sdlc:build`→`/sdlc:qa`→`/sdlc:deploy`→`/sdlc:review`.

## Cost, tier & reliability (.helmforge/pipeline.config.yaml)

A single `.helmforge/pipeline.config.yaml` controls how `/sdlc` runs — right-sized to the ticket so it doesn't burn Max quota.

**Tier (pick pipeline depth):** `/sdlc` triages the ticket → `trivial` / `small` / `standard` / `large`, running only the right number of agents. A small change doesn't drag in all 12 agents.

| Tier | Agents | Use for |
|---|---|---|
| trivial | 1–2 (implementer + review) | text fix, config, 1-2 lines |
| small | 3-4 (light BA + impl + QA + review) | bug fix, small well-defined change |
| standard | full | typical feature |
| large | full + human checkpoints | architecture/security/payments change |

```bash
/sdlc:quick <ticket>          # force lite path (1-3 agents) for small work
/sdlc <ticket>                # auto-triage tier; asks for confirmation if over budget.confirm_if_agents_over
/sdlc --tier standard <ticket>   # force a tier
/sdlc:resume <ticket>         # continue a paused/failed pipeline (don't restart from scratch)
```

**Budget:** `max_agents_per_ticket` (hard ceiling → STOP if exceeded), `confirm_if_agents_over` (ask before spending), `effort_by_tier` (low tiers use low effort = cheap). ⚠️ Honestly: Claude Code has no hook to hard-cap tokens by dollars — this is right-sizing + warnings + confirmation. The real ceiling is your Max plan's limit; watch `/cost`.

**Resume (#3):** the pipeline writes `docs/specs/<ticket>/pipeline-state.yaml` after every phase **and after every deliverable** (the `checkpoint-resume` skill). Stop mid-agent (Ctrl-C, crash, maxTurns, out of context) → `/sdlc:resume` reads `phase_progress`, skips deliverables already written to disk, and continues at the next one — **not just between phases, but inside an agent too**. Done work is never redone; only the remaining unfinished deliverable may need to continue (shrink it by writing/committing to disk often).

**CI auto-fix (#4):** after opening a PR + reviewer APPROVE, devops reads CI; if red → the agent fixes, pushes, re-checks, **bounded by `max_fix_attempts` (default 2)** then escalates (prevents a quota-burning loop). It never auto-merges.

**Preflight (#5):** `.helmforge/scripts/preflight.sh` checks the repo installs/typechecks/lints/builds/tests cleanly BEFORE agents code. A broken baseline (not the agent's fault) → STOP, tell the human. `/sdlc` runs this automatically; `setup.sh` also offers to run it for existing repos.

**Multi-VCS (#6):** `vcs.provider` = github | gitlab | bitbucket | azure-devops. GitHub has the deepest integration (MCP + `@claude`); the rest use git + a provider CLI (`glab`...) + templates in `.helmforge/ci-templates/`. See `.helmforge/ci-templates/README.md`.

## Existing repo (brownfield) — add a feature to a running codebase

This is the main use case, not an exception. There are 3 modes:

| Command | When | Special agent |
|---|---|---|
| `/sdlc:init <description>` | Empty repo, build from zero | solution-architect (greenfield scaffold) |
| `/sdlc:onboard` | **Existing repo — run once before adding features** | solution-architect (brownfield-audit) + BA |
| `/sdlc <ticket>` | Add a feature / fix a bug (existing repo) | — |

**Workflow for an existing repo:**
```bash
./setup.sh            # detects "existing", installs the kit, no scaffold
claude
> /sdlc:onboard       # analyze the repo: stack, structure, conventions, tests, risk areas
                      # → generate CLAUDE.md + docs/architecture-map.md FROM REAL CODE (merge if present)
                      # → set .helmforge/stack.config.yaml from what's detected; suggest a profile
> /sdlc Add feature X ...
```

`/sdlc:onboard` uses the `codebase-analysis` skill: reads README/manifest/CI, maps the structure 2-3 levels deep, extracts the **conventions actually in use** (response shape, naming, ORM, state lib, auth, import style), finds tests/coverage, builds a dependency/impact map, and flags under-tested areas. If the repo has an API, the BA reverse-engineers `api/openapi.yaml` from existing routes. An existing CLAUDE.md is **merged**, not overwritten over human-written notes.

**Brownfield discipline** (FE/BE/mobile/ai agents all have this section): read before writing → **follow existing conventions, don't impose the kit's greenfield structure** → impact analysis (grep callers) before touching shared code → minimal diff, no gratuitous refactor/format → don't add a library when one already does the job → use the existing migration mechanism → write characterization tests before touching untested code. **Golden rule: the existing repo's conventions BEAT the kit's defaults** — only migrate structure when the ticket explicitly asks and a human approves.

## Living BRD — a living spec / source of truth

For each feature, business-analyst records requirements in a living registry at `docs/brd/` (committed to git), with **global IDs** + status + traceability:

- `docs/brd/requirements.yaml` — **source of truth**: one record per requirement (`FR-AUTH-001`, `NFR-PERF-003`...), `status` (proposed/planned/in-progress/shipped/deprecated), priority, statement, and `acceptance`/`ticket`/`pr` links.
- `docs/brd/brd.md` — a human-readable view (overview + per-domain tables + traceability), **auto-generated** by `.helmforge/scripts/brd.sh report` (don't edit by hand).

```bash
.helmforge/scripts/brd.sh init "My Product"        # create docs/brd/ (/sdlc:init & /sdlc:onboard call this)
.helmforge/scripts/brd.sh next-id AUTH FR          # next global ID → FR-AUTH-002 (avoids collisions)
.helmforge/scripts/brd.sh report                   # regenerate brd.md from the registry
.helmforge/scripts/brd.sh validate                 # check for duplicate IDs + required fields (doctor runs this too)
```

**Append-as-you-go (existing repo with no BRD yet):** `/sdlc:onboard` creates an empty skeleton (it doesn't back-fill old code). From there **every feature you build via `/sdlc` (or `/sdlc:quick`) is recorded in the BRD** with a global ID, `status: shipped` on merge. The BRD grows exactly with the parts of the product the kit has touched — accurate, not invented. To record a pre-existing area, add it manually with `status: shipped` + a `pre-existing` note.

Difference from per-ticket `docs/specs/<ticket>/requirements.md`: that's a per-ticket snapshot (local IDs); `docs/brd/` is the **unified, always-current, global-ID, cross-traceable** document — registered in CLAUDE.md so every agent reads it.

**Consolidated story-spec (best practice):** beyond the registry, the BA emits `docs/specs/<ticket>/<US-ID>-spec.md` — a human-readable doc following the `brd-authoring` skill (INVEST, testable + measurable, WHAT/HOW separation, scope IN/OUT, NFR checklist, mermaid user-flow, error/edge cases, assumptions/risks, Depends/Blocks from the BRD graph). It **links** to canonical artifacts (`openapi.yaml`, migration, `acceptance.feature`) instead of copying DDL/API tables into prose — anti-drift. This is the "like your example, but with traceability + runnable acceptance + no duplication" version.

## Adapting to a language outside the list

Framework not in the table? The agent still runs: it pulls docs via Context7 from an ID you add to the agent, or you add a line to the "Framework Adaptation" table in `.claude/agents/<agent>.md`. Edit `.helmforge/install-skills.sh` to swap in a matching skill.

## Troubleshooting

| Problem | Fix |
|---|---|
| `npx skills` not found | Need Node 20+ and internet to fetch the skills package |
| Skill doesn't load when an agent runs | Verify `.claude/skills/<name>/SKILL.md` exists; restart `claude` |
| Agent doesn't self-delegate | The description must have a "MUST BE USED for X" pattern |
| Cost burns fast | Lower `effort: high` → `medium` in the agent frontmatter |
| Hook doesn't fire | `chmod +x .claude/hooks/*.sh` |

## References

- **skills.sh leaderboard**: https://www.skills.sh
- **ui-ux-pro-max skill**: https://www.skills.sh/nextlevelbuilder/ui-ux-pro-max-skill/ui-ux-pro-max
- **frontend-design (Anthropic)**: https://www.skills.sh/anthropics/skills/frontend-design
- **Vercel React skills**: https://www.skills.sh/vercel-labs/agent-skills
- **Mattpocock skills**: https://www.skills.sh/mattpocock/skills
- **Security audits**: https://www.skills.sh/audits

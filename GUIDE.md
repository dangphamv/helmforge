# 📖 HelmForge User Guide

A multi-agent, Spec-Driven SDLC kit for Claude Code: drop it into a repo, describe a ticket, and a team of specialist agents takes it from product brief → spec → design → build → QA → deploy → review, opening a PR for you to merge.

> This guide is the long-form manual. For a quick overview see `README.md`; for the command map see `docs/COMMANDS.md`; the authoritative behavior of each role lives in `.claude/agents/*.md`.

## Table of contents

1. What this kit does
2. Prerequisites
3. Step-by-step install
4. Daily use
5. Understanding the agent pipeline
6. Writing good tickets
7. Reading and handling human checkpoints
8. Reviewing an agent's PR
9. Managing cost
10. Customizing and extending
11. Troubleshooting
12. FAQ
13. Cheat sheet

---

## 1. What this kit does

HelmForge runs a real software-team workflow as a chain of Claude Code subagents. You give it a ticket; it produces a spec, a design, an implementation with tests, a CI-checked PR, and a security/quality review — each step owned by a focused agent.

### Three operating modes
- **Init a new project** — `/sdlc:init <description>`: empty repo → solution-architect scaffolds the skeleton, ADRs, conventions, and CLAUDE.md, then builds the first feature.
- **Implement a feature** — `/sdlc <ticket>`: add a feature to an existing codebase.
- **Fix a bug** — `/sdlc <ticket>` or `@claude` from a GitHub issue.

### The full pipeline
PO → PM → BA → UX/UI → Frontend + Backend (parallel) → QA → DevOps → Code Reviewer. Each agent loads the `expert-voice` skill first (anti-AI-slop) plus its role skills, writes its deliverables to disk, updates `pipeline-state.yaml`, and hands off. The reviewer enforces `constitution.md` as a blocking gate.

### How this differs from plain Claude Code
- Defined roles with separate responsibilities and voice, instead of one generalist.
- Spec-before-code: a living BRD with global requirement IDs and traceability.
- A project constitution the reviewer enforces.
- Cost right-sizing (tiers/budget), resumable pipelines, preflight checks, CI auto-fix, multi-VCS.
- Outputs tuned to read like a senior practitioner, not generic AI.

---

## 2. Prerequisites

### Required software
```bash
node --version     # ≥ 20
pnpm --version     # or your package manager
git --version
claude --version   # ≥ v2.1.100
```
Plus **bash** (macOS/Linux, or WSL/Git Bash on Windows).

### Accounts you'll need
- **Anthropic** with a Claude Code plan (Max 20x recommended for full pipelines — see chapter 9).
- **GitHub** (for `@claude` triggers + Actions) — a fine-grained PAT.
- **Context7** (free API key) — keeps agents from hallucinating framework APIs.
- Optional: **Supabase/Postgres**, **Vercel**, **Sentry** depending on your stack.

---

## 3. Step-by-step install

### Step 0 — Interactive setup (one command)
```bash
npx helmforge init          # or: tar -xzf helmforge.tar.gz && cd helmforge && ./setup.sh
```
The script detects greenfield vs existing, asks for name/description/stack, copies `.claude/` + `.github/` + `.helmforge/`, generates `CLAUDE.md`, and optionally installs skills + MCP servers. Everything below is the manual equivalent.

### Step 1 — Install Claude Code
```bash
npm install -g @anthropic-ai/claude-code@latest
claude          # first run opens a browser for OAuth login
claude --version
```

### Step 2 — Copy the kit into your project
```bash
cd /path/to/your-project
tar -xzf helmforge.tar.gz
cp -r helmforge/.claude .
cp -r helmforge/.github .
cp -r helmforge/.helmforge .
cp helmforge/CLAUDE.md.template ./CLAUDE.md
cp helmforge/constitution.md .
chmod +x .claude/hooks/*.sh .helmforge/*.sh .helmforge/scripts/*.sh
```

### Step 3 — Edit CLAUDE.md (the most important step)
Open `CLAUDE.md`, replace every `🔴 EDIT THIS` line, and make the `## Stack` section match your real frameworks. Agents read this file on every run.

### Step 4 — Install skills from skills.sh
```bash
.helmforge/install-skills.sh
```
Runs `npx skills add ...` for 27 external skills (product/PM/design/frontend/backend/QA/devops/review). Each skill's audit status is noted in the script — review sensitive ones.

### Step 5 — Install MCP servers
```bash
# 5a. GitHub (fine-grained PAT: Contents R/W, Pull requests R/W)
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  -H "Authorization: Bearer $GITHUB_PAT"

# 5b. Context7 (free key at context7.com — prevents API hallucination)
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp --api-key $CONTEXT7_KEY

# 5c. Sequential thinking (for PO/PM)
claude mcp add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking

# 5d. Postgres (read-only; for BA/BE)
claude mcp add postgres -- docker run -i --rm crystaldba/postgres-mcp-pro:latest \
  --connection-uri "$DATABASE_URL" --access-mode=restricted

# 5e. Playwright (for UX/QA)
claude mcp add playwright -- npx @playwright/mcp@latest
npx playwright init-agents --loop=claude

# 5f. Vercel + 5g. Sentry (for DevOps; OAuth in browser)
claude mcp add --transport http vercel https://mcp.vercel.com
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
```
Verify with `claude` then `/mcp`.

### Step 6 — GitHub Actions
```bash
claude setup-token           # copy the sk-ant-oat01-... output
# GitHub → Settings → Secrets → Actions → new secret CLAUDE_CODE_OAUTH_TOKEN
```

### Step 7 — Install the GitHub App
In Claude Code, run `/install-github-app` and follow the prompts (enables `@claude` on issues/PRs).

### Step 8 — Smoke test
```bash
claude
> /sdlc:quick Fix a trivial typo somewhere harmless
```
If an agent runs, writes a small change, and proposes a PR, you're set.

---

## 4. Daily use

### Mode 0: New project — `/sdlc:init`
```bash
claude
> /sdlc:init A subscription billing dashboard for SaaS teams. Next.js + NestJS + Postgres.
```
solution-architect chooses the stack, scaffolds a feature-based monorepo + walking skeleton, writes ADRs + CLAUDE.md + initializes the living BRD, then builds the first feature.

### Mode 1: Terminal — `/sdlc` (feature/bug)
```bash
claude
> /sdlc Add forgot-password. /login has a "Forgot password?" link → email → reset link valid 30 min → set new password. Rate limit 3/hour per email.
```

### Mode 2: Headless / background
```bash
claude -p "/sdlc <ticket>" > run.log 2>&1 &
tail -f run.log
```

### Mode 3: GitHub issue + `@claude`
1. Open an issue describing the ticket.
2. Comment `@claude /sdlc implement this`.
3. A PR opens automatically.

### Mode 4: Small work — `/sdlc:quick`
```bash
> /sdlc:quick Fix off-by-one in pagination: last page missing 1 item (utils/paginate.ts)
```
Runs a lite path (1-3 agents), skipping vision/plan/design.

---

## 5. Understanding the agent pipeline

- **🟣 Product Owner** — value, scope, KPIs, kill criteria → `product-brief.md`. Opus.
- **🔵 Project Manager** — task breakdown, dependency DAG with `[P]` parallel markers, risks, tier recommendation → `plan.md` + `tasks.yaml`.
- **🔷 Business Analyst** — requirements, acceptance (`.feature`), `openapi.yaml`, Prisma schema diff, and the living BRD; emits a consolidated `<US-ID>-spec.md` that links canonical artifacts (anti-drift).
- **🌸 UX/UI Designer** — prototypes + `ux-spec.md`, WCAG 2.2 AA, design tokens.
- **🟠 Frontend + 🟢 Backend Engineer** (parallel) — framework-adaptive implementation with tests; brownfield-aware (read before write, minimal diff, match conventions).
- **🟡 QA Engineer** — Playwright + axe-core tests, files bugs.
- **⚪ DevOps Engineer** — deploy/preview, CI gate + bounded auto-fix, Sentry, migration gates.
- **🔴 Code Reviewer** — enforces `constitution.md` (blocking), OWASP Top 10 2025, perf budgets, spec coverage; on APPROVE + green CI flips the BRD records to `shipped`. Opus.

Opus is used for product-owner, solution-architect, and code-reviewer; Sonnet for the rest.

---

## 6. Writing good tickets

### Template
```
<What> — one sentence of the outcome.
<Who/why> — the user and the value.
<Acceptance> — observable conditions ("user can…", "returns 422 when…").
<Constraints> — limits, rate limits, security, budgets.
<Out of scope> — what NOT to build.
```

### Bad vs good
- ❌ "Add login." (ambiguous: which method? sessions? lockout?)
- ✅ "Add email+password login. Session via httpOnly cookie, 7-day sliding expiry. Lock after 5 failed attempts/15 min. Return identical 401 for wrong email vs wrong password (no enumeration). Out of scope: OAuth, 2FA."

### Ticket types
- **Feature** — lead with user value + acceptance.
- **Bug** — steps to reproduce, expected vs actual, the offending file if known.
- **Refactor/tech-debt** — state the invariant that must not change; ask for characterization tests first.

---

## 7. Reading and handling human checkpoints

The pipeline stops and asks you when a decision is irreversible or outside its authority.

### Checkpoint types
- **Ambiguity** — the spec is underspecified; `/sdlc:clarify` asks a focused question and folds your answer back into the BRD.
- **Budget** — the estimated tier exceeds `confirm_if_agents_over`; confirm or downgrade.
- **Risk gate** — architecture/security/payments/multi-system change (tier `large`) needs explicit human approval.
- **Broken baseline** — preflight found main doesn't build/test; fix the environment or main first.
- **Human action required** — something only a human can do (sign up, get a key, configure DNS).

### Human-action guides
When a task needs an external human step, the agent writes `docs/human-actions/<id>-<name>.md` (why it's needed, the exact steps, a verify command, security notes), stubs the code to fail fast, and surfaces it in the PR. Example structure:
```
# Human Action: Sign up for SendGrid + get an API key
## Why it's needed
## Steps
## Verify   →  expected: "✓ SendGrid connection OK, sender verified"
## Security  →  set a spend cap; store the key in the secret manager, not .env in git
```

---

## 8. Reviewing an agent's PR

### Review checklist
- Does it satisfy the acceptance criteria / BRD record?
- Tests present and meaningful (not just snapshots)? Do they actually run in CI?
- Security: input validation, authz, no secrets in code, OWASP 2025 items.
- Perf budgets respected (bundle size, query counts, N+1)?
- Minimal diff — no gratuitous refactors; existing conventions followed (brownfield).
- Migrations expand-contract safe and reversible?
- Human-action guides present for anything you must do.

### A good review
Approve specifics, not vibes: "Token is single-use (DB `used_at`), 30-min TTL, rate-limited 3/hr/email — matches spec. One concern: the reset endpoint leaks timing; constant-time compare would close it." The reviewer agent already grills the code; your job is judgment + merge.

---

## 9. Managing cost

### Max 20x is effectively required
Full pipelines run many agents with high-effort reasoning. The 20x Max plan is the realistic floor for running complete `/sdlc` flows without constant rate-limiting.

### Monitor usage
```bash
# in a claude session
/cost
/status
```

### When you hit rate limits
Wait 30–60 minutes and retry, or downgrade the tier (`/sdlc:quick`, `--tier small`).

### Cut cost when needed
- Use `/sdlc:quick` and `--tier` to right-size.
- Lower effort in `.helmforge/pipeline.config.yaml` (`effort_by_tier`) or per-agent frontmatter:
```yaml
# from:
effort: high
# to:
effort: medium
```
- Honest limit: Claude Code can't hard-cap dollars via a hook. The kit right-sizes + warns + confirms; the real ceiling is your plan. Watch `/cost`.

---

## 10. Customizing and extending

### Enable/disable agents (frontend-only / backend-only)
```bash
.helmforge/configure-agents.sh --status
.helmforge/configure-agents.sh --profile frontend     # disable backend-engineer
.helmforge/configure-agents.sh --profile backend      # disable ux-ui-designer + frontend-engineer
.helmforge/configure-agents.sh --interactive
```
Disabled agents move to `.claude/agents-disabled/` so Claude Code won't call them. The CLAUDE.md "Active Agents" block updates on each run.

### Add a convention to CLAUDE.md
```md
## Conventions (add new rules here)
- All money is integer cents; never floats.
- API errors follow RFC 9457 problem+json.
```

### Adapt to another stack
Edit `.helmforge/stack.config.yaml`, then `.helmforge/configure-agents.sh --sync-skills`. For a framework without a dedicated skill, agents pull docs via Context7. To bake in idioms, add a line to the "Framework Adaptation" table in `.claude/agents/<agent>.md` (e.g. a Go engineer: PostToolUse hook runs `gofmt -w && golangci-lint run`).

### Add a skills.sh skill to an agent
Install it via `.helmforge/install-skills.sh` (add the `npx skills add ...` line), then add the skill name to the `skills:` list in the relevant agent.

### Create a new agent
Copy an existing `.claude/agents/*.md`, give it a `name` + `description` with a "MUST BE USED for X" trigger, list its skills, and add it to `.helmforge/agents.config.yaml`.

---

## 11. Troubleshooting

| Problem | Fix |
|---|---|
| `npx skills` not found | Need Node 20+ and internet |
| Skill doesn't load | Verify `.claude/skills/<name>/SKILL.md`; restart `claude` |
| Agent won't self-delegate | Description needs a "MUST BE USED for X" pattern |
| Cost burns fast | Lower `effort: high` → `medium`; use `/sdlc:quick` |
| Hook doesn't fire | `chmod +x .claude/hooks/*.sh` |
| `--doctor` reports issues | Run `.helmforge/configure-agents.sh --doctor` and fix what it lists |

### Debug a specific agent
Inspect the latest session transcript (`transcript.jsonl` in the project's Claude folder), or run one agent in isolation: `> Use the qa-engineer subagent to ...`.

### Reset a stuck pipeline
Delete or fix `docs/specs/<ticket>/pipeline-state.yaml`, then `/sdlc:resume <ticket>` (continues where it left off) or rerun `/sdlc`.

---

## 12. FAQ

- **Do I still review every PR?** Yes. This is a senior-team simulator with leverage, not set-and-forget. The reviewer is an LLM and can be wrong; you merge.
- **Does it work on existing repos?** Yes — that's the main use case. Run `/sdlc:onboard` once, then `/sdlc`.
- **Windows?** Use WSL or Git Bash (the installer/scripts are bash).
- **Can I run only some phases?** Yes — `/sdlc:<phase>`; they're order-flexible.
- **Will it touch my secrets / run dangerous commands?** Hooks block dangerous Bash and writes to secret files (see the cheat sheet).
- **Is the product name the same as the command namespace?** No — the product is HelmForge; commands stay under `/sdlc:*` because that name describes what they do.

---

## 13. Cheat sheet

### Common commands
```bash
claude                                  # start a session
/sdlc:init <description>                # new project from zero
/sdlc <ticket>                          # full pipeline (feature/bug)
/sdlc:quick <ticket>                    # lite path (1-3 agents)
/sdlc:<phase> <scope>                   # one phase (vision|plan|brd|clarify|design|build|qa|deploy|review)
/sdlc:resume <ticket>                   # continue a paused pipeline
/sdlc:onboard                           # analyze an existing repo (run once)
> Use the <agent> subagent to ...       # run one agent
/cost          /status         /mcp     # cost, usage, MCP connections
/compact                                # compact a long context
```

### Agent frontmatter shortcuts
```yaml
effort: medium        # lower cost (high|medium|low)
model: claude-opus-4-...   # change model for that agent
```

### Hooks quick reference
```
block-dangerous.sh blocks:
  - rm -rf (/|~|$HOME|*|.git|..)
  - terraform destroy
  - DROP DATABASE / DROP TABLE
  - git push --force main/master
  - prisma migrate dev

protect-secrets.sh blocks writes to:
  - .env, .env.local, .env.production, .env.staging
  - secrets/**, credentials/**
  - *.pem, *.key, id_rsa, id_ed25519, *.vault.yml, kubeconfig
```

### Quick ticket template
```
<What> + <who/why> + <acceptance> + <constraints> + <out of scope>
```

### Quick PR-review checklist
acceptance met · tests real + in CI · security/OWASP · perf budgets · minimal diff · migrations safe · human-actions present

### Escalation keywords
```
The agent will stop and ask if it detects:
  architecture change · security/auth · payments · data migration · irreversible action · ambiguity
Reply to continue with your decision, then it proceeds.
```

---

## Support and references
- README: `README.md` · Commands: `docs/COMMANDS.md` · Principles: `constitution.md`
- skills.sh: https://www.skills.sh
- Each role's full behavior: `.claude/agents/*.md`

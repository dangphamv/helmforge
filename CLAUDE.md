# Project Name
<!-- 🔴 EDIT THIS: Project name + one-line description -->
One-sentence project description.

## Stack
<!-- 🔴 EDIT THIS: Change if your stack differs -->
- **Web**: Next.js 15 App Router, React 19, TypeScript 5.x strict, Tailwind v4, shadcn/ui
- **API**: NestJS 11, Prisma 6, Postgres 16, Redis 7 (queues/cache)
- **Tests**: Vitest + Testing Library (web), Jest + Supertest (api), Playwright 1.56+ (e2e)
- **Lint**: ESLint + Prettier (format-on-save)
- **Package manager**: pnpm 9 (NEVER npm/yarn)
- **Node**: 20+

## Commands
- `pnpm dev` — start all apps (web :3000, api :4000)
- `pnpm test` — all tests
- `pnpm test --filter @acme/web` / `--filter @acme/api` — scoped
- `pnpm lint` / `pnpm typecheck`
- `pnpm prisma migrate dev --name <desc>` — LOCAL only (CI uses `migrate deploy`)
- `pnpm prisma generate` — regenerate client

## Project Structure
```
apps/
  web/          → Next.js (App Router)
  api/          → NestJS
packages/
  shared/       → Shared Zod schemas, types
  email/        → Email templates
prisma/
  schema.prisma → SSOT
  migrations/   → Generated, never hand-edit (unless --create-only for expand/contract)
docs/
  specs/<ticket>/  → product-brief, plan, requirements, acceptance.feature, ux-spec
  adr/             → Architecture Decision Records
api/
  openapi.yaml  → OpenAPI 3.1 contract (BA-owned)
```

## Conventions

### API
- Response: `{ ok: true, data: T }` | `{ ok: false, error: { code, message } }` (RFC 7807-compatible)
- All controllers use `ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true })`
- All non-public endpoints have a guard (`@UseGuards(JwtAuthGuard, RolesGuard)`)
- DB writes through service classes — never controllers
- Prisma queries ALWAYS use `select`/`include` (no nakedfind)
- Migrations: additive by default; expand-and-contract (3 deploys) for any rename/drop

### Frontend
- Server Components by default. `'use client'` only for state/effects/browser APIs
- React 19: `useActionState` for forms, `useOptimistic` for mutations, `useFormStatus` for submit buttons
- Tailwind v4: `@theme` in CSS (no `tailwind.config.js`); OKLCH colors; container queries (`@container`)
- shadcn/ui via registry; wrap don't fork; use `data-slot` for variants
- Forms: react-hook-form + Zod resolver
- Data: TanStack Query v5 (client islands) or Server Component `fetch({ next: { revalidate }})`
- Performance budget: route JS ≤170KB, LCP ≤2.5s, INP ≤200ms, CLS ≤0.1

### Git
- Branch: `feat/<ticket-id>-<kebab>` | `fix/<ticket-id>-<kebab>`
- Commits: Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `chore:`, `refactor:`)
- Never force-push `main`
- PRs require: green CI + code-reviewer approval

### Testing
- Coverage ≥80% on changed files (CI gate)
- Selectors: `getByRole`, `getByLabel` (accessibility-tree first); `data-testid` only as last resort
- No `waitForTimeout` (sleep); use `expect.poll` / `waitFor`

## Patterns to AVOID
- ❌ `npm` or `yarn` install
- ❌ Business logic in Next.js Server Actions (delegate to API)
- ❌ Raw SQL outside reviewed `$queryRaw` exceptions
- ❌ New state managers, HTTP clients, form libs, test runners (use existing)
- ❌ `prisma migrate dev` in CI/staging/prod
- ❌ Dropping/renaming columns in a single migration
- ❌ `'use client'` on layouts (push boundary down)
- ❌ Modifying CI/CD/infra without devops-engineer review

## SDLC Pipeline (autonomous flow)
When a ticket comes in (via `/sdlc` slash command or `@claude` mention), agents run in order:

```
1. product-owner       → product-brief.md (value, KPI, scope, kill criteria)
2. project-manager     → plan.md + tasks.yaml (T-shirt sizes, DAG, risks)
3. business-analyst    → requirements.md + openapi.yaml + acceptance.feature + schema.prisma
4. ux-ui-designer      → ux-spec.md + wcag-audit.md (parallel with BE)
5a. frontend-engineer  → React/Next.js implementation + Vitest tests
5b. backend-engineer   → NestJS module + Prisma migration + Jest/Supertest
6. qa-engineer         → Playwright agents + axe-core; files bugs as GitHub issues
7. devops-engineer     → Preview deploy, Sentry release, migration safety gate
8. code-reviewer       → Final OWASP/perf/test review; APPROVE or REQUEST_CHANGES
```

If at any phase the spec is ambiguous → agent STOPS and posts clarifying questions.
Large/risky tickets get human checkpoints at: spec sign-off, design sign-off, pre-merge.

## Three modes of operation

| Mode | Command | When | Extra agent |
|------|---------|------|-------------|
| **Init new project** | `/sdlc:init <description>` | Empty repo, building from zero | `solution-architect` (scaffolds skeleton, writes ADRs, sets conventions) |
| **Implement feature** | `/sdlc <ticket>` | Add a feature to existing codebase | — |
| **Fix bug** | `/sdlc <ticket>` or `@claude` | Fix a defect | — |

**Init mode** runs PO → PM → solution-architect (scaffold + walking skeleton + ADRs + CLAUDE.md) → then the first real feature through BA → UX → FE/BE → QA → DevOps → Reviewer. Skeleton must work end-to-end (page → API → DB → render, CI green, deployed) before the first feature starts.

## Human-action handoff guides

Whenever implementation depends on something only a human can do — register a third-party account, retrieve an API key from a dashboard, configure DNS, register an OAuth app, upgrade a paid plan — the responsible agent (usually backend-engineer or devops-engineer) MUST:
1. Emit a step-by-step guide at `docs/human-actions/<id>-<slug>.md` (exact URLs, where to store the result, a verification command).
2. Append it to the master checklist `docs/human-actions/README.md`.
3. Stub the code to fail fast with a pointer to the guide (never a silent undefined env var).
4. Surface it in the PR description under "⚠️ Human action required before this works in production".

See `.claude/skills/human-action-guide/SKILL.md`.

## Voice & Writing Style (apply to ALL agent outputs)

Every agent loads the `expert-voice` skill first. Outputs must read like a senior practitioner, not an AI. This is non-negotiable.

**Banned in all outputs:**
- Opener clichés: "I'd be happy to...", "Great question!", "Certainly!", "Let me walk you through..."
- Hedge padding: "It's worth noting that...", "You might want to consider...", "Generally speaking..."
- Closer clichés: "In summary...", "Let me know if you have any questions", "Hope this helps!"
- Hollow words: leverage, robust, scalable, seamless, elegant, intuitive, comprehensive, simply, just, basically, essentially
- Marketing-speak: "world-class", "industry-standard", "state-of-the-art", "production-ready" (without listed SLOs)
- Restating the question / mirror-the-prompt openers
- Symmetric 3-bullet lists where prose would flow naturally

**Required in all outputs:**
- Specifics: numbers (with units), names, versions, file paths, error codes
- Owned trade-offs: pick a side, name what you gave up
- Calibrated confidence: strong claims with evidence; admit uncertainty when real
- Restraint: cut padding; silence where AI would over-explain

Each agent has additional role-specific anti-patterns in its `# Voice` section. See `.claude/skills/expert-voice/SKILL.md` for the full guide.

## Reference Docs
<!-- Add paths to docs agents should read on demand -->
<!-- @docs/api-architecture.md -->
<!-- @docs/data-model.md -->
<!-- @docs/security-policy.md -->

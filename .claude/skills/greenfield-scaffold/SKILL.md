---
name: greenfield-scaffold
description: How to bootstrap a brand-new Next.js 15 + NestJS 11 + Prisma 6 monorepo from zero — folder structure, tooling, CI/CD, env templates, first vertical slice. Use when initializing a new project (the /sdlc:init command), not when adding features to an existing repo.
---

# Greenfield Project Scaffold

Bootstrapping a new project is different from feature work. You're setting conventions that every future ticket inherits. Get the foundation right; it compounds.

## Principle: walking skeleton first

Don't scaffold everything then implement. Build the thinnest end-to-end vertical slice that proves the whole stack works:

```
A user can load a page → it calls the API → the API reads the DB → returns data → renders.
```

If that round-trip works and is tested and deployed, every subsequent feature is "just more of the same." Ship the skeleton before the second feature.

## Target structure (pnpm monorepo)

Internal packages use the `@<project>/` prefix and `workspace:*` protocol. Apps are feature-based inside (see "Internal layout" below — this is the part that compounds).

```
<project>/
├── apps/
│   ├── web/                    # Next.js 15  →  thin routes, fat features
│   │   ├── src/
│   │   │   ├── app/             # ROUTING ONLY (page.tsx readable in 30s)
│   │   │   ├── features/        # the real work: features/<domain>/{components,actions,hooks}
│   │   │   ├── components/ui/    # shadcn primitives ONLY (dumb, shared)
│   │   │   └── lib/             # api client, auth helper, cross-cutting utils
│   │   ├── next.config.ts       # transpilePackages: ["@<project>/contracts","@<project>/ui"]
│   │   └── package.json         # deps: "@<project>/db":"workspace:*", "@<project>/contracts":"workspace:*"
│   └── api/                    # NestJS 11  →  domain modules + 3 support folders
│       ├── src/
│       │   ├── core/            # config, auth, prisma provider, redis, logger
│       │   ├── common/          # pipes, guards, decorators, filters, interceptors
│       │   ├── integrations/    # stripe.service.ts, sendgrid.service.ts (vendor wrappers)
│       │   ├── modules/         # DOMAIN modules (feature-based): users/, billing/, ...
│       │   ├── app.module.ts
│       │   └── main.ts
│       └── package.json         # deps: "@<project>/db":"workspace:*", "@<project>/contracts":"workspace:*"
├── packages/
│   ├── db/                     # @<project>/db — SINGLE SOURCE OF TRUTH for data
│   │   ├── prisma/schema.prisma  # the ONE schema + migrations/
│   │   └── src/{client.ts,index.ts}
│   ├── contracts/              # @<project>/contracts — Zod schemas (validation + types, both ends)
│   │   └── src/<domain>/*.schema.ts
│   ├── ui/                     # @<project>/ui — shared shadcn components (only if web + admin both exist)
│   └── config/                 # @<project>/config — shared tsconfig, eslint, tailwind preset
├── docs/{adr,specs,human-actions}/
├── .github/workflows/{ci.yml,claude.yml}
├── docker-compose.yml          # postgres:16 + redis:7
├── .env.example
├── pnpm-workspace.yaml
├── turbo.json                  # task graph — see "Turborepo task graph" below
├── CLAUDE.md                   # encodes the structure rules so every agent inherits them
└── README.md
```

## Bootstrap sequence

### 1. Init workspace
```bash
mkdir <project> && cd <project>
pnpm init
cat > pnpm-workspace.yaml <<'EOF'
packages:
  - "apps/*"
  - "packages/*"
EOF
pnpm add -Dw turbo typescript @types/node prettier eslint
```

### 2. Scaffold web (Next.js 15)
```bash
cd apps
pnpm create next-app@latest web --typescript --tailwind --app --no-src-dir --use-pnpm
cd web && pnpm dlx shadcn@latest init
```

### 3. Scaffold api (NestJS 11)
```bash
cd ../  # apps/
pnpm dlx @nestjs/cli new api --package-manager pnpm --skip-git
```

### 4. Set up Prisma (shared package)
```bash
cd ../packages && mkdir db && cd db
pnpm init && pnpm add prisma @prisma/client
pnpm prisma init --datasource-provider postgresql
```

`packages/db/prisma/schema.prisma` — start minimal:
```prisma
generator client {
  provider = "prisma-client-js"
  output   = "../generated/client"
}
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// First model — proves the skeleton end-to-end
model HealthCheck {
  id        String   @id @default(cuid())
  status    String   @default("ok")
  checkedAt DateTime @default(now())
}
```

### 5. docker-compose for local dev
```yaml
services:
  postgres:
    image: postgres:16
    environment: { POSTGRES_USER: dev, POSTGRES_PASSWORD: dev, POSTGRES_DB: app }
    ports: ["5432:5432"]
    volumes: ["./.pgdata:/var/lib/postgresql/data"]
  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
```

### 6. The walking skeleton
- **API:** `GET /healthz` → reads `HealthCheck` table → returns `{ ok, status, checkedAt, gitSha }`
- **Web:** a page that fetches `/healthz` (Server Component) and renders the status
- **Test:** Supertest hits `/healthz` (200 + shape); Playwright loads the page and asserts the status text
- **CI:** `ci.yml` runs lint + typecheck + test + build on every PR
- **Deploy:** Vercel for web, Fly.io/Railway for api; preview on PR

### 7. .env.example (always current)
```bash
# Database
DATABASE_URL="postgresql://dev:dev@localhost:5432/app"
SHADOW_DATABASE_URL="postgresql://dev:dev@localhost:5432/app_shadow"

# Redis
REDIS_URL="redis://localhost:6379"

# API
API_PORT=4000
JWT_SECRET=""          # generate: openssl rand -base64 32

# Web
NEXT_PUBLIC_API_URL="http://localhost:4000"

# Third-party (see docs/human-actions/ for setup guides)
# SENDGRID_API_KEY=""   # → docs/human-actions/sendgrid.md
# STRIPE_SECRET_KEY=""  # → docs/human-actions/stripe.md
```

## Variant: co-located API (`backend.framework: next-api` + Supabase)

If `.helmforge/stack.config.yaml` sets `backend.framework: next-api`, do NOT scaffold `apps/api`. The API lives inside the single Next.js app:

```
<project>/
├── src/
│   ├── app/                    # routes + app/api/*/route.ts (webhooks, public endpoints)
│   ├── features/<domain>/
│   │   ├── components/          # (frontend-engineer)
│   │   └── actions.ts           # Server Actions — mutations (backend-engineer)
│   └── lib/
│       ├── supabase/            # server + browser clients (@supabase/ssr)
│       └── db/                  # (optional) Drizzle/Prisma if not using supabase-js direct
├── supabase/
│   ├── migrations/*.sql         # schema + RLS policies (backend-engineer)
│   └── config.toml
├── packages/contracts/          # shared Zod (still worth it even single-app)
└── (no apps/api, no packages/db unless using Drizzle/Prisma)
```

- One app, two agents: `frontend-engineer` (UI + read-side Server Components) and `backend-engineer` (Server Actions, route handlers, Supabase schema/RLS/migrations). profile stays `fullstack`.
- Supabase = data layer. RLS on every user-data table. `@supabase/ssr` for cookie auth. `anon` key client-side, `service_role` server-only.
- Walking skeleton for this variant: a page that reads one row from Supabase through a Server Component + a Server Action that writes one row, with RLS on — deployed to Vercel, env keys via the Supabase human-action guide.
- Emit `docs/human-actions/<id>-supabase.md` (project URL + keys) — see `human-action-guide` skill.

For a heavier or polyglot API, keep the default `apps/api` (NestJS/Fastify/etc.) instead of `next-api`.

## Internal layout — feature-based (the rule that compounds)

Inside each app, organize by **domain feature, never by technical layer**. A change to one feature should touch one folder, not five.

### Web (`apps/web/src/`)

```
app/(dashboard)/billing/page.tsx     # thin: fetch via feature fn → render feature view
features/billing/
├── components/InvoiceList.tsx         # feature-private UI
├── actions.ts                         # Server Actions
├── hooks/useInvoices.ts
└── index.ts                           # PUBLIC API — only this is importable from outside
components/ui/button.tsx                # shadcn primitive (dumb, shared)
lib/api-client.ts                       # cross-cutting
```

A `page.tsx` reads in 30 seconds:
```tsx
import { getInvoices } from '@/features/billing/actions';
import { InvoiceList } from '@/features/billing';   // public index, not deep path
export default async function Page() {
  const invoices = await getInvoices();
  return <InvoiceList invoices={invoices} />;
}
```

### API (`apps/api/src/`)

```
modules/billing/
├── billing.controller.ts   # thin: route + validate + delegate
├── billing.service.ts      # business logic
├── billing.module.ts       # exports ONLY what others inject: exports: [BillingService]
├── dto/create-invoice.dto.ts   # via nestjs-zod, from @<project>/contracts
└── billing.service.spec.ts
core/        # config, auth, prisma provider, redis, logger
common/      # pipes, guards, decorators, filters, interceptors
integrations/  # stripe.service.ts — swap a vendor = touch one file
```

**Dependency direction is law:** `app/`→`features/`→`lib/`/`packages/`. Features never import another feature's internals — share through `@<project>/contracts` or the feature's public `index.ts`. This is Feature-Sliced Design: refactor blast-radius = one slice, not the repo.

## packages/db — single source of truth for data

```ts
// packages/db/src/client.ts
import { PrismaClient } from '../generated/client';
const g = globalThis as unknown as { prisma?: PrismaClient };
export const prisma = g.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== 'production') g.prisma = prisma;

// packages/db/src/index.ts
export { prisma } from './client';
export * from '../generated/client';   // re-export Prisma types
```

- Install Prisma at the **root** (avoids version drift across packages).
- `apps/api` imports `@<project>/db` for queries; `apps/web` imports **types only** (never opens a DB connection client-side).
- One schema, one migration history, one place to reason about the model.

## packages/contracts — kill front/back type drift

Zod is the single source of truth. Define once → runtime validation + TS type everywhere. (Prevents the `userId`→`user_id` silent-drift class of bug.)

```ts
// packages/contracts/src/billing/create-invoice.schema.ts
import { z } from 'zod';
export const CreateInvoiceSchema = z.object({
  customerId: z.string().cuid(),
  amountCents: z.number().int().positive(),
  currency: z.enum(['USD', 'VND']),
});
export type CreateInvoice = z.infer<typeof CreateInvoiceSchema>;
```

- API: `nestjs-zod` turns the schema into a DTO that plugs into the ValidationPipe AND `@nestjs/swagger` (runtime OpenAPI matches the contract).
- Web: the SAME schema feeds react-hook-form's `zodResolver` and types the fetch response.
- Keep BA's `api/openapi.yaml` in lockstep with these schemas.

## Shared packages export raw TS source

Don't ship compiled JS from `packages/*`. Export source; let each app transpile per its runtime:
```ts
// apps/web/next.config.ts
const config = { transpilePackages: ['@<project>/contracts', '@<project>/ui'] };
```
This sidesteps the CJS/ESM war (NestJS wants CJS, Next/Vite want ESM). One source of truth, each consumer transpiles its own way.

## Turborepo task graph (not optional)

A wrong graph turned one team's CI from 90s into 26 minutes ($4,200/mo) because everything rebuilt everything. Define `dependsOn` + `outputs` so only affected packages rebuild:

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build":     { "dependsOn": ["^build"], "outputs": ["dist/**", ".next/**"] },
    "typecheck": { "dependsOn": ["^build"] },
    "test":      { "dependsOn": ["^build"] },
    "lint":      {},
    "dev":       { "cache": false, "persistent": true }
  }
}
```

`^build` = build this package's workspace dependencies first. Set CI `concurrency` to cancel stale runs on force-push. Turborepo under ~10 packages; reach for Nx only when you need enforced module boundaries + generators.

## ADRs to write at init time

Every greenfield project starts with these Architecture Decision Records in `docs/adr/`:

1. **ADR-0001: Stack choice** — why Next.js + NestJS + Prisma + Postgres (vs alternatives)
2. **ADR-0002: Monorepo tooling** — Turborepo vs Nx vs none; why
3. **ADR-0003: Auth strategy** — JWT vs session; cookie vs header; refresh rotation
4. **ADR-0004: Deployment targets** — Vercel + Fly.io; preview strategy
5. **ADR-0005: Shared contracts** — how FE and BE share types (packages/contracts via Zod + OpenAPI)

Keep each ADR to: Context → Decision → Consequences → Alternatives Considered. One page max.

## Conventions to set in CLAUDE.md at init

The architect must write the project's CLAUDE.md before the first feature, fixing:
- **Source structure rules** (so every agent inherits them): feature-based not layer-based; `app/` thin + `features/` fat (web); `core/`+`common/`+`integrations/`+`modules/` (api); one `packages/db`; one `packages/contracts` (Zod source of truth); unidirectional deps + public `index.ts` per slice; `@<project>/` naming + `workspace:*`
- Response envelope (`{ ok, data }` / `{ ok, error }`)
- Naming (camelCase fields, PascalCase types, kebab routes)
- State management (Zustand, no Redux)
- Form library (react-hook-form + Zod from `@<project>/contracts`)
- Test runners (Vitest web, Jest api, Playwright e2e)
- Migration policy (additive default, expand-and-contract for destructive)
- Commit convention (Conventional Commits)

## What NOT to do at init

- ❌ Scaffold 12 modules before any of them is tested end-to-end
- ❌ Add auth, billing, notifications all at once — skeleton first, then ONE real feature
- ❌ Choose exotic tooling that no one on the team knows
- ❌ Skip CI setup ("we'll add it later" = never)
- ❌ Commit a `.env` with real values instead of `.env.example`
- ❌ Pick a database without ACID when the domain needs transactions
- ❌ Defer the first deploy — deploy the skeleton on day one
- ❌ **Layer-based folders** (`controllers/`/`services/`/`dtos/`) — regret guaranteed past ~20 controllers
- ❌ **Flat `/components`** dump — feature-private UI goes in `features/<x>/components/`
- ❌ **Duplicated FE/BE types** — one Zod schema in `packages/contracts`
- ❌ **Multiple Prisma schemas/clients** — one `packages/db`, Prisma at root
- ❌ **Everything-depends-on-everything** — define the Turborepo `dependsOn` graph
- ❌ **Compiled JS from shared packages** — export raw TS + `transpilePackages`

## Definition of a successful init

- [ ] `pnpm install && pnpm dev` starts web + api locally
- [ ] `GET /healthz` returns 200 with DB round-trip
- [ ] Web page renders the health status (proves FE→API→DB→FE)
- [ ] `pnpm test` passes (≥1 unit + 1 integration + 1 e2e)
- [ ] CI green on a PR
- [ ] Skeleton deployed (preview URL works)
- [ ] 5 ADRs written
- [ ] CLAUDE.md complete with conventions
- [ ] `.env.example` covers every var; `docs/human-actions/` has guides for any third-party setup

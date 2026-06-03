---
name: codebase-analysis
description: How to understand an existing/legacy repository before changing it — map structure, extract the conventions actually in use, find entry points and the dependency graph, locate tests and CI, and surface risky areas. Use when onboarding to an existing repo (the /sdlc:onboard command) or before adding a feature / fixing a bug in unfamiliar code.
---

# Codebase Analysis — understand before you touch

The #1 brownfield failure is imposing the "ideal" structure on a repo that already has its own. Your job on existing code is to **discover and match what's there**, not to refactor it to taste. Read first. Conform. Change the minimum. Refactor only when the ticket asks and the tests back you up.

## The golden rule

> The existing repo's conventions WIN over this kit's defaults. The kit's opinionated structure (feature-based, monorepo, `@<project>/contracts`) is for greenfield. In a brownfield repo, match the patterns already in use — even if they're not what you'd pick — unless the ticket is explicitly a refactor.

## Analysis pass (do this before writing any code)

### 1. Orient — what is this?
- `README.md`, `CONTRIBUTING.md`, `docs/`, any `ARCHITECTURE.md`
- `package.json` / `pyproject.toml` / `go.mod` / `Gemfile` / `pom.xml` → language, framework, scripts, deps
- Lockfile → package manager (pnpm/npm/yarn/poetry/…)
- `.github/workflows`, `.gitlab-ci.yml` → how it builds, tests, deploys
- Monorepo? (`pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json`)

### 2. Map the structure
- Top 2-3 directory levels (`view` the tree). Is it layer-based (`controllers/services/`) or feature-based (`features/`/`modules/`)? **Whatever it is, you follow it.**
- Where do routes/pages live? Where does business logic live? Where do tests live (colocated vs `__tests__/` vs `/test`)?
- Find the entry points: `main.ts`/`index.ts`/`app/`/`manage.py`/`cmd/`.

### 3. Extract the conventions ACTUALLY in use (not the ideal)
Read 3-5 representative files in each area and note:
- Naming: camelCase vs snake_case fields; file naming (`UserCard.tsx` vs `user-card.tsx`); route style.
- API response shape: `{ data }`? `{ ok, data }`? bare objects? error format?
- Data access: ORM? raw SQL? repository pattern? Which ORM, which version?
- State management (FE): Redux? Zustand? Context? Which?
- Forms/validation: Zod? Yup? class-validator? none?
- Auth pattern: JWT? sessions? a library (Auth.js/Passport/Clerk)?
- Error handling: exceptions? Result types? try/catch style?
- Import style: aliases (`@/`)? relative? barrel files?

### 4. Find the test + quality setup
- Test runner + how to run a single test
- Coverage expectation (if any), existing coverage level
- Linter/formatter config — match it exactly (don't reformat untouched lines)
- Type checking strictness

### 5. Dependency + impact map
- For the area you'll touch: who calls it? (grep for the symbol/route). What depends on it?
- Shared modules/utilities you must not break.
- Public API surface (exported things other code/consumers rely on).

### 6. Surface risk
- Areas with no tests (change carefully, add characterization tests first)
- `// TODO`/`// HACK`/`// FIXME` clusters, `any` soup, god files (>500 lines)
- Migrations history — how are schema changes done here?
- Anything that looks load-bearing and fragile

## Output: an accurate picture, written down

After the pass, produce (or update) these so every agent inherits the truth:

- **`CLAUDE.md`** — generated from REALITY: actual commands, actual structure, actual conventions, actual "patterns to avoid" observed. Not the template defaults.
- **`docs/architecture-map.md`** — directory map, where things live, the data flow (request → handler → service → db → response), the conventions table, the test strategy, and a "danger zones" list.
- **`.helmforge/stack.config.yaml`** — set to what you DETECTED (framework, orm, db, pm), not the kit defaults.

## CLAUDE.md from reality — template

```markdown
# <repo name> (existing codebase — analyzed <date>)

## Stack (detected)
- <language/framework/versions as found>
- Package manager: <detected from lockfile>

## Commands (from package.json scripts / Makefile)
- dev: `<actual>`  · test: `<actual>`  · lint: `<actual>`  · build: `<actual>`
- run one test: `<actual>`

## Structure (as-is)
<the real tree + where routes/logic/tests live>
Organization: <layer-based | feature-based | mixed> — FOLLOW THIS.

## Conventions in use (match these, don't impose new ones)
- API response shape: <observed>
- Field naming: <observed>
- Data access: <ORM/pattern observed>
- State / forms / auth: <observed>
- Import style: <observed>

## Patterns to AVOID (observed footguns + house rules)
- <e.g. "no new global state; this repo uses prop drilling deliberately">
- <e.g. "migrations via Flyway in db/migration — never edit applied ones">

## Danger zones (low/no test coverage — change carefully)
- <paths>
```

## Brownfield discipline for the change itself

Once you understand the repo and start the ticket:
- **Minimal diff.** Touch only what the ticket needs. Don't reformat or "tidy" unrelated code.
- **Match the local style** of the file you're in, even if it differs from elsewhere in the repo.
- **Impact analysis before editing a shared symbol:** grep all callers; update or preserve their contract.
- **Characterization tests first** when changing untested code: capture current behavior, then change, so you notice regressions.
- **Don't introduce a new library** (state manager, HTTP client, ORM, test runner) when one is already in use — use the incumbent.
- **Don't migrate the structure** to feature-based/monorepo as a side effect. If the ticket is a refactor, that's its own PR with its own review.
- **Respect the migration mechanism** already in place (Flyway/Liquibase/Alembic/Prisma/Rails) — don't introduce a second one.

## Anti-patterns

- ❌ Imposing the kit's greenfield structure on a repo that has its own
- ❌ Reformatting/refactoring files the ticket didn't ask you to touch (noise in the diff, breaks blame)
- ❌ Adding a 2nd state manager / ORM / test runner alongside the existing one
- ❌ Editing a shared function without grepping its callers
- ❌ Changing untested code with no characterization test
- ❌ Writing CLAUDE.md from the template instead of from the actual code
- ❌ "While I'm here, let me clean this up" — scope creep that explodes review

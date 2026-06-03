---
name: prisma-6-migration
description: How to author Prisma 6 migrations safely, including expand-and-contract for any destructive change. Use whenever modifying prisma/schema.prisma or files in prisma/migrations/.
---

# Prisma 6 Migration Safety

## Golden rules

1. **Local: `prisma migrate dev`** to author migrations.
2. **CI/staging/prod: `prisma migrate deploy` ONLY.** Never `dev` outside local.
3. **Additive by default.** Adding tables/columns/indexes is safe.
4. **Destructive → expand-and-contract** (3 deploys minimum).

## Additive migration (safe)

```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  createdAt DateTime @default(now())
  // NEW (safe additive):
  timezone  String?  // nullable → no backfill needed
}
```

```bash
pnpm prisma migrate dev --name add_user_timezone
```

## Destructive migration (3-deploy expand-and-contract)

Goal: rename `User.fullName` → `User.displayName` without data loss or downtime.

### Deploy 1 — EXPAND (add new, keep old)

```prisma
model User {
  fullName    String   // legacy, still required by old code
  displayName String?  // new, nullable for now
}
```

In code: write to BOTH fields, read from `fullName`.

```bash
pnpm prisma migrate dev --name expand_add_display_name
```

### Backfill (between deploys)

```sql
-- Run as a job or a migration with --create-only:
UPDATE "User" SET "displayName" = "fullName" WHERE "displayName" IS NULL;
```

### Deploy 2 — SWITCH READS (code only, no schema change)

In code: write to BOTH, read from `displayName`.

### Deploy 3 — CONTRACT (drop old)

```prisma
model User {
  displayName String   // now required
  // fullName removed
}
```

```bash
pnpm prisma migrate dev --name contract_drop_full_name
```

## Long-running migrations (concurrent index)

Prisma migrations run in a transaction by default. For Postgres `CREATE INDEX CONCURRENTLY`, use `--create-only` and hand-edit:

```bash
pnpm prisma migrate dev --create-only --name add_concurrent_index
```

Then edit `migration.sql`:

```sql
-- Run OUTSIDE a transaction (Prisma respects -- BEGIN/COMMIT)
CREATE INDEX CONCURRENTLY "User_email_idx" ON "User" ("email");
```

## Reversibility

Every destructive migration must answer in the PR description:

```
Reversibility: NO — Step 1/3 (expand-step)
Forward fix on rollback: re-deploy previous Docker image; data is preserved.
```

## Advisory locks for one-instance migration runners

If multiple API instances start simultaneously, only one should run migrations:

```sql
SELECT pg_advisory_lock(<bigint-derived-from-migration-name>);
-- migration runs
SELECT pg_advisory_unlock(<same>);
```

Most platforms (Fly.io, Railway, Vercel Postgres) handle this via a release command — keep `migrate deploy` in the release phase, not the start phase.

## Anti-patterns

- ❌ DROP COLUMN + ADD COLUMN in the same migration to "rename"
- ❌ ALTER COLUMN TYPE without considering existing data
- ❌ `prisma db push` in any environment with real data
- ❌ Hand-editing applied migrations (only `--create-only` files before they're applied)
- ❌ Long-running locks on hot tables during peak traffic

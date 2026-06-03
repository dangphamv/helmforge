---
name: living-brd
description: Maintain a LIVING Business Requirements Document as the product's source of truth — a versioned registry of functional/non-functional requirements with globally-unique IDs, status, and traceability to acceptance + tests + PRs. Use whenever requirements are created or changed (business-analyst on every feature), and when onboarding an existing repo. Append-as-you-go: features you build get recorded; you do NOT back-fill an entire legacy product.
---

# Living BRD — the requirements source of truth

Per-ticket specs (`docs/specs/<ticket>/requirements.md`) are point-in-time snapshots. The **living BRD** is the one consolidated, maintained document that answers "what does this product require, right now, and where is each requirement implemented & tested." It lives in `docs/brd/` and is committed to the repo.

## Files

- **`docs/brd/requirements.yaml`** — THE registry. Hand/agent-maintained. The single source of truth. Every requirement is one record with a globally-unique ID.
- **`docs/brd/brd.md`** — human-readable view (product overview + per-domain requirement tables + traceability), GENERATED from the registry by `.helmforge/scripts/brd.sh report`. Don't hand-edit the generated sections.
- The per-ticket `docs/specs/<ticket>/requirements.md` still exists as the working spec for that ticket, but it now references global IDs and the BRD registry is canonical.

## The registry format (`docs/brd/requirements.yaml`)

```yaml
product: <name>
updated: <ISO date>
# status: proposed | planned | in-progress | shipped | deprecated
# type:   FR (functional) | NFR (non-functional)
requirements:
  - id: FR-AUTH-001
    type: FR
    domain: AUTH
    status: shipped
    priority: must            # must | should | could | wont
    statement: "A registered user can sign in with email and password."
    acceptance: docs/specs/ACME-12/acceptance.feature#login
    ticket: ACME-12
    pr: "#34"
    added: 2026-05-01
    updated: 2026-05-10
  - id: NFR-PERF-001
    type: NFR
    domain: PERF
    status: shipped
    priority: should
    statement: "Login responds in p95 < 300ms server-side."
    acceptance: docs/specs/ACME-12/acceptance.feature#login-latency
    ticket: ACME-12
    pr: "#34"
    added: 2026-05-01
    updated: 2026-05-01
```

## Global ID scheme (no collisions, cross-ticket traceable)

`<FR|NFR>-<DOMAIN>-<NNN>` — e.g. `FR-AUTH-001`, `FR-BILLING-007`, `NFR-PERF-003`, `NFR-SEC-002`.
- DOMAIN is the feature area in UPPER-CASE (AUTH, BILLING, SEARCH, PERF, SEC, A11Y, …).
- NNN is zero-padded, allocated per (type, domain). **Allocate via `.helmforge/scripts/brd.sh next-id <DOMAIN> <FR|NFR>`** so two agents never collide. Never reuse a retired ID.
- These IDs are GLOBAL and stable — unlike the per-ticket FR-001/NFR-001 in `requirements.md`. The per-ticket doc maps its local items to these global IDs.

## When to update (business-analyst owns this, every feature)

On each `/sdlc` feature, after writing the per-ticket `requirements.md`:

1. **Ensure the BRD exists.** If `docs/brd/` is missing, create it first (`.helmforge/scripts/brd.sh init`, or scaffold the two files). On an EXISTING repo with no BRD, do NOT try to reverse-engineer the whole product — start empty and **append only what this feature adds** (see Brownfield below).
2. **Append/merge this feature's requirements** into `requirements.yaml`:
   - New requirement → allocate a global ID (`brd.sh next-id`), `status: planned` (or `in-progress` once code starts), fill statement/priority/domain, link `acceptance`, `ticket`.
   - Changed behavior of an existing requirement → update its `statement`, bump `updated`, keep the ID.
   - Removed feature → set `status: deprecated` (never delete the record — history matters), note the ticket that removed it.
3. **Set traceability fields:** `acceptance` (path#scenario), `ticket`, and `pr` (once the PR opens).
4. **Flip to `shipped`** when the PR merges (the code-reviewer/devops step or the next run does this).
5. **Regenerate** `brd.md`: `.helmforge/scripts/brd.sh report` (overview + per-domain tables + traceability matrix).
6. **Validate:** `.helmforge/scripts/brd.sh validate` (no duplicate IDs, every record has type/domain/status/statement, every `shipped` has acceptance + pr). Fix before finishing.

## Brownfield — append-as-you-go (repo exists, no BRD yet)

The rule the user asked for: **whatever feature you build, that feature gets saved.**
- First touch: `.helmforge/scripts/brd.sh init` creates `docs/brd/requirements.yaml` (product name + empty list) and a seed `brd.md`. `/sdlc:onboard` may add a one-line product overview + (optionally) list detected modules as context comments — but it does NOT invent requirement records for existing code.
- From then on, every feature you implement via `/sdlc` (or `/sdlc:quick`) appends its requirements with global IDs and `status: shipped` once merged. The BRD grows to cover exactly the parts of the product the kit has worked on — accurate by construction, never speculative.
- If you later want to document a pre-existing area, add its requirements explicitly with `status: shipped` + a note `source: pre-existing` — a deliberate act, not an auto-backfill.

## Register as source of truth

Add to `CLAUDE.md` so every agent reads it:
```markdown
## Requirements source of truth
- `docs/brd/requirements.yaml` — living BRD registry (global IDs, status, traceability). Read it for what the product requires; update it when requirements change (see `living-brd` skill).
```

## Anti-patterns

- ❌ Letting per-ticket `requirements.md` be the only record → no consolidated, current view
- ❌ Per-ticket local IDs (FR-001) used as if global → collisions, no traceability
- ❌ Deleting a requirement record when a feature is removed → use `status: deprecated`
- ❌ Back-filling a whole legacy product's requirements speculatively → only record what you actually build/verify
- ❌ Hand-editing the generated `brd.md` tables instead of `requirements.yaml` → drift
- ❌ Shipping a requirement with no `acceptance`/`pr` link → untraceable

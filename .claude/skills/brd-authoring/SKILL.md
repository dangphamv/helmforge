---
name: brd-authoring
description: Best practices for writing requirements and per-story specs (the human-readable deliverable). Apply when business-analyst authors a feature spec. Encodes INVEST, testable acceptance, separation of WHAT vs HOW, measurable NFRs, scope boundaries, assumptions/risks, and an anti-drift consolidated story-spec template that REFERENCES the canonical machine artifacts instead of duplicating them.
---

# BRD authoring — write specs a senior BA would sign off

Goal: a per-story spec that is unambiguous, testable, traceable, and readable in one sitting — without duplicating the machine artifacts (which drift). The story spec is the narrative + decisions + flow; the canonical truth for API/AC/requirements lives in `openapi.yaml`, `acceptance.feature`, and the living BRD. Link, don't copy.

## Principles (apply all)

- **INVEST** for each story: Independent, Negotiable, Valuable, Estimable, Small, Testable. If a story fails one, split or reshape it.
- **Separate WHAT from HOW.** Requirements state the need + outcome; solution detail (endpoints, schema) is referenced from the canonical artifacts, not re-specified in prose that will rot. Mark anything that's a *suggested* design as such, so it stays negotiable.
- **Every requirement is testable + measurable.** No "fast", "secure", "user-friendly" without a number or a checkable condition. "p95 < 300ms", "lockout after 5 failed attempts", "WCAG 2.2 AA".
- **Acceptance = behavior, in Given/When/Then.** The readable spec summarizes scenarios; the executable truth is `acceptance.feature`. One AC ⇄ at least one scenario ⇄ at least one test.
- **Stable global IDs.** Requirements get living-BRD IDs (`FR-AUTH-001`); ACs and scenarios reference them. This is what makes traceability real across tickets.
- **Scope boundaries are explicit.** State what's IN, what's OUT (this release), and what's deferred. Most spec disputes are scope disputes.
- **Surface the unknowns.** Assumptions, constraints, open questions, and risks are first-class sections — not omitted to look finished.
- **Cover the unhappy paths.** Errors, edge cases, empty/loading/permission states, idempotency, concurrency. The happy path is the easy 20%.
- **NFRs are not optional.** Walk the checklist (below) every story; record the ones that apply with targets.
- **Personas/actors named.** Who is this for, what's their context, what's the entry point.

## NFR checklist (record the applicable ones with targets)

Performance (latency p95/throughput), Security (authN method, authZ/RBAC, secrets, PII handling), Privacy/compliance (consent, retention, region), Accessibility (WCAG 2.2 AA), Reliability (availability, idempotency, retries), Observability (logs/metrics/traces, what to alert on), Rate limiting/abuse, i18n/l10n (and error-message localization), Data (validation, encryption at rest/in transit), Cost (per-request/per-user ceilings for paid services/LLM).

## Consolidated story-spec template (anti-drift)

Write to `docs/specs/<ticket>/<US-ID>-spec.md`. Embed narrative + flow + decisions; LINK to canonical artifacts for the machine truth.

```markdown
# <US-ID>: <Title>

| Field | Value |
|---|---|
| ID | <US-ID> |
| Epic / Domain | <Epic> / <DOMAIN> |
| Priority (MoSCoW) | Must / Should / Could / Won't |
| Actor(s) | <persona> |
| Depends on | <US-IDs>  ·  Blocks | <US-IDs>   ← from the living BRD graph |
| BRD requirements | FR-<DOM>-NNN, NFR-<DOM>-NNN  (registry: docs/brd/requirements.yaml) |
| Status | proposed / planned / in-progress / shipped |

## 1. Business context (WHY)
As a <persona>, I want <capability> so that <business value>. Success metric: <measurable KPI>.

## 2. Scope
- **In:** <bullets>
- **Out (this release):** <bullets>
- **Deferred / Phase 2:** <bullets>

## 3. User flow
\`\`\`mermaid
flowchart TD
  ... (happy path + key branches incl. error/locked states)
\`\`\`

## 4. Functional requirements (WHAT)
- **FR-<DOM>-NNN** — <statement>. Acceptance: `acceptance.feature#<scenario>`
(stable IDs from the living BRD; statements describe outcomes, not implementation)

## 5. Acceptance criteria (behavior)
Summarize the Given/When/Then scenarios; the executable source of truth is `docs/specs/<ticket>/acceptance.feature`. Cover happy path + each unhappy path + edge cases.

## 6. Non-functional requirements
<from the NFR checklist, each with a target and an NFR-<DOM>-NNN id>

## 7. UX / screen notes
Per-screen intent, states (default/empty/loading/error/disabled), and key affordances. Full visual spec: `docs/specs/<ticket>/ux-spec.md`. Accessibility per `wcag-audit.md`.

## 8. Solution references (HOW — canonical, not duplicated)
- API contract: `api/openapi.yaml` (paths: <list>) — do not restate request/response here; link.
- Data model: `<prisma/schema.prisma | the repo's migration>` (entities touched: <list>).
- Suggested design notes (negotiable): <only decisions worth recording, e.g. "Redis for OTP rate-limit + lockout">.

## 9. Errors & edge cases
| Condition | Result | User-facing message (per locale) | Recovery |
(include localized messages when the product is localized; reference the API error envelope)

## 10. Dependencies & human actions
- Internal: <US-IDs / modules>
- External services: <e.g. SMS, OAuth providers> → each needs a human-action guide (docs/human-actions/…)
- Infrastructure: <db, cache, storage, geo>

## 11. Assumptions, constraints, risks, open questions
- Assumptions: … · Constraints: … · Risks (+ mitigation): … · Open questions (blocking?): …
```

## Anti-drift rule (important)

Do NOT paste the full OpenAPI request/response tables or the full SQL DDL into the story spec — those live in `openapi.yaml` and the migration, which are the canonical, versioned, machine-checked sources. The story spec *links* to them and lists the touched paths/entities. Duplicating them guarantees they diverge (the `userId`→`user_id` class of bug). The living BRD registry is canonical for requirement IDs/status; the spec references those IDs.

## Definition of Ready (before implementation starts)
Every FR has ≥1 testable AC; NFRs walked; scope IN/OUT stated; dependencies + human-actions identified; no blocking open question; IDs registered in the living BRD.

## Anti-patterns
- ❌ Solutioning inside requirements (locking in HOW before WHAT is agreed)
- ❌ Unmeasurable adjectives ("fast", "intuitive") with no target
- ❌ Duplicating openapi/schema into prose → drift
- ❌ Only the happy path; no error/edge/empty/permission states
- ❌ No explicit OUT-of-scope → endless scope creep
- ❌ Hiding assumptions/risks to look complete
- ❌ Local per-ticket IDs used as if global → no cross-story traceability

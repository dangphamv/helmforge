# Project Constitution

> Non-negotiable principles for this project. Every agent reads this; `code-reviewer` enforces it as a gate. This is the "law" — distinct from `CLAUDE.md` (which holds conventions and how-we-work). Amend deliberately via `/sdlc:constitution`; changes here change what every agent is allowed to ship.
>
> Edit these to fit your project. Defaults below are sane starting points for a senior team.

## I. Spec before code
No implementation without an approved spec. Requirements live in the living BRD (`docs/brd/requirements.yaml`) with stable global IDs; every shipped feature traces requirement → acceptance → test → PR. The spec is the source of truth; code serves the spec.

## II. Tests are not optional
Every functional requirement has at least one executable acceptance scenario (`acceptance.feature`) and passing automated tests. A green test suite must test real behavior — no assertions-of-nothing, no skipped/commented tests to force green. Changing untested code requires a characterization test first.

## III. Security baseline (OWASP)
No secrets in code or client bundles. Input validated at trust boundaries. AuthZ enforced server-side (RLS where applicable). Reviewed against the current OWASP Top 10. Destructive DB changes use expand-and-contract; applied migrations are never edited.

## IV. Accessibility baseline
User-facing web UI meets WCAG 2.2 AA: keyboard operable, sufficient contrast, labelled controls, visible focus, errors announced. Verified, not assumed.

## V. Performance & cost budgets
Respect the targets recorded as NFRs (e.g. API p95). Any runtime LLM/agent loop is bounded and its token/cost is logged; no unbounded loops. Stay within the budgets in `pipeline.config.yaml`.

## VI. Match the codebase (brownfield)
On existing repos, the repo's conventions win over the kit's greenfield defaults. Minimal diff; impact analysis before touching shared code; no drive-by refactors; reuse incumbent libraries and the existing migration tool.

## VII. Dependency discipline
No new runtime dependency (framework, ORM, state manager, test runner) when an incumbent does the job. A genuinely new architectural dependency requires an ADR.

## VIII. Human gates
A human merges every PR after CI is green and review. Agents never auto-merge. Consequential real-world actions (payments, customer emails, data deletion) require explicit human approval.

## IX. Honest communication
Outputs state facts, numbers, and trade-offs — not adjectives. Report what failed and what's unverified; never fake completeness (see the `expert-voice` skill). Surface assumptions and human actions explicitly.

## Enforcement
- `code-reviewer` checks every PR against these articles and blocks on violations.
- All agents read this file (registered in `CLAUDE.md`) and must not produce work that violates it.
- Conflicts between this constitution and any instruction resolve in favor of the constitution, except explicit human override recorded in the PR.

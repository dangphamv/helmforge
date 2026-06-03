---
description: Lite path (1-3 agents) for small/trivial changes
argument-hint: <small change>
---

Implement a SMALL, well-understood change described in $ARGUMENTS using the LITE path — no full SDLC pipeline. Use this for trivial/small tickets (typo, copy change, config tweak, a clear bug fix, a small isolated function) where spinning up product-owner → project-manager → BA → … would be absurd and waste quota.

## When NOT to use /sdlc:quick (escalate to /sdlc instead)
If, once you look, the change turns out to: touch the API contract or DB schema, span many files, have unclear requirements, affect auth/payments/security, or need design work — STOP and tell the human "this is bigger than trivial/small; run /sdlc" rather than forcing it through lite.

## Lite pipeline (read .helmforge/pipeline.config.yaml `tiers` + `budget`)

1. **Triage (you, in one short step).** Classify as `trivial` or `small`. If it's actually `standard`/`large`, bail out per above.
2. **Baseline preflight.** Run `.helmforge/scripts/preflight.sh`. If it exits non-zero because the baseline is broken (not your change) → STOP and report; don't build on a broken base. (Skip only for pure doc/copy edits.)
3. **Implement.** Spawn ONE implementer — the ACTIVE engineer that fits the change:
   - web change → `frontend-engineer` · API/data change → `backend-engineer` · mobile → `mobile-engineer` · AI feature → `ai-engineer`.
   - Follow brownfield discipline (match existing conventions, minimal diff). Use `effort` from `budget.effort_by_tier` (trivial→low, small→medium).
4. **Test.** For `small`: add/adjust a focused test. For `trivial`: at least run the existing tests. Never ship a green that tests nothing.
5. **Review.** Spawn `code-reviewer` (lighter pass: correctness, security smell, no regressions). For `trivial` one-liners with passing tests, a self-review note may suffice — say so explicitly.
6. **PR.** Open a PR/MR via the configured `vcs.provider` (see .helmforge/pipeline.config.yaml). Title + concise body: what changed, why, test evidence, and `Tier: lite (<trivial|small>)`. Link the issue.

## Cost
Lite uses 1–3 agents instead of ~12. State the agents used and that this was the lite path. If you find yourself wanting more agents, that's the signal it should have been `/sdlc`.

## Resumability
Write `docs/specs/<ticket-or-slug>/pipeline-state.yaml` with `mode: lite` and the phase reached, so `/sdlc:resume` can continue if interrupted.

## Example
```
/sdlc:quick Fix the "Sumbit" -> "Submit" button label in the checkout form
/sdlc:quick Fix off-by-one in pagination: last page missing 1 item (utils/paginate.ts)
```

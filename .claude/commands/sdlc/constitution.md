---
description: Create or amend constitution.md — non-negotiable principles
argument-hint: [amendment]
---

Create or amend the project's `constitution.md` — the non-negotiable principles every agent reads and `code-reviewer` enforces. $ARGUMENTS describes the principle(s) to add/change (or is empty to review the current one). Borrowed from spec-driven development's constitution concept.

## What it does
1. If `constitution.md` doesn't exist at repo root → create it from the kit template (sane senior-team defaults: spec-before-code, tests-required, OWASP baseline, WCAG 2.2 AA, perf/cost budgets, brownfield-match, dependency discipline, human gates, honest communication).
2. If it exists → read it, then apply the amendment in $ARGUMENTS: add/modify/remove an article. Keep articles concise, testable, and enforceable (a reviewer must be able to check a PR against each).
3. Ensure it is registered in `CLAUDE.md` (so every agent loads it) and that `code-reviewer` treats it as a gate.
4. Show a diff of what changed and confirm.

## Rules
- The constitution is the "law": principles that override convenience. Keep it short — only genuinely non-negotiable items belong here; everyday conventions go in `CLAUDE.md`.
- Each article must be enforceable. "Be good" is not an article; "No secrets in code or client bundles" is.
- Amend deliberately — changes here change what every agent is allowed to ship. Note the date/rationale of significant changes.
- This command does NOT write feature code; it only governs.

## Examples
```
/sdlc:constitution                                   # review current principles
/sdlc:constitution Add: all money handled in integer minor units, never floats
/sdlc:constitution Strengthen the a11y article to WCAG 2.2 AAA for the checkout flow
```

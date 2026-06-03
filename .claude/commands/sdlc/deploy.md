---
description: Phase 7 · devops: deploy + CI gate & auto-fix
argument-hint: <feature>
---

Run ONLY the DevOps/deploy phase (devops-engineer) for $ARGUMENTS, then STOP.

Standard flow: … → `/sdlc:qa` → **`/sdlc:deploy`** → `/sdlc:review`. Step 7.

## Active-agents gate
Skip if `devops-engineer` is disabled.

## Steps
1. Spawn `devops-engineer` → preview deploy, migration safety gate (expand-and-contract), Sentry/release, env-var alignment.
2. **CI gate & auto-fix** (per `.helmforge/pipeline.config.yaml` `ci`): read CI for the PR via the `vcs.provider`; if RED and `auto_fix_on_red`, fix → push → re-check, BOUNDED by `max_fix_attempts`, else escalate. Never auto-merge.
3. `checkpoint-resume`: update pipeline-state (current_phase: deploy).

## Stop here
Tell the user: "Deploy/preview ready, CI <green/fixed/escalated>. Run **`/sdlc:review`** for the final gate."

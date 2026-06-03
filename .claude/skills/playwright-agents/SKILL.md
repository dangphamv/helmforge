---
name: playwright-agents
description: How to use Playwright 1.56+ Agents (planner / generator / healer) to scale E2E coverage. Use whenever adding E2E tests for a new feature.
---

# Playwright Agents (1.56+)

Playwright Test Agents (shipped Oct 2025) automate the test lifecycle. Three agents:

| Agent | Input | Output |
|------:|------|------|
| **planner** | Live app + seed | `specs/<feature>.md` (numbered scenarios in prose) |
| **generator** | `specs/<feature>.md` | `tests/<feature>.spec.ts` (Playwright code) |
| **healer** | Failing test + new DOM | Patched locators in the spec |

## Bootstrap once per repo

```bash
npx playwright init-agents --loop=claude
# (or --loop=copilot / --loop=opencode)
```

This creates:
- `.github/playwright-planner.md`, `playwright-generator.md`, `playwright-healer.md`
- A `playwright.config.ts` template

## Standard E2E loop for a new feature

### Step 1 — plan
In Claude Code chat:

```
@playwright-planner
Explore the app at http://localhost:3000/forgot-password.
Acceptance file: docs/specs/ACME-481/acceptance.feature
Produce specs/forgot-password.md with one scenario per acceptance criterion.
```

Planner produces:
```markdown
# Forgot Password Flow

## Scenario 1: Happy path
1. Navigate to /login
2. Click "Forgot password?"
3. Fill email with seeded user 'alice@example.com'
4. Submit
5. Assert success message appears
6. Inspect Mailpit at :8025, get the reset link
7. Open reset link
8. Submit new password
9. Assert redirected to /home (signed in)
```

### Step 2 — generate
```
@playwright-generator specs/forgot-password.md
```

Generator emits `tests/forgot-password.spec.ts` with `getByRole`-first locators.

### Step 3 — run
```bash
pnpm playwright test forgot-password
```

### Step 4 — heal (only on failure)
```
@playwright-healer tests/forgot-password.spec.ts (current failure: "locator timeout on `getByRole('button', { name: 'Submit' })`")
```

Healer inspects the live DOM, proposes a locator update (`getByRole('button', { name: 'Send reset link' })`).

## Selector strategy (in every spec)

Priority order — use the first that's stable:
1. `getByRole('button', { name: 'Submit' })`
2. `getByLabel('Email address')`
3. `getByText('Forgot password?')`
4. `getByTestId('forgot-pw-link')` ← only when 1–3 are impossible

Forbidden:
- `page.locator('.btn-primary > span')`
- `page.locator('css=...')`
- `page.locator('xpath=//div[3]/button')`

## Determinism rules

- ❌ `await page.waitForTimeout(1000)` — replace with `expect.poll` or `await expect(locator).toBeVisible()`
- ❌ Asserting on volatile data (timestamps, random IDs)
- ❌ Sharing state across tests — each test should set up + tear down via fixtures
- ✅ Use `page.route()` to stub flaky external APIs

## Coverage in CI

```yaml
- name: Playwright tests
  run: pnpm playwright test --reporter=html
- name: Upload trace
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: playwright-report
    path: playwright-report/
```

## Triaging flakes

If a test fails intermittently:
1. Run locally: `pnpm playwright test <file> --repeat-each=10 --retries=0`
2. If <100% pass: it's a flake. Either fix the test (better waits) or fix the underlying race condition.
3. **Never** just `--retries=2` to mask flakes. Quarantine via `test.fixme(true, 'tracked in ISSUE-123')`.

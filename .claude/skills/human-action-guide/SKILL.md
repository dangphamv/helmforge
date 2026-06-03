---
name: human-action-guide
description: How to produce a step-by-step human-action guide whenever implementation depends on something only a human can do (register an account, obtain an API key, configure DNS, register an OAuth app, upgrade a paid plan, set a dashboard toggle). Use after implementing code that consumes such a credential or external setup. ALL engineering and devops agents reference this.
---

# Human-Action Handoff Guides

Agents implement code. Humans do the things agents can't: registering accounts, retrieving secret keys from a dashboard, verifying a domain, approving an OAuth consent screen, upgrading a billing plan. When implementation depends on one of these, the code is useless until a human acts.

**The rule:** after you implement code that consumes a credential or external resource you cannot create yourself, you MUST emit a human-action guide AND stub the code so it fails loudly with a pointer to the guide. Never leave a silent `process.env.SOME_KEY` that's undefined.

## When to produce a guide

Produce one whenever the implementation depends on any of these:

| Trigger | Examples |
|---|---|
| **Third-party account registration** | Stripe, SendGrid, Twilio, VNPay, Auth0, Cloudflare |
| **API key / secret retrieval** | Stripe secret key, SendGrid API key, OpenAI key |
| **OAuth app registration** | Google OAuth client, GitHub OAuth app, Facebook login |
| **Webhook secret / endpoint setup** | Stripe webhook signing secret, GitHub webhook |
| **DNS / domain configuration** | MX records for email, CNAME for custom domain, SPF/DKIM |
| **Dashboard toggle / manual setting** | Enable a Stripe feature, set a Vercel env scope |
| **Paid plan upgrade** | A feature gated behind a paid tier |
| **Certificate / signing key** | Apple push cert, code-signing cert |
| **Manual approval / verification** | Domain verification, business verification, app review |

## Output location

Write to `docs/human-actions/<id>-<slug>.md` and append an entry to `docs/human-actions/README.md` (the master index).

```
docs/human-actions/
  README.md                          # master checklist of all pending human actions
  ACME-481-sendgrid-template.md
  ACME-481-stripe-webhook-secret.md
```

## Guide template

```markdown
# Human Action: <Short title>
**Ticket:** <id>  **Created by:** <agent>  **Blocking:** <what won't work until done>
**Estimated time:** <N minutes>  **Cost:** <free / $X per month / usage-based>
**Status:** ⏳ PENDING  (change to ✅ DONE when complete)

## Why this is needed
<1-2 sentences: what code depends on this, what breaks without it>

## Prerequisites
- <e.g., a company email, a credit card on file, admin access to the DNS zone>

## Steps
1. Go to <exact URL>
2. <exact action — which button, which menu, what to type>
3. <exact action>
4. Copy the value labeled "<exact label in the dashboard>"
5. Store it:
   - **Local dev:** add to `.env.local`:
     ```
     SENDGRID_API_KEY=<paste here>
     ```
   - **Production:** add to <Vercel env / Fly secrets / GitHub Actions secret>:
     ```bash
     vercel env add SENDGRID_API_KEY production
     # or
     fly secrets set SENDGRID_API_KEY=<value>
     ```

## Verify it works
```bash
<exact command to verify, e.g.:>
pnpm tsx scripts/verify-sendgrid.ts
# Expected output: "✓ SendGrid connection OK, sender verified"
```

## Troubleshooting
- If you see "<common error>": <cause + fix>
- If the key starts with "SG.test" instead of "SG.": you grabbed the sandbox key; get the production one from <location>

## Security notes
- This is a <SECRET / publishable> key. <SECRET → never commit, never log, rotate every N months>
- Scope: grant only <minimal scope, e.g., "Mail Send" permission, not Full Access>
```

## Code stubbing (mandatory)

The code must fail loudly, not silently, when the human action isn't done yet. Three patterns:

### Pattern 1 — fail fast at startup (preferred for required config)

```typescript
// config/env.ts — validated once at boot
import { z } from 'zod';

const envSchema = z.object({
  SENDGRID_API_KEY: z.string().startsWith('SG.', {
    message: 'SENDGRID_API_KEY missing or invalid. See docs/human-actions/ACME-481-sendgrid-template.md',
  }),
});

export const env = envSchema.parse(process.env);
// App refuses to boot with a clear pointer to the guide if the key is missing.
```

### Pattern 2 — feature-flag the dependent code path

```typescript
// When the integration is optional or being rolled out:
if (!process.env.STRIPE_WEBHOOK_SECRET) {
  logger.warn(
    'STRIPE_WEBHOOK_SECRET not set — webhook verification disabled. ' +
    'See docs/human-actions/ACME-481-stripe-webhook-secret.md'
  );
  // route returns 503 with a clear message rather than silently accepting unverified webhooks
}
```

### Pattern 3 — a verification script the human runs

Always ship a `scripts/verify-<service>.ts` so the human can self-check after completing the guide:

```typescript
// scripts/verify-sendgrid.ts
import sgMail from '@sendgrid/mail';
sgMail.setApiKey(process.env.SENDGRID_API_KEY!);
const [resp] = await sgMail.client.request({ method: 'GET', url: '/v3/verified_senders' });
console.log(resp.statusCode === 200
  ? '✓ SendGrid connection OK, sender verified'
  : '✗ SendGrid responded ' + resp.statusCode);
```

## Worked example — Supabase (project URL + keys)

`docs/human-actions/<id>-supabase.md`:

```markdown
# Setup: Supabase

**Why this is needed:** The app uses Supabase for Postgres + Auth + Storage. Nothing
data-related works without the project URL and keys.
**Who can do this:** Anyone who can create/admin the team's Supabase org.
**Estimated time:** 8 minutes. **Cost:** Free tier (500MB DB, 50k MAU) → paid as you grow.

## Steps
1. Go to https://supabase.com/dashboard → **New project** (pick region closest to users; for VN: Singapore `ap-southeast-1`).
2. Set a strong DB password (store it in the team vault).
3. After provisioning, open **Project Settings → API**. Copy:
   - **Project URL** → `NEXT_PUBLIC_SUPABASE_URL`
   - **anon public** key → `NEXT_PUBLIC_SUPABASE_ANON_KEY` (safe for the browser)
   - **service_role** key → `SUPABASE_SERVICE_ROLE_KEY` (⚠️ SERVER-ONLY — never ship to client)
4. **Project Settings → Database → Connection string** → copy the URI → `DATABASE_URL` (for Drizzle/Prisma if used).
5. Where to put them:
   - Local: `.env.local`
   - Production: Vercel → Settings → Environment Variables (service_role scoped Production only)

## Verify it works
\`\`\`bash
pnpm tsx scripts/verify-supabase.ts
# Expected: "✓ Supabase reachable. Auth + DB OK."
\`\`\`

## Gotchas
- The **anon** key relies on Row Level Security — enable RLS on every table with user data, or the anon key can read everything.
- **service_role** bypasses RLS. Use only in server-only code (Route Handlers / Server Actions), never in a Client Component.
- Free projects pause after ~1 week of inactivity — first request after that is slow.

## Rollback / rotate
Project Settings → API → **Reset** the relevant key; update env vars within minutes (old key dies immediately).
```

## Worked example — LLM provider key (Anthropic / OpenAI / AI Gateway)

`docs/human-actions/<id>-llm-provider.md`:

```markdown
# Setup: LLM Provider Key

**Why this is needed:** The in-app AI features (chatbot/agents/RAG) call an LLM. No key = no AI.
**Who can do this:** Anyone who can admin the team's Anthropic/OpenAI account (or Vercel AI Gateway).
**Estimated time:** 5 minutes. **Cost:** usage-based — SET A SPEND LIMIT before going live.

## Steps (Anthropic)
1. https://console.anthropic.com → **API Keys → Create Key**. Copy (starts with `sk-ant-`).
2. **Settings → Limits** → set a monthly spend cap (e.g. $50) so a runaway loop can't drain the account.
3. Put it server-side only:
   - Local: `.env.local` → `ANTHROPIC_API_KEY=sk-ant-...`
   - Prod: Vercel → Settings → Environment Variables (Production) — NOT `NEXT_PUBLIC_*`.
4. (Optional) Vercel AI Gateway: dashboard → AI → create a Gateway key (`AI_GATEWAY_KEY`) for one key across providers + spend caps + model switching.

## Verify it works
\`\`\`bash
pnpm tsx scripts/verify-llm.ts   # Expected: "✓ Provider reachable. Model responded."
\`\`\`

## Gotchas
- NEVER expose the key to the browser. All LLM calls go through a server route.
- Set the spend cap FIRST. An unbounded agent loop can burn a lot before you notice.
- Test vs prod keys differ if you use separate accounts/projects.

## Rollback / rotate
Console → API Keys → revoke; create a new one; update env vars (old key dies immediately).
```

## Master index format

`docs/human-actions/README.md`:

```markdown
# Human Actions — Master Checklist

Pending actions block features from working. Complete and mark ✅.

| Status | Action | Ticket | Blocks | Time | Guide |
|--------|--------|--------|--------|------|-------|
| ⏳ | Register SendGrid + get API key | ACME-481 | Password reset emails | 10m | [guide](./ACME-481-sendgrid-template.md) |
| ⏳ | Set Stripe webhook signing secret | ACME-490 | Payment confirmation | 5m | [guide](./ACME-490-stripe-webhook-secret.md) |
| ✅ | Verify domain for email DKIM | ACME-481 | Email deliverability | 30m | [guide](./ACME-481-dkim.md) |
```

## In the PR description

When a PR ships code with a pending human action, the PR description MUST include a section:

```markdown
## ⚠️ Human action required before this works in production
This PR adds password-reset emails, but they won't send until:
1. SendGrid account registered + API key set — see docs/human-actions/ACME-481-sendgrid-template.md (~10 min)
2. DKIM domain verified — see docs/human-actions/ACME-481-dkim.md (~30 min, DNS propagation up to 24h)

Code is stubbed to fail fast with these pointers if the keys are missing. Tests use a mocked SendGrid client, so CI passes without the real key.
```

## Anti-patterns

- ❌ Silent `process.env.KEY` that's `undefined` at runtime with no guard
- ❌ "Add your API key to .env" with no URL, no steps, no verification
- ❌ Hardcoding a placeholder key that looks real (`sk_test_xxx`) — confuses debugging
- ❌ Committing the guide but forgetting the master index entry
- ❌ A guide without a verification command (human can't confirm success)
- ❌ Not noting whether a key is SECRET vs publishable
- ❌ Not stating the cost (free tier? paid? usage-based?) — humans need to know before registering
- ❌ Assuming the human knows which dashboard menu — give exact labels and URLs

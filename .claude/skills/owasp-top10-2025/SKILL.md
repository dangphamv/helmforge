---
name: owasp-top10-2025
description: OWASP Top 10:2025 checklist for security code review of Next.js + NestJS applications. Use when reviewing any PR that touches input handling, auth, data access, or external integrations.
---

# OWASP Top 10:2025 — Code Review Checklist

The 2025 edition (RC at OWASP Global AppSec Washington D.C. Nov 6, 2025; final Jan 2026) merges SSRF into A01, promotes Security Misconfiguration to #2, and adds two new categories (A03 Software Supply Chain Failures, A10 Mishandling of Exceptional Conditions).

## A01 Broken Access Control (#1, now includes SSRF)

Checks:
- [ ] Every controller method has an explicit guard or `@Public()` decorator
- [ ] User-scoped resources verify `ownerId === requestUser.id` (IDOR)
- [ ] No URL parameter directly maps to a database PK without authz check
- [ ] **SSRF:** outbound URLs from user input go through an allowlist
- [ ] CORS configured (Vercel + NestJS); not `*` for credentialed requests
- [ ] Admin routes behind an additional role guard

Red flags:
```ts
// ❌ IDOR risk
@Get(':id')
findOne(@Param('id') id: string) { return this.svc.findById(id); }

// ✅ scoped
@Get(':id')
findOne(@Param('id') id: string, @CurrentUser() user: User) {
  return this.svc.findByIdForUser(id, user.id);
}
```

## A02 Security Misconfiguration (#2, jumped from #5)

Checks:
- [ ] No exposed admin endpoints (`/admin`, `/_next/debug`)
- [ ] CSP header set on the FE (`next.config.ts` headers)
- [ ] No default credentials in seeds committed to git
- [ ] Production logs do not include stack traces in responses
- [ ] No `NODE_ENV=development` in production deploys
- [ ] HTTP security headers: `Strict-Transport-Security`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`

## A03 Software Supply Chain Failures (NEW)

Checks:
- [ ] `pnpm-lock.yaml` committed and verified in CI
- [ ] Dependabot or Renovate enabled
- [ ] No `~`/`^` on critical packages (prefer exact versions for security-sensitive)
- [ ] SBOM generated (e.g., `pnpm sbom` or `cyclonedx-npm`)
- [ ] Consider artifact signing (Sigstore)
- [ ] Third-party scripts loaded with `integrity` (SRI)

## A04 Cryptographic Failures

Checks:
- [ ] Passwords: Argon2id (NOT bcrypt's max length issue, NOT MD5/SHA1)
- [ ] No custom crypto — use `crypto.subtle` or `node:crypto` only
- [ ] JWTs verified, not just decoded; check `exp`, `nbf`, `aud`
- [ ] No secrets in error messages or logs
- [ ] TLS enforced (HSTS preload)

## A05 Injection

Checks:
- [ ] Prisma queries use ORM API (parameterized by default)
- [ ] Any `$queryRaw` uses tagged template (`prisma.$queryRaw\`SELECT ... WHERE id = ${id}\``)
- [ ] DTOs use `class-validator`; pipe configured `whitelist: true`
- [ ] FE forms use Zod schemas
- [ ] XSS: React escapes by default; `dangerouslySetInnerHTML` audited

## A06 Insecure Design

- [ ] Threat-model exists for any new auth/payment/PII flow
- [ ] Rate limits on auth routes (login, reset, verify)
- [ ] Confirmation step for destructive actions

## A07 Identification & Authentication Failures

Checks:
- [ ] Session timeout configured
- [ ] MFA available for admin/sensitive accounts
- [ ] Password reset tokens single-use, short TTL (≤15min)
- [ ] No account enumeration (same response for valid vs invalid email)
- [ ] Brute-force protection (rate limit + lockout)

## A08 Software & Data Integrity Failures

Checks:
- [ ] CI verifies lockfile integrity
- [ ] No pulling code from URLs at runtime
- [ ] Webhook payloads verified by signature (Stripe, GitHub, etc.)

## A09 Security Logging & Alerting Failures (renamed from "Monitoring")

Checks:
- [ ] Auth events logged (login, failed login, password reset, MFA changes)
- [ ] Logs include: timestamp, event type, user id, outcome, source IP
- [ ] Logs do NOT include: passwords, tokens, full credit-card numbers, full SSN
- [ ] Sentry alerts wired for 5xx spikes
- [ ] Auth anomalies trigger an alert (geo, velocity)

## A10 Mishandling of Exceptional Conditions (NEW)

Checks:
- [ ] No empty `catch {}` — log + rethrow or convert to typed error
- [ ] No fail-open behavior (if auth check throws → deny, not allow)
- [ ] Global exception filter maps to RFC 7807 Problem Details
- [ ] Async errors caught (no unhandled rejections to PM2/Node)
- [ ] Timeouts on all external calls; cleanup on cancel

Red flag:
```ts
// ❌ Swallowed exception (A10)
try {
  await this.userService.checkAccess(id, user);
} catch {} // continues as if access was granted

// ✅ Proper handling
try {
  await this.userService.checkAccess(id, user);
} catch (err) {
  if (err instanceof ForbiddenError) throw err;
  this.logger.error('Access check failed', err);
  throw new InternalServerErrorException();
}
```

## Secret-detection regex (grep these in changed files)

```bash
grep -rE '(AKIA[0-9A-Z]{16}|sk_live_[0-9a-zA-Z]{24}|ey[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]+|github_pat_[0-9a-zA-Z_]{82})' .
```

Plus pre-commit hooks: gitleaks, detect-secrets.

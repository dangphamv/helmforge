---
name: wcag-2.2-aa
description: WCAG 2.2 Level AA conformance checklist with focus on the 9 new success criteria. Use when designing or implementing any user-facing UI.
---

# WCAG 2.2 Level AA — Compliance Checklist

WCAG 2.2 (published Oct 2023, EU EAA enforced Jun 2025) adds **9 new SC** to WCAG 2.1. 6 are AA-level.

## NEW success criteria (added in 2.2)

### 2.4.11 Focus Not Obscured (Minimum) [AA]
The focused element must not be entirely hidden by sticky headers/footers/modals.
- ❌ Sticky header that hides the focused input below
- ✅ `scroll-margin-top` on focusable elements

### 2.4.12 Focus Not Obscured (Enhanced) [AAA — optional]
The focused element must not be obscured AT ALL.

### 2.4.13 Focus Appearance [AAA — optional]
Focus indicator must have area ≥2 CSS px around perimeter, contrast ≥3:1.

### 2.5.7 Dragging Movements [AA]
Any drag operation must have a single-pointer alternative (click, tap).
- ❌ Drag-only sortable list
- ✅ Drag + arrow buttons (`↑↓` to reorder)

### 2.5.8 Target Size (Minimum) [AA]
Interactive targets ≥**24×24 CSS px** (or spacing equivalent).
- ❌ 16px icon button
- ✅ Icon in a 32×32 hit area; or 16px icon with `padding` to 24×24

### 3.2.6 Consistent Help [A — but check at AA]
If help (contact, FAQ, chat) appears on multiple pages, it must be in the same relative order.

### 3.3.7 Redundant Entry [A — but check at AA]
Information previously entered must be auto-populated or selectable (except passwords, security info).

### 3.3.8 Accessible Authentication (Minimum) [AA]
Authentication must NOT rely solely on a **cognitive function test** (memory, transcription, puzzles).
- ❌ "Enter the 6-digit code we sent (no paste allowed)"
- ❌ Image CAPTCHA only
- ✅ Allow password managers (no anti-paste)
- ✅ Passkeys / WebAuthn
- ✅ Magic link via email
- ✅ Object-recognition CAPTCHA (object recognition is NOT a cognitive function test)

### 3.3.9 Accessible Authentication (Enhanced) [AAA — optional]
Even object-recognition CAPTCHAs are disallowed.

## Pre-existing AA criteria (still apply)

### Perceivable
- 1.3.1 Info & Relationships — semantic HTML, ARIA only when no semantic alternative
- 1.4.3 Contrast (Minimum) — text 4.5:1 (3:1 for large text 18pt+)
- 1.4.11 Non-text Contrast — UI components, focus indicators 3:1
- 1.4.10 Reflow — works at 320 CSS px without horizontal scroll
- 1.4.12 Text Spacing — works when user overrides line height, letter/word spacing

### Operable
- 2.1.1 Keyboard — every interaction is keyboard-accessible
- 2.1.2 No Keyboard Trap — focus can leave any component
- 2.4.3 Focus Order — logical
- 2.4.7 Focus Visible — focus indicator visible (use `:focus-visible`, not `:focus`)
- 2.5.3 Label in Name — accessible name includes visible label text

### Understandable
- 3.2.3 Consistent Navigation — same order on every page
- 3.3.1 Error Identification — errors identified in text
- 3.3.3 Error Suggestion — suggest a fix when known
- 3.3.4 Error Prevention (Legal/Financial) — confirm before submit; allow correction

### Robust
- 4.1.2 Name, Role, Value — every interactive element has accessible name + role + state
- 4.1.3 Status Messages — `role="status"` / `role="alert"` for dynamic updates

## Implementation hints (React / Tailwind / shadcn)

- Use `:focus-visible` not `:focus` (Tailwind: `focus-visible:ring-2`)
- shadcn primitives are AA-correct by default; do not strip their ARIA
- For drag interactions: dnd-kit's keyboard sensor or arrow-key handlers
- Pair every `<label htmlFor>` with its input; or wrap input in `<label>`
- Toasts (Sonner): include `role="status"` for non-critical, `role="alert"` for errors
- Modals: trap focus, return focus on close, ESC to close

## Quick audit commands

```bash
# Axe via Playwright (in qa-engineer agent flow)
npx @axe-core/cli http://localhost:3000/login

# Lighthouse accessibility audit
npx lighthouse http://localhost:3000 --only-categories=accessibility
```

## Common false-positives

- "Color contrast ratio" failing on disabled controls — disabled is exempt
- "Decorative image lacks alt" — `<img alt="">` is correct for purely decorative
- "Missing heading hierarchy" inside dialogs — dialogs may have their own H1/H2

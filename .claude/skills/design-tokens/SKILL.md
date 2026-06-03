---
name: design-tokens
description: How to author and use design tokens with Tailwind v4 + shadcn/ui (OKLCH colors, @theme block, dark-mode pairing, container queries). Use when adding/modifying theme tokens or building components that consume them.
---

# Design Tokens with Tailwind v4 + shadcn

Tailwind v4 (released 2025) moved configuration FROM `tailwind.config.js` INTO CSS via the `@theme` directive. No more JS config for tokens.

## File structure

```
app/globals.css            # Tokens live here, in @theme blocks
components.json            # shadcn config (theme: zinc | slate | gray | ...)
```

## Token definition

```css
/* app/globals.css */
@import "tailwindcss";

@theme {
  /* Color tokens in OKLCH (perceptually uniform; better gradients) */
  --color-background: oklch(1 0 0);                /* white */
  --color-foreground: oklch(0.145 0 0);            /* near-black */
  --color-primary: oklch(0.205 0 0);
  --color-primary-foreground: oklch(0.985 0 0);
  --color-destructive: oklch(0.577 0.245 27.325);
  --color-muted: oklch(0.97 0 0);
  --color-muted-foreground: oklch(0.556 0 0);

  /* Spacing scale (rem-based) */
  --spacing: 0.25rem;     /* 1 spacing unit = 0.25rem; works with `p-4` = 1rem */

  /* Radius */
  --radius: 0.625rem;
  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);

  /* Font */
  --font-sans: "Inter Variable", ui-sans-serif, system-ui, sans-serif;
  --font-mono: "JetBrains Mono Variable", ui-monospace, monospace;

  /* Container query breakpoints */
  --container-sm: 24rem;
  --container-md: 32rem;
  --container-lg: 48rem;
}

/* Dark mode pairing */
:root[data-theme="dark"] {
  --color-background: oklch(0.145 0 0);
  --color-foreground: oklch(0.985 0 0);
  --color-primary: oklch(0.985 0 0);
  --color-primary-foreground: oklch(0.205 0 0);
  --color-muted: oklch(0.269 0 0);
  --color-muted-foreground: oklch(0.708 0 0);
}
```

## Why OKLCH

| Format | Pros | Cons |
|--------|------|------|
| `#3b82f6` | Familiar | Not perceptually uniform — gradients look uneven |
| `hsl(...)` | Editable | Same uniformity problem; chroma differs by hue |
| **`oklch(L C H)`** | Perceptually uniform; predictable gradients; covers wider gamut on modern displays | Newer syntax |

Use OKLCH for any palette generation, gradients, or dark-mode pairs. Browsers since 2023 support it.

## Consuming tokens in components

Tailwind v4 auto-generates utility classes from `@theme`:

```tsx
<div className="bg-background text-foreground border border-border rounded-lg">
  <h2 className="font-sans text-2xl">Title</h2>
</div>
```

Never:
```tsx
<div className="bg-[#3b82f6]">  {/* ❌ hardcoded — escapes the token system */}
```

## Component-level theming via CSS variables

shadcn components honor CSS variables. To create a "destructive" variant of a card, scope tokens locally:

```tsx
<Card className="[--color-card:theme(colors.destructive)] [--color-card-foreground:theme(colors.destructive-foreground)]">
  Critical alert
</Card>
```

## Dark mode

Use `data-theme="dark"` on `<html>` (not the older `.dark` class). Toggle via:

```tsx
// components/theme-toggle.tsx
"use client";
const apply = (t: "light" | "dark") =>
  document.documentElement.setAttribute("data-theme", t);
```

Honor system preference on first paint via inline script in `<head>` to avoid flash.

## Container queries vs media queries

For component-level adaptive layouts, use container queries (Tailwind v4 ships them natively):

```tsx
<div className="@container">
  <div className="grid @sm:grid-cols-2 @lg:grid-cols-4 gap-4">
    {items.map(...)}
  </div>
</div>
```

Reserve media queries (`sm:`, `md:`, `lg:`) for page-level layout only.

## Token naming conventions

- `--color-<role>` — semantic, not literal (`--color-primary` ✅; `--color-blue-500` ❌)
- `--color-<role>-foreground` — paired text color for that role
- `--spacing` — single scale unit; never define `--spacing-4` etc.
- `--radius-{sm,md,lg}` — three sizes max
- `--container-{sm,md,lg}` — container breakpoints (not viewport)

## Anti-patterns

- ❌ Reintroducing `tailwind.config.js` for tokens (Tailwind v4 deprecated this for tokens)
- ❌ Inline `style={{ color: '...' }}` instead of utility classes
- ❌ Hardcoded hex in `className="bg-[#...]"`
- ❌ Defining `--color-blue-500` style tokens (use semantic names)
- ❌ Forgetting dark-mode pairs (every color token needs both light and dark)
- ❌ Using media queries when container queries fit (`md:` instead of `@sm:`)

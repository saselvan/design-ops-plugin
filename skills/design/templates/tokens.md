# Design Tokens: {project-name}

id: TOKENS-{project}
version: 1.0
date: {YYYY-MM-DD}
domain: {domain}

---

## Domain Context

**Industry**: {from research}
**Users**: {who}
**Environment**: {where used}
**Emotional Goal**: {how should it feel}

---

## Typography

### Font Stack

| Role | Font | Fallback | Why |
|------|------|----------|-----|
| Primary | {font} | system-ui | {domain rationale} |
| Mono | {font} | ui-monospace | {use case} |

### Scale

| Token | Size | Line Height | Use |
|-------|------|-------------|-----|
| `text-xs` | 12px | 1.5 | Labels, metadata |
| `text-sm` | 14px | 1.5 | Secondary content |
| `text-base` | 16px | 1.5 | Body text |
| `text-lg` | 18px | 1.4 | Emphasis |
| `text-xl` | 20px | 1.3 | Section headers |
| `text-2xl` | 24px | 1.2 | Page titles |

### Weights

| Token | Weight | Use |
|-------|--------|-----|
| `font-normal` | 400 | Body text |
| `font-medium` | 500 | Emphasis |
| `font-semibold` | 600 | Headings |
| `font-bold` | 700 | Strong emphasis |

---

## Color

### Semantic Palette

| Token | Value | Use | Contrast Ratio |
|-------|-------|-----|----------------|
| `primary` | {hex} | Actions, links | {ratio} ✓/✗ |
| `primary-hover` | {hex} | Hover state | |
| `secondary` | {hex} | Secondary actions | {ratio} ✓/✗ |
| `success` | {hex} | Positive states | {ratio} ✓/✗ |
| `warning` | {hex} | Attention needed | {ratio} ✓/✗ |
| `danger` | {hex} | Errors, destructive | {ratio} ✓/✗ |
| `neutral` | {hex} | Body text | {ratio} ✓/✗ |

### Domain-Specific Status

| Status | Background | Text | Icon | Meaning |
|--------|------------|------|------|---------|
| {status} | {color} | {color} | {icon} | {meaning} |
| {status} | {color} | {color} | {icon} | {meaning} |

### Background Layers

| Layer | Color | Use |
|-------|-------|-----|
| `bg-base` | {color} | Page background |
| `bg-surface` | {color} | Cards, panels |
| `bg-elevated` | {color} + shadow | Modals, dropdowns |
| `bg-muted` | {color} | Disabled, secondary areas |

### Borders

| Token | Color | Use |
|-------|-------|-----|
| `border-default` | {color} | Standard borders |
| `border-muted` | {color} | Subtle separators |
| `border-focus` | {color} | Focus rings |

---

## Spacing

### Scale (base: 4px)

| Token | Value | Use |
|-------|-------|-----|
| `space-0` | 0 | No spacing |
| `space-1` | 4px | Tight grouping |
| `space-2` | 8px | Related items |
| `space-3` | 12px | Component padding (sm) |
| `space-4` | 16px | Component padding (md) |
| `space-6` | 24px | Card padding |
| `space-8` | 32px | Section separation |
| `space-12` | 48px | Page sections |
| `space-16` | 64px | Major divisions |

---

## Borders & Radius

| Token | Value | Use |
|-------|-------|-----|
| `radius-sm` | 4px | Buttons, inputs |
| `radius-md` | 8px | Cards |
| `radius-lg` | 12px | Modals, large cards |
| `radius-full` | 9999px | Avatars, pills |

---

## Shadows

| Token | Value | Use |
|-------|-------|-----|
| `shadow-sm` | 0 1px 2px rgba(0,0,0,0.05) | Subtle lift |
| `shadow-md` | 0 4px 6px rgba(0,0,0,0.1) | Cards |
| `shadow-lg` | 0 10px 15px rgba(0,0,0,0.1) | Dropdowns |
| `shadow-xl` | 0 20px 25px rgba(0,0,0,0.1) | Modals |

---

## Motion

### Timing

| Token | Duration | Use |
|-------|----------|-----|
| `duration-fast` | 150ms | Micro-interactions |
| `duration-normal` | 250ms | Standard transitions |
| `duration-slow` | 400ms | Emphasis, modals |

### Easing

| Token | Curve | Use |
|-------|-------|-----|
| `ease-out` | cubic-bezier(0, 0, 0.2, 1) | Enter animations |
| `ease-in` | cubic-bezier(0.4, 0, 1, 1) | Exit animations |
| `ease-in-out` | cubic-bezier(0.4, 0, 0.2, 1) | Move animations |

### Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## Icons

**Library**: {e.g., Lucide React}

| Context | Size |
|---------|------|
| Inline with text | 16px |
| Button icon | 18px |
| Card header | 20px |
| Empty state | 48px |

---

## Component Tokens

### Buttons

| Variant | Background | Text | Border | Hover |
|---------|------------|------|--------|-------|
| Primary | `primary` | white | none | `primary-hover` |
| Secondary | white | `neutral` | `border-default` | `bg-muted` |
| Ghost | transparent | `neutral` | none | `bg-muted` |
| Danger | `danger` | white | none | `danger-hover` |

### Inputs

| State | Background | Border | Text |
|-------|------------|--------|------|
| Default | `bg-surface` | `border-default` | `neutral` |
| Focus | `bg-surface` | `primary` | `neutral` |
| Error | `bg-surface` | `danger` | `neutral` |
| Disabled | `bg-muted` | `border-muted` | `neutral-muted` |

### Cards

```css
.card {
  background: var(--bg-surface);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-md);
  padding: var(--space-6);
  box-shadow: var(--shadow-sm);
}
```

---

## Export Formats

Generate from this spec:
- [ ] `tokens.css` — CSS custom properties
- [ ] `tokens.json` — For tooling/AI
- [ ] `tailwind.config.js` — Tailwind integration

---

## Changelog

| Version | Date | Change | Why |
|---------|------|--------|-----|
| 1.0 | {date} | Initial tokens | {source} |

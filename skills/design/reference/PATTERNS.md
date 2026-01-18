# Design Patterns

Proven component patterns. When you solve a problem well, add it here.

## Layout Patterns

### App Shell: Top Nav
When: Single-level navigation, 5-7 main sections

```
┌─────────────────────────────────────────────────────┐
│ [Logo]  Nav Nav Nav Nav Nav    [Actions] [User]     │
├─────────────────────────────────────────────────────┤
│                                                     │
│                    Content                          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

Use when: Simple app, few top-level pages
Avoid when: Deep hierarchy, need persistent sidebar

### App Shell: Sidebar
When: Deep navigation, collapsible sections

```
┌──────────┬──────────────────────────────────────────┐
│          │  [Breadcrumb]               [Actions]    │
│  Nav     ├──────────────────────────────────────────┤
│  Nav     │                                          │
│  Nav     │                Content                   │
│  ---     │                                          │
│  Nav     │                                          │
│          │                                          │
└──────────┴──────────────────────────────────────────┘
```

Use when: Many sections, hierarchical content
Avoid when: Simple app, mobile-first

### Dashboard Grid
When: Multiple metrics/cards at a glance

```
┌─────────────────────────────────────────────────────┐
│  [Stat] [Stat] [Stat] [Stat]                        │
├─────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────────────┐   │
│  │                 │  │                         │   │
│  │  Primary Card   │  │     Secondary Card      │   │
│  │                 │  │                         │   │
│  └─────────────────┘  └─────────────────────────┘   │
├─────────────────────────────────────────────────────┤
│  [List of items...]                                 │
└─────────────────────────────────────────────────────┘
```

Use when: Overview page, multiple data types
Pattern: Stats top, primary content middle, list bottom

## Component Patterns

### Status Badge
Semantic coloring for state:

| Status | Background | Text | Icon |
|--------|------------|------|------|
| Success/Healthy | emerald-50 | emerald-700 | ✓ |
| Warning/Attention | amber-50 | amber-700 | ⚠ |
| Danger/At-Risk | rose-50 | rose-700 | ! |
| Neutral/Info | slate-100 | slate-600 | ℹ |

```tsx
<Badge variant="success">Healthy</Badge>
<Badge variant="warning">Needs Attention</Badge>
<Badge variant="danger">At Risk</Badge>
```

### Card with Actions
Hover reveals actions, keeps UI clean:

```
┌─────────────────────────────────────┐
│ [Icon]  Title                       │
│         Subtitle / metadata         │
│                                     │
│ Content content content...          │
│                                     │
├─────────────────────────────────────┤  ← appears on hover
│ [Edit] [Share] [Archive]            │
└─────────────────────────────────────┘
```

### Empty State
When there's no data yet:

```
┌─────────────────────────────────────┐
│                                     │
│            [Large Icon]             │
│                                     │
│          No {things} yet            │
│                                     │
│   Helpful message about what        │
│   to do to get started              │
│                                     │
│         [Primary Action]            │
│                                     │
└─────────────────────────────────────┘
```

Always include: Icon, title, helpful text, action button

### Loading States

**Skeleton**: For content that will appear
```
┌─────────────────────────────────────┐
│ [████]  ████████████                │ ← shimmer animation
│         █████████                   │
└─────────────────────────────────────┘
```

**Spinner**: For actions in progress
- Use when: Button clicked, form submitting
- Show after: 200ms delay (avoid flash)

**Progress**: For long operations
- Use when: > 2 seconds expected
- Show: Percentage or steps completed

### Error States

**Inline Error** (form fields):
```
┌─────────────────────────────────────┐
│ [Input field                    ]   │
│ ⚠ Email address is required        │  ← red, below field
└─────────────────────────────────────┘
```

**Banner Error** (page-level):
```
┌─────────────────────────────────────┐
│ ⚠ Couldn't load accounts.     [↻]  │  ← top of content area
│   Check connection and retry.       │
└─────────────────────────────────────┘
```

**Full Page Error** (fatal):
```
┌─────────────────────────────────────┐
│                                     │
│            [Error Icon]             │
│                                     │
│       Something went wrong          │
│                                     │
│   {Specific, actionable message}    │
│                                     │
│    [Try Again]  [Go Home]           │
│                                     │
└─────────────────────────────────────┘
```

## Interaction Patterns

### Command Palette
Keyboard-first power user feature:

- Trigger: `Cmd+K` or `Ctrl+K`
- Fuzzy search all actions
- Recent items first
- Keyboard navigation

Steal from: Linear, Raycast, Superhuman

### Quick Capture
Minimal friction input:

```
┌─────────────────────────────────────┐
│ [What did you learn? ...        ] + │
└─────────────────────────────────────┘
         ↓ (on focus, expand)
┌─────────────────────────────────────┐
│ [What did you learn? ...        ] + │
├─────────────────────────────────────┤
│ Type: [Win] [Loss] [Insight] [Obs]  │
│ Account: [dropdown]                 │
└─────────────────────────────────────┘
```

### Expandable Rows
Show summary, reveal details:

```
┌─────────────────────────────────────┐
│ ▶ Item title          Metadata    │ ← collapsed
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ ▼ Item title          Metadata    │ ← expanded
├─────────────────────────────────────┤
│   Full details here...              │
│   Additional fields...              │
│   [Actions]                         │
└─────────────────────────────────────┘
```

### Filter Tabs
Switch views quickly:

```
┌─────────────────────────────────────┐
│ [All (12)] [Active (8)] [Done (4)] │ ← pill/tab style
├─────────────────────────────────────┤
│ [Search...              ] [Filter]  │
└─────────────────────────────────────┘
```

## Form Patterns

### Inline Validation
Validate as user types (debounced):

- Valid: Green check after field
- Invalid: Red message below field
- Validating: Subtle spinner

### Autosave
For important content:

- Save on blur
- Save on pause (2s debounce)
- Show "Saved" indicator briefly
- Show "Saving..." during save

### Multi-Step Forms
For complex input:

```
[1. Basics] → [2. Details] → [3. Review] → [Done]
    ●────────────○────────────○────────────○
```

- Show progress
- Allow back navigation
- Preserve state between steps

---

## Adding New Patterns

When you solve a problem well:

1. Name the pattern
2. Describe when to use it
3. Show the visual structure (ASCII)
4. Provide code snippet if applicable
5. Note where you stole it from

```markdown
### Pattern Name
When: {situation}

{ASCII diagram}

Use when: {good scenarios}
Avoid when: {bad scenarios}
Stolen from: {source}
```

---

## Design Smells

Inspired by Martin Fowler's "code smells" — signs that specs, journeys, or patterns need refactoring.

### Spec Smells

| Smell | Symptom | Remedy |
|-------|---------|--------|
| **Spec Bloat** | >3 pages, hard to hold in head | Split into smaller specs |
| **Changelog Explosion** | >5 changelog entries | Major refactor or split |
| **Test Explosion** | >20 tests per spec | Spec too large, decompose |
| **Orphan Spec** | No journey link | Delete or link to journey |
| **Zombie Spec** | Draft >4 weeks | Decide: finish or archive |

### Journey Smells

| Smell | Symptom | Remedy |
|-------|---------|--------|
| **Journey Bloat** | >10 steps in flow | Split into sub-journeys |
| **Fork Overload** | >3 decision points | Simplify or split paths |
| **Vague Actor** | "User does X" | Create persona or be specific |
| **Missing Emotion** | No emotional arc | Add user feeling at each stage |
| **Happy Path Only** | No edge cases | Add error/edge scenarios |

### Token Smells

| Smell | Symptom | Remedy |
|-------|---------|--------|
| **Token Sprawl** | >50 tokens | Consolidate, use semantic groups |
| **Magic Numbers** | Hardcoded values in specs | Extract to tokens |
| **Contrast Violations** | Failed WCAG checks | Fix color pairings |
| **Font Soup** | >3 font families | Reduce to 2 |

### Research Smells

| Smell | Symptom | Remedy |
|-------|---------|--------|
| **Stale Research** | >6 months old | Refresh with live search |
| **Echo Chamber** | Only 1-2 sources | Broaden research |
| **Missing Prior Art** | No competitors studied | Do competitive analysis |
| **Domain Drift** | Research doesn't match problem | Re-research for actual domain |

### Pattern Smells

| Smell | Symptom | Remedy |
|-------|---------|--------|
| **One-Off Pattern** | Only used once | Not a pattern — inline it |
| **Over-Abstraction** | Pattern harder than direct code | Simplify or delete |
| **Stale Pattern** | Hasn't been used in 6 months | Validate still relevant |

### When to Refactor

Refactor when you notice:
- Onboarding takes too long (system too complex)
- Same question asked twice (documentation unclear)
- Specs conflict with each other (versioning issue)
- Implementation diverges from spec (spec drift)

### Refactoring Checklist

- [ ] Identify the smell
- [ ] Verify tests still pass after change
- [ ] Update changelog with refactoring rationale
- [ ] Notify anyone using the affected artifact

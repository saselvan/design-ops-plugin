# Visual Targets: {project-name}

id: VT-{project}
version: 1.0
date: {YYYY-MM-DD}
figma_source: {Figma URL or "N/A"}

---

## Purpose

Capture visual references before writing specs. These become the source of truth for visual validators during implementation.

---

## Figma Source

### File Information

| Field | Value |
|-------|-------|
| File URL | {Figma URL} |
| File Name | {name} |
| Last Updated | {date} |
| Access | view/edit |

### Frames to Capture

| Frame Name | Node ID | Breakpoint | Captured? |
|------------|---------|------------|-----------|
| {frame} | {node-id} | Desktop | yes/no |
| {frame} | {node-id} | Tablet | yes/no |
| {frame} | {node-id} | Mobile | yes/no |

### Figma Variables Extracted

| Variable | Type | Value | Mapped To |
|----------|------|-------|-----------|
| {name} | color | {value} | --color-{name} |
| {name} | spacing | {value} | --space-{n} |
| {name} | typography | {value} | --text-{name} |

> Run `/design {project} visual` to auto-extract using Figma MCP.

---

## Reference Screenshots

### Breakpoint Definitions

| Breakpoint | Width | Target Devices |
|------------|-------|----------------|
| Desktop | 1440px | Laptop, external monitor |
| Tablet | 768px | iPad portrait |
| Mobile | 320px | iPhone SE, small phones |

### Captured Screenshots

#### Desktop (1440px)

| Component/Page | Screenshot | Notes |
|----------------|------------|-------|
| {name} | ![](./assets/{name}-desktop.png) | {notes} |

#### Tablet (768px)

| Component/Page | Screenshot | Notes |
|----------------|------------|-------|
| {name} | ![](./assets/{name}-tablet.png) | {notes} |

#### Mobile (320px)

| Component/Page | Screenshot | Notes |
|----------------|------------|-------|
| {name} | ![](./assets/{name}-mobile.png) | {notes} |

---

## Capture Methods

### Figma MCP (Preferred)

```bash
# Extract screenshots directly from Figma frames
figma-mcp screenshot --file {file-id} --node {node-id} --output assets/
```

### Playwright MCP

```bash
# Screenshot existing URL at multiple breakpoints
playwright-mcp screenshot --url {url} --widths 320,768,1440 --output assets/
```

### Manual Upload

1. Take screenshot from Figma/browser
2. Name: `{component}-{breakpoint}.png`
3. Place in `docs/design/assets/`

---

## Visual Acceptance Criteria

### Global Criteria (Apply to All)

- [ ] Colors use tokens from tokens.md exclusively
- [ ] Spacing follows 4px/8px grid from tokens.md
- [ ] Typography uses defined font stack
- [ ] Focus states are visible and consistent
- [ ] Hover states provide clear feedback
- [ ] Reduced motion alternatives exist

### Component-Specific Criteria

| Component | Criteria |
|-----------|----------|
| {component} | {specific visual requirements} |

---

## Token Mapping

### Colors

| Figma Color | Hex | Token |
|-------------|-----|-------|
| Primary | {hex} | --color-primary |
| Secondary | {hex} | --color-secondary |
| Background | {hex} | --bg-base |
| Surface | {hex} | --bg-surface |
| Text | {hex} | --color-neutral |
| {name} | {hex} | --color-{name} |

### Spacing

| Figma Spacing | Value | Token |
|---------------|-------|-------|
| XS | 4px | --space-1 |
| SM | 8px | --space-2 |
| MD | 16px | --space-4 |
| LG | 24px | --space-6 |
| XL | 32px | --space-8 |

### Typography

| Figma Style | Font | Size | Weight | Token |
|-------------|------|------|--------|-------|
| Heading 1 | {font} | {size} | {weight} | --text-2xl |
| Heading 2 | {font} | {size} | {weight} | --text-xl |
| Body | {font} | {size} | {weight} | --text-base |
| Caption | {font} | {size} | {weight} | --text-sm |

---

## Component Library

### Extracted Components

| Figma Component | Maps To | Props |
|-----------------|---------|-------|
| Button/Primary | `<Button variant="primary">` | {props} |
| Button/Secondary | `<Button variant="secondary">` | {props} |
| Card | `<Card>` | {props} |
| {component} | {implementation} | {props} |

---

## Sync Status

| Item | Last Synced | Status |
|------|-------------|--------|
| Figma variables | {date} | current/stale |
| Reference screenshots | {date} | current/stale |
| Component mappings | {date} | current/stale |

### Re-sync Triggers

Run `/design {project} visual` when:
- Figma file is updated
- New components are added
- Design tokens change
- Before starting new implementation phase

---

## Notes

{Any additional context about the visual targets, design decisions, or known issues}

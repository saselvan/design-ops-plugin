# Zeroshot Design Cluster Config

A pre-configured multi-agent cluster for implementing UI specs with visual validation.

## Overview

This cluster config adds visual validators to the standard Zeroshot implementation flow:

```
┌─────────┐    ┌─────────┐    ┌───────────────────────────┐
│ Planner │ →  │ Worker  │ →  │      VALIDATORS           │
└─────────┘    └─────────┘    │                           │
                              │  ✓ spec-validator         │
                              │  ✓ test-validator         │
                              │  ✓ visual-validator ←──── Playwright
                              │  ✓ a11y-validator         │
                              └───────────────────────────┘
                                       │
                                  REJECT? → Back to Worker
                                       │
                                   ALL OK → Commit
```

## Installation

### Option 1: Copy to Zeroshot configs

```bash
# Find your zeroshot config directory
zeroshot config list

# Copy the config
cp zeroshot-design-cluster.json ~/.zeroshot/cluster-templates/design-implementation.json
```

### Option 2: Reference from project

Keep the config in your project and reference it:

```bash
zeroshot run docs/design/implement.md --config ./zeroshot-design-cluster.json
```

## Prerequisites

Before running, ensure:

1. **Playwright installed:**
   ```bash
   npm install -g playwright
   npx playwright install
   ```

2. **Project structure:**
   ```
   docs/design/
   ├── specs/           # Feature specs (S-001-*.md)
   ├── tests/           # Test contracts (T-001-*.md)
   ├── tokens.md        # Design tokens
   ├── visual-targets.md # Visual references
   ├── assets/          # Reference screenshots
   │   ├── S-001-desktop.png
   │   ├── S-001-tablet.png
   │   └── S-001-mobile.png
   └── implement.md     # Implementation orchestration file
   ```

3. **Reference screenshots captured:**
   Run `/design {project} visual` to capture screenshots before implementation.

## Usage

### Basic

```bash
zeroshot run docs/design/implement.md --config design-implementation
```

### With Docker isolation

```bash
zeroshot run docs/design/implement.md --config design-implementation --docker
```

### With worktree isolation

```bash
zeroshot run docs/design/implement.md --config design-implementation --worktree
```

## Validators

### spec-validator

Checks implementation against specs/*.md:
- Interface contracts (props, state, events)
- State machine transitions
- Error handling
- Accessibility requirements

### test-validator

Runs tests/*.md acceptance criteria:
- Given/When/Then scenarios
- Edge cases
- Performance targets

### visual-validator

Screenshots and compares visual output:
- **Breakpoints:** 1440px, 768px, 320px
- **Token validation:** Colors, spacing, typography
- **Responsive check:** Layout, overflow, touch targets

**Rejection criteria:**
- Spacing > 4px off from reference
- Hardcoded colors (not from tokens.md)
- Typography not matching scale
- Layout breaks at any breakpoint
- Visual regression > 5% pixel difference

### a11y-validator

Runs axe-core accessibility audit:
- WCAG 2.1 AA compliance
- Color contrast (4.5:1 text, 3:1 UI)
- Keyboard navigation
- Focus indicators
- ARIA labels

## Customization

### Adjust rejection thresholds

Edit `visual-validator` prompt:
```json
"REJECT if:\n- Spacing > 8px off from reference\n..."
```

### Add custom validators

Add to `validators` array:
```json
{
  "name": "performance-validator",
  "model": "haiku",
  "trigger": "on_task_complete",
  "prompt": "Run Lighthouse performance audit. Reject if score < 90."
}
```

### Change breakpoints

Edit `visual-validator` prompt:
```json
"1. Screenshot rendered component at breakpoints:\n   - Desktop: 1920px\n   - Tablet: 1024px\n..."
```

## Troubleshooting

### Visual validator failing incorrectly

1. Check reference screenshots are current
2. Ensure tokens.md is complete
3. Increase `screenshot_wait` in settings
4. Check for dynamic content affecting screenshots

### A11y validator too strict

Adjust from "REJECT if any violation" to:
```
REJECT if any critical or serious violation.
WARN for moderate violations.
```

### Slow validation

Enable parallel validation (if validators are independent):
```json
"parallel_validation": true
```

## Integration with Design Ops

This config is designed to work with the Design Ops flywheel:

1. `/design {project}` produces specs + tests + tokens + visual targets
2. Zeroshot with this config implements and validates
3. `/design {project} retrospective` captures learnings (including visual accuracy)

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-01 | Initial release with visual + a11y validators |

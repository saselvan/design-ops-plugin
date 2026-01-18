# Visual Validation: {project-name}

id: VV-{NNN}
specs_validated: S-{NNN}, S-{NNN}, ...
date: {YYYY-MM-DD}
validator: {name}

---

## Purpose

Before writing tests, validate that visual targets are achievable and properly specified. This catches issues that would otherwise surface during implementation.

> "If you can't describe it in tokens, you can't validate it programmatically."

---

## Figma Feasibility

Can the design be implemented with the current tech stack?

| Design Element | Feasible? | Notes |
|----------------|-----------|-------|
| {layout/component} | yes/partial/no | {implementation notes} |

### Feasibility Issues

| Issue | Design Element | Resolution |
|-------|----------------|------------|
| {blocker} | {element} | {how to resolve or descope} |

---

## Token Coverage

Are all visual elements covered by tokens.md?

### Color Check

| Spec | Color Used | Token Exists? | Token Name |
|------|------------|---------------|------------|
| S-{NNN} | {hex value} | yes/no | {token or "MISSING"} |

### Spacing Check

| Spec | Spacing Used | On Grid? | Token Name |
|------|--------------|----------|------------|
| S-{NNN} | {px value} | yes/no | {token or "OFF GRID"} |

### Typography Check

| Spec | Font/Size Used | In Scale? | Token Name |
|------|----------------|-----------|------------|
| S-{NNN} | {font/size} | yes/no | {token or "MISSING"} |

### Missing Tokens

| Missing Token | Used In | Proposed Value | Add to tokens.md? |
|---------------|---------|----------------|-------------------|
| {token name} | S-{NNN} | {value} | yes/no |

---

## Responsive Coherence

Do breakpoint designs make sense together?

### Breakpoint Inventory

| Breakpoint | Width | Designs Available? |
|------------|-------|-------------------|
| Desktop | 1440px | yes/no |
| Tablet | 768px | yes/no |
| Mobile | 320px | yes/no |

### Coherence Check

| Element | Desktop | Tablet | Mobile | Coherent? |
|---------|---------|--------|--------|-----------|
| {element} | {behavior} | {behavior} | {behavior} | yes/no |

### Coherence Issues

| Issue | Breakpoints | Resolution |
|-------|-------------|------------|
| {problem} | {which breakpoints} | {fix} |

---

## Reference Capture

Are reference screenshots captured for comparison during implementation?

### Screenshot Inventory

| Spec | Desktop | Tablet | Mobile | Location |
|------|---------|--------|--------|----------|
| S-{NNN} | yes/no | yes/no | yes/no | assets/S-{NNN}-*.png |

### Capture Method

| Method | Used? | Notes |
|--------|-------|-------|
| Figma MCP screenshot | yes/no | {notes} |
| Playwright URL capture | yes/no | {notes} |
| Manual upload | yes/no | {notes} |

---

## Visual Testability

Can visual requirements be validated programmatically?

### Testability Check

| Visual Requirement | Testable? | How |
|--------------------|-----------|-----|
| Color matches token | yes | Compare computed style to token value |
| Spacing on grid | yes | Check element dimensions/margins |
| Typography correct | yes | Compare font-family, font-size |
| Layout at breakpoint | yes | Playwright screenshot comparison |
| Animation timing | partial | Can check duration, hard to verify easing |
| "Feels right" | no | Requires human judgment |

### Non-Testable Requirements

| Requirement | Why Not Testable | Mitigation |
|-------------|------------------|------------|
| {requirement} | {reason} | {how to handle - manual check, design review, etc.} |

---

## Validation Checklist

### Pre-Implementation

- [ ] All colors map to tokens
- [ ] All spacing values align with spacing scale
- [ ] All typography uses defined font stack
- [ ] All breakpoints have designs
- [ ] Reference screenshots captured for all specs
- [ ] Visual acceptance criteria are specific and testable
- [ ] Animation requirements include reduced-motion alternatives

### Token Coverage

- [ ] No hardcoded color values in specs
- [ ] No off-grid spacing values
- [ ] No undefined font combinations
- [ ] All component variants use token-based styling

### Responsive

- [ ] Mobile-first approach possible
- [ ] Breakpoint transitions are logical
- [ ] No content hidden on mobile that's critical

---

## Validation Result

| Check | Status |
|-------|--------|
| Figma Feasibility | pass/fail/partial |
| Token Coverage | pass/fail/partial |
| Responsive Coherence | pass/fail/partial |
| Reference Capture | pass/fail/partial |
| Visual Testability | pass/fail/partial |

**Overall**: pass/fail

### Blockers (must resolve before tests)

| Blocker | Resolution | Owner |
|---------|------------|-------|
| {issue} | {fix} | {who} |

### Warnings (can proceed, but track)

| Warning | Risk | Mitigation |
|---------|------|------------|
| {issue} | {risk level} | {how to handle} |

---

## Sign-Off

**Validated by**: {name}
**Date**: {YYYY-MM-DD}
**Ready for tests**: yes/no

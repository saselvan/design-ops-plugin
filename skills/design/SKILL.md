---
name: design
description: "Use when starting any design work - new products, features, or components. Orchestrates the full Design Ops flywheel from research to implementation-ready specs."
---

# Design Ops Flywheel

Turn ideas into exhaustive, tested implementations through a research-driven design process.

## Overview

This skill orchestrates a complete design workflow:

```
Research → Validation → Constraints → Brainstorm → Journeys → Tokens → Visual Targets → Specs → Visual Validation → Tests → Implementation
```

Each phase has validation gates that catch problems before they propagate downstream.

## Usage

```
/design {project}                      # Auto-detect mode, full workflow
/design {project} full                 # Force full mode (new product)
/design {project} standard             # Force standard mode (multi-file feature)
/design {project} minimal              # Force minimal mode (bug fix)
/design {project} research             # Research phase only
/design {project} journey              # Journey phase only
/design {project} spec                 # Spec phase only
/design {project} visual               # Capture visual targets (screenshots, tokens from Figma)
/design {project} validate visual      # Run visual validation on implementation
/design {project} retrospective        # Post-implementation review
```

## Mode Detection

Analyze the request to determine mode:

| Signal | Mode |
|--------|------|
| "new product", "build from scratch", "greenfield" | Full |
| "feature", "add", "implement", multiple components | Standard |
| "fix", "bug", "tweak", "update", single component | Minimal |
| Unclear | Ask user |

## Mode Comparison

| Phase | Full | Standard | Minimal |
|-------|------|----------|---------|
| Research + Validation | ✅ 2 iterations | ✅ 1 iteration | ❌ |
| Constraints | ✅ | ✅ | ❌ |
| Brainstorm | ✅ | Optional | ❌ |
| Tracer Bullet | ✅ | ❌ | ❌ |
| Personas | If needed | ❌ | ❌ |
| Journeys + Validation | ✅ 2 iterations | ✅ 1 iteration | ❌ |
| Tokens | ✅ | Reuse existing | Reuse existing |
| Visual Targets | ✅ | ✅ if UI | ❌ |
| Specs + Validation | ✅ 2 iterations | ✅ 1 iteration | ✅ no validation |
| Visual Validation | ✅ | ✅ if UI | ❌ |
| Tests + Validation | ✅ 2 iterations | ✅ 1 iteration | ✅ no validation |
| Retrospective | ✅ | ✅ | Optional |

## The Phases

### Phase 1: Research
Gather domain expertise, prior art, and cross-domain inspiration.
- Find domain experts and legends (minimum 3 sources)
- Analyze competitors and adjacent products
- Cross-domain inspiration (architecture, industrial design, art)
- Generate token recommendations

**Read:** `templates/research.md` for full process and output format.

### Phase 1.5: Research Validation
Stress test research before it poisons everything downstream.
- Echo chamber detection (diverse perspectives?)
- Staleness check (current sources?)
- Domain drift detection (matches actual problem?)
- Missing competitors
- Assumption surfacing

**Read:** `templates/research-validation.md` for validation prompts.

### Phase 2: Constraints
Capture boundaries before designing within them.
- Technical stack, deployment, auth
- Performance budgets
- Timeline and resources
- Non-negotiables and explicit descopes

**Read:** `templates/constraints.md` for full template.

### Phase 3: Brainstorm
Turn research + constraints into requirements through dialogue.
- Invoke `superpowers:brainstorming` if available
- Load research as context
- Explore requirements conversationally

### Phase 3.5: Tracer Bullet (Full mode only)
Validate assumptions with minimal end-to-end implementation.
- Pick ONE journey (riskiest)
- Build ugly but functional
- Document learnings
- Adjust remaining specs

### Phase 4: Personas (if needed)
Create reusable actor profiles for distinct user types.

**Read:** `templates/persona.md` for template.

### Phase 5: User Journeys
Map user paths with emotional awareness.
- Actor, goal, context
- Mermaid flowchart
- Emotional arc
- Edge cases and error paths

**Read:** `templates/journey.md` for full template.

### Phase 5.5: Journey Validation
Stress test journeys before they drive specs.
- Happy path bias detection
- Actor vagueness check
- Reality check
- Missing decision points
- Emotional arc validation
- Journey bloat detection

**Read:** `templates/journey-validation.md` for validation prompts.

### Phase 6: Design Tokens
Codify visual design decisions as reusable tokens.
- Typography, colors, spacing
- Borders, shadows, motion
- Component tokens
- Extract from Figma MCP if available

**Check domain libraries:** `domains/{domain}.md`
**Read:** `templates/tokens.md` for template.

### Phase 6.5: Visual Targets
Capture visual references before writing specs.
- Extract screenshots from Figma (Figma MCP) or existing URLs (Playwright MCP)
- Capture at breakpoints: Desktop (1440px), Tablet (768px), Mobile (320px)
- Map Figma variables to design tokens
- Document visual acceptance criteria

**Run:** `/design {project} visual` to capture targets.
**Read:** `templates/visual-targets.md` for template.

### Phase 7: Specs
Ralph-style exhaustive specifications.
- Interface contracts
- State machines
- Visual specs with references
- Accessibility requirements
- Performance targets
- Definition of Done

**Read:** `templates/spec.md` for full template.

### Phase 7.5: Spec Validation
Stress test specs before deriving tests.
- Ambiguity detection
- Edge case generation
- Implementation simulation
- Contradiction detection

**Read:** `templates/spec-validation.md` for validation prompts.

### Phase 7.7: Visual Validation
Validate visual targets before writing tests.
- Figma feasibility (can design be implemented with current stack?)
- Token coverage (all colors, spacing, typography mapped?)
- Responsive coherence (breakpoint designs make sense together?)
- Reference capture (screenshots captured for all specs?)
- Visual testability (can requirements be validated programmatically?)

**Read:** `templates/visual-validation.md` for validation prompts.

### Phase 8: Tests
Multi-layer test contracts.
- Functional tests (Given/When/Then)
- Non-functional tests (performance, accessibility, security)
- LLM-as-Judge tests (quality gates)

**Read:** `templates/test.md` for template.

### Phase 8.5: Test Validation
Stress test the tests themselves.
- False positive detection
- False negative detection
- Spec coverage
- Mutation survival
- The Inversion Test

**Read:** `templates/test-validation.md` for validation prompts.

### Handoff
Package specs + tests for implementation.

**With Zeroshot visual validators:**
```bash
zeroshot run docs/design/implement.md --config design-implementation
```

**Standard Zeroshot:**
```bash
zeroshot run --specs ./docs/design/specs --tests ./docs/design/tests
```

**Ralph:**
```bash
ralph build --spec ./docs/design/specs/S-001-*.md
```

**Read:** `zeroshot/zeroshot-design-cluster.md` for visual validation cluster config.

### Phase 9: Retrospective
Capture learnings after implementation.
- Research accuracy
- Journey accuracy
- Spec accuracy
- Test accuracy
- Visual accuracy (token usage, validator results, Figma drift)
- Learnings to propagate

**Read:** `templates/retrospective.md` for template.

## Output Structure

```
{project}/docs/design/
├── research.md
├── research-validation.md
├── constraints.md
├── requirements.md
├── tokens.md
├── visual-targets.md
├── visual-validation.md
├── personas/
│   └── P-001-{name}.md
├── journeys/
│   ├── J-001-{name}.md
│   └── J-001-validation.md
├── specs/
│   ├── S-001-{name}.md
│   └── S-001-validation.md
├── tests/
│   ├── T-001-{name}.md
│   └── T-001-validation.md
├── assets/
│   ├── S-001-desktop.png
│   ├── S-001-tablet.png
│   └── S-001-mobile.png
└── retrospective.md
```

## Zeroshot Visual Validation

For UI-heavy projects, use the visual validation cluster config:

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

**Read:** `zeroshot/zeroshot-design-cluster.md` for setup and usage.

## Escape Hatch

If complexity discovered mid-process, recommend upgrading to a higher mode. Don't power through with insufficient design.

## Expert Foundations

This system is grounded in principles from:
- **The Pragmatic Programmer** (Hunt & Thomas) — DRY, tracer bullets
- **Shape Up** (Basecamp) — Fixed time/variable scope, no backlog
- **About Face** (Alan Cooper) — Goal-directed design, personas
- **Test-Driven Development** (Kent Beck) — Tests before code
- **Refactoring** (Martin Fowler) — Small transformations, code smells
- **Clean Code** (Robert Martin) — Unambiguous specs

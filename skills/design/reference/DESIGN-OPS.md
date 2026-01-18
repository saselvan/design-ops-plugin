# Design Ops System

A self-contained system for turning ideas into exhaustive, tested implementations.

## The Flywheel

```
/design {project}
        ↓
   Research (domain experts, prior art, legends)
        ↓
   Research Validation (echo chamber, staleness, drift)
        ↓
   Constraints (tech, timeline, non-negotiables)
        ↓
   Brainstorm (informed by research)
        ↓
   Tracer Bullet (optional: minimal vertical slice)
        ↓
   User Journeys (Mermaid + narrative)
        ↓
   Journey Validation (happy path bias, actor clarity, reality)
        ↓
   Design Tokens (domain-informed visual system)
        ↓
   Specs (Ralph-style, exhaustive)
        ↓
   Spec Validation (ambiguity, edge cases, contradictions)
        ↓
   Tests (functional + non-functional + LLM-as-judge)
        ↓
   Test Validation (false positives, coverage, mutation)
        ↓
   Feed to Zeroshot/Ralph → Implementation
        ↓
   Retrospective (accuracy analysis, learning capture)
        ↓
   Learnings → PRINCIPLES / PATTERNS / Domains → next /design
```

## Quick Start

```
/design my-new-project
```

The skill will guide you through each phase.

## Output Structure

```
{project}/docs/design/
├── research.md          # Domain research, prior art, principles
├── constraints.md       # Technical and resource boundaries
├── requirements.md      # What we're building
├── tokens.md            # Visual design system
├── journeys/
│   ├── J-001-{name}.md  # User journey files
│   └── ...
├── specs/
│   ├── S-001-{name}.md  # Feature specifications
│   └── ...
└── tests/
    ├── T-001-{name}.md  # Test contracts
    └── ...
```

## Phases

### 1. Research
- Domain experts and legends
- Prior art (competitors, adjacent products, architecture, art)
- Cross-domain inspiration
- Live search + curated library

See: `templates/research.md`

### 1.5 Research Validation (Required)
Before research informs design, stress test it:
- **Echo Chamber Detection**: Are we only citing sources that agree?
- **Staleness Check**: Is anything outdated?
- **Domain Drift Detection**: Does research match the actual problem?
- **Missing Competitors**: Who are we ignoring?
- **Assumption Surfacing**: What are we taking for granted?

> "Flawed research poisons everything downstream. Validate before building on it."

Minimum 2 iterations. All critical gaps must be resolved.

See: `templates/research-validation.md`

### 2. Constraints
- Technical boundaries (stack, deployment, auth)
- Performance budgets
- Resource reality (timeline, team, budget)
- Non-negotiables vs explicit descopes

See: `templates/constraints.md`

### 3. Brainstorm
Uses `superpowers:brainstorming` with research context loaded.
- Requirements emerge from conversation
- Informed by domain expertise
- Grounded in constraints

### 3.5 Tracer Bullet (Optional but Recommended)
Before committing to full specs, build a minimal vertical slice:
- Pick ONE journey, implement end-to-end
- Ugly but functional — validate assumptions
- Informs remaining specs with real learnings
- Reduces risk of spec-reality mismatch

> "Tracer bullets show what you're hitting. They illuminate the path from requirement to system." — Pragmatic Programmer

### 4. Personas (If Needed)
For products with distinct user types:
- Lightweight actor profiles
- Reusable across journeys
- Capture goals, pains, context

See: `templates/persona.md`

### 5. User Journeys
- Actor, goal, context
- Mermaid flowchart (happy path)
- Narrative (emotional arc)
- Edge cases and error paths
- Traceability ID (J-001, J-002, ...)

See: `templates/journey.md`

### 5.5 Journey Validation (Required)
Before journeys drive specs, stress test them:
- **Happy Path Bias**: What happens when things go wrong?
- **Actor Vagueness**: Is the actor specific enough to design for?
- **Reality Check**: Does this match how users actually behave?
- **Missing Decision Points**: Are all branches captured?
- **Emotional Arc**: Is the user's feeling considered at each stage?
- **Journey Bloat**: Is this one journey or many?

> "A journey that only shows success teaches nothing about resilience."

Minimum 2 iterations. Common error paths must be documented.

See: `templates/journey-validation.md`

### 6. Design Tokens
- Typography (domain-appropriate fonts)
- Color (semantic palette with contrast ratios)
- Spacing (consistent scale)
- Components (buttons, cards, badges)
- Motion (timing, easing, reduced motion)

See: `templates/tokens.md`, `domains/`

### 7. Specs
Ralph-style exhaustive specifications:
- Interface contracts
- Component breakdown
- State machines
- API shapes
- Accessibility requirements
- Version + changelog
- Traceability (S-001 → J-001)

See: `templates/spec.md`

### 7.5 Spec Validation (Required)
Before deriving tests, stress test the spec itself:
- **Ambiguity Detection**: Can any requirement be interpreted multiple ways?
- **Edge Case Generation**: Does the spec handle unexpected inputs?
- **Implementation Simulation**: Can someone build from this spec alone?
- **Contradiction Detection**: Do any requirements conflict?

> "Bad specs create bad tests. Bad tests create false confidence. False confidence creates production bugs." — The Spec-Test Chain of Pain

Minimum 2 iterations required. Spec must pass all four checks before tests are written.

See: `templates/spec-validation.md`

### 8. Tests
Multi-layer testing:
- **Functional**: Given/When/Then behavioral scenarios
- **Non-Functional**: Performance, accessibility, security, resilience
- **LLM-as-Judge**: Quality gates evaluated against original requirements

See: `templates/test.md`

### 8.5 Test Validation (Required)
Before tests become the quality gate, stress test them:
- **False Positive Detection**: Would tests pass even if feature is broken?
- **False Negative Detection**: Would tests fail even when feature works?
- **Spec Coverage Gap**: Does every requirement have a test?
- **Mutation Survival**: Would tests catch common bugs?
- **Test Smell Detection**: Anti-patterns that make tests unreliable?

> "A test that can't fail is worthless. A test that fails for the wrong reason is dangerous."

Minimum 2 iterations. The Inversion Test: deliberately break implementation, verify tests fail.

See: `templates/test-validation.md`

### 9. Definition of Done
Every spec includes exit criteria:
- Code quality checks
- Accessibility validation
- Documentation updated
- Deployed and tested
- Real usage validation (you used it)

### 10. Retrospective (Required)
After implementation, capture learnings:
- **Research Accuracy**: Did our research predict reality?
- **Journey Accuracy**: Did users follow the paths we designed?
- **Spec Accuracy**: Did specs match implementation needs?
- **Test Accuracy**: Did tests catch real bugs?
- **Process Observations**: What worked, what didn't?

Propagate learnings to: PRINCIPLES.md, PATTERNS.md, Domain files, Validation prompts.

> "We don't learn from experience. We learn from reflecting on experience." — John Dewey

See: `templates/retrospective.md`

## Traceability

Every artifact links back:

```
Requirement → Journey → Spec → Test → Code → Commit
   REQ-001  →  J-001  → S-001 → T-001 → Component.tsx
```

## Versioning

- Specs have version numbers and changelogs
- States: `draft` → `active` → `deprecated` → `archived`
- Git tracks history, changelog tracks intent

## Backlog Policy

Inspired by Shape Up's "no backlog" philosophy:

- **Specs not implemented within 2 cycles** → Archive them
- **Ideas don't accumulate** — Capture fresh each time
- **If it's important, it'll come up again**
- **Stale research (>6 months)** → Refresh before using

This prevents backlog guilt and keeps focus on current priorities.

## Domain Library

Pre-researched token sets and principles for common domains:

- `domains/healthcare.md`
- `domains/fintech.md`
- `domains/developer-tools.md`
- `domains/consumer.md`

Start from these, customize per project.

## Lightweight Mode

Not everything needs the full flywheel. Use this decision tree:

```
Is it a new product/major feature?
    YES → Full flywheel (all phases, all validations)
    NO  ↓

Is it a multi-component feature (>3 files)?
    YES → Standard mode (skip tracer bullet, 1 validation iteration)
    NO  ↓

Is it a bug fix or minor enhancement?
    YES → Minimal mode (spec + tests only, no validation)
    NO  → Just do it
```

### Mode Comparison

| Phase | Full | Standard | Minimal |
|-------|------|----------|---------|
| Research | ✅ + validation | ✅ (no validation) | ❌ |
| Constraints | ✅ | ✅ | ❌ |
| Brainstorm | ✅ | Optional | ❌ |
| Tracer Bullet | ✅ | ❌ | ❌ |
| Personas | If needed | ❌ | ❌ |
| Journeys | ✅ + validation | ✅ (1 iteration) | ❌ |
| Tokens | ✅ | Reuse existing | Reuse existing |
| Specs | ✅ + validation | ✅ (1 iteration) | ✅ (no validation) |
| Tests | ✅ + validation | ✅ (no validation) | ✅ |
| Retrospective | ✅ | ✅ | Optional |

### Escape Hatch

If you start in Minimal mode and discover complexity:
1. Stop
2. Upgrade to Standard or Full
3. Don't power through with insufficient design

> "The time you 'save' skipping design, you pay back 10x in debugging."

---

## Integration with Zeroshot

Zeroshot handles implementation orchestration. Design Ops handles pre-implementation.

```
Design Ops Flywheel          Zeroshot
─────────────────────────    ─────────────────────────
Research
    ↓
Research Validation
    ↓
Constraints
    ↓
Brainstorm
    ↓
Journeys
    ↓
Journey Validation
    ↓
Tokens
    ↓
Specs
    ↓
Spec Validation
    ↓
Tests ──────────────────────► Zeroshot ingests specs + tests
                                  ↓
                             Multi-agent implementation
                                  ↓
                             Code + commits
                                  ↓
Retrospective ◄───────────── Implementation complete
    ↓
Learnings → next cycle
```

### Handoff to Zeroshot

When specs are validated, package for Zeroshot:

```
{project}/docs/design/
├── specs/
│   ├── S-001-*.md      ← Zeroshot reads these
│   └── ...
├── tests/
│   ├── T-001-*.md      ← Zeroshot uses as acceptance criteria
│   └── ...
└── tokens.md           ← Zeroshot uses for styling
```

Zeroshot command:
```bash
zeroshot run --specs ./docs/design/specs --tests ./docs/design/tests
```

### Handoff from Zeroshot

After implementation, capture learnings:
1. Run `/design retrospective {project}`
2. Document what specs got wrong
3. Document what tests missed
4. Feed into next design cycle

---

## Integration

Outputs are formatted for direct ingestion by:
- **Zeroshot**: Multi-agent implementation orchestration (specs → code)
- **Ralph**: TDD-based build system (tests → implementation)
- **Claude/Cursor**: AI-assisted development (any artifact)

## Plugin Structure

```
design-ops/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── skills/
│   └── design/
│       ├── SKILL.md
│       ├── templates/
│       ├── domains/
│       └── reference/
├── README.md
└── LICENSE
```

## Commands

| Command | Purpose |
|---------|---------|
| `/design {project}` | Start flywheel (auto-detect mode) |
| `/design {project} full` | Force full mode (new product/major feature) |
| `/design {project} standard` | Force standard mode (multi-file feature) |
| `/design {project} minimal` | Force minimal mode (bug fix/enhancement) |
| `/design {project} research` | Research phase only |
| `/design {project} journey` | Journey phase only |
| `/design {project} spec` | Spec phase only |
| `/design {project} validate` | Run validation on existing artifacts |
| `/design {project} retrospective` | Post-implementation learning capture |

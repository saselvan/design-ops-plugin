# Design Ops v2.0

A spec compiler for Claude Code. Transforms human intent into validated, AI-executable specifications.

**Version**: 2.0 | **Status**: Production Ready | **License**: MIT

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/saselvan/design-ops-plugin.git ~/tools/design-ops
cd ~/tools/design-ops
```

### 2. Make scripts executable

```bash
chmod +x enforcement/*.sh tools/*.sh
```

### 3. Verify installation

```bash
cd test-integration && ./real-project-test.sh
# Should show: ✅ ALL INTEGRATION TESTS PASSED! (18/18)
```

### 4. Add to Claude Code

**Option A: Project-level** (recommended)

Create `.claude/settings.json` in your project:

```json
{
  "skills": ["~/tools/design-ops/design.md"]
}
```

**Option B: Reference in CLAUDE.md**

Add to your project's `CLAUDE.md`:

```markdown
## Skills
- ~/tools/design-ops/design.md
```

### 5. Use it

```bash
claude
> /design validate specs/my-feature.md
> /design prp specs/my-feature.md
```

---

## What is Design Ops?

Design Ops is a comprehensive methodology for designing and implementing software:

1. **Research-driven**: Cross-domain inspiration, deep domain analysis
2. **Validation-heavy**: 43 invariants catch issues at spec-time, not production
3. **Emotionally-aware**: Captures user emotional arcs, not just functional flows
4. **AI-optimized**: Generates AI-executable PRPs from validated specs
5. **Learning-enabled**: Retrospectives improve the system over time

---

## What's New in v2.0

**Enhanced with AI-Execution Optimization** (January 2026)

Based on comprehensive analysis of 2025 agentic engineering methodologies (Cole Medin, Spec-Kit, BMAD, Anthropic), v2.0 adds:

| Feature | Description |
|---------|-------------|
| Spec Validation | 43 invariants enforce clarity and completeness |
| PRP Generation | Automated transformation from specs to AI-executable PRPs |
| Confidence Scoring | Quantitative risk assessment (1-10 scale) |
| Implementation Review | Verify code matches design intent |
| Codebase Awareness | Auto-extract conventions and patterns |

---

## Quick Start

### 1. Validate a Spec

```bash
/design validate specs/S-001-feature.md
```

### 2. Generate PRP

```bash
/design prp specs/S-001-feature.md
```

### 3. Review Implementation

```bash
/design review specs/S-001-feature.md src/feature/
```

See [QUICKSTART.md](enforcement/QUICKSTART.md) for the 5-minute guide.

---

## Architecture

```
Design Ops v2.0
├── Core Skill
│   └── design.md                    # Claude Code skill file
│
├── Validation System
│   ├── validator.sh                 # 43 invariants enforcement
│   ├── system-invariants.md         # Universal invariants (1-10)
│   └── domains/                     # Domain-specific invariants
│       ├── consumer-product.md      # 11-15
│       ├── physical-construction.md # 16-21
│       ├── data-architecture.md     # 22-26
│       ├── integration.md           # 27-30
│       ├── remote-management.md     # 31-36
│       └── skill-gap-transcendence.md # 37-43
│
├── PRP Generation
│   ├── spec-to-prp.sh               # Spec → PRP generator
│   ├── prp-checker.sh               # PRP quality checker
│   ├── confidence-calculator.sh     # Risk assessment
│   └── templates/
│       ├── prp-base.md              # Master PRP template
│       ├── confidence-rubric.md     # Scoring guidelines
│       ├── section-library.md       # Reusable sections
│       └── prp-examples/            # 3 complete examples
│
├── Supporting Tools
│   └── tools/
│       ├── conventions-generator.sh # Extract codebase patterns
│       └── conventions-updater.sh   # Update CONVENTIONS.md
│
├── Testing
│   ├── test-suite/                  # Validator tests
│   └── test-integration/            # End-to-end tests
│
├── CI/CD
│   ├── .github/workflows/           # GitHub Actions
│   └── docs/git-hooks/              # Pre-commit hooks
│
└── Documentation
    ├── README.md (this file)
    ├── QUICKSTART.md
    └── docs/
```

---

## Complete Workflow

```
Research
  ↓
/design init {project}
  ↓
Constraints
  ↓
Brainstorm (requirements dialogue)
  ↓
Journeys (with emotional arcs)
  ↓
Tokens (visual design system)
  ↓
Specs (exhaustive specifications)
  ↓
/design validate {spec}          ← NEW: Invariant enforcement
  ↓
/design prp {spec}               ← NEW: PRP generation
  ↓
Implementation (using PRP)
  ↓
/design review {spec} {code}     ← NEW: Compliance check
  ↓
Retrospective
  ↓
Learnings → spec-delta → Next Project
```

---

## Key Features

### 1. Spec Validation (43 Invariants)

Catches ambiguity before it causes problems:

```bash
/design validate specs/S-001-feature.md

❌ VIOLATION: Invariant #1 (Ambiguity is Invalid)
   Line 12: "process data properly"
   → Fix: Replace 'properly' with objective criteria
```

### 2. Confidence Scoring

Quantitative risk assessment before implementation:

```
Confidence Score: 8/10
  ✅ Requirement clarity: 9/10
  ✅ Pattern availability: 9/10
  ⚠️  Edge cases: 6/10

Risk: Third-party API behavior uncertain
```

### 3. PRP Generation

Transform specs into AI-executable blueprints:

```bash
/design prp specs/S-001-feature.md

📊 PRP generated: PRPs/feature-prp.md
   Confidence: 8/10
   Quality score: 95/100
```

### 4. Implementation Review

Verify code matches design:

```bash
/design review specs/S-001-feature.md src/feature/

✅ Requirements: 11/12 implemented (92%)
✅ Tests: 87% coverage
⚠️  2 convention violations
```

---

## Philosophy

### Core Principles

1. **Invariants from pain, not theory**: Every invariant comes from a real failure
2. **Rejection over correction**: System rejects bad specs, doesn't fix them
3. **Validation before implementation**: Catch issues at spec-time
4. **Learning loops**: Retrospectives improve the system (spec-delta)
5. **Appropriate rigor**: Full/Standard/Quick modes

### Why This Approach Works

- Cross-domain research finds solutions others miss
- Emotional design creates better user experiences
- Multiple validation gates catch compound errors
- AI-executable PRPs enable reliable implementation
- Confidence scoring provides early risk warnings

---

## Documentation

| Document | Purpose |
|----------|---------|
| [QUICKSTART.md](enforcement/QUICKSTART.md) | 5-minute getting started |
| [docs/HOW-TO-USE-DESIGN-SKILL.md](docs/HOW-TO-USE-DESIGN-SKILL.md) | Complete command reference |
| [docs/FAQ.md](docs/FAQ.md) | Common questions |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Fixing issues |
| [templates/confidence-rubric.md](templates/confidence-rubric.md) | Scoring guide |
| [system-invariants.md](system-invariants.md) | Invariant definitions |

---

## Integration

### Claude Code

Load the skill by adding `design.md` from this directory to your Claude Code skills.

### Git Hooks

```bash
cd docs/git-hooks && ./install.sh
```

### CI/CD

Copy `.github/workflows/validate-specs.yml` to your repo.

---

## Testing

```bash
# Run validator tests
cd test-suite && ./run-tests.sh

# Run integration tests
cd test-integration && ./real-project-test.sh
```

---

## Version History

**v2.0** (2026-01-20)
- Added AI-execution optimization
- Integrated spec validation (43 invariants)
- Added PRP generation and quality checking
- Added confidence scoring
- Added implementation review
- Added CONVENTIONS.md generator

**v1.0** (Original)
- Research → Journeys → Specs → Implementation
- Manual handoff to implementation
- Retrospective learning loops

---

## Acknowledgments

Design Ops v2.0 was built by analyzing and synthesizing ideas from leading agentic engineering methodologies:

| Project | Author | Key Inspiration |
|---------|--------|-----------------|
| [Context Engineering](https://github.com/coleam00/context-engineering-intro) | Cole Medin | PRD structure, context file organization, validation gates |
| [Spec-Kit](https://github.com/spec-kit/spec-kit) | Spec-Kit Team | Spec validation patterns, invariant-based checking |
| [BMAD Method](https://github.com/bmadcode/BMAD-METHOD) | BMAD | Multi-agent orchestration, role-based prompting |
| [Claude Code](https://github.com/anthropics/claude-code) | Anthropic | Skill system architecture, CLI patterns |

Additional influences from foundational works:
- **The Pragmatic Programmer** (Hunt & Thomas) - Design by contract
- **About Face** (Alan Cooper) - Goal-directed design, personas
- **Test-Driven Development** (Kent Beck) - Validation-first methodology
- **Clean Architecture** (Robert Martin) - Separation of concerns

---

## References

- [System Invariants](system-invariants.md) - All 43 invariants explained
- [Confidence Rubric](templates/confidence-rubric.md) - Scoring methodology

---

*Design Ops: Where human intent compiles to executable specifications.*

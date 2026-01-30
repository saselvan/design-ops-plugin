# Design Ops v3.0

The production gold standard for AI-assisted system design. Transforms human intent into validated, executable specifications and PRPs through automated invariant enforcement.

**Version**: 3.0 (Agent-Driven) | **Status**: Production | **License**: MIT

---

## 🚀 RALPH Pipeline - Spec to Production in Minutes

**Want to go from a validated spec to production-ready code automatically?**

👉 **[ralph.md](ralph.md)** - Complete RALPH documentation

```bash
# Install
git clone https://github.com/saselvan/design-ops-plugin ~/.claude/design-ops
cd ~/.claude/design-ops
chmod +x enforcement/*.sh enforcement/lib/*.sh

# In Claude Code
"Run RALPH on specs/feature.md"

# Result: Production-ready code in 12 automated gates
# Time: 30-45 minutes with full automation
```

**What RALPH Does:**
- ✅ Generates 30-40 unit tests from your spec
- ✅ Implements code using **progressive integration** (ONE test at a time)
- ✅ Catches regressions immediately (not at the end)
- ✅ Automated validation loops (Edit→Commit→Log→Re-check)
- ✅ Playwright MCP browser verification for UI tests
- ✅ Full audit trail (every edit logged + committed)
- ✅ Parallel sub-agents for independent checks
- ✅ **FULLY AUTOMATED** - no manual steps required

**12 Gates:** STRESS_TEST → VALIDATE → GENERATE_PRP → CHECK_PRP → GENERATE_TESTS → TEST_VALIDATION → PREFLIGHT → IMPLEMENT_TDD (N sub-tasks) → PARALLEL_CHECKS → VISUAL_REGRESSION → SMOKE_TEST → AI_CODE_REVIEW

**v3.0 Changes:**
- Agent-driven orchestration (no Python scripts)
- Progressive integration (prevents integration test failures)
- Forced instruction execution (no more skipping)
- Dynamic file naming (parallel runs supported)
- State file tracking (full audit trail)

---

## Three Ways to Use Design-Ops

1. **RALPH Pipeline** (RECOMMENDED) - Automated spec-to-production
   - 📖 **[QUICKSTART-RALPH.md](QUICKSTART-RALPH.md)** - Start here!
   - 📖 [ralph.md](ralph.md) - Skill documentation
   - 📖 [enforcement/RALPH-2026-SUMMARY.md](enforcement/RALPH-2026-SUMMARY.md) - Complete reference

2. **Orchestrator** (Manual mode) - Run individual gates with retries
   - 📖 [INSTALLATION.md](INSTALLATION.md) - Installation & usage
   - 📖 [enforcement/ORCHESTRATORS.md](enforcement/ORCHESTRATORS.md) - Full documentation

3. **Skill** (Ad-hoc validation) - Use `/design` commands in Claude Code
   - See installation below

---

## Installation

### Option 1: Global Installation (Recommended)

```bash
# Clone repo
git clone https://github.com/saselvan/design-ops-plugin.git ~/.claude/design-ops
cd ~/.claude/design-ops

# Make scripts executable
chmod +x enforcement/*.sh enforcement/lib/*.sh

# Symlink RALPH skill to Claude Code
mkdir -p ~/.claude/skills
ln -s ~/.claude/design-ops/ralph.md ~/.claude/skills/ralph.md
```

**On new computer**: Same commands. Repo stays in sync via git pull.

### Option 2: Project-Specific (Git Submodule)

```bash
cd ~/projects/my-app

# Add as submodule
git submodule add https://github.com/saselvan/design-ops-plugin.git .design-ops

# Make executable
chmod +x .design-ops/enforcement/*.sh .design-ops/enforcement/lib/*.sh

# Add to .claude/settings.json
echo '{"skills": [".design-ops/ralph.md"]}' > .claude/settings.json
```

**On new computer**:
```bash
git clone <your-repo>
git submodule update --init --recursive
```

### Verify Installation

```bash
# Check scripts are executable
ls -l ~/.claude/design-ops/enforcement/*.sh
ls -l ~/.claude/design-ops/enforcement/lib/*.sh

# Check skill is linked
ls -l ~/.claude/skills/ralph.md
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

## RALPH Pipeline: Automated Spec-to-Production

**RALPH** = **R**igor **A**t **L**aunch **P**hase **H**andoff

The RALPH Pipeline is Design-Ops' **automated implementation system** that takes a validated spec through to production-ready code via 12 automated gates:

```
Validated Spec → RALPH (12 Gates) → Production-Ready Code
```

### What RALPH Does

1. **Generates tests automatically** from your PRP (30-40 unit tests)
2. **Implements code** using TDD (RED → GREEN → REFACTOR)
3. **Runs automated checks** (build, lint, integration, accessibility)
4. **Validates security** (SQL injection, XSS, CSRF scanning)
5. **Tests performance** (Lighthouse audit, bundle size)
6. **Verifies visuals** (screenshot regression testing)
7. **Runs E2E tests** (smoke tests for critical paths)
8. **AI code review** (LLM-based quality audit)

### The 12 Gates

| Gate | What It Validates | Output |
|------|-------------------|--------|
| **1. STRESS_TEST** | Spec completeness | Validated spec |
| **2. VALIDATE + SECURITY_SCAN** | 43 invariants + security | Secure spec |
| **3. GENERATE_PRP** | Extract requirements | PRP file |
| **4. CHECK_PRP** | PRP structure | Validated PRP |
| **5. GENERATE_TESTS** | Test generation | Test suite |
| **5.5. TEST_VALIDATION** | Test quality | Quality tests |
| **5.75. PREFLIGHT** | Environment ready | Ready environment |
| **6. IMPLEMENT_TDD** | Code to pass tests | Working code |
| **6.5. PARALLEL_CHECKS** | Build/Lint/Integration/A11y | Quality code |
| **6.9. VISUAL_REGRESSION** | Screenshot testing | UI validated |
| **7. SMOKE_TEST** | E2E critical paths | Tested system |
| **8. AI_CODE_REVIEW** | Security/quality/performance | Production ready |

### How It Works

```bash
# 1. Generate all tasks from your spec
python ~/.claude/design-ops/enforcement/ralph-orchestrator.py specs/feature.md

# 2. In Claude Code, load and execute
# "Load the RALPH tasks and create them"

# 3. Monitor progress
/tasks

# Result: Production-ready code with full audit trail
```

Each gate is **stateless** (sees only latest committed files + last errors) and follows an **ASSESS → FIX → COMMIT → VALIDATE** loop until it passes.

Tasks auto-execute as dependencies complete. No manual intervention required.

**See [ralph.md](ralph.md) for complete documentation.**

---

## v2.2 Current: Production Gold Standard

Design Ops v2.2 (January 2026) is the definitive specification system for AI-assisted development:

| Core Capability | Benefit |
|-----------------|---------|
| **43 Invariant Validation** | Catches ambiguity, incompleteness, and design errors before code |
| **11-Step Validated Pipeline** | Stress-test → Validate → Generate → Check → Implement → Test → Deploy |
| **PRP Compilation** | Transforms specs into AI-executable Product Requirements Prompts |
| **Confidence Scoring** | Quantitative risk assessment (1-10) gates implementation |
| **Multi-Domain Support** | Universal + 6 domain-specific invariant sets |
| **Continuous Validation** | Watch-mode real-time spec health monitoring |
| **Learning Loops** | Retrospectives improve system over time |

---

## Quick Start (v2.2)

**Follow the 11-step pipeline. Skip nothing.** Each step catches different problems:

### The Pipeline (in order)

```bash
/design spec journey.md               # 0. Create spec from journey
/design stress-test specs/feature.md  # 1. Check completeness
/design validate specs/feature.md     # 2. Check clarity
/design prp specs/feature.md          # 3. Compile to PRP
/design check PRPs/feature-prp.md     # 4. Verify PRP quality
/design implement PRPs/feature-prp.md # 5. Generate tests (TDD)
/design test-validate test_*.py       # 6. Validate test suite
/design test-cohesion tests/          # 7. Check test interactions
/design ralph-check PRPs/feature-prp.md # 8. Verify PRP compliance
/design run PRPs/feature-prp.md       # 9. AI implements to spec
# 10. Retrospective (learning loop)
```

**Why this order?** Specs generate structure. Stress-test finds incompleteness. Validate finds ambiguity. All must pass before PRP generation.

See [QUICKSTART.md](enforcement/QUICKSTART.md) for the complete 5-minute guide.

---

## Why v2.2 is Production Gold Standard

**Invariant-Enforced Design**: 43 domain-aware invariants catch design issues at spec-time, before implementation. Not suggestions—hard gates.

**Validated Pipeline**: The 11-step workflow is non-negotiable. Each step enforces different constraints:
- Steps 0-2: Spec completeness and clarity
- Step 3: PRP compilation
- Step 4: Quality assurance
- Steps 5-8: Test-driven implementation prep
- Steps 9-10: AI implementation + learning

**Multi-Agent Architecture**: Spec-analyst, validator, conventions-checker, PRP-generator, and reviewer agents run in parallel, each with specific expertise.

**Confidence-Gated Implementation**: Quantitative risk assessment (1-10) prevents overconfident decisions. A 6/10 spec doesn't get built without explicit acknowledgment.

**Codebase Integration**: Automatic CONVENTIONS.md extraction ensures implementations match project patterns.

---

## Architecture (v2.2)

```
Design Ops v2.2 (Production Gold Standard)
├── Core Skill
│   └── design.md                    # Main Claude Code skill
│
├── Validation Engine (43 Invariants)
│   ├── validator.sh                 # Enforcement runner
│   ├── system-invariants.md         # Universal (1-11)
│   └── domains/                     # Domain-specific
│       ├── consumer-product.md      # 12-15
│       ├── physical-construction.md # 16-21
│       ├── data-architecture.md     # 22-26
│       ├── integration.md           # 27-30
│       ├── remote-management.md     # 31-36
│       └── skill-gap-transcendence.md # 37-43
│
├── 11-Step Pipeline
│   ├── design-ops-v3.sh             # Main orchestrator
│   ├── stress-test                  # Completeness check
│   ├── validate                     # Clarity check
│   ├── generate (prp)               # PRP compilation
│   ├── check                        # Quality assurance
│   ├── implement                    # TDD test generation
│   ├── test-validate                # Test suite validation
│   ├── test-cohesion                # Test interaction check
│   ├── ralph-check                  # PRP compliance
│   ├── run                          # AI implementation
│   └── retrospective                # Learning loop
│
├── PRP Generation & Checking
│   ├── spec-to-prp.sh
│   ├── prp-checker.sh
│   ├── confidence-calculator.sh
│   └── templates/
│
├── Pattern Extraction
│   ├── conventions-generator.sh
│   └── CONVENTIONS.md templates
│
├── Continuous Validation
│   ├── watch-mode.sh                # Real-time monitoring
│   ├── continuous-validator.sh      # Background service
│   └── validation-dashboard.sh      # Health status UI
│
├── Testing & CI/CD
│   ├── test-suite/
│   ├── test-integration/
│   └── .github/workflows/
│
└── Documentation
    ├── README.md (v2.2 overview)
    ├── SKILL.md (command reference)
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

## Version Timeline

**v2.2** (2026-01-26) — Production Gold Standard
- Finalized 11-step validated pipeline
- Multi-agent parallel architecture (spec-analyst, validator, CONVENTIONS-checker, prp-generator, reviewer)
- Confidence-gated implementation gates
- Continuous validation (watch-mode + dashboard)
- Complete retrospective learning system

**v2.0** (2026-01-20) — AI-Execution Optimization
- 43-invariant validation system
- PRP generation + quality checking
- Confidence scoring framework
- Implementation review workflow

**v1.0** (Original) — Foundation
- Research → Journeys → Specs → Implementation
- Manual handoff to implementation
- Retrospective learning loops

*v2.2 supersedes all prior versions. Do not use v1.0 or v2.0.*

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

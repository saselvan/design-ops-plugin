---
name: design
description: "Design Ops v3. Journey → PRP → Issues → TDD. Tiered pipeline with invariant enforcement, devil's advocate, and e2e testing. USE WHEN design, PRP, validate, requirements, init project, review implementation."
---

# Design Ops v3

Transform intent into executable PRPs with built-in adversarial review and integration testing.

## The Pipeline

Three tiers. Pick the one that matches your task.

```
SMALL (< 1 file, obvious scope, clear pattern):
  → Just implement with tests. No PRP needed.

MEDIUM (multi-file, < 1 day, known domain):
  → /design prp {journey-or-description}
  → /design implement {prp}
  → /design run {prp}

LARGE (multi-day, architectural impact, high risk, new domain):
  → /design discover {journey}        ← Interactive exploration + grill-me
  → /design prp {journey}             ← Generate PRP with invariant validation
  → /design verify {prp}              ← Single quality + compliance gate
  → /design implement {prp}           ← Generate tests (TDD, vertical slices)
  → /design run {prp}                 ← AI implements per slice
  → /design retro                     ← Only if something surprised you
```

## Tier Selection Guide

| Signal | Tier |
|--------|------|
| "Add a field to this form" | SMALL |
| "Build the fabric import page" | MEDIUM |
| "Design the data pipeline for PHI de-identification" | LARGE |
| Confidence score < 5 | LARGE (regardless of size) |
| New domain or tech stack | LARGE |
| Multiple teams or stakeholders | LARGE |

**When in doubt, start MEDIUM.** You can escalate to LARGE if you hit uncertainty during PRP generation.

## Command Reference

### /design discover {journey-or-description}

Interactive exploration before PRP generation. Use for LARGE tier only.

**What happens:**
1. Read the journey/problem statement
2. Explore the codebase for relevant patterns and conventions
3. Run `/grill-me` — devil's advocate walks the decision tree with you, challenges assumptions, offers counterarguments
4. Resolve each branch of the decision tree interactively
5. Document decisions for PRP generation

**Output:** Shared understanding ready for PRP compilation. No artifact — the conversation IS the artifact.

**When to skip:** When you already know the approach and just need to formalize it.

---

### /design prp {input} [--domain domain] [--tier medium|large]

Generate a PRP from a journey, problem statement, or conversation context.

**Input:** Journey file, description, or "from conversation" (uses discover context).

**What happens:**
1. **Detect domain** → load universal invariants (1-10) + domain-specific invariants
2. **Explore codebase** → detect patterns, conventions, tech stack
3. **Generate PRP** using domain-aware template (see PRP Template below)
4. **Validate invariants** on the generated PRP (built-in, not a separate step)
5. **Score confidence** (1-10 scale, 5 weighted factors)
6. **Red-team review** (LARGE tier only) — 7 adversarial questions:
   - What failure paths are missing?
   - What assumptions are hidden?
   - What edge cases aren't covered?
   - What's the build order dependency?
   - Where could integration break?
   - What's over-engineered?
   - What would a user actually do differently?

**Output:** PRP markdown file with confidence score, vertical slices, and validation commands.

**Invariant violations:** BLOCKING for universal invariants 1-10. ADVISORY for domain invariants (warn, don't reject) unless healthcare/compliance domain where all invariants are blocking.

---

### /design verify {prp}

Single quality gate. Replaces the old check + test-validate + test-cohesion + ralph-check.

**What it checks (one pass):**
- No unfilled placeholders
- All success criteria have validation commands
- Confidence score is calculated and appropriate
- Vertical slices cover all success criteria
- Domain invariants addressed (blocking or acknowledged)
- E2E smoke test defined

**Output:** PASS or BLOCKED with specific issues.

---

### /design implement {prp}

Generate test suite from PRP. TDD mode — tests are the contract.

**What happens:**
1. **Codebase pre-scan** → detect route groups, auth patterns, data fetching, UI library
2. **For each vertical slice** in the PRP:
   - Generate unit tests for the slice's acceptance criteria
   - Generate integration test that verifies the slice works with previous slices
3. **Generate e2e smoke test** that runs the full user workflow
4. **Validate test suite** — syntax, coverage, no duplicates (built-in, not a separate step)

**Testing pyramid per slice:**
```
Unit tests       → Does this slice's logic work?
Integration test → Does this slice work with previous slices?
Contract test    → Does the output match the defined interface?
E2E smoke test   → Does the full workflow still work? (shared across all slices)
```

**Output:** Test files + coverage matrix + e2e smoke test.

**Key rule (from Kent Beck):** Implement tests ONE SLICE AT A TIME, not all at once. Red-green-refactor per slice. Don't generate 30 tests and implement everything — that's test-first, not TDD.

---

### /design run {prp}

AI implements code to pass the test suite, one vertical slice at a time.

**Per-slice loop:**
```
1. Run the slice's failing tests (RED)
2. Write minimal code to pass (GREEN)
3. Run integration test for this + all previous slices
4. Run e2e smoke test
5. Refactor if needed
6. Move to next slice
```

**Implementation invariants (Claude Code specific):**
- API contract changes → test ALL consumers
- No claiming "done" without verification evidence
- No ad-hoc changes outside the pipeline for LARGE tier
- Maintain dependency awareness (API → consumer map)

---

### /design retro

Extract learnings after implementation. Only run when something surprised you.

**What to capture:**
- What invariant would have caught this earlier?
- What was the gap between the PRP and reality?
- Should the confidence rubric be updated?

**Rule:** New invariants come from pain, not theory. If a retro proposes an invariant, it must cite the specific failure it would have prevented.

---

### /design init {project-name} [--domain domain]

Bootstrap project structure.

```
{project-name}/
├── docs/design/
│   ├── journeys/
│   ├── PRPs/
│   └── deltas/
├── CONVENTIONS.md
└── .designops (domain config)
```

---

## Confidence Scoring

Quantitative risk assessment. 5 weighted factors:

| Factor | Weight | What it measures |
|--------|--------|-----------------|
| Requirement Clarity | 30% | Are requirements unambiguous and testable? |
| Pattern Availability | 25% | Do proven patterns exist for this? |
| Test Coverage Plan | 20% | How well-defined is validation? |
| Edge Case Handling | 15% | Are failure modes identified? |
| Tech Familiarity | 10% | How well do you know the tech? |

**Score → Action:**
- 1-3 (Red): STOP. Address gaps. Escalate to LARGE tier.
- 4-6 (Yellow): PROCEED with explicit risk acknowledgment.
- 7-9 (Green): PROCEED normally.
- 10 (Perfect): Suspicious. Verify nothing was missed.

---

## Invariant Enforcement

### Universal Invariants (always enforced, blocking)

| # | Invariant | Key test |
|---|-----------|----------|
| 1 | Ambiguity is Invalid | No "properly", "easily" without definition |
| 2 | State Must Be Explicit | Every verb has before→action→after |
| 3 | Emotional Intent Must Compile | "Feel X" becomes ":= concrete mechanism" |
| 4 | No Irreversible Without Recovery | Destructive verbs have undo/backup |
| 5 | Execution Must Fail Loudly | No "gracefully" or "silently" |
| 6 | Scope Must Be Bounded | No "all" without limits |
| 7 | Validation Must Be Executable | Metrics + thresholds, not "looks good" |
| 8 | Cost Boundaries Must Be Explicit | Limits on API/storage/money |
| 9 | Blast Radius Must Be Declared | Write ops declare affected scope |
| 10 | Degradation Path Must Exist | External deps have fallbacks |

### Domain Invariants (loaded per project, advisory by default)

| Domain | When to load |
|--------|-------------|
| consumer-product | Mobile/web apps, consumer-facing |
| data-architecture | Pipelines, warehouses, analytics |
| healthcare-ai | PHI, clinical data, compliance-critical |
| hls-solution-accelerator | Databricks HLS solutions |
| integration | APIs, webhooks, third-party services |
| physical-construction | Buildings, infrastructure |
| remote-management | Projects managed from distance |
| security | Security-critical systems |
| skill-gap-transcendence | New tech, learning-intensive |

**Healthcare and security domains are BLOCKING, not advisory.** Compliance violations are rejection criteria.

### Code-Level Invariants (during implementation)

| ID | Rule |
|----|------|
| TYPE-001 | Single canonical location for database/domain types |
| TYPE-002 | TypeScript interfaces must match DB schema nullability |
| TYPE-003 | No `as any` for known tables |
| FRAME-001 | Use correct framework version patterns |
| INV-IMPL-001 | API contract changes → test all consumers |
| INV-IMPL-002 | Verification evidence required (snapshots, not claims) |

---

## Integration Testing Strategy

**The core problem this solves:** Unit tests pass but the system is broken. Components work in isolation but don't integrate.

### Testing Pyramid Per Vertical Slice

```
After Slice 1:
  → Unit tests for slice 1
  → E2E smoke test

After Slice 2:
  → Unit tests for slice 2
  → Integration test: slices 1+2 together
  → E2E smoke test (regression)

After Slice N:
  → Unit tests for slice N
  → Integration test: all slices together
  → E2E smoke test (regression)
```

### Contract Testing

Every module consumed by another module defines its contract:
- Input types and constraints
- Output types and guarantees
- Breaking change rules

Integration tests verify contracts are maintained across slice boundaries.

### E2E Smoke Test

One test that runs the ENTIRE user workflow. If this passes, the system works. If it fails, something is broken. Run after every slice.

---

## Key Files

```
design-ops/
├── SKILL.md                    # This file (v3 command reference)
├── system-invariants.md        # Universal invariants 1-10
├── domains/                    # Domain-specific invariants
├── templates/
│   ├── prp-template.md         # Domain-aware PRP template
│   ├── confidence-rubric.md    # Scoring guidelines
│   └── prp-examples/           # Filled examples
└── _archive/                   # v2.x files (preserved, not loaded)
```

---

**Version**: 3.0
**Predecessor**: v2.5 (11-step pipeline → 3-tier pipeline)
**Last updated**: 2026-03-22

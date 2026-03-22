---
name: design
description: "Design Ops v3. Journey → PRP → Issues → TDD. Tiered pipeline with invariant enforcement, devil's advocate, and e2e testing. USE WHEN design, PRP, validate, requirements, init project, review implementation."
version: "3.0"
---

# Design Ops v3

Journey → PRP → Issues → TDD. Three tiers, not eleven steps.

See `~/.claude/design-ops/SKILL.md` for full command reference and pipeline details.

---

## Quick Reference

```
SMALL (< 1 file, obvious scope):
  → Just implement with tests.

MEDIUM (multi-file, < 1 day):
  → /design prp {journey}        Generate PRP (validation built in)
  → /design implement {prp}      Generate tests (TDD, vertical slices)
  → /design run {prp}            AI implements per slice

LARGE (multi-day, high risk, new domain):
  → /design discover {journey}   Explore + grill-me (devil's advocate)
  → /design prp {journey}        Generate PRP + red-team review
  → /design verify {prp}         Single quality gate
  → /design implement {prp}      Tests per vertical slice
  → /design run {prp}            AI implements per slice
  → /design retro                Only if something surprised you
```

---

## When to Use Each Tier

| Signal | Tier |
|--------|------|
| Bug fix, add a field, simple UI change | SMALL — just do it with tests |
| New page, new feature, multi-file change | MEDIUM — PRP keeps you honest |
| New architecture, compliance-critical, unknown domain | LARGE — explore first |
| Confidence score < 5 | Escalate to LARGE |

---

## Two Agents (Not Six)

| Agent | What it does | When it runs |
|-------|-------------|-------------|
| **validator** | Checks PRP against universal invariants (1-10) + domain invariants. Flags violations as BLOCKING (universal, healthcare, security) or ADVISORY (other domains). | During `/design prp` |
| **red-team** | Devil's advocate. 7 adversarial questions: missing failure paths, hidden assumptions, edge cases, build order deps, integration risks, over-engineering, UX gaps. BLOCKING findings halt the pipeline. | During `/design prp` (LARGE tier only) |

The old spec-analyst, CONVENTIONS-checker, reviewer, prp-generator, and ralph-checker are consolidated. Codebase pattern detection happens during `/design prp` and `/design implement` — it doesn't need a named agent.

---

## PRP Structure (6 Core Sections)

Every PRP has these sections. Domain extensions are added based on the project.

1. **Meta + Confidence Score** — risk quantification (1-10)
2. **Problem & Solution** — what's broken, what we're building, scope
3. **Success Criteria** — pseudo-code conditions (SUCCESS := ALL(...))
4. **Vertical Slices** — thin end-to-end paths with acceptance criteria and validation gates
5. **Risks & Fallbacks** — circuit breakers, degradation paths
6. **Validation Commands** — per-slice, integration, e2e smoke test, build/quality

Domain extensions (appended when relevant):
- **Healthcare/HLS**: Compliance, PHI handling, data governance
- **Data Architecture**: Pipeline contracts, data quality gates, lineage
- **Consumer Product**: Accessibility (WCAG 2.1 AA), performance budgets
- **Integration**: API contracts, retry/circuit breaker patterns
- **Physical Construction**: Material specs, inspection gates

Template: `~/.claude/design-ops/templates/prp-template.md`

---

## Integration Testing (The Gap v2 Missed)

**Problem:** Unit tests pass but the system is broken. Components work in isolation but don't integrate.

**Solution:** Testing pyramid per vertical slice:

```
After each slice:
  1. Unit tests      → Does this slice's logic work?
  2. Contract test   → Does output match the defined interface?
  3. Integration test → Does this slice work WITH previous slices?
  4. E2E smoke test  → Does the full user workflow still work?

ALL FOUR must pass before the slice is complete.
```

During `/design run`, the AI implements ONE SLICE AT A TIME:
```
RED:    Run slice's failing tests
GREEN:  Write minimal code to pass
VERIFY: Run integration test (this slice + all previous)
VERIFY: Run e2e smoke test
REFACTOR: Clean up if needed
NEXT:   Move to next slice
```

---

## Invariants

### Universal (1-10) — Always blocking

1. Ambiguity is Invalid — terms need operational definitions
2. State Must Be Explicit — before→action→after
3. Emotional Intent Must Compile — "feel X" := concrete mechanism
4. No Irreversible Without Recovery — destructive actions need escape hatch
5. Execution Must Fail Loudly — no silent failures
6. Scope Must Be Bounded — no unbounded operations
7. Validation Must Be Executable — measurable criteria only
8. Cost Boundaries Explicit — limits on resources
9. Blast Radius Declared — write ops state what they affect
10. Degradation Path Exists — external deps have fallbacks

Full definitions: `~/.claude/design-ops/system-invariants.md`

### Domain Invariants — Advisory (except healthcare/security which are blocking)

Loaded per project from `~/.claude/design-ops/domains/`. See domain selection guide in SKILL.md.

### Code-Level Invariants — During implementation

- TYPE-001: Single type source (one canonical location per interface)
- TYPE-002: Schema-type parity (TS matches DB nullability)
- TYPE-003: No `as any` for known tables
- FRAME-001: Framework version awareness
- INV-IMPL-001: API changes → test all consumers
- INV-IMPL-002: Verification evidence required (snapshots, not claims)

---

## Component Contracts

When a module is consumed by another module, define its contract:
- Input types and constraints
- Output types and guarantees
- List of consumers
- Breaking change rules

Integration tests verify contracts across slice boundaries. This prevents the class of bug where "all tests pass but the system is broken."

---

## Confidence Scoring

| Factor | Weight |
|--------|--------|
| Requirement Clarity | 30% |
| Pattern Availability | 25% |
| Test Coverage Plan | 20% |
| Edge Case Handling | 15% |
| Tech Familiarity | 10% |

Score 1-3 (Red) → STOP, fix gaps, use LARGE tier.
Score 4-6 (Yellow) → PROCEED with risk acknowledgment.
Score 7-9 (Green) → PROCEED normally.

Rubric: `~/.claude/design-ops/templates/confidence-rubric.md`

---

## What Changed from v2

| v2 (11-step pipeline) | v3 (3-tier pipeline) |
|---|---|
| Spec required before PRP | Specs eliminated — journey → PRP directly |
| 5 validation steps | 1 validation step (built into PRP generation) |
| 6 named agents | 2 agents (validator + red-team) |
| 11-section PRP template | 6-section PRP + domain extensions |
| No fast path | 3 tiers: small/medium/large |
| Component tests only | Testing pyramid: unit → contract → integration → e2e |
| Stress-test + validate separate | Merged into PRP generation |
| test-validate + test-cohesion + ralph-check separate | Merged into single verify step |
| Freshness check (monthly) | Removed — update when something breaks |
| Enforcement bash scripts | Removed — invariants enforced by the AI during PRP generation |

---

**Version**: 3.0
**Last updated**: 2026-03-22

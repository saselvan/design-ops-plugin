---
name: design
description: "Design Ops v3.2. Journey → PRP → Issues → TDD. Tiered pipeline with invariant enforcement, devil's advocate, e2e testing, and blackboard-powered parallel builds. USE WHEN design, PRP, validate, requirements, init project, review implementation."
version: "3.2"
---

# Design Ops v3.2

Journey → PRP → Issues → TDD. Three tiers. PRP defines WHAT. Issues define HOW.

See `~/.claude/design-ops/SKILL.md` for full command reference.

---

## IMPORTANT: Tier Proposal

At the start of ANY coding task, you MUST propose a tier and wait for confirmation:

> "This looks like a **MEDIUM** task — want me to generate a PRP, or just implement with tests?"

Do not skip this. Do not default to SMALL to avoid overhead. Do not nag about PRPs for genuinely small work.

---

## Quick Reference

```
SMALL (< 1 file, obvious scope):
  → Just implement with tests.

MEDIUM (multi-file, < 1 day):
  → /design prp {journey}        Generate PRP + red-team + auto-validate
  → /prp-to-issues {prp}         Interactive vertical slicing → GitHub issues
  → /design build                 TDD per issue (red-green-refactor)

LARGE (multi-day, high risk, new domain):
  → /design discover {journey}   Explore + grill-me → decisions log FILE
  → /design prp {journey}        Generate PRP + red-team + auto-validate
  → /prp-to-issues {prp}         Interactive vertical slicing → GitHub issues
  → /design build                 TDD per issue (red-green-refactor)
  → /design retro                Only if something surprised you
```

---

## Key Design Principles

### PRP = WHAT. Issues = HOW.

The PRP defines scope, success criteria, dependencies, and risks. It does NOT contain vertical slices. Vertical slicing happens in `/prp-to-issues` through an interactive quiz. `/design build` implements per issue, not per PRP section.

### Red-team runs for MEDIUM and LARGE

Every PRP gets 7 adversarial questions. No PRP ships without challenge.

### Auto-validation

`validate-prp.sh` runs automatically after every `/design prp`. No separate `/design verify` step needed.

### Hard gate on Red confidence

Confidence score < 4 (Red) = HARD STOP. Cannot proceed without explicit human override ("proceed with risk"). Claude cannot bypass this.

### True TDD per issue

`/design build` does red-green-refactor ONE ISSUE AT A TIME. No "generate all tests then implement everything." Each issue's implementation informs the next issue's tests.

### Progress-based circuit breaker

During `/design build`, if 2 consecutive attempts produce identical failures → STOP and diagnose whether the problem is in the code, the issue, or the PRP. Hard max: 5 attempts.

### Completion summary

`/design build` ends with a summary listing which success criteria are proven by tests vs. which require production observation. Clear definition of "done."

---

## Two Agents

| Agent | What it does | When |
|-------|-------------|------|
| **validator** | Invariant enforcement (universal blocking, domain advisory/blocking) | During `/design prp` |
| **red-team** | 7 adversarial questions. Blocking findings halt pipeline. | During `/design prp` (MEDIUM + LARGE) |

---

## PRP Structure (6 Core Sections)

1. **Meta + Confidence Score** — domain, risk (1-10), tier
2. **Problem & Solution** — what's broken, what we're building, scope
3. **Success Criteria** — SUCCESS := ALL(...), FAILURE := ANY(...)
4. **Scope & Dependencies** — components, relationships, dependency map
5. **Risks & Fallbacks** — circuit breakers, degradation paths
6. **Validation Commands** — integration test, e2e smoke test (domain-specific), build/quality

Domain extensions appended per `.designops` config.

---

## Domain Configuration

Per-project `.designops` file. Auto-loaded by `/design prp`.

```yaml
domains:
  - healthcare-ai
  - data-architecture
e2e:
  tool: pytest
  time_budget: 300s
  run_frequency: every_slice
parallel:
  enabled: true
  max_parallel_issues: 3
```

Healthcare and security domains enforce ALL invariants as BLOCKING.

---

## E2E Smoke Test (Domain-Specific)

| Domain | Tool | Time budget |
|--------|------|-------------|
| consumer-product | Playwright | 30-120s |
| data-architecture | pytest / notebook | 60-300s |
| healthcare-ai | pytest + audit | 120-600s |
| integration | pytest / curl | 15-60s |
| physical-construction | manual checklist | N/A |

If e2e exceeds time budget → run every 2-3 issues, always at final completion.

---

## Integration Testing

Testing pyramid per issue during `/design build`:

```
1. Unit tests       → Does this issue's logic work?
2. Contract test    → Does output match the defined interface?
3. Integration test → Does this work WITH previous issues?
4. E2E smoke test   → Does the full workflow still work?
```

All four must pass before moving to the next issue.

---

## Invariants

### Universal (1-10) — Always blocking

1. Ambiguity is Invalid
2. State Must Be Explicit
3. Emotional Intent Must Compile
4. No Irreversible Without Recovery
5. Execution Must Fail Loudly
6. Scope Must Be Bounded
7. Validation Must Be Executable
8. Cost Boundaries Explicit
9. Blast Radius Declared
10. Degradation Path Exists

Full definitions: `~/.claude/design-ops/system-invariants.md`

### Domain — Advisory (healthcare/security = blocking)

Loaded from `~/.claude/design-ops/domains/` per `.designops` config.

### Code-Level — During `/design build`

- TYPE-001: Single type source
- TYPE-002: Schema-type parity
- TYPE-003: No `as any` for known tables
- FRAME-001: Framework version awareness
- INV-IMPL-001: API changes → test all consumers
- INV-IMPL-002: Verification evidence required

---

## Component Contracts

Modules consumed by other modules define: input types, output guarantees, consumer list, breaking change rules. Integration tests verify contracts across issue boundaries.

---

## `/design discover` Output

Writes a decisions log to `docs/design/discoveries/{feature}.md`. Not conversation-only — file survives context compression. `/design prp` reads this file as input.

---

## Blackboard Integration

Design-ops is the **workflow brain**. `/blackboard` is the **dumb parallelizer**.

| Where | Trigger | What happens |
|-------|---------|-------------|
| `/design discover` | Key module boundary | Parallel interface exploration (4 design constraints) |
| `/design prp` (LARGE) | Always | Validator + red-team run in parallel |
| `/design build` | 2+ independent issues | Parallel TDD with worktree isolation, merge + integration test |

All parallel work uses Claude Code native `isolation: worktree`. See `/blackboard` skill v2.0 for full protocol.

---

**Version**: 3.2
**Last updated**: 2026-03-23

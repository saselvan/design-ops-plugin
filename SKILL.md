---
name: design
description: "Design Ops v3.1. Journey → PRP → Issues → TDD. Tiered pipeline with invariant enforcement, devil's advocate, and e2e testing. USE WHEN design, PRP, validate, requirements, init project, review implementation."
---

# Design Ops v3.1

Transform intent into executable PRPs. Issues own the vertical slicing. TDD per issue.

## Tier Selection (AI-Proposed, Human-Confirmed)

At the start of any coding task, Claude MUST propose a tier and wait for confirmation:

> "This looks like a **MEDIUM** task — want me to generate a PRP, or just implement with tests?"

Do not skip this. Do not default to SMALL to save tokens. Propose honestly based on:

```
SMALL (< 1 file, obvious scope, clear pattern):
  → Just implement with tests. No PRP needed.
  → Do NOT nag about PRPs for small work.

MEDIUM (multi-file, < 1 day, known domain):
  → /design prp {journey}        Generate PRP + red-team review + auto-validate
  → /prp-to-issues {prp}         Interactive slicing into GitHub issues
  → /design build {issues}       TDD per issue (red-green-refactor)

LARGE (multi-day, architectural impact, high risk, new domain):
  → /design discover {journey}   Explore + grill-me → decisions log file
  → /design prp {journey}        Generate PRP + red-team + auto-validate
  → /prp-to-issues {prp}         Interactive slicing into GitHub issues
  → /design build {issues}       TDD per issue (red-green-refactor)
  → /design retro                Only if something surprised you
```

| Signal | Tier |
|--------|------|
| Bug fix, add a field, simple UI change | SMALL |
| New page, new feature, multi-file change | MEDIUM |
| New architecture, compliance-critical, unknown domain | LARGE |
| Confidence score < 5 | Escalate to LARGE |
| New domain or tech stack | LARGE |
| Multiple teams or stakeholders | LARGE |

**When in doubt, start MEDIUM.** You can escalate to LARGE if you hit uncertainty during PRP generation.

---

## Command Reference

### /design discover {journey-or-description}

Interactive exploration before PRP generation. LARGE tier only.

**What happens:**
1. Read the journey/problem statement
2. Explore the codebase for relevant patterns and conventions
3. Run `/grill-me` — devil's advocate walks the decision tree, challenges assumptions
4. Resolve each branch interactively
5. **Write a decisions log file** (not just conversation — survives context compression)

**Output:** Decisions log file at `docs/design/discoveries/{feature-name}.md`:

```markdown
# Discovery: {Feature Name}
Date: {date}

## Decisions
1. {Decision 1} — {rationale}
2. {Decision 2} — {rationale}

## Open Questions
- {Unresolved question}

## Confidence Concerns
- {Factor}: {concern} (estimated score: {X}/10)

## Codebase Patterns Found
- {Pattern 1}: {where found, how to reuse}
```

**When to skip:** When you already know the approach and just need to formalize it.

---

### /design prp {input} [--domain domain] [--tier medium|large]

Generate a PRP from a journey, problem statement, or discovery decisions log.

**Input:** Journey file, description, discovery log, or "from conversation."

**Domain detection:**
1. Check for `.designops` file in project root → use declared domain(s)
2. Fall back to `--domain` flag if specified
3. Fall back to universal-only if neither exists

**What happens:**
1. **Load domain** from `.designops` config or `--domain` flag
2. **Explore codebase** → detect patterns, conventions, tech stack
3. **Generate PRP** using domain-aware template (6 core sections + domain extensions)
4. **Validate invariants** on the generated PRP (built-in)
5. **Score confidence** (1-10 scale, 5 weighted factors)
6. **Red-team review** (MEDIUM and LARGE) — 7 adversarial questions:
   - What failure paths are missing?
   - What assumptions are hidden?
   - What edge cases aren't covered?
   - What are the component dependencies?
   - Where could integration break?
   - What's over-engineered?
   - What would a user actually do differently?
7. **Auto-validate** — run `validate-prp.sh` on the generated file

**Output:** PRP markdown file with confidence score and validation results.

**Hard gate:** If confidence score is RED (< 4), the pipeline STOPS. You must explicitly type "proceed with risk" or fix the gaps. Claude cannot override this.

**Invariant violations:** BLOCKING for universal invariants 1-10. ADVISORY for domain invariants (warn, don't reject) unless healthcare/security domain where ALL invariants are blocking.

---

### /prp-to-issues {prp}

**This is where vertical slicing happens.** The PRP defines WHAT (scope, success criteria, dependencies). Issues define HOW (vertical slices, build order).

See the `prp-to-issues` skill for full details. Key points:
- Interactive quiz loop to refine slices with the user
- Each slice is a thin end-to-end tracer bullet (schema → API → UI → tests)
- HITL vs AFK classification
- Dependency ordering
- Issues link back to PRP success criteria

---

### /design build {issues-or-prp}

True TDD per issue. Replaces the old `/design implement` + `/design run` split.

**Per-issue loop (in dependency order):**
```
1. Read issue's acceptance criteria
2. Write failing tests for THIS issue only          (RED)
3. Write minimal code to pass                        (GREEN)
4. Run integration test (this + all previous issues)
5. Run e2e smoke test (if within domain time budget)
6. Refactor if needed
7. Commit
8. Next issue
```

**Progress-based circuit breaker:**
```
After each fix attempt:
  - Did failing test count decrease?    → PROGRESS, continue
  - Did error messages change?          → PROGRESS, continue
  - Same failures, same errors?         → STUCK

STUCK after 2 identical failures → escalate immediately with:
  - What failed
  - What was tried
  - Diagnosis: code problem / issue problem / PRP problem
  - Recommended fix at the right level

Hard max: 5 attempts per issue regardless of progress
```

**Testing pyramid per issue:**
```
Unit tests       → Does this issue's logic work?
Contract test    → Does output match the defined interface?
Integration test → Does this issue work WITH previous issues?
E2E smoke test   → Does the full workflow still work?
```

**Implementation invariants (Claude Code specific):**
- API contract changes → test ALL consumers (INV-IMPL-001)
- Verification evidence required — snapshots, not claims (INV-IMPL-002)
- No ad-hoc changes outside the pipeline for LARGE tier
- Maintain dependency awareness (API → consumer map)

**Completion summary:** When all issues pass, output:

```markdown
## Build Complete: {Feature Name}

### Proven by tests
- {Success criterion 1} ✓ (verified by: {test name})
- {Success criterion 2} ✓ (verified by: {test name})

### Requires production observation
- {Success criterion 3} — monitor: {metric, dashboard, or method}
- {Success criterion 4} — verify after: {timeframe}

### Open risks
- {Risk from PRP that wasn't fully mitigated}

### Issues completed
- #{issue1}: {title} ✓
- #{issue2}: {title} ✓
```

---

### /design retro

Extract learnings after implementation. **Only run when something surprised you.**

**What to capture:**
- What invariant would have caught this earlier?
- What was the gap between the PRP and reality?
- Should the confidence rubric be updated?

**Rule:** New invariants come from pain, not theory. Must cite the specific failure it would have prevented.

---

### /design init {project-name} [--domain domain]

Bootstrap project structure with domain config.

```
{project-name}/
├── docs/design/
│   ├── journeys/
│   ├── discoveries/        ← NEW: decisions logs from /design discover
│   ├── PRPs/
│   └── deltas/
├── .designops              ← Domain config (read by /design prp)
├── CONVENTIONS.md
└── README.md
```

**.designops file format:**
```yaml
domains:
  - consumer-product
e2e:
  tool: playwright
  time_budget: 120s
```

---

## Domain Configuration (.designops)

Per-project config file. Eliminates per-command `--domain` flags.

```yaml
# .designops
domains:
  - healthcare-ai
  - data-architecture
e2e:
  tool: pytest           # playwright | pytest | notebook | manual
  time_budget: 300s      # max time for e2e smoke test
  run_frequency: every_slice  # every_slice | every_2_slices | at_gates
```

**Domain auto-loading:** `/design prp` reads this file automatically. The `--domain` flag overrides it.

---

## E2E Smoke Test (Domain-Specific)

E2E means different things per domain. Define in `.designops` and in the PRP's domain extension.

| Domain | E2E tool | What it verifies | Typical time |
|--------|----------|-----------------|-------------|
| consumer-product | Playwright | Browser click-through of critical user path | 30-120s |
| data-architecture | pytest / notebook | Pipeline run with test data → output schema + row counts + quality | 60-300s |
| healthcare-ai | pytest + audit check | Above + PHI absent from output + audit log populated | 120-600s |
| integration | pytest / curl | Request → response → contract match + side effects | 15-60s |
| physical-construction | manual checklist | Inspection gate completion | N/A (human) |

**Time budget rule:** If e2e exceeds the time budget, run it every 2-3 issues instead of every issue. Always run at final build completion.

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
- 1-3 (Red): **HARD STOP.** Cannot proceed without explicit human override ("proceed with risk"). Escalate to LARGE tier.
- 4-6 (Yellow): PROCEED with explicit risk acknowledgment in PRP.
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

Loaded from `.designops` config. Healthcare and security domains are **BLOCKING**.

### Code-Level Invariants (during /design build)

| ID | Rule |
|----|------|
| TYPE-001 | Single canonical location for database/domain types |
| TYPE-002 | TypeScript interfaces must match DB schema nullability |
| TYPE-003 | No `as any` for known tables |
| FRAME-001 | Use correct framework version patterns |
| INV-IMPL-001 | API contract changes → test all consumers |
| INV-IMPL-002 | Verification evidence required (snapshots, not claims) |

---

## Two Agents

| Agent | What it does | When it runs |
|-------|-------------|-------------|
| **validator** | Checks PRP against universal invariants (1-10) + domain invariants. BLOCKING or ADVISORY per domain. | During `/design prp` |
| **red-team** | Devil's advocate. 7 adversarial questions. BLOCKING findings halt the pipeline. | During `/design prp` (MEDIUM and LARGE) |

---

## PRP Structure (6 Core Sections)

The PRP defines **WHAT** must be true. Issues define **HOW** to get there.

1. **Meta + Confidence Score** — domain, risk quantification (1-10), tier
2. **Problem & Solution** — what's broken, what we're building, scope
3. **Success Criteria** — pseudo-code conditions (SUCCESS := ALL(...), FAILURE := ANY(...))
4. **Scope & Dependencies** — components, their relationships, what depends on what
5. **Risks & Fallbacks** — circuit breakers, degradation paths
6. **Validation Commands** — integration, e2e smoke test (domain-specific), build/quality

Domain extensions appended when relevant. Template: `~/.claude/design-ops/templates/prp-template.md`

---

## Key Files

```
design-ops/
├── SKILL.md                    # This file (v3.1 command reference)
├── design.md                   # Skill loaded into context
├── system-invariants.md        # Universal invariants 1-10
├── validate-prp.sh             # Auto-validator (runs after /design prp)
├── domains/                    # Domain-specific invariants
├── templates/
│   ├── prp-template.md         # Domain-aware PRP template
│   ├── confidence-rubric.md    # Scoring guidelines
│   └── prp-examples/           # Filled examples
└── _archive/                   # v2.x files (preserved, not loaded)
```

---

**Version**: 3.1
**Predecessor**: v3.0 (refined by grill-me session)
**Last updated**: 2026-03-22

# Design Ops v3.1 - Simplified Pipeline

## Philosophy Change

**v2 (over-engineered):**
- LLM validates → LLM fixes → loop until 95% → repeat
- Circular reasoning: LLM agreeing with itself
- 14 files, 3700 lines, fragile JSON parsing

**v3 (simplified):**
- Deterministic checks first (fast, free, reliable)
- LLM provides suggestions (advisory only)
- Human decides and fixes
- 1 file, ~600 lines, robust Python JSON parsing

## The Workflow (Correct Order)

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: Write Spec (You + Claude)                              │
│  Together: Define problem, success criteria, scope              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: Stress Test (RUN FIRST)                                │
│  Question: "Is this spec COMPLETE?"                             │
│  - Does it cover all requirements?                              │
│  - Does it handle error cases?                                  │
│  - Does it address failure modes?                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: Validate                                               │
│  Question: "Is this spec CLEAR?"                                │
│  - Has required sections?                                       │
│  - No vague terms?                                              │
│  - Unambiguous?                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: Generate PRP (one-shot)                                │
│  Create agent-executable PRP from validated spec                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 5: Human Review                                           │
│  You approve before implementation                              │
└─────────────────────────────────────────────────────────────────┘
```

**Why this order?**
- No point polishing (validate) a spec that's missing half the requirements
- First: Do we have all the ingredients? (stress-test)
- Then: Is the recipe written clearly? (validate)
- Finally: Cook the dish (generate)

## Architecture

```mermaid
flowchart TB
    subgraph Layer1["Layer 1: Deterministic (Fast, Free)"]
        D1[Required sections present?]
        D2[Minimum content length?]
        D3[No unfilled placeholders?]
        D4[No vague terms overload?]
    end

    subgraph Layer2["Layer 2: LLM Advisory (Optional)"]
        L1[Get suggestions]
        L2[Show to human]
        L3[Human decides]
    end

    subgraph Layer3["Layer 3: Human Review"]
        H1[Review output]
        H2[Make fixes manually]
        H3[Approve for use]
    end

    SPEC[Spec File] --> D1 --> D2 --> D3 --> D4
    D4 --> |PASS/NEEDS_WORK/FAIL| L1
    L1 --> L2 --> L3
    L3 --> H1 --> H2 --> H3
    H3 --> DONE[Ready for Implementation]

    style Layer1 fill:#c8e6c9
    style Layer2 fill:#fff9c4
    style Layer3 fill:#bbdefb
```

## Usage

```bash
# 1. STRESS TEST (run first) - Is spec complete?
./design-ops-v3.sh stress-test specs/my-feature.md

# With optional requirements/journeys files
./design-ops-v3.sh stress-test specs/my-feature.md --requirements reqs.md --journeys journeys.md

# 2. VALIDATE - Is spec clear?
./design-ops-v3.sh validate specs/my-feature.md

# 3. GENERATE PRP (one-shot, no loops)
./design-ops-v3.sh generate specs/my-feature.md

# 4. CHECK PRP quality
./design-ops-v3.sh check PRPs/my-feature-prp.md

# Quick mode (skip LLM, deterministic only)
./design-ops-v3.sh stress-test specs/my-feature.md --quick
./design-ops-v3.sh validate specs/my-feature.md --quick
```

## Stress Test Output Example

```
╔═══════════════════════════════════════════════════════════════╗
║  SPEC STRESS TEST (v3.1.0) - Completeness Check               ║
╚═══════════════════════════════════════════════════════════════╝

━━━ Deterministic Coverage Checks ━━━
  ✓ Happy path mentioned
  ✓ Error cases mentioned
  ✗ Empty/null states not explicitly handled
  ✗ External failure modes not addressed (API down, timeout, offline)
  ? Concurrency not explicitly addressed (may not apply)
  ✓ Limits/boundaries mentioned

Basic Coverage: 4/6 (66%)

━━━ LLM Deep Analysis ━━━
Coverage Grade: NEEDS_WORK

Missing Requirements:
  ✗ Password reset flow not specified
  ✗ Session timeout handling not defined

Unaddressed Failure Modes:
  ? What if the database is unavailable?
  ? What if user's session expires mid-operation?

Critical Questions to Answer:
  1. What happens if the user loses network during upload?
  2. How should errors be displayed to the user?
  3. What's the retry policy for failed API calls?

═══════════════════════════════════════════════════════════════
  Final Grade: NEEDS_WORK
  Spec is incomplete. Review gaps and add missing coverage.

  Next step: ./design-ops-v3.sh validate specs/my-feature.md
═══════════════════════════════════════════════════════════════
Cost estimate: ~$0.0312 (2841 input + 1203 output tokens)
```

## Grades (Not Percentages)

| Grade | Meaning | Action |
|-------|---------|--------|
| **PASS** | Meets requirements | Proceed |
| **NEEDS_WORK** | Has suggestions | Review, then proceed |
| **FAIL** | Missing required elements | Fix before proceeding |

## Cost Tracking

Every run shows estimated cost:
```
Cost estimate: ~$0.0234 (1523 input + 892 output tokens)
```

## What's Different

| Aspect | v2 | v3 |
|--------|----|----|
| Auto-fix loops | Yes (up to 5 iterations) | No (one-shot) |
| LLM role | Authoritative | Advisory |
| JSON parsing | grep/sed (fragile) | Python (robust) |
| Threshold | 95% (false precision) | PASS/NEEDS_WORK/FAIL |
| Cost visibility | None | Every run |
| Files | 14 shell scripts | 1 shell script |
| Debugging | "LLM gave wrong score" | Clear deterministic checks |

## Migration

v2 files are preserved but deprecated. Use v3:

```bash
# Old (deprecated)
./spec-to-prp-pipeline.sh spec.md

# New (recommended)
./design-ops-v3.sh validate spec.md
./design-ops-v3.sh generate spec.md
./design-ops-v3.sh check output.md
```

## The Key Insight

> "The value is in thinking through requirements, not in automating the validation of that thinking."

v3 helps you think by:
1. Catching obvious omissions (deterministic)
2. Suggesting improvements (LLM advisory)
3. Letting you decide (human review)

It does NOT try to:
1. Score with false precision
2. Auto-fix documents
3. Loop until an arbitrary threshold
4. Replace human judgment

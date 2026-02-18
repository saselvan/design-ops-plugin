---
name: Design
description: Design Ops v2.4 gold standard. Transform intent → executable PRPs through streamlined journey-to-PRP pipeline with invariant enforcement and multi-agent architecture. Specs are optional for complex features. USE WHEN design, spec, PRP, validate, requirements, init project, review implementation.
version: "2.4"
---

# Design Ops v2.5 Skill

**PRODUCTION GOLD STANDARD FOR AI-ASSISTED SYSTEM DESIGN**

Design Ops v2.5 transforms human intent directly into executable PRPs with built-in adversarial review. Every PRP is stress-tested by a devil's advocate pass that checks for missing failure paths, hidden assumptions, ambiguous requirements, and edge cases before implementation begins. The spec layer is optional — for most features, a journey or problem statement goes straight to PRP.

## Multi-Agent Architecture

The pipeline executes 6 specialized agents in coordinated sequence:

```
                    Journey / Intent / Spec
                                │
                ┌───────────────┼───────────────┐
                ▼               ▼               ▼
        ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
        │spec-analyst │  │  validator  │  │  CONVENTIONS│
        │             │  │             │  │    check    │
        │• Complete   │  │• Invariants │  │             │
        │• Complexity │  │• Domain     │  │• Style      │
        │• Think level│  │• Confidence │  │• Patterns   │
        └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
               │                │                │
               └────────────────┼────────────────┘
                                │
                                ▼
                    ┌─────────────────────┐
                    │   prp-generator     │ ← Templates + Patterns
                    │                     │
                    │ • Structure PRP     │
                    │ • Validation cmds   │
                    │ • Thinking level    │
                    │ • Pattern links     │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │     reviewer        │ ← Quality gate
                    │                     │
                    │ • Required sections │
                    │ • No placeholders   │
                    │ • Executable cmds   │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   red-team          │ ← Devil's advocate
                    │                     │
                    │ • Failure paths     │
                    │ • Hidden assumptions│
                    │ • Edge cases        │
                    │ • Build order       │
                    │ • Over-engineering  │
                    └──────────┬──────────┘
                               │
                    ┌──────────┴──────────┐
                    ▼                     ▼
              APPROVED              BLOCKED
              (risks noted)         (must resolve)
                    │                     │
                    ▼                     └─► Fix → re-run
            ┌─────────────────────┐
            │   ralph-check       │ ← PRP compliance
            │                     │
            │ • Schema fields     │
            │ • Routes match      │
            │ • Success criteria  │
            └──────────┬──────────┘
                       │
            ┌──────────┴──────────┐
            ▼                     ▼
         COMPLIANT           VIOLATIONS
            │                     │
            ▼                     └─► Fix steps
        Implementation (run)
                    │
                    ▼
            ┌─────────────────────┐
            │   retrospective     │ ← Learning loop
            │                     │
            │ • Extract learnings │
            │ • Propose invariants│
            │ • System improve    │
            └─────────────────────┘
```

---

## Why v2.5 is Production Gold Standard

**Invariant enforcement as hard gates**: 43 invariants (11 universal + 32 domain-specific) catch design issues at spec-time, not production. The system rejects bad specs; it doesn't attempt fixes.

**Streamlined pipeline**: Journey → PRP → Implement. The spec layer is collapsed into the PRP for most features. Validation and stress-testing are built into PRP generation. Separate specs are only needed when the approach is uncertain.

**Built-in devil's advocate**: Every PRP is adversarially reviewed before implementation. 7 red team questions probe for missing failure paths, hidden assumptions, ambiguous requirements, build order dependencies, edge cases, UX gaps, and over-engineering. BLOCKING findings halt the pipeline — you fix the PRP before writing code, not after.

**Confidence-gated implementation**: Quantitative risk assessment (1-10 scale) prevents overconfident decisions. A 6/10 spec gets built WITH EXPLICIT RISK ACKNOWLEDGMENT.

**Multi-agent parallel analysis**: Spec-analyst, validator, CONVENTIONS-checker, PRP-generator, red-team reviewer, and ralph-check agents run in coordinated sequence, each with specific expertise.

**Automatic CONVENTIONS enforcement**: Extracts codebase patterns and ensures implementations match project style, not just functional requirements.

**Learning loops built in**: Retrospectives after implementation extract learnings, propose new invariants, continuously improve the system.

---

## Implementation Enforcement Invariants (Claude Code Specific)

**CRITICAL**: Claude Code is an unreliable executor. It will take shortcuts, skip verification, and claim "done" without evidence. These invariants exist because Claude WILL violate them without hard enforcement.

### INV-IMPL-001: API Contract Changes → Test All Consumers

**Rule:** When you modify a function's return type, interface, or API response schema, you MUST test ALL consumers of that API with Playwright.

**Trigger:** Any Edit/Write to files matching:
- `*/api/**/route.ts`
- `*/lib/**/*.ts` (exported functions)
- Any file defining `interface` or `type` that is exported

**Enforcement:**
```
BEFORE claiming the change is complete:
1. Grep for all imports of the modified file
2. List every consumer file found
3. For each consumer that renders UI:
   → Run Playwright verification
   → Paste snapshot as evidence
4. If ANY consumer is untested → NOT DONE
```

**Example Violation:** Changed `extract-with-style-master.ts` to return `items[]` instead of `styleNumbers[]`. Did NOT test `import-photo/page.tsx` which consumes it. Page crashed.

---

### INV-IMPL-002: Verification Evidence Required

**Rule:** "I tested it" is NOT acceptable. You must paste the actual Playwright snapshot as proof.

**Enforcement:**
```
To claim ANY step/feature complete, you MUST include:

1. The exact Playwright command:
   mcp__playwright__browser_navigate({ url: "..." })
   mcp__playwright__browser_snapshot({})

2. The snapshot output showing expected elements

3. Explicit confirmation: "Verified: [element1], [element2], [element3]"

WITHOUT ALL THREE → NOT DONE
```

**Anti-pattern:** "I verified the page loads correctly" (no snapshot = lying)

**Correct pattern:**
```
Verified /seasons/import-photo:
- "Step 1: Upload Design Notes Photos" ✓
- "Extract Fabrics & Styles" button ✓
- Season Code input ✓
[snapshot pasted above]
```

---

### INV-IMPL-003: Commit Gate

**Rule:** No git commit without Playwright verification evidence for ALL changed files that affect UI.

**Enforcement:**
```
BEFORE running `git commit`:

1. List all modified .tsx files
2. For each modified UI file:
   → What URL renders this component?
   → Paste Playwright snapshot of that URL
3. For each modified API/lib file:
   → List consumers (INV-IMPL-001)
   → Paste Playwright snapshot for each consumer

If you cannot provide snapshots → DO NOT COMMIT
```

**Anti-pattern:** Committing after CLI test passes but before UI verification.

---

### INV-IMPL-004: No Ad-Hoc Changes Outside Pipeline

**Rule:** ALL code changes must go through the Ralph pipeline. No "quick fixes" or "small changes" that bypass verification.

**Trigger:** Any use of Edit/Write tool on `.ts`/`.tsx` files.

**Enforcement:**
```
BEFORE using Edit/Write on source code, answer:

1. Which Ralph step does this change belong to?
   → If none exists: STOP. Create a step first.

2. What test verifies this change?
   → If none exists: STOP. Write the test first.

3. How will you verify with Playwright?
   → If unclear: STOP. Define verification criteria first.

"Quick fix" or "small change" is NOT an excuse to skip the pipeline.
```

**Anti-pattern:** "Let me just fix this one thing real quick..." [edits file, claims done, breaks something else]

---

### INV-IMPL-005: Dependency Awareness

**Rule:** Maintain awareness of API → Consumer relationships. When modifying an API, automatically identify and test all consumers.

**Required Dependency Map (update as codebase evolves):**
```
/api/extract-design-notes/route.ts
  → /seasons/import-photo/page.tsx

/lib/extraction/extract-with-style-master.ts
  → /api/extract-design-notes/route.ts
  → /seasons/import-photo/page.tsx

/lib/supabase/*.ts
  → ALL pages using database

/components/ui/*.tsx
  → ALL pages importing that component
```

**Enforcement:**
```
When you modify a file:
1. Check the dependency map above
2. If the file is listed as a dependency source:
   → Identify all consumers
   → Add them to your verification checklist
3. Update the dependency map if you discover new relationships
```

---

### Enforcement Summary

| Invariant | Trigger | Gate |
|-----------|---------|------|
| INV-IMPL-001 | API/interface change | Must test all consumers |
| INV-IMPL-002 | Claiming "done" | Must paste snapshot evidence |
| INV-IMPL-003 | git commit | Must have UI verification for all changes |
| INV-IMPL-004 | Edit/Write on source | Must be part of Ralph step |
| INV-IMPL-005 | Modifying shared code | Must identify and test consumers |

**Remember:** These invariants exist because Claude Code WILL skip verification if not forced. Trust nothing. Verify everything. Show receipts.

---

## Component Contracts & Integration Testing

**THE CORE PROBLEM:** Unit tests pass but the system is broken. Each step works in isolation but they don't integrate. This happens because there are no contracts between components and no cumulative integration tests.

### Contract Definition

Every module that is consumed by another module MUST define a contract:

```typescript
// CONTRACT: extract-with-style-master.ts
// =========================================
//
// EXPORTS:
//   - extractWithStyleMaster(imageBase64: string, options?) → ExtractionResult
//
// INPUT CONTRACT:
//   - imageBase64: base64-encoded JPEG/PNG image
//   - options.preferredEngine: 'gemini' | 'claude' (default: 'gemini')
//
// OUTPUT CONTRACT (ExtractionResult):
//   {
//     collection: string,
//     theme: string | null,
//     fabrics: ExtractedFabric[],  // MUST be array, never undefined
//     engine: 'gemini' | 'claude'
//   }
//
// ExtractedFabric CONTRACT:
//   {
//     name: string,               // MUST be non-empty
//     alternateName: string | null,
//     fabricContent: string | null,
//     items: ExtractedItem[],     // MUST be array, never undefined
//     generalFabricNotes: string | null
//   }
//
// ExtractedItem CONTRACT:
//   {
//     styleId: string,            // MUST be 4-digit string
//     dbMatchName: string | null,
//     assignedFabric: string | null,
//     notes: string | null,
//     status: 'matched' | 'new_style'  // MUST be one of these
//   }
//
// CONSUMERS:
//   - /api/extract-design-notes/route.ts
//   - /seasons/import-photo/page.tsx (via API)
//
// BREAKING CHANGES:
//   - Changing items[] structure breaks import-photo page
//   - Changing status values breaks UI rendering
//   - Adding required fields breaks all consumers
```

**Rule:** When you modify a module, check its contract. If you change the contract, you MUST update all consumers.

### Cumulative Integration Test

**After EVERY step, run a cumulative integration test that covers ALL completed steps.**

```
┌─────────────────────────────────────────────────────────────────┐
│  CUMULATIVE INTEGRATION TEST FLOW                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  After Step 1 completes:                                        │
│    → Run integration-test-01.sh (tests step 1 in context)       │
│                                                                 │
│  After Step 2 completes:                                        │
│    → Run integration-test-01.sh (regression)                    │
│    → Run integration-test-02.sh (tests steps 1+2 together)      │
│                                                                 │
│  After Step 3 completes:                                        │
│    → Run integration-test-01.sh (regression)                    │
│    → Run integration-test-02.sh (regression)                    │
│    → Run integration-test-03.sh (tests steps 1+2+3 together)    │
│                                                                 │
│  After Step N completes:                                        │
│    → Run ALL previous integration tests (regression)            │
│    → Run integration-test-N.sh (tests all steps together)       │
│                                                                 │
│  IF ANY INTEGRATION TEST FAILS → STEP IS NOT COMPLETE           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Integration Test Structure

Each integration test should test the INTERFACE between components, not just the component itself:

```bash
# integration-test-03.sh
# Tests: Photo upload → Extraction → Season creation (steps 1+2+3)

# This is NOT a unit test of step 3
# This tests that steps 1, 2, and 3 WORK TOGETHER

echo "=== INTEGRATION TEST 03: Photo → Extract → Season ==="

# 1. Start from clean state
# 2. Upload photo (step 1 functionality)
# 3. Extract fabrics (step 2 functionality)
# 4. Verify extraction result matches CONTRACT
# 5. Create season (step 3 functionality)
# 6. Verify season page loads with extracted data
# 7. Verify data flows correctly between ALL components

# Playwright E2E test
cat << 'INTEGRATION_TEST'
{
  "name": "Photo to Season Integration",
  "steps": [
    {"action": "navigate", "url": "/seasons/import-photo"},
    {"action": "upload", "file": "test-image.jpg"},
    {"action": "click", "element": "Extract Fabrics & Styles"},
    {"action": "wait", "text": "Step 2: Review Extracted Fabrics"},
    {"action": "verify", "contract": "ExtractionResult", "check": "fabrics.length > 0"},
    {"action": "verify", "contract": "ExtractedFabric", "check": "items is array"},
    {"action": "click", "element": "Create Season"},
    {"action": "wait", "url_contains": "/seasons/"},
    {"action": "verify", "element": "Season Fabrics table"},
    {"action": "verify", "element": "fabric count matches extraction"}
  ]
}
INTEGRATION_TEST
```

### E2E Smoke Test (Run After EVERY Change)

**A single test that runs the ENTIRE user workflow from start to finish.**

```bash
# e2e-smoke-test.sh
# THE ULTIMATE TEST: Does the whole system actually work?

echo "=== E2E SMOKE TEST: Full Karen Workflow ==="

# This test runs the COMPLETE user journey:
# 1. Login
# 2. Navigate to seasons
# 3. Import from photo
# 4. Extract fabrics (AI extraction)
# 5. Review and confirm
# 6. Create season
# 7. View season page
# 8. Edit pricing (if applicable)
# 9. Export to AIMS
# 10. Verify CSV output

# If this test passes, the system WORKS.
# If this test fails, something is BROKEN.

# Run with Playwright:
# mcp__playwright__browser_navigate → each step
# mcp__playwright__browser_snapshot → verify each state
# mcp__playwright__browser_click → user actions

# MUST RUN THIS:
# - After ANY code change
# - Before ANY commit
# - Before claiming ANY step complete
```

### Contract Verification in Tests

Every integration test should verify contracts are maintained:

```typescript
// In test files, verify contracts explicitly:

function verifyExtractionResultContract(result: unknown): void {
  // Verify structure matches contract
  assert(typeof result === 'object', 'Result must be object');
  assert('fabrics' in result, 'Result must have fabrics');
  assert(Array.isArray(result.fabrics), 'fabrics must be array');

  for (const fabric of result.fabrics) {
    verifyExtractedFabricContract(fabric);
  }
}

function verifyExtractedFabricContract(fabric: unknown): void {
  assert(typeof fabric === 'object', 'Fabric must be object');
  assert(typeof fabric.name === 'string', 'name must be string');
  assert(fabric.name.length > 0, 'name must be non-empty');
  assert(Array.isArray(fabric.items), 'items must be array'); // THIS WOULD HAVE CAUGHT THE BUG

  for (const item of fabric.items) {
    verifyExtractedItemContract(item);
  }
}
```

### The Integration Testing Rule

```
┌─────────────────────────────────────────────────────────────────┐
│  MANDATORY INTEGRATION TESTING                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. UNIT TEST: Does this step work in isolation?                │
│     → Run step-N test                                           │
│                                                                 │
│  2. CONTRACT TEST: Does output match defined contract?          │
│     → Verify all output types match contract definitions        │
│                                                                 │
│  3. INTEGRATION TEST: Does this step work with previous steps?  │
│     → Run ALL integration tests (01 through N)                  │
│                                                                 │
│  4. E2E SMOKE TEST: Does the full workflow still work?          │
│     → Run complete user journey test                            │
│                                                                 │
│  ALL FOUR MUST PASS BEFORE STEP IS COMPLETE                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### What Would Have Caught The Bug

If we had this in place:

1. **Contract definition** for `ExtractedFabric` would specify `items: ExtractedItem[]`
2. **Contract test** would verify extraction output has `items` array
3. **Integration test** would test photo upload → extraction → UI rendering
4. **E2E smoke test** would run full workflow and crash at import-photo page

The bug would have been caught at step 3 (integration test) instead of in production demo.

---

## The Workflow

Two paths depending on complexity:

### Fast Path (most features) — Journey → PRP

```
INTENT (user story, journey, or problem statement)
  ↓
1. /design prp {journey-or-description}             Generate PRP directly
   └─► Validation + stress-testing built in
2. /design check {prp}                              Verify PRP quality
  ↓ (MUST PASS)
EXECUTABLE PRP
  ↓
3. /design implement {prp}                          Generate tests (TDD)
4. /design test-validate {tests}                    Validate test syntax
5. /design test-cohesion {tests}                    Verify test interactions
6. /design ralph-check {prp}                        Verify PRP compliance
  ↓ (MUST PASS)
TEST SUITE + READY-TO-IMPLEMENT PRP
  ↓
7. /design run {prp}                                AI implements to spec
  ↓
IMPLEMENTATION
  ↓
8. Retrospective                                    Extract learnings
  ↓
LEARNINGS → System improvements
```

### Deliberate Path (complex/uncertain features) — Journey → Spec → PRP

Use this when the approach is unclear, there are multiple valid architectures, or you need to think through options before committing.

```
INTENT
  ↓
0. /design spec {journey}                           Think through approach
  ↓
1. /design stress-test {spec}                       Check COMPLETENESS
  ↓ (MUST PASS)
2. /design validate {spec}                          Check CLARITY
  ↓ (MUST PASS)
3. /design prp {spec}                               Compile to PRP
  ↓
... (same as Fast Path from step 2 onward)
```

**When to use Deliberate Path:**
- Multiple valid architectures (need to evaluate trade-offs)
- New domain (team hasn't built this type of thing before)
- High-risk changes (irreversible, affects many users)
- Uncertain requirements (need to clarify before committing)

---

## Agent Usage

This skill is used by design systems engineers and implementation teams. You will follow the 11-step pipeline exactly.

## Command Reference

### Command Workflow

**Fast Path (most features):**

```
┌─────────────────────────────────────────────────────────────────┐
│  1. /design prp            "Generate PRP from journey/intent"   │
│     └─► Accepts: journey file, description, OR spec file        │
│     └─► Embeds problem/journey context in PRP overview          │
│     └─► Runs validation + stress-test internally                │
│     └─► Runs dependency-trace (INV-L010, INV-L011)              │
│                                                                 │
│  2. /design check          "Is the PRP READY?"                  │
│     └─► Verifies: extraction completeness, no placeholders      │
│     └─► (Runs automatically after prp)                          │
│                                                                 │
│  3. HUMAN REVIEWS          ← YOU approve before implementation  │
│                                                                 │
│  4. /design implement      "Generate tests (TDD mode)"          │
│     └─► Creates: test_NN.py, gate_N.py, conftest.py            │
│     └─► NO step files - tests are the contract (INV-L007)       │
│                                                                 │
│  5. /design test-validate  "Are tests valid & complete?"        │
│     └─► Verifies: syntax, SC coverage, integration (INV-L008)   │
│                                                                 │
│  6. /design test-cohesion  "Do tests work together?"            │
│     └─► Verifies: no duplicates, fixtures, imports (INV-L009)   │
│                                                                 │
│  7. /design ralph-check    "Do tests match PRP?"                │
│     └─► Verifies: schema fields, routes, success criteria       │
│                                                                 │
│  8. /design run            "AI writes code to pass tests"       │
│     └─► AI coding agent implements, tests verify, iterate       │
└─────────────────────────────────────────────────────────────────┘
```

**Deliberate Path** adds steps before the PRP: `/design spec`, `/design stress-test`, `/design validate`. Use when the approach is uncertain.

**Don't skip validation.** The PRP command runs validation internally. If it flags issues, fix them before proceeding.

---

### /design init {project-name}

Bootstrap a new project with complete Design Ops structure.

**Usage:**
```
/design init my-new-feature
/design init house-build --domain physical-construction
/design init api-service --domain integration
```

**Execution:**

1. **Create folder structure:**
```
{project-name}/
├── docs/
│   └── design/
│       ├── research/           # Market research, user interviews
│       ├── personas/           # User persona definitions
│       ├── journeys/           # User journey maps
│       ├── specs/              # Feature specifications
│       ├── PRPs/               # Compiled Product Requirements Prompts
│       └── deltas/             # Post-execution learnings
├── CONVENTIONS.md              # Codebase conventions (if code exists)
└── README.md                   # Project overview
```

2. **Initialize templates:**
   - Copy spec template to `docs/design/specs/spec-template.md`
   - Copy PRP template to `docs/design/PRPs/prp-template.md`
   - Initialize empty `CONVENTIONS.md` if codebase exists

3. **Configure domain (if specified):**
   - Create `.designops` config file with domain reference
   - Note which domain invariants will apply

**Output:**
```
Created Design Ops structure for: {project-name}
├── docs/design/ (6 subdirectories)
├── CONVENTIONS.md (initialized)
└── .designops (config)

Domain: {domain | universal}
Invariants: Universal (1-10) + {domain-specific if applicable}

Next steps:
1. Add research to docs/design/research/
2. Define personas in docs/design/personas/
3. Create journeys in docs/design/journeys/
4. Run: /design spec docs/design/journeys/your-journey.md
```

---

### /design spec {journey-file} [--output path] *(optional — Deliberate Path only)*

Generate a specification from a user journey document. **Only needed when the approach is uncertain** — for most features, skip this and go directly to `/design prp`. Extracts pain points, goals, and steps into functional requirements.

**Usage:**
```
/design spec docs/design/journeys/pathologist-search-journey.md
/design spec journeys/checkout-flow.md --output specs/checkout-spec.md
```

**What It Does:**

1. **Parses journey document:**
   - Extracts journey steps (the WHAT)
   - Identifies pain points (the PROBLEMS)
   - Captures goals (the OUTCOMES)
   - Notes persona references

2. **Generates structured spec:**
   - Problem statement from pain points
   - Functional requirements from steps
   - Success criteria from goals
   - Non-functional requirements inferred

3. **Prepares manifest for traceability:**
   - Links spec back to source journey
   - Tracks journey hash for change detection

**Execution:**
```bash
./enforcement/design-ops-v3.sh spec-prepare "{journey-file}"
# Reads manifest at output_dir/.manifest.json
# Then generates spec using template
```

**Output:**
```
━━━ SPEC-PREPARE COMPLETE ━━━
Journey:     journeys/pathologist-search-journey.md
Output:      specs/pathologist-search-spec.md

Extracted:
  Steps:        14
  Pain points:  8
  Goals:        5
  Personas:     1 (Dr. Sarah Chen)

Generated spec sections:
  - Problem Statement (from pain points)
  - Scope (bounded by journey steps)
  - Functional Requirements (14 FRs)
  - Success Criteria (5 measurable criteria)
  - Failure Modes (from pain points)

Next: /design stress-test specs/pathologist-search-spec.md
```

---

### /design stress-test {spec-file} [--requirements file] [--journeys file]

Check spec COMPLETENESS against domain invariants. **Run this BEFORE validate.**

**Usage:**
```
/design stress-test docs/design/specs/feature-spec.md
/design stress-test specs/api-spec.md --requirements requirements.md
/design stress-test specs/checkout.md --journeys user-journeys.md
```

**What It Checks:**

1. **Domain Detection:**
   - Parses `Domain:` header from spec
   - Resolves applicable invariants (universal + domain-specific)
   - Reports total invariant count

2. **Deterministic Coverage Checks:**
   - Happy path explicitly described
   - Error/failure cases addressed
   - Empty/null states handled
   - External failure modes (timeout, offline, API down)
   - Concurrency considerations
   - Limits/boundaries specified

3. **LLM Invariant Analysis:**
   - Invariant #1 (Ambiguity): Terms without operational definitions
   - Invariant #4 (No Irreversible Without Recovery): Destructive actions without undo
   - Invariant #5 (Fail Loudly): Silent failures
   - Invariant #7 (Validation Executable): Untestable success criteria
   - Invariant #10 (Degradation Path): Missing fallback strategies

**Execution:**
```bash
./enforcement/design-ops-v3.sh stress-test "{spec-file}" [--requirements "{file}"] [--journeys "{file}"] [--quick]
```

**Output:**
```
━━━ Domain Detection ━━━
  Domains detected: 2 (including universal)
  Total invariants: 20
    → Universal: system-invariants.md (1-11)
    → Domain (consumer product): consumer-product.md (11-15)

━━━ Deterministic Coverage Checks ━━━
  ✓ Happy path mentioned
  ✓ Error cases mentioned
  ✗ External failure modes not addressed

━━━ LLM Deep Analysis ━━━
Invariant Violations:
  ✗ Invariant #4: Delete operation has no confirmation dialog
  ✗ Invariant #7: "Works correctly" is not testable

Missing Coverage:
  ? Offline mode behavior not specified
  ? Rate limiting not addressed

Critical Blockers:
  1. What happens when AIMS API is unavailable?
  2. Max file size for imports not specified

───────────────────────────────────────────────────────────────
  Status: REVIEW REQUIRED
  → Address invariant violations before proceeding to validate
───────────────────────────────────────────────────────────────
```

**Pipeline State:**

Findings are saved to `~/.design-ops-state/{spec-name}.state.json` for use by subsequent commands.

**Next step:** `/design validate {spec-file}`

---

### /design validate {spec-file} [--domain domain-file]

Validate a specification against system invariants before PRP compilation.

**Usage:**
```
/design validate docs/design/specs/feature-spec.md
/design validate specs/mobile-app.md --domain consumer-product
/design validate specs/house-foundation.md --domain physical-construction --domain remote-management
```

**Execution:**

1. **Run validator.sh:**
```bash
./enforcement/validator.sh "{spec-file}" [--domain "{domain-file}"]
```

2. **Parse output for:**
   - Violations (blocking - must fix)
   - Warnings (non-blocking - should address)

3. **Report results with actionable fixes**

**Output (Pass):**
```
Validating: specs/my-feature.md

Checking Universal Invariants...
  [1] Ambiguity is Invalid........... PASS
  [2] State Must Be Explicit......... PASS
  [3] Emotional Intent Must Compile.. PASS
  [4] No Irreversible Without Recovery PASS
  [5] Execution Must Fail Loudly..... PASS
  [6] Scope Must Be Bounded.......... PASS
  [7] Validation Must Be Executable.. PASS
  [8] Cost Boundaries Explicit....... PASS
  [9] Blast Radius Declared.......... PASS
  [10] Degradation Path Exists....... PASS

Violations: 0
Warnings: 0

PASS - Spec ready for PRP compilation
Run: /design prp specs/my-feature.md
```

**Output (Fail):**
```
Validating: specs/my-feature.md

Checking Universal Invariants...
  [1] Ambiguity is Invalid........... FAIL

VIOLATION: Invariant #1 (Ambiguity is Invalid)
  Line 23: "Process data properly"
  Fix: Replace 'properly' with objective criteria: metric + threshold + measurement

VIOLATION: Invariant #3 (Emotional Intent Must Compile)
  Line 45: "Users should feel confident"
  Fix: Use format: emotion := concrete_mechanism (e.g., confident := show_success_rate + undo_option)

Violations: 2
Warnings: 0

REJECTED - Fix violations before proceeding
```

---

### /design prp {input} [--output path] (alias: generate)

Generate a Product Requirements Prompt from a journey, description, or spec. **This is the primary entry point for most features** — no separate spec needed.

**Input types:**
- **Journey file** (`.md` with user journey) — extracts problem, steps, and goals into PRP
- **Inline description** (text string) — generates PRP from a brief feature description
- **Spec file** (from Deliberate Path) — compiles validated spec into PRP

**Usage:**
```
/design prp "In-canvas line sheet editor — drag cards, edit text, export PDF"
/design prp docs/design/journeys/checkout-flow.md
/design prp specs/feature-spec.md                    # Deliberate Path
/design prp specs/api-spec.md --output PRPs/api-prp.md
/design prp journeys/mobile-app.md --template user-feature
```

**Note:** The shell script uses `generate` as the command name:
```bash
./enforcement/design-ops-v3.sh generate specs/feature.md
```

**Template options:**
- `base` - Generic PRP template (auto-detected by default)
- `api-integration` - Technical API/integration projects
- `user-feature` - Consumer-facing features
- `data-migration` - Database/data infrastructure projects

**Execution:**

1. **If input is a journey or description (Fast Path):**
   - Extract problem statement, user steps, goals
   - Run invariant validation on extracted requirements
   - Run stress-test (completeness check) on extracted requirements
   - If violations found: report and STOP (user must clarify)
   - Embed journey context in PRP overview section (2-3 paragraphs)

2. **If input is a spec (Deliberate Path):**
   - Validate spec first:
```bash
./enforcement/validator.sh "{spec-file}" [--domain "{domain}"]
# Abort if violations found
```

3. **Gather context:**
   - Read input content
   - Detect project type
   - Load CONVENTIONS.md if exists
   - Identify domain-specific requirements
   - Extract timeline hints
   - Extract key requirements

3. **Generate PRP:**
```bash
./enforcement/spec-to-prp.sh "{spec-file}" [--template type] [--output path]
```

4. **Run quality check:**
```bash
./enforcement/prp-checker.sh "{output-file}"
```

5. **Red Team Pass (Devil's Advocate):**

   After the PRP is generated, automatically run an adversarial review that tries to break it. This catches gaps that the generator is blind to — it wrote the PRP, so it can't see its own assumptions.

   **The red team asks 7 questions:**

   | # | Question | What It Catches |
   |---|----------|-----------------|
   | RT-1 | **What happens when X fails?** For every external call (API, DB, file, network), is there a failure path? | Missing error handling, silent failures |
   | RT-2 | **What's the first thing that will break during implementation?** Walk through building this step by step — where does the implementer get stuck? | Unstated dependencies, ordering issues, missing context |
   | RT-3 | **What did the PRP assume without saying?** List every implicit assumption (library exists, data format, user behavior, browser support). Sub-check: *State or references?* For every data structure that stores objects for later replay (undo stacks, caches, queues), ask: should we store serialized state (data) or live references? Serialized state implies round-trip capability — can the object be reconstructed synchronously from its serialization? If not (e.g., Canvas/DOM objects with embedded resources, async deserialization), store references instead. | Hidden assumptions that become bugs, type-system vs runtime lifecycle mismatches |
   | RT-4 | **What's ambiguous enough to build two different things?** Find requirements where two competent developers would build different solutions. | Ambiguous requirements |
   | RT-5 | **What edge cases are missing?** Empty states, max limits, concurrent access, Unicode, timezone, first-run vs Nth-run. | Untested edge cases |
   | RT-6 | **What will the user actually do vs what the PRP expects?** Real users don't follow happy paths — what happens when they go off-script? | UX gaps, missing validation |
   | RT-7 | **Is anything over-engineered?** Features nobody asked for, abstractions for one use case, premature optimization. | Scope creep, wasted effort |

   **Severity levels:**
   - **BLOCKING** — Cannot implement without resolving. Missing critical information. (Stops pipeline.)
   - **RISK** — Can implement but likely to cause problems. Should address before implementation.
   - **NOTE** — Worth knowing. Implementer should be aware.

   **Output format:** Appends a `## Holes & Risks` section to the PRP:

   ```markdown
   ## Holes & Risks (Red Team Review)

   _Auto-generated adversarial review. Address BLOCKING items before implementation._

   ### BLOCKING

   - **RT-2: Build order dependency.** Phase 2 references `canvas-history.ts` undo stack
     but Phase 1 doesn't create it. Implementer will get stuck at Phase 2 Step 1.
     **→ Move undo stack to Phase 1 or make Phase 2 not depend on it.**

   ### RISK

   - **RT-1: PDF export failure path.** FR-6.1 says "Export PDF renders current canvas
     to PDF" but no failure handling if sharp/resvg crashes on malformed SVG.
     **→ Add: on export failure, show error toast and offer SVG download as fallback.**

   - **RT-5: Empty canvas.** What if user deletes ALL cards? Canvas is blank.
     No mention of empty state behavior. **→ Define: show "No styles remaining" message
     with an Undo button.**

   ### NOTE

   - **RT-3: Assumes Fabric.js handles our SVG.** The PRP says "Fabric.js can parse
     our SVG directly" but our SVG uses custom `id` attributes and nested groups.
     Fabric.js may flatten or lose group structure. **→ Test SVG import early in Phase 1.**

   - **RT-3 (state vs references): Delete command stores `objectState: Record<string, unknown>`
     — implies JSON serialization via `toJSON()`. But restoring a Fabric.js object from
     JSON requires async `fabric.util.enlivenObjects`, and `applyReverse` is synchronous.**
     A disciplined implementer will stub it rather than break the type contract. **→ Store
     the live object reference, not serialized state. `canvas.remove()` keeps the object
     alive; `canvas.add(obj)` restores it exactly — images, styles, positions intact,
     no serialization overhead, synchronous.**

   - **RT-7: Multi-select (FR-2.4) adds complexity.** Karen's workflow is single-card
     moves. Multi-select is nice-to-have. **→ Consider deferring to Phase 4.**
   ```

   **Blocking behavior:**
   - If ANY finding is **BLOCKING**: pipeline stops. User must resolve before `/design implement`.
   - **RISK** and **NOTE** findings are appended to PRP and carried forward — implementer sees them.

6. **Report confidence and next steps**

**Output:**
```
PRP Generation
==============

Reading input: journeys/canvas-editor.md
Extracting requirements... 7 FRs, 4 NFRs, 10 success criteria

Generating PRP...
  Template: user-feature (auto-detected)
  PRP_ID: PRP-2026-02-17-001

Running quality check...
  Required sections: PASS
  Quality score: 82/100

Running red team pass...
  RT-1 (failure paths):  1 RISK found
  RT-2 (build order):    1 BLOCKING found
  RT-3 (assumptions):    1 NOTE found
  RT-4 (ambiguity):      0 findings
  RT-5 (edge cases):     1 RISK found
  RT-6 (user behavior):  0 findings
  RT-7 (over-engineering): 1 NOTE found

  ⛔ 1 BLOCKING finding — must resolve before implementation

OUTPUT: PRPs/canvas-editor-prp.md

Red team findings appended to PRP.

Next steps:
1. Open PRPs/canvas-editor-prp.md
2. Resolve BLOCKING item (build order dependency)
3. Review RISK items (2 findings)
4. Run: /design check PRPs/canvas-editor-prp.md
5. Begin execution with /design implement
```

---

### /design check {prp-file}

Verify PRP quality and extraction completeness. **Runs automatically after generate.**

**Usage:**
```
/design check PRPs/feature-prp.md
/design check PRPs/api-prp.md --quick
```

**What It Checks:**

1. **Domain Detection** (from PRP content)

2. **Source Spec Comparison:**
   - Extracts `source_spec:` path from PRP meta block
   - If source spec accessible, compares key content:
     - Database schema (CREATE TABLE statements)
     - API endpoints (GET/POST/PUT/DELETE routes)
     - ASCII wireframes (box-drawing characters)
     - Error messages

3. **Structural Checks:**
   - Required sections present (overview, success criteria, timeline, risk, validation)
   - No unfilled placeholders ([FILL], [TODO], [TBD])
   - No LLM reasoning artifacts ("let me", "I'll", "here's my")

4. **LLM Readiness Assessment:**
   - Confidence score sanity check
   - Extraction completeness (NOT_SPECIFIED_IN_SPEC flags)
   - Thinking level appropriateness
   - Appendix content verification
   - Implementation blockers

**Execution:**
```bash
./enforcement/design-ops-v3.sh check "{prp-file}" [--quick]
```

**Output:**
```
━━━ Spec-to-PRP Comparison ━━━
  ✓ Database schema content preserved
  ✓ API endpoints preserved
  ✗ Source has ASCII wireframes but PRP may be missing them

━━━ Deterministic Checks ━━━
  ✓ overview section found
  ✓ success criteria section found
  ✗ Found 2 unfilled placeholders

━━━ LLM Advisory Assessment ━━━
Summary: PRP is mostly implementation-ready with minor gaps

Blockers (must resolve):
  ✗ Section 4.2 references "degradation strategy" but none defined

Confidence Assessment:
  Stated 7.2/10 seems accurate given documented edge cases

───────────────────────────────────────────────────────────────
  Status: ITEMS TO REVIEW
  → Fix placeholders, then proceed to implementation
───────────────────────────────────────────────────────────────
```

**Next step:** Human review, then `/design implement`

---

### /design review {spec-file} {implementation-path}

Review an implementation against its source specification for compliance.

**Usage:**
```
/design review specs/feature-spec.md ./src/feature/
/design review specs/api-spec.md ./api/ --check-conventions
```

**Execution:**

1. **Load spec requirements:**
   - Parse spec file for requirements (bullet points, acceptance criteria)
   - Extract validation criteria
   - Load CONVENTIONS.md if present

2. **Analyze implementation:**
   - Scan implementation path for relevant files
   - Check for test coverage
   - Look for validation commands
   - Check convention compliance

3. **Cross-reference:**
   - Map requirements to implementation
   - Identify gaps
   - Check edge case handling

4. **Run validation commands (if defined):**
   - Execute test suites
   - Check linting
   - Run type checks

5. **Generate compliance report**

**Output:**
```
Implementation Review
=====================

Spec: specs/feature-spec.md
Implementation: ./src/feature/

Requirements Coverage
---------------------
[ ] Requirement 1: User can submit form
    Status: IMPLEMENTED
    Files: src/feature/form.tsx, src/feature/submit.ts
    Tests: tests/feature/form.test.ts

[ ] Requirement 2: Form validates email format
    Status: IMPLEMENTED
    Files: src/feature/validation.ts
    Tests: tests/feature/validation.test.ts

[ ] Requirement 3: Error messages display inline
    Status: PARTIAL
    Files: src/feature/errors.tsx
    Missing: No test coverage for error display

[!] Requirement 4: Rate limit submissions
    Status: NOT IMPLEMENTED
    Note: No rate limiting found in codebase

Convention Compliance
--------------------
[x] TypeScript strict mode enabled
[x] ESLint rules passing
[x] Test coverage >= 80%
[ ] Component naming conventions - 2 violations
    - SubmitBtn.tsx should be SubmitButton.tsx
    - errorMsg.tsx should be ErrorMessage.tsx

Validation Commands
------------------
npm test: PASS (45/45)
npm run lint: PASS
npm run typecheck: PASS

SUMMARY
-------
Requirements: 3/4 implemented (75%)
Conventions: 3/4 passing (75%)
Tests: PASS

Status: NEEDS ATTENTION
- Complete rate limiting implementation
- Fix naming convention violations
- Add error display tests
```

---

### /design orchestrate {spec-file} [--domain domain] [--phase phase]

Run the multi-agent orchestration pipeline for complete spec-to-PRP workflow.

**Usage:**
```
/design orchestrate specs/feature-spec.md --domain api
/design orchestrate specs/migration-spec.md --phase analysis
/design orchestrate specs/api-spec.md --domain integration --output ./output
```

**Phases:**
- `analysis` - Run spec-analyst and validator in parallel
- `generate` - Generate PRP from analysis results
- `review` - Review existing PRP for quality
- `retrospective` - Create retrospective from completed PRP
- `full` - Run complete pipeline (default)

**Execution:**
```bash
./tools/multi-agent-orchestrator.sh --spec "{spec-file}" --domain "{domain}" [--phase "{phase}"]
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║      MULTI-AGENT DESIGN OPS ORCHESTRATOR                      ║
╚═══════════════════════════════════════════════════════════════╝

Phase: full
Domain: api
Output: ./output

━━━ Phase 1: Analysis ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[10:23:45] Starting parallel analysis...
[10:23:47] ✓ spec-analyst completed
[10:23:48] ✓ validator completed

Analysis results: Completeness=85%, Thinking=Think
Validation results: Confidence=78%, Violations=0

━━━ Phase 2: Generation ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[10:23:50] ✓ prp-generator completed

━━━ Phase 3: Review ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[10:23:52] ✓ reviewer completed

╔═══════════════════════════════════════════════════════════════╗
║                      ORCHESTRATION COMPLETE                   ║
╚═══════════════════════════════════════════════════════════════╝

Generated Files:
  - analysis.json
  - validation.json
  - prp-feature.md
  - review.json

Status: PRP APPROVED - Ready for implementation
```

---

### /design watch {spec-file} [--domain domain] [--interval seconds]

Monitor spec file for changes with real-time validation feedback.

**Usage:**
```
/design watch specs/feature-spec.md --domain api
/design watch specs/api-spec.md --interval 5
```

**Execution:**
```bash
./tools/watch-mode.sh --spec "{spec-file}" --domain "{domain}" [--interval "{seconds}"]
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║                    WATCH MODE - LIVE VALIDATION               ║
╚═══════════════════════════════════════════════════════════════╝

Watching: specs/feature-spec.md
Domain:   api
Interval: 2s

Press Ctrl+C to stop

[10:25:32] Confidence: 78% ─ | Major: 1 Warnings: 2 (updated)
[10:25:34] Watching... (no changes)
[10:25:38] Confidence: 82% ↑ | Warnings: 1 (updated)
✓ Confidence improved by 4%
```

---

### /design dashboard [--results-dir dir]

Display real-time validation dashboard showing all spec health status.

**Usage:**
```
/design dashboard
/design dashboard --refresh 10
```

**Execution:**
```bash
./tools/validation-dashboard.sh [--results-dir "{dir}"] [--refresh "{seconds}"]
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║           DESIGN OPS VALIDATION DASHBOARD                     ║
╚═══════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════╗
║ SYSTEM HEALTH                                                 ║
╠═══════════════════════════════════════════════════════════════╣
║ Status: HEALTHY                                               ║
║ Specs Monitored: 5                                            ║
║ Average Confidence: 76%                                       ║
║                                                               ║
║   ████████████████░░░░░░░░                                    ║
║   ■ Healthy: 4  ■ Warning: 1  ■ Critical: 0                   ║
╚═══════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════╗
║ SPEC VALIDATION STATUS                                        ║
╠═══════════════════════════════════════════════════════════════╣
║   SPEC                   CONFIDENCE           CRIT  MAJOR     ║
║   ──────────────────────────────────────────────────────────  ║
║   ● api-spec             ████████████████░░░░  82%    0     0 ║
║   ● user-feature         ████████████████░░░░  78%    0     1 ║
║   ● migration            ████████████░░░░░░░░  65%    0     2 ║
╚═══════════════════════════════════════════════════════════════╝
```

---

### /design continuous start|stop|status [--spec files]

Manage background continuous validation service.

**Usage:**
```
/design continuous start --spec specs/api.md --spec specs/db.md --domain api
/design continuous status
/design continuous stop
```

**Execution:**
```bash
./tools/continuous-validator.sh start --spec "{file1}" --spec "{file2}" --domain "{domain}"
./tools/continuous-validator.sh status
./tools/continuous-validator.sh stop
```

---

### /design retrospective {prp-file} --outcome "{summary}"

Generate retrospective and extract learnings after implementation.

**Usage:**
```
/design retrospective PRPs/feature-prp.md --outcome "Successfully deployed, minor issues with error handling"
```

**Execution:**
```bash
./agents/retrospective.sh "{prp-file}" --outcome "{summary}" --domain "{domain}"
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║  RETROSPECTIVE - Learning Extraction & System Improvement     ║
╚═══════════════════════════════════════════════════════════════╝

PRP:     PRPs/feature-prp.md
Domain:  api
Outcome: Successfully deployed, minor issues with error handling

[1/4] Analyzing implementation...
  Completion: 45/48 tasks (94%)

[2/4] Generating retrospective...

[3/4] Identifying invariant proposals...
  Generated 2 invariant proposals

[4/4] Generating output files...
  Created: retrospective-feature.md
  Created: invariant-proposals.json

Generated Files:
  Retrospective: retrospective-feature.md
  Proposals:     invariant-proposals.json

Summary:
  Project:       Feature Implementation
  Completion:    94%
  Proposals:     2

Next steps:
  1. Review and complete the retrospective answers
  2. Finalize invariant proposals
  3. Run: ./tools/spec-delta-to-invariant.sh retrospective-feature.md
```

---

### /design freshness [quick|full]

Run the Design Ops freshness check to ensure methodology stays current with agentic engineering best practices.

**Usage:**
```
/design freshness quick   # Check known sources only (5-10 min)
/design freshness full    # Full landscape research (15-30 min)
/design freshness         # Defaults to quick
```

**What It Does:**

1. **Scans Current State** - Inventories all Design Ops files
2. **Checks Source Health** - Validates registry sources are still active
3. **Researches Landscape** - Discovers new developments since last scan
4. **Validates Findings** - Scores against Anthropic-anchored criteria
5. **Analyzes Impact** - Compares findings to current Design Ops
6. **Generates Actions** - Creates prioritized update plan

**Execution (Claude Code does this inline):**

**Step 1: Gather Context**
```
Read and summarize current Design Ops state:
- templates/ (what PRP templates exist)
- tools/ (what automation exists)
- examples/ (what patterns are documented)
- docs/ (what guidance exists)
- invariants/ (what domains are covered)
```

**Step 2: Research Landscape**
```
Research agentic engineering developments from [LAST_SCAN_DATE] to today.

REQUIRED SOURCES (always check):
- Anthropic official: docs.anthropic.com, anthropic.com/research
- Anthropic Cookbook: github.com/anthropics/anthropic-cookbook
- Claude Code docs: Current best practices
- MCP updates: modelcontextprotocol.io

DISCOVERY FOCUS:
- New methodologies with >1000 GitHub stars OR enterprise adoption
- Patterns validated by Anthropic or recognized experts
- Tools/approaches compatible with invariant-based validation

CONTEXT: Design Ops uses invariant-based validation, multi-agent orchestration,
confidence scoring, and PRP-based implementation planning. Assess compatibility.

For each finding provide:
- Source URL
- Validation evidence (who endorses, adoption metrics)
- Key innovation (what's new)
- Relevance to Design Ops (1-10)
- Recommended action (adopt/watch/ignore)
```

**Step 3: Validate Against Framework**
```
For each discovered source, score against:
1. Anthropic Alignment (0-3): Is it endorsed/compatible with Anthropic guidance?
2. Traction (0-3): GitHub stars >1000? Enterprise adoption? Case studies?
3. Design Ops Fit (0-3): Compatible with invariants, PRPs, confidence scoring?
4. Freshness (0-1): Updated in last 6 months?

Total score /10. Only sources scoring ≥6 get recommended.
```

**Step 4: Generate Impact Analysis**
```
Compare findings against current Design Ops:

VALIDATED (Design Ops already does this):
- [List what's confirmed as best practice]

NEEDS UPDATE (Design Ops should change):
- [List specific files and changes needed]

DEPRECATED (Design Ops should remove/update):
- [List anything now outdated]

NEW ADDITIONS (Design Ops should add):
- [List new patterns/tools to incorporate]
```

**Step 5: Create Action Plan**
```
Write to docs/freshness/actions/YYYY-MM-actions.md:

## Quick Wins (< 1 hour)
- [ ] Action 1: File, change, reason

## Short-term (1 day)
- [ ] Action 2: File, change, reason

## Medium-term (1 week)
- [ ] Action 3: File, change, reason

## Watch List (revisit next month)
- Source X: Why watching, trigger for action
```

**Step 6: Update Dashboard**
```
Write to docs/freshness/dashboard.md:
- Last scan date
- Health score (0-100)
- Sources monitored
- Pending actions count
- Design Ops version alignment
```

**Output Files:**
```
docs/freshness/
├── discoveries/YYYY-MM-raw.md       # Raw research findings
├── validated/YYYY-MM-validated.md   # Scored and filtered
├── impact/YYYY-MM-impact.md         # Gap analysis
├── actions/YYYY-MM-actions.md       # Prioritized todo list
├── reports/YYYY-MM-summary.md       # Executive summary
└── dashboard.md                     # Current state (always updated)
```

**Automated Monthly Reminder:**
Install with `./tools/freshness/install.sh` to get MacOS notification on 1st of each month.

---

### /design report {project-name}

Generate a comprehensive project status report.

**Usage:**
```
/design report my-project
/design report house-build --include-deltas
```

**Execution:**

1. **Scan project structure:**
   - Find all specs in `docs/design/specs/`
   - Find all PRPs in `docs/design/PRPs/`
   - Find all deltas in `docs/design/deltas/`

2. **For each spec:**
   - Run validation status
   - Check if PRP exists
   - Check implementation status if path defined

3. **Aggregate metrics:**
   - Specs validated vs total
   - PRPs generated
   - Invariant violation trends
   - Phase completion status

4. **Generate report**

**Output:**
```
Design Ops Project Report
=========================

Project: my-project
Report Date: 2026-01-19

Specifications
--------------
| Spec | Validated | PRP | Status |
|------|-----------|-----|--------|
| feature-a.md | PASS | YES | In Progress |
| feature-b.md | PASS | YES | Complete |
| feature-c.md | FAIL (2) | NO | Blocked |

Invariant Summary
-----------------
Total validations: 15
Passed: 12 (80%)
Failed: 3 (20%)

Most common violations:
1. Invariant #1 (Ambiguity): 5 occurrences
2. Invariant #7 (Validation): 3 occurrences

PRPs Generated: 8
PRPs with unfilled placeholders: 3

Spec Deltas
-----------
| Date | Delta | New Invariant |
|------|-------|---------------|
| 2026-01-15 | API timeout handling | #44 |
| 2026-01-10 | Payment idempotency | #45 |

Recommendations
---------------
1. Address ambiguity in feature-c.md (2 violations)
2. Fill placeholders in 3 PRPs before execution
3. Review Invariant #44 applicability to active specs
```

---

## Implementation: Ralph Methodology

The Ralph Methodology provides atomic, test-verified implementation of PRPs. See [ralph-methodology.md](docs/ralph-methodology.md) for full documentation.

### /design implement {prp-file} [--output dir] [--phase N]

Generate Ralph steps from an approved PRP using **structured extraction** (not freeform generation).

**Usage:**
```
/design implement PRPs/phase1-foundation-prp.md
/design implement PRPs/feature-prp.md --output ./app/ralph-steps
/design implement PRPs/large-prp.md --phase 2  # Generate only phase 2
```

**Script Execution:**
```bash
# Uses the implement command in design-ops-v3.sh
./enforcement/design-ops-v3.sh implement "{prp-file}" [--output dir] [--phase N]

# This loads the prompt template from:
# $TEMPLATES_DIR/implement-prompt.md
```

**Prompt Template Location:** `~/.claude/plugins/design-ops/templates/implement-prompt.md`

The prompt template ensures consistent, deterministic output across all invocations.

**CRITICAL: Extraction, Not Generation**

The implement command must EXTRACT from PRP, not invent. This prevents drift between PRP and implementation.

**Extraction Mapping (MUST FOLLOW):**

| PRP Section | → | Ralph Output | Extraction Rule |
|-------------|---|--------------|-----------------|
| Meta: confidence_score | → | Step headers | Include score + derivation |
| Meta: thinking_level | → | Step headers | Flag high-attention sections |
| Timeline phases | → | Gate boundaries | One gate per phase |
| Phase deliverables | → | step-NN.sh objectives | **VERBATIM** - one step per deliverable |
| Success criteria table | → | test-NN.sh assertions | **VERBATIM** as test checks |
| Appendix: Validation commands | → | test-NN.sh commands | **COPY EXACTLY** |
| Appendix: Database schema | → | step-NN.sh SQL | **VERBATIM** - must match |
| Appendix: UI wireframes | → | step-NN.sh JSX structure | Preserve layout |
| Appendix: Error messages | → | step-NN.sh error handling | **COPY text exactly** |
| Appendix: API endpoints | → | step-NN.sh routes | **VERBATIM** paths + methods |
| Domain invariants | → | Step + test headers | Reference by number |

**Execution:**

1. **Parse PRP metadata:**
   ```
   Extract from PRP Meta section:
   - prp_id: PRP-2026-01-21-001
   - confidence_score: 7.2/10
   - thinking_level: Think Hard
   - domain: Consumer Product + Integration
   - invariants: Universal (1-11) + Domain-specific
   ```

2. **Extract phase structure:**
   ```
   For each PRP phase (Phase 1, 2, 3...):
   - List all deliverables (F0.1, F1.2, F2.4...)
   - List success criteria (SC-1.1, SC-1.2...)
   - Note performance targets
   - Note validation commands
   ```

3. **Generate step scripts with headers:**

   **REQUIRED STEP HEADER FORMAT:**
   ```bash
   #!/bin/bash
   # ==============================================================================
   # Step NN: [Deliverable title from PRP - VERBATIM]
   # ==============================================================================
   # PRP: [prp_id]
   # PRP Phase: [Phase N.M - Phase title]
   # PRP Deliverable: [F0.1 - Deliverable description]
   #
   # Invariants Applied:
   #   - #1 (Ambiguity): [specific application]
   #   - #7 (Validation): [specific application]
   #   - #11 (Accessibility): [specific application]
   #
   # Thinking Level: [Normal|Think|Think Hard|Ultrathink]
   # High-Attention Sections: [list if Think Hard or Ultrathink]
   #
   # Confidence: [X.X/10] ([High|Medium|Low])
   # Confidence Notes: [why this score, derived from PRP section]
   # ==============================================================================

   # === OBJECTIVE (from PRP deliverable - VERBATIM) ===
   # [Copy deliverable description exactly from PRP]

   # === ACCEPTANCE CRITERIA (from PRP success criteria - VERBATIM) ===
   # SC-N.1: [criterion text]
   # SC-N.2: [criterion text]

   # === IMPLEMENTATION ===
   ```

4. **Generate test scripts with PRP traceability:**

   **REQUIRED TEST FORMAT:**
   ```bash
   #!/bin/bash
   # ==============================================================================
   # Test NN: [Same title as step]
   # ==============================================================================
   # PRP: [prp_id]
   # PRP Phase: [Phase N.M]
   # Success Criteria Tested: SC-N.1, SC-N.2, SC-N.3
   # Invariants Verified: #7, #11
   # ==============================================================================

   source "$(dirname "$0")/test-utils.sh"

   # === PRP SUCCESS CRITERIA (VERBATIM from PRP Section 2) ===
   # SC-N.1: [exact text from PRP]
   # SC-N.2: [exact text from PRP]
   # === END PRP CRITERIA ===

   # === FILE EXISTENCE CHECKS ===
   check_file "src/app/styles/page.tsx"
   check_file "src/components/styles/style-list.tsx"

   # === CONTENT CHECKS (derived from success criteria) ===
   check "grep -q 'Style Library' src/app/styles/page.tsx" "SC-N.1: Styles heading"
   check "grep -q 'No styles yet' src/app/styles/page.tsx" "SC-N.2: Empty state"

   # === PRP VALIDATION COMMANDS (VERBATIM from PRP Appendix) ===
   # Copied from PRP Section 8 - Validation Commands
   check "npm run build" "Build passes"
   check "npx tsc --noEmit" "TypeScript strict mode"
   # === END VERBATIM ===

   # === INVARIANT #11: Accessibility Audit ===
   if command -v axe &> /dev/null; then
     check "axe http://localhost:3000/styles --exit" "Accessibility audit"
   else
     echo "  [SKIP] axe-cli not installed"
   fi

   # === PLAYWRIGHT VERIFICATION ===
   cat << 'PLAYWRIGHT_VERIFY'
   {
     "route": "/styles",
     "prp_phase": "1.3",
     "prp_criteria": ["SC-1.3.1", "SC-1.3.2"],
     "invariants": [11],
     "checks": [
       {
         "type": "heading",
         "level": 1,
         "text": "Style Library",
         "prp_ref": "SC-1.3.1",
         "comment": "Copied from PRP Success Criteria table"
       },
       {
         "type": "text",
         "text": "No styles yet",
         "prp_ref": "SC-1.3.2",
         "comment": "Empty state from PRP UI wireframe"
       },
       {
         "type": "a11y",
         "standard": "wcag21aa",
         "fail_on": ["critical", "serious"],
         "invariant_ref": 11,
         "comment": "Invariant #11 requires automated accessibility audit"
       }
     ]
   }
   PLAYWRIGHT_VERIFY

   report_results
   ```

5. **Generate gate scripts with phase aggregation:**

   **REQUIRED GATE FORMAT:**
   ```bash
   #!/bin/bash
   # ==============================================================================
   # Gate N: [Phase title from PRP]
   # ==============================================================================
   # PRP: [prp_id]
   # PRP Phase: [Phase N - title]
   # Steps Covered: step-01.sh through step-NN.sh
   # Success Criteria Aggregated: SC-N.1 through SC-N.M
   # Invariants Verified: #1, #7, #11
   # Performance Targets: [from PRP]
   # ==============================================================================

   echo "═══════════════════════════════════════════════════════════"
   echo "  GATE N: [Phase title]"
   echo "═══════════════════════════════════════════════════════════"

   FAIL=0

   # === RUN ALL PHASE TESTS ===
   for test in test-01.sh test-02.sh ... test-NN.sh; do
     echo "Running $test..."
     ./$test || FAIL=$((FAIL + 1))
   done

   # === PHASE SUCCESS CRITERIA (from PRP Section 2) ===
   echo ""
   echo "Checking phase success criteria..."

   # SC-N.1: [exact text from PRP]
   check_criterion "npm run build" "SC-N.1: Build successful"

   # SC-N.2: [exact text from PRP]
   check_criterion "npx tsc --noEmit" "SC-N.2: TypeScript passes"

   # SC-N.3: [exact text from PRP]
   check_criterion "test -f src/app/styles/page.tsx" "SC-N.3: Style page exists"

   # === PERFORMANCE TARGETS (from PRP) ===
   echo ""
   echo "Checking performance targets..."

   # PRP Target: Build <30s
   BUILD_START=$(date +%s)
   npm run build > /dev/null 2>&1
   BUILD_END=$(date +%s)
   BUILD_TIME=$((BUILD_END - BUILD_START))

   if [ $BUILD_TIME -lt 30 ]; then
     echo "  ✓ Build time: ${BUILD_TIME}s (target: <30s)"
   else
     echo "  ✗ Build time: ${BUILD_TIME}s (target: <30s)"
     FAIL=$((FAIL + 1))
   fi

   # === INVARIANT #11: Full Accessibility Audit ===
   echo ""
   echo "Running accessibility audit (Invariant #11)..."
   if command -v axe &> /dev/null; then
     axe http://localhost:3000 --exit || FAIL=$((FAIL + 1))
   fi

   # === GATE RESULT ===
   echo ""
   echo "═══════════════════════════════════════════════════════════"
   if [ $FAIL -eq 0 ]; then
     echo "  GATE N: PASSED"
     echo "  Proceed to Phase N+1"
   else
     echo "  GATE N: FAILED ($FAIL issues)"
     echo "  Fix issues before proceeding"
     exit 1
   fi
   echo "═══════════════════════════════════════════════════════════"
   ```

6. **Generate PRP-COVERAGE.md with full traceability:**

   ```markdown
   # PRP Coverage Matrix

   **PRP:** [prp_id]
   **Generated:** [date]
   **Confidence:** [X.X/10]
   **Thinking Level:** [level]

   ## Deliverable → Step Mapping

   | PRP Deliverable | Step | Test | Gate | Success Criteria |
   |-----------------|------|------|------|------------------|
   | F0.1 Sidebar nav | step-01.sh | test-01.sh | gate-1 | SC-0.1.1, SC-0.1.2 |
   | F0.2 Routes | step-02.sh | test-02.sh | gate-1 | SC-0.2.1 |
   | F1.1 Season DB | step-04.sh | test-04.sh | gate-2 | SC-1.1.1, SC-1.1.2 |

   ## Success Criteria → Test Mapping

   | Criterion | Test | Check | Status |
   |-----------|------|-------|--------|
   | SC-0.1.1: Sidebar shows LIBRARY section | test-01.sh | grep 'LIBRARY' | ○ |
   | SC-0.1.2: Sidebar shows SEASON section | test-01.sh | grep 'SEASON' | ○ |

   ## Invariant Coverage

   | Invariant | Applied In | Verification |
   |-----------|------------|--------------|
   | #1 Ambiguity | All steps | PRP criteria verbatim |
   | #7 Validation | All tests | Executable checks |
   | #11 Accessibility | All UI tests | axe-core audit |

   ## Schema Traceability

   | PRP Schema (Appendix B) | Step | Verification |
   |-------------------------|------|--------------|
   | seasons.code (TEXT UNIQUE) | step-04.sh | test-04.sh grep |
   | buyers.company_name | step-10.sh | test-10.sh grep |
   ```

7. **Generate integration tests (CUMULATIVE):**

   For each step N, generate `integration-test-NN.sh` that tests steps 1 through N working together:

   ```bash
   #!/bin/bash
   # ==============================================================================
   # Integration Test NN: Steps 1-N Working Together
   # ==============================================================================
   # Tests that all completed steps integrate correctly.
   # This is NOT a unit test - it tests the INTERFACES between components.
   #
   # Components tested:
   #   - Step 1: [component]
   #   - Step 2: [component]
   #   - ...
   #   - Step N: [component]
   #
   # Contracts verified:
   #   - [Contract 1]: [API] → [Consumer]
   #   - [Contract 2]: [Module] → [Page]
   # ==============================================================================

   echo "=== INTEGRATION TEST NN: Steps 1-N ==="

   # Test the full flow through all completed components
   # Use Playwright to navigate through the actual UI
   # Verify data flows correctly between ALL components

   cat << 'INTEGRATION_VERIFY'
   {
     "test": "integration-NN",
     "steps_covered": [1, 2, ..., N],
     "workflow": [
       {"action": "navigate", "url": "/start"},
       {"action": "perform_step_1", "verify": "output matches contract"},
       {"action": "perform_step_2", "verify": "receives step 1 output correctly"},
       ...
       {"action": "perform_step_N", "verify": "full flow completes"}
     ],
     "contracts_verified": ["Contract1", "Contract2"]
   }
   INTEGRATION_VERIFY
   ```

8. **Generate E2E smoke test:**

   Generate ONE `e2e-smoke-test.sh` that runs the complete user workflow:

   ```bash
   #!/bin/bash
   # ==============================================================================
   # E2E Smoke Test: Full User Workflow
   # ==============================================================================
   # THE ULTIMATE TEST: Does the whole system actually work?
   #
   # This test runs the COMPLETE user journey from start to finish.
   # If this test passes, the system WORKS.
   # If this test fails, something is BROKEN.
   #
   # User Journey (from PRP):
   #   1. [First user action]
   #   2. [Second user action]
   #   ...
   #   N. [Final user action - expected outcome]
   # ==============================================================================

   echo "=== E2E SMOKE TEST: Full Workflow ==="

   # Run complete user journey with Playwright
   # Every step must succeed for the test to pass

   cat << 'E2E_WORKFLOW'
   {
     "test": "e2e-smoke",
     "description": "Complete user workflow from PRP",
     "steps": [
       {"action": "login", "verify": "dashboard loads"},
       {"action": "navigate_to_feature", "verify": "feature page loads"},
       {"action": "perform_main_task", "verify": "task completes"},
       {"action": "verify_result", "verify": "expected outcome achieved"},
       {"action": "export_or_save", "verify": "data persisted correctly"}
     ],
     "success_criteria": "All steps complete without error"
   }
   E2E_WORKFLOW
   ```

9. **Generate contract definitions:**

   For each API/module, generate `contracts/[module]-contract.ts`:

   ```typescript
   // ==============================================================================
   // Contract: [module-name]
   // ==============================================================================
   // This contract defines the interface between [producer] and [consumers].
   // Breaking this contract will break: [list of consumers]
   //
   // CONSUMERS:
   //   - [consumer1.tsx]
   //   - [consumer2.ts]
   // ==============================================================================

   export interface [ModuleName]Input {
     // Input contract - what this module expects
   }

   export interface [ModuleName]Output {
     // Output contract - what this module returns
     // ALL FIELDS ARE REQUIRED unless marked optional
   }

   // Contract verification function
   export function verify[ModuleName]Contract(output: unknown): output is [ModuleName]Output {
     // Runtime verification that output matches contract
     // Used in integration tests
   }
   ```

**Output:**
```
Generated Ralph implementation:
├── ralph.sh                    # Runner script
├── ralph-results.json          # Progress tracker
├── ralph-tests/
│   ├── test-01.sh ... test-NN.sh       (unit tests)
│   ├── integration-test-01.sh ...      (cumulative integration tests)
│   ├── e2e-smoke-test.sh               (full workflow test)
│   ├── gate-1.sh ... gate-N.sh         (phase gates)
│   └── contracts/                      (contract definitions)
│       ├── extraction-contract.ts
│       ├── season-api-contract.ts
│       └── ...
└── PRP-COVERAGE.md                     (full traceability)

Total: NN steps, NN unit tests, NN integration tests, 1 E2E test, N gates
Coverage: 100% of PRP deliverables
Invariants: All referenced in headers
PRP Criteria: All mapped to tests

Next: ./ralph.sh 1  (run step 1)
```

**Quality Checks Before Output:**

Before generating output, verify:
1. ☐ Every PRP deliverable has exactly one step
2. ☐ Every success criterion appears in a test with `prp_ref`
3. ☐ Validation commands copied VERBATIM from PRP
4. ☐ Schema field names match PRP Appendix B exactly
5. ☐ Invariant numbers in all step/test headers
6. ☐ Thinking level propagated to steps
7. ☐ PLAYWRIGHT_VERIFY has prp_criteria references
8. ☐ Gates aggregate all phase success criteria
9. ☐ Performance targets from PRP in gates
10. ☐ PRP-COVERAGE.md has complete traceability

---

### /design dependency-trace {prp-file} --journey {journey-file}

Validate that all implicit dependencies have explicit deliverables. **Required before `/design implement` (INV-L010, INV-L011).**

**Purpose:** Catch gaps like "table referenced but never created" or "TODO item with no deliverable."

**Usage:**
```
/design dependency-trace ./prps/PRP-F-010.md --journey ./journeys/J-010.md
```

**What It Checks:**

1. **TODO/⏳ Items (INV-L010):**
   - Extract all `⏳|TODO|TBD|PENDING` from journey
   - Verify each has a `F*.N` deliverable in PRP

2. **Table Lineage (INV-L011):**
   - Find all `INSERT INTO|UPDATE|DELETE FROM` statements
   - Verify each table has a `CREATE TABLE` somewhere

3. **External Services:**
   - Find all endpoint/index/model references
   - Verify each has a creation/deployment deliverable

**Output:**
```
═══════════════════════════════════════════════════════════════
  DEPENDENCY TRACE - PRP-F-010
═══════════════════════════════════════════════════════════════

━━━ TODO/⏳ Items ━━━
  ✓ Vector Search index → F5.2
  ✓ Model Serving endpoint → F1.2
  ✗ pending_stakeholders table → MISSING

━━━ Table Lineage ━━━
  ✓ signals → CREATE in PRP-F-002
  ✓ graph_nodes → CREATE in PRP-F-003
  ✗ processing_logs → NO CREATE FOUND

───────────────────────────────────────────────────────────────
  STATUS: ❌ BLOCKED - 2 gaps
───────────────────────────────────────────────────────────────
```

**Blocking:** If ANY gaps found, do not proceed to `/design implement`.

---

### /design test-validate {tests-dir}

Validate generated test files before execution. **Required in TDD mode (INV-L007, INV-L008).**

Since tests are the sole contract in TDD mode, they must be validated for:
1. **Syntax correctness** - Tests compile without errors
2. **SC coverage completeness** - Every Success Criterion has a test
3. **Integration readiness** - Tests can run together as a suite

**Usage:**
```
/design test-validate ./ralph-tests-feature
/design test-validate ./ralph-tests-feature --strict
```

**What It Checks:**

1. **Syntax Validation:**
```bash
python -m py_compile test_*.py
```

2. **SC Coverage Mapping:**
```python
# Extract SC-* references from test docstrings
# Verify every SC in PRP has corresponding test
```

3. **Test Collection (pytest dry run):**
```bash
pytest --collect-only ./ralph-tests-feature
```

4. **Integration Check:**
```bash
# Verify conftest.py exists
# Verify shared fixtures work
# Verify no import conflicts
```

**Execution (inline by LLM):**

1. Read all test_*.py files in directory
2. Parse docstrings for SC-* references
3. Compare to PRP Success Criteria table
4. Report gaps and issues

**Output:**
```
═══════════════════════════════════════════════════════════════
  TEST VALIDATION (TDD Mode)
═══════════════════════════════════════════════════════════════

━━━ Syntax Check ━━━
  ✓ test_01_forecast.py - valid
  ✓ test_02_daily_ops.py - valid
  ✗ test_03_newsletter.py - SyntaxError line 45

━━━ SC Coverage ━━━
  PRP Success Criteria: 15
  Tests covering SC-*: 14
  
  MISSING:
    ✗ SC-3.2: "Response time < 2s" - no test found

━━━ Integration Check ━━━
  ✓ conftest.py exists
  ✓ pytest --collect-only: 47 tests collected
  ✓ No import conflicts

───────────────────────────────────────────────────────────────
  Status: 1 SYNTAX ERROR, 1 MISSING SC
  → Fix before proceeding to /design run
───────────────────────────────────────────────────────────────
```

**Next step:** Fix issues, then `/design test-cohesion`

---

### /design test-cohesion {tests-dir}

Validate that all tests work together as a cohesive suite. **Required after test-validate (INV-L009).**

**Purpose:** Catch suite-wide issues that individual test validation misses.

**Usage:**
```
/design test-cohesion ./ralph-tests-J-010
```

**What It Checks:**

1. **Duplicate Function Names:**
   - No two tests can have the same function name
   - Duplicates cause pytest to skip tests silently

2. **Fixture Availability:**
   - All fixtures used by tests must be defined in conftest.py
   - Missing fixtures cause collection failures

3. **Import Collisions:**
   - No conflicting imports across test files
   - Aliases must be consistent

4. **State Isolation:**
   - Warn on module-level mutable state
   - Warn on `global` keyword usage

5. **Integration Test Exists (INV-L009):**
   - Must have test_*integration*.py
   - Integration test must cover full workflow

**Execution (inline by LLM):**

1. Collect all test_*.py files
2. Parse with ast module
3. Extract function names, fixtures, imports
4. Run pytest --collect-only
5. Report issues

**Output:**
```
═══════════════════════════════════════════════════════════════
  TEST COHESION CHECK - ralph-tests-J-010
═══════════════════════════════════════════════════════════════

━━━ Test Count ━━━
  Files: 19
  Test functions: 87
  Integration test: ✓ test_16_integration.py

━━━ Duplicate Names ━━━
  ✓ No duplicates found

━━━ Fixture Analysis ━━━
  Fixtures defined: 5 (conftest.py)
  Fixtures used: 8
  ✓ All fixtures available

━━━ Import Analysis ━━━
  ✓ No collisions

━━━ State Isolation ━━━
  ⚠️ test_05.py uses module-level variable (line 15)

━━━ Suite Collection ━━━
  $ pytest --collect-only
  87 tests collected
  ✓ All tests collectable

───────────────────────────────────────────────────────────────
  STATUS: ✓ COHESIVE (1 warning)
───────────────────────────────────────────────────────────────
```

**Blocking:** If duplicates, missing fixtures, or no integration test → BLOCK.

**Next step:** `/design ralph-check`

---

### /design ralph-check {prp-file} --tests {tests-dir}

Validate generated tests against the PRP contract before execution.

**The PRP is the source of truth.** This command ensures all generated tests verify the exact field names, routes, and validation rules defined in the PRP.

**Usage:**
```
/design ralph-check ./PRPs/phase1-prp.md --steps ./ralph-steps-v3
/design ralph-check ./PRPs/auth-prp.md --steps ./ralph-steps --quick
```

**What It Checks:**

1. **Schema Compliance:**
   - Field names match PRP definitions (e.g., `aims_code` not `fabric_id`)
   - Data types align with PRP specifications
   - Constraint definitions are consistent

2. **Route Coverage:**
   - All routes defined in PRP exist in steps
   - No orphan routes in implementation

3. **Success Criteria:**
   - Steps address each success criterion in PRP
   - Measurable targets are testable

4. **Validation Rules:**
   - Business rules from PRP are implemented
   - Format validations match PRP specifications

**Execution:**

Invoke the shell script:
```bash
./enforcement/design-ops-v3.sh ralph-check "{prp-file}" --steps "{steps-dir}" [--quick]
```

**Output:**
```
═══════════════════════════════════════════════════════════════
  RALPH PRP COMPLIANCE CHECK (v3.3.0)
═══════════════════════════════════════════════════════════════

━━━ Deterministic Checks ━━━
Extracting PRP schema definitions...
  ✓ Fabrics schema found: fabric_name,aims_code,fabric_type,status

Issues (implementation doesn't match PRP):
  ✗ Steps use 'fabric_id' but PRP defines 'aims_code'
  ✗ Steps use 'description' but PRP defines 'fabric_name'

───────────────────────────────────────────────────────────────
  Status: COMPLIANCE ISSUES
  → Fix field names, routes, or validations to match PRP.
───────────────────────────────────────────────────────────────
```

**Why This Matters:**

The schema mismatches we experienced (fabric_id vs aims_code) happened because Ralph steps were generated without validating against the PRP. This check catches those issues **before** execution, not after painful debugging.

**Run this check:**
- After `/design implement` generates Ralph steps
- Before `/design run` executes any steps
- Whenever the PRP is updated

---

### /design run [--dangerous] [--max-regen N]

**EXECUTABLE PROCEDURE - FOLLOW THESE STEPS EXACTLY**

**TDD MODE (INV-L007):** In TDD mode, there are no step scripts. The AI coding agent writes implementation code to pass tests.

---

## STEP 0: IMPLEMENTATION INVARIANT PRE-CHECK (MANDATORY)

**Before ANY code changes, verify these invariants are being followed:**

```
┌─────────────────────────────────────────────────────────────────┐
│  INV-IMPL PRE-CHECK - BLOCKING GATE                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  □ INV-IMPL-004: Is this change part of a Ralph step?           │
│    → If editing code outside a defined step: STOP               │
│                                                                 │
│  □ INV-IMPL-001: Does this step modify any API/interface?       │
│    → If yes: List all consumer files that must be tested        │
│                                                                 │
│  □ INV-IMPL-002: How will you provide verification evidence?    │
│    → Define the Playwright commands you will run                │
│    → Define the elements you will check in snapshot             │
│                                                                 │
│  □ INV-IMPL-005: Check dependency map for affected consumers    │
│    → Add all consumers to verification checklist                │
│                                                                 │
│  IF ANY CHECK IS UNCLEAR → DO NOT PROCEED                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## STEP 1: LOCATE AND LOAD STATE

```
ACTION: Find ralph-tests directory and load state
```

1.1. Look for `ralph-tests-*/` in current directory (TDD mode) or `ralph-steps/` (legacy mode)
1.2. Read `ralph-state.json`
1.3. If not found: ERROR "No ralph-state.json. Run /design implement first."
1.4. Extract: `current_step`, `total_steps`, `mode`, `dev_server.port`, `dev_server.command`
1.5. Parse arguments:
    - `--dangerous` → set mode to "dangerous"
    - `--max-regen N` → set max_regenerations (default 3)

---

## STEP 2: EXECUTE THE LOOP (TDD MODE)

```
FOR step_num FROM current_step TO total_steps:
```

### 2.1 RUN TEST (EXPECT FAILURE)

```bash
pytest ralph-tests-*/test_{step_num:02d}_*.py -v
```

- If exit code == 0 (unexpected pass): Log warning, continue to 2.5
- If exit code != 0 (expected): Continue to 2.2

### 2.2 AI IMPLEMENTS CODE TO PASS TEST

Read the test file docstring for implementation instructions:
- Target file path
- Required components (endpoints, classes, functions)
- Schema requirements from PRP

**AI coding agent writes implementation code to pass the test.**

### 2.3 RUN TEST (EXPECT PASS)

```bash
pytest ralph-tests-*/test_{step_num:02d}_*.py -v
```

- Capture FULL OUTPUT (stdout + stderr)
- If exit code != 0: Go to **STEP 3: HANDLE FAILURE**
- If exit code == 0: Continue to 2.4

### 2.4 VALIDATE IMPLEMENTATION

Verify the created file:
- File exists at target path
- Contains required components from test docstring
- No syntax errors

Continue to 2.5

### 2.3 PARSE PLAYWRIGHT_VERIFY

Search test output for JSON between `PLAYWRIGHT_VERIFY` markers:

```
Extract: route, checks[]
```

- If no PLAYWRIGHT_VERIFY found: Skip to 2.5
- If found: Continue to 2.4

### 2.4 PLAYWRIGHT MCP VERIFICATION

**2.4.1 Ensure dev server running:**

```bash
Bash: curl -s http://localhost:{port} --max-time 2
```

If fails:
```bash
Bash: lsof -ti:{port} | xargs kill -9 2>/dev/null; {dev_command} &
     (run_in_background=true)
```
Wait 5 seconds, retry health check.

**2.4.2 Navigate:**

```
mcp__playwright__browser_navigate({ url: "http://localhost:{port}{route}" })
```

**2.4.3 Snapshot:**

```
mcp__playwright__browser_snapshot({})
```

**2.4.4 Verify each check:**

| Check Type | How to Verify |
|------------|---------------|
| `heading` | Find `heading` with matching `level` containing `text` |
| `button` | Find `button` containing `text` |
| `text` | Find `text` anywhere in snapshot |
| `link` | Find `link` containing `text` |
| `section` | Find section/region with `label` |
| `navigation` | Find `navigation` landmark |

**2.4.5 If ANY check fails:**

Record failure:
```json
{
  "step": {step_num},
  "check_type": "{type}",
  "expected": "{expected_text}",
  "actual": "Not found in snapshot",
  "snapshot_excerpt": "{relevant_part_of_snapshot}"
}
```

Go to **STEP 3: HANDLE FAILURE**

### 2.5 UPDATE STATE (SUCCESS) - REQUIRES EVIDENCE (INV-IMPL-002)

**BEFORE updating state, you MUST have provided verification evidence.**

```
┌─────────────────────────────────────────────────────────────────┐
│  EVIDENCE CHECKLIST - ALL REQUIRED TO CLAIM STEP COMPLETE       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ✓ Playwright snapshot was captured and shown in conversation   │
│                                                                 │
│  ✓ Expected elements were explicitly listed and confirmed:      │
│    "Verified: [element1] ✓, [element2] ✓, [element3] ✓"         │
│                                                                 │
│  ✓ If API/interface was modified (INV-IMPL-001):                │
│    → All consumer pages were tested with Playwright             │
│    → Snapshots for each consumer were shown                     │
│                                                                 │
│  IF ANY EVIDENCE IS MISSING → STEP IS NOT COMPLETE              │
│  DO NOT UPDATE STATE WITHOUT EVIDENCE                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

Update `ralph-state.json`:
```json
{
  "steps": {
    "{step_num}": {
      "status": "passed",
      "attempts": {attempts},
      "evidence": {
        "playwright_url": "{url tested}",
        "elements_verified": ["{element1}", "{element2}"],
        "consumers_tested": ["{consumer1}", "{consumer2}"] // if API change
      }
    }
  },
  "current_step": {step_num + 1}
}
```

### 2.6 RUN CUMULATIVE INTEGRATION TESTS (MANDATORY)

**After unit test passes, run ALL integration tests up to current step.**

```
┌─────────────────────────────────────────────────────────────────┐
│  CUMULATIVE INTEGRATION TEST - BLOCKING GATE                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  FOR i FROM 1 TO current_step:                                  │
│    Run integration-test-{i}.sh                                  │
│    IF FAIL → Go to STEP 3: HANDLE FAILURE                       │
│                                                                 │
│  ALL integration tests must pass before proceeding.             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

```bash
# Run all integration tests up to current step
for i in $(seq 1 {step_num}); do
  echo "Running integration-test-$(printf %02d $i).sh..."
  ./ralph-tests/integration-test-$(printf %02d $i).sh || FAIL=1
done

if [ $FAIL -eq 1 ]; then
  echo "INTEGRATION TEST FAILED - Step is NOT complete"
  exit 1
fi
```

**Why this matters:** Unit test passing means the step works in isolation. Integration test passing means it works WITH all previous steps. Both must pass.

### 2.7 RUN E2E SMOKE TEST (MANDATORY)

**After integration tests pass, run the full E2E smoke test.**

```bash
# Run E2E smoke test - the ultimate "does it actually work" check
./ralph-tests/e2e-smoke-test.sh

if [ $? -ne 0 ]; then
  echo "E2E SMOKE TEST FAILED - Something broke the full workflow"
  exit 1
fi
```

**The E2E smoke test runs the complete user journey.** If it fails, something you changed broke the overall system, even if unit and integration tests passed.

### 2.8 CHECK FOR GATE

If `ralph-steps/gate-{N}.sh` exists for completed phase:

```bash
Bash: ./ralph-steps/gate-{N}.sh
```

- **Default mode**: Ask user "Gate {N} passed. Continue? [Y/n]"
- **Dangerous mode**: Auto-continue

### 2.9 CONTINUE LOOP

Go to next step_num

---

## STEP 3: HANDLE FAILURE

**3.0 Determine failure type:**

| Failed Script | Failure Type | Retry Strategy |
|---------------|--------------|----------------|
| `step-N.sh` | Environment/setup | Often NOT fixable by code edit. Check: missing dependency? permission? If syntax error in step script itself, fix it. Otherwise STOP. |
| `test-N.sh` | Code verification | FIXABLE. The source code that step created is wrong. Fix with Edit/Write. |
| Playwright check | UI rendering | FIXABLE. The component isn't rendering correctly. Fix the source code. |

**3.1 Record attempt:**

```json
{
  "steps": {
    "{step_num}": {
      "status": "failed",
      "attempts": {attempts},
      "error": "{error_message}",
      "failure_type": "step|test|playwright"
    }
  }
}
```

**3.2 If STEP script failed:**

1. Read error message
2. If dependency/permission issue: STOP, output "Environment issue: {error}. Fix manually."
3. If syntax error in step script itself: Fix with Edit, retry
4. If unclear: STOP, wait for human

**3.3 If TEST script failed (attempts < 3):**

1. Read the step script header to understand INTENT
2. Read the error message from test output
3. Identify what source code needs fixing (not the test - test is the contract)
4. Use **Edit** or **Write** to fix the SOURCE CODE that step created
5. Increment attempts
6. Go back to 2.2 (re-run test, not step)

**3.4 If PLAYWRIGHT check failed (attempts < 3):**

1. Read the snapshot to see what's actually rendered
2. Compare to expected check
3. Fix the SOURCE CODE (component/page) to render correctly
4. Increment attempts
5. Go back to 2.4 (re-run playwright verification)

**3.5 If attempts >= 3:**

- **Default mode**:
  - STOP execution
  - Output: "Step {step_num} failed 3 times. Fix manually and run `/design run {step_num}`"

- **Dangerous mode**:
  - If regenerations < max_regenerations:
    - Record learning: what failed, why, what was tried
    - Read PRP file for the deliverable this step implements
    - Regenerate `step-N.sh` with context: "Previous attempts failed because {errors}. Generate differently."
    - NOTE: Do NOT regenerate `test-N.sh` - it's the PRP contract
    - Increment regenerations
    - Reset attempts to 0
    - Go back to 2.1
  - Else:
    - STOP: "Max regenerations ({max_regenerations}) reached"

---

## STEP 4: COMPLETION

When all steps pass:

1. Output summary:
```
═══════════════════════════════════════════════════════════
  RALPH EXECUTION COMPLETE
═══════════════════════════════════════════════════════════
Steps: {total_steps}/{total_steps} passed
Gates: {gates_passed}/{total_gates} passed
Learnings: {learnings_count} captured

Dev server running at http://localhost:{port}
```

2. Update state: `"status": "complete"`

---

## STEP 5: COMMIT GATE (INV-IMPL-003) - BEFORE ANY GIT COMMIT

**This gate is MANDATORY before running `git commit`. No exceptions.**

```
┌─────────────────────────────────────────────────────────────────┐
│  COMMIT GATE - BLOCKING CHECKPOINT                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  STEP 5.1: List all modified files                              │
│  ─────────────────────────────────────────────────────────────  │
│  Run: git status                                                │
│  Identify: ALL .ts/.tsx files that were modified                │
│                                                                 │
│  STEP 5.2: For each modified UI file (.tsx)                     │
│  ─────────────────────────────────────────────────────────────  │
│  □ What URL renders this component?                             │
│  □ Did you run Playwright on that URL?                          │
│  □ Did you paste the snapshot as evidence?                      │
│  □ Did you list elements verified?                              │
│                                                                 │
│  STEP 5.3: For each modified API/lib file (.ts)                 │
│  ─────────────────────────────────────────────────────────────  │
│  □ List all consumers of this file (grep for imports)           │
│  □ For each consumer that renders UI:                           │
│    → Did you run Playwright on that consumer's URL?             │
│    → Did you paste the snapshot as evidence?                    │
│                                                                 │
│  STEP 5.4: Evidence summary                                     │
│  ─────────────────────────────────────────────────────────────  │
│  Before committing, explicitly state:                           │
│                                                                 │
│  "COMMIT EVIDENCE:                                              │
│   - Modified: [file1.tsx, file2.ts, ...]                        │
│   - URLs tested: [/path1, /path2, ...]                          │
│   - Elements verified: [elem1, elem2, ...]                      │
│   - Consumers tested: [consumer1, consumer2, ...] (if API)      │
│   - All Playwright snapshots shown above: YES"                  │
│                                                                 │
│  IF YOU CANNOT FILL THIS IN → DO NOT COMMIT                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Anti-patterns that trigger this gate:**
- "Let me commit this real quick" → NO. Show evidence first.
- "The CLI test passed" → NOT ENOUGH. UI verification required.
- "I tested it earlier" → Show the snapshot NOW or don't commit.

---

## STEP 6: INTEGRATION TESTING (INV-IMPL-001) - AFTER EACH STEP

**Integration tests run AFTER unit tests pass, BEFORE claiming step complete.**

```
┌─────────────────────────────────────────────────────────────────┐
│  INTEGRATION TEST FLOW                                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Unit Test (step test)                                          │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────┐                                                │
│  │ PASS?       │──NO──► Fix code, retry unit test               │
│  └─────────────┘                                                │
│       │ YES                                                     │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ INTEGRATION CHECK: Did this step modify shared code?    │    │
│  │                                                         │    │
│  │ Shared code = APIs, interfaces, lib functions, types    │    │
│  └─────────────────────────────────────────────────────────┘    │
│       │                                                         │
│       ├──NO──► Skip to Step Complete                            │
│       │                                                         │
│       ▼ YES                                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ FIND ALL CONSUMERS:                                     │    │
│  │                                                         │    │
│  │ grep -r "import.*{modified_file}" --include="*.tsx"     │    │
│  │                                                         │    │
│  │ List every file that imports the modified code          │    │
│  └─────────────────────────────────────────────────────────┘    │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ FOR EACH CONSUMER:                                      │    │
│  │                                                         │    │
│  │ 1. What URL does this consumer render?                  │    │
│  │ 2. Run Playwright: navigate to URL                      │    │
│  │ 3. Run Playwright: capture snapshot                     │    │
│  │ 4. Verify: page loads without error                     │    │
│  │ 5. Verify: expected elements present                    │    │
│  │                                                         │    │
│  │ If ANY consumer fails → FIX before claiming complete    │    │
│  └─────────────────────────────────────────────────────────┘    │
│       │                                                         │
│       ▼                                                         │
│  Step Complete (with evidence for all consumers)                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Example - What Should Have Happened:**

```
Step: Update extract-with-style-master.ts (change items[] format)

Unit Test: CLI extraction test
  → PASS: JSON output looks correct

Integration Check: Is this shared code?
  → YES: It's a lib function used by API routes

Find Consumers:
  → grep -r "extract-with-style-master" --include="*.ts" --include="*.tsx"
  → Found: /api/extract-design-notes/route.ts
  → Found: (route is consumed by) /seasons/import-photo/page.tsx

Integration Test Each Consumer:
  → Navigate to /seasons/import-photo
  → Upload image, click Extract
  → Capture snapshot
  → Verify: "Step 2: Review Extracted Fabrics" appears
  → Verify: Fabric cards render with style badges
  → FAIL: Page crashed - items.map is not a function

Fix: Update page.tsx to use new items[] format
Re-run Integration Test: PASS

NOW step is complete.
```

**The Rule:** Unit test passing is NOT enough. If you changed shared code, you MUST integration test all consumers with Playwright.

---

## QUICK REFERENCE

| Situation | Action |
|-----------|--------|
| Unit test fails | Read error, fix source code, retry |
| Integration test fails | Something broke between components - check contracts |
| E2E smoke test fails | Full workflow broken - trace through each step |
| Playwright check fails | Read snapshot, fix UI code, retry |
| 3 failures (default) | Stop, wait for human |
| 3 failures (dangerous) | Regenerate from PRP |
| Gate reached (default) | Ask approval |
| Gate reached (dangerous) | Auto-continue |
| **API/lib modified** | **Find consumers, Playwright test each** |
| **Claiming step done** | **Must have snapshot evidence** |
| **Before git commit** | **Run COMMIT GATE checklist** |
| **Contract change** | **Update all consumers, run integration tests** |

## Test Hierarchy (ALL MUST PASS)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  1. UNIT TEST (test-NN.sh)                                      │
│     Does this step work in isolation?                           │
│     └─► PASS required to continue                               │
│                                                                 │
│  2. CONTRACT VERIFICATION                                       │
│     Does output match defined contract?                         │
│     └─► PASS required to continue                               │
│                                                                 │
│  3. INTEGRATION TESTS (integration-test-01..NN.sh)              │
│     Do all completed steps work TOGETHER?                       │
│     └─► ALL must PASS to continue                               │
│                                                                 │
│  4. E2E SMOKE TEST (e2e-smoke-test.sh)                          │
│     Does the complete user workflow still work?                 │
│     └─► PASS required to claim step complete                    │
│                                                                 │
│  ALL FOUR LEVELS MUST PASS BEFORE STEP IS COMPLETE              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

### Devcontainer Integration

**Setup (one-time, human):**
```bash
# Enter devcontainer
devcontainer exec --workspace-folder . bash

# Login to Claude
claude login
```

**Runner script (`ralph-runner.sh`):**
```bash
#!/bin/bash
# Ralph runner for devcontainers - executes in dangerous mode

PRP_PATH="${1:-./docs/plans/*.prp.md}"
MAX_REGEN="${2:-3}"

echo "Starting Ralph v2 in dangerous mode..."
claude --dangerously-skip-permissions \
  -p "/design run --dangerous --max-regen $MAX_REGEN"
```

---

### Two-Tier Learning System

| Level | Scope | Storage | Example |
|-------|-------|---------|---------|
| **Local** | This project | `ralph-state.json`, `LEARNINGS.md` | "Providence has non-standard YAML" |
| **Invariant** | All future PRPs | `learned-invariants.md` | "Always use python3 not python" |

**Promotion flow:**
```
Local learning captured
       │
       ▼
Human reviews (default) / auto-flag (dangerous)
       │
       ▼
If systemic → promote to invariant
       │
       ▼
Future /design implement references invariant
```

---

### Learning Review & Promotion

**Default mode:** Human reviews learnings after execution:

```
/design learnings review
```

Output:
```
╔═══════════════════════════════════════════════════════════════╗
║  LEARNING REVIEW                                              ║
╚═══════════════════════════════════════════════════════════════╝

Found 3 learning(s) to review:

[L4-1] Step 4 (Phase 1 - Data Loaders)
    python: command not found - use python3 in bash scripts

[L7-1] Step 7 (Phase 3 - Meeting Prep)
    grep interprets --pattern as flag - use grep -- "$pattern"

[L9-1] Step 9 (Phase 4 - Integration)
    YAML parse errors in Obsidian files - need defensive parsing

Options: [A]ccept  [R]eject  [P]romote to invariant
```

**Dangerous mode:** Auto-accepts local learnings, flags potential invariants for later review.

**Promote to invariant:**
```
/design learnings promote L4-1
```

Creates entry in `learned-invariants.md`:
```markdown
### INV-001

**Source:** SA Assistant / Step 4 (Phase 1)
**Date:** 2026-01-23

**Rule:** Always use python3 not python in shell scripts

**Context:** macOS bash doesn't have python in PATH by default

**Prevention:** In test-utils.sh and gate scripts, use python3 -c not python -c
```

**Output (success):**
```
═══════════════════════════════════════════════════════
  STEP 5: Create design system CSS
═══════════════════════════════════════════════════════

Executing step-05.sh...
✓ Step executed

Running test-05.sh...
✓ All checks passed (12/12)

Playwright verification /...
  ✓ heading[1]: "SA DASHBOARD"
  ✓ section: "KEY METRICS"
✓ Playwright: 2/2 checks passed

✓ Step 5 PASSED → Proceeding to Step 6
```

**Output (failure with fix):**
```
═══════════════════════════════════════════════════════
  STEP 5 - ATTEMPT 2/3
═══════════════════════════════════════════════════════

Previous error: TypeError: calculate_health is not defined
Analysis: Missing import in health_calculator.py
Fix: Adding import statement...

Re-running test-05.sh...
✓ All checks passed

✓ Step 5 PASSED (fixed on retry)
Learning captured: "health_calculator needs explicit imports"
```

---

### /design verify {route} [--checks "check1,check2"]

Run Playwright MCP verification for a specific route.

**Usage:**
```
/design verify /styles
/design verify /fabrics/import --checks "heading:Import Fabrics,button:Upload"
/design verify /login --screenshot
```

**Execution:**

The agent executes actual Playwright MCP tools:

1. **Start dev server if needed:**
   ```bash
   curl -s http://localhost:3000 > /dev/null 2>&1 || (cd {app-dir} && npm run dev &)
   ```

2. **Navigate to route:**
   ```javascript
   mcp__playwright__browser_navigate({ url: "http://localhost:3000{route}" })
   ```

3. **Capture snapshot:**
   ```javascript
   mcp__playwright__browser_snapshot({})
   ```

4. **Parse and verify:**
   - Extract text content from snapshot
   - Check for expected elements
   - Verify accessibility tree
   - Report findings

**Verification Types:**

| Type | Example | What it checks |
|------|---------|----------------|
| `heading` | `heading:Style Library` | H1-H6 with exact text |
| `button` | `button:Import` | Button with text/label |
| `link` | `link:View Details` | Link with text |
| `text` | `text:No styles yet` | Any text content |
| `input` | `input:Search` | Input with label/placeholder |
| `form` | `form:Login` | Form with accessible name |
| `table` | `table:Styles` | Table with caption/label |
| `a11y` | `a11y:no-violations` | Accessibility audit |

**Output:**
```
═══════════════════════════════════════════════════════
  PLAYWRIGHT VERIFICATION: /styles
═══════════════════════════════════════════════════════

Navigation: http://localhost:3000/styles
Status: Page loaded successfully

Checks:
  ✓ heading: "Style Library" found
  ✓ button: "Import Styles" found (admin only)
  ✓ text: "No styles yet" found (empty state)
  ✓ a11y: No critical violations

Summary: 4/4 checks passed

Snapshot saved: /tmp/verify-styles-2026-01-20.md
═══════════════════════════════════════════════════════
```

**Screenshot Mode:**

With `--screenshot`, also captures visual screenshot:
```javascript
mcp__playwright__browser_take_screenshot({ filename: "verify-{route}.png" })
```

---

### /design gate [gate-number]

Run a validation gate checkpoint.

**Usage:**
```
/design gate 1        # Run gate 1
/design gate          # Run next pending gate
```

**Execution:**

1. **Aggregate checks from PRP phase:**
   - Build verification
   - TypeScript strict mode
   - Phase-specific file checks
   - Performance targets
   - Accessibility audit

2. **Report results:**
   - Pass/fail for each criterion
   - Overall gate status
   - Next steps

**Output:**
```
═══════════════════════════════════════════════════════
  GATE 1: Foundation Setup
═══════════════════════════════════════════════════════

[PASS] Build successful (exit code 0)
[PASS] TypeScript passes (0 errors)
[PASS] All 6 auth files present
[PASS] Database schema with RLS
[PASS] Dashboard with role-based sidebar

═══════════════════════════════════════════════════════
  GATE 1 RESULTS: 5/5 PASSED
═══════════════════════════════════════════════════════

STATUS: GATE PASSED
Proceed to Phase 2: Authentication & Permissions
```

---

### /design status

Show current Ralph implementation progress.

**Usage:**
```
/design status
```

**Output:**
```
Ralph Implementation Status
===========================

PRP: PRPs/phase1-foundation-prp.md
Progress: 12/25 steps (48%)

Completed Steps:
  ✓ 1-8: Foundation Setup
  ✓ 9-12: Authentication

Current Step: 13 (Dashboard layout)
Status: Failed (attempt 2/3)
Last Error: Component not found

Gates:
  ✓ Gate 1: Foundation (passed)
  ○ Gate 2: Auth & Permissions (pending)
  ○ Gate 3: Style Management (pending)
  ○ Gate 4: Fabric Management (pending)

Next action: Fix step 13, then run: /design run 13
```

---

## Workflow Integration

### Complete Design Ops Flywheel

```
         ┌───────────────────────────────────────────────┐
         │                                               │
         ▼                                               │
    [Journey / Intent / Problem Statement]               │
         │                                               │
         ▼                                               │
┌─────────────────────┐     ISSUES                       │
│   /design prp       │ ────────────────┐                │
│   (journey → PRP)   │                 │                │
│   validates inline  │                 ▼                │
└─────────────────────┘       ┌─────────────────┐        │
         │                    │   Clarify intent │        │
         │ PASS               │   (fix issues)   │        │
         │                    └─────────────────┘        │
         │                              │                │
         │◄─────────────────────────────┘                │
         │                                               │
         ▼                                               │
┌─────────────────────┐                                  │
│   Human Review      │                                  │
│   (approve PRP)     │                                  │
└─────────────────────┘                                  │
         │                                               │
         ▼                                               │
┌─────────────────────┐                                  │
│ /design implement   │                                  │
│ (generate Ralph)    │                                  │
└─────────────────────┘                                  │
         │                                               │
         ▼                                               │
┌─────────────────────┐                                  │
│   /design run       │◄──────────┐                      │
│   (atomic steps)    │           │                      │
└─────────────────────┘           │                      │
         │                        │ retry                │
         ▼                        │ (with error context) │
┌─────────────────────┐           │                      │
│   Test + Verify     │───FAIL────┘                      │
│   (Playwright MCP)  │                                  │
└─────────────────────┘                                  │
         │ PASS                                          │
         ▼                                               │
┌─────────────────────┐                                  │
│   /design gate      │                                  │
│   (checkpoint)      │                                  │
└─────────────────────┘                                  │
         │                                               │
         ▼                                               │
┌─────────────────────┐                                  │
│ /design review      │                                  │
│ (compliance check)  │                                  │
└─────────────────────┘                                  │
         │                                               │
         │ Gap found?                                    │
         │                                               │
         ▼                                               │
┌─────────────────────┐                                  │
│   Spec Delta        │ ─────────────────────────────────┘
│   (new invariant)   │
└─────────────────────┘
```

---

## Error Handling

### Validation Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `Spec file not found` | Invalid path | Check file path, use absolute path |
| `Invariants file not found` | Missing system-invariants.md | Ensure DesignOps structure exists |
| `Domain file not found` | Invalid domain reference | Check domain file path |
| `VIOLATION: Invariant #N` | Spec violates invariant | Follow fix suggestion in output |

### PRP Generation Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `Spec has N violations` | Validation failed | Run `/design validate` and fix issues |
| `Template not found` | Invalid template name | Use: base, api-integration, user-feature, data-migration |
| `Cannot detect project type` | Ambiguous spec | Specify `--template` explicitly |

### Review Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `Implementation path not found` | Invalid directory | Check path exists |
| `No spec requirements found` | Malformed spec | Ensure spec has bullet points or criteria |
| `CONVENTIONS.md not found` | No conventions defined | Create CONVENTIONS.md or use `--skip-conventions` |

---

## Dependencies

### Path Resolution

**IMPORTANT**: All paths are relative to this skill file's location (`design.md`).

When executing commands, resolve the DesignOps root directory as:
- The directory containing this `design.md` file
- Or use `$DESIGNOPS_ROOT` environment variable if set

```
{DESIGNOPS_ROOT}/           ← Directory containing this skill file
├── design.md               ← This skill file
├── enforcement/            ← Shell scripts
├── templates/              ← PRP templates
├── domains/                ← Domain invariant files
└── system-invariants.md    ← Core invariants
```

### Required Scripts

**Located at `{DESIGNOPS_ROOT}/enforcement/`:**

| Script | Purpose | Commands Implemented |
|--------|---------|---------------------|
| `design-ops-v3.sh` | **Main pipeline script** | stress-test, validate, generate, check, ralph-check |

**Note:** The following are archived/legacy (functionality now in design-ops-v3.sh):
- `validator.sh` → use `design-ops-v3.sh validate`
- `spec-to-prp.sh` → use `design-ops-v3.sh generate`
- `prp-checker.sh` → use `design-ops-v3.sh check`
- `confidence-calculator.sh` → called internally by generate

**Located at `{DESIGNOPS_ROOT}/agents/`:**

| Script | Purpose | Direct Use |
|--------|---------|------------|
| `spec-analyst.sh` | Analyze spec completeness | `./spec-analyst.sh <spec> --domain <domain>` |
| `validator.sh` | Domain invariant validation | `./validator.sh <spec> --domain <domain>` |
| `prp-generator.sh` | Generate PRP from analysis | `./prp-generator.sh <spec> --analysis <file> --validation <file>` |
| `reviewer.sh` | Review PRP quality | `./reviewer.sh <prp>` |
| `retrospective.sh` | Extract learnings | `./retrospective.sh <prp> --outcome "<summary>"` |

**Located at `{DESIGNOPS_ROOT}/tools/`:**

| Script | Purpose | Direct Use |
|--------|---------|------------|
| `multi-agent-orchestrator.sh` | Full pipeline coordination | `./multi-agent-orchestrator.sh --spec <file> --domain <domain>` |
| `watch-mode.sh` | Real-time spec monitoring | `./watch-mode.sh --spec <file> --domain <domain>` |
| `continuous-validator.sh` | Background validation service | `./continuous-validator.sh start|stop|status` |
| `validation-dashboard.sh` | Terminal dashboard | `./validation-dashboard.sh` |
| `spec-delta-to-invariant.sh` | Extract invariants from retrospectives | `./spec-delta-to-invariant.sh <retro>` |

### Required Files

| File | Location | Purpose |
|------|----------|---------|
| `system-invariants.md` | `{DESIGNOPS_ROOT}/` | Core invariant definitions |
| `prp-base.md` | `{DESIGNOPS_ROOT}/templates/` | Base PRP template |
| `thinking-level-rubric.md` | `{DESIGNOPS_ROOT}/templates/` | Thinking level quick reference |
| `validation-commands-library.md` | `{DESIGNOPS_ROOT}/templates/` | Reusable validation commands |
| `retrospective-template.md` | `{DESIGNOPS_ROOT}/templates/` | Post-implementation retro template |
| Domain files | `{DESIGNOPS_ROOT}/domains/` | Domain-specific invariants |

### Pattern Examples

| Pattern | Location | Use Case |
|---------|----------|----------|
| `api-client.md` | `{DESIGNOPS_ROOT}/examples/` | API integration, HTTP clients, retries |
| `error-handling.md` | `{DESIGNOPS_ROOT}/examples/` | Error hierarchy, Result types, circuit breakers |
| `database-patterns.md` | `{DESIGNOPS_ROOT}/examples/` | Repository pattern, transactions, pooling |
| `config-loading.md` | `{DESIGNOPS_ROOT}/examples/` | Env vars, validation, secrets |
| `test-fixtures.md` | `{DESIGNOPS_ROOT}/examples/` | Factories, mocks, test isolation |

### Documentation

| Doc | Location | Purpose |
|-----|----------|---------|
| `multi-agent-architecture.md` | `{DESIGNOPS_ROOT}/docs/` | Agent coordination design |
| `thinking-levels.md` | `{DESIGNOPS_ROOT}/docs/` | When to use Think/Think Hard/Ultrathink |

### Configuration

| File | Location | Purpose |
|------|----------|---------|
| `watch-config.yaml` | `{DESIGNOPS_ROOT}/config/` | Watch mode and agent configuration |

### Available Domains

| Domain | File | Use When |
|--------|------|----------|
| Consumer Product | `consumer-product.md` | Mobile apps, web apps, user-facing features |
| Physical Construction | `physical-construction.md` | Buildings, infrastructure, materials |
| Data Architecture | `data-architecture.md` | Pipelines, warehouses, analytics |
| Integration | `integration.md` | APIs, webhooks, third-party services |
| Remote Management | `remote-management.md` | Projects managed from distance |
| Skill Gap Transcendence | `skill-gap-transcendence.md` | New tech, learning-intensive projects |

---

## Configuration

### Project Configuration (.designops)

```yaml
# .designops - Project-level Design Ops configuration
project: my-project
domain: consumer-product
additional_domains:
  - integration

paths:
  specs: docs/design/specs
  prps: docs/design/PRPs
  deltas: docs/design/deltas
  conventions: CONVENTIONS.md

validation:
  strict: true  # Treat warnings as errors

templates:
  default: user-feature
```

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `CLAUDE_MODEL` | `claude-sonnet-4-20250514` | Model for all LLM calls |
| `PIPELINE_STATE_DIR` | `~/.design-ops-state` | Directory for inter-command state files |
| `DESIGN_OPS_BASE` | `~/.claude/plugins/design-ops` | Root directory for invariants, domains, templates |
| `DESIGNOPS_STRICT` | `0` | Set to `1` to treat warnings as errors |

**Example: Use a different model:**
```bash
CLAUDE_MODEL=claude-opus-4-20250514 ./enforcement/design-ops-v3.sh generate spec.md
```

**Example: Custom state directory:**
```bash
PIPELINE_STATE_DIR=/tmp/design-ops ./enforcement/design-ops-v3.sh stress-test spec.md
```

---

### Pipeline State

Commands share findings via JSON state files for continuity:

**Location:** `~/.design-ops-state/{spec-basename}.state.json`

**How it works:**
```
stress-test  →  Saves: invariant_violations, missing_coverage, critical_blockers
     ↓
validate     →  Saves: ambiguity_flags, implicit_assumptions
     ↓
generate     →  Reads previous findings (influences confidence calculation)
     ↓
check        →  Reads all previous findings for context
```

**State file structure:**
```json
{
  "stress-test": {
    "timestamp": "2026-01-21T10:30:00Z",
    "findings": {
      "invariant_violations": ["#4: delete without undo"],
      "critical_blockers": ["Max file size not specified"]
    }
  },
  "validate": {
    "timestamp": "2026-01-21T10:35:00Z",
    "findings": {
      "ambiguity_flags": ["'handle errors properly' - what is properly?"]
    }
  }
}
```

**Clear state for a spec:**
```bash
rm ~/.design-ops-state/my-spec.state.json
```

**Clear all state:**
```bash
rm -rf ~/.design-ops-state/
```

---

## Examples

### Example 1: New Feature Project

```
User: "/design init checkout-optimization"

→ Creates folder structure
→ Initializes templates
→ Provides next steps

User: "Here's my spec for the checkout flow..."
[Creates spec in docs/design/specs/checkout-v2.md]

User: "/design validate docs/design/specs/checkout-v2.md --domain consumer-product"

→ Checks universal invariants (1-10)
→ Checks consumer product invariants (11-15)
→ Reports 1 warning about loading states

User: "/design prp docs/design/specs/checkout-v2.md"

→ Validates (PASS with warning)
→ Auto-detects user-feature template
→ Generates PRP with 18 placeholders
→ Quality score: 78/100
```

### Example 2: House Construction

```
User: "/design init kuberan-house --domain physical-construction"

→ Creates structure with construction-specific templates
→ Notes domain invariants 16-21 will apply

User: "/design validate specs/foundation.md --domain physical-construction --domain remote-management"

→ Checks universal + construction + remote management invariants
→ FAIL: Invariant #17 (Vendor Capabilities) - contractor without verification
→ FAIL: Invariant #31 (Independent Inspection) - no third-party verification

User: [Fixes spec]

User: "/design validate specs/foundation.md --domain physical-construction --domain remote-management"

→ PASS (2 warnings about climate consideration)
```

### Example 3: API Integration Review

```
User: "/design review specs/stripe-integration.md ./src/payments/"

→ Loads spec requirements
→ Scans implementation
→ Runs test suite
→ Checks rate limiting, idempotency, error handling
→ Reports: 4/5 requirements implemented
→ Missing: circuit breaker implementation
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.5 | 2026-02-17 | **Red Team Pass (Devil's Advocate).** `/design prp` now auto-runs an adversarial review after generating the PRP. 7 red team questions check for missing failure paths, build order issues, hidden assumptions, ambiguity, edge cases, UX gaps, and over-engineering. BLOCKING findings stop the pipeline. Findings appended as `## Holes & Risks` section in PRP. |
| 2.4 | 2026-02-17 | **Journey → PRP direct path.** Specs are now optional (Deliberate Path only). `/design prp` accepts journeys, descriptions, or specs directly. Validation and stress-testing built into PRP generation. Streamlined pipeline from 11 steps to 8 for the common case. |
| 2.3 | 2026-01-29 | **Implementation Enforcement Invariants** - Added INV-IMPL-001 through INV-IMPL-005 to prevent Claude Code shortcuts. Added mandatory integration testing after API changes. Added commit gate with evidence requirements. Added explicit "show your work" proof requirements for Playwright verification. |
| 2.2 | 2026-01-22 | Added `/design spec` for journey-to-spec generation, unified workflow |
| 2.1 | 2026-01-20 | Ralph Methodology for atomic implementation (implement, run, gate, status commands) |
| 2.0 | 2026-01-19 | Multi-agent architecture, continuous validation, examples library, thinking levels |
| 1.0 | 2026-01-19 | Initial release with validate, prp, review, report commands |

---

## Quick Reference

| Command | Purpose | Key Output |
|---------|---------|------------|
| `/design init {name}` | Bootstrap project | Folder structure + templates |
| `/design prp {journey\|desc\|spec}` | **Generate PRP (primary entry point)** | Compiled PRP + quality score |
| `/design spec {journey}` | *(optional)* Think through approach | Structured spec with FRs |
| `/design stress-test {spec}` | *(optional)* Check completeness | Invariant violations, gaps |
| `/design validate {spec}` | *(optional)* Check clarity | PASS/FAIL + fix suggestions |
| `/design check {prp}` | Verify PRP ready | Extraction completeness |
| `/design implement {prp}` | Generate Ralph steps | Atomic steps + tests + gates |
| `/design ralph-check {prp}` | Verify steps match PRP | Schema/route compliance |
| `/design run [step]` | Execute with retry | Step result + progress |
| `/design gate [n]` | Phase checkpoint | Gate pass/fail |
| `/design verify {route}` | Playwright verification | UI element checks |
| `/design status` | Implementation progress | Steps + gates status |
| `/design learnings review` | Review captured learnings | Accept/Reject/Promote |
| `/design review {spec} {impl}` | Check compliance | Coverage report |
| `/design report {project}` | Status overview | Metrics + recommendations |
| `/design orchestrate {spec}` | Full pipeline | Analysis → PRP → Review |
| `/design watch {spec}` | Live monitoring | Real-time confidence |
| `/design dashboard` | System health | All specs status |
| `/design continuous start` | Background service | Continuous validation |
| `/design retrospective {prp}` | Extract learnings | Retro + invariant proposals |
| `/design freshness` | Methodology check | Update recommendations |

---

*Skill version: 2.5*
*Last updated: 2026-02-17*
*Enforcement tools: validator.sh v1.1, spec-to-prp.sh v1.1, prp-checker.sh v1.0*
*Multi-agent system: spec-analyst, validator, prp-generator, reviewer, retrospective*
*Continuous validation: watch-mode, continuous-validator, validation-dashboard*
*Implementation: Ralph Methodology v1.0*
*Implementation Enforcement: INV-IMPL-001 through INV-IMPL-005 (Claude Code anti-shortcut invariants)*

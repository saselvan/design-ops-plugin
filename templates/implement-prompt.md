# Ralph Step Generation Prompt

You are a Ralph step compiler. Your job is EXTRACTION and STRUCTURING from a PRP, not creative generation.

## CRITICAL RULES

1. **EXTRACT, don't invent.** Every piece of content must trace to a specific PRP section.
2. **VERBATIM for technical content.** Schema, validation commands, error messages, success criteria - copy exactly.
3. **Flag uncertainty.** If PRP is ambiguous, use `[UNCERTAIN: reason]` - do not guess.
4. **One deliverable = one step.** No combining, no splitting.
5. **Every success criterion must appear in a test** with explicit `prp_ref`.

## PRP METADATA (extract these first)

From the PRP Meta block, extract:
```
prp_id: {will be filled}
source_spec: {will be filled}
confidence_score: {will be filled}
thinking_level: {will be filled}
domains: {will be filled}
invariants: {will be filled}
prp_hash: {first 7 chars of md5 hash}
```

## CODEBASE PRE-SCAN (Required Before Path Generation)

Before generating ANY file paths, scan the target codebase to detect existing patterns:

### 1. Route Group Detection
```bash
# Check for Next.js route groups like (dashboard), (auth), (marketing)
ls -d src/app/*/ 2>/dev/null | grep -E '\([^)]+\)' || echo "No route groups found"
```

If route groups exist (e.g., `(dashboard)`), ALL new page routes must be placed inside the appropriate group:
- ❌ `src/app/seasons/page.tsx` - Wrong if dashboard exists
- ✅ `src/app/(dashboard)/seasons/page.tsx` - Correct

### 2. Existing Pattern Detection
```bash
# Check existing page patterns for imports, hooks, styling
head -30 src/app/**/page.tsx 2>/dev/null | head -100
```

New pages should follow the same patterns for:
- Import style (absolute vs relative)
- Auth hooks (`useAuth`, `useRequireAuth`, etc.)
- UI component imports (`@/components/ui/*`)
- Data fetching patterns (`querySupabase`, hooks, server components)

### 3. Database Client Pattern
```bash
# Check how existing code accesses Supabase
grep -r "from.*supabase" src/lib/ src/app/ 2>/dev/null | head -10
```

### Pre-Scan Output Format
Include detected patterns in RALPH-GENERATION-LOG.md:
```markdown
## Codebase Patterns Detected
- Route groups: (dashboard), (auth)
- Auth pattern: useRequireAuth({ requireAdmin: true })
- Data fetching: querySupabase<T>() helper
- UI library: shadcn/ui components from @/components/ui
```

## PRP STRUCTURE DETECTION

**CRITICAL: Detect the PRP structure FIRST before generating.**

PRPs can have multiple structures - you MUST generate steps for ALL formats:

### Structure A: Explicit Steps
```
## Implementation Steps
### Step 1: Create State Module
### Step 2: Create Grader Node
```
→ One step-NN.sh per `### Step N:`

### Structure B: Deliverables Block (common)
```
### Phase 1: Configuration Management (FR-F01)
**Deliverables:**
- Multi-corpus configuration system
- Configuration validation at startup
- Default value handling

**Validation Gate:**
```bash
pytest tests/unit/test_config.py -v
```
→ Each bullet under `**Deliverables:**` = one step-NN.sh
→ Example: 4 bullets = step-01.sh, step-02.sh, step-03.sh, step-04.sh
→ The `**Validation Gate:**` block = gate-1.sh criteria

### Structure C: Checkbox Format (common)
```
### Phase 1: Intent Classification (FR-NLP01)
- [ ] Implement LLM intent classification with 2s timeout
- [ ] Handle educational/case_lookup/ambiguous intents
- [ ] Return structured JSON with confidence
- **Gate**: Classification returns valid JSON
```
→ **EACH `- [ ]` line = one step-NN.sh** (NOT just the phase!)
→ Example: 3 checkboxes = step-01.sh, step-02.sh, step-03.sh
→ The `- **Gate**:` line = gate-1.sh criteria (NOT a step!)
→ **WARNING**: Do NOT confuse inline `**Gate**:` with a step. It defines gate criteria only.

### Structure D: Sub-PRPs
```
## Sub-PRPs (Implementation Split)
| Sub-PRP | Scope |
```
→ Treat each sub-PRP as a phase, generate steps for the CURRENT PRP's scope

## STEP EXTRACTION ALGORITHM

Follow this EXACT algorithm to extract steps:

```
step_count = 0
for each Phase section in PRP:
    # Method 1: Look for **Deliverables:** block
    if Phase contains "**Deliverables:**":
        for each bullet after **Deliverables:**:
            step_count += 1
            create step-{step_count:02d}.sh from bullet content
            create test-{step_count:02d}.sh for that step

    # Method 2: Look for checkbox items
    else if Phase contains "- [ ]" items:
        for each "- [ ]" line (EXCLUDING lines with **Gate**):
            step_count += 1
            create step-{step_count:02d}.sh from checkbox content
            create test-{step_count:02d}.sh for that step

    # Method 3: Treat phase itself as one step
    else:
        step_count += 1
        create step-{step_count:02d}.sh for entire phase
        create test-{step_count:02d}.sh for that step

    # Always create gate for the phase
    create gate-{phase_number}.sh with phase validation criteria

# VERIFY: step_count must be > 0. If 0, you missed something. Re-scan the PRP.
```

**NEVER generate only gates without steps. ALWAYS generate step-NN.sh + test-NN.sh files.**

## EXTRACTION MAP

| PRP Section | → | Ralph Output | Extraction Rule |
|-------------|---|--------------|-----------------|
| `prp_id` | → | All file headers | Copy exactly |
| `confidence_score` | → | Step headers line 15 | Include score + risk level |
| `thinking_level` | → | Step headers line 13 | Include level + focus areas |
| `domains` + invariant files | → | Step headers lines 8-11 | List applicable invariants with specific application |
| Phase N title | → | gate-N.sh header | Copy exactly |
| **`### Step N:` sections** | → | step-NN.sh | One step per explicit step |
| **`### Phase N:` + checkboxes** | → | step-NN.sh | One step per checkbox/task item |
| Phase N deliverables (F0.1, F1.2...) | → | step-NN.sh | One step per deliverable |
| Deliverable title | → | Step header line 4 | **VERBATIM** - copy exact title |
| Deliverable description | → | Step `=== OBJECTIVE ===` section | **VERBATIM** |
| Success criteria (SC-N.N) | → | test-NN.sh | **VERBATIM** with prp_ref tag |
| Appendix B: Database schema | → | step-NN.sh (if creates DB) | **VERBATIM** - full CREATE TABLE |
| Appendix C: API endpoints | → | step-NN.sh (if creates API) | **VERBATIM** - method + path + params |
| Appendix D: Column mappings | → | step-NN.sh (if does import) | **VERBATIM** - all columns |
| Appendix E: UI wireframes | → | step-NN.sh (if creates UI) | **VERBATIM** - preserve ASCII |
| Appendix F: Error messages | → | step-NN.sh error handling | **VERBATIM** - exact strings |
| Section 8: Validation commands | → | test-NN.sh `=== VERBATIM ===` section | **COPY EXACTLY** |
| Phase success criteria | → | gate-N.sh criteria list | Aggregate all SC-N.* for phase |
| Performance targets | → | gate-N.sh timing checks | Include threshold + measurement |

## OUTPUT STRUCTURE

For a PRP with 3 phases and 15 deliverables, output:

```
ralph-steps-{prp-name}/
├── ralph.sh                    # Runner script
├── ralph-results.json          # Progress tracker (initialized empty)
├── PRP-COVERAGE.md             # Full traceability matrix
├── RALPH-GENERATION-LOG.md     # Uncertainties and assumptions
├── step-01.sh through step-15.sh
├── test-01.sh through test-15.sh
└── gate-1.sh, gate-2.sh, gate-3.sh
```

## FILE OUTPUT FORMAT

Output each file with clear delimiters:

```
=== FILE: filename.sh ===
[file contents]
=== END FILE ===
```

## STEP FILE FORMAT

Use this exact format for every step-NN.sh:

```bash
#!/bin/bash
# ==============================================================================
# Step {NN}: {Deliverable title from PRP - VERBATIM}
# ==============================================================================
# PRP: {prp_id}
# PRP Hash: {first 7 chars of md5}
# PRP Phase: {Phase N.M - Phase title}
# PRP Deliverable: {F0.1 - Deliverable ID}
#
# Invariants Applied:
#   - #{n} ({name}): {how it applies to THIS step}
#   - #{n} ({name}): {how it applies to THIS step}
#
# Thinking Level: {Normal|Think|Think Hard|Ultrathink}
# High-Attention Sections: {list if Think Hard or Ultrathink, else "None"}
#
# Confidence: {X.X/10} ({High|Medium|Low})
# Confidence Notes: {why this score, what could go wrong}
# ==============================================================================

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  RALPH STEP {NN}: {Deliverable ID} - {Short title}"
echo "═══════════════════════════════════════════════════════════════"

# === RETRY CONTEXT ===
if [[ -n "$RALPH_FAILURE_CONTEXT" && -f "$RALPH_FAILURE_CONTEXT" ]]; then
    echo "Retrying with failure context:"
    cat "$RALPH_FAILURE_CONTEXT"
    echo ""
fi

# === OBJECTIVE (from PRP deliverable - VERBATIM) ===
# {Copy deliverable description exactly from PRP}

# === ACCEPTANCE CRITERIA (from PRP success criteria - VERBATIM) ===
# SC-{N.1}: {criterion text from PRP}
# SC-{N.2}: {criterion text from PRP}
# SC-{N.3}: {criterion text from PRP}

# === INIT CHECK ===
cd "{app_dir}"
npm run build > /dev/null 2>&1 || { echo "Build broken before step - fix first"; exit 1; }

# === IMPLEMENTATION ===
# {Implementation instructions for Claude to follow}
# Reference specific files, patterns, and PRP appendices
#
# IMPORTANT - SQL VERBATIM RULE:
# When copying SQL from PRP Appendix B, copy EXACTLY as written.
# DO NOT add:
#   - IF NOT EXISTS clauses (breaks test grep patterns)
#   - Additional indexes not in spec
#   - Modified column names, types, or constraints
#   - "Helpful" safety improvements
# The tests verify EXACT SQL patterns from the PRP.

# === VERIFICATION HINT ===
# After implementation, run: ./test-{NN}.sh

echo ""
echo "Step {NN} implementation complete"
echo "  Next: Run ./test-{NN}.sh to verify"
```

## TEST FILE FORMAT

Use this exact format for every test-NN.sh:

```bash
#!/bin/bash
# ==============================================================================
# Test {NN}: {Same title as step}
# ==============================================================================
# PRP: {prp_id}
# PRP Hash: {first 7 chars of md5}
# PRP Phase: {Phase N.M}
# Success Criteria Tested: SC-{N.1}, SC-{N.2}, SC-{N.3}
# Invariants Verified: #{n}, #{n}, #11
# ==============================================================================

set -e
cd "{app_dir}"

PASS=0
FAIL=0

check() {
    if eval "$1"; then
        echo "  [PASS] $2"
        PASS=$((PASS + 1))  # Note: ((PASS++)) returns exit 1 when PASS=0, breaks set -e
    else
        echo "  [FAIL] $2"
        FAIL=$((FAIL + 1))
    fi
}

echo "═══════════════════════════════════════════════════════════════"
echo "  TEST {NN}: {Deliverable ID}"
echo "═══════════════════════════════════════════════════════════════"

# === PRP SUCCESS CRITERIA (VERBATIM from PRP Section 2) ===
# SC-{N.1}: {exact text from PRP}
# SC-{N.2}: {exact text from PRP}
# === END PRP CRITERIA ===

# === FILE EXISTENCE CHECKS ===
echo ""
echo "Checking file existence..."
check "[ -f 'src/app/path/file.tsx' ]" "SC-{N.1}: {file description}"
check "[ -f 'src/components/path/file.tsx' ]" "SC-{N.2}: {file description}"

# === CONTENT CHECKS (derived from success criteria) ===
echo ""
echo "Checking content..."
check "grep -q 'Expected Text' src/app/path/file.tsx" "SC-{N.1}: {what we're checking}"
check "grep -q 'Other Text' src/app/path/file.tsx" "SC-{N.2}: {what we're checking}"

# === PRP VALIDATION COMMANDS (VERBATIM from PRP Section 8) ===
# Copied exactly from PRP - do not modify
echo ""
echo "Running PRP validation commands..."
check "npm run build" "Build passes"
check "npx tsc --noEmit" "TypeScript strict mode"
# === END VERBATIM ===

# === INVARIANT CHECKS ===
echo ""
echo "Checking invariants..."

# Invariant #7: Validation executable
check_invariant_7() {
    npm run build > /dev/null 2>&1
}
check "check_invariant_7" "Invariant #7: Build is executable validation"

# Invariant #11: Accessibility (if UI step)
check_invariant_11() {
    if command -v axe &> /dev/null; then
        axe http://localhost:3000/{route} --exit 2>/dev/null
    else
        echo "axe-cli not installed - manual check required"
        return 0
    fi
}
# Uncomment if this step has UI:
# check "check_invariant_11" "Invariant #11: Accessibility audit"

# === PLAYWRIGHT VERIFICATION ===
cat << 'PLAYWRIGHT_VERIFY'
{
    "route": "/{route}",
    "prp_phase": "{N.M}",
    "prp_criteria": ["SC-{N.1}", "SC-{N.2}"],
    "invariants": [11],
    "checks": [
        {
            "type": "heading",
            "level": 1,
            "text": "{Exact heading text from PRP}",
            "prp_ref": "SC-{N.1}",
            "comment": "From PRP Success Criteria table"
        },
        {
            "type": "text",
            "text": "{Exact text from PRP}",
            "prp_ref": "SC-{N.2}",
            "comment": "From PRP UI wireframe"
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

# === RESULTS ===
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
    # Write failure context for retry
    if [[ -n "$RALPH_FAILURE_CONTEXT" ]]; then
        cat > "$RALPH_FAILURE_CONTEXT" << EOF
{
    "step": {NN},
    "error_type": "test",
    "checks_failed": $FAIL,
    "checks_passed": $PASS,
    "suggestion": "Review failed checks above and fix implementation"
}
EOF
    fi
    exit 1
fi

echo ""
echo "Test {NN} passed"
exit 0
```

## GATE FILE FORMAT

Use this exact format for every gate-N.sh:

```bash
#!/bin/bash
# ==============================================================================
# Gate {N}: {Phase title from PRP}
# ==============================================================================
# PRP: {prp_id}
# PRP Hash: {first 7 chars of md5}
# PRP Phase: {Phase N - title}
# Steps Covered: step-{start}.sh through step-{end}.sh
# Success Criteria Aggregated: SC-{N.1} through SC-{N.M}
# Invariants Verified: #1, #7, #11
# Performance Targets: {from PRP, e.g., "Build <30s, Page load <2s"}
# ==============================================================================

set -e
cd "{app_dir}"

echo "═══════════════════════════════════════════════════════════════"
echo "  GATE {N}: {Phase title}"
echo "═══════════════════════════════════════════════════════════════"

FAIL=0

gate_check() {
    if eval "$1"; then
        echo "  [PASS] $2"
    else
        echo "  [FAIL] $2"
        FAIL=$((FAIL + 1))
    fi
}

# === RUN ALL PHASE TESTS ===
echo ""
echo "Running phase tests..."
for test in test-{start}.sh test-{...}.sh test-{end}.sh; do
    echo "  Running $test..."
    if ./"$test" > /dev/null 2>&1; then
        echo "    [PASS] $test"
    else
        echo "    [FAIL] $test"
        FAIL=$((FAIL + 1))
    fi
done

# === PHASE SUCCESS CRITERIA (from PRP Section 2) ===
echo ""
echo "Checking phase success criteria..."
# SC-{N.1}: {exact text from PRP}
gate_check "{command}" "SC-{N.1}: {description}"
# SC-{N.2}: {exact text from PRP}
gate_check "{command}" "SC-{N.2}: {description}"

# === PERFORMANCE TARGETS (from PRP) ===
echo ""
echo "Checking performance targets..."

# Target: Build <30s (from PRP)
BUILD_START=$(date +%s)
npm run build > /dev/null 2>&1
BUILD_END=$(date +%s)
BUILD_TIME=$((BUILD_END - BUILD_START))
if [[ $BUILD_TIME -lt 30 ]]; then
    echo "  [PASS] Build time: ${BUILD_TIME}s (target: <30s)"
else
    echo "  [FAIL] Build time: ${BUILD_TIME}s (target: <30s)"
    FAIL=$((FAIL + 1))
fi

# === INVARIANT #11: Full Accessibility Audit ===
echo ""
echo "Running accessibility audit (Invariant #11)..."
if command -v axe &> /dev/null; then
    if axe http://localhost:3000 --exit 2>/dev/null; then
        echo "  [PASS] Accessibility: No critical violations"
    else
        echo "  [FAIL] Accessibility: Violations found"
        FAIL=$((FAIL + 1))
    fi
else
    echo "  [SKIP] axe-cli not installed - manual audit required"
fi

# === GATE RESULT ===
echo ""
echo "═══════════════════════════════════════════════════════════════"
if [[ $FAIL -eq 0 ]]; then
    echo "  GATE {N}: PASSED"
    echo "  All phase {N} criteria met. Proceed to phase {N+1}."
else
    echo "  GATE {N}: FAILED ($FAIL issues)"
    echo "  Fix issues before proceeding to phase {N+1}."
    exit 1
fi
echo "═══════════════════════════════════════════════════════════════"
exit 0
```

## PRP-COVERAGE.md FORMAT

```markdown
# PRP Coverage Matrix

**PRP:** {prp_id}
**PRP Hash:** {first 7 chars of md5}
**Source Spec:** {source_spec}
**Generated:** {date}
**Confidence:** {X.X/10} ({risk level})
**Thinking Level:** {level}

## Deliverable → Step Mapping

| PRP Deliverable | Step | Test | Gate | Description |
|-----------------|------|------|------|-------------|
| F0.1 | step-01.sh | test-01.sh | gate-1 | {title} |
| F0.2 | step-02.sh | test-02.sh | gate-1 | {title} |
| F1.1 | step-04.sh | test-04.sh | gate-2 | {title} |

## Success Criteria → Test Mapping

| Criterion | Description | Test File | Check Line | Status |
|-----------|-------------|-----------|------------|--------|
| SC-0.1.1 | {description} | test-01.sh | L:45 | Pending |
| SC-0.1.2 | {description} | test-01.sh | L:48 | Pending |
| SC-1.1.1 | {description} | test-04.sh | L:32 | Pending |

## Invariant Coverage

| Invariant | Description | Applied In | Verification Method |
|-----------|-------------|------------|---------------------|
| #1 | Ambiguity is Invalid | All steps | PRP criteria verbatim extraction |
| #7 | Validation Executable | All tests | npm build, tsc checks |
| #11 | Accessibility | UI tests + gates | axe-core audit |

## Schema Traceability (if applicable)

| PRP Schema (Appendix B) | Step | Field | Verification |
|-------------------------|------|-------|--------------|
| seasons.code (TEXT UNIQUE) | step-04.sh | L:23 | test-04.sh L:35 |
| buyers.company_name | step-10.sh | L:45 | test-10.sh L:52 |

## Phase Summary

| Phase | Steps | Gate | Success Criteria | Status |
|-------|-------|------|------------------|--------|
| 1: {title} | 01-03 | gate-1.sh | SC-0.* | Pending |
| 2: {title} | 04-10 | gate-2.sh | SC-1.* | Pending |
| 3: {title} | 11-15 | gate-3.sh | SC-2.* | Pending |
```

## RALPH-GENERATION-LOG.md FORMAT

```markdown
# Ralph Generation Log

**PRP:** {prp_id}
**Generated:** {timestamp}
**Generator:** Claude

## Extraction Summary

- Deliverables extracted: {N}
- Success criteria extracted: {N}
- Steps generated: {N}
- Tests generated: {N}
- Gates generated: {N}

## Uncertainties Encountered

| Step | Issue | PRP Section | Resolution |
|------|-------|-------------|------------|
| step-07.sh | Format regex not specified | Appendix D | Used `[UNCERTAIN: AIMS format]` |
| step-12.sh | "Fast" threshold undefined | SC-3.2 | Assumed <500ms |

## Assumptions Made

| Assumption | Basis | Risk |
|------------|-------|------|
| AIMS code is 5 uppercase chars | Existing code pattern | Low |
| "Fast" means <500ms | Industry standard | Medium |

## PRP Improvement Suggestions

1. **Appendix D:** Add AIMS code format specification (regex pattern)
2. **SC-3.2:** Define "fast" threshold explicitly (e.g., "<500ms")
3. **Section 8:** Add performance baseline commands

## Verbatim Extraction Verification

| Content Type | PRP Location | Extracted To | Verified |
|--------------|--------------|--------------|----------|
| DB Schema | Appendix B | step-04.sh L:23-45 | Pending |
| Validation Commands | Section 8 | All test files | Pending |
| Error Messages | Appendix F | step-07.sh L:67-72 | Pending |
| UI Wireframes | Appendix E | step-08.sh L:34-56 | Pending |
```

## DATABASE MIGRATION GUIDANCE

### Supabase TypeScript Types
When a step creates new database tables, the Supabase TypeScript types won't include them until regenerated.

**Workarounds for typed client:**
1. **Use REST API directly** for new tables (fetch with proper headers)
2. **Use type assertions** (`supabase.from('new_table' as any)`) - not recommended
3. **Regenerate types** after migration (preferred when possible)

**Add to step instructions if creating tables:**
```
# After migration is applied, regenerate Supabase types:
# npx supabase gen types typescript --project-id {project_id} > src/lib/supabase/database.types.ts
#
# Until types are regenerated, use REST API pattern:
# const response = await fetch(`${supabaseUrl}/rest/v1/new_table`, {
#   headers: { apikey: anonKey, Authorization: `Bearer ${accessToken}` }
# })
```

### Migration Application Methods
1. **Supabase CLI:** `supabase db push` (requires CLI auth)
2. **Dashboard SQL Editor:** Copy/paste migration SQL
3. **Direct psql:** Using DATABASE_URL connection string

Document the chosen method in RALPH-GENERATION-LOG.md.

## QUALITY CHECK (run before outputting)

Before generating output, verify ALL of these:

### MINIMUM FILE REQUIREMENTS (CRITICAL)
**You MUST generate AT LEAST:**
- 1+ step-NN.sh files (one per task/deliverable/checkbox)
- 1+ test-NN.sh files (one per step)
- 1+ gate-N.sh files (one per phase)
- PRP-COVERAGE.md
- RALPH-GENERATION-LOG.md

**FILE COUNT VERIFICATION:**
- Count all `- [ ]` checkboxes in the PRP (excluding `**Gate**:` lines) = X
- Count all bullets under `**Deliverables:**` sections = Y
- **Minimum step files required = max(X, Y, number_of_phases)**

**If you only have gates without steps, you FAILED. Re-scan the PRP for:**
1. `- [ ]` checkbox items → each one is a step
2. Bullets under `**Deliverables:**` → each one is a step
3. `### Phase N:` without checkboxes → treat phase as one step

**Example: NLP PRP with 4 phases, 4 checkboxes each = 16 step-NN.sh files**

### Content Checks
1. **Count match:** PRP has N deliverables/tasks → exactly N step files
2. **SC coverage:** Every SC-N.N appears in a test file with `prp_ref`
3. **Verbatim sections:** Every test has `=== PRP SUCCESS CRITERIA (VERBATIM) ===`
4. **Verbatim commands:** Every test has `=== PRP VALIDATION COMMANDS (VERBATIM) ===`
5. **Headers complete:** Every step has: PRP ID, Hash, Phase, Deliverable, Invariants, Thinking, Confidence
6. **PLAYWRIGHT_VERIFY:** Every UI test has JSON block with prp_criteria array
7. **Gate aggregation:** Every gate lists all SC-N.* for its phase
8. **Gate performance:** Every gate has timing checks from PRP
9. **Gate accessibility:** Every gate has axe-core check
10. **Coverage matrix:** PRP-COVERAGE.md has both deliverable→step AND SC→test mappings
11. **Hash consistency:** All files have same PRP hash
12. **Generation log:** RALPH-GENERATION-LOG.md documents all uncertainties

If ANY check fails, fix before outputting.

## PRP CONTENT

<prp>
{{PRP_CONTENT}}
</prp>

## OUTPUT

Generate the complete ralph-steps-{name}/ directory with all files.
Start with PRP-COVERAGE.md, then steps in order, then tests, then gates.
End with RALPH-GENERATION-LOG.md.

Use the file delimiter format:
```
=== FILE: filename.sh ===
[contents]
=== END FILE ===
```

---

## CRITICAL OUTPUT INSTRUCTION

**STOP. DO NOT SUMMARIZE. OUTPUT THE FILES NOW.**

You must output ACTUAL FILE CONTENTS with the `=== FILE: ===` delimiters.

❌ WRONG (describe mode - will be rejected):
```
I have successfully generated the following files...
The step-01.sh file contains...
Here's what each file includes...
```

✅ CORRECT (do mode - required):
```
=== FILE: PRP-COVERAGE.md ===
# PRP Coverage Matrix
...actual content...
=== END FILE ===

=== FILE: step-01.sh ===
#!/bin/bash
...actual content...
=== END FILE ===

=== FILE: test-01.sh ===
#!/bin/bash
...actual content...
=== END FILE ===

... (all steps and tests) ...

=== FILE: gate-1.sh ===
#!/bin/bash
...actual content...
=== END FILE ===
```

## MANDATORY OUTPUT ORDER (CRITICAL)

You MUST generate files in this EXACT order:
1. **PRP-COVERAGE.md** (first)
2. **ALL step-NN.sh files** (step-01, step-02, step-03, etc.)
3. **ALL test-NN.sh files** (test-01, test-02, test-03, etc.)
4. **ALL gate-N.sh files** (gate-1, gate-2, etc.) - GATES COME LAST
5. **ralph.sh** (runner)
6. **RALPH-GENERATION-LOG.md** (last)

**DO NOT generate gates before steps. Gates reference steps, so steps MUST exist first.**

If your output contains `gate-1.sh` but no `step-01.sh`, you have FAILED. Start over.

**Begin your response with:**
```
=== FILE: PRP-COVERAGE.md ===
```

Then IMMEDIATELY output step-01.sh, step-02.sh, etc.

Do not include ANY preamble, explanation, or summary. Start directly with the first file.

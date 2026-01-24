# Ralph Test Generation Prompt (TDD Mode)

You are a Ralph test compiler. Your job is to generate **tests only** from a PRP. The AI coding agent will write implementation code to pass these tests.

## TDD PHILOSOPHY (INV-L007)

**Tests are the sole contract.** Implementation code is NOT generated - it emerges when the AI writes code to pass tests.

```
OLD: PRP → step.py (code) → test.py (verify) → execute step → run test
NEW: PRP → test.py (contract) → AI writes code → test passes
```

**Benefits:**
- ~70% fewer tokens (no pre-written implementations)
- True TDD - tests define acceptance criteria
- Better quality - AI iterates to satisfaction
- Clearer separation - PRP → Tests → Code

## REQUIRED DOMAIN

Load domain: `ralph-execution.md` (Invariants 70-76)

These invariants apply to generated tests:
- **#70**: Unix line endings (LF only, no CRLF)
- **#76**: Python3 portability (never bare `python`)

## TEST QUALITY REQUIREMENTS (INV-L008)

Since tests are the sole contract, they MUST be:
1. **Complete**: Every SC-* has corresponding test assertions
2. **Correct**: Tests verify behavior, not just file existence
3. **Executable**: `pytest test-*.py` runs without syntax errors
4. **Integrated**: Tests share fixtures and can run as a suite

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

## EXTRACTION MAP (TDD Mode)

| PRP Section | → | Ralph Output | Extraction Rule |
|-------------|---|--------------|-----------------|
| `prp_id` | → | All test file headers | Copy exactly |
| `confidence_score` | → | Test headers | Include score + risk level |
| `thinking_level` | → | Test headers | Include level |
| Phase N title | → | gate-N.py header | Copy exactly |
| Phase N deliverables (F0.1, F1.2...) | → | test-NN.py | One test file per deliverable |
| Success criteria (SC-N.N) | → | test-NN.py assertions | **VERBATIM** with prp_ref tag |
| Appendix B: Database schema | → | test-NN.py schema checks | Verify columns, types, constraints |
| Appendix C: API endpoints | → | test-NN.py route checks | Verify method + path + response |
| Appendix D: Column mappings | → | test-NN.py import checks | Verify field transformations |
| Appendix E: UI wireframes | → | test-NN.py UI checks | Verify component structure |
| Appendix F: Error messages | → | test-NN.py error checks | Verify exact error strings |
| Section 8: Validation commands | → | test-NN.py commands | **COPY EXACTLY** |
| Phase success criteria | → | gate-N.py criteria list | Aggregate all SC-N.* for phase |
| Performance targets | → | gate-N.py timing checks | Include threshold + measurement |

**NOTE:** No step files are generated. The AI coding agent writes implementation to pass tests.

## OUTPUT STRUCTURE (TDD Mode)

For a PRP with 3 phases and 15 deliverables, output:

```
ralph-tests-{prp-name}/
├── conftest.py                 # Shared fixtures
├── ralph-state.json            # Progress tracker
├── PRP-COVERAGE.md             # SC → Test traceability matrix
├── RALPH-GENERATION-LOG.md     # Uncertainties and assumptions
├── test_01_{feature}.py        # Test for deliverable F0.1
├── test_02_{feature}.py        # Test for deliverable F0.2
├── ...
├── test_15_{feature}.py        # Test for deliverable FN.M
├── gate_1.py                   # Phase 1 gate (runs test_01-05)
├── gate_2.py                   # Phase 2 gate
├── gate_3.py                   # Phase 3 gate
└── test_integration.py         # End-to-end workflow test (INV-L009)
```

**NO step-*.py files.** Tests are the contract; code emerges.

## FILE OUTPUT FORMAT

Output each file with clear delimiters:

```
=== FILE: filename.py ===
[file contents]
=== END FILE ===
```

## CONFTEST.PY (Shared Fixtures)

Every test suite needs a conftest.py with shared fixtures:

```python
"""
Shared fixtures for Ralph TDD tests.
PRP: {prp_id}
"""
import pytest
import sys
from pathlib import Path

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Target paths - where implementation code should be created
TARGET_PATHS = {
    "router": PROJECT_ROOT / "sa-intel-app" / "backend" / "routers",
    "services": PROJECT_ROOT / "sa-intel-app" / "backend" / "services",
    "frontend": PROJECT_ROOT / "sa-intel-app" / "frontend" / "src",
}

@pytest.fixture
def project_root():
    return PROJECT_ROOT

@pytest.fixture  
def router_path():
    return TARGET_PATHS["router"]
```

## TEST FILE FORMAT (TDD Mode)

Use this exact format for every test_NN_{feature}.py:

```python
"""
# ==============================================================================
# Test {NN}: {Deliverable title from PRP - VERBATIM}
# ==============================================================================
# PRP: {prp_id}
# PRP Hash: {first 7 chars of md5}
# PRP Phase: {Phase N.M - Phase title}
# PRP Deliverable: {F0.1 - Deliverable ID}
#
# Success Criteria Tested: SC-{N.1}, SC-{N.2}, SC-{N.3}
#
# IMPLEMENTATION INSTRUCTIONS FOR AI:
# Create file: {target_file_path}
# Must contain:
#   - {specific requirement 1}
#   - {specific requirement 2}
#   - {specific requirement 3}
# ==============================================================================
"""
import pytest
from pathlib import Path

# === TARGET FILE ===
TARGET_FILE = Path("sa-intel-app/backend/routers/{feature}.py")


class TestDeliverable{NN}:
    """Tests for PRP Deliverable F{N.M}."""
    
    # === SC-{N.1}: {criterion text from PRP - VERBATIM} ===
    def test_file_exists(self, project_root):
        """SC-{N.1}: {criterion description}"""
        target = project_root / TARGET_FILE
        assert target.exists(), f"AI must create: {TARGET_FILE}"
    
    # === SC-{N.2}: {criterion text from PRP - VERBATIM} ===
    def test_endpoint_defined(self, project_root):
        """SC-{N.2}: {criterion description}"""
        target = project_root / TARGET_FILE
        content = target.read_text()
        assert "@router.get" in content, "Must define GET endpoint"
        assert "{expected_field}" in content, "Must include {field}"
    
    # === SC-{N.3}: {criterion text from PRP - VERBATIM} ===
    def test_response_schema(self, project_root):
        """SC-{N.3}: {criterion description}"""
        target = project_root / TARGET_FILE
        content = target.read_text()
        # Verify response model matches PRP
        assert "week: str" in content
        assert "use_cases: List" in content
        assert "snapshots: List" in content
    
    # === APPENDIX VERBATIM CHECKS ===
    def test_schema_matches_prp(self, project_root):
        """Verify SQL/schema matches PRP Appendix B exactly."""
        # From PRP Appendix B:
        # predicted_status, predicted_close_date, predicted_mrr
        target = project_root / TARGET_FILE
        content = target.read_text()
        assert "predicted_status" in content
        assert "predicted_close_date" in content
        assert "predicted_mrr" in content


# === IMPLEMENTATION HINTS FOR AI ===
"""
To pass these tests, the AI coding agent must:

1. Create file: {TARGET_FILE}
2. Define router with prefix: {prefix}
3. Create endpoint: {method} {path}
4. Return response with fields: {fields}
5. Use these exact field names from PRP Appendix: {appendix_fields}

Reference: PRP Section {section}, Appendix {appendix}
"""
```

## OLD: STEP FILE FORMAT (DEPRECATED)

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

### PRP Extraction Checks
1. **Count match:** PRP has N deliverables → exactly N step files
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

### Ralph Execution Invariant Checks (70-76)
13. **INV-70 Line endings:** No CRLF in any script (use `\n` not `\r\n`)
14. **INV-71 mkdir before cat:** Every `cat >` to nested path uses `write_file` helper or has `mkdir -p`
15. **INV-72 Bash 3.2:** No `declare -A`, no `${var,,}`, no `|&`
16. **INV-73 Self-contained:** Each step includes `write_file` helper or `mkdir -p` for all paths it writes
17. **INV-74 Project root:** Every step verifies PROJECT_ROOT with marker file check
18. **INV-75 Separation:** Step scripts have NO `pytest`, `npm run build`, `python -m` - those go in test scripts only
19. **INV-76 Python3:** Every `python` call is `python3` (grep for bare `python ` or `python -c`)

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

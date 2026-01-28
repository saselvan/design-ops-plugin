#!/bin/bash
# ==============================================================================
# ralph-task-generator.sh - Generate RALPH tasks for Claude Code
#
# Usage: ./ralph-task-generator.sh --spec <spec-file>
#
# Generates 6 tasks for the RALPH pipeline:
# 1. GATE 1: STRESS_TEST - Check spec completeness
# 2. GATE 2: VALIDATE - Check spec against invariants
# 3. GATE 3-4: GENERATE_PRP + CHECK_PRP - Create and validate PRP
# 5. GATE 5: GENERATE_TESTS - Create test files from PRP
# 6. GATE 6: CHECK_TESTS - Validate test files pass
# ==============================================================================

set -eo pipefail

SPEC_FILE=""
SESSION_ID="${CLAUDE_CODE_SESSION_ID}"
TASK_DIR="$HOME/.claude/tasks/$SESSION_ID"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $(basename "$0") --spec <spec-file>

Generate RALPH tasks for Claude Code task system.

Options:
  --spec FILE    Specification file path (required)
  -h, --help     Show this help

Example:
  $(basename "$0") --spec specs/pathfinder-frontend-foundation.md
EOF
    exit 0
}

log() {
    echo -e "${GREEN}[ralph-task-generator]${NC} $1"
}

error() {
    echo -e "${RED}[ralph-task-generator ERROR]${NC} $1" >&2
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --spec)
            SPEC_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validation
[[ -z "$SPEC_FILE" ]] && error "--spec required"
[[ -z "$SESSION_ID" ]] && error "CLAUDE_CODE_SESSION_ID not set"
[[ ! -d "$TASK_DIR" ]] && error "Task directory not found: $TASK_DIR"

log "Generating RALPH tasks for spec: $SPEC_FILE"
log "Session ID: $SESSION_ID"

# ==============================================================================
# TASK 1: GATE 1 - STRESS_TEST
# ==============================================================================

cat > "$TASK_DIR/1.json" << 'TASK1_EOF'
{
  "id": "1",
  "subject": "GATE 1: STRESS_TEST - Check spec completeness",
  "description": "## GATE 1: STRESS_TEST - Check spec completeness\n\n**FILES:**\n- Input: `SPEC_FILE_PLACEHOLDER`\n- Output: none (validation only)\n\n**STATELESS: Each loop iteration sees only current spec + current assessment + recommended fixes**\n\n### Loop Iteration:\n\n**ASSESS:**\n```bash\n/Users/samuel.selvan/.claude/design-ops/enforcement/design-ops-v3-refactored.sh stress-test SPEC_FILE_PLACEHOLDER\n```\n\nRead instruction and assess spec against 6 coverage areas:\n```json\n{\n  \"completeness_check\": {\n    \"happy_path\": \"explicit|missing|unclear\",\n    \"error_cases\": \"addressed|missing|partial\",\n    \"empty_states\": \"handled|missing|unclear\",\n    \"external_failures\": \"addressed|missing|partial\",\n    \"concurrency\": \"considered|missing|unclear\",\n    \"boundaries\": \"explicit|missing|partial\"\n  },\n  \"gaps\": [\"gap 1\"],\n  \"critical_blockers\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF PASS** (all 6 PASS, gaps: [], blockers: []):\n- Done, proceed to next gate\n\n**IF FAIL** (any gaps/blockers):\n\n**FIX:**\n- Edit spec to address all gaps (single pass)\n- Apply all recommended fixes\n\n**COMMIT:**\n```bash\ngit add SPEC_FILE_PLACEHOLDER && git commit -m \"ralph: GATE 1 - fix: [gaps addressed]\"\n```\n\n**VALIDATE:**\n- Re-run stress-test (go back to ASSESS step)\n- Get fresh assessment on latest committed version\n- Only previous commit + new assessment visible (no context history)\n\n**LOOP:**\n- Repeat ASSESS → FIX → COMMIT → VALIDATE until PASS\n\n### Pass Condition\n- All 6 areas: PASS\n- gaps: []\n- critical_blockers: []",
  "activeForm": "Running GATE 1 stress-test",
  "status": "pending",
  "blocks": ["2"],
  "blockedBy": []
}
TASK1_EOF

sed -i '' "s|SPEC_FILE_PLACEHOLDER|$SPEC_FILE|g" "$TASK_DIR/1.json"

# ==============================================================================
# TASK 2: GATE 2 - VALIDATE
# ==============================================================================

cat > "$TASK_DIR/2.json" << 'TASK2_EOF'
{
  "id": "2",
  "subject": "GATE 2: VALIDATE - Check spec against invariants",
  "description": "## GATE 2: VALIDATE - Check spec against domain-appropriate invariants\n\n**FILES:**\n- Input: `SPEC_FILE_PLACEHOLDER`\n- Output: none (validation only)\n\n**MANIFEST INTEGRATION:**\n- Read: `.ralph/manifest.md` to get `spec_file`\n- Write: Append `gate_2_status: pass|fail`, `gate_2_detected_domains: [...]`, `gate_2_spec_file: <path>` to manifest\n\n**STATELESS: Each loop iteration sees only current spec + current assessment + recommended fixes**\n\n### PHASE: DETECT DOMAINS → ASSESS → FIX → VALIDATE LOOP\n\n**STEP 1 - Read Manifest:**\n```bash\nspec_file=$(grep '^spec_file:' .ralph/manifest.md | cut -d' ' -f2)\necho \"Working with spec: $spec_file\"\n```\n\n**STEP 2 - DETECT DOMAINS:**\n\nAnalyze spec content and detect which domains apply:\n- **consumer-product**: Keywords: React, component, UI, button, form, props, TypeScript, frontend, responsive\n- **healthcare-ai**: Keywords: clinical, pathology, diagnostic, medical, patient, doctor, disease\n- **data-architecture**: Keywords: pipeline, warehouse, delta lake, spark, ETL, schema, dataset\n- **hls-solution-accelerator**: Keywords: Databricks, solution accelerator, reference implementation, PathFinder\n\nMap detected domains to invariant ranges:\n- Universal: 1-10 (always included)\n- consumer-product: 11-15 (if detected)\n- data-architecture: 22-26 (if detected)\n- healthcare-ai: 27-30 (if detected)\n- hls-solution-accelerator: 31-38 (if detected)\n\n**STEP 3 - ASSESS:**\n```bash\n/Users/samuel.selvan/.claude/design-ops/enforcement/design-ops-v3-refactored.sh validate \"$spec_file\"\n```\n\nRead generated instruction file and assess spec against all detected invariants.\n\nOutput JSON assessment:\n```json\n{\n  \"detected_domains\": [\"consumer-product\", \"healthcare-ai\", \"hls-solution-accelerator\"],\n  \"applicable_invariants\": \"1-10, 11-15, 27-30, 31-38\",\n  \"invariant_violations\": {\n    \"INV-1\": \"PASS|FAIL - reasoning\",\n    \"[...]\": \"all detected invariants\"\n  },\n  \"vague_terms_found\": [\"term1\"],\n  \"violations\": [\"violation 1\"],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**STEP 4 - IF PASS:**\n```bash\necho 'gate_2_status: pass' >> .ralph/manifest.md\necho \"gate_2_detected_domains: consumer-product, healthcare-ai, hls-solution-accelerator\" >> .ralph/manifest.md\necho \"gate_2_spec_file: $spec_file\" >> .ralph/manifest.md\necho \"✅ GATE 2 PASS\"\n```\n→ Done, Task #3 auto-unblocks\n\n**STEP 5 - IF FAIL (any invariant violations or vague terms):**\n\n**FIX:**\n- Edit spec to remove vague terms\n- Address ALL invariant violations (single pass)\n- Apply all recommended fixes\n\n**COMMIT:**\n```bash\ngit add \"$spec_file\" && git commit -m \"ralph: GATE 2 - fix: [invariants addressed]\"\n```\n\n**STEP 6 - VALIDATE (re-assess):**\n- Re-run: `/Users/samuel.selvan/.claude/design-ops/enforcement/design-ops-v3-refactored.sh validate \"$spec_file\"`\n- Get fresh assessment on latest committed version\n- Only previous commit + new assessment visible (stateless)\n\n**STEP 7 - IF STILL FAIL:**\n- Go back to STEP 5 (FIX)\n- Repeat STEP 5 → STEP 6 until PASS\n\n**STEP 8 - WHEN PASS:**\n```bash\necho 'gate_2_status: pass' >> .ralph/manifest.md\necho \"gate_2_detected_domains: [domains from assessment]\" >> .ralph/manifest.md\necho \"gate_2_spec_file: $spec_file\" >> .ralph/manifest.md\necho \"✅ GATE 2 PASS\"\n```\n\n### Pass Condition\n- All detected invariants: PASS\n- vague_terms_found: []\n- violations: []",
  "activeForm": "Running GATE 2 validation",
  "status": "pending",
  "blocks": ["3"],
  "blockedBy": ["1"]
}
TASK2_EOF

sed -i '' "s|SPEC_FILE_PLACEHOLDER|$SPEC_FILE|g" "$TASK_DIR/2.json"

# ==============================================================================
# TASK 3: GATE 3-4 - GENERATE_PRP + CHECK_PRP
# ==============================================================================

# Extract base name for PRP file
SPEC_BASENAME=$(basename "$SPEC_FILE" .md)
PRP_FILE="prp/${SPEC_BASENAME}-prp.md"

cat > "$TASK_DIR/3.json" << 'TASK3_EOF'
{
  "id": "3",
  "subject": "GATE 3-4: GENERATE_PRP + CHECK_PRP - Create and validate PRP",
  "description": "## GATE 3-4: GENERATE_PRP + CHECK_PRP - Create and validate PRP from spec\n\n**FILES:**\n- Input: `SPEC_FILE_PLACEHOLDER`\n- Output: `PRP_FILE_PLACEHOLDER`\n\n**MANIFEST INTEGRATION:**\n- Read: `.ralph/manifest.md` to get `spec_file` (written by Task #1)\n- Write: Append `gate_3_prp_file: PRP_FILE_PLACEHOLDER`, `gate_3_status: pass|fail` to manifest\n\n**STATELESS: Each loop iteration sees only current spec + current assessment + recommended fixes**\n\n---\n\n## PHASE A: ASSESS EXTRACTION READINESS\n\n**STEP 1 - Read Manifest:**\n```bash\nspec_file=$(grep '^spec_file:' .ralph/manifest.md | cut -d' ' -f2)\necho \"Working with spec: $spec_file\"\n```\n\n**STEP 2 - DETECT DOMAINS & ASSESS:**\n```bash\n/Users/samuel.selvan/.claude/design-ops/enforcement/design-ops-v3-refactored.sh generate \"$spec_file\"\n```\n\nRead generated extraction instruction. Assess if spec has all sections needed for complete PRP extraction:\n\n```json\n{\n  \"extraction_readiness\": {\n    \"problem_statement_complete\": \"PASS|FAIL - clearly defined\",\n    \"success_criteria_testable\": \"PASS|FAIL - measurable and executable\",\n    \"functional_requirements_complete\": \"PASS|FAIL - all features described with inputs/outputs\",\n    \"failure_modes_addressed\": \"PASS|FAIL - error cases and recovery defined\",\n    \"acceptance_tests_definable\": \"PASS|FAIL - testable criteria present\",\n    \"scope_bounded\": \"PASS|FAIL - in-scope vs out-of-scope clear\"\n  },\n  \"missing_sections\": [\"section 1\"],\n  \"extraction_blockers\": [\"blocker 1\"],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**STEP 3 - IF PASS** (all extraction readiness criteria PASS, no missing sections):\n- Proceed to PHASE B (PRP Generation)\n\n**STEP 4 - IF FAIL** (any criteria FAIL or blockers exist):\n\n**FIX:**\n- Edit spec to add missing sections\n- Make success criteria testable and measurable\n- Define failure modes explicitly\n- Apply all recommended fixes (single pass)\n\n**COMMIT:**\n```bash\ngit add \"$spec_file\" && git commit -m \"ralph: GATE 3-4 PHASE A - fix: [missing sections addressed]\"\n```\n\n**VALIDATE:**\n- Re-run: `/Users/samuel.selvan/.claude/design-ops/enforcement/design-ops-v3-refactored.sh generate \"$spec_file\"`\n- Get fresh assessment on latest committed version\n\n**STEP 5 - IF STILL FAIL:**\n- Go back to STEP 4 (FIX)\n- Repeat STEP 4 → STEP 5 until PASS\n\n---\n\n## PHASE B: GENERATE PRP\n\nOnce PHASE A passes, extract PRP from spec using structured extraction (verbatim copy, no invention):\n\n```bash\nprp_file=\"PRP_FILE_PLACEHOLDER\"\n```\n\nFollow extraction instruction to build:\n- PRP metadata (prp_id, domain, confidence, thinking_level, invariants)\n- Phase/Deliverables section\n- Success Criteria table\n- Functional Requirements (verbatim from spec)\n- Failure Modes & Recovery\n- Type Definitions\n- Acceptance Tests\n- Domain Invariants Enforced\n\n**COMMIT PRP:**\n```bash\ngit add \"$prp_file\" && git commit -m \"ralph: GATE 3-4 PHASE B - generate: PRP created from spec\"\n```\n\n---\n\n## PHASE C: CHECK PRP\n\n**STEP 6 - ASSESS PRP QUALITY:**\n```bash\n/Users/samuel.selvan/.claude/design-ops/enforcement/design-ops-v3-refactored.sh check \"$prp_file\"\n```\n\nAssess PRP quality and structure:\n\n```json\n{\n  \"detected_domains\": [\"consumer-product\", \"healthcare-ai\", \"hls-solution-accelerator\"],\n  \"applicable_invariants\": \"1-10, 11-15, 27-30, 31-38\",\n  \"prp_structure\": {\n    \"metadata\": \"PASS|FAIL - has prp_id, domain, confidence, thinking_level, invariants\",\n    \"deliverables\": \"PASS|FAIL - all phase deliverables listed\",\n    \"success_criteria\": \"PASS|FAIL - all SCs testable and measurable\",\n    \"functional_requirements\": \"PASS|FAIL - all FRs extracted from spec\",\n    \"failure_modes\": \"PASS|FAIL - error handling defined\",\n    \"acceptance_tests\": \"PASS|FAIL - detailed tests per FR\",\n    \"invariants_reflected\": \"PASS|FAIL - domain invariants visible in PRP sections\"\n  },\n  \"gaps\": [\"gap 1\"],\n  \"critical_blockers\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**STEP 7 - IF PASS** (structure complete, all SCs testable, domain invariants reflected, no gaps/blockers):\n```bash\necho 'gate_3_prp_file: PRP_FILE_PLACEHOLDER' >> .ralph/manifest.md\necho 'gate_3_status: pass' >> .ralph/manifest.md\necho \"✅ GATE 3-4 PASS\"\n```\n→ Done, Task #5 auto-unblocks\n\n**STEP 8 - IF FAIL** (any gaps or blockers exist):\n\n**FIX:**\n- Edit PRP to address ALL gaps (single pass)\n- Ensure domain-appropriate invariants are explicit in PRP sections\n- Apply all recommended fixes\n\n**COMMIT:**\n```bash\ngit add \"$prp_file\" && git commit -m \"ralph: GATE 3-4 PHASE C - fix: [gaps addressed]\"\n```\n\n**VALIDATE:**\n- Re-run: `/Users/samuel.selvan/.claude/design-ops/enforcement/design-ops-v3-refactored.sh check \"$prp_file\"`\n- Get fresh assessment on latest committed version\n\n**STEP 9 - IF STILL FAIL:**\n- Go back to STEP 8 (FIX)\n- Repeat STEP 8 → STEP 9 until PASS\n\n**STEP 10 - WHEN PASS:**\n```bash\necho 'gate_3_prp_file: PRP_FILE_PLACEHOLDER' >> .ralph/manifest.md\necho 'gate_3_status: pass' >> .ralph/manifest.md\necho \"✅ GATE 3-4 PASS\"\n```\n\n### Pass Condition\n- PHASE A: extraction readiness all PASS, no missing sections\n- PHASE B: PRP created and committed\n- PHASE C: PRP structure all PASS, invariants reflected, gaps: [], blockers: []",
  "activeForm": "Running GATE 3-4 PRP generation and validation",
  "status": "pending",
  "blocks": ["5"],
  "blockedBy": ["2"]
}
TASK3_EOF

sed -i '' "s|SPEC_FILE_PLACEHOLDER|$SPEC_FILE|g" "$TASK_DIR/3.json"
sed -i '' "s|PRP_FILE_PLACEHOLDER|$PRP_FILE|g" "$TASK_DIR/3.json"

# ==============================================================================
# TASK 5: GATE 5 - GENERATE_TESTS
# ==============================================================================

cat > "$TASK_DIR/5.json" << 'TASK5_EOF'
{
  "id": "5",
  "subject": "GATE 5: GENERATE_TESTS - Create test files from PRP",
  "description": "## GATE 5: GENERATE_TESTS - Create test files from PRP\n\n**FILES:**\n- Input: `PRP_FILE_PLACEHOLDER`\n- Output: `apps/frontend/tests/components.test.tsx` (or equivalent test structure)\n\n**STATELESS: Each loop iteration sees only current PRP + current assessment + recommended fixes**\n\n### Loop Iteration:\n\n**STEP 1 - ASSESS TEST GENERATION READINESS:**\n\nRead PRP and assess if it has everything needed for complete test generation:\n\n```json\n{\n  \"test_readiness\": {\n    \"success_criteria_testable\": \"PASS|FAIL - all SCs have measurable assertions\",\n    \"acceptance_tests_detailed\": \"PASS|FAIL - acceptance tests are concrete, not vague\",\n    \"functional_requirements_testable\": \"PASS|FAIL - each FR has testable acceptance criteria\",\n    \"performance_targets_specified\": \"PASS|FAIL - numeric targets with device context\",\n    \"accessibility_requirements_clear\": \"PASS|FAIL - WCAG AA, contrast ratios, aria-live specified\",\n    \"responsive_breakpoints_defined\": \"PASS|FAIL - 320px, 768px, 1024px+ behaviors explicit\"\n  },\n  \"missing_test_specs\": [\"spec 1\"],\n  \"test_blockers\": [\"blocker 1\"],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF PASS** (all readiness PASS, no blockers):\n- Proceed to STEP 2 (Generate Tests)\n\n**IF FAIL** (any criteria FAIL or blockers):\n\n**FIX:**\n- Edit PRP to make all acceptance tests concrete and measurable\n- Add numeric performance targets with device context\n- Clarify accessibility and responsive requirements\n- Apply all recommended fixes (single pass)\n\n**COMMIT:**\n```bash\ngit add PRP_FILE_PLACEHOLDER && git commit -m \"ralph: GATE 5 - fix: [test specs clarified]\"\n```\n\n**VALIDATE:**\n- Re-assess PRP against test readiness criteria (fresh assessment)\n- Only previous commit + new assessment visible (stateless)\n\n**LOOP:**\n- Repeat ASSESS → FIX → COMMIT → VALIDATE until PASS\n\n**STEP 2 - GENERATE TEST FILES:**\n\nOnce readiness passes, create test files from PRP:\n\n```bash\ntest_file=\"apps/frontend/tests/components.test.tsx\"\n```\n\nGenerate tests covering:\n- All components from PRP deliverables\n- Design tokens (import/export)\n- TypeScript strict mode\n- Accessibility (axe-core 0 violations)\n- Responsive design (320px, 768px, 1024px+)\n- Performance targets from PRP\n- All functional requirements\n- Error states and edge cases\n\nTarget: 30-40 tests, >300 lines, verbatim success criteria from PRP\n\n**COMMIT TEST FILES:**\n```bash\ngit add \"$test_file\" && git commit -m \"ralph: GATE 5 - generate: test suite created from PRP\"\n```\n\n### Pass Condition\n- Test readiness all PASS, no blockers\n- Test files created and committed\n- Task #6 auto-unblocks for test validation",
  "activeForm": "Generating test files from PRP",
  "status": "pending",
  "blocks": ["6"],
  "blockedBy": ["3"]
}
TASK5_EOF

sed -i '' "s|PRP_FILE_PLACEHOLDER|$PRP_FILE|g" "$TASK_DIR/5.json"

# ==============================================================================
# TASK 6: GATE 6 - IMPLEMENT
# ==============================================================================

cat > "$TASK_DIR/6.json" << 'TASK6_EOF'
{
  "id": "6",
  "subject": "GATE 6: IMPLEMENT - Write code until tests pass",
  "description": "## GATE 6: IMPLEMENT - Write code to make tests pass (TDD)\n\n**FILES:**\n- Input: `apps/frontend/tests/components.test.tsx` (created by Task #5)\n- Input: `PRP_FILE_PLACEHOLDER` (for reference)\n- Output: All component files specified in PRP deliverables\n\n**STATELESS: Each loop iteration sees only current test files + current code + current assessment + recommended fixes**\n\n---\n\n## PHASE A: UNIT TESTS - Implement components until unit tests pass\n\n**ASSESS:**\n\nRun unit tests and assess failures:\n\n```bash\ncd /Users/samuel.selvan/projects/hls-pathology-dual-corpus && npm test -- components.test.tsx\n```\n\nOutput JSON assessment:\n\n```json\n{\n  \"unit_test_execution\": {\n    \"tests_collected\": \"PASS|FAIL - jest can collect tests\",\n    \"all_tests_pass\": \"PASS|FAIL - no test failures\",\n    \"failing_tests\": [\"test name 1\", \"test name 2\"],\n    \"missing_implementations\": [\"SearchInput\", \"ImageDropzone\"],\n    \"implementation_errors\": [\"error 1\"]\n  },\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF PASS** (all unit tests pass):\n- Proceed to PHASE B (Integration Tests)\n\n**IF FAIL** (tests failing or missing implementations):\n\n**FIX:**\n- Read failing test to understand what's expected\n- Implement or fix the component code to satisfy test assertions\n- Create missing components per PRP deliverables\n- Fix TypeScript errors, import issues, prop mismatches\n- Apply all recommended fixes (single pass)\n\n**COMMIT:**\n```bash\ngit add apps/frontend/src/ && git commit -m \"ralph: GATE 6 PHASE A - fix: [components implemented/fixed]\"\n```\n\n**VALIDATE:**\n- Re-run: `npm test -- components.test.tsx`\n- Get fresh assessment on latest committed version\n- Only previous commit + new assessment visible (no context history)\n\n**LOOP:**\n- Repeat ASSESS → FIX → COMMIT → VALIDATE until all unit tests PASS\n\n---\n\n## PHASE B: INTEGRATION TESTS - Test component interactions\n\n**ASSESS:**\n\nCreate and run integration tests:\n\n```bash\ntest_file=\"apps/frontend/tests/integration.test.tsx\"\n```\n\nGenerate integration tests covering:\n- Component composition (Layout with SearchInput, ModeSelector, ResultCard)\n- Data flow between components (search → results → selection)\n- State management across components\n- Error propagation and recovery\n- User workflows (search → view results → select → view reasoning)\n\nRun integration tests:\n```bash\nnpm test -- integration.test.tsx\n```\n\nOutput JSON assessment:\n\n```json\n{\n  \"integration_test_execution\": {\n    \"all_tests_pass\": \"PASS|FAIL\",\n    \"failing_tests\": [\"test name 1\"],\n    \"integration_issues\": [\"components don't communicate properly\"],\n    \"workflow_gaps\": [\"gap 1\"]\n  },\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF PASS** (all integration tests pass):\n```bash\necho 'gate_6_status: pass' >> .ralph/manifest.md\necho \"✅ GATE 6 PASS (Unit + Integration)\"\n```\n→ Done, Task #8 auto-unblocks\n\n**IF FAIL** (integration tests failing):\n\n**FIX:**\n- Fix component interactions and data flow\n- Ensure state properly shared/communicated\n- Fix error propagation issues\n- Apply all recommended fixes (single pass)\n\n**COMMIT:**\n```bash\ngit add apps/frontend/src/ apps/frontend/tests/ && git commit -m \"ralph: GATE 6 PHASE B - fix: [integration issues resolved]\"\n```\n\n**VALIDATE:**\n- Re-run: `npm test -- integration.test.tsx`\n- Get fresh assessment on latest committed version\n- Only previous commit + new assessment visible (no context history)\n\n**LOOP:**\n- Repeat ASSESS → FIX → COMMIT → VALIDATE until all integration tests PASS\n\n### Pass Condition\n- PHASE A: All unit tests pass (components work in isolation)\n- PHASE B: All integration tests pass (components work together)\n- gate_6_status: pass",
  "activeForm": "Implementing components until tests pass",
  "status": "pending",
  "blocks": ["8"],
  "blockedBy": ["5"]
}
TASK6_EOF

sed -i '' "s|PRP_FILE_PLACEHOLDER|$PRP_FILE|g" "$TASK_DIR/6.json"

# ==============================================================================
# TASK 8: GATE 7 - SMOKE_TEST
# ==============================================================================

cat > "$TASK_DIR/8.json" << 'TASK8_EOF'
{
  "id": "8",
  "subject": "GATE 7: SMOKE_TEST - Final validation",
  "description": "## GATE 7: SMOKE_TEST - Final end-to-end validation\n\n**FILES:**\n- Input: All implemented components and tests\n- Output: none (validation only)\n\n**STATELESS: Each loop iteration sees only current codebase + current assessment + recommended fixes**\n\n### Loop Iteration:\n\n**ASSESS:**\n\nRun smoke tests to validate end-to-end functionality:\n\n```bash\ncd /Users/samuel.selvan/projects/hls-pathology-dual-corpus && npm run smoke-test\n```\n\nIf smoke-test script doesn't exist, create and run:\n```bash\ntest_file=\"apps/frontend/tests/smoke.test.tsx\"\n```\n\nGenerate smoke tests covering critical paths:\n- App loads without errors\n- ComponentsShowcase renders all 6 components\n- SearchInput accepts input and clears\n- ImageDropzone accepts file drag-drop\n- ModeSelector switches between 3 modes\n- ResultCard displays and can be selected\n- ReasoningPanel expands/collapses\n- Layout renders header/main/footer correctly\n- No console errors on load\n- Bundle size < 500KB\n- Initial page load < 3s\n\nRun smoke tests:\n```bash\nnpm test -- smoke.test.tsx\n```\n\nOutput JSON assessment:\n\n```json\n{\n  \"smoke_test_execution\": {\n    \"app_loads\": \"PASS|FAIL - app starts without errors\",\n    \"critical_paths_work\": \"PASS|FAIL - all critical user flows complete\",\n    \"no_console_errors\": \"PASS|FAIL - no errors in console\",\n    \"performance_acceptable\": \"PASS|FAIL - bundle <500KB, load <3s\",\n    \"all_components_render\": \"PASS|FAIL - ComponentsShowcase displays correctly\"\n  },\n  \"failing_smoke_tests\": [\"test 1\"],\n  \"critical_issues\": [\"issue 1\"],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF PASS** (all smoke tests pass, no critical issues):\n```bash\necho 'gate_7_status: pass' >> .ralph/manifest.md\necho 'pipeline_status: complete' >> .ralph/manifest.md\necho \"✅ GATE 7 PASS\"\necho \"✅ RALPH PIPELINE COMPLETE\"\n```\n→ Done, RALPH pipeline finished successfully\n\n**IF FAIL** (smoke tests failing or critical issues found):\n\n**FIX:**\n- Debug critical path failures\n- Fix console errors\n- Optimize bundle if too large\n- Fix performance issues if load too slow\n- Ensure all components render in showcase\n- Apply all recommended fixes (single pass)\n\n**COMMIT:**\n```bash\ngit add apps/frontend/src/ apps/frontend/tests/ && git commit -m \"ralph: GATE 7 - fix: [smoke test issues resolved]\"\n```\n\n**VALIDATE:**\n- Re-run smoke tests (fresh assessment on latest committed version)\n- Only previous commit + new assessment visible (no context history)\n\n**LOOP:**\n- Repeat ASSESS → FIX → COMMIT → VALIDATE until all smoke tests PASS\n\n### Pass Condition\n- All smoke tests pass (app loads, critical paths work, no errors)\n- Bundle size < 500KB\n- Initial load < 3s\n- No critical issues\n- pipeline_status: complete",
  "activeForm": "Running final smoke tests",
  "status": "pending",
  "blocks": [],
  "blockedBy": ["6"]
}
TASK8_EOF

# ==============================================================================
# Success
# ==============================================================================

log "${GREEN}✅ RALPH tasks generated successfully!${NC}"
log ""
log "Tasks created:"
log "  1. GATE 1: STRESS_TEST - Check spec completeness"
log "  2. GATE 2: VALIDATE - Check spec against invariants"
log "  3. GATE 3-4: GENERATE_PRP + CHECK_PRP - Create and validate PRP"
log "  5. GATE 5: GENERATE_TESTS - Create test files from PRP"
log "  6. GATE 6: IMPLEMENT - Write code until tests pass (TDD)"
log "  8. GATE 7: SMOKE_TEST - Final validation"
log ""
log "Task directory: $TASK_DIR"
log "Spec file: $SPEC_FILE"
log "PRP file: $PRP_FILE"
log ""
log "DAG: 1 → 2 → 3 → 5 → 6 → 8"
log "Tasks auto-unblock when dependencies complete."
log ""
log "Run '/tasks' in Claude Code to see the task list."

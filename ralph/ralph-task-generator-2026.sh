#!/bin/bash
# ==============================================================================
# ralph-task-generator-2026.sh - Generate RALPH tasks with 2026 best practices
#
# Usage: ./ralph-task-generator-2026.sh --spec <spec-file>
#
# Generates 12 tasks for the complete RALPH pipeline:
# 1. GATE 1: STRESS_TEST
# 2. GATE 2: VALIDATE + SECURITY_SCAN
# 3. GATE 3-4: GENERATE_PRP + CHECK_PRP
# 5. GATE 5: GENERATE_TESTS
# 6. GATE 5.5: TEST_VALIDATION + TEST_QUALITY
# 7. GATE 5.75: PREFLIGHT
# 8. GATE 6: IMPLEMENT_TDD (micro-loops per test)
# 9. GATE 6.5: PARALLEL_CHECKS (Build + Lint + Integration + A11y)
# 10. GATE 6.9: VISUAL_REGRESSION
# 11. GATE 7: SMOKE_TEST
# 12. GATE 8: AI_CODE_REVIEW + PERFORMANCE_AUDIT
# ==============================================================================

set -eo pipefail

SPEC_FILE=""
SESSION_ID="${CLAUDE_CODE_SESSION_ID}"
TASK_DIR="$HOME/.claude/tasks/$SESSION_ID"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $(basename "$0") --spec <spec-file>

Generate RALPH tasks with 2026 best practices.

Options:
  --spec FILE    Specification file path (required)
  -h, --help     Show this help

Example:
  $(basename "$0") --spec specs/pathfinder-frontend-foundation.md
EOF
    exit 0
}

log() {
    echo -e "${GREEN}[ralph-2026]${NC} $1"
}

error() {
    echo -e "${RED}[ralph-2026 ERROR]${NC} $1" >&2
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

log "Generating RALPH 2026 tasks for spec: $SPEC_FILE"

# Extract PRP file path
SPEC_BASENAME=$(basename "$SPEC_FILE" .md)
PRP_FILE="prp/${SPEC_BASENAME}-prp.md"

# ==============================================================================
# TASK 1: GATE 1 - STRESS_TEST
# ==============================================================================

cat > "$TASK_DIR/1.json" << 'EOF'
{
  "id": "1",
  "subject": "GATE 1: STRESS_TEST - Check spec completeness",
  "description": "## GATE 1: STRESS_TEST - Check spec completeness\n\n**FILES:**\n- Input: `SPEC_FILE_PLACEHOLDER`\n- Output: none (validation only)\n\n**STATELESS CONTEXT (each iteration sees ONLY):**\n- Latest committed spec file content\n- Errors from last stress-test run\n- Recommended fixes from last assessment\n- NO full conversation history\n\n### Loop:\n\n**ASSESS:**\n```bash\n/Users/samuel.selvan/.claude/design-ops/enforcement/design-ops-v3-refactored.sh stress-test SPEC_FILE_PLACEHOLDER\n```\n\nAssess against 6 coverage areas:\n```json\n{\n  \"completeness_check\": {\n    \"happy_path\": \"explicit|missing\",\n    \"error_cases\": \"addressed|missing\",\n    \"empty_states\": \"handled|missing\",\n    \"external_failures\": \"addressed|missing\",\n    \"concurrency\": \"considered|missing\",\n    \"boundaries\": \"explicit|missing\"\n  },\n  \"gaps\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF PASS:** Done\n\n**IF FAIL:**\n\n**FIX:** Edit spec to address all gaps\n\n**COMMIT:**\n```bash\ngit add SPEC_FILE_PLACEHOLDER && git commit -m \"ralph: GATE 1 - fix: [gaps addressed]\"\n```\n\n**VALIDATE:** Re-run stress-test (sees: new file + new errors only)\n\n**LOOP:** Until PASS\n\n### Telemetry\nWrite metrics:\n```bash\nmkdir -p .ralph/metrics\necho \"{\\\"gate\\\": \\\"GATE_1\\\", \\\"iterations\\\": $iteration, \\\"duration_ms\\\": $duration}\" > .ralph/metrics/gate-1.json\n```\n\n### Pass Condition\n- All 6 areas: PASS\n- gaps: []",
  "activeForm": "Running GATE 1 stress-test",
  "status": "pending",
  "blocks": ["2"],
  "blockedBy": []
}
EOF

sed -i '' "s|SPEC_FILE_PLACEHOLDER|$SPEC_FILE|g" "$TASK_DIR/1.json"

# ==============================================================================
# TASK 2: GATE 2 - VALIDATE + SECURITY_SCAN
# ==============================================================================

cat > "$TASK_DIR/2.json" << 'EOF'
{
  "id": "2",
  "subject": "GATE 2: VALIDATE + SECURITY_SCAN",
  "description": "## GATE 2: VALIDATE + SECURITY_SCAN\n\n**FILES:**\n- Input: `SPEC_FILE_PLACEHOLDER`\n- Output: `.ralph/metrics/gate-2-security.json`\n\n**STATELESS CONTEXT (each iteration sees ONLY):**\n- Latest committed spec file\n- Errors from last validation run\n- Security gaps from last assessment\n- NO full conversation history\n\n---\n\n## PHASE A: VALIDATE INVARIANTS\n\n**DETECT DOMAINS:**\n- consumer-product: React, component, UI, TypeScript\n- healthcare-ai: clinical, pathology, diagnostic\n- data-architecture: pipeline, ETL, schema\n- hls-solution-accelerator: Databricks, PathFinder\n\n**ASSESS:**\n```bash\n/Users/samuel.selvan/.claude/design-ops/enforcement/design-ops-v3-refactored.sh validate SPEC_FILE_PLACEHOLDER\n```\n\n```json\n{\n  \"detected_domains\": [],\n  \"applicable_invariants\": \"1-10, ...\",\n  \"violations\": [],\n  \"vague_terms\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF FAIL:** Edit spec → Commit → Re-assess\n\n---\n\n## PHASE B: SECURITY_SCAN\n\n**ASSESS:**\n```json\n{\n  \"security_check\": {\n    \"authentication_specified\": \"PASS|FAIL\",\n    \"authorization_specified\": \"PASS|FAIL\",\n    \"pii_handling_documented\": \"PASS|FAIL\",\n    \"rate_limiting_defined\": \"PASS|FAIL\",\n    \"input_validation_explicit\": \"PASS|FAIL\",\n    \"error_handling_secure\": \"PASS|FAIL\"\n  },\n  \"gaps\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**Save:**\n```bash\nmkdir -p .ralph/metrics\necho \"$assessment\" > .ralph/metrics/gate-2-security.json\n```\n\n**IF FAIL:** Add security requirements to spec → Commit → Re-assess\n\n### Telemetry\n```bash\necho \"{\\\"gate\\\": \\\"GATE_2\\\", \\\"iterations\\\": $iteration, \\\"security_gaps\\\": $gap_count}\" > .ralph/metrics/gate-2.json\n```\n\n### Pass Condition\n- PHASE A: All invariants PASS, vague_terms: []\n- PHASE B: All 6 security checks PASS",
  "activeForm": "Running GATE 2 validation + security",
  "status": "pending",
  "blocks": ["3"],
  "blockedBy": ["1"]
}
EOF

sed -i '' "s|SPEC_FILE_PLACEHOLDER|$SPEC_FILE|g" "$TASK_DIR/2.json"

# ==============================================================================
# TASK 3: GATE 3-4 - GENERATE_PRP + CHECK_PRP
# ==============================================================================

cat > "$TASK_DIR/3.json" << 'EOF'
{
  "id": "3",
  "subject": "GATE 3-4: GENERATE_PRP + CHECK_PRP",
  "description": "## GATE 3-4: GENERATE_PRP + CHECK_PRP\n\n**FILES:**\n- Input: `SPEC_FILE_PLACEHOLDER`\n- Output: `PRP_FILE_PLACEHOLDER`\n\n**STATELESS CONTEXT (each iteration sees ONLY):**\n- Latest committed spec/PRP file\n- Errors from last generate/check run\n- Extraction gaps from last assessment\n- NO full conversation history\n\n---\n\n## PHASE A: ASSESS EXTRACTION READINESS\n\n**ASSESS:**\n```bash\n/Users/samuel.selvan/.claude/design-ops/enforcement/design-ops-v3-refactored.sh generate SPEC_FILE_PLACEHOLDER\n```\n\n```json\n{\n  \"extraction_readiness\": {\n    \"problem_statement_complete\": \"PASS|FAIL\",\n    \"success_criteria_testable\": \"PASS|FAIL\",\n    \"functional_requirements_complete\": \"PASS|FAIL\",\n    \"failure_modes_addressed\": \"PASS|FAIL\",\n    \"acceptance_tests_definable\": \"PASS|FAIL\",\n    \"scope_bounded\": \"PASS|FAIL\"\n  },\n  \"gaps\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF FAIL:** Edit spec → Commit → Re-assess\n\n---\n\n## PHASE B: GENERATE PRP\n\nExtract PRP from spec (verbatim, no invention):\n- PRP metadata\n- Deliverables\n- Success Criteria\n- Functional Requirements\n- Failure Modes\n- Type Definitions\n- Acceptance Tests\n\n**COMMIT:**\n```bash\ngit add PRP_FILE_PLACEHOLDER && git commit -m \"ralph: GATE 3-4 PHASE B - generate: PRP created\"\n```\n\n---\n\n## PHASE C: CHECK PRP\n\n**ASSESS:**\n```bash\n/Users/samuel.selvan/.claude/design-ops/enforcement/design-ops-v3-refactored.sh check PRP_FILE_PLACEHOLDER\n```\n\n```json\n{\n  \"prp_structure\": {\n    \"metadata\": \"PASS|FAIL\",\n    \"deliverables\": \"PASS|FAIL\",\n    \"success_criteria\": \"PASS|FAIL\",\n    \"functional_requirements\": \"PASS|FAIL\",\n    \"failure_modes\": \"PASS|FAIL\",\n    \"acceptance_tests\": \"PASS|FAIL\",\n    \"invariants_reflected\": \"PASS|FAIL\"\n  },\n  \"gaps\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF FAIL:** Edit PRP → Commit → Re-assess\n\n### Telemetry\n```bash\necho \"{\\\"gate\\\": \\\"GATE_3_4\\\", \\\"iterations\\\": $iteration, \\\"prp_lines\\\": $(wc -l < PRP_FILE_PLACEHOLDER)}\" > .ralph/metrics/gate-3.json\n```\n\n### Pass Condition\n- PHASE A: extraction readiness all PASS\n- PHASE B: PRP created\n- PHASE C: PRP structure all PASS, gaps: []",
  "activeForm": "Running GATE 3-4 PRP generation",
  "status": "pending",
  "blocks": ["5"],
  "blockedBy": ["2"]
}
EOF

sed -i '' "s|SPEC_FILE_PLACEHOLDER|$SPEC_FILE|g" "$TASK_DIR/3.json"
sed -i '' "s|PRP_FILE_PLACEHOLDER|$PRP_FILE|g" "$TASK_DIR/3.json"

# ==============================================================================
# TASK 5: GATE 5 - GENERATE_TESTS
# ==============================================================================

cat > "$TASK_DIR/5.json" << 'EOF'
{
  "id": "5",
  "subject": "GATE 5: GENERATE_TESTS - Create test files",
  "description": "## GATE 5: GENERATE_TESTS - Create unit test files\n\n**FILES:**\n- Input: `PRP_FILE_PLACEHOLDER`\n- Output: `apps/frontend/tests/components.test.tsx`\n\n**STATELESS CONTEXT (each iteration sees ONLY):**\n- Latest committed PRP file\n- Test generation errors from last run\n- Coverage gaps from last assessment\n- NO full conversation history\n\n### Loop:\n\n**ASSESS TEST READINESS:**\n```json\n{\n  \"test_readiness\": {\n    \"success_criteria_testable\": \"PASS|FAIL\",\n    \"acceptance_tests_detailed\": \"PASS|FAIL\",\n    \"functional_requirements_testable\": \"PASS|FAIL\",\n    \"performance_targets_specified\": \"PASS|FAIL\",\n    \"accessibility_requirements_clear\": \"PASS|FAIL\",\n    \"responsive_breakpoints_defined\": \"PASS|FAIL\"\n  },\n  \"gaps\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF FAIL:** Edit PRP → Commit → Re-assess\n\n**IF PASS:** Generate test files covering:\n- All components from PRP deliverables\n- Design tokens (import/export)\n- TypeScript strict mode\n- Accessibility (axe-core)\n- Responsive (320/768/1024)\n- Performance targets\n- Error states\n\nTarget: 30-40 tests, >300 lines\n\n**COMMIT:**\n```bash\ngit add apps/frontend/tests/ && git commit -m \"ralph: GATE 5 - generate: tests created\"\n```\n\n### Telemetry\n```bash\necho \"{\\\"gate\\\": \\\"GATE_5\\\", \\\"test_count\\\": $(grep -c 'test(' apps/frontend/tests/components.test.tsx)}\" > .ralph/metrics/gate-5.json\n```\n\n### Pass Condition\n- Test readiness all PASS\n- Test files created and committed",
  "activeForm": "Generating test files",
  "status": "pending",
  "blocks": ["6"],
  "blockedBy": ["3"]
}
EOF

sed -i '' "s|PRP_FILE_PLACEHOLDER|$PRP_FILE|g" "$TASK_DIR/5.json"

# ==============================================================================
# TASK 6: GATE 5.5 - TEST_VALIDATION + TEST_QUALITY
# ==============================================================================

cat > "$TASK_DIR/6.json" << 'EOF'
{
  "id": "6",
  "subject": "GATE 5.5: TEST_VALIDATION + TEST_QUALITY",
  "description": "## GATE 5.5: TEST_VALIDATION + TEST_QUALITY\n\n**FILES:**\n- Input: `apps/frontend/tests/components.test.tsx`\n- Output: `.ralph/metrics/gate-5.5-test-quality.json`\n\n**STATELESS CONTEXT (each iteration sees ONLY):**\n- Latest committed test files\n- Test validation errors from last run\n- Quality metrics from last assessment\n- NO full conversation history\n\n---\n\n## PHASE A: TEST_VALIDATION (tests fail for RIGHT reasons)\n\n**ASSESS:**\n\nRun tests (expect ALL to fail - no implementations exist yet):\n```bash\ncd /Users/samuel.selvan/projects/hls-pathology-dual-corpus && npm test -- components.test.tsx 2>&1 | tee .ralph/test-output.txt\n```\n\n```json\n{\n  \"test_validation\": {\n    \"tests_collected\": \"PASS|FAIL - jest can import tests\",\n    \"all_tests_fail_correctly\": \"PASS|FAIL - fail because implementations missing, NOT syntax errors\",\n    \"imports_valid\": \"PASS|FAIL - all imports resolve\",\n    \"mocks_present\": \"PASS|FAIL - necessary mocks defined\",\n    \"assertions_specific\": \"PASS|FAIL - no .toBeTruthy() on everything\"\n  },\n  \"syntax_errors\": [],\n  \"import_errors\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**Expected:** All tests fail with \"Cannot find module\" or \"X is not defined\" (implementation missing)\n**Bad:** Tests fail with \"Unexpected token\" or \"Cannot read property of undefined\" (test broken)\n\n**IF FAIL:** Fix test syntax/imports/mocks → Commit → Re-run\n\n---\n\n## PHASE B: TEST_QUALITY (mutation testing + coverage)\n\n**ASSESS:**\n\n1. **Check assertion strength:**\n```bash\ngrep -r \"toBeTruthy\\|toBeDefined\" apps/frontend/tests/ | wc -l\n```\nShould be 0 (no weak assertions)\n\n2. **Check test isolation:**\nEach test should be independent (no shared state)\n\n3. **Coverage targets:**\n```json\n{\n  \"coverage_thresholds\": {\n    \"statements\": 80,\n    \"branches\": 75,\n    \"functions\": 80,\n    \"lines\": 80\n  }\n}\n```\n\n**Save quality metrics:**\n```bash\nmkdir -p .ralph/metrics\necho \"$assessment\" > .ralph/metrics/gate-5.5-test-quality.json\n```\n\n**IF FAIL:** Improve test assertions → Add missing test cases → Commit → Re-assess\n\n### Telemetry\n```bash\necho \"{\\\"gate\\\": \\\"GATE_5_5\\\", \\\"weak_assertions\\\": $weak_count, \\\"coverage_target\\\": 80}\" > .ralph/metrics/gate-5.5.json\n```\n\n### Pass Condition\n- PHASE A: All tests fail for right reason (implementation missing)\n- PHASE B: No weak assertions, coverage targets defined",
  "activeForm": "Validating test quality",
  "status": "pending",
  "blocks": ["7"],
  "blockedBy": ["5"]
}
EOF

# ==============================================================================
# TASK 7: GATE 5.75 - PREFLIGHT
# ==============================================================================

cat > "$TASK_DIR/7.json" << 'EOF'
{
  "id": "7",
  "subject": "GATE 5.75: PREFLIGHT - Environment ready",
  "description": "## GATE 5.75: PREFLIGHT - Verify environment ready for implementation\n\n**FILES:**\n- Input: package.json, tsconfig.json\n- Output: `.ralph/metrics/gate-5.75-preflight.json`\n\n**STATELESS CONTEXT:** Current environment state only\n\n### Check:\n\n**ASSESS:**\n```bash\ncd /Users/samuel.selvan/projects/hls-pathology-dual-corpus\n\n# Dependencies installed?\nnpm list 2>&1 | grep -q \"missing\" && echo \"FAIL\" || echo \"PASS\"\n\n# Build works?\nnpm run build 2>&1 | grep -q \"error\" && echo \"FAIL\" || echo \"PASS\"\n\n# Test runner works?\nnpm test -- --version 2>&1 | grep -q \"jest\" && echo \"PASS\" || echo \"FAIL\"\n\n# TypeScript version correct?\ntsc --version | grep -qE \"5\\\\.[0-9]+\" && echo \"PASS\" || echo \"FAIL\"\n```\n\n```json\n{\n  \"preflight_checks\": {\n    \"dependencies_installed\": \"PASS|FAIL\",\n    \"build_works\": \"PASS|FAIL\",\n    \"test_runner_works\": \"PASS|FAIL\",\n    \"typescript_version_ok\": \"PASS|FAIL\",\n    \"node_version_ok\": \"PASS|FAIL\"\n  },\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF FAIL:**\n- `npm install` if dependencies missing\n- Fix tsconfig.json if TS issues\n- Upgrade/downgrade Node if version mismatch\n\n**Save:**\n```bash\necho \"$assessment\" > .ralph/metrics/gate-5.75-preflight.json\n```\n\n### Pass Condition\n- All preflight checks PASS\n- Environment ready for implementation",
  "activeForm": "Running preflight checks",
  "status": "pending",
  "blocks": ["8"],
  "blockedBy": ["6"]
}
EOF

# ==============================================================================
# TASK 8: GATE 6 - IMPLEMENT_TDD (micro-loops)
# ==============================================================================

cat > "$TASK_DIR/8.json" << 'EOF'
{
  "id": "8",
  "subject": "GATE 6: IMPLEMENT_TDD - Write code (micro-loops)",
  "description": "## GATE 6: IMPLEMENT_TDD - Test-Driven Development (ONE test at a time)\n\n**FILES:**\n- Input: `apps/frontend/tests/components.test.tsx`\n- Output: All component files per PRP\n\n**STATELESS CONTEXT (each iteration sees ONLY):**\n- Latest committed code files\n- Current failing test output (ONE test only)\n- Errors from last implementation attempt\n- NO full conversation history\n\n**CRITICAL: Micro-loops = ONE test at a time, NOT batch**\n\n---\n\n## RED → GREEN → REFACTOR Loop\n\n**STEP 1 - RED: Get one failing test**\n```bash\nnpm test -- components.test.tsx --bail\n```\nThis runs tests and stops at FIRST failure.\n\n**Output:**\n```\nFAILED: SearchInput › renders with placeholder\n  Cannot find module 'SearchInput'\n```\n\n**STEP 2 - GREEN: Implement ONLY enough to pass THIS test**\n\nDO NOT implement entire component. Implement ONLY what this test needs:\n- Test needs SearchInput to exist? Create empty component\n- Test needs placeholder prop? Add placeholder prop only\n- Test needs it to render? Add minimal JSX\n\n**COMMIT:**\n```bash\ngit add apps/frontend/src/ && git commit -m \"ralph: GATE 6 - green: SearchInput renders with placeholder\"\n```\n\n**STEP 3 - Verify test passes:**\n```bash\nnpm test -- components.test.tsx --bail\n```\n\nIf still fails: go back to STEP 2 (more implementation needed)\nIf passes: go to STEP 4\n\n**STEP 4 - REFACTOR (optional):**\nClean up code if needed. Run test again to ensure still passes.\n\n**STEP 5 - NEXT TEST:**\nGo back to STEP 1 for next failing test.\n\n**LOOP until all unit tests pass.**\n\n---\n\n## PHASE B: INTEGRATION_TESTS\n\nOnce all unit tests pass, create integration tests:\n\n```bash\ntest_file=\"apps/frontend/tests/integration.test.tsx\"\n```\n\nTest:\n- Component composition (Layout + SearchInput + ResultCard)\n- Data flow between components\n- State management\n- Error propagation\n- User workflows\n\nRun same RED → GREEN loop for integration tests.\n\n### Telemetry (per test cycle)\n```bash\necho \"{\\\"gate\\\": \\\"GATE_6\\\", \\\"test_name\\\": \\\"$test\\\", \\\"attempt\\\": $attempt, \\\"lines_added\\\": $lines}\" >> .ralph/metrics/gate-6-tdd.jsonl\n```\n\n### Pass Condition\n- All unit tests pass (RED → GREEN cycles complete)\n- All integration tests pass",
  "activeForm": "Implementing TDD (micro-loops)",
  "status": "pending",
  "blocks": ["9"],
  "blockedBy": ["7"]
}
EOF

# ==============================================================================
# TASK 9: GATE 6.5 - PARALLEL_CHECKS
# ==============================================================================

cat > "$TASK_DIR/9.json" << 'EOF'
{
  "id": "9",
  "subject": "GATE 6.5: PARALLEL_CHECKS - Build + Lint + A11y",
  "description": "## GATE 6.5: PARALLEL_CHECKS - Build, Lint, Integration, Accessibility\n\n**FILES:**\n- Input: All implemented code\n- Output: `.ralph/metrics/gate-6.5-parallel.json`\n\n**STATELESS CONTEXT:** Latest committed codebase\n\n**CRITICAL: These checks run in PARALLEL (independent)**\n\n---\n\n## PHASE A: BUILD\n\n```bash\ncd /Users/samuel.selvan/projects/hls-pathology-dual-corpus && npm run build\n```\n\n```json\n{\n  \"build_status\": {\n    \"typescript_compiles\": \"PASS|FAIL\",\n    \"bundle_builds\": \"PASS|FAIL\",\n    \"bundle_size\": \"<500KB|FAIL\",\n    \"no_type_errors\": \"PASS|FAIL\"\n  },\n  \"errors\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF FAIL:** Fix TypeScript errors → Commit → Rebuild\n\n---\n\n## PHASE B: LINT\n\n```bash\nnpm run lint\n```\n\n```json\n{\n  \"lint_status\": {\n    \"eslint_passes\": \"PASS|FAIL\",\n    \"prettier_formatted\": \"PASS|FAIL\",\n    \"no_unused_vars\": \"PASS|FAIL\",\n    \"no_console_logs\": \"PASS|FAIL\"\n  },\n  \"violations\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF FAIL:** Run `npm run lint --fix` → Commit → Re-lint\n\n---\n\n## PHASE C: INTEGRATION_TESTS\n\n```bash\nnpm test -- integration.test.tsx\n```\n\n```json\n{\n  \"integration_status\": {\n    \"all_tests_pass\": \"PASS|FAIL\",\n    \"components_communicate\": \"PASS|FAIL\",\n    \"workflows_complete\": \"PASS|FAIL\"\n  },\n  \"failing_tests\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF FAIL:** Fix integration issues → Commit → Re-run\n\n---\n\n## PHASE D: ACCESSIBILITY_AUDIT\n\n```bash\nnpm run test:a11y\n```\n\n```json\n{\n  \"a11y_status\": {\n    \"axe_core_violations\": 0,\n    \"wcag_aa_compliant\": \"PASS|FAIL\",\n    \"aria_labels_present\": \"PASS|FAIL\",\n    \"keyboard_navigable\": \"PASS|FAIL\",\n    \"color_contrast_ok\": \"PASS|FAIL\"\n  },\n  \"violations\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF FAIL:** Fix a11y issues → Commit → Re-audit\n\n---\n\n**Save combined results:**\n```bash\necho \"{\\\"build\\\": $build_status, \\\"lint\\\": $lint_status, \\\"integration\\\": $int_status, \\\"a11y\\\": $a11y_status}\" > .ralph/metrics/gate-6.5-parallel.json\n```\n\n### Pass Condition\n- ALL 4 phases PASS\n- Build succeeds, Lint passes, Integration works, A11y compliant",
  "activeForm": "Running parallel checks",
  "status": "pending",
  "blocks": ["10"],
  "blockedBy": ["8"]
}
EOF

# ==============================================================================
# TASK 10: GATE 6.9 - VISUAL_REGRESSION
# ==============================================================================

cat > "$TASK_DIR/10.json" << 'EOF'
{
  "id": "10",
  "subject": "GATE 6.9: VISUAL_REGRESSION - Screenshot testing",
  "description": "## GATE 6.9: VISUAL_REGRESSION - Visual regression testing\n\n**FILES:**\n- Input: All components\n- Output: `.ralph/metrics/gate-6.9-visual.json`, screenshots\n\n**STATELESS CONTEXT:** Latest committed codebase\n\n### Visual Testing:\n\n**ASSESS:**\n\n1. **Take baseline screenshots** (first run):\n```bash\nnpm run test:visual -- --update-snapshots\n```\n\n2. **Compare against baseline** (subsequent runs):\n```bash\nnpm run test:visual\n```\n\n```json\n{\n  \"visual_regression\": {\n    \"screenshots_captured\": 6,\n    \"visual_diffs_found\": 0,\n    \"diff_percentage\": 0.0,\n    \"new_components\": [],\n    \"changed_components\": []\n  },\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF visual diffs >5%:**\n- Review screenshots in `.ralph/visual-diffs/`\n- If intentional: Update baseline (`--update-snapshots`)\n- If unintentional: Fix CSS → Commit → Re-test\n\n**Save:**\n```bash\necho \"$assessment\" > .ralph/metrics/gate-6.9-visual.json\n```\n\n### Pass Condition\n- Screenshots captured for all components\n- Visual diffs ≤5% or approved",
  "activeForm": "Running visual regression tests",
  "status": "pending",
  "blocks": ["11"],
  "blockedBy": ["9"]
}
EOF

# ==============================================================================
# TASK 11: GATE 7 - SMOKE_TEST
# ==============================================================================

cat > "$TASK_DIR/11.json" << 'EOF'
{
  "id": "11",
  "subject": "GATE 7: SMOKE_TEST - E2E critical paths",
  "description": "## GATE 7: SMOKE_TEST - End-to-end smoke tests\n\n**FILES:**\n- Input: Complete application\n- Output: `.ralph/metrics/gate-7-smoke.json`\n\n**STATELESS CONTEXT (each iteration sees ONLY):**\n- Latest committed codebase\n- Smoke test failures from last run\n- NO full conversation history\n\n### Smoke Tests:\n\n**ASSESS:**\n\nCreate/run smoke tests:\n```bash\ntest_file=\"apps/frontend/tests/smoke.test.tsx\"\n```\n\nTest critical paths:\n- App loads without errors\n- ComponentsShowcase renders all 6 components\n- SearchInput accepts input\n- ImageDropzone accepts files\n- ModeSelector switches modes\n- ResultCard displays and selects\n- ReasoningPanel expands\n- Layout renders correctly\n- No console errors\n\n```bash\nnpm test -- smoke.test.tsx\n```\n\n```json\n{\n  \"smoke_test_execution\": {\n    \"app_loads\": \"PASS|FAIL\",\n    \"critical_paths_work\": \"PASS|FAIL\",\n    \"no_console_errors\": \"PASS|FAIL\",\n    \"performance_ok\": \"PASS|FAIL - bundle <500KB, load <3s\",\n    \"all_components_render\": \"PASS|FAIL\"\n  },\n  \"failing_tests\": [],\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF FAIL:** Debug → Fix → Commit → Re-run\n\n**Save:**\n```bash\necho \"$assessment\" > .ralph/metrics/gate-7-smoke.json\n```\n\n### Pass Condition\n- All smoke tests pass\n- No critical path failures\n- Bundle <500KB, load <3s",
  "activeForm": "Running smoke tests",
  "status": "pending",
  "blocks": ["12"],
  "blockedBy": ["10"]
}
EOF

# ==============================================================================
# TASK 12: GATE 8 - AI_CODE_REVIEW + PERFORMANCE_AUDIT
# ==============================================================================

cat > "$TASK_DIR/12.json" << 'EOF'
{
  "id": "12",
  "subject": "GATE 8: AI_CODE_REVIEW + PERFORMANCE_AUDIT",
  "description": "## GATE 8: AI_CODE_REVIEW + PERFORMANCE_AUDIT - Final quality checks\n\n**FILES:**\n- Input: Complete codebase\n- Output: `.ralph/metrics/gate-8-final.json`\n\n**STATELESS CONTEXT:** Latest committed codebase\n\n---\n\n## PHASE A: AI_CODE_REVIEW\n\n**ASSESS:**\n\nLLM reviews full implementation for:\n- Security issues (XSS, injection, auth bypass)\n- Code smells (large functions, duplicated code)\n- Performance anti-patterns (unnecessary re-renders, memory leaks)\n- Accessibility issues\n- Error handling gaps\n\n```json\n{\n  \"ai_code_review\": {\n    \"security_issues\": [],\n    \"code_smells\": [],\n    \"performance_issues\": [],\n    \"accessibility_gaps\": [],\n    \"error_handling_gaps\": [],\n    \"severity\": \"CRITICAL|HIGH|MEDIUM|LOW|NONE\"\n  },\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF CRITICAL/HIGH issues:** Fix → Commit → Re-review\n\n---\n\n## PHASE B: PERFORMANCE_AUDIT\n\n**ASSESS:**\n\n1. **Lighthouse audit:**\n```bash\nlighthouse http://localhost:3000 --output json --output-path .ralph/lighthouse.json\n```\n\n2. **Core Web Vitals:**\n- LCP (Largest Contentful Paint) < 2.5s\n- FID (First Input Delay) < 100ms\n- CLS (Cumulative Layout Shift) < 0.1\n\n3. **Bundle analysis:**\n```bash\nnpm run build -- --analyze\n```\n- Main bundle < 500KB gzipped\n- No duplicate dependencies\n- Tree-shaking working\n\n```json\n{\n  \"performance_audit\": {\n    \"lighthouse_score\": 90,\n    \"lcp\": \"2.1s\",\n    \"fid\": \"80ms\",\n    \"cls\": \"0.05\",\n    \"bundle_size\": \"420KB\",\n    \"core_web_vitals_pass\": \"PASS|FAIL\"\n  },\n  \"summary\": \"PASS|FAIL\"\n}\n```\n\n**IF FAIL:** Optimize → Commit → Re-audit\n\n---\n\n**Save final metrics:**\n```bash\necho \"{\\\"ai_review\\\": $review_status, \\\"performance\\\": $perf_status}\" > .ralph/metrics/gate-8-final.json\necho 'gate_8_status: pass' >> .ralph/manifest.md\necho 'pipeline_status: complete' >> .ralph/manifest.md\necho \"✅ RALPH PIPELINE COMPLETE (2026 STANDARD)\"\n```\n\n### Pass Condition\n- PHASE A: No critical/high security or quality issues\n- PHASE B: Lighthouse ≥90, Core Web Vitals pass, bundle <500KB\n- pipeline_status: complete",
  "activeForm": "Running AI review + performance audit",
  "status": "pending",
  "blocks": [],
  "blockedBy": ["11"]
}
EOF

# ==============================================================================
# Success
# ==============================================================================

log "${GREEN}✅ RALPH 2026 tasks generated!${NC}"
log ""
log "Pipeline (12 gates):"
log "  1. GATE 1: STRESS_TEST"
log "  2. GATE 2: VALIDATE + SECURITY_SCAN"
log "  3. GATE 3-4: GENERATE_PRP + CHECK_PRP"
log "  5. GATE 5: GENERATE_TESTS"
log "  6. GATE 5.5: TEST_VALIDATION + TEST_QUALITY"
log "  7. GATE 5.75: PREFLIGHT"
log "  8. GATE 6: IMPLEMENT_TDD (micro-loops)"
log "  9. GATE 6.5: PARALLEL_CHECKS (Build+Lint+Integration+A11y)"
log "  10. GATE 6.9: VISUAL_REGRESSION"
log "  11. GATE 7: SMOKE_TEST"
log "  12. GATE 8: AI_CODE_REVIEW + PERFORMANCE_AUDIT"
log ""
log "${CYAN}2026 Best Practices Included:${NC}"
log "  ✓ Stateless = last committed file + last errors only"
log "  ✓ TDD micro-loops (one test at a time)"
log "  ✓ Test validation before implementation"
log "  ✓ Test quality gates (mutation testing, coverage)"
log "  ✓ Parallel checks (3-5x faster)"
log "  ✓ Security scan (auth/authz/PII/rate-limiting)"
log "  ✓ Visual regression testing"
log "  ✓ AI code review"
log "  ✓ Performance audit (Lighthouse, Core Web Vitals)"
log "  ✓ Telemetry at every gate (.ralph/metrics/)"
log ""
log "DAG: 1→2→3→5→6→7→8→9→10→11→12"
log "Tasks auto-unblock when dependencies complete."
log ""
log "Metrics stored in: .ralph/metrics/"
log "Run '/tasks' in Claude Code to see task list."

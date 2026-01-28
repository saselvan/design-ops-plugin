#!/bin/bash
# ==============================================================================
# design-ops-v3-refactored.sh - Instruction-Based Design Ops Pipeline
#
# Philosophy: Script is a VALIDATOR & INSTRUCTION GENERATOR
#   - Validates specs locally (deterministic checks)
#   - Enforces step ordering
#   - Outputs structured instructions for Claude to follow
#   - No API calls, no subprocess LLM invocations
#
# Version: 3.4-refactored
# Date: 2026-01-26
# ==============================================================================

set -e

VERSION="3.4-refactored"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESIGN_OPS_BASE="${DESIGN_OPS_BASE:-$(dirname "$SCRIPT_DIR")}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# Configuration
PIPELINE_STATE_DIR="${PIPELINE_STATE_DIR:-$HOME/.design-ops-state}"
INSTRUCTION_OUTPUT_DIR="${INSTRUCTION_OUTPUT_DIR:-.}"

# Source library modules
source "$SCRIPT_DIR/lib/state.sh"
source "$SCRIPT_DIR/lib/validation.sh"
source "$SCRIPT_DIR/lib/instructions.sh"

# ==============================================================================
# DOMAIN DETECTION (SMART KEYWORD ANALYSIS)
# ==============================================================================

detect_domains() {
    local spec_file="$1"
    local content
    content=$(cat "$spec_file" | tr '[:upper:]' '[:lower:]')

    # If explicitly stated, use it
    local explicit_domain=$(grep -i "^Domain:" "$spec_file" | cut -d: -f2 | xargs || echo "")
    if [[ -n "$explicit_domain" ]]; then
        echo "$explicit_domain"
        return 0
    fi

    local detected_domains=()

    # Consumer Product: React, component, UI, button, form, async, loading, disabled, spinner, modal, input, hook, props, render, frontend, web app
    if echo "$content" | grep -qiE "\breact\b|\bjsx\b|\bcomponent\b|\bui\b|\bbutton\b|\bform\b|\basync\b|\bloading\b|\bdisabled\b|\bspinner\b|\bmodal\b|\binput\b|\bhook\b|\bprops\b|\brender\b|\bfrontend\b|\bweb app\b"; then
        detected_domains+=("consumer-product")
    fi

    # Healthcare AI: clinical, pathology, diagnostic, medical, patient, doctor, disease, symptom, hospital, radiology
    if echo "$content" | grep -qiE "\bclinical\b|\bpathology\b|\bdiagnostic\b|\bmedical\b|\bpatient\b|\bdoctor\b|\bdisease\b|\bsymptom\b|\bhospital\b|\bradiology\b|\blab\b|\bpathologist\b"; then
        detected_domains+=("healthcare-ai")
    fi

    # HLS Solution Accelerator: databricks, solution accelerator, pathfinder, demo, reference implementation
    if echo "$content" | grep -qiE "\bdatabricks\b|\bsolution accelerator\b|\bpathfinder\b|\breference implementation\b"; then
        detected_domains+=("hls-solution-accelerator")
    fi

    # Data Architecture: pipeline, warehouse, delta lake, spark, ml model, analytics, etl, schema, dataset
    if echo "$content" | grep -qiE "\bpipeline\b|\bwarehouse\b|\bdelta lake\b|\bspark\b|\bml model\b|\banalytics\b|\betl\b|\bdata schema\b|\bdataset\b|\bbatch\b|\bstream\b"; then
        detected_domains+=("data-architecture")
    fi

    # Integration: external api, webhook, third-party, oauth, rest api
    if echo "$content" | grep -qiE "\bexternal api\b|\bwebhook\b|\bthird-party\b|\boauth\b|\brest api\b"; then
        detected_domains+=("integration")
    fi

    # Ralph Execution: bash script, shell script, automation runner, ralph step, subprocess
    if echo "$content" | grep -qiE "\bbash script\b|\bshell script\b|\bautomation runner\b|\bralph\b"; then
        detected_domains+=("ralph-execution")
    fi

    # Skill Gap Transcendence: new technology, unknown tech, experimental, unfamiliar framework
    if echo "$content" | grep -qiE "\bnew technology\b|\bunknown tech\b|\bexperimental\b|\bunfamiliar framework\b"; then
        detected_domains+=("skill-gap-transcendence")
    fi

    # Remove duplicates and join with space
    if [[ ${#detected_domains[@]} -gt 0 ]]; then
        printf '%s\n' "${detected_domains[@]}" | sort -u | tr '\n' ' ' | sed 's/ $//'
    else
        echo "universal"
    fi
}

# ==============================================================================
# CORE VALIDATION FUNCTIONS (LOCAL, NO API)
# ==============================================================================

check_spec_exists() {
    local spec_file="$1"
    [[ -f "$spec_file" ]] || {
        echo -e "${RED}❌ File not found: $spec_file${NC}"
        echo -e "${YELLOW}Hint: Use absolute path or check current directory: $(pwd)${NC}"
        exit 1
    }
}

enforce_step_prerequisites() {
    local command="$1"
    local spec_file="$2"
    local state_file=$(get_state_file_path "$spec_file")
    local state=$(read_pipeline_state "$state_file")

    case "$command" in
        validate)
            if ! echo "$state" | grep -q '"stress-test"'; then
                echo -e "${RED}❌ Prerequisites not met${NC}"
                echo -e "${YELLOW}Must run stress-test first:${NC}"
                echo -e "  ${CYAN}$0 stress-test $spec_file${NC}"
                exit 1
            fi
            ;;
        generate)
            if ! echo "$state" | grep -q '"stress-test"'; then
                echo -e "${RED}❌ Prerequisites not met${NC}"
                echo -e "${YELLOW}Must run stress-test first${NC}"
                exit 1
            fi
            if ! echo "$state" | grep -q '"validate"'; then
                echo -e "${RED}❌ Prerequisites not met${NC}"
                echo -e "${YELLOW}Must run validate first${NC}"
                exit 1
            fi
            ;;
        implement)
            if ! echo "$state" | grep -q '"check"'; then
                echo -e "${RED}❌ Prerequisites not met${NC}"
                echo -e "${YELLOW}Must run check first (after generate)${NC}"
                exit 1
            fi
            ;;
    esac
}

# ==============================================================================
# COMMANDS - INSTRUCTION-BASED
# ==============================================================================

cmd_stress_test() {
    local spec_file="$1"
    local state_file=$(get_state_file_path "$spec_file")

    echo -e "${BLUE}━━━ STRESS-TEST ━━━${NC}"
    echo "Spec: $spec_file"
    echo ""

    check_spec_exists "$spec_file"

    # Run local deterministic checks
    echo -e "${BLUE}Local checks:${NC}"
    check_spec_structure "$spec_file" || {
        echo -e "${RED}❌ Spec structure issues found${NC}"
        exit 1
    }

    # Save state
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    update_pipeline_state "$state_file" "stress-test" "{\"timestamp\":\"$timestamp\",\"status\":\"pass\"}"

    # Output instruction for Claude
    echo ""
    echo -e "${CYAN}Generating instruction for completeness check...${NC}"
    generate_stress_test_instruction "$spec_file" "$INSTRUCTION_OUTPUT_DIR"

    echo ""
    echo -e "${GREEN}✅ Local checks passed${NC}"
    echo -e "${YELLOW}Next step: Review the instruction and check spec completeness${NC}"
}

cmd_validate() {
    local spec_file="$1"
    local state_file=$(get_state_file_path "$spec_file")

    echo -e "${BLUE}━━━ VALIDATE ━━━${NC}"

    check_spec_exists "$spec_file"
    enforce_step_prerequisites "validate" "$spec_file"

    # Detect applicable domains
    echo -e "${BLUE}Domain detection:${NC}"
    local domains=$(detect_domains "$spec_file")
    echo -e "  ${CYAN}Domains: $domains${NC}"
    echo ""

    # Run local structure validation
    echo -e "${BLUE}Structure validation:${NC}"
    validate_spec_structure "$spec_file" || {
        echo -e "${RED}❌ Validation failed${NC}"
        exit 1
    }

    # Save state with detected domains
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    update_pipeline_state "$state_file" "validate" "{\"timestamp\":\"$timestamp\",\"status\":\"pass\",\"domains\":\"$domains\"}"

    # Output instruction for Claude
    echo ""
    echo -e "${CYAN}Generating instruction for clarity check...${NC}"
    generate_validate_instruction "$spec_file" "$INSTRUCTION_OUTPUT_DIR" "$domains"

    echo ""
    echo -e "${GREEN}✅ Structure validation passed${NC}"
    echo -e "${YELLOW}Checking against: Universal Invariants (1-10) + Domain Invariants from: $domains${NC}"
    echo -e "${YELLOW}Next step: Review the instruction and validate against all invariants${NC}"
}

cmd_generate() {
    local spec_file="$1"
    local state_file=$(get_state_file_path "$spec_file")

    # Expected PRP file path
    local prp_file="${spec_file%.md}-PRP.md"

    echo -e "${BLUE}━━━ GENERATE PRP ━━━${NC}"

    check_spec_exists "$spec_file"
    enforce_step_prerequisites "generate" "$spec_file"

    # Check if PRP already exists and validate
    if [[ -f "$prp_file" ]]; then
        echo -e "${BLUE}Validating existing PRP...${NC}"

        # Check for required PRP sections
        local missing_sections=()
        grep -qE "^# PRP[:-]" "$prp_file" || missing_sections+=("PRP Header")
        grep -q "^## Meta" "$prp_file" || missing_sections+=("Meta")
        grep -qE "^## (Section 1|Problem Statement)" "$prp_file" || missing_sections+=("Problem Statement")
        grep -qE "^## (Section 2|Success Criteria)" "$prp_file" || missing_sections+=("Success Criteria")

        if [[ ${#missing_sections[@]} -eq 0 ]]; then
            echo -e "${GREEN}✅ PRP file exists and has required sections${NC}"

            # Update state to complete
            local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
            update_pipeline_state "$state_file" "generate" "{\"timestamp\":\"$timestamp\",\"status\":\"complete\"}"
            return 0
        else
            echo -e "${RED}❌ PRP missing required sections: ${missing_sections[*]}${NC}"
            echo -e "${YELLOW}Generating instruction to fix...${NC}"
        fi
    else
        echo -e "${RED}❌ PRP file does not exist: $prp_file${NC}"
    fi

    # Detect applicable domains
    echo -e "${BLUE}Domain detection:${NC}"
    local domains=$(detect_domains "$spec_file")
    echo -e "  ${CYAN}Domains: $domains${NC}"
    echo ""

    # Quick extract from spec (no LLM)
    echo -e "${BLUE}Extracting spec structure...${NC}"
    local random_num=$((RANDOM % 900 + 100))
    local prp_id=$(date +%Y-%m-%d)"-$random_num"

    # Save state with domains
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    update_pipeline_state "$state_file" "generate" "{\"timestamp\":\"$timestamp\",\"status\":\"pending\",\"prp_id\":\"$prp_id\",\"domains\":\"$domains\"}"

    # Output instruction for Claude
    echo -e "${CYAN}Generating instruction for PRP compilation...${NC}"
    generate_prp_instruction "$spec_file" "$prp_id" "$domains" "$INSTRUCTION_OUTPUT_DIR"

    echo ""
    echo -e "${RED}❌ PRP not yet generated${NC}"
    echo -e "${YELLOW}Next step: Follow the instruction to generate PRP using structured extraction${NC}"
    exit 1
}

cmd_check() {
    local prp_file="$1"
    local state_file=$(get_state_file_path "${prp_file%.*}.spec.md")

    echo -e "${BLUE}━━━ CHECK PRP ━━━${NC}"

    [[ -f "$prp_file" ]] || {
        echo -e "${RED}❌ PRP file not found: $prp_file${NC}"
        exit 1
    }

    # Validate PRP structure
    echo -e "${BLUE}PRP structure validation:${NC}"
    validate_prp_structure "$prp_file" || {
        echo -e "${RED}❌ PRP validation failed${NC}"
        exit 1
    }

    # Save state
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    update_pipeline_state "$state_file" "check" "{\"timestamp\":\"$timestamp\",\"status\":\"pass\"}"

    echo ""
    echo -e "${GREEN}✅ PRP validation passed${NC}"
    echo -e "${YELLOW}Next step: Review PRP, then run 'implement' for Ralph generation${NC}"
}

cmd_implement() {
    local prp_file="$1"
    local output_dir="${2:-.}"

    echo -e "${BLUE}━━━ IMPLEMENT (RALPH GENERATION) ━━━${NC}"

    [[ -f "$prp_file" ]] || {
        echo -e "${RED}❌ PRP file not found: $prp_file${NC}"
        exit 1
    }

    # Create output directory
    mkdir -p "$output_dir"

    # Check if Ralph steps already generated
    if [[ -d "$output_dir" ]] && [[ -n "$(ls -A "$output_dir" 2>/dev/null)" ]]; then
        echo -e "${BLUE}Validating existing Ralph steps...${NC}"

        # Check for at least one step file and one test file
        local step_count=$(find "$output_dir" -name "step-*.sh" 2>/dev/null | wc -l)
        local test_count=$(find "$output_dir" -name "test-*.sh" 2>/dev/null | wc -l)

        if [[ $step_count -gt 0 ]] && [[ $test_count -gt 0 ]]; then
            echo -e "${GREEN}✅ Ralph steps exist: $step_count steps, $test_count tests${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Incomplete Ralph steps (steps: $step_count, tests: $test_count)${NC}"
            echo -e "${YELLOW}Generating instruction to complete...${NC}"
        fi
    else
        echo -e "${RED}❌ No Ralph steps found in: $output_dir${NC}"
    fi

    # Extract phase structure from PRP
    echo -e "${BLUE}Extracting PRP structure...${NC}"
    local prp_id=$(grep -E "^# PRP[:-]" "$prp_file" | head -1 | sed 's/^# PRP[:-] *//' || echo "unknown")
    local phases=$(grep -cE "^## (Phase|Section)" "$prp_file" || echo "0")

    # Generate extraction mapping
    echo -e "${CYAN}Generating instruction for Ralph step generation...${NC}"
    generate_implement_instruction "$prp_file" "$output_dir"

    echo ""
    echo -e "${RED}❌ Ralph steps not yet generated${NC}"
    echo -e "${YELLOW}Next step: Follow the instruction to generate ralph-steps using structured extraction${NC}"
    exit 1
}

cmd_create_spec() {
    local req_dir="$1"
    local spec_file="${2:-spec.md}"

    echo -e "${BLUE}━━━ CREATE-SPEC ━━━${NC}"
    echo "Requirements: $req_dir"
    echo "Output: $spec_file"
    echo ""

    [[ -d "$req_dir" ]] || {
        echo -e "${RED}❌ Requirements directory not found: $req_dir${NC}"
        exit 1
    }

    # Check if spec exists and validate its structure
    if [[ -f "$spec_file" ]]; then
        echo -e "${BLUE}Validating existing spec...${NC}"

        # Check for required sections
        local missing_sections=()
        grep -q "^#.*Problem Statement" "$spec_file" || missing_sections+=("Problem Statement")
        grep -q "^#.*User Journey" "$spec_file" || missing_sections+=("User Journey")
        grep -q "^#.*Requirements" "$spec_file" || missing_sections+=("Requirements")
        grep -qE "^#.*(Success Criteria|Acceptance Criteria)" "$spec_file" || missing_sections+=("Success Criteria")

        if [[ ${#missing_sections[@]} -eq 0 ]]; then
            echo -e "${GREEN}✅ Spec file exists and has required sections${NC}"
            return 0
        else
            echo -e "${RED}❌ Spec missing required sections: ${missing_sections[*]}${NC}"
            echo -e "${YELLOW}Generating instruction to fix...${NC}"
            generate_create_spec_instruction "$req_dir" "$spec_file" "$INSTRUCTION_OUTPUT_DIR"
            exit 1
        fi
    else
        # Spec doesn't exist, generate instruction
        echo -e "${RED}❌ Spec file does not exist: $spec_file${NC}"
        echo -e "${CYAN}Generating instruction for spec creation...${NC}"
        generate_create_spec_instruction "$req_dir" "$spec_file" "$INSTRUCTION_OUTPUT_DIR"
        exit 1
    fi
}

cmd_generate_tests() {
    local prp_file="$1"
    local test_dir="${2:-tests}"

    echo -e "${BLUE}━━━ GENERATE-TESTS ━━━${NC}"

    [[ -f "$prp_file" ]] || {
        echo -e "${RED}❌ PRP file not found: $prp_file${NC}"
        exit 1
    }

    # Create test directory
    mkdir -p "$test_dir"

    # Generate instruction for test creation
    echo -e "${CYAN}Generating instruction for test generation...${NC}"
    generate_test_generation_instruction "$prp_file" "$test_dir" "$INSTRUCTION_OUTPUT_DIR"

    echo ""
    echo -e "${GREEN}✅ Instruction generated${NC}"
    echo -e "${YELLOW}Next step: Follow the instruction to generate test files${NC}"
}

cmd_implement_tdd() {
    local test_dir="$1"
    local code_dir="${2:-.}"

    echo -e "${BLUE}━━━ IMPLEMENT-TDD ━━━${NC}"

    [[ -d "$test_dir" ]] || {
        echo -e "${RED}❌ Test directory not found: $test_dir${NC}"
        exit 1
    }

    # Run tests to get failures
    echo -e "${BLUE}Running tests to identify failures...${NC}"
    local test_output
    test_output=$(run_tests "$test_dir" 2>&1 || true)

    # Check if tests exist
    if [[ -z "$test_output" ]]; then
        echo -e "${RED}❌ No test output found${NC}"
        exit 1
    fi

    # Generate instruction for TDD implementation
    echo -e "${CYAN}Generating instruction for TDD implementation...${NC}"
    generate_tdd_instruction "$test_dir" "$test_output" "$code_dir" "$INSTRUCTION_OUTPUT_DIR"

    echo ""
    echo -e "${GREEN}✅ Instruction generated${NC}"
    echo -e "${YELLOW}Next step: Follow the instruction to implement code${NC}"
}

cmd_parallel_checks() {
    local code_dir="$1"

    echo -e "${BLUE}━━━ PARALLEL-CHECKS ━━━${NC}"

    [[ -d "$code_dir" ]] || {
        echo -e "${RED}❌ Code directory not found: $code_dir${NC}"
        exit 1
    }

    # Run parallel checks
    echo -e "${BLUE}Running build/lint/a11y checks...${NC}"
    local check_results=""

    # Build check
    if command -v npm &> /dev/null; then
        check_results+="=== BUILD ===\n"
        check_results+="$(npm run build 2>&1 || true)\n\n"
    fi

    # Lint check
    if command -v eslint &> /dev/null; then
        check_results+="=== LINT ===\n"
        check_results+="$(eslint "$code_dir" 2>&1 || true)\n\n"
    fi

    # Generate instruction for fixing issues
    echo -e "${CYAN}Generating instruction for fixing check failures...${NC}"
    generate_parallel_checks_instruction "$code_dir" "$check_results" "$INSTRUCTION_OUTPUT_DIR"

    echo ""
    echo -e "${GREEN}✅ Instruction generated${NC}"
    echo -e "${YELLOW}Next step: Follow the instruction to fix issues${NC}"
}

cmd_smoke_test() {
    local code_dir="$1"
    local test_script="${2:-npm run test:e2e}"

    echo -e "${BLUE}━━━ SMOKE-TEST ━━━${NC}"

    [[ -d "$code_dir" ]] || {
        echo -e "${RED}❌ Code directory not found: $code_dir${NC}"
        exit 1
    }

    # Run smoke tests
    echo -e "${BLUE}Running E2E smoke tests...${NC}"
    local test_output
    test_output=$(eval "$test_script" 2>&1 || true)

    # Generate instruction for fixing failures
    echo -e "${CYAN}Generating instruction for fixing smoke test failures...${NC}"
    generate_smoke_test_instruction "$code_dir" "$test_output" "$INSTRUCTION_OUTPUT_DIR"

    echo ""
    echo -e "${GREEN}✅ Instruction generated${NC}"
    echo -e "${YELLOW}Next step: Follow the instruction to fix E2E failures${NC}"
}

cmd_ai_review() {
    local code_dir="$1"

    echo -e "${BLUE}━━━ AI-REVIEW ━━━${NC}"

    [[ -d "$code_dir" ]] || {
        echo -e "${RED}❌ Code directory not found: $code_dir${NC}"
        exit 1
    }

    # Generate instruction for security/quality review
    echo -e "${CYAN}Generating instruction for AI security review...${NC}"
    generate_ai_review_instruction "$code_dir" "$INSTRUCTION_OUTPUT_DIR"

    echo ""
    echo -e "${GREEN}✅ Instruction generated${NC}"
    echo -e "${YELLOW}Next step: Follow the instruction to perform Opus review${NC}"
}

cmd_security_scan() {
    local spec_file="$1"

    echo -e "${BLUE}━━━ SECURITY-SCAN ━━━${NC}"

    [[ -f "$spec_file" ]] || {
        echo -e "${RED}❌ Spec file not found: $spec_file${NC}"
        exit 1
    }

    # Security validation checks
    echo -e "${BLUE}Security checks:${NC}"

    local has_issues=0
    local issues=""

    # Check for authentication mention
    if ! grep -qi "auth" "$spec_file"; then
        issues+="⚠️  No authentication mentioned\n"
        has_issues=1
    fi

    # Check for authorization/permissions
    if ! grep -qi "permiss\|authoriz\|role\|access control" "$spec_file"; then
        issues+="⚠️  No authorization/permissions documented\n"
        has_issues=1
    fi

    # Check for PII handling
    if grep -qi "user.*data\|personal.*info\|email\|phone\|address" "$spec_file"; then
        if ! grep -qi "encrypt\|pii\|gdpr\|privacy" "$spec_file"; then
            issues+="⚠️  PII mentioned but no privacy/encryption handling specified\n"
            has_issues=1
        fi
    fi

    # Check for rate limiting
    if grep -qi "api\|endpoint\|request" "$spec_file"; then
        if ! grep -qi "rate.*limit\|throttl" "$spec_file"; then
            issues+="⚠️  API/endpoints mentioned but no rate limiting specified\n"
            has_issues=1
        fi
    fi

    # Check for input validation
    if ! grep -qi "validat\|sanitiz\|input.*check" "$spec_file"; then
        issues+="⚠️  No input validation mentioned\n"
        has_issues=1
    fi

    # Check for error handling that might leak info
    if grep -qi "error" "$spec_file"; then
        if ! grep -qi "error.*message\|error.*handling" "$spec_file"; then
            issues+="⚠️  Errors mentioned but no secure error handling specified\n"
            has_issues=1
        fi
    fi

    if [[ $has_issues -eq 1 ]]; then
        echo -e "${RED}❌ Security scan found issues:${NC}\n"
        echo -e "$issues"

        # Generate instruction
        local instruction_file="${spec_file}.security-instruction.md"
        cat > "$instruction_file" << EOF
# Security Scan Issues

The following security concerns were identified in the spec:

$issues

## Required Fixes:

1. **Authentication**: Specify authentication method (JWT, OAuth, session-based)
2. **Authorization**: Define permission model and access control rules
3. **PII Handling**: If handling personal data, specify:
   - Encryption (at rest and in transit)
   - Data retention policies
   - GDPR/privacy compliance
4. **Rate Limiting**: Define rate limits for API endpoints
5. **Input Validation**: Specify validation rules for all user inputs
6. **Error Handling**: Ensure error messages don't leak sensitive information

## Security Checklist:

- [ ] Authentication method specified
- [ ] Authorization/permissions documented
- [ ] PII handling explicit (if applicable)
- [ ] Rate limiting defined
- [ ] Input validation rules clear
- [ ] Error handling secure (no info leakage)
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (input sanitization)
- [ ] CSRF protection (tokens)
EOF
        echo -e "${YELLOW}Instruction generated: $instruction_file${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ Security scan passed${NC}"
    fi
}

cmd_test_validate() {
    local test_dir="$1"

    echo -e "${BLUE}━━━ TEST-VALIDATE ━━━${NC}"

    [[ -d "$test_dir" ]] || {
        echo -e "${RED}❌ Test directory not found: $test_dir${NC}"
        exit 1
    }

    # Check if tests exist
    local test_files=$(find "$test_dir" -name "*.test.*" -o -name "test_*.py" -o -name "*_test.go" 2>/dev/null | wc -l)

    if [[ $test_files -eq 0 ]]; then
        echo -e "${RED}❌ No test files found in $test_dir${NC}"
        exit 1
    fi

    echo -e "${BLUE}Found $test_files test files${NC}"

    # Run tests and check they fail (RED state)
    echo -e "${BLUE}Running tests to verify they fail initially...${NC}"

    local test_passed=0

    # Detect test framework
    if [[ -f "$test_dir/../package.json" ]]; then
        # JavaScript/TypeScript - npm test
        (cd "$test_dir/.." && npm test 2>&1) && test_passed=1
    elif [[ -f "$test_dir/../pytest.ini" ]] || [[ -f "$test_dir/../setup.py" ]]; then
        # Python - pytest
        (cd "$test_dir/.." && pytest "$test_dir" 2>&1) && test_passed=1
    elif [[ -f "$test_dir/../go.mod" ]]; then
        # Go - go test
        (cd "$test_dir/.." && go test ./... 2>&1) && test_passed=1
    else
        echo -e "${YELLOW}⚠️  Could not detect test framework${NC}"
        echo -e "${YELLOW}Manually verify tests fail before implementation${NC}"
        exit 0
    fi

    if [[ $test_passed -eq 1 ]]; then
        echo -e "${RED}❌ Tests are PASSING but implementation doesn't exist yet!${NC}"
        echo -e "${RED}   Tests should fail (RED state) before TDD implementation.${NC}"

        # Generate instruction
        local instruction_file="${test_dir}.test-validate-instruction.md"
        cat > "$instruction_file" << EOF
# Test Validation Failed

## Problem:
Tests are passing but no implementation exists yet.

## Why This Is Bad:
In TDD, tests must fail first (RED state) to prove they're testing real behavior.
If tests pass without implementation, they're either:
1. Testing nothing (weak assertions)
2. Testing mocks instead of real code
3. Missing the actual implementation check

## Required Fix:

Review each test and ensure it:
1. Actually calls the function being tested
2. Asserts on real behavior (not just mock calls)
3. Will fail if implementation is missing

## Example of BAD test:
\`\`\`javascript
test('user can login', () => {
  const mockLogin = jest.fn();
  mockLogin();
  expect(mockLogin).toHaveBeenCalled(); // ❌ Always passes
});
\`\`\`

## Example of GOOD test:
\`\`\`javascript
test('user can login', () => {
  const result = login('user@example.com', 'password');
  expect(result.success).toBe(true); // ✅ Fails if login() missing
});
\`\`\`

Run tests again after fixing. They should FAIL until implementation is written.
EOF
        echo -e "${YELLOW}Instruction generated: $instruction_file${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ Tests fail correctly (RED state confirmed)${NC}"
        echo -e "${GREEN}   Ready for TDD implementation${NC}"
    fi
}

cmd_test_quality() {
    local test_dir="$1"

    echo -e "${BLUE}━━━ TEST-QUALITY ━━━${NC}"

    [[ -d "$test_dir" ]] || {
        echo -e "${RED}❌ Test directory not found: $test_dir${NC}"
        exit 1
    }

    local has_issues=0
    local issues=""

    # Find all test files
    local test_files=$(find "$test_dir" -name "*.test.*" -o -name "test_*.py" -o -name "*_test.go" 2>/dev/null)

    if [[ -z "$test_files" ]]; then
        echo -e "${RED}❌ No test files found${NC}"
        exit 1
    fi

    # Check for weak assertions
    echo -e "${BLUE}Checking for weak assertions...${NC}"

    if grep -r "toBeTruthy\|toBeDefined\|toExist\|assert True\|assert.*is not None" $test_dir 2>/dev/null | grep -v "node_modules" > /dev/null; then
        issues+="⚠️  Weak assertions found (toBeTruthy, toBeDefined, assert True)\n"
        has_issues=1
    fi

    # Check for empty tests
    echo -e "${BLUE}Checking for empty/trivial tests...${NC}"

    for file in $test_files; do
        # Count assertions
        local assert_count=$(grep -c "expect\|assert" "$file" 2>/dev/null || echo 0)
        if [[ $assert_count -lt 1 ]]; then
            issues+="⚠️  Test file has no assertions: $file\n"
            has_issues=1
        fi
    done

    # Check for AAA pattern (basic heuristic)
    echo -e "${BLUE}Checking test structure...${NC}"

    for file in $test_files; do
        local has_arrange=$(grep -c "const\|let\|var\|=.*new\|setup" "$file" 2>/dev/null || echo 0)
        local has_act=$(grep -c "\..*(" "$file" 2>/dev/null || echo 0)
        local has_assert=$(grep -c "expect\|assert" "$file" 2>/dev/null || echo 0)

        if [[ $has_arrange -eq 0 ]] || [[ $has_act -eq 0 ]] || [[ $has_assert -eq 0 ]]; then
            issues+="⚠️  Test file missing AAA pattern (Arrange-Act-Assert): $(basename $file)\n"
            has_issues=1
        fi
    done

    # Check test count
    local test_count=$(echo "$test_files" | wc -l)
    if [[ $test_count -lt 10 ]]; then
        issues+="⚠️  Only $test_count test files (recommend 30-40 for comprehensive coverage)\n"
        has_issues=1
    fi

    if [[ $has_issues -eq 1 ]]; then
        echo -e "${RED}❌ Test quality issues found:${NC}\n"
        echo -e "$issues"

        # Generate instruction
        local instruction_file="${test_dir}.test-quality-instruction.md"
        cat > "$instruction_file" << EOF
# Test Quality Issues

The following test quality issues were identified:

$issues

## Required Fixes:

### 1. Remove Weak Assertions

Replace weak assertions with specific checks:

❌ BAD:
\`\`\`javascript
expect(result).toBeTruthy();
expect(user).toBeDefined();
\`\`\`

✅ GOOD:
\`\`\`javascript
expect(result.success).toBe(true);
expect(user.email).toBe('test@example.com');
\`\`\`

### 2. Follow AAA Pattern

Every test should have:
- **Arrange**: Set up test data
- **Act**: Call the function
- **Assert**: Check the result

\`\`\`javascript
test('calculates total', () => {
  // Arrange
  const items = [{ price: 10 }, { price: 20 }];

  // Act
  const total = calculateTotal(items);

  // Assert
  expect(total).toBe(30);
});
\`\`\`

### 3. Add More Tests

Aim for 30-40 tests covering:
- Happy paths (5-10 tests)
- Error cases (10-15 tests)
- Edge cases (10-15 tests)
- Boundary conditions (5-10 tests)

### 4. Test Isolation

Each test should:
- Not depend on other tests
- Clean up after itself
- Use fresh data

## Quality Checklist:

- [ ] No weak assertions
- [ ] All tests follow AAA pattern
- [ ] 30+ tests for comprehensive coverage
- [ ] Tests are isolated
- [ ] Each test has 1-3 specific assertions
- [ ] Test names describe what's being tested
EOF
        echo -e "${YELLOW}Instruction generated: $instruction_file${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ Test quality checks passed${NC}"
    fi
}

cmd_preflight() {
    local project_dir="$1"

    echo -e "${BLUE}━━━ PREFLIGHT ━━━${NC}"

    [[ -d "$project_dir" ]] || {
        echo -e "${RED}❌ Project directory not found: $project_dir${NC}"
        exit 1
    }

    local has_issues=0
    local issues=""

    # Check for package manager files
    echo -e "${BLUE}Checking dependencies...${NC}"

    if [[ -f "$project_dir/package.json" ]]; then
        # Node.js project
        if [[ ! -d "$project_dir/node_modules" ]]; then
            issues+="⚠️  node_modules not found - run: npm install\n"
            has_issues=1
        fi

        # Check if dependencies are installed
        if [[ -f "$project_dir/package-lock.json" ]]; then
            local lock_time=$(stat -f %m "$project_dir/package-lock.json" 2>/dev/null || stat -c %Y "$project_dir/package-lock.json" 2>/dev/null)
            local pkg_time=$(stat -f %m "$project_dir/package.json" 2>/dev/null || stat -c %Y "$project_dir/package.json" 2>/dev/null)
            if [[ $pkg_time -gt $lock_time ]]; then
                issues+="⚠️  package.json newer than lock file - run: npm install\n"
                has_issues=1
            fi
        fi
    elif [[ -f "$project_dir/requirements.txt" ]]; then
        # Python project
        if ! pip list 2>/dev/null | grep -q "pytest"; then
            issues+="⚠️  pytest not installed - run: pip install pytest\n"
            has_issues=1
        fi
    elif [[ -f "$project_dir/go.mod" ]]; then
        # Go project
        if [[ ! -d "$project_dir/vendor" ]] && ! go list ./... &>/dev/null; then
            issues+="⚠️  Go dependencies not ready - run: go mod download\n"
            has_issues=1
        fi
    else
        issues+="⚠️  No package manager file found (package.json, requirements.txt, go.mod)\n"
        has_issues=1
    fi

    # Check build system
    echo -e "${BLUE}Checking build system...${NC}"

    if [[ -f "$project_dir/package.json" ]]; then
        # Check if build script exists
        if ! grep -q '"build"' "$project_dir/package.json"; then
            issues+="⚠️  No build script in package.json\n"
            has_issues=1
        else
            # Try to build
            if ! (cd "$project_dir" && npm run build &>/dev/null); then
                issues+="⚠️  Build fails - run: npm run build (and fix errors)\n"
                has_issues=1
            fi
        fi
    fi

    # Check test runner
    echo -e "${BLUE}Checking test runner...${NC}"

    if [[ -f "$project_dir/package.json" ]]; then
        if ! grep -q '"test"' "$project_dir/package.json"; then
            issues+="⚠️  No test script in package.json\n"
            has_issues=1
        fi
    elif [[ -f "$project_dir/pytest.ini" ]] || [[ -f "$project_dir/setup.py" ]]; then
        if ! command -v pytest &>/dev/null; then
            issues+="⚠️  pytest not in PATH\n"
            has_issues=1
        fi
    fi

    # Check for .env if .env.example exists
    if [[ -f "$project_dir/.env.example" ]] && [[ ! -f "$project_dir/.env" ]]; then
        issues+="⚠️  .env.example exists but .env missing - copy and configure it\n"
        has_issues=1
    fi

    if [[ $has_issues -eq 1 ]]; then
        echo -e "${RED}❌ Preflight checks failed:${NC}\n"
        echo -e "$issues"

        # Generate instruction
        local instruction_file="${project_dir}/preflight-instruction.md"
        cat > "$instruction_file" << EOF
# Preflight Check Failed

The following environment issues were found:

$issues

## Required Fixes:

### For Node.js Projects:
\`\`\`bash
npm install              # Install dependencies
npm run build           # Verify build works
npm test                # Verify test runner works
\`\`\`

### For Python Projects:
\`\`\`bash
pip install -r requirements.txt  # Install dependencies
pip install pytest              # Install test framework
pytest                          # Verify test runner works
\`\`\`

### For Go Projects:
\`\`\`bash
go mod download         # Download dependencies
go build ./...          # Verify build works
go test ./...           # Verify test runner works
\`\`\`

### Environment Variables:
If .env.example exists:
\`\`\`bash
cp .env.example .env
# Edit .env with actual values
\`\`\`

## Preflight Checklist:

- [ ] Dependencies installed
- [ ] Build system works
- [ ] Test runner configured
- [ ] Environment variables set
- [ ] Can run tests (even if they fail)
EOF
        echo -e "${YELLOW}Instruction generated: $instruction_file${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ Preflight checks passed${NC}"
        echo -e "${GREEN}   Environment ready for TDD implementation${NC}"
    fi
}

cmd_visual_regression() {
    local project_dir="$1"

    echo -e "${BLUE}━━━ VISUAL-REGRESSION ━━━${NC}"

    [[ -d "$project_dir" ]] || {
        echo -e "${RED}❌ Project directory not found: $project_dir${NC}"
        exit 1
    }

    # Check if visual regression tool is configured
    local has_tool=0

    if [[ -f "$project_dir/playwright.config.ts" ]] || [[ -f "$project_dir/playwright.config.js" ]]; then
        has_tool=1
        echo -e "${BLUE}Detected Playwright${NC}"
    elif grep -q "cypress" "$project_dir/package.json" 2>/dev/null; then
        has_tool=1
        echo -e "${BLUE}Detected Cypress${NC}"
    elif [[ -f "$project_dir/.storybook/main.js" ]]; then
        has_tool=1
        echo -e "${BLUE}Detected Storybook (can use Chromatic)${NC}"
    fi

    if [[ $has_tool -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  No visual regression tool detected${NC}"
        echo -e "${YELLOW}   Skipping visual regression tests${NC}"
        echo -e "${YELLOW}   To enable, install Playwright or Cypress${NC}"
        exit 0
    fi

    # Create baseline directory if it doesn't exist
    mkdir -p "$project_dir/.ralph/visual-baselines"

    # Generate instruction for visual regression
    local instruction_file="$project_dir/.ralph/visual-regression-instruction.md"
    cat > "$instruction_file" << EOF
# Visual Regression Testing

## Setup:

### For Playwright:
\`\`\`bash
npx playwright test --update-snapshots  # Create baseline screenshots
\`\`\`

### For Cypress:
\`\`\`bash
npm run cypress:open
# Take screenshots of each important view
# Save to cypress/snapshots/
\`\`\`

## Run Visual Tests:

\`\`\`bash
npx playwright test  # Compare against baselines
\`\`\`

## Review Diffs:

If tests fail:
1. Open the diff report (usually in playwright-report/ or .ralph/visual-regression-report.html)
2. For each failed screenshot:
   - **If intentional change**: Update baseline
   - **If regression**: Fix the code

## Update Baselines:

\`\`\`bash
npx playwright test --update-snapshots
git add .ralph/visual-baselines/
git commit -m "ralph: GATE 6.9 - approve new visual baseline"
\`\`\`

## Visual Regression Checklist:

- [ ] Baseline screenshots exist
- [ ] All views screenshot correctly
- [ ] Diffs < 5% (or approved)
- [ ] No unintended visual changes
- [ ] Baselines committed to git
EOF

    echo -e "${GREEN}✅ Visual regression setup complete${NC}"
    echo -e "${YELLOW}Instruction generated: $instruction_file${NC}"
    echo -e "${YELLOW}Follow instructions to capture baselines and run tests${NC}"
}

cmd_performance_audit() {
    local project_dir="$1"

    echo -e "${BLUE}━━━ PERFORMANCE-AUDIT ━━━${NC}"

    [[ -d "$project_dir" ]] || {
        echo -e "${RED}❌ Project directory not found: $project_dir${NC}"
        exit 1
    }

    # Generate instruction for performance audit
    local instruction_file="$project_dir/.ralph/performance-audit-instruction.md"
    cat > "$instruction_file" << EOF
# Performance Audit

## Run Lighthouse:

### Option 1: Chrome DevTools
1. Open project in browser (npm run dev / npm start)
2. Open Chrome DevTools (F12)
3. Go to "Lighthouse" tab
4. Click "Generate report"

### Option 2: CLI
\`\`\`bash
npm install -g lighthouse
lighthouse http://localhost:3000 --output html --output-path .ralph/lighthouse-report.html
\`\`\`

## Performance Requirements:

### Lighthouse Score: ≥90
- Performance: ≥90
- Accessibility: ≥90
- Best Practices: ≥90
- SEO: ≥90

### Core Web Vitals:
- **LCP** (Largest Contentful Paint): <2.5s
- **FID** (First Input Delay): <100ms
- **CLS** (Cumulative Layout Shift): <0.1

### Bundle Size:
- **JavaScript**: <500KB gzipped
- **CSS**: <100KB gzipped
- **Images**: Optimized (use WebP/AVIF)

## Check Bundle Size:

### For Vite/Webpack:
\`\`\`bash
npm run build
# Check dist/ or build/ directory sizes
du -sh dist/*
\`\`\`

### For Next.js:
\`\`\`bash
npm run build
# Sizes shown in output
\`\`\`

## Common Fixes:

### If bundle too large:
- Code split with dynamic imports
- Remove unused dependencies
- Use tree-shaking

### If LCP slow:
- Optimize images (use next/image or similar)
- Preload critical resources
- Reduce server response time

### If CLS high:
- Set explicit width/height on images
- Reserve space for dynamic content
- Avoid layout shifts

## Performance Checklist:

- [ ] Lighthouse score ≥90 for all categories
- [ ] LCP <2.5s
- [ ] FID <100ms
- [ ] CLS <0.1
- [ ] Bundle size <500KB gzipped
- [ ] No duplicate dependencies
- [ ] Images optimized
EOF

    echo -e "${GREEN}✅ Performance audit setup complete${NC}"
    echo -e "${YELLOW}Instruction generated: $instruction_file${NC}"
    echo -e "${YELLOW}Follow instructions to run Lighthouse and check bundle size${NC}"
}

# ==============================================================================
# HELP & USAGE
# ==============================================================================

usage() {
    cat << 'EOF'
Design Ops v3.4 (Refactored) - Instruction-Based Pipeline

PHILOSOPHY: Script validates locally and generates instructions.
            Claude reads instructions and executes.
            No API calls. No subprocess LLM invocations.

USAGE: design-ops-v3-refactored.sh <command> <spec-file>

CORE COMMANDS (in order):

  stress-test <spec>       Check completeness (runs local validation)
  validate <spec>          Check clarity (runs structure validation)
  security-scan <spec>     Check security requirements
  generate <spec>          Generate PRP (outputs extraction instruction)
  check <prp>              Check PRP (validates structure)
  generate-tests <prp>     Generate test suite
  test-validate <test-dir> Validate tests fail correctly (RED state)
  test-quality <test-dir>  Check test quality (no weak assertions)
  preflight <project>      Check environment ready for TDD
  implement-tdd <project>  Implement code with TDD
  parallel-checks <project> Run build/lint/integration/a11y checks
  visual-regression <project> Screenshot testing
  smoke-test <project>     Run E2E critical paths
  ai-review <project>      AI security/quality review
  performance-audit <project> Lighthouse/bundle size audit

WORKFLOW:

  Step 1: ./design-ops-v3-refactored.sh stress-test specs/feature.md
          → Runs deterministic checks
          → Outputs: specs/feature.stress-test-instruction.md
          → You review the instruction, check spec completeness

  Step 2: ./design-ops-v3-refactored.sh validate specs/feature.md
          → Runs structure validation
          → Outputs: specs/feature.validate-instruction.md
          → You validate against 43 invariants

  Step 3: ./design-ops-v3-refactored.sh generate specs/feature.md
          → Extracts spec structure
          → Outputs: specs/feature.generate-instruction.md
          → You compile PRP using structured extraction

  Step 4: ./design-ops-v3-refactored.sh check PRPs/feature.prp.md
          → Validates PRP structure
          → Ready for implementation

  Step 5: ./design-ops-v3-refactored.sh implement PRPs/feature.prp.md
          → Extracts PRP structure
          → Outputs: PRPs/feature.implement-instruction.md
          → You generate ralph-steps using structured extraction

KEY PRINCIPLES:

  • Instruction-based: Script outputs instructions, Claude follows them
  • Local-first: Deterministic checks run locally, no API calls
  • Step ordering: Prerequisites enforced (can't skip steps)
  • Transparent: Instructions are readable files you can review
  • Human-controlled: You decide what to do, not the script

OPTIONS:

  --output <dir>          Output directory for instructions (default: current)
  --help                  Show this help

PHILOSOPHY:

  The script is NOT a judge. It's a CHECKLIST and INSTRUCTION GENERATOR.
  YOU are the agent. The script helps you stay on track.

EOF
    exit 1
}

# ==============================================================================
# MAIN
# ==============================================================================

[[ $# -lt 1 ]] && usage

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            INSTRUCTION_OUTPUT_DIR="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        create-spec|stress-test|validate|security-scan|generate|check|implement|generate-tests|test-validate|test-quality|preflight|implement-tdd|parallel-checks|visual-regression|smoke-test|ai-review|performance-audit)
            COMMAND="$1"
            shift
            break
            ;;
        *)
            echo -e "${RED}Unknown command: $1${NC}"
            usage
            ;;
    esac
done

# Route to command
case "$COMMAND" in
    create-spec) cmd_create_spec "$@" ;;
    stress-test) cmd_stress_test "$@" ;;
    validate) cmd_validate "$@" ;;
    security-scan) cmd_security_scan "$@" ;;
    generate) cmd_generate "$@" ;;
    check) cmd_check "$@" ;;
    implement) cmd_implement "$@" ;;
    generate-tests) cmd_generate_tests "$@" ;;
    test-validate) cmd_test_validate "$@" ;;
    test-quality) cmd_test_quality "$@" ;;
    preflight) cmd_preflight "$@" ;;
    implement-tdd) cmd_implement_tdd "$@" ;;
    parallel-checks) cmd_parallel_checks "$@" ;;
    visual-regression) cmd_visual_regression "$@" ;;
    smoke-test) cmd_smoke_test "$@" ;;
    ai-review) cmd_ai_review "$@" ;;
    performance-audit) cmd_performance_audit "$@" ;;
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        usage
        ;;
esac

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

  stress-test <spec>      Check completeness (runs local validation)
  validate <spec>         Check clarity (runs structure validation)
  generate <spec>         Generate PRP (outputs extraction instruction)
  check <prp>             Check PRP (validates structure)
  implement <prp>         Generate Ralph steps (outputs extraction instruction)

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
        create-spec|stress-test|validate|generate|check|implement|generate-tests|implement-tdd|parallel-checks|smoke-test|ai-review)
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
    generate) cmd_generate "$@" ;;
    check) cmd_check "$@" ;;
    implement) cmd_implement "$@" ;;
    generate-tests) cmd_generate_tests "$@" ;;
    implement-tdd) cmd_implement_tdd "$@" ;;
    parallel-checks) cmd_parallel_checks "$@" ;;
    smoke-test) cmd_smoke_test "$@" ;;
    ai-review) cmd_ai_review "$@" ;;
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        usage
        ;;
esac

#!/bin/bash
# ==============================================================================
# runner.sh - Core RALPH State Machine
# Universal 8-state pipeline for spec → code workflow
# Tool-agnostic (works with Claude Code, Cursor, Windsurf)
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESIGN_OPS_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ==============================================================================
# Configuration
# ==============================================================================

PROJECT_DIR="${PROJECT_DIR:-.}"
SPEC_FILE=""
TEST_COMMAND=""
TEST_PATH=""
TEST_FILTER=""
PHASE_START=1
PHASE_END=8
MAX_RETRIES=5
VERBOSE=false
DRY_RUN=false
RESUME=false
TOOL=""
PRP_FILE=""

# ==============================================================================
# State Order Mapping (1-8)
# ==============================================================================

get_state_order() {
    local state="$1"
    case "$state" in
        STRESS_TEST) echo 1 ;;
        VALIDATE) echo 2 ;;
        GENERATE_PRP) echo 3 ;;
        CHECK_PRP) echo 4 ;;
        GENERATE_TESTS) echo 5 ;;
        CHECK_TESTS) echo 6 ;;
        IMPLEMENT) echo 7 ;;
        COMPLETE) echo 8 ;;
        *) echo 0 ;;
    esac
}

get_next_state() {
    local current_order=$1
    case "$current_order" in
        1) echo "VALIDATE" ;;
        2) echo "GENERATE_PRP" ;;
        3) echo "CHECK_PRP" ;;
        4) echo "GENERATE_TESTS" ;;
        5) echo "CHECK_TESTS" ;;
        6) echo "IMPLEMENT" ;;
        7) echo "COMPLETE" ;;
        8) echo "COMPLETE" ;;
        *) echo "" ;;
    esac
}

# ==============================================================================
# Safety Guardrails
# ==============================================================================

validate_safety() {
    local command="$1"

    # CRITICAL: Block destructive patterns
    local dangerous_patterns=(
        "rm.*-rf.*/"          # rm -rf /anything
        "rm.*-rf.*\*"         # rm -rf *
        "mkfs"                # Format filesystem
        "dd.*if=.*of=/"       # Disk write to root
        ":(){.*};"            # Fork bomb
        ">/dev/sda"           # Write to disk device
        "chmod.*000.*/"       # Remove all permissions on root
        "shutdown\|reboot\|halt"  # System shutdown
    )

    for pattern in "${dangerous_patterns[@]}"; do
        if echo "$command" | grep -qiE "$pattern"; then
            return 1  # BLOCKED
        fi
    done

    return 0  # SAFE
}

# ==============================================================================
# Tool Detection
# ==============================================================================

detect_tool() {
    if command -v claude &>/dev/null; then
        echo "claude"
    elif command -v cursor &>/dev/null; then
        echo "cursor"
    elif command -v windsurf &>/dev/null; then
        echo "windsurf"
    else
        if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
            echo "claude-api"
        else
            echo ""
        fi
    fi
}

# ==============================================================================
# Config Management
# ==============================================================================

load_config() {
    local config_file="$PROJECT_DIR/.ralph/config"

    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
}

save_config() {
    mkdir -p "$PROJECT_DIR/.ralph"
    local config_file="$PROJECT_DIR/.ralph/config"

    cat > "$config_file" << EOF
# RALPH Configuration
SPEC_FILE=$SPEC_FILE
TEST_PATH=${TEST_PATH:-tests/}
TEST_FILTER=${TEST_FILTER:-}
EOF
}

# ==============================================================================
# Test Framework Detection
# ==============================================================================

detect_test_framework() {
    if [[ -f "$PROJECT_DIR/pytest.ini" ]] || [[ -f "$PROJECT_DIR/setup.py" ]] || [[ -f "$PROJECT_DIR/pyproject.toml" ]]; then
        local path="${TEST_PATH:-tests/}"
        echo "pytest $path -v --tb=short"
    elif [[ -f "$PROJECT_DIR/package.json" ]]; then
        echo "npm test"
    elif [[ -f "$PROJECT_DIR/go.mod" ]]; then
        echo "go test ./..."
    elif [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
        echo "cargo test"
    elif [[ -f "$PROJECT_DIR/build.gradle" ]] || [[ -f "$PROJECT_DIR/pom.xml" ]]; then
        echo "mvn test"
    else
        local path="${TEST_PATH:-tests/}"
        echo "pytest $path -v --tb=short"
    fi
}

# ==============================================================================
# PRP File Detection
# ==============================================================================

detect_prp_file() {
    local spec_base=$(basename "$SPEC_FILE" .md)
    spec_base="${spec_base%.spec}"

    if [[ -f "$PROJECT_DIR/prp/${spec_base}-prp.md" ]]; then
        echo "$PROJECT_DIR/prp/${spec_base}-prp.md"
    elif [[ -f "$PROJECT_DIR/prp/${spec_base}.prp.md" ]]; then
        echo "$PROJECT_DIR/prp/${spec_base}.prp.md"
    elif [[ -f "$PROJECT_DIR/prps/${spec_base}.md" ]]; then
        echo "$PROJECT_DIR/prps/${spec_base}.md"
    else
        echo "$PROJECT_DIR/prp/${spec_base}-prp.md"
    fi
}

# ==============================================================================
# Prompt Generation
# ==============================================================================

generate_prompt() {
    local state="$1"
    local command="$2"
    local pass_condition="$3"

    cat << EOF
# RALPH State Machine - Gate: $state

## Current State
State: **$state**
Pass Condition: "$pass_condition"

## Gate Command
\`\`\`bash
$command
\`\`\`

## Your Task

1. **Fresh Assessment** - Validate the artifact for THIS gate with clean eyes
2. **Run the gate command** above
3. **Does output contain pass condition?**
   - YES → Output: \`<ralph>PASS</ralph>\`
   - NO → Fix issue, loop within this gate only, re-run until it passes
4. **Once passing:**
   - Commit changes: \`git add -A && git commit -m "ralph: $state pass"\`
   - Output: \`<ralph>PASS</ralph>\`

## How This Gate Works
- **Input:** Artifact from previous gate (spec → PRP → tests → code)
- **Scope:** ONLY fix issues in THIS gate's artifact
- **Loop:** If issues found, fix and re-validate IN THIS GATE
- **Do NOT:** Go back to previous gates unless something is drastically broken
- **Output:** Passing artifact for next gate

## Important
- Fresh eyes for each validation (don't carry forward previous assessments)
- Focus only on passing this gate
- Don't modify .ralph/state.md manually
- Output exactly \`<ralph>PASS</ralph>\` when gate passes
EOF
}

# ==============================================================================
# State Management
# ==============================================================================

init_state() {
    mkdir -p "$PROJECT_DIR/.ralph"
    local state_file="$PROJECT_DIR/.ralph/state.md"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    cat > "$state_file" << EOF
# RALPH State

current_state: STRESS_TEST
retry_count: 0
max_retries: $MAX_RETRIES
started_at: $timestamp
history:
  - $timestamp | INIT -> STRESS_TEST
EOF
}

get_state() {
    local state_file="$PROJECT_DIR/.ralph/state.md"
    grep "^current_state:" "$state_file" | cut -d: -f2 | tr -d ' '
}

get_retry_count() {
    local state_file="$PROJECT_DIR/.ralph/state.md"
    grep "^retry_count:" "$state_file" | cut -d: -f2 | tr -d ' '
}

increment_retry() {
    local state_file="$PROJECT_DIR/.ralph/state.md"
    local current=$(get_retry_count)
    local next=$((current + 1))

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^retry_count:.*/retry_count: $next/" "$state_file"
    else
        sed -i "s/^retry_count:.*/retry_count: $next/" "$state_file"
    fi
}

transition_state() {
    local new_state="$1"
    local state_file="$PROJECT_DIR/.ralph/state.md"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local old_state=$(get_state)

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^current_state:.*/current_state: $new_state/" "$state_file"
        sed -i '' "s/^retry_count:.*/retry_count: 0/" "$state_file"
    else
        sed -i "s/^current_state:.*/current_state: $new_state/" "$state_file"
        sed -i "s/^retry_count:.*/retry_count: 0/" "$state_file"
    fi

    echo "  - $timestamp | $old_state -> $new_state" >> "$state_file"
}

# ==============================================================================
# Gate Result File (for background/autonomous mode)
# ==============================================================================

get_gate_result() {
    local result_file="$PROJECT_DIR/.ralph/gate-result"
    if [[ -f "$result_file" ]]; then
        cat "$result_file"
        rm "$result_file"
    fi
}

write_gate_result() {
    echo "$1" > "$PROJECT_DIR/.ralph/gate-result"
}

# ==============================================================================
# Command Execution
# ==============================================================================

get_gate_command() {
    local state="$1"

    case "$state" in
        STRESS_TEST)
            echo "$DESIGN_OPS_DIR/enforcement/design-ops-v3-refactored.sh stress-test {{spec_file}}"
            ;;
        VALIDATE)
            echo "$DESIGN_OPS_DIR/enforcement/design-ops-v3-refactored.sh validate {{spec_file}}"
            ;;
        GENERATE_PRP)
            echo "$DESIGN_OPS_DIR/enforcement/design-ops-v3-refactored.sh generate {{spec_file}}"
            ;;
        CHECK_PRP)
            echo "$DESIGN_OPS_DIR/enforcement/design-ops-v3-refactored.sh check {{prp_file}}"
            ;;
        GENERATE_TESTS)
            echo "pytest {{test_path}} --collect-only -q 2>&1"
            ;;
        CHECK_TESTS|IMPLEMENT)
            echo "{{test_command}}"
            ;;
        COMPLETE)
            echo "echo 'Pipeline complete'"
            ;;
        *)
            echo ""
            ;;
    esac
}

get_pass_condition() {
    local state="$1"

    case "$state" in
        STRESS_TEST) echo "Instruction generated" ;;
        VALIDATE) echo "Structure validation passed" ;;
        GENERATE_PRP) echo "generate-instruction.md" ;;
        CHECK_PRP) echo "PRP validation passed" ;;
        GENERATE_TESTS) echo "selected" ;;
        CHECK_TESTS) echo "passed" ;;
        IMPLEMENT) echo "passed" ;;
        COMPLETE) echo "Pipeline complete" ;;
        *) echo "" ;;
    esac
}

run_gate() {
    local state="$1"
    local command="$2"

    # Substitute variables
    command="${command//\{\{spec_file\}\}/$SPEC_FILE}"
    command="${command//\{\{prp_file\}\}/$PRP_FILE}"
    command="${command//\{\{test_command\}\}/$TEST_COMMAND}"
    command="${command//\{\{test_path\}\}/${TEST_PATH:-tests/}}"

    if $DRY_RUN; then
        echo -e "${YELLOW}[DRY RUN] Would run:${NC}"
        echo "$command"
        return 0
    fi

    echo -e "${CYAN}Running: $command${NC}"
    cd "$PROJECT_DIR"
    eval "$command" 2>&1 || true
}

check_gate_condition() {
    local state="$1"
    local pass_condition="$2"

    # For deterministic gates, check if condition is present in recent git/files
    case "$state" in
        STRESS_TEST)
            # Check if instruction file was generated
            if [[ -f "$PROJECT_DIR/$SPEC_FILE"*"-stress-test-instruction.md" ]]; then
                return 0
            fi
            return 1
            ;;
        VALIDATE)
            # Check if validation instruction exists
            if [[ -f "$PROJECT_DIR/$SPEC_FILE"*"-validate-instruction.md" ]]; then
                return 0
            fi
            return 1
            ;;
        GENERATE_PRP)
            # Check if PRP was generated
            if [[ -f "$PRP_FILE" ]]; then
                return 0
            fi
            return 1
            ;;
        CHECK_PRP)
            # Check if PRP structure is valid
            if grep -q "## Meta" "$PRP_FILE" 2>/dev/null; then
                return 0
            fi
            return 1
            ;;
        GENERATE_TESTS)
            # Check if tests exist
            if [[ -f "$PROJECT_DIR/${TEST_PATH:-tests/}test_"*.py ]] || [[ -f "$PROJECT_DIR/${TEST_PATH:-tests/}/"*.test.ts ]]; then
                return 0
            fi
            return 1
            ;;
        CHECK_TESTS)
            # Run test command and check for "passed"
            cd "$PROJECT_DIR"
            if eval "$TEST_COMMAND" 2>&1 | grep -qi "passed\|all tests passed\|✅"; then
                return 0
            fi
            return 1
            ;;
        IMPLEMENT)
            # Check if components exist
            if [[ -n $(find "$PROJECT_DIR" -name "*.tsx" -o -name "*.ts" | head -1) ]]; then
                return 0
            fi
            return 1
            ;;
        COMPLETE)
            return 0
            ;;
    esac

    return 0
}

invoke_tool() {
    local state="$1"
    local command="$2"
    local pass_condition="$3"

    local prompt=$(generate_prompt "$state" "$command" "$pass_condition")

    if [[ -z "$TOOL" ]]; then
        TOOL=$(detect_tool)
    fi

    case "$TOOL" in
        claude)
            echo "$prompt" | claude "$@" || true
            ;;
        cursor)
            echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
            echo -e "${CYAN}Cursor: Read and execute the prompt below:${NC}"
            echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
            echo "$prompt"
            echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
            ;;
        windsurf)
            echo "$prompt" | windsurf "$@" || true
            ;;
        claude-api|*)
            echo -e "${YELLOW}No LLM tool detected. Paste this into your Claude conversation:${NC}"
            echo ""
            echo "$prompt"
            ;;
    esac
}

# ==============================================================================
# Main Loop
# ==============================================================================

auto_commit_changes() {
    local gate_name="$1"
    cd "$PROJECT_DIR"

    # Check for changes
    if git diff --quiet && git diff --cached --quiet; then
        return 0  # No changes
    fi

    # Stage all changes
    git add -A

    # Commit with gate name
    git commit -m "ralph: $gate_name - fixes and adjustments" 2>&1 || true

    echo -e "${GREEN}✅ Committed changes for $gate_name${NC}"
}

run_state_machine() {
    local iteration=0
    local log_file="$PROJECT_DIR/.ralph/runner.log"

    # Initialize state if needed
    if [[ ! -f "$PROJECT_DIR/.ralph/state.md" ]] && [[ "$RESUME" != "true" ]]; then
        init_state
    fi

    # Detect test command if not set
    if [[ -z "$TEST_COMMAND" ]]; then
        TEST_COMMAND=$(detect_test_framework)
    fi

    # Detect PRP file if not set
    if [[ -z "$PRP_FILE" ]]; then
        PRP_FILE=$(detect_prp_file)
    fi

    # Log start
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] RALPH runner started (spec: $SPEC_FILE)" >> "$log_file"

    while true; do
        iteration=$((iteration + 1))

        local current_state=$(get_state)
        local current_order=$(get_state_order "$current_state")
        local retry_count=$(get_retry_count)

        # Check if we've reached the end
        if [[ "$current_state" == "COMPLETE" ]]; then
            echo -e "${GREEN}✅ Pipeline Complete!${NC}"
            echo -e "${GREEN}All 8 gates passed with stateless validation and automatic commits.${NC}"
            echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] RALPH runner COMPLETE - all 8 gates passed" >> "$log_file"
            return 0
        fi

        # Check phase filtering
        if [[ $current_order -lt $PHASE_START ]] || [[ $current_order -gt $PHASE_END ]]; then
            transition_state "COMPLETE"
            continue
        fi

        # Check retry limit
        if [[ $retry_count -ge $MAX_RETRIES ]]; then
            echo -e "${RED}🚨 GUTTER: Max retries exceeded for $current_state${NC}"
            echo -e "${YELLOW}Fix manually and run: $0 --resume${NC}"
            return 1
        fi

        # Get gate info
        local command=$(get_gate_command "$current_state")
        local pass_condition=$(get_pass_condition "$current_state")

        echo ""
        echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}State: $current_state (order: $current_order, retry: $retry_count/$MAX_RETRIES)${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${MAGENTA}Stateless Context: Fresh assessment only${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

        # Log gate invocation
        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] GATE $current_state (order: $current_order, retry: $retry_count) - INVOKED" >> "$log_file"

        # Invoke tool with prompt
        invoke_tool "$current_state" "$command" "$pass_condition"

        # Try auto-detection first
        local auto_result=""
        if check_gate_condition "$current_state" "$pass_condition"; then
            auto_result="pass"
            echo ""
            echo -e "${GREEN}✅ Auto-detected gate completion${NC}"
        fi

        # Try gate result file (LLM input)
        local file_result=$(get_gate_result)
        local result=""

        if [[ -n "$file_result" ]]; then
            result="$file_result"
            echo -e "${GREEN}✅ LLM result from .ralph/gate-result: $result${NC}"
        elif [[ -n "$auto_result" ]]; then
            result="$auto_result"
        # If TTY available, ask user
        elif [[ -t 0 ]]; then
            echo ""
            read -p "Gate result? (pass/fail/skip): " -r result
        else
            echo ""
            echo -e "${CYAN}Waiting for LLM assessment (timeout: 180s)${NC}"
            echo -e "${CYAN}Write result to: ${PROJECT_DIR}/.ralph/gate-result${NC}"

            # Poll for gate-result file (180s timeout)
            local wait_count=0
            local max_wait=180
            while [[ ! -f "$PROJECT_DIR/.ralph/gate-result" ]] && [[ $wait_count -lt $max_wait ]]; do
                sleep 1
                wait_count=$((wait_count + 1))
                if [[ $((wait_count % 30)) -eq 0 ]]; then
                    echo -e "${DIM}...waiting ($wait_count/$max_wait)${NC}"
                fi
            done

            if [[ -f "$PROJECT_DIR/.ralph/gate-result" ]]; then
                result=$(get_gate_result)
            else
                echo -e "${RED}❌ Timeout (180s) waiting for LLM result${NC}"
                return 1
            fi
        fi

        case "$result" in
            pass|PASS|y|yes)
                echo -e "${GREEN}✅ Gate passed${NC}"

                # Auto-commit changes from this gate
                auto_commit_changes "$current_state"

                # Log gate pass
                echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] GATE $current_state - PASSED (retry: $retry_count)" >> "$log_file"

                # Transition to next state
                local next_state=$(get_next_state "$current_order")
                transition_state "$next_state"
                ;;
            fail|FAIL|n|no)
                echo -e "${RED}❌ Gate failed, retrying...${NC}"
                increment_retry

                # Log gate failure
                echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] GATE $current_state - FAILED (retry: $retry_count -> $((retry_count + 1)))" >> "$log_file"
                ;;
            skip)
                echo -e "${YELLOW}Skipping to next state${NC}"
                local next_state=$(get_next_state "$current_order")
                transition_state "$next_state"

                # Log gate skip
                echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] GATE $current_state - SKIPPED" >> "$log_file"
                ;;
            *)
                echo -e "${YELLOW}Invalid input. Try again.${NC}"
                ;;
        esac
    done
}

# ==============================================================================
# Argument Parsing
# ==============================================================================

usage() {
    cat << EOF
RALPH Runner - Spec to Code Pipeline

Usage: $(basename "$0") [OPTIONS]

Options:
  --state-machine           Run full state machine
  --spec FILE              Spec file path (required)
  --test-path PATH         Test directory (auto-detected if not set)
  --test-filter FILTER     Run only tests matching filter
  --test-command CMD       Custom test command (auto-detected if not set)
  --phase N                Only run phase N (1-8)
  --from-phase N           Start from phase N
  --to-phase N             End at phase N
  --only-tests             Only generate and run tests (phases 5-7)
  --init                   Initialize project config
  --resume                 Resume from last state
  --dry-run                Preview without executing
  --verbose                Verbose output
  -h, --help               Show this help

Examples:
  # Initialize project
  $(basename "$0") --init --spec specs/my-feature.md

  # Run full pipeline
  $(basename "$0") --state-machine --spec specs/my-feature.md

  # Only hypothesis tests
  $(basename "$0") --state-machine --spec specs/hypothesis-mode.md --test-filter hypothesis

  # Resume after GUTTER
  $(basename "$0") --state-machine --resume

  # Only implementation phase
  $(basename "$0") --state-machine --from-phase 7 --spec specs/my-feature.md

EOF
    exit 0
}

INIT_MODE=false
STATE_MACHINE_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --state-machine)
            STATE_MACHINE_MODE=true
            shift
            ;;
        --spec)
            SPEC_FILE="$2"
            shift 2
            ;;
        --test-path)
            TEST_PATH="$2"
            shift 2
            ;;
        --test-filter)
            TEST_FILTER="$2"
            shift 2
            ;;
        --test-command)
            TEST_COMMAND="$2"
            shift 2
            ;;
        --phase)
            PHASE_START="$2"
            PHASE_END="$2"
            shift 2
            ;;
        --from-phase)
            PHASE_START="$2"
            shift 2
            ;;
        --to-phase)
            PHASE_END="$2"
            shift 2
            ;;
        --only-tests)
            PHASE_START=5
            PHASE_END=7
            shift
            ;;
        --init)
            INIT_MODE=true
            shift
            ;;
        --resume)
            RESUME=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Handle init mode after all arguments parsed
if [[ "$INIT_MODE" == "true" ]]; then
    echo "Initializing RALPH project..."
    if [[ -z "$SPEC_FILE" ]]; then
        read -p "Spec file path: " -r SPEC_FILE
    fi
    save_config
    init_state
    echo -e "${GREEN}✅ Initialized. Run: $0 --state-machine${NC}"
    exit 0
fi

# ==============================================================================
# Validation & Execution
# ==============================================================================

if [[ -z "$SPEC_FILE" ]]; then
    load_config
fi

if [[ -z "$SPEC_FILE" ]]; then
    echo -e "${RED}Error: --spec required or missing .ralph/config${NC}"
    echo "Run: $0 --init --spec <spec-file>"
    exit 1
fi

# Run state machine if not in init mode
if [[ "$INIT_MODE" != "true" ]]; then
    run_state_machine
fi

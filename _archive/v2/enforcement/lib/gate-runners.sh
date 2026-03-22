#!/bin/bash

# gate-runners.sh - Execute gates with Cursor CLI integration
# Part of the RALPH Design-Ops enforcement system

set -euo pipefail

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/cursor-prompts.sh"
source "$LIB_DIR/validation.sh"
source "$LIB_DIR/state.sh"

# Configuration
DEFAULT_MAX_ITERATIONS=5
CURSOR_MODEL="${CURSOR_MODEL:-opus-4.5}"

# Core gate runner function
run_gate_with_cursor() {
    local gate_cmd="$1"
    local target_file="$2"
    local max_iterations="${3:-$DEFAULT_MAX_ITERATIONS}"
    local workspace="${4:-$(pwd)}"

    echo "🚀 Starting gate: $gate_cmd"
    echo "   Target: $target_file"
    echo "   Max iterations: $max_iterations"
    echo "   Workspace: $workspace"
    echo ""

    for iteration in $(seq 1 "$max_iterations"); do
        echo "🔄 Iteration $iteration/$max_iterations"

        # 1. Run design-ops validation
        echo "   ├─ Running validation..."
        local validation_result
        if ! validation_result=$(run_validation "$gate_cmd" "$target_file" 2>&1); then
            local exit_code=$?
            echo "   ├─ Validation FAILED (exit code: $exit_code)"

            # 2. Check if we have an instruction file
            local instruction_file
            if [[ "$gate_cmd" == "create-spec" ]]; then
                # For create-spec, instruction is in current directory
                instruction_file="./create-spec-instruction.md"
            elif [[ "$gate_cmd" == "implement" ]]; then
                # For implement, instruction is in output_dir (second part after colon)
                local prp_file="${target_file%%:*}"
                local output_dir="${target_file#*:}"
                local basename=$(basename "$prp_file" .md)
                instruction_file="${output_dir}/${basename}.${gate_cmd}-instruction.md"
            else
                # Instruction files are generated in current dir with basename of target file
                local basename=$(basename "$target_file" .md)
                instruction_file="./${basename}.${gate_cmd}-instruction.md"
            fi

            if [[ ! -f "$instruction_file" ]]; then
                echo "   └─ ❌ No instruction file generated. Cannot proceed."
                echo "   └─ Expected: $instruction_file"
                return 1
            fi

            # 3. Read instruction and extract feedback
            local instruction
            instruction=$(cat "$instruction_file")
            local feedback
            feedback=$(extract_feedback_from_validation "$validation_result")

            # 4. Build Cursor prompt
            echo "   ├─ Building Cursor prompt..."
            local cursor_prompt
            cursor_prompt=$(build_cursor_prompt_for_gate "$gate_cmd" "$target_file" "$instruction" "$feedback")

            # 5. Call Cursor CLI
            echo "   ├─ Invoking Cursor CLI (model: $CURSOR_MODEL)..."
            if ! cursor agent --print --model "$CURSOR_MODEL" \
                --workspace "$workspace" \
                "$cursor_prompt"; then
                echo "   └─ ⚠️  Cursor invocation failed, continuing to next iteration..."
            fi

            # 6. Save iteration state
            save_iteration_state "$gate_cmd" "$target_file" "$iteration" "$validation_result"

            echo "   └─ Iteration $iteration complete"
            echo ""
        else
            # Gate passed!
            echo "   └─ ✅ Validation PASSED"
            echo ""
            echo "✅ Gate $gate_cmd PASSED on iteration $iteration"
            return 0
        fi
    done

    # Failed after max iterations
    echo "❌ Gate $gate_cmd FAILED after $max_iterations iterations"
    echo ""
    return 1
}

# Extract feedback from validation output
extract_feedback_from_validation() {
    local validation_output="$1"

    # Extract lines after "FEEDBACK:" or "ISSUES:" markers
    echo "$validation_output" | awk '
        /FEEDBACK:|ISSUES:|VIOLATIONS:|GAPS:|FAILURES:/ { capture=1; next }
        capture && /^$/ { exit }
        capture { print }
    '
}

# Build Cursor prompt based on gate type
build_cursor_prompt_for_gate() {
    local gate_cmd="$1"
    local target_file="$2"
    local instruction="$3"
    local feedback="$4"

    case "$gate_cmd" in
        create-spec)
            # Split target_file on colon: req_dir:spec_file
            local req_dir="${target_file%%:*}"
            local spec_file="${target_file#*:}"
            build_create_spec_prompt "$req_dir" "$spec_file" "$instruction"
            ;;
        implement)
            # Split target_file on colon: prp_file:output_dir
            local prp_file="${target_file%%:*}"
            local output_dir="${target_file#*:}"
            build_implement_prompt "$prp_file" "$output_dir" "$instruction" "$feedback"
            ;;
        stress-test)
            build_fix_gaps_prompt "$target_file" "$feedback"
            ;;
        validate)
            build_fix_violations_prompt "$target_file" "$feedback"
            ;;
        generate)
            local prp_file="${target_file%.md}-PRP.md"
            build_generate_prp_prompt "$target_file" "$prp_file" "$instruction"
            ;;
        check)
            build_fix_prp_prompt "$target_file" "$feedback"
            ;;
        generate-tests)
            local test_dir="$(dirname "$target_file")/tests"
            build_generate_tests_prompt "$target_file" "$test_dir" "$instruction"
            ;;
        implement-tdd)
            build_implement_tdd_prompt "$feedback" "$target_file"
            ;;
        parallel-checks)
            build_fix_parallel_checks_prompt "$feedback" "$target_file"
            ;;
        smoke-test)
            build_fix_smoke_test_prompt "$feedback" "$target_file"
            ;;
        ai-review)
            build_fix_security_prompt "$feedback" "$target_file"
            ;;
        *)
            # Fallback to base prompt
            build_cursor_base_prompt "$instruction" "$feedback" "$target_file"
            ;;
    esac
}

# Run validation using design-ops.sh
run_validation() {
    local gate_cmd="$1"
    local target_file="$2"

    # Find design-ops.sh
    local design_ops_script="$LIB_DIR/../design-ops-v3-refactored.sh"
    if [[ ! -f "$design_ops_script" ]]; then
        design_ops_script="$LIB_DIR/../design-ops-v3.sh"
    fi

    if [[ ! -f "$design_ops_script" ]]; then
        echo "ERROR: Could not find design-ops.sh" >&2
        return 1
    fi

    # Special handling for gates that take 2 arguments
    if [[ "$gate_cmd" == "create-spec" ]] || [[ "$gate_cmd" == "implement" ]]; then
        # Split target_file on colon: first:second
        local first_arg="${target_file%%:*}"
        local second_arg="${target_file#*:}"
        "$design_ops_script" "$gate_cmd" "$first_arg" "$second_arg"
    else
        # Standard gate: single target file
        "$design_ops_script" "$gate_cmd" "$target_file"
    fi
}

# Save iteration state for debugging
save_iteration_state() {
    local gate_cmd="$1"
    local target_file="$2"
    local iteration="$3"
    local validation_result="$4"

    local state_dir=".design-ops/iterations"
    mkdir -p "$state_dir"

    local state_file="$state_dir/${gate_cmd}-$(basename "$target_file")-iter${iteration}.log"
    cat > "$state_file" <<EOF
Gate: $gate_cmd
Target: $target_file
Iteration: $iteration
Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

VALIDATION RESULT:
$validation_result
EOF

    echo "   ├─ State saved to: $state_file"
}

# Run full pipeline from requirements to code
run_full_pipeline() {
    local req_dir="$1"
    local output_dir="${2:-.}"
    local workspace="${3:-$(pwd)}"

    echo "🏗️  Running full RALPH pipeline"
    echo "   Requirements: $req_dir"
    echo "   Output: $output_dir"
    echo ""

    # Gate 0: Create spec
    local spec_file="$output_dir/spec.md"
    if ! run_gate_with_cursor "create-spec" "$req_dir" 5 "$workspace"; then
        echo "❌ Pipeline failed at Gate 0: CREATE_SPEC"
        return 1
    fi

    # Gate 1: Stress test
    if ! run_gate_with_cursor "stress-test" "$spec_file" 5 "$workspace"; then
        echo "❌ Pipeline failed at Gate 1: STRESS_TEST"
        return 1
    fi

    # Gate 2: Validate
    if ! run_gate_with_cursor "validate" "$spec_file" 5 "$workspace"; then
        echo "❌ Pipeline failed at Gate 2: VALIDATE"
        return 1
    fi

    # Gate 3: Generate PRP
    local prp_file="$output_dir/PRP.md"
    if ! run_gate_with_cursor "generate" "$spec_file" 5 "$workspace"; then
        echo "❌ Pipeline failed at Gate 3: GENERATE_PRP"
        return 1
    fi

    # Gate 4: Check PRP
    if ! run_gate_with_cursor "check" "$prp_file" 5 "$workspace"; then
        echo "❌ Pipeline failed at Gate 4: CHECK_PRP"
        return 1
    fi

    # Gate 5: Generate tests
    if ! run_gate_with_cursor "generate-tests" "$prp_file" 5 "$workspace"; then
        echo "❌ Pipeline failed at Gate 5: GENERATE_TESTS"
        return 1
    fi

    # Gate 6: Implement TDD
    local test_dir="$output_dir/tests"
    if ! run_gate_with_cursor "implement-tdd" "$test_dir" 10 "$workspace"; then
        echo "❌ Pipeline failed at Gate 6: IMPLEMENT_TDD"
        return 1
    fi

    # Gate 6.5: Parallel checks
    if ! run_gate_with_cursor "parallel-checks" "$output_dir" 5 "$workspace"; then
        echo "❌ Pipeline failed at Gate 6.5: PARALLEL_CHECKS"
        return 1
    fi

    # Gate 7: Smoke test
    if ! run_gate_with_cursor "smoke-test" "$output_dir" 5 "$workspace"; then
        echo "❌ Pipeline failed at Gate 7: SMOKE_TEST"
        return 1
    fi

    # Gate 8: AI review
    if ! run_gate_with_cursor "ai-review" "$output_dir" 5 "$workspace"; then
        echo "❌ Pipeline failed at Gate 8: AI_REVIEW"
        return 1
    fi

    echo ""
    echo "✅ Full pipeline completed successfully!"
    echo "   Spec: $spec_file"
    echo "   PRP: $prp_file"
    echo "   Tests: $test_dir"
    echo "   Code: $output_dir"
    return 0
}

# Export functions
export -f run_gate_with_cursor
export -f extract_feedback_from_validation
export -f build_cursor_prompt_for_gate
export -f run_validation
export -f save_iteration_state
export -f run_full_pipeline

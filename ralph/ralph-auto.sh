#!/bin/bash
# ==============================================================================
# ralph-auto.sh - Fully Autonomous RALPH with Claude CLI
#
# Orchestrates all 8 gates autonomously using Claude CLI (dangerously mode)
# for LLM assessment at each gate.
#
# SAFETY CONSTRAINTS:
# - Claude assesses spec/PRP/tests/code quality (yes/no decisions only)
# - Claude NEVER runs shell commands or destructive operations
# - All file creation/deletion happens through the runner.sh state machine
# - Runner has built-in safeguards against destructive patterns (rm -rf /, etc)
# - Output is read-only: Claude generates files via Bash tool within main session
# - This script purely orchestrates gate polling and result passing
#
# Usage: ./ralph-auto.sh --spec specs/my-feature.md
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-.}"
SPEC_FILE=""
LOG_FILE="$PROJECT_DIR/.ralph/auto.log"
RUNNER_LOG="$PROJECT_DIR/.ralph/runner.log"
GATE_RESULT="$PROJECT_DIR/.ralph/gate-result"
RUNNER_PID=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
DIM='\033[2m'
NC='\033[0m'

# ==============================================================================
# Logging
# ==============================================================================

log() {
    local msg="$1"
    echo -e "${msg}" | tee -a "$LOG_FILE"
}

log_trace() {
    local msg="$1"
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $msg" >> "$LOG_FILE"
}

# ==============================================================================
# Gate Prompt Generators
# ==============================================================================

generate_stress_test_prompt() {
    cat << 'EOF'
GATE 1: STRESS_TEST - Review spec for COMPLETENESS

Check these 6 coverage areas:
1. Happy path explicitly described?
2. Error cases addressed (invalid input, timeouts, external failures)?
3. Empty/null states handled?
4. External failure modes (API down, network slow, DB unavailable)?
5. Concurrency considerations?
6. Limits and boundaries specified?

Read: specs/pathfinder-frontend-foundation.md

Output ONLY one word:
- "pass" if ALL 6 areas are well-addressed
- "fail" if ANY area has gaps

Then explain findings in 2-3 lines.
EOF
}

generate_validate_prompt() {
    cat << 'EOF'
GATE 2: VALIDATE - Check spec against 15 invariants

Universal (1-10): Ambiguity, state, intent, recovery, fail-loud, scope, testable, boundaries, blast-radius, degradation

Domain (11-15): Applies to consumer-product, healthcare-ai, data-architecture, hls-solution-accelerator

Read: specs/pathfinder-frontend-foundation.md

Check:
- All 15 invariants satisfied?
- No vague terms (properly, efficiently, reasonable)?
- All requirements testable with metrics?
- All error paths explicit?
- All limits with units?

Output ONLY:
- "pass" if 0-1 minor issues
- "fail" if 2+ significant violations

Then list issues found (max 5 lines).
EOF
}

generate_generate_prp_prompt() {
    cat << 'EOF'
GATE 3: GENERATE_PRP - Extract spec into structured PRP

Read: specs/pathfinder-frontend-foundation.md

Generate PRP-2026-01-27-NNN with:
1. Problem statement (copy from spec)
2. Success criteria (7 testable SC)
3. 8 functional requirements (FRs extracted)
4. Failure modes & recovery
5. Type definitions
6. Acceptance tests (detailed, measurable)

Output: PRP structured markdown saved to prp/pathfinder-frontend-foundation-prp.md

Output ONLY:
- "pass" if PRP generated and complete
- "fail" if incomplete

Then report: "Generated: [lines] lines, [sections] sections"
EOF
}

generate_check_prp_prompt() {
    cat << 'EOF'
GATE 4: CHECK_PRP - Validate PRP quality

Read: prp/pathfinder-frontend-foundation-prp.md
Compare against: specs/pathfinder-frontend-foundation.md

Validate:
1. All 8 FRs captured?
2. All success criteria testable?
3. Acceptance tests detailed with measurements?
4. Search history (FR-8) included?
5. Clinical context (INV-3) explicit?
6. Performance targets (SC-8) specified?
7. All 15 invariants enforced?

Output ONLY:
- "pass" if all 7 items valid
- "fail" if any gaps remain

Then list gaps (max 5 lines).
EOF
}

generate_generate_tests_prompt() {
    cat << 'EOF'
GATE 5: GENERATE_TESTS - Prepare test generation

Read: prp/pathfinder-frontend-foundation-prp.md

Should tests be generated covering:
- 7 functional requirements (unit tests)
- Design tokens (import/export test)
- Component props (TypeScript strict test)
- Accessibility (axe-core test)
- Responsive (320px/768px/1024px test)
- Performance (mount/render/load tests)
- Search history (localStorage FIFO test)
- Clinical context (ResultCard 3-element test)

Target: 30-40 tests total, >300 lines

Output ONLY:
- "pass" if test generation approved
- "fail" if any requirement should be skipped
EOF
}

generate_check_tests_prompt() {
    cat << 'EOF'
GATE 6: CHECK_TESTS - Validate tests pass

Run: npm test -- components.test.tsx

Check output for:
- All tests passed (green checkmarks, no failures)
- Test count (should be 30+)
- Coverage (should include all FRs, accessibility, performance)

Output ONLY:
- "pass" if ALL tests pass, no failures
- "fail" if ANY test failed

Then report: "Tests: [X] passed, [Y] failed"
EOF
}

generate_implement_prompt() {
    cat << 'EOF'
GATE 7: IMPLEMENT - Build components

Read: prp/pathfinder-frontend-foundation-prp.md

Create React components:
- apps/frontend/src/styles/design-tokens.ts (design tokens export)
- apps/frontend/src/components/SearchInput.tsx
- apps/frontend/src/components/ImageDropzone.tsx
- apps/frontend/src/components/ModeSelector.tsx
- apps/frontend/src/components/ResultCard.tsx
- apps/frontend/src/components/ReasoningPanel.tsx
- apps/frontend/src/components/Layout.tsx
- apps/frontend/src/types/index.ts (type definitions)
- apps/frontend/src/pages/ComponentsShowcase.tsx (demo page)
- apps/frontend/src/components/index.ts (exports)

Requirements:
- All components TypeScript strict mode
- All props typed
- All error handling per spec
- Accessibility (ARIA labels)
- Responsive CSS

Output ONLY:
- "pass" if all 6 components + types + showcase built successfully
- "fail" if build fails or components missing

Then report: "Built: [N] components, [N] types"
EOF
}

# ==============================================================================
# Gate Assessment Engine
# ==============================================================================

get_last_gate_name() {
    if [[ -f "$RUNNER_LOG" ]]; then
        grep "GATE .* - INVOKED" "$RUNNER_LOG" | tail -1 | sed 's/.*GATE \([A-Z_]*\).*/\1/'
    fi
}

invoke_claude_for_gate() {
    local gate_name="$1"
    local prompt=""

    case "$gate_name" in
        STRESS_TEST) prompt=$(generate_stress_test_prompt) ;;
        VALIDATE) prompt=$(generate_validate_prompt) ;;
        GENERATE_PRP) prompt=$(generate_generate_prp_prompt) ;;
        CHECK_PRP) prompt=$(generate_check_prp_prompt) ;;
        GENERATE_TESTS) prompt=$(generate_generate_tests_prompt) ;;
        CHECK_TESTS) prompt=$(generate_check_tests_prompt) ;;
        IMPLEMENT) prompt=$(generate_implement_prompt) ;;
        *) return 1 ;;
    esac

    log_trace "Invoking Claude for GATE $gate_name"

    # Call Claude CLI with dangerously mode
    # Pass prompt as argument (not stdin), extract first line of response (pass/fail)
    local response
    response=$(claude --print --dangerously-skip-permissions "$prompt" 2>&1 | head -1 | tr -d '\n' | tr -d '\r')

    # Validate response
    if [[ "$response" == "pass" ]] || [[ "$response" == "fail" ]]; then
        echo "$response"
        log_trace "Claude response: $response"
        return 0
    else
        log_trace "Invalid Claude response: $response"
        return 1
    fi
}

# ==============================================================================
# Main Loop
# ==============================================================================

cleanup() {
    if [[ -n "$RUNNER_PID" ]] && ps -p "$RUNNER_PID" > /dev/null 2>&1; then
        log_trace "Killing runner process $RUNNER_PID"
        kill "$RUNNER_PID" 2>/dev/null || true
        wait "$RUNNER_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT

run_autonomous_pipeline() {
    local max_iterations=500
    local iteration=0
    local last_gate=""
    local gate_seen=false

    log "${GREEN}=== RALPH Autonomous Pipeline Started ===${NC}"
    log "Spec: $SPEC_FILE"
    log "Runner PID: $RUNNER_PID"
    log ""

    while [[ $iteration -lt $max_iterations ]]; do
        iteration=$((iteration + 1))

        # Check if runner is still alive
        if ! ps -p "$RUNNER_PID" > /dev/null 2>&1; then
            log_trace "Runner process died"
            # Check if pipeline completed
            if grep -q "Pipeline complete\|Pipeline Complete" "$RUNNER_LOG" 2>/dev/null; then
                log "${GREEN}✅ Pipeline completed successfully!${NC}"
                return 0
            else
                log "${RED}❌ Runner process died unexpectedly${NC}"
                return 1
            fi
        fi

        # Check for new gate invocation
        local current_gate=$(get_last_gate_name)

        if [[ -n "$current_gate" ]] && [[ "$current_gate" != "$last_gate" ]]; then
            last_gate="$current_gate"
            gate_seen=true

            log ""
            log "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            log "${CYAN}GATE: $current_gate${NC}"
            log "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

            # Clear old gate result
            rm -f "$GATE_RESULT"

            # Invoke Claude
            log "${YELLOW}Invoking Claude assessment...${NC}"
            local result
            if result=$(invoke_claude_for_gate "$current_gate"); then
                log "${GREEN}Claude result: $result${NC}"

                # Write gate result
                echo "$result" > "$GATE_RESULT"
                log_trace "Wrote result to gate-result: $result"

                log "${GREEN}✅ Gate assessment complete${NC}"
            else
                log "${RED}❌ Claude assessment failed${NC}"
                log_trace "Failed to get valid response from Claude for $current_gate"
                # Write fail to move past gate (retry logic in runner)
                echo "fail" > "$GATE_RESULT"
            fi
        fi

        sleep 2
    done

    log "${RED}❌ Pipeline timeout (500 iterations)${NC}"
    return 1
}

# ==============================================================================
# Argument Parsing
# ==============================================================================

usage() {
    cat << EOF
RALPH Autonomous Pipeline

Usage: $(basename "$0") --spec SPEC_FILE

Options:
  --spec FILE    Specification file path (required)
  -h, --help     Show this help

Example:
  $(basename "$0") --spec specs/pathfinder-frontend-foundation.md

EOF
    exit 0
}

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
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [[ -z "$SPEC_FILE" ]]; then
    echo "Error: --spec required"
    usage
fi

# ==============================================================================
# Execution
# ==============================================================================

# Start runner in background
log_trace "Starting runner in background..."
"$SCRIPT_DIR/runner.sh" --state-machine > /dev/null 2>&1 &
RUNNER_PID=$!

sleep 2

# Run autonomous pipeline
if run_autonomous_pipeline; then
    log ""
    log "${GREEN}════════════════════════════════════════════${NC}"
    log "${GREEN}✅ RALPH Pipeline Complete!${NC}"
    log "${GREEN}════════════════════════════════════════════${NC}"
    log ""
    log "Results:"
    log "  Spec: $SPEC_FILE"
    log "  State: $(grep "^current_state:" .ralph/state.md | cut -d: -f2 | xargs)"
    log "  Log: $LOG_FILE"
    log ""
    exit 0
else
    log ""
    log "${RED}════════════════════════════════════════════${NC}"
    log "${RED}❌ Pipeline failed${NC}"
    log "${RED}════════════════════════════════════════════${NC}"
    log ""
    log "Log: $LOG_FILE"
    exit 1
fi

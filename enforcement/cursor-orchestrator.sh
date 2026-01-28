#!/bin/bash

# cursor-orchestrator.sh - Main orchestrator for RALPH Design-Ops with Cursor CLI
#
# This orchestrator uses Cursor CLI as the generator for ALL gates,
# with Claude Code (via design-ops.sh) as the validator and loop controller.
#
# Architecture:
#   1. Claude: ./design-ops.sh <gate> <file> → instruction.md + feedback
#   2. Claude: Read instruction + feedback
#   3. Claude: cursor agent --model opus-4.5 "<prompt>"
#   4. Cursor: Generate/fix the file
#   5. Claude: Loop back to step 1 until PASS
#
# Usage:
#   ./cursor-orchestrator.sh <gate> <target-file> [max-iterations] [workspace]
#   ./cursor-orchestrator.sh pipeline <req-dir> [output-dir] [workspace]

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "$SCRIPT_DIR/lib/gate-runners.sh"
source "$SCRIPT_DIR/lib/cursor-prompts.sh"
source "$SCRIPT_DIR/lib/validation.sh"
source "$SCRIPT_DIR/lib/state.sh"

# Configuration
CURSOR_MODEL="${CURSOR_MODEL:-opus-4.5}"
DEFAULT_MAX_ITERATIONS=5

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print usage
usage() {
    cat <<EOF
RALPH Design-Ops Cursor Orchestrator

USAGE:
    $0 <gate> <target-file> [max-iterations] [workspace]
    $0 create-spec <req-dir> <spec-file> [max-iterations] [workspace]
    $0 pipeline <req-dir> [output-dir] [workspace]

GATES:
    create-spec      Generate spec from requirements directory (takes 2 args)
    stress-test      Fix completeness gaps in spec
    validate         Fix invariant violations in spec
    generate         Generate PRP from validated spec
    check            Fix PRP structure issues
    implement        Generate Ralph steps from PRP (takes 2 args: prp-file output-dir)
    generate-tests   Generate test files from PRP
    implement-tdd    Implement code to pass tests
    parallel-checks  Fix build/lint/a11y issues
    smoke-test       Fix E2E test failures
    ai-review        Fix security/quality issues

PIPELINE:
    pipeline         Run full pipeline (all 10 gates)

OPTIONS:
    max-iterations   Maximum validation loops (default: $DEFAULT_MAX_ITERATIONS)
    workspace        Project workspace for Cursor (default: current directory)

ENVIRONMENT:
    CURSOR_MODEL     Model to use for Cursor CLI (default: opus-4.5)

EXAMPLES:
    # Create spec from requirements
    $0 create-spec requirements/ output/spec.md

    # Run validation gate
    $0 validate specs/feature.md

    # Run with custom iterations
    $0 stress-test specs/feature.md 10

    # Run full pipeline
    $0 pipeline requirements/ output/

    # Run with custom workspace
    $0 validate specs/feature.md 5 /path/to/project

EOF
    exit 1
}

# Main entry point
main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local command="$1"
    shift

    case "$command" in
        pipeline)
            run_pipeline_command "$@"
            ;;
        create-spec|implement|stress-test|validate|generate|check|generate-tests|implement-tdd|parallel-checks|smoke-test|ai-review)
            run_gate_command "$command" "$@"
            ;;
        -h|--help|help)
            usage
            ;;
        *)
            echo -e "${RED}ERROR: Unknown command: $command${NC}" >&2
            echo ""
            usage
            ;;
    esac
}

# Run a single gate
run_gate_command() {
    local gate="$1"
    shift

    # Special case: create-spec and implement take 2 file arguments
    if [[ "$gate" == "create-spec" ]] || [[ "$gate" == "implement" ]]; then
        local first_arg="${1:-}"
        local second_arg="${2:-}"
        local max_iterations="${3:-$DEFAULT_MAX_ITERATIONS}"
        local workspace="${4:-$(pwd)}"

        if [[ -z "$first_arg" ]]; then
            echo -e "${RED}ERROR: first argument required${NC}" >&2
            usage
        fi

        if [[ -z "$second_arg" ]]; then
            echo -e "${RED}ERROR: second argument required${NC}" >&2
            usage
        fi

        echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║  RALPH Design-Ops Cursor Orchestrator      ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}Configuration:${NC}"
        echo "  Gate:           $gate"
        if [[ "$gate" == "create-spec" ]]; then
            echo "  Requirements:   $first_arg"
            echo "  Output Spec:    $second_arg"
        else
            echo "  PRP File:       $first_arg"
            echo "  Output Dir:     $second_arg"
        fi
        echo "  Max Iterations: $max_iterations"
        echo "  Workspace:      $workspace"
        echo "  Cursor Model:   $CURSOR_MODEL"
        echo ""

        # Check if Cursor CLI is available
        if ! command -v cursor &> /dev/null; then
            echo -e "${RED}ERROR: Cursor CLI not found in PATH${NC}" >&2
            echo "Please install Cursor CLI: https://cursor.sh/docs/cli" >&2
            exit 1
        fi

        # Run the gate - pass both args as target separated by colon
        local target_arg="$first_arg:$second_arg"
        if run_gate_with_cursor "$gate" "$target_arg" "$max_iterations" "$workspace"; then
            echo ""
            echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║           GATE PASSED ✅                    ║${NC}"
            echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
            exit 0
        else
            echo ""
            echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
            echo -e "${RED}║           GATE FAILED ❌                    ║${NC}"
            echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
            exit 1
        fi
    else
        # Standard gate: single target file
        local target_file="${1:-}"
        local max_iterations="${2:-$DEFAULT_MAX_ITERATIONS}"
        local workspace="${3:-$(pwd)}"

        if [[ -z "$target_file" ]]; then
            echo -e "${RED}ERROR: target-file required${NC}" >&2
            usage
        fi

        echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║  RALPH Design-Ops Cursor Orchestrator      ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}Configuration:${NC}"
        echo "  Gate:           $gate"
        echo "  Target:         $target_file"
        echo "  Max Iterations: $max_iterations"
        echo "  Workspace:      $workspace"
        echo "  Cursor Model:   $CURSOR_MODEL"
        echo ""

        # Check if Cursor CLI is available
        if ! command -v cursor &> /dev/null; then
            echo -e "${RED}ERROR: Cursor CLI not found in PATH${NC}" >&2
            echo "Please install Cursor CLI: https://cursor.sh/docs/cli" >&2
            exit 1
        fi

        # Run the gate
        if run_gate_with_cursor "$gate" "$target_file" "$max_iterations" "$workspace"; then
            echo ""
            echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║           GATE PASSED ✅                    ║${NC}"
            echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
            exit 0
        else
            echo ""
            echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
            echo -e "${RED}║           GATE FAILED ❌                    ║${NC}"
            echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
            exit 1
        fi
    fi
}

# Run full pipeline
run_pipeline_command() {
    local req_dir="${1:-}"
    local output_dir="${2:-.}"
    local workspace="${3:-$(pwd)}"

    if [[ -z "$req_dir" ]]; then
        echo -e "${RED}ERROR: requirements directory required${NC}" >&2
        usage
    fi

    if [[ ! -d "$req_dir" ]]; then
        echo -e "${RED}ERROR: Requirements directory not found: $req_dir${NC}" >&2
        exit 1
    fi

    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║    RALPH Full Pipeline with Cursor CLI     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Requirements:   $req_dir"
    echo "  Output:         $output_dir"
    echo "  Workspace:      $workspace"
    echo "  Cursor Model:   $CURSOR_MODEL"
    echo ""

    # Check if Cursor CLI is available
    if ! command -v cursor &> /dev/null; then
        echo -e "${RED}ERROR: Cursor CLI not found in PATH${NC}" >&2
        echo "Please install Cursor CLI: https://cursor.sh/docs/cli" >&2
        exit 1
    fi

    # Create output directory
    mkdir -p "$output_dir"

    # Run full pipeline
    local start_time=$(date +%s)

    if run_full_pipeline "$req_dir" "$output_dir" "$workspace"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local duration_min=$((duration / 60))
        local duration_sec=$((duration % 60))

        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║      PIPELINE COMPLETED ✅                  ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}Total time: ${duration_min}m ${duration_sec}s${NC}"
        exit 0
    else
        echo ""
        echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║       PIPELINE FAILED ❌                    ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
        exit 1
    fi
}

# Run main
main "$@"

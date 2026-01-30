#!/bin/bash
set -euo pipefail

# RALPH State Management
# Maintains audit trail of all gates, attempts, commits in .ralph/state/{spec_name}-state.json

VERSION="3.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat << EOF
RALPH State Management v${VERSION}

Usage:
  $0 init --spec <spec-file> --prp <prp-file>
  $0 log --spec <spec-name> --gate <N> --attempt <M> --action <description> --files <files> [--commit <sha>]
  $0 complete --spec <spec-name> --gate <N> --status <pass|fail>
  $0 read --spec <spec-name> [--gate <N>]
  $0 current --spec <spec-name>

Commands:
  init      Initialize state file for new RALPH run
  log       Log an attempt within a gate
  complete  Mark a gate as complete
  read      Read state file contents
  current   Get current gate number

Examples:
  # Initialize
  $0 init --spec specs/auth.md --prp PRPs/auth-prp.md

  # Log attempt
  $0 log --spec auth --gate 2 --attempt 1 --action "fix ambiguity" --files "specs/auth.md"

  # Mark gate complete
  $0 complete --spec auth --gate 2 --status pass

  # Read current state
  $0 read --spec auth

  # Get current gate
  $0 current --spec auth
EOF
    exit 1
}

# Parse arguments
parse_args() {
    COMMAND="$1"
    shift

    while [[ $# -gt 0 ]]; do
        case $1 in
            --spec) SPEC_ARG="$2"; shift 2 ;;
            --prp) PRP_ARG="$2"; shift 2 ;;
            --gate) GATE="$2"; shift 2 ;;
            --attempt) ATTEMPT="$2"; shift 2 ;;
            --action) ACTION="$2"; shift 2 ;;
            --files) FILES="$2"; shift 2 ;;
            --commit) COMMIT="$2"; shift 2 ;;
            --status) STATUS="$2"; shift 2 ;;
            *) echo "Unknown argument: $1"; usage ;;
        esac
    done
}

# Extract spec name from file path
get_spec_name() {
    local spec_path="$1"
    basename "$spec_path" .md
}

# Get state file path
get_state_file() {
    local spec_name="$1"
    echo ".ralph/state/${spec_name}-state.json"
}

# Initialize state file
cmd_init() {
    [[ -z "${SPEC_ARG:-}" ]] && { echo "Error: --spec required"; usage; }
    [[ -z "${PRP_ARG:-}" ]] && { echo "Error: --prp required"; usage; }

    local spec_name=$(get_spec_name "$SPEC_ARG")
    local state_file=$(get_state_file "$spec_name")

    mkdir -p .ralph/state .ralph/instructions .ralph/tasks

    if [[ -f "$state_file" ]]; then
        echo -e "${YELLOW}⚠️  State file already exists: $state_file${NC}"
        echo -e "${YELLOW}   Continuing with existing state${NC}"
        return 0
    fi

    cat > "$state_file" << EOF
{
  "spec": "$SPEC_ARG",
  "prp": "$PRP_ARG",
  "started": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "current_gate": null,
  "gates": []
}
EOF

    echo -e "${GREEN}✅ Initialized state: $state_file${NC}"
}

# Log an attempt
cmd_log() {
    [[ -z "${SPEC_ARG:-}" ]] && { echo "Error: --spec required"; usage; }
    [[ -z "${GATE:-}" ]] && { echo "Error: --gate required"; usage; }
    [[ -z "${ATTEMPT:-}" ]] && { echo "Error: --attempt required"; usage; }
    [[ -z "${ACTION:-}" ]] && { echo "Error: --action required"; usage; }
    [[ -z "${FILES:-}" ]] && { echo "Error: --files required"; usage; }

    local spec_name="$SPEC_ARG"
    if [[ "$spec_name" == *.md ]]; then
        spec_name=$(get_spec_name "$SPEC_ARG")
    fi

    local state_file=$(get_state_file "$spec_name")

    [[ ! -f "$state_file" ]] && { echo "Error: State file not found: $state_file"; exit 1; }

    # Get commit SHA if not provided
    local commit_sha="${COMMIT:-$(git rev-parse HEAD 2>/dev/null || echo 'no-commit')}"

    # Get current state
    local state_content=$(cat "$state_file")

    # Use Python to update JSON (jq not always available)
    python3 << PYTHON_SCRIPT
import json
import sys
from datetime import datetime

state_file = "$state_file"
gate_num = int("$GATE")
attempt_num = int("$ATTEMPT")

with open(state_file, 'r') as f:
    state = json.load(f)

# Update current_gate
state["current_gate"] = f"GATE {gate_num}"

# Find or create gate entry
gate_entry = None
for g in state["gates"]:
    if g.get("gate") == f"GATE {gate_num}":
        gate_entry = g
        break

if gate_entry is None:
    gate_entry = {
        "gate": f"GATE {gate_num}",
        "started": datetime.utcnow().isoformat() + "Z",
        "attempts": []
    }
    state["gates"].append(gate_entry)

# Add attempt
gate_entry["attempts"].append({
    "attempt": attempt_num,
    "timestamp": datetime.utcnow().isoformat() + "Z",
    "action": "$ACTION",
    "files_edited": "$FILES".split(","),
    "commit_sha": "$commit_sha"
})

with open(state_file, 'w') as f:
    json.dump(state, f, indent=2)

print(f"✅ Logged: GATE {gate_num} attempt {attempt_num} - $ACTION")
PYTHON_SCRIPT

}

# Mark gate complete
cmd_complete() {
    [[ -z "${SPEC_ARG:-}" ]] && { echo "Error: --spec required"; usage; }
    [[ -z "${GATE:-}" ]] && { echo "Error: --gate required"; usage; }
    [[ -z "${STATUS:-}" ]] && { echo "Error: --status required"; usage; }

    local spec_name="$SPEC_ARG"
    if [[ "$spec_name" == *.md ]]; then
        spec_name=$(get_spec_name "$SPEC_ARG")
    fi

    local state_file=$(get_state_file "$spec_name")

    [[ ! -f "$state_file" ]] && { echo "Error: State file not found: $state_file"; exit 1; }

    python3 << PYTHON_SCRIPT
import json
from datetime import datetime

state_file = "$state_file"
gate_num = int("$GATE")
status = "$STATUS"

with open(state_file, 'r') as f:
    state = json.load(f)

# Find gate entry
for g in state["gates"]:
    if g.get("gate") == f"GATE {gate_num}":
        g["completed"] = datetime.utcnow().isoformat() + "Z"
        g["status"] = status
        break

with open(state_file, 'w') as f:
    json.dump(state, f, indent=2)

print(f"✅ GATE {gate_num} marked as {status}")
PYTHON_SCRIPT

}

# Read state
cmd_read() {
    [[ -z "${SPEC_ARG:-}" ]] && { echo "Error: --spec required"; usage; }

    local spec_name="$SPEC_ARG"
    if [[ "$spec_name" == *.md ]]; then
        spec_name=$(get_spec_name "$SPEC_ARG")
    fi

    local state_file=$(get_state_file "$spec_name")

    [[ ! -f "$state_file" ]] && { echo "Error: State file not found: $state_file"; exit 1; }

    if [[ -n "${GATE:-}" ]]; then
        # Show specific gate
        python3 << PYTHON_SCRIPT
import json

with open("$state_file", 'r') as f:
    state = json.load(f)

gate_num = int("$GATE")
for g in state["gates"]:
    if g.get("gate") == f"GATE {gate_num}":
        print(json.dumps(g, indent=2))
        break
PYTHON_SCRIPT
    else
        # Show full state
        cat "$state_file" | python3 -m json.tool
    fi
}

# Get current gate
cmd_current() {
    [[ -z "${SPEC_ARG:-}" ]] && { echo "Error: --spec required"; usage; }

    local spec_name="$SPEC_ARG"
    if [[ "$spec_name" == *.md ]]; then
        spec_name=$(get_spec_name "$SPEC_ARG")
    fi

    local state_file=$(get_state_file "$spec_name")

    [[ ! -f "$state_file" ]] && { echo "1"; exit 0; }

    python3 << PYTHON_SCRIPT
import json

with open("$state_file", 'r') as f:
    state = json.load(f)

current = state.get("current_gate")
if current:
    # Extract number from "GATE 2"
    print(current.split()[-1])
else:
    print("1")
PYTHON_SCRIPT
}

# Main
[[ $# -eq 0 ]] && usage

COMMAND="$1"
shift

parse_args "$COMMAND" "$@"

case "$COMMAND" in
    init) cmd_init ;;
    log) cmd_log ;;
    complete) cmd_complete ;;
    read) cmd_read ;;
    current) cmd_current ;;
    *) echo "Unknown command: $COMMAND"; usage ;;
esac

#!/bin/bash
# run-gate-with-tasks.sh - Wrapper that outputs task commands for Claude Code to execute
#
# This script outputs JSON commands that Claude Code can parse to create/update tasks
# Usage: Called by Claude Code, not directly by users

set -euo pipefail

GATE="$1"
shift
ARGS=("$@")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCHESTRATOR="$SCRIPT_DIR/cursor-orchestrator.sh"

# Output task creation command
cat <<EOF
{
  "action": "create_task",
  "subject": "Gate: $GATE",
  "description": "Running gate $GATE with args: ${ARGS[*]}",
  "activeForm": "Running $GATE gate"
}
EOF

# Run the actual orchestrator
if "$ORCHESTRATOR" "$GATE" "${ARGS[@]}"; then
  # Success - output task completion
  cat <<EOF
{
  "action": "complete_task",
  "status": "completed"
}
EOF
  exit 0
else
  # Failure - output task failure
  cat <<EOF
{
  "action": "complete_task",
  "status": "failed"
}
EOF
  exit 1
fi

#!/bin/bash
set -euo pipefail

# RALPH Autonomous Orchestrator
# Polls for unblocked tasks, launches subagents, waits for completion
# Usage: ./ralph-orchestrator.sh [--session-id SESSION_ID]

TASK_DIR="${HOME}/.claude/tasks/${CLAUDE_CODE_SESSION_ID}"
POLL_INTERVAL=10
MAX_RETRIES=3

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

usage() {
    cat <<EOF
RALPH Autonomous Orchestrator

Usage: $0 [--session-id SESSION_ID]

Environment Variables:
  CLAUDE_CODE_SESSION_ID   Session ID for task directory (required if not passed as arg)

Description:
  Autonomously executes RALPH pipeline by:
  1. Finding unblocked tasks (status=pending, blockedBy=[])
  2. Launching subagent for each task
  3. Waiting for completion
  4. Repeating until pipeline complete

  Each subagent runs with stateless context:
  - Latest committed file
  - Last run errors
  - NO full conversation history
EOF
    exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --session-id)
            CLAUDE_CODE_SESSION_ID="$2"
            TASK_DIR="${HOME}/.claude/tasks/${CLAUDE_CODE_SESSION_ID}"
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

# Validate session ID
if [[ -z "${CLAUDE_CODE_SESSION_ID:-}" ]]; then
    error "CLAUDE_CODE_SESSION_ID not set. Pass --session-id or export variable."
fi

if [[ ! -d "$TASK_DIR" ]]; then
    error "Task directory not found: $TASK_DIR"
fi

log "Starting RALPH orchestrator for session: $CLAUDE_CODE_SESSION_ID"
log "Task directory: $TASK_DIR"

# Get task status
get_task_status() {
    local task_id="$1"
    local task_file="$TASK_DIR/${task_id}.json"

    if [[ ! -f "$task_file" ]]; then
        echo "missing"
        return
    fi

    jq -r '.status // "pending"' "$task_file"
}

# Get task blockedBy list
get_task_blocked_by() {
    local task_id="$1"
    local task_file="$TASK_DIR/${task_id}.json"

    if [[ ! -f "$task_file" ]]; then
        echo "[]"
        return
    fi

    jq -c '.blockedBy // []' "$task_file"
}

# Check if task is unblocked
is_task_unblocked() {
    local task_id="$1"
    local status=$(get_task_status "$task_id")
    local blocked_by=$(get_task_blocked_by "$task_id")

    # Must be pending
    if [[ "$status" != "pending" ]]; then
        return 1
    fi

    # Must have no blockers OR all blockers completed
    if [[ "$blocked_by" == "[]" ]]; then
        return 0
    fi

    # Check if all blockers are completed
    local blocker_ids=$(echo "$blocked_by" | jq -r '.[]')
    for blocker_id in $blocker_ids; do
        local blocker_status=$(get_task_status "$blocker_id")
        if [[ "$blocker_status" != "completed" ]]; then
            return 1
        fi
    done

    return 0
}

# Find next unblocked task
find_next_task() {
    local task_files=("$TASK_DIR"/*.json)

    for task_file in "${task_files[@]}"; do
        if [[ ! -f "$task_file" ]]; then
            continue
        fi

        local task_id=$(basename "$task_file" .json)

        if is_task_unblocked "$task_id"; then
            echo "$task_id"
            return 0
        fi
    done

    return 1
}

# Count tasks by status
count_tasks_by_status() {
    local status="$1"
    local count=0

    for task_file in "$TASK_DIR"/*.json; do
        if [[ ! -f "$task_file" ]]; then
            continue
        fi

        local task_status=$(jq -r '.status // "pending"' "$task_file")
        if [[ "$task_status" == "$status" ]]; then
            ((count++))
        fi
    done

    echo "$count"
}

# Check if pipeline is complete
is_pipeline_complete() {
    local pending=$(count_tasks_by_status "pending")
    local in_progress=$(count_tasks_by_status "in_progress")

    if [[ "$pending" -eq 0 && "$in_progress" -eq 0 ]]; then
        return 0
    fi

    return 1
}

# Launch subagent for task
launch_subagent() {
    local task_id="$1"
    local task_file="$TASK_DIR/${task_id}.json"

    local subject=$(jq -r '.subject' "$task_file")
    local description=$(jq -r '.description' "$task_file")

    log "Launching subagent for Task #$task_id: $subject"

    # Create subagent prompt
    local prompt=$(cat <<EOF
Execute Task #${task_id} from the RALPH pipeline.

**Task File**: ${task_file}

**Instructions**:
1. Read the task file to understand requirements
2. Follow the stateless loop pattern documented in the task description
3. Execute ASSESS → FIX → COMMIT → VALIDATE loops until pass condition met
4. Update task status to "completed" when done
5. DO NOT ask user questions - follow the task instructions autonomously

**Stateless Context**:
- You see ONLY: latest committed files, last run errors
- You do NOT see: full conversation history, previous iterations

**Task Description**:
${description}

Begin execution now.
EOF
    )

    # Write subagent request to temp file
    local subagent_request="/tmp/ralph-subagent-${task_id}-${CLAUDE_CODE_SESSION_ID}.txt"
    echo "$prompt" > "$subagent_request"

    log "Subagent prompt written to: $subagent_request"
    log "Task #${task_id} subagent launched. Waiting for completion..."

    # Return the request file path for tracking
    echo "$subagent_request"
}

# Wait for task completion
wait_for_task_completion() {
    local task_id="$1"
    local retry_count=0

    while true; do
        local status=$(get_task_status "$task_id")

        if [[ "$status" == "completed" ]]; then
            log "Task #${task_id} completed successfully"
            return 0
        fi

        if [[ "$status" == "pending" ]]; then
            ((retry_count++))
            if [[ $retry_count -gt $MAX_RETRIES ]]; then
                error "Task #${task_id} still pending after ${MAX_RETRIES} checks. Subagent may have failed."
            fi
        fi

        log "Task #${task_id} status: $status (checking again in ${POLL_INTERVAL}s...)"
        sleep "$POLL_INTERVAL"
    done
}

# Main orchestration loop
main() {
    log "Pipeline status at start:"
    log "  Pending: $(count_tasks_by_status pending)"
    log "  In Progress: $(count_tasks_by_status in_progress)"
    log "  Completed: $(count_tasks_by_status completed)"

    local iteration=0

    while true; do
        ((iteration++))
        log "=== Iteration $iteration ==="

        # Check if pipeline complete
        if is_pipeline_complete; then
            log "✅ PIPELINE COMPLETE! All tasks finished."
            log "Final status:"
            log "  Completed: $(count_tasks_by_status completed)"

            # Show metrics summary
            if [[ -d ".ralph/metrics" ]]; then
                log ""
                log "Metrics Summary:"
                for metric_file in .ralph/metrics/*.json*; do
                    if [[ -f "$metric_file" ]]; then
                        log "  $(basename "$metric_file"): $(cat "$metric_file" | jq -c '.')"
                    fi
                done
            fi

            exit 0
        fi

        # Find next unblocked task
        local next_task
        if next_task=$(find_next_task); then
            log "Found unblocked task: #${next_task}"

            # Launch subagent
            local request_file=$(launch_subagent "$next_task")

            # IMPORTANT: User must manually execute the subagent
            log ""
            log "⚠️  MANUAL STEP REQUIRED:"
            log "    Run the following in Claude Code to execute Task #${next_task}:"
            log ""
            log "    Task(subagent_type=\"general-purpose\", description=\"Execute GATE ${next_task}\", prompt=\"$(cat "$request_file" | head -c 200)...\")"
            log ""
            log "    Or paste the prompt from: $request_file"
            log ""
            log "Waiting for Task #${next_task} to complete..."

            # Wait for completion
            wait_for_task_completion "$next_task"

        else
            log "No unblocked tasks found. Checking if any in progress..."

            local in_progress=$(count_tasks_by_status "in_progress")
            if [[ "$in_progress" -gt 0 ]]; then
                log "Tasks in progress: $in_progress (waiting...)"
                sleep "$POLL_INTERVAL"
            else
                log "No tasks pending or in progress, but pipeline not complete. Possible deadlock?"
                log "Current status:"
                log "  Pending: $(count_tasks_by_status pending)"
                log "  In Progress: $(count_tasks_by_status in_progress)"
                log "  Completed: $(count_tasks_by_status completed)"

                # Show blocked tasks
                log ""
                log "Blocked tasks:"
                for task_file in "$TASK_DIR"/*.json; do
                    if [[ ! -f "$task_file" ]]; then
                        continue
                    fi

                    local task_id=$(basename "$task_file" .json)
                    local status=$(get_task_status "$task_id")
                    if [[ "$status" == "pending" ]]; then
                        local blocked_by=$(get_task_blocked_by "$task_id")
                        log "  Task #${task_id}: blocked by ${blocked_by}"
                    fi
                done

                error "Pipeline stuck. Check task dependencies."
            fi
        fi
    done
}

# Run
main "$@"

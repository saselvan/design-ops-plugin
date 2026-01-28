# Task-Based Orchestration Pattern

## Overview

The cursor orchestrator integrates with Claude Code's Task system for proper tracking and visibility.

**Key Principle:** Claude Code (not bash scripts) manages tasks directly using TaskCreate/TaskUpdate/TaskList.

## Pattern

### Running a Single Gate

```python
# 1. Create task
TaskCreate(
    subject="Run validate gate",
    description="Validate spec against 43 invariants\nTarget: specs/feature.md",
    activeForm="Validating spec"
)
# Returns: Task #N created

# 2. Mark in progress
TaskUpdate(taskId=N, status="in_progress")

# 3. Run gate via Bash tool
Bash("cd /project && ~/.claude/design-ops/enforcement/cursor-orchestrator.sh validate specs/feature.md 5")

# 4. Update based on result
if gate_passed:
    TaskUpdate(taskId=N, status="completed")
else:
    TaskUpdate(taskId=N, status="completed")  # Still mark completed, failure is captured in description
```

### Running Full Pipeline

```python
# Create parent pipeline task
pipeline_task = TaskCreate(
    subject="RALPH Full Pipeline",
    description="Run all 10 gates: requirements → production code",
    activeForm="Running full pipeline"
)

# Create child tasks for each gate
gates = [
    ("create-spec", "requirements/", "output/spec.md"),
    ("stress-test", "output/spec.md"),
    ("validate", "output/spec.md"),
    ("generate", "output/spec.md"),
    ("check", "output/spec-PRP.md"),
    ("implement", "output/spec-PRP.md", "output/ralph-steps"),
]

for gate_info in gates:
    gate_name = gate_info[0]
    gate_args = gate_info[1:]

    # Create subtask
    task_id = TaskCreate(
        subject=f"Gate: {gate_name}",
        description=f"Args: {gate_args}",
        activeForm=f"Running {gate_name}"
    )

    # Mark in progress
    TaskUpdate(taskId=task_id, status="in_progress")

    # Run gate
    success = run_gate(gate_name, gate_args)

    # Update task
    TaskUpdate(taskId=task_id, status="completed" if success else "failed")

    # Stop pipeline if gate failed
    if not success:
        TaskUpdate(taskId=pipeline_task, status="failed")
        break

# Mark pipeline complete
TaskUpdate(taskId=pipeline_task, status="completed")
```

## Benefits

1. **Visibility**: Users can run `/tasks` to see pipeline progress
2. **Resumability**: If pipeline fails, can see which gates passed/failed
3. **Parallel Execution**: Can mark tasks as blocked by others and run independent gates in parallel
4. **Better UX**: Progress spinner shows which gate is running
5. **History**: Task list provides audit trail of pipeline runs

## Usage Examples

### Example 1: Run Single Gate

```bash
# User runs:
# (Claude Code creates task, runs gate, updates status)
> Run the validate gate on specs/feature.md

# Claude Code does:
1. TaskCreate(subject="Validate spec"...)
2. TaskUpdate(taskId=1, status="in_progress")
3. Bash("...orchestrator.sh validate specs/feature.md")
4. TaskUpdate(taskId=1, status="completed")
```

### Example 2: Full Pipeline

```bash
# User runs:
> Run the full RALPH pipeline on Phase 3 requirements

# Claude Code does:
1. TaskCreate(subject="RALPH Pipeline - Phase 3"...)
2. For each gate:
   - TaskCreate(subject=f"Gate: {gate}"...)
   - TaskUpdate(in_progress)
   - Run gate
   - TaskUpdate(completed/failed)
3. TaskUpdate(pipeline_task, completed)
```

### Example 3: Check Progress

```bash
# User runs:
> /tasks

# Output:
#1 [in_progress] RALPH Pipeline - Phase 3
#2 [completed] Gate: create-spec
#3 [completed] Gate: stress-test
#4 [in_progress] Gate: validate  ← Currently running
#5 [pending] Gate: generate
#6 [pending] Gate: check
```

## Implementation Status

✅ Task pattern documented
✅ Example demonstrated (task #2)
✅ Bash orchestrator works correctly
⬜ Create helper function for common pattern
⬜ Add parallel execution support
⬜ Add task dependencies (blocks/blockedBy)

## Next Steps

1. Create `run_gate_with_tracking()` helper function
2. Add dependency tracking for parallel execution
3. Update pipeline command to use tasks
4. Add progress percentage to task descriptions

#!/usr/bin/env python3
"""
RALPH Task Loader for Claude Code

Reads .ralph/tasks.json and creates all tasks using Claude Code's Task system.
This script should be run from within Claude Code.

Usage:
    # From Claude Code:
    python ~/.claude/design-ops/enforcement/ralph-task-loader.py
"""

import json
from pathlib import Path
import sys


def load_tasks():
    """Load task definitions from .ralph/tasks.json"""

    tasks_file = Path(".ralph/tasks.json")

    if not tasks_file.exists():
        print("❌ Task file not found: .ralph/tasks.json")
        print("\nRun ralph-orchestrator.py first to generate tasks:")
        print("  python ~/.claude/design-ops/enforcement/ralph-orchestrator.py specs/feature.md")
        sys.exit(1)

    with open(tasks_file) as f:
        tasks = json.load(f)

    return tasks


def format_task_creation_instructions(tasks):
    """Format instructions for Claude Code to create tasks"""

    instructions = """# RALPH Pipeline Task Creation

I need you to create the following tasks using the TaskCreate tool.

**IMPORTANT**: Create ALL tasks in a SINGLE message with multiple TaskCreate tool calls.

Here are the tasks to create:

"""

    for task in tasks:
        instructions += f"""
## Task {task['id']}: {task['subject']}

```
TaskCreate(
    subject="{task['subject']}",
    description='''
{task['description']}
''',
    activeForm="{task['activeForm']}"
)
```

After creation, update with dependencies:
- blocks: {task['blocks']}
- blockedBy: {task['blockedBy']}

---
"""

    instructions += """

## After Creating All Tasks

1. Use TaskUpdate to set up dependencies (blocks/blockedBy)
2. Use TaskList to verify all 12 tasks are created
3. Tasks will auto-unblock as dependencies complete

## Task Execution Pattern

Each task follows this pattern:
1. Task becomes available when blockedBy tasks complete
2. Claude Code agent spawns automatically
3. Agent sees ONLY stateless context (latest file + last errors)
4. Agent runs ASSESS → FIX → COMMIT → VALIDATE loop
5. Agent marks task complete on PASS
6. Next task auto-unblocks

## Monitoring Progress

Use `/tasks` command to see current status:
- pending: Waiting for dependencies
- in_progress: Currently running
- completed: Passed and committed
"""

    return instructions


def main():
    print("=" * 80)
    print("RALPH TASK LOADER")
    print("=" * 80)

    tasks = load_tasks()

    print(f"\n✅ Loaded {len(tasks)} task definitions from .ralph/tasks.json")

    instructions = format_task_creation_instructions(tasks)

    # Write instructions to file for Claude Code to read
    instruction_file = Path(".ralph/task-creation-instructions.md")
    with open(instruction_file, 'w') as f:
        f.write(instructions)

    print(f"📄 Task creation instructions written to: {instruction_file}")
    print("\n" + "=" * 80)
    print("INSTRUCTIONS FOR CLAUDE CODE")
    print("=" * 80)
    print("\nPlease read the following file and create all tasks as specified:")
    print(f"  {instruction_file}")
    print("\nKey points:")
    print("  • Create ALL 12 tasks in a SINGLE message with multiple TaskCreate calls")
    print("  • Then use TaskUpdate to set up blocks/blockedBy dependencies")
    print("  • Verify with TaskList that all tasks are created correctly")
    print("  • Tasks will auto-execute as dependencies complete")
    print("\n" + "=" * 80)

    # Also print the tasks summary
    print("\nTask Summary:")
    print("-" * 80)
    for task in tasks:
        status_icon = "🔒" if task['blockedBy'] else "🟢"
        print(f"{status_icon} {task['id']}: {task['subject']}")
        if task['blockedBy']:
            print(f"   ↳ Blocked by: {', '.join(task['blockedBy'])}")
    print("-" * 80)


if __name__ == "__main__":
    main()

# Design-Ops Orchestrators

Two orchestration options for running the RALPH pipeline with automated validation loops.

## Overview

Both orchestrators integrate the design-ops validation system with AI code generation:
- **design-ops.sh** = VALIDATOR (runs deterministic checks)
- **AI Tool** = GENERATOR (creates/fixes code)
- **Orchestrator** = LOOP CONTROLLER (retries until validation passes)

## Option 1: Cursor Orchestrator (Original)

**Best for:** Teams using Cursor IDE

### Installation

```bash
cd ~/.claude/design-ops/enforcement
chmod +x cursor-orchestrator.sh
```

### Usage

```bash
# Run single gate
./cursor-orchestrator.sh validate specs/feature.md 5

# Run full pipeline
./cursor-orchestrator.sh pipeline requirements/phase4/
```

### How It Works

1. Runs design-ops validation
2. If FAIL: generates instruction file
3. Calls `cursor agent` CLI to fix issues
4. Re-validates
5. Repeats until PASS (max 5 iterations)

### Requirements

- Cursor IDE installed
- `cursor` CLI in PATH
- Opus 4.5 model access

### Files

- `cursor-orchestrator.sh` - Main orchestrator script
- `lib/cursor-prompts.sh` - Prompt templates for Cursor

## Option 2: Claude Code Orchestrator (New)

**Best for:** Claude Code users, teams without Cursor

### Installation

```bash
cd ~/.claude/design-ops/enforcement
chmod +x claude-code-orchestrator.py
python3 --version  # Requires Python 3.7+
```

### Usage

```bash
# Run single gate
python claude-code-orchestrator.py run-gate validate specs/feature.md

# Run full pipeline
python claude-code-orchestrator.py run-pipeline requirements/phase4/

# Validate spec only
python claude-code-orchestrator.py validate-spec specs/feature.md
```

### How It Works

1. Runs design-ops validation
2. If FAIL: displays instruction summary
3. **Waits for user** to spawn Claude Code agent
4. User presses ENTER when done
5. Re-validates
6. Repeats until PASS (max 5 iterations)

### Workflow

```bash
# User runs orchestrator
python claude-code-orchestrator.py run-gate validate specs/feature.md

# Output:
⚠️  Gate validate FAILED
Reading instruction: specs/feature.md.validate-instruction.md

📋 Instruction Summary:
## Failed Invariants
- Invariant #23: Missing error states
- Invariant #31: Vague success criteria

ACTION REQUIRED:
1. Review instruction file: specs/feature.md.validate-instruction.md
2. Use Claude Code agent to follow instruction and fix issues
3. Press ENTER when done to re-validate

[User spawns Claude Code agent, fixes issues, presses ENTER]

# Re-validates...
✅ Gate validate PASSED
```

### Requirements

- Python 3.7+
- Claude Code (for manual agent spawning)
- No external dependencies

### Files

- `claude-code-orchestrator.py` - Main orchestrator script
- `TASK-ORCHESTRATION-PATTERN.md` - Task system integration docs

## Comparison

| Feature | Cursor Orchestrator | Claude Code Orchestrator |
|---------|-------------------|------------------------|
| **Automation** | Fully automated | Semi-automated (user spawns agents) |
| **Dependencies** | Cursor CLI required | Python only |
| **Cost** | Uses Cursor API | Uses Claude Code session |
| **Speed** | Fast (parallel possible) | Moderate (user waits between iterations) |
| **Control** | Less (Cursor decides) | More (user reviews each step) |
| **Best For** | CI/CD, batch runs | Interactive development |

## Which Should I Use?

### Use Cursor Orchestrator If:
- You have Cursor IDE with CLI access
- You want fully automated pipeline runs
- You're running in CI/CD
- You want fastest iteration speed

### Use Claude Code Orchestrator If:
- You're using Claude Code (not Cursor)
- You want manual review between iterations
- You prefer explicit control over fixes
- You're learning the system (more transparent)

## Task System Integration (Claude Code Only)

The Claude Code orchestrator integrates with Claude Code's Task system:

```python
# Claude Code internally creates tasks for tracking
TaskCreate(subject="Run validate gate", description="...")
TaskUpdate(taskId=1, status="in_progress")
# ... runs gate ...
TaskUpdate(taskId=1, status="completed")
```

User can check progress with `/tasks` command.

See `TASK-ORCHESTRATION-PATTERN.md` for full documentation.

## Common Patterns

### Single Gate Validation

**Cursor:**
```bash
./cursor-orchestrator.sh validate specs/feature.md 5
```

**Claude Code:**
```bash
python claude-code-orchestrator.py run-gate validate specs/feature.md
```

### Full Pipeline

**Cursor:**
```bash
./cursor-orchestrator.sh pipeline requirements/phase4/
```

**Claude Code:**
```bash
python claude-code-orchestrator.py run-pipeline requirements/phase4/
```

### Quick Validation (No Loop)

Both can call design-ops directly:

```bash
./design-ops-v3-refactored.sh validate specs/feature.md
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              VALIDATION LOOP (Both Orchestrators)            │
│                                                              │
│  1. design-ops.sh <gate> <target>                           │
│     → Runs deterministic validation                         │
│     → Outputs: instruction.md (if failed)                   │
│                                                              │
│  2. AI Generator (Cursor CLI or Claude Code)                │
│     → Reads instruction                                     │
│     → Fixes issues in target file                          │
│                                                              │
│  3. Loop back to step 1 until PASS                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘

Key Difference:
- Cursor: Automatic (orchestrator calls Cursor CLI)
- Claude Code: Manual (user spawns agents between iterations)
```

## Exit Codes

Both orchestrators use standard exit codes:

- `0` - Success (gate passed)
- `1` - Failure (gate failed after max iterations)

## Troubleshooting

### Cursor Orchestrator

**"cursor: command not found"**
```bash
# Add Cursor CLI to PATH
export PATH="$PATH:/Applications/Cursor.app/Contents/Resources/app/bin"
```

**"Gate keeps failing"**
- Check Cursor has workspace access
- Verify Opus 4.5 model is available
- Increase max iterations: `./cursor-orchestrator.sh validate spec.md 10`

### Claude Code Orchestrator

**"design-ops script not found"**
```bash
# Set correct path in claude-code-orchestrator.py
DESIGN_OPS_SCRIPT = Path.home() / ".claude/design-ops/enforcement/design-ops-v3-refactored.sh"
```

**"Waiting forever at ENTER prompt"**
- This is expected - spawn Claude Code agent manually
- Fix issues per instruction
- Press ENTER when done

## Examples

See the PathFinder AI demo for real-world usage:
- Repository: `hls-pathology-dual-corpus`
- Uses: Claude Code Orchestrator
- Pipeline: 4 phases, all gates passed
- Documentation: `.design-ops/README.md` in project

## Contributing

To add a new orchestrator:

1. Create new script: `enforcement/<name>-orchestrator.{sh|py}`
2. Implement core loop:
   - Call design-ops validation
   - Read instruction file
   - Invoke AI generator
   - Re-validate
3. Add to this document
4. Test with full pipeline

## License

MIT - See LICENSE file in repository root

---
name: ralph
description: RALPH Pipeline - Automated validation from spec to production-ready code
---

# RALPH Pipeline Skill

**RALPH** = **R**igor **A**t **L**aunch **P**hase **H**andoff

Automated 12-gate validation pipeline that takes a spec through to production-ready code with automated testing, security checks, and quality validation.

## When to Use

Use this skill when you have a validated specification and want to:
- Generate tests automatically
- Implement code with TDD
- Run automated security/quality/performance checks
- Get production-ready code with full audit trail

## Prerequisites

1. **Validated spec file** - Must pass stress-test and validate gates first
2. **Git repository** - All progress tracked via commits
3. **Project structure** - Standard layout with specs/, PRPs/, src/, tests/

## Usage

### Step 1: Generate Tasks

```bash
python ~/.claude/design-ops/enforcement/ralph-orchestrator.py <spec-file>
```

This creates `.ralph/tasks.json` with all 12 gates.

### Step 2: Load Tasks into Claude Code

Once you run the orchestrator, tell me:

"Load the RALPH tasks and create them"

I will:
1. Read `.ralph/task-creation-instructions.md`
2. Create all 12 tasks using TaskCreate
3. Set up dependencies with TaskUpdate
4. Verify with TaskList

### Step 3: Execute Pipeline

Tasks auto-execute as dependencies complete. Monitor with `/tasks`.

## The 12 Gates

| Gate | What It Does | Output |
|------|--------------|--------|
| **1. STRESS_TEST** | Check spec completeness (6 areas) | Validated spec |
| **2. VALIDATE + SECURITY_SCAN** | 43 invariants + security checks | Secure spec |
| **3. GENERATE_PRP** | Extract Product Requirements Prompt | PRP file |
| **4. CHECK_PRP** | Validate PRP structure | Validated PRP |
| **5. GENERATE_TESTS** | Create 30-40 unit tests | Test suite |
| **5.5. TEST_VALIDATION** | Validate test quality | Quality tests |
| **5.75. PREFLIGHT** | Environment checks | Ready environment |
| **6. IMPLEMENT_TDD** | Write code to pass tests | Working code |
| **6.5. PARALLEL_CHECKS** | Build/Lint/Integration/A11y | Quality code |
| **6.9. VISUAL_REGRESSION** | Screenshot testing | UI validated |
| **7. SMOKE_TEST** | E2E critical paths | Tested system |
| **8. AI_CODE_REVIEW** | Security/quality/performance | Production ready |

## Task Dependencies (DAG)

```
1 → 2 → 3 → 4 → 5 → 5.5 → 5.75 → 6 → 6.5 → 6.9 → 7 → 8
```

Each task auto-unblocks the next when it completes successfully.

## Stateless Context Pattern

Each task sees ONLY:
- Latest committed file content
- Errors from last run
- Recommended fixes
- **NO full conversation history**

This ensures deterministic, reproducible execution.

## ASSESS → FIX → COMMIT → VALIDATE Loop

Every task follows this pattern:

1. **ASSESS**: Run validation command
2. **IF PASS**: Mark complete, unblock next task
3. **IF FAIL**:
   - Read instruction file
   - **FIX**: Edit files to address issues
   - **COMMIT**: Git commit the fix
   - **VALIDATE**: Re-run validation
   - **LOOP**: Repeat until PASS

## Example: Full Workflow

```bash
# 1. Generate tasks
python ~/.claude/design-ops/enforcement/ralph-orchestrator.py specs/S-001-login.md

# 2. In Claude Code:
# "Load the RALPH tasks and create them"

# 3. Monitor progress:
# /tasks

# 4. When complete:
# - All 12 gates passed
# - Code is production-ready
# - Full audit trail in git history
# - Telemetry in .ralph/metrics/
```

## Git Commit History

After successful pipeline, you'll have commits like:

```
ralph: GATE 1 - fix completeness gaps
ralph: GATE 2 - fix invariant violations and security issues
ralph: GATE 3 - fix PRP extraction issues
ralph: GATE 4 - fix PRP structure
ralph: GATE 5 - generate test suite
ralph: GATE 5.5 - fix test suite quality
ralph: GATE 5.75 - fix environment setup
ralph: GATE 6 - pass test: test_user_login
ralph: GATE 6 - pass test: test_invalid_credentials
...
ralph: GATE 6.5 - fix parallel check failures
ralph: GATE 6.9 - fix visual regression
ralph: GATE 7 - fix smoke test failures
ralph: GATE 8 - fix security/quality/performance issues
```

Every change is tracked and auditable.

## Telemetry

Each gate writes metrics to `.ralph/metrics/gate-N.json`:

```json
{
  "gate": "1",
  "name": "STRESS_TEST",
  "status": "PASS",
  "iterations": 2,
  "start_time": "2026-01-28T10:00:00Z",
  "end_time": "2026-01-28T10:05:23Z",
  "duration_seconds": 323,
  "errors": [],
  "fixes_applied": [
    "Added edge cases section",
    "Clarified acceptance criteria"
  ]
}
```

Final summary written to `.ralph/COMPLETE.md`.

## Monitoring Active Pipeline

Use Claude Code's task system to monitor:

```bash
# List all tasks
/tasks

# Check specific task
/task <task-id>

# See completed tasks
/tasks completed
```

## Troubleshooting

### "Task file not found"
Run ralph-orchestrator.py first to generate tasks.

### "Validation keeps failing"
Each task has an instruction file explaining what needs to be fixed. Read it carefully.

### "Task stuck in pending"
Check dependencies with `/task <task-id>`. Task won't start until blockedBy tasks complete.

### "Want to skip a gate"
DON'T. Each gate catches different issues. Skipping = shipping bugs.

## Integration with Design-Ops

RALPH is the **implementation phase** of Design-Ops:

```
Design-Ops Flow:
  Research → Journeys → Specs → VALIDATE → RALPH → Production
                                    ↑          ↑
                                  Gate 2   Gates 3-8
```

Gates 1-2 (STRESS_TEST, VALIDATE) can be run standalone for spec validation.
Gates 3-8 require the full RALPH pipeline.

## Files Created

```
.ralph/
├── tasks.json                    # Task definitions
├── task-creation-instructions.md # Instructions for Claude Code
├── metrics/
│   ├── gate-1.json
│   ├── gate-2.json
│   └── ...
└── COMPLETE.md                   # Final summary
```

## Success Criteria

Pipeline is complete when:
- ✅ All 12 gates passed
- ✅ All tests passing
- ✅ Security scan clean
- ✅ Performance audit > 90
- ✅ Visual regression approved
- ✅ Smoke tests passing
- ✅ Git history shows all commits

## Next Steps After RALPH

1. **Manual review** - Human review of generated code
2. **Integration testing** - Test with real systems
3. **Deployment** - Ship to staging/production
4. **Monitoring** - Track in production
5. **Retrospective** - Update learnings

---

**Remember**: RALPH automates rigor, not thinking. Review the code, understand the decisions, and validate the approach makes sense for your use case.

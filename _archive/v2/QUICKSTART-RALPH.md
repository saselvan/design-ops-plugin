# RALPH Pipeline - 5 Minute Quick Start

**RALPH** = **R**igor **A**t **L**aunch **P**hase - Automated spec-to-production pipeline

## Prerequisites

- Python 3.7+
- Git repository initialized in your project
- A validated spec file (passed stress-test and validate gates)

## Step 1: Install Design-Ops

```bash
git clone https://github.com/saselvan/design-ops-plugin ~/.claude/design-ops
chmod +x ~/.claude/design-ops/enforcement/*.py
```

## Step 2: Navigate to Your Project

```bash
cd ~/projects/my-app  # Your project directory
```

Your project should have this structure:
```
my-app/
├── specs/           # Your spec files
├── PRPs/            # Generated PRPs (will be created)
├── src/             # Source code (will be generated)
└── tests/           # Tests (will be generated)
```

## Step 3: Run RALPH Orchestrator

```bash
python ~/.claude/design-ops/enforcement/ralph-orchestrator.py specs/my-feature.md
```

**Output:**
```
RALPH ORCHESTRATOR - Task Generation
====================================
Spec file: specs/my-feature.md
✅ Generated 12 tasks
📄 Task definitions written to: .ralph/tasks.json

Next steps:
1. Review .ralph/tasks.json
2. In Claude Code, run:
   python ~/.claude/design-ops/enforcement/ralph-task-loader.py
```

## Step 4: Load Tasks (In Claude Code)

Open Claude Code in your project directory and say:

```
Load the RALPH tasks and create them
```

Or manually run:
```bash
python ~/.claude/design-ops/enforcement/ralph-task-loader.py
```

Then in Claude Code, ask me to:
```
Read .ralph/task-creation-instructions.md and create all 12 tasks
```

## Step 5: Monitor Progress

In Claude Code:
```bash
/tasks
```

You'll see all 12 gates:
```
🟢 ralph-1: GATE 1: STRESS_TEST - Check spec completeness
🔒 ralph-2: GATE 2: VALIDATE + SECURITY_SCAN (blocked by ralph-1)
🔒 ralph-3: GATE 3: GENERATE_PRP (blocked by ralph-2)
...
```

Tasks auto-execute as dependencies complete.

## The 12 Gates (In Order)

| Gate | What It Does | Output |
|------|--------------|--------|
| 1. STRESS_TEST | Check spec completeness | Validated spec |
| 2. VALIDATE + SECURITY_SCAN | 43 invariants + security | Secure spec |
| 3. GENERATE_PRP | Extract requirements | PRP file |
| 4. CHECK_PRP | Validate PRP structure | Validated PRP |
| 5. GENERATE_TESTS | Create 30-40 unit tests | Test suite |
| 5.5. TEST_VALIDATION | Validate test quality | Quality tests |
| 5.75. PREFLIGHT | Environment checks | Ready environment |
| 6. IMPLEMENT_TDD | Write code (TDD) | Working code |
| 6.5. PARALLEL_CHECKS | Build/Lint/Integration/A11y | Quality code |
| 6.9. VISUAL_REGRESSION | Screenshot testing | UI validated |
| 7. SMOKE_TEST | E2E critical paths | Tested system |
| 8. AI_CODE_REVIEW | Security/quality/performance | Production ready |

## What Happens Automatically

Each gate:
1. **ASSESS**: Runs validation command
2. **IF FAIL**:
   - Reads instruction file
   - Fixes issues
   - Commits to git
   - Re-validates
3. **IF PASS**: Marks complete, unblocks next gate

## Git History After Completion

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
ralph: GATE 8 - fix security/quality/performance issues
```

## Files Created

```
.ralph/
├── tasks.json                    # Task definitions
├── task-creation-instructions.md # Instructions for Claude Code
├── metrics/
│   ├── gate-1.json              # Telemetry for each gate
│   ├── gate-2.json
│   └── ...
└── COMPLETE.md                   # Final summary
```

## Troubleshooting

### "ModuleNotFoundError" or "Command not found"
```bash
# Make scripts executable
chmod +x ~/.claude/design-ops/enforcement/*.py

# Verify Python version
python3 --version  # Should be 3.7+
```

### "Task file not found"
You need to run `ralph-orchestrator.py` FIRST to generate `.ralph/tasks.json`.

### "Tasks not auto-executing"
Tasks are created with dependencies (`blockedBy`). They'll auto-execute as previous tasks complete.
Check with `/tasks` to see status.

### "Gate keeps failing"
Each gate creates an instruction file (e.g., `spec.md.validate-instruction.md`).
Read it - it tells you exactly what to fix.

## Example: Full Workflow

```bash
# 1. Go to project
cd ~/projects/login-app

# 2. Create initial spec (or use existing)
cat > specs/S-001-login.md << 'EOF'
# S-001: User Login
[... your spec content ...]
EOF

# 3. Generate RALPH tasks
python ~/.claude/design-ops/enforcement/ralph-orchestrator.py specs/S-001-login.md

# Output: .ralph/tasks.json created

# 4. In Claude Code:
# "Load the RALPH tasks and create them"

# 5. Monitor progress:
# /tasks

# 6. When complete:
# - All tests passing
# - Code is production-ready
# - Full audit trail in git
```

## Success Criteria

Pipeline is complete when:
- ✅ All 12 gates passed
- ✅ All tests passing (unit + integration + E2E)
- ✅ Security scan clean (no OWASP Top 10)
- ✅ Performance audit > 90 (Lighthouse)
- ✅ Visual regression approved
- ✅ Git history shows all commits

## Next Steps

After RALPH completes:
1. **Manual review** - Human review of generated code
2. **Integration testing** - Test with real systems
3. **Deployment** - Ship to staging/production
4. **Retrospective** - Update learnings in Design-Ops

## More Documentation

- **Complete Reference**: [ralph.md](ralph.md)
- **Design-Ops Overview**: [README.md](README.md)
- **Installation Guide**: [INSTALLATION.md](INSTALLATION.md)
- **12-Gate Deep Dive**: [enforcement/RALPH-2026-SUMMARY.md](enforcement/RALPH-2026-SUMMARY.md)

## Support

- **Issues**: https://github.com/saselvan/design-ops-plugin/issues
- **Discussions**: https://github.com/saselvan/design-ops-plugin/discussions

---

**Remember**: RALPH automates rigor, not thinking. Review the output, understand the decisions, validate it makes sense for your use case.

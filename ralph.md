---
name: ralph
description: RALPH (Rigor At Launch Phase Handoff) - Automated spec-to-production pipeline with TDD and progressive integration
---

# RALPH: Automated Spec-to-Production Pipeline

**Version**: 3.0 (Agent-Driven Orchestration)
**Status**: Production

---

## Instructions for Claude (How to Invoke RALPH)

When the user says **"Run RALPH on specs/{file}.md"** or similar:

1. **Use the Task tool** to launch the orchestrator agent:
   ```
   Task(
     subagent_type: "general-purpose",
     description: "Launch RALPH orchestrator",
     prompt: "You are the RALPH orchestrator agent.

     Read the orchestrator specification from:
     ~/.claude/design-ops/enforcement/ralph-orchestrator-agent.md

     Then create all RALPH tasks for the spec file: {spec_file}

     Follow the specification exactly to:
     - Analyze the codebase (count tests, detect stack, identify UI tests)
     - Generate dynamic file paths (.ralph/state/{spec_name}-state.json)
     - Create all tasks using TaskCreate tool in ONE message
     - Return summary of tasks created"
   )
   ```

2. **Wait for orchestrator completion** - it will return summary of tasks created

3. **Tell user**: "Created N RALPH tasks. Monitor progress with `/tasks`"

**Do NOT**:
- Try to create tasks yourself
- Read the spec file and generate tasks manually
- Skip the Task tool and try to orchestrate directly

**The orchestrator agent handles everything** - you just launch it.

---

### When User Says "Show RALPH state for {spec_name}"

1. **Read state file**:
   ```bash
   Bash: ~/.claude/design-ops/enforcement/lib/ralph-state.sh read --spec {spec_name}
   ```

2. **Parse and show**:
   - Current gate
   - All attempts with commits
   - Status (pass/fail)

---

### When User Says "Resume RALPH for {spec_name}"

1. **Read state file** to find current gate:
   ```bash
   Bash: ~/.claude/design-ops/enforcement/lib/ralph-state.sh current --spec {spec_name}
   ```

2. **Check tasks**:
   ```
   /tasks
   ```

3. **Find failed task** and retry from that point

---

### Error Handling

If orchestrator agent fails:
- Check that `~/.claude/design-ops/enforcement/ralph-orchestrator-agent.md` exists
- Check that `~/.claude/design-ops/enforcement/lib/ralph-state.sh` exists
- Check that spec file exists and is valid
- Read error message and help user fix

---

## What is RALPH?

RALPH is an intelligent orchestrator that transforms validated specifications into production-ready code through:

- **Progressive Integration**: ONE test at a time, catching regressions immediately
- **Automated Validation Loops**: Edit→Commit→Log→Re-check until clean
- **Playwright Browser Verification**: Automated UI testing with MCP tools
- **Full Audit Trail**: Every edit logged with git commits + state file

**Result**: 30-45 minutes from spec to production-ready code with full test coverage.

---

## Quick Start

### 1. Ensure Design Ops is Installed

```bash
# Clone if not already
git clone https://github.com/saselvan/design-ops-plugin.git ~/.claude/design-ops
cd ~/.claude/design-ops

# Make scripts executable
chmod +x enforcement/*.sh enforcement/lib/*.sh
```

### 2. Run RALPH on Your Spec

In Claude Code:

```
Run RALPH on specs/auth-feature.md
```

That's it. RALPH will:
1. Analyze your spec/PRP
2. Count test files
3. Create 30-50 tasks automatically
4. Execute with full automation (no manual steps)

### 3. Monitor Progress

```
/tasks
```

Watch gates execute sequentially with progressive integration.

---

## What RALPH Does

### The 12 Gates

**Pipeline**: Spec → Validate → PRP → Tests → Implement → Verify → Deploy

```
GATE 1: STRESS_TEST          Check spec completeness
GATE 2: VALIDATE             43 invariants + security (parallel)
GATE 3: GENERATE_PRP         Extract requirements
GATE 4: CHECK_PRP            Validate PRP structure
GATE 5: GENERATE_TESTS       Create 30-40 unit tests
GATE 5.5: TEST_VALIDATION    Verify tests fail correctly (parallel)
GATE 5.75: PREFLIGHT         Environment ready check
GATE 6: IMPLEMENT_TDD        ONE test at a time (N sub-tasks)
GATE 6.5: PARALLEL_CHECKS    Build + Lint + Integration + A11y
GATE 6.9: VISUAL_REGRESSION  Playwright screenshot testing
GATE 7: SMOKE_TEST           E2E critical paths
GATE 8: AI_CODE_REVIEW       Security + performance audit (parallel)
```

### Progressive Integration (GATE 6)

Instead of implementing all 30 tests at once and discovering integration failures at the end:

**OLD (broken) approach:**
```
Implement all 30 tests
Run all tests
❌ Test 3 and Test 17 fail together (shared state conflict)
Fix and repeat
```

**NEW (RALPH) approach:**
```
Implement test 1 → Run test 1 → GREEN ✅ → Commit
Implement test 2 → Run test 2 → GREEN ✅ → Run tests 1+2 → GREEN ✅ → Commit
Implement test 3 → Run test 3 → GREEN ✅ → Run tests 1+2+3 → Test 2 FAILS ❌
  → FIX test 3 code (regression detected!)
  → Re-run tests 1+2+3 → ALL GREEN ✅ → Commit
Implement test 4 → ...
```

**Catches regressions immediately** instead of at the end.

### Edit→Commit→Log→Re-check Loop

Every fix gets individual tracking:

```
GATE 2: VALIDATE
  Run validate → 3 violations found

  Violation 1: "Ambiguous requirement in auth section"
  → Edit spec.md
  → Commit: "ralph: GATE 2 attempt 1 - fix ambiguity in auth section"
  → Log to state file: {gate: 2, attempt: 1, action: "fix_ambiguity", commit: "abc123"}
  → Re-run validate → 2 violations remain

  Violation 2: "Missing success criteria"
  → Edit spec.md
  → Commit: "ralph: GATE 2 attempt 2 - add success criteria"
  → Log to state file: {gate: 2, attempt: 2, action: "add_success_criteria", commit: "def456"}
  → Re-run validate → 1 violation remains

  Violation 3: "Edge cases not defined"
  → Edit spec.md
  → Commit: "ralph: GATE 2 attempt 3 - define edge cases"
  → Log to state file: {gate: 2, attempt: 3, action: "define_edge_cases", commit: "ghi789"}
  → Re-run validate → PASS (0 violations)

  Final commit: "ralph: GATE 2 complete"
```

**Benefits:**
- Atomic commits (easy rollback)
- Full audit trail (what was fixed when)
- Learning data (which violations are common)

### Playwright MCP Verification (Selective)

For UI tests, RALPH automatically:

```javascript
// Detects UI test by parsing imports
test_content = "import { AuthPage } from '@/app/auth/page'"
→ This touches src/app/ → UI test detected

// Adds Playwright verification steps
1. Start dev server (if not running)
   Bash: curl http://localhost:3000 || npm run dev &

2. Navigate to route
   mcp__playwright__browser_navigate({ url: "http://localhost:3000/auth" })

3. Take snapshot
   mcp__playwright__browser_snapshot({})

4. Verify UI elements
   - Check heading "Sign In" exists
   - Check button "Continue" exists
   - Check form fields present

5. If verification fails
   → Fix component/page code
   → Commit fix
   → Re-run verification
```

**Only runs for UI tests** (not every test).

---

## Installation Across Computers

### Option 1: Clone + Symlink (Recommended)

```bash
# Clone repo
git clone https://github.com/saselvan/design-ops-plugin.git ~/.claude/design-ops

# Make scripts executable
cd ~/.claude/design-ops
chmod +x enforcement/*.sh enforcement/lib/*.sh

# Symlink skill to Claude Code
mkdir -p ~/.claude/skills
ln -s ~/.claude/design-ops/ralph.md ~/.claude/skills/ralph.md
```

**On new computer**: Same commands. Repo stays in sync via git.

### Option 2: Git Submodule (for project-specific)

```bash
cd ~/projects/my-app

# Add as submodule
git submodule add https://github.com/saselvan/design-ops-plugin.git .design-ops

# Make executable
chmod +x .design-ops/enforcement/*.sh .design-ops/enforcement/lib/*.sh

# Add to .claude/settings.json
echo '{"skills": [".design-ops/ralph.md"]}' > .claude/settings.json
```

**On new computer**:
```bash
git clone <your-repo>
git submodule update --init --recursive
```

### Option 3: Global Installation

```bash
# Install to /usr/local
sudo git clone https://github.com/saselvan/design-ops-plugin.git /usr/local/lib/design-ops
sudo chmod +x /usr/local/lib/design-ops/enforcement/*.sh /usr/local/lib/design-ops/enforcement/lib/*.sh

# Symlink skill
ln -s /usr/local/lib/design-ops/ralph.md ~/.claude/skills/ralph.md
```

**Updates**:
```bash
cd /usr/local/lib/design-ops
sudo git pull
```

---

## Usage Patterns

### Basic Usage

```
Run RALPH on specs/feature.md
```

### Check RALPH Status

```
Show me the RALPH state for auth-feature
```

I'll read `.ralph/state/auth-feature-state.json` and show current gate, attempts, commits.

### Resume After Failure

```
Resume RALPH for auth-feature from current gate
```

I'll check state file, see which gate failed, resume from there.

### Parallel Runs

```
Run RALPH on specs/auth-feature.md
Run RALPH on specs/payment-api.md
```

Both execute simultaneously with isolated state files.

---

## State File Tracking

Every RALPH run creates a state file:

**Location**: `.ralph/state/{spec_name}-state.json`

**Example**:
```json
{
  "spec": "specs/auth-feature.md",
  "prp": "PRPs/auth-feature-prp.md",
  "started": "2026-01-29T18:23:45Z",
  "current_gate": "GATE 6.3",

  "gates": [
    {
      "gate": "GATE 2: VALIDATE",
      "started": "2026-01-29T18:24:12Z",
      "attempts": [
        {
          "attempt": 1,
          "timestamp": "2026-01-29T18:24:30Z",
          "action": "fix_ambiguity_in_auth_section",
          "files_edited": ["specs/auth-feature.md"],
          "commit_sha": "abc1234"
        }
      ],
      "completed": "2026-01-29T18:26:00Z",
      "status": "pass"
    }
  ]
}
```

**View state**:
```bash
~/.claude/design-ops/enforcement/lib/ralph-state.sh read --spec auth-feature
```

---

## Troubleshooting

### "State file not found"

Initialize manually:
```bash
~/.claude/design-ops/enforcement/lib/ralph-state.sh init \
  --spec specs/feature.md \
  --prp PRPs/feature-prp.md
```

### "Tasks not executing"

Check dependencies:
```
/tasks
```

Tasks execute when `blockedBy` dependencies complete.

### "Integration tests failing"

Check state file to see which GATE 6.N introduced regression:
```bash
~/.claude/design-ops/enforcement/lib/ralph-state.sh read --spec feature
```

Git log shows commit for that sub-task - rollback and fix.

---

*RALPH: Where specs compile to production-ready code.*

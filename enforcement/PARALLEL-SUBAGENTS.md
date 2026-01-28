# RALPH Parallel Sub-Agent Strategy

## Overview

While RALPH gates are **sequential** (each gate must complete before the next), **within individual gates** there are opportunities for parallel execution using sub-agents.

## Why Parallel Sub-Agents?

**Gates are sequential because they have data dependencies:**
- Can't generate PRP before validating spec
- Can't write tests before generating PRP
- Can't implement code before writing tests

**But within a single gate, sub-tasks can be independent:**
- GATE 2: Validate invariants AND security (independent checks on same file)
- GATE 6.5: Build AND lint AND accessibility (independent validations)
- GATE 8: AI review AND performance audit (independent analyses)

## Parallelizable Gates

| Gate | Parallel Sub-Tasks | Est. Speedup |
|------|-------------------|--------------|
| **GATE 2** | VALIDATE + SECURITY_SCAN | 2x |
| **GATE 5** | Generate tests by module (optional) | 2-4x |
| **GATE 5.5** | TEST_VALIDATE + TEST_QUALITY | 2x |
| **GATE 6.5** | BUILD + LINT + ACCESSIBILITY | 3x ⭐ |
| **GATE 8** | AI_REVIEW + PERFORMANCE_AUDIT | 2x |

**Total**: 9-12 concurrent sub-agents across entire pipeline

## How to Launch Parallel Sub-Agents

### ❌ WRONG: Sequential Execution

```
Run validate on spec.md
[wait for completion]
Run security-scan on spec.md
```

**Time**: 2 × validation_time

### ✅ CORRECT: Parallel Execution

```
Launch two parallel agents using the Task tool in a SINGLE message:
1. Agent A: Run validate on spec.md
2. Agent B: Run security-scan on spec.md
```

**Time**: max(validation_time, security_scan_time)

## Example: GATE 6.5 (Most Parallelizable)

```markdown
## GATE 6.5: PARALLEL_CHECKS

Launch 3 parallel sub-agents in SINGLE message:

### Sub-Agent A: BUILD CHECK
```bash
npm run build
```
If fail: Fix compilation → Commit → Done

### Sub-Agent B: LINT CHECK
```bash
npm run lint
```
If fail: Fix linting → Commit → Done

### Sub-Agent C: ACCESSIBILITY CHECK
```bash
~/.claude/design-ops/enforcement/design-ops-v3-refactored.sh parallel-checks src/
```
If fail: Fix a11y → Commit → Done

### GATE COMPLETE WHEN:
✅ All 3 sub-agents report PASS
```

## Sub-Agent Communication

### Independent Sub-Agents (No Coordination Needed)

**GATE 2, 6.5, 8**: Sub-agents work on same files but different validations.

**Pattern**: Each sub-agent commits separately, parent task waits for all to complete.

```
Main Task (GATE 6.5)
├── Sub-Agent A: Build → Commit "fix build"
├── Sub-Agent B: Lint → Commit "fix lint"
└── Sub-Agent C: A11y → Commit "fix a11y"

All done? → Unblock GATE 6.9
```

### Coordinated Sub-Agents (Rare)

**GATE 5 (optional)**: If PRP has clear module boundaries.

**Pattern**: Each sub-agent generates tests for their module.

```
Main Task (GATE 5)
├── Sub-Agent A: Generate auth tests → Commit "add auth tests"
├── Sub-Agent B: Generate data tests → Commit "add data tests"
└── Sub-Agent C: Generate API tests → Commit "add API tests"

All done? → Single commit "ralph: GATE 5 - all tests" → Unblock GATE 5.5
```

## Git Commit Strategy with Parallel Sub-Agents

### Each Sub-Agent Commits Separately

```bash
# Sub-Agent A
git commit -m "ralph: GATE 6.5A - fix build"

# Sub-Agent B
git commit -m "ralph: GATE 6.5B - fix lint"

# Sub-Agent C
git commit -m "ralph: GATE 6.5C - fix accessibility"
```

**Why separate commits?**
- Clear audit trail (which sub-agent fixed what)
- No merge conflicts (different concerns)
- Easy rollback if one sub-agent breaks something

### When ALL Sub-Agents Complete

Main task verifies all checks pass, then unblocks next gate.

## Performance Impact

### Without Parallel Sub-Agents

```
GATE 2: validate (2min) → security-scan (1min) = 3min
GATE 6.5: build (1min) → lint (30s) → a11y (2min) = 3.5min
GATE 8: ai-review (3min) → perf (2min) = 5min

Total for these 3 gates: 11.5min
```

### With Parallel Sub-Agents

```
GATE 2: max(validate 2min, security-scan 1min) = 2min
GATE 6.5: max(build 1min, lint 30s, a11y 2min) = 2min
GATE 8: max(ai-review 3min, perf 2min) = 3min

Total for these 3 gates: 7min
```

**Speedup: 39% faster** (11.5min → 7min)

## When NOT to Parallelize

### Sequential Dependencies Within Gate

❌ Don't parallelize if sub-tasks depend on each other:

```
GATE 6: IMPLEMENT_TDD
- Write code for test A
- Write code for test B (depends on A)
- Write code for test C (depends on B)

Must be sequential: A → B → C
```

### Single File/Target

❌ Don't parallelize if there's only one target:

```
GATE 1: STRESS_TEST
- Check completeness of spec.md

No parallelism possible (single file)
```

### Complex Coordination Required

❌ Don't parallelize if coordination cost > benefit:

```
GATE 3: GENERATE_PRP
- Extract requirements from spec
- Build relationships between requirements
- Generate PRP structure

Complex interdependencies → keep sequential
```

## Implementation in Orchestrator v3

**File**: `ralph-orchestrator-v3-parallel.py`

**Key Changes from v2**:

1. **Parallel Instructions**: Gates 2, 5.5, 6.5, 8 now have explicit parallel sub-agent instructions
2. **Sub-Agent Naming**: Clear A/B/C naming for tracking
3. **Commit Messages**: Unique commit messages per sub-agent (e.g., "GATE 6.5A", "GATE 6.5B")
4. **Completion Criteria**: "All N sub-agents report PASS" instead of single validation

**Usage**:

```bash
python ~/.claude/design-ops/enforcement/ralph-orchestrator-v3-parallel.py specs/feature.md
```

Generates tasks.json with parallel instructions embedded in gate descriptions.

## Best Practices

1. **Launch all parallel sub-agents in ONE message**
   - ✅ "Launch 3 agents: build, lint, a11y"
   - ❌ "Launch build agent" → [wait] → "Launch lint agent"

2. **Each sub-agent commits separately**
   - Clear audit trail
   - Easy rollback
   - No conflicts

3. **Main task waits for ALL sub-agents**
   - Don't unblock next gate until all pass
   - Re-run failed sub-agents only (don't restart passing ones)

4. **Use unique commit message suffixes**
   - GATE 6.5A, 6.5B, 6.5C
   - Easy to see which sub-agent made which change

5. **Document parallelism in gate description**
   - Make it obvious this gate can parallelize
   - Show example of launching parallel agents
   - List completion criteria

## Future: Git Worktrees for Gate-Level Parallelism

**Current**: Parallel sub-agents within gates
**Future**: Parallel gates using git worktrees

**Pattern**:
```
main worktree: GATE 1 → 2 → 3 (sequential)
worktree-docs: GATE D1 → D2 (documentation)
worktree-ci: GATE CI1 → CI2 (CI/CD setup)

All worktrees merge to main when complete
```

**Complexity**: High (merge conflicts, coordination)
**Benefit**: Even faster pipeline
**Status**: Deferred (sub-agent parallelism covers 80% of benefit)

## Summary

**What Changed**: Added parallel sub-agent support within gates where sub-tasks are independent.

**Impact**: 39% faster for parallelizable gates (7min vs 11.5min for gates 2, 6.5, 8).

**Adoption**: Zero breaking changes - parallel execution is OPTIONAL. If Claude Code doesn't launch parallel agents, gates still work sequentially.

**Best ROI**: GATE 6.5 (3 parallel checks) saves the most time.

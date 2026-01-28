#!/usr/bin/env python3
"""
RALPH Orchestrator for Claude Code v2

CRITICAL CHANGE: Git commits are now MANDATORY and EXPLICIT in every gate.
Each task description now emphasizes commits are BLOCKING requirements.

Usage:
    python ralph-orchestrator-v2.py <spec-file>
"""

import sys
import os
from pathlib import Path
import json

def generate_tasks(spec_file):
    """Generate all 12 RALPH gates as task definitions with MANDATORY git commits."""

    spec_path = Path(spec_file).resolve()
    if not spec_path.exists():
        print(f"❌ Spec file not found: {spec_file}")
        sys.exit(1)

    # Derive paths
    spec_name = spec_path.stem
    spec_dir = spec_path.parent
    prp_file = spec_dir.parent / "PRPs" / f"{spec_name}-prp.md"
    code_dir = spec_dir.parent / "src"
    test_dir = spec_dir.parent / "tests"

    design_ops_script = Path.home() / ".claude/design-ops/enforcement/design-ops-v3-refactored.sh"

    tasks = [
        # GATE 1: STRESS_TEST
        {
            "id": "ralph-1",
            "subject": "GATE 1: STRESS_TEST - Check spec completeness",
            "description": f"""## GATE 1: STRESS_TEST

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Understand: Your ONE job is to make THIS gate pass
3. Remember: NO extra features, NO refactoring outside scope

**Rules:**
- ✅ Fix ONLY what fails validation
- ✅ Commit after EVERY fix  
- ✅ Follow ASSESS → FIX → COMMIT → VALIDATE loop
- ❌ NO adding features
- ❌ NO refactoring unrelated code
- ❌ NO optimizing prematurely
- ❌ NO "I should also..." thoughts

**If validation says "fix X"** → Fix X only. Not X + Y + Z.

---

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed spec file: {spec_path}
- Errors from last stress-test run
- NO full conversation history

### Command:
```bash
{design_ops_script} stress-test {spec_path}
```

### MANDATORY Loop (DO NOT SKIP ANY STEP):

**1. ASSESS:**
```bash
{design_ops_script} stress-test {spec_path}
```

**2. IF PASS:**
✅ Mark task complete and unblock next gate.
✅ Done.

**3. IF FAIL:**

**3a. READ INSTRUCTION:**
```bash
cat {spec_path}.stress-test-instruction.md
```

**3b. FIX:**
Edit spec to address ALL gaps listed in instruction.

**3c. 🚨 MANDATORY GIT COMMIT (DO NOT SKIP):**
```bash
git add {spec_path}
git commit -m "ralph: GATE 1 - fix completeness gaps"
```

**WHY COMMIT IS MANDATORY:**
- Next gate sees ONLY committed files
- Without commit, fixes are lost
- Audit trail requires commits

**3d. VERIFY COMMIT:**
```bash
git log -1 --oneline
# Should show: "ralph: GATE 1 - fix completeness gaps"
```

**3e. RE-VALIDATE:**
```bash
{design_ops_script} stress-test {spec_path}
```

**3f. LOOP:**
If still failing, go back to step 3a.

**Telemetry:**
Write to `.ralph/metrics/gate-1.json` on completion.
""",
            "activeForm": "Running GATE 1: STRESS_TEST",
            "blocks": ["ralph-2"],
            "blockedBy": []
        },

        # GATE 2: VALIDATE + SECURITY_SCAN
        {
            "id": "ralph-2",
            "subject": "GATE 2: VALIDATE + SECURITY_SCAN - Check clarity and security",
            "description": f"""## GATE 2: VALIDATE + SECURITY_SCAN

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Understand: Your ONE job is to make THIS gate pass
3. Remember: NO extra features, NO refactoring outside scope

**Rules:**
- ✅ Fix ONLY what fails validation
- ✅ Commit after EVERY fix  
- ✅ Follow ASSESS → FIX → COMMIT → VALIDATE loop
- ❌ NO adding features
- ❌ NO refactoring unrelated code
- ❌ NO optimizing prematurely
- ❌ NO "I should also..." thoughts

**If validation says "fix X"** → Fix X only. Not X + Y + Z.

---

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed spec file: {spec_path}
- Errors from last validate run
- NO full conversation history

### Commands:
```bash
{design_ops_script} validate {spec_path}
{design_ops_script} security-scan {spec_path}
```

### MANDATORY Loop (DO NOT SKIP ANY STEP):

**1. ASSESS:**
```bash
{design_ops_script} validate {spec_path}
{design_ops_script} security-scan {spec_path}
```

**2. IF BOTH PASS:**
✅ Mark task complete and unblock next gate.
✅ Done.

**3. IF EITHER FAILS:**

**3a. READ INSTRUCTIONS:**
```bash
cat {spec_path}.validate-instruction.md
cat {spec_path}.security-instruction.md
```

**3b. FIX:**
Edit spec to fix ALL violations (43 invariants + security issues).

**3c. 🚨 MANDATORY GIT COMMIT (DO NOT SKIP):**
```bash
git add {spec_path}
git commit -m "ralph: GATE 2 - fix invariant violations and security issues"
```

**WHY COMMIT IS MANDATORY:**
- Stateless gates require commits between iterations
- PRP generation (Gate 3) reads from git HEAD
- Without commit, changes invisible to next gate

**3d. VERIFY COMMIT:**
```bash
git log -1 --oneline
# Should show: "ralph: GATE 2 - fix invariant violations and security issues"
```

**3e. RE-VALIDATE:**
```bash
{design_ops_script} validate {spec_path}
{design_ops_script} security-scan {spec_path}
```

**3f. LOOP:**
If still failing, go back to step 3a.

**Telemetry:**
Write to `.ralph/metrics/gate-2.json` on completion.
""",
            "activeForm": "Running GATE 2: VALIDATE + SECURITY_SCAN",
            "blocks": ["ralph-3"],
            "blockedBy": ["ralph-1"]
        },

        # GATE 3: GENERATE_PRP
        {
            "id": "ralph-3",
            "subject": "GATE 3: GENERATE_PRP - Extract Product Requirements Prompt",
            "description": f"""## GATE 3: GENERATE_PRP

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Understand: Your ONE job is to make THIS gate pass
3. Remember: NO extra features, NO refactoring outside scope

**Rules:**
- ✅ Fix ONLY what fails validation
- ✅ Commit after EVERY fix  
- ✅ Follow ASSESS → FIX → COMMIT → VALIDATE loop
- ❌ NO adding features
- ❌ NO refactoring unrelated code
- ❌ NO optimizing prematurely
- ❌ NO "I should also..." thoughts

**If validation says "fix X"** → Fix X only. Not X + Y + Z.

---

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed spec file: {spec_path}
- NO full conversation history

### Command:
```bash
{design_ops_script} generate {spec_path}
```

### MANDATORY Loop (DO NOT SKIP ANY STEP):

**1. ASSESS:**
```bash
{design_ops_script} generate {spec_path}
```

**2. IF PASS:**
✅ PRP generated at {prp_file}
✅ Mark task complete and unblock next gate.
✅ Done.

**3. IF FAIL:**

**3a. READ INSTRUCTION:**
```bash
cat {spec_path}.generate-instruction.md
```

**3b. FIX:**
Edit spec to address extraction issues.

**3c. 🚨 MANDATORY GIT COMMIT (DO NOT SKIP):**
```bash
git add {spec_path}
git commit -m "ralph: GATE 3 - fix PRP extraction issues"
```

**WHY COMMIT IS MANDATORY:**
- Gate 4 (CHECK_PRP) reads PRP from committed state
- Without commit, PRP validation fails

**3d. VERIFY COMMIT:**
```bash
git log -1 --oneline
```

**3e. RE-VALIDATE:**
```bash
{design_ops_script} generate {spec_path}
```

**3f. LOOP:**
If still failing, go back to step 3a.

**Output:**
PRP file created at: {prp_file}

**Telemetry:**
Write to `.ralph/metrics/gate-3.json` on completion.
""",
            "activeForm": "Running GATE 3: GENERATE_PRP",
            "blocks": ["ralph-4"],
            "blockedBy": ["ralph-2"]
        },

        # GATE 4: CHECK_PRP
        {
            "id": "ralph-4",
            "subject": "GATE 4: CHECK_PRP - Validate PRP structure",
            "description": f"""## GATE 4: CHECK_PRP

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Understand: Your ONE job is to make THIS gate pass
3. Remember: NO extra features, NO refactoring outside scope

**Rules:**
- ✅ Fix ONLY what fails validation
- ✅ Commit after EVERY fix  
- ✅ Follow ASSESS → FIX → COMMIT → VALIDATE loop
- ❌ NO adding features
- ❌ NO refactoring unrelated code
- ❌ NO optimizing prematurely
- ❌ NO "I should also..." thoughts

**If validation says "fix X"** → Fix X only. Not X + Y + Z.

---

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed PRP file: {prp_file}
- NO full conversation history

### Command:
```bash
{design_ops_script} check {prp_file}
```

### MANDATORY Loop (DO NOT SKIP ANY STEP):

**1. ASSESS:**
```bash
{design_ops_script} check {prp_file}
```

**2. IF PASS:**
✅ Mark task complete and unblock next gate.
✅ Done.

**3. IF FAIL:**

**3a. READ VALIDATION ERRORS:**
The `check` command outputs structural validation errors to console.
Review the error output above (NO instruction file is generated).

Common PRP structure issues:
- Missing required sections (Goal, Context, Requirements, etc.)
- Incomplete requirement definitions
- Missing acceptance criteria
- Ambiguous technical constraints

**3b. FIX:**
Edit PRP to fix ALL structure issues shown in validation output.

**3c. 🚨 MANDATORY GIT COMMIT (DO NOT SKIP):**
```bash
git add {prp_file}
git commit -m "ralph: GATE 4 - fix PRP structure"
```

**WHY COMMIT IS MANDATORY:**
- Gate 5 (GENERATE_TESTS) reads PRP from committed state
- Test generation depends on clean PRP

**3d. VERIFY COMMIT:**
```bash
git log -1 --oneline
```

**3e. RE-VALIDATE:**
```bash
{design_ops_script} check {prp_file}
```

**3f. LOOP:**
If still failing, go back to step 3a.

**Telemetry:**
Write to `.ralph/metrics/gate-4.json` on completion.
""",
            "activeForm": "Running GATE 4: CHECK_PRP",
            "blocks": ["ralph-5"],
            "blockedBy": ["ralph-3"]
        },

        # GATE 5: GENERATE_TESTS
        {
            "id": "ralph-5",
            "subject": "GATE 5: GENERATE_TESTS - Create test suite",
            "description": f"""## GATE 5: GENERATE_TESTS

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Understand: Your ONE job is to make THIS gate pass
3. Remember: NO extra features, NO refactoring outside scope

**Rules:**
- ✅ Fix ONLY what fails validation
- ✅ Commit after EVERY fix  
- ✅ Follow ASSESS → FIX → COMMIT → VALIDATE loop
- ❌ NO adding features
- ❌ NO refactoring unrelated code
- ❌ NO optimizing prematurely
- ❌ NO "I should also..." thoughts

**If validation says "fix X"** → Fix X only. Not X + Y + Z.

---

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed PRP file: {prp_file}
- NO full conversation history

### Command:
```bash
{design_ops_script} generate-tests {prp_file}
```

### MANDATORY Loop (DO NOT SKIP ANY STEP):

**1. ASSESS:**
```bash
{design_ops_script} generate-tests {prp_file}
```

**2. IF PASS:**
✅ Tests generated in {test_dir}/
✅ Mark task complete and unblock next gate.
✅ Done.

**3. IF FAIL:**

**3a. READ INSTRUCTION:**
```bash
cat {prp_file}.generate-tests-instruction.md
```

**3b. FIX:**
Generate 30-40 unit tests covering:
- Happy paths
- Error paths
- Edge cases
- Boundary conditions

**3c. 🚨 MANDATORY GIT COMMIT (DO NOT SKIP):**
```bash
git add {test_dir}/
git commit -m "ralph: GATE 5 - generate test suite"
```

**WHY COMMIT IS MANDATORY:**
- Gate 5.5 (TEST_VALIDATION) reads tests from committed state
- Gate 6 (IMPLEMENT_TDD) depends on committed tests

**3d. VERIFY COMMIT:**
```bash
git log -1 --oneline
git status  # Should be clean
```

**3e. RE-VALIDATE:**
```bash
{design_ops_script} generate-tests {prp_file}
```

**3f. LOOP:**
If still failing, go back to step 3a.

**Output:**
Test files in: {test_dir}/

**Telemetry:**
Write to `.ralph/metrics/gate-5.json` on completion.
""",
            "activeForm": "Running GATE 5: GENERATE_TESTS",
            "blocks": ["ralph-5.5"],
            "blockedBy": ["ralph-4"]
        },

        # GATE 5.5: TEST_VALIDATION + TEST_QUALITY
        {
            "id": "ralph-5.5",
            "subject": "GATE 5.5: TEST_VALIDATION + TEST_QUALITY - Validate test suite",
            "description": f"""## GATE 5.5: TEST_VALIDATION + TEST_QUALITY

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Understand: Your ONE job is to make THIS gate pass
3. Remember: NO extra features, NO refactoring outside scope

**Rules:**
- ✅ Fix ONLY what fails validation
- ✅ Commit after EVERY fix  
- ✅ Follow ASSESS → FIX → COMMIT → VALIDATE loop
- ❌ NO adding features
- ❌ NO refactoring unrelated code
- ❌ NO optimizing prematurely
- ❌ NO "I should also..." thoughts

**If validation says "fix X"** → Fix X only. Not X + Y + Z.

---

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed test files: {test_dir}/
- NO full conversation history

### Commands:
```bash
{design_ops_script} test-validate {test_dir}
{design_ops_script} test-quality {test_dir}
```

### MANDATORY Loop (DO NOT SKIP ANY STEP):

**1. ASSESS:**
```bash
{design_ops_script} test-validate {test_dir}
{design_ops_script} test-quality {test_dir}
```

Check:
- All tests fail initially (RED state)
- No weak assertions
- Proper AAA structure
- Edge cases covered

**2. IF BOTH PASS:**
✅ Mark task complete and unblock next gate.
✅ Done.

**3. IF EITHER FAILS:**

**3a. READ INSTRUCTIONS:**
```bash
cat {test_dir}.test-validate-instruction.md
cat {test_dir}.test-quality-instruction.md
```

**3b. FIX:**
Edit tests to fix issues.

**3c. 🚨 MANDATORY GIT COMMIT (DO NOT SKIP):**
```bash
git add {test_dir}/
git commit -m "ralph: GATE 5.5 - fix test suite quality"
```

**WHY COMMIT IS MANDATORY:**
- Gate 6 (IMPLEMENT_TDD) reads tests from committed state
- TDD loop depends on clean, failing tests

**3d. VERIFY COMMIT:**
```bash
git log -1 --oneline
```

**3e. RE-VALIDATE:**
```bash
{design_ops_script} test-validate {test_dir}
{design_ops_script} test-quality {test_dir}
```

**3f. LOOP:**
If still failing, go back to step 3a.

**Telemetry:**
Write to `.ralph/metrics/gate-5.5.json` on completion.
""",
            "activeForm": "Running GATE 5.5: TEST_VALIDATION + TEST_QUALITY",
            "blocks": ["ralph-5.75"],
            "blockedBy": ["ralph-5"]
        },

        # GATE 5.75: PREFLIGHT
        {
            "id": "ralph-5.75",
            "subject": "GATE 5.75: PREFLIGHT - Environment checks",
            "description": f"""## GATE 5.75: PREFLIGHT

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Understand: Your ONE job is to make THIS gate pass
3. Remember: NO extra features, NO refactoring outside scope

**Rules:**
- ✅ Fix ONLY what fails validation
- ✅ Commit after EVERY fix  
- ✅ Follow ASSESS → FIX → COMMIT → VALIDATE loop
- ❌ NO adding features
- ❌ NO refactoring unrelated code
- ❌ NO optimizing prematurely
- ❌ NO "I should also..." thoughts

**If validation says "fix X"** → Fix X only. Not X + Y + Z.

---

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed project files
- NO full conversation history

### Command:
```bash
{design_ops_script} preflight {code_dir.parent}
```

### MANDATORY Loop (DO NOT SKIP ANY STEP):

**1. ASSESS:**
```bash
{design_ops_script} preflight {code_dir.parent}
```

Check:
- Dependencies installed
- Build system working
- Test runner configured
- Environment variables set

**2. IF PASS:**
✅ Mark task complete and unblock next gate.
✅ Done.

**3. IF FAIL:**

**3a. READ INSTRUCTION:**
```bash
cat {code_dir.parent}/preflight-instruction.md
```

**3b. FIX:**
Fix environment issues.

**3c. 🚨 MANDATORY GIT COMMIT (DO NOT SKIP):**
```bash
git add .
git commit -m "ralph: GATE 5.75 - fix environment setup"
```

**WHY COMMIT IS MANDATORY:**
- Gate 6 (IMPLEMENT_TDD) depends on working environment
- Package.json / requirements.txt must be committed

**3d. VERIFY COMMIT:**
```bash
git log -1 --oneline
```

**3e. RE-VALIDATE:**
```bash
{design_ops_script} preflight {code_dir.parent}
```

**3f. LOOP:**
If still failing, go back to step 3a.

**Telemetry:**
Write to `.ralph/metrics/gate-5.75.json` on completion.
""",
            "activeForm": "Running GATE 5.75: PREFLIGHT",
            "blocks": ["ralph-6"],
            "blockedBy": ["ralph-5.5"]
        },

        # GATE 6: IMPLEMENT_TDD
        {
            "id": "ralph-6",
            "subject": "GATE 6: IMPLEMENT_TDD - Write code to pass tests",
            "description": f"""## GATE 6: IMPLEMENT_TDD

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Understand: Your ONE job is to make THIS gate pass
3. Remember: NO extra features, NO refactoring outside scope

**Rules:**
- ✅ Fix ONLY what fails validation
- ✅ Commit after EVERY fix  
- ✅ Follow ASSESS → FIX → COMMIT → VALIDATE loop
- ❌ NO adding features
- ❌ NO refactoring unrelated code
- ❌ NO optimizing prematurely
- ❌ NO "I should also..." thoughts

**If validation says "fix X"** → Fix X only. Not X + Y + Z.

---

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed test files: {test_dir}/
- Latest committed source files: {code_dir}/
- Current test failures
- NO full conversation history

### TDD Micro-Loop (ONE test at a time):

**For each failing test:**

**1. RED:** Confirm test fails
**2. GREEN:** Write MINIMAL code to pass
**3. REFACTOR:** Clean up if needed
**4. 🚨 MANDATORY GIT COMMIT (DO NOT SKIP):**
```bash
git add {code_dir}/ {test_dir}/
git commit -m "ralph: GATE 6 - pass test: [test_name]"
```

**WHY COMMIT AFTER EACH TEST:**
- Stateless gates require granular commits
- Each commit is ONE test passing
- Audit trail shows TDD progression

### Overall Loop:

**1. ASSESS:**
```bash
cd {code_dir.parent} && pytest {test_dir}/
```

**2. IF ALL TESTS PASS:**
✅ Mark task complete and unblock next gate.
✅ Done.

**3. IF ANY FAIL:**

**3a. Pick ONE failing test**

**3b. Run TDD micro-loop (above) for that ONE test**

**3c. VERIFY COMMIT:**
```bash
git log -1 --oneline
# Should show: "ralph: GATE 6 - pass test: [specific_test_name]"
```

**3d. RE-RUN ALL TESTS:**
```bash
pytest {test_dir}/
```

**3e. LOOP:**
If more tests failing, go back to step 3a.

**Critical Rules:**
- 🚨 ONE test at a time
- 🚨 COMMIT after EACH test passes
- 🚨 MINIMAL code only
- 🚨 NO speculative features

**Telemetry:**
Write to `.ralph/metrics/gate-6.json` on completion.
""",
            "activeForm": "Running GATE 6: IMPLEMENT_TDD",
            "blocks": ["ralph-6.5"],
            "blockedBy": ["ralph-5.75"]
        },

        # GATE 6.5: PARALLEL_CHECKS
        {
            "id": "ralph-6.5",
            "subject": "GATE 6.5: PARALLEL_CHECKS - Build/Lint/Integration/A11y",
            "description": f"""## GATE 6.5: PARALLEL_CHECKS

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Understand: Your ONE job is to make THIS gate pass
3. Remember: NO extra features, NO refactoring outside scope

**Rules:**
- ✅ Fix ONLY what fails validation
- ✅ Commit after EVERY fix  
- ✅ Follow ASSESS → FIX → COMMIT → VALIDATE loop
- ❌ NO adding features
- ❌ NO refactoring unrelated code
- ❌ NO optimizing prematurely
- ❌ NO "I should also..." thoughts

**If validation says "fix X"** → Fix X only. Not X + Y + Z.

---

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed source files: {code_dir}/
- NO full conversation history

### Command:
```bash
{design_ops_script} parallel-checks {code_dir.parent}
```

Runs in parallel:
1. Build validation
2. Linting
3. Integration tests
4. A11y checks

### MANDATORY Loop (DO NOT SKIP ANY STEP):

**1. ASSESS:**
```bash
{design_ops_script} parallel-checks {code_dir.parent}
```

**2. IF ALL PASS:**
✅ Mark task complete and unblock next gate.
✅ Done.

**3. IF ANY FAIL:**

**3a. READ INSTRUCTION:**
```bash
cat {code_dir.parent}/parallel-checks-instruction.md
```

**3b. FIX:**
Address all failures.

**3c. 🚨 MANDATORY GIT COMMIT (DO NOT SKIP):**
```bash
git add {code_dir}/
git commit -m "ralph: GATE 6.5 - fix parallel check failures"
```

**WHY COMMIT IS MANDATORY:**
- Gate 6.9 (VISUAL_REGRESSION) reads from committed state
- Clean build required for visual tests

**3d. VERIFY COMMIT:**
```bash
git log -1 --oneline
```

**3e. RE-VALIDATE:**
```bash
{design_ops_script} parallel-checks {code_dir.parent}
```

**3f. LOOP:**
If still failing, go back to step 3a.

**Telemetry:**
Write to `.ralph/metrics/gate-6.5.json` on completion.
""",
            "activeForm": "Running GATE 6.5: PARALLEL_CHECKS",
            "blocks": ["ralph-6.9"],
            "blockedBy": ["ralph-6"]
        },

        # GATE 6.9: VISUAL_REGRESSION
        {
            "id": "ralph-6.9",
            "subject": "GATE 6.9: VISUAL_REGRESSION - Screenshot testing",
            "description": f"""## GATE 6.9: VISUAL_REGRESSION

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Understand: Your ONE job is to make THIS gate pass
3. Remember: NO extra features, NO refactoring outside scope

**Rules:**
- ✅ Fix ONLY what fails validation
- ✅ Commit after EVERY fix  
- ✅ Follow ASSESS → FIX → COMMIT → VALIDATE loop
- ❌ NO adding features
- ❌ NO refactoring unrelated code
- ❌ NO optimizing prematurely
- ❌ NO "I should also..." thoughts

**If validation says "fix X"** → Fix X only. Not X + Y + Z.

---

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed source files: {code_dir}/
- Baseline screenshots
- NO full conversation history

### Command:
```bash
{design_ops_script} visual-regression {code_dir.parent}
```

### MANDATORY Loop (DO NOT SKIP ANY STEP):

**1. ASSESS:**
```bash
{design_ops_script} visual-regression {code_dir.parent}
```

**2. IF PASS:**
✅ Mark task complete and unblock next gate.
✅ Done.

**3. IF FAIL:**

**3a. READ DIFF REPORT:**
```bash
open {code_dir.parent}/.ralph/visual-regression-report.html
```

**3b. DETERMINE:**
- Expected change? Approve baseline
- Regression? Fix code

**3c. FIX OR APPROVE:**
If regression: Fix code
If intended: Approve baseline:
```bash
{design_ops_script} visual-regression-approve {code_dir.parent}
```

**3d. 🚨 MANDATORY GIT COMMIT (DO NOT SKIP):**
```bash
git add {code_dir}/ .ralph/visual-baselines/
git commit -m "ralph: GATE 6.9 - fix visual regression OR approve new baseline"
```

**WHY COMMIT IS MANDATORY:**
- Gate 7 (SMOKE_TEST) reads from committed state
- Baseline screenshots must be versioned

**3e. VERIFY COMMIT:**
```bash
git log -1 --oneline
```

**3f. RE-VALIDATE:**
```bash
{design_ops_script} visual-regression {code_dir.parent}
```

**3g. LOOP:**
If still failing, go back to step 3a.

**Telemetry:**
Write to `.ralph/metrics/gate-6.9.json` on completion.
""",
            "activeForm": "Running GATE 6.9: VISUAL_REGRESSION",
            "blocks": ["ralph-7"],
            "blockedBy": ["ralph-6.5"]
        },

        # GATE 7: SMOKE_TEST
        {
            "id": "ralph-7",
            "subject": "GATE 7: SMOKE_TEST - E2E critical paths",
            "description": f"""## GATE 7: SMOKE_TEST

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Understand: Your ONE job is to make THIS gate pass
3. Remember: NO extra features, NO refactoring outside scope

**Rules:**
- ✅ Fix ONLY what fails validation
- ✅ Commit after EVERY fix  
- ✅ Follow ASSESS → FIX → COMMIT → VALIDATE loop
- ❌ NO adding features
- ❌ NO refactoring unrelated code
- ❌ NO optimizing prematurely
- ❌ NO "I should also..." thoughts

**If validation says "fix X"** → Fix X only. Not X + Y + Z.

---

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed source files: {code_dir}/
- Latest committed E2E tests
- NO full conversation history

### Command:
```bash
{design_ops_script} smoke-test {code_dir.parent}
```

### MANDATORY Loop (DO NOT SKIP ANY STEP):

**1. ASSESS:**
```bash
{design_ops_script} smoke-test {code_dir.parent}
```

**2. IF ALL PASS:**
✅ Mark task complete and unblock next gate.
✅ Done.

**3. IF ANY FAIL:**

**3a. READ REPORT:**
```bash
cat {code_dir.parent}/.ralph/smoke-test-report.html
```

**3b. FIX:**
Address E2E failures.

**3c. 🚨 MANDATORY GIT COMMIT (DO NOT SKIP):**
```bash
git add {code_dir}/
git commit -m "ralph: GATE 7 - fix smoke test failures"
```

**WHY COMMIT IS MANDATORY:**
- Gate 8 (AI_CODE_REVIEW) reads from committed state
- Final review requires working system

**3d. VERIFY COMMIT:**
```bash
git log -1 --oneline
```

**3e. RE-VALIDATE:**
```bash
{design_ops_script} smoke-test {code_dir.parent}
```

**3f. LOOP:**
If still failing, go back to step 3a.

**Critical Paths Tested:**
- User login/auth
- Core feature workflows
- Data CRUD operations
- Error handling

**Telemetry:**
Write to `.ralph/metrics/gate-7.json` on completion.
""",
            "activeForm": "Running GATE 7: SMOKE_TEST",
            "blocks": ["ralph-8"],
            "blockedBy": ["ralph-6.9"]
        },

        # GATE 8: AI_CODE_REVIEW + PERFORMANCE_AUDIT
        {
            "id": "ralph-8",
            "subject": "GATE 8: AI_CODE_REVIEW + PERFORMANCE_AUDIT - Final validation",
            "description": f"""## GATE 8: AI_CODE_REVIEW + PERFORMANCE_AUDIT

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Understand: Your ONE job is to make THIS gate pass
3. Remember: NO extra features, NO refactoring outside scope

**Rules:**
- ✅ Fix ONLY what fails validation
- ✅ Commit after EVERY fix  
- ✅ Follow ASSESS → FIX → COMMIT → VALIDATE loop
- ❌ NO adding features
- ❌ NO refactoring unrelated code
- ❌ NO optimizing prematurely
- ❌ NO "I should also..." thoughts

**If validation says "fix X"** → Fix X only. Not X + Y + Z.

---

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed source files: {code_dir}/
- NO full conversation history

### Commands:
```bash
{design_ops_script} ai-review {code_dir.parent}
{design_ops_script} performance-audit {code_dir.parent}
```

### MANDATORY Loop (DO NOT SKIP ANY STEP):

**1. ASSESS:**
```bash
{design_ops_script} ai-review {code_dir.parent}
{design_ops_script} performance-audit {code_dir.parent}
```

**2. IF BOTH PASS:**
✅ No critical issues
✅ Mark task complete
✅ 🎉 RALPH PIPELINE COMPLETE!
✅ Done.

**3. IF EITHER FAILS:**

**3a. READ REPORTS:**
```bash
cat {code_dir.parent}/.ralph/ai-review-report.md
cat {code_dir.parent}/.ralph/performance-report.json
```

**3b. FIX:**
Address issues:
- Security: CRITICAL (fix immediately)
- Quality: HIGH (refactor)
- Performance: MEDIUM (optimize)

**3c. 🚨 MANDATORY GIT COMMIT (DO NOT SKIP):**
```bash
git add {code_dir}/
git commit -m "ralph: GATE 8 - fix security/quality/performance issues"
```

**WHY COMMIT IS MANDATORY:**
- Final commit = production-ready state
- Git tag will mark this commit
- Deployment reads from this commit

**3d. VERIFY COMMIT:**
```bash
git log -1 --oneline
```

**3e. RE-VALIDATE:**
```bash
{design_ops_script} ai-review {code_dir.parent}
{design_ops_script} performance-audit {code_dir.parent}
```

**3f. LOOP:**
If still failing, go back to step 3a.

**Final Output:**
- Security report: {code_dir.parent}/.ralph/ai-review-report.md
- Performance metrics: {code_dir.parent}/.ralph/performance-report.json
- Production readiness: ✅ or ❌

**Telemetry:**
Write to `.ralph/metrics/gate-8.json` on completion.
Write final summary to `.ralph/COMPLETE.md`.

**🎉 CONGRATULATIONS - RALPH PIPELINE COMPLETE!**

All 12 gates passed. Code is production-ready.

Git history shows full audit trail:
```bash
git log --oneline --grep="ralph: GATE"
```
""",
            "activeForm": "Running GATE 8: AI_CODE_REVIEW + PERFORMANCE_AUDIT",
            "blocks": [],
            "blockedBy": ["ralph-7"]
        }
    ]

    return tasks


def main():
    if len(sys.argv) < 2:
        print("Usage: python ralph-orchestrator-v2.py <spec-file>")
        print("\nExample:")
        print("  python ralph-orchestrator-v2.py specs/S-001-feature.md")
        sys.exit(1)

    spec_file = sys.argv[1]

    print("=" * 80)
    print("RALPH ORCHESTRATOR V2 - Task Generation")
    print("🚨 GIT COMMITS NOW MANDATORY AND EXPLICIT")
    print("=" * 80)
    print(f"\nSpec file: {spec_file}")

    tasks = generate_tasks(spec_file)

    # Output task JSON for Claude Code to consume
    output_file = Path(".ralph/tasks.json")
    output_file.parent.mkdir(exist_ok=True)

    with open(output_file, 'w') as f:
        json.dump(tasks, f, indent=2)

    print(f"\n✅ Generated {len(tasks)} tasks with MANDATORY git commits")
    print(f"📄 Task definitions written to: {output_file}")
    print("\nKey changes in V2:")
    print("  🚨 Git commits are now MANDATORY (bold, caps, explicit)")
    print("  🚨 Each commit has VERIFY step (git log check)")
    print("  🚨 WHY COMMIT IS MANDATORY section explains reason")
    print("  🚨 GATE 6: Commit after EACH test (not end of gate)")
    print("\nNext steps:")
    print("1. Review .ralph/tasks.json")
    print("2. In Claude Code, run:")
    print("   python ~/.claude/design-ops/enforcement/ralph-task-loader.py")
    print("\nTasks will enforce git commits at every fix iteration.")


if __name__ == "__main__":
    main()

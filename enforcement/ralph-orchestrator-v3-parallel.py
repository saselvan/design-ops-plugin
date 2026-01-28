#!/usr/bin/env python3
"""
RALPH Orchestrator v3 - With Parallel Sub-Agent Support

Key Features:
- Sequential gates (unchanged)
- Parallel sub-agents WITHIN gates where applicable
- MANDATORY git commits
- Stateless execution

Usage:
    python ralph-orchestrator-v3-parallel.py <spec-file>
"""

import sys
import os
from pathlib import Path
import json

def generate_tasks(spec_file):
    """Generate all 12 RALPH gates with parallel sub-agent support where applicable."""

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
        # GATE 1: STRESS_TEST (no parallelism - single spec file)
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

---

**STATELESS CONTEXT:**
- Latest committed spec file: {spec_path}
- Errors from last stress-test run

### MANDATORY Loop:

**1. ASSESS:**
```bash
{design_ops_script} stress-test {spec_path}
```

**2. IF PASS:**
✅ Mark task complete and unblock next gate.

**3. IF FAIL:**

**3a. READ INSTRUCTION:**
```bash
cat {spec_path}.stress-test-instruction.md
```

**3b. FIX:**
Edit spec to address ALL gaps.

**3c. 🚨 MANDATORY GIT COMMIT:**
```bash
git add {spec_path}
git commit -m "ralph: GATE 1 - fix completeness gaps"
```

**3d. VERIFY COMMIT:**
```bash
git log -1 --oneline
```

**3e. RE-VALIDATE:**
Go back to step 1.
""",
            "activeForm": "Running GATE 1: STRESS_TEST",
            "blocks": ["ralph-2"],
            "blockedBy": []
        },

        # GATE 2: VALIDATE + SECURITY_SCAN (PARALLEL SUB-AGENTS)
        {
            "id": "ralph-2",
            "subject": "GATE 2: VALIDATE + SECURITY_SCAN - 43 invariants + security",
            "description": f"""## GATE 2: VALIDATE + SECURITY_SCAN

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Your ONE job: Make THIS gate pass
3. NO extra features, NO refactoring outside scope

---

## ⚡ PARALLEL EXECUTION STRATEGY

This gate has TWO independent validations that can run in parallel:

1. **VALIDATE**: Check 43 system invariants
2. **SECURITY_SCAN**: Check security rules

**RECOMMENDED APPROACH:**

Launch 2 parallel sub-agents in a SINGLE message using the Task tool:

```
Launch two parallel agents:
1. Agent A: Run validate on {spec_path}
2. Agent B: Run security-scan on {spec_path}
```

**Each sub-agent follows:**

### Sub-Agent A: VALIDATE

**1. ASSESS:**
```bash
{design_ops_script} validate {spec_path}
```

**2. IF FAIL:**
- Read: `cat {spec_path}.validation-instruction.md`
- Fix violations
- **Commit:** `git commit -m "ralph: GATE 2A - fix invariant violations"`
- Re-validate

### Sub-Agent B: SECURITY_SCAN

**1. ASSESS:**
```bash
{design_ops_script} security-scan {spec_path}
```

**2. IF FAIL:**
- Read: `cat {spec_path}.security-instruction.md`
- Fix security issues
- **Commit:** `git commit -m "ralph: GATE 2B - fix security issues"`
- Re-validate

### GATE COMPLETE WHEN:
✅ Both sub-agents report PASS
✅ All commits made
✅ Unblock GATE 3
""",
            "activeForm": "Running GATE 2: VALIDATE + SECURITY_SCAN",
            "blocks": ["ralph-3"],
            "blockedBy": ["ralph-1"]
        },

        # GATE 3: GENERATE_PRP (no parallelism - single PRP file)
        {
            "id": "ralph-3",
            "subject": "GATE 3: GENERATE_PRP - Extract requirements",
            "description": f"""## GATE 3: GENERATE_PRP

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Your ONE job: Generate PRP from validated spec
3. NO extra features

---

**STATELESS CONTEXT:**
- Latest committed spec file: {spec_path}
- Output: {prp_file}

### MANDATORY Loop:

**1. GENERATE:**
```bash
{design_ops_script} generate {spec_path}
```

This creates: {prp_file}

**2. COMMIT:**
```bash
git add {prp_file}
git commit -m "ralph: GATE 3 - generate PRP"
```

**3. VERIFY:**
```bash
git log -1 --oneline
ls -lh {prp_file}
```

✅ Mark complete and unblock GATE 4.
""",
            "activeForm": "Running GATE 3: GENERATE_PRP",
            "blocks": ["ralph-4"],
            "blockedBy": ["ralph-2"]
        },

        # GATE 4: CHECK_PRP (no parallelism - single PRP file)
        {
            "id": "ralph-4",
            "subject": "GATE 4: CHECK_PRP - Validate PRP structure",
            "description": f"""## GATE 4: CHECK_PRP

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Your ONE job: Make PRP pass structural validation
3. NO extra features

---

**STATELESS CONTEXT:**
- Latest committed PRP file: {prp_file}

### MANDATORY Loop:

**1. ASSESS:**
```bash
{design_ops_script} check {prp_file}
```

**NOTE**: This command outputs errors to CONSOLE (no instruction file).

**2. IF PASS:**
✅ Mark complete and unblock GATE 5.

**3. IF FAIL:**

**3a. READ VALIDATION ERRORS:**
Review console output above.

Common PRP structure issues:
- Missing required sections
- Incomplete requirement definitions
- Malformed YAML frontmatter

**3b. FIX:**
Edit {prp_file} to fix structural issues.

**3c. 🚨 MANDATORY GIT COMMIT:**
```bash
git add {prp_file}
git commit -m "ralph: GATE 4 - fix PRP structure"
```

**3d. RE-VALIDATE:**
Go back to step 1.
""",
            "activeForm": "Running GATE 4: CHECK_PRP",
            "blocks": ["ralph-5"],
            "blockedBy": ["ralph-3"]
        },

        # GATE 5: GENERATE_TESTS (PARALLEL SUB-AGENTS POSSIBLE)
        {
            "id": "ralph-5",
            "subject": "GATE 5: GENERATE_TESTS - Create 30-40 unit tests",
            "description": f"""## GATE 5: GENERATE_TESTS

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Your ONE job: Generate tests from PRP
3. NO implementation code yet (tests only)

---

## ⚡ PARALLEL EXECUTION STRATEGY (Optional)

If PRP has multiple independent modules/components, you can parallelize:

**Option A: Sequential (Simple)**
```bash
{design_ops_script} generate-tests {prp_file}
```

Generates all tests in {test_dir}/

**Option B: Parallel (Advanced)**

If PRP has clear module boundaries:

Launch parallel sub-agents in SINGLE message:

```
Launch parallel agents to generate tests for:
1. Agent A: auth module tests
2. Agent B: data module tests
3. Agent C: API module tests
```

Each agent generates tests for their module, commits separately.

### MANDATORY After Generation:

**COMMIT ALL TESTS:**
```bash
git add {test_dir}/
git commit -m "ralph: GATE 5 - generate tests"
```

**VERIFY:**
```bash
git log -1 --oneline
find {test_dir} -name "*.test.*" | wc -l
# Should show 30-40 test files
```

✅ Mark complete and unblock GATE 5.5.
""",
            "activeForm": "Running GATE 5: GENERATE_TESTS",
            "blocks": ["ralph-5.5"],
            "blockedBy": ["ralph-4"]
        },

        # GATE 5.5: TEST_VALIDATE + TEST_QUALITY (PARALLEL SUB-AGENTS)
        {
            "id": "ralph-5.5",
            "subject": "GATE 5.5: TEST_VALIDATE + TEST_QUALITY - Verify tests",
            "description": f"""## GATE 5.5: TEST_VALIDATE + TEST_QUALITY

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Your ONE job: Verify tests are valid and high-quality
3. NO implementation code yet

---

## ⚡ PARALLEL EXECUTION STRATEGY

TWO independent checks that can run in parallel:

1. **TEST_VALIDATE**: Verify tests FAIL (RED state - no implementation yet)
2. **TEST_QUALITY**: Check test quality (assertions, AAA pattern)

**Launch 2 parallel sub-agents:**

### Sub-Agent A: TEST_VALIDATE

**1. ASSESS:**
```bash
{design_ops_script} test-validate {test_dir}
```

**2. IF FAIL:**
- Tests are passing (BAD - no implementation exists)
- Fix: Make tests properly fail
- Commit: `git commit -m "ralph: GATE 5.5A - fix test validation"`

### Sub-Agent B: TEST_QUALITY

**1. ASSESS:**
```bash
{design_ops_script} test-quality {test_dir}
```

**2. IF FAIL:**
- Fix weak assertions
- Add AAA pattern
- Commit: `git commit -m "ralph: GATE 5.5B - improve test quality"`

### GATE COMPLETE WHEN:
✅ Both sub-agents report PASS
✅ All commits made
✅ Unblock GATE 5.75
""",
            "activeForm": "Running GATE 5.5: TEST_VALIDATE + TEST_QUALITY",
            "blocks": ["ralph-5.75"],
            "blockedBy": ["ralph-5"]
        },

        # GATE 5.75: PREFLIGHT (no parallelism - environment check)
        {
            "id": "ralph-5.75",
            "subject": "GATE 5.75: PREFLIGHT - Pre-implementation checks",
            "description": f"""## GATE 5.75: PREFLIGHT

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Your ONE job: Verify environment is ready for implementation
3. NO implementation code yet

---

**STATELESS CONTEXT:**
- Check dependencies, build system, test runner

### MANDATORY Check:

**1. ASSESS:**
```bash
{design_ops_script} preflight {test_dir}
```

**2. IF PASS:**
✅ Mark complete and unblock GATE 6.

**3. IF FAIL:**

**3a. READ INSTRUCTION:**
```bash
cat {test_dir}.preflight-instruction.md
```

**3b. FIX:**
Install dependencies, configure build system as instructed.

**3c. 🚨 MANDATORY GIT COMMIT:**
```bash
git add package.json requirements.txt # (or relevant files)
git commit -m "ralph: GATE 5.75 - configure environment"
```

**3d. RE-VALIDATE:**
Go back to step 1.
""",
            "activeForm": "Running GATE 5.75: PREFLIGHT",
            "blocks": ["ralph-6"],
            "blockedBy": ["ralph-5.5"]
        },

        # GATE 6: IMPLEMENT_TDD (no parallelism initially - focused implementation)
        {
            "id": "ralph-6",
            "subject": "GATE 6: IMPLEMENT_TDD - Write code to pass tests",
            "description": f"""## GATE 6: IMPLEMENT_TDD

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Your ONE job: Write MINIMAL code to pass tests
3. NO extra features, NO premature optimization

---

**STATELESS CONTEXT:**
- Latest committed test files: {test_dir}/
- Code directory: {code_dir}/

### MANDATORY TDD Loop:

**1. ASSESS:**
```bash
{design_ops_script} implement-tdd {test_dir}
```

**2. IF ALL TESTS PASS:**
✅ Mark complete and unblock GATE 6.5.

**3. IF TESTS FAIL:**

**3a. READ FAILURES:**
Review test output to see what's failing.

**3b. IMPLEMENT:**
Write MINIMAL code to pass ONE failing test.

**3c. 🚨 MANDATORY GIT COMMIT (per passing test):**
```bash
git add {code_dir}/
git commit -m "ralph: GATE 6 - implement [feature] to pass test"
```

**3d. RE-VALIDATE:**
Go back to step 1.

**IMPORTANT:**
- Commit after EACH test starts passing
- NO batch commits
- NO "let me also add..." thinking
""",
            "activeForm": "Running GATE 6: IMPLEMENT_TDD",
            "blocks": ["ralph-6.5"],
            "blockedBy": ["ralph-5.75"]
        },

        # GATE 6.5: PARALLEL_CHECKS (PARALLEL SUB-AGENTS - Most Parallelizable Gate)
        {
            "id": "ralph-6.5",
            "subject": "GATE 6.5: PARALLEL_CHECKS - Build/Lint/A11y",
            "description": f"""## GATE 6.5: PARALLEL_CHECKS

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Your ONE job: Pass all parallel checks
3. NO extra features

---

## ⚡ PARALLEL EXECUTION STRATEGY (HIGHLY PARALLELIZABLE)

THREE independent checks that SHOULD run in parallel:

1. **Build Check**: Code compiles/builds
2. **Lint Check**: Code style/quality
3. **Accessibility Check**: WCAG 2.1 AA compliance

**Launch 3 parallel sub-agents in SINGLE message:**

```
Launch three parallel agents:
1. Agent A: Run build check
2. Agent B: Run lint check
3. Agent C: Run accessibility check
```

### Sub-Agent A: BUILD CHECK

**1. RUN:**
```bash
npm run build
# OR
python -m build
```

**2. IF FAIL:**
- Fix compilation errors
- Commit: `git commit -m "ralph: GATE 6.5A - fix build"`

### Sub-Agent B: LINT CHECK

**1. RUN:**
```bash
npm run lint
# OR
flake8 {code_dir}
```

**2. IF FAIL:**
- Fix linting errors
- Commit: `git commit -m "ralph: GATE 6.5B - fix lint"`

### Sub-Agent C: ACCESSIBILITY CHECK

**1. RUN:**
```bash
{design_ops_script} parallel-checks {code_dir}
```

**2. IF FAIL:**
- Fix a11y issues
- Commit: `git commit -m "ralph: GATE 6.5C - fix accessibility"`

### GATE COMPLETE WHEN:
✅ All 3 sub-agents report PASS
✅ All commits made
✅ Unblock GATE 6.9

**NOTE**: This is the MOST parallelizable gate in RALPH.
""",
            "activeForm": "Running GATE 6.5: PARALLEL_CHECKS",
            "blocks": ["ralph-6.9"],
            "blockedBy": ["ralph-6"]
        },

        # GATE 6.9: VISUAL_REGRESSION (no parallelism - sequential screenshot comparison)
        {
            "id": "ralph-6.9",
            "subject": "GATE 6.9: VISUAL_REGRESSION - UI consistency",
            "description": f"""## GATE 6.9: VISUAL_REGRESSION

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Your ONE job: Set up visual regression testing
3. NO extra features

---

**STATELESS CONTEXT:**
- Latest committed code: {code_dir}/

### MANDATORY Check:

**1. ASSESS:**
```bash
{design_ops_script} visual-regression {code_dir}
```

**2. IF PASS:**
✅ Mark complete and unblock GATE 7.

**3. IF FAIL:**

**3a. READ INSTRUCTION:**
```bash
cat {code_dir}.visual-regression-instruction.md
```

**3b. SETUP:**
Configure Playwright/Cypress for visual regression.

**3c. 🚨 MANDATORY GIT COMMIT:**
```bash
git add playwright.config.js # (or cypress config)
git commit -m "ralph: GATE 6.9 - configure visual regression"
```

**3d. RE-VALIDATE:**
Go back to step 1.
""",
            "activeForm": "Running GATE 6.9: VISUAL_REGRESSION",
            "blocks": ["ralph-7"],
            "blockedBy": ["ralph-6.5"]
        },

        # GATE 7: SMOKE_TEST (no parallelism - sequential E2E scenarios)
        {
            "id": "ralph-7",
            "subject": "GATE 7: SMOKE_TEST - E2E critical paths",
            "description": f"""## GATE 7: SMOKE_TEST

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Your ONE job: Pass E2E smoke tests
3. NO extra features

---

**STATELESS CONTEXT:**
- Latest committed code: {code_dir}/

### MANDATORY Loop:

**1. ASSESS:**
```bash
{design_ops_script} smoke-test {code_dir}
```

**2. IF PASS:**
✅ Mark complete and unblock GATE 8.

**3. IF FAIL:**

**3a. READ INSTRUCTION:**
```bash
cat {code_dir}.smoke-test-instruction.md
```

**3b. FIX:**
Fix E2E failures.

**3c. 🚨 MANDATORY GIT COMMIT:**
```bash
git add {code_dir}/
git commit -m "ralph: GATE 7 - fix E2E failures"
```

**3d. RE-VALIDATE:**
Go back to step 1.
""",
            "activeForm": "Running GATE 7: SMOKE_TEST",
            "blocks": ["ralph-8"],
            "blockedBy": ["ralph-6.9"]
        },

        # GATE 8: AI_REVIEW + PERFORMANCE_AUDIT (PARALLEL SUB-AGENTS)
        {
            "id": "ralph-8",
            "subject": "GATE 8: AI_REVIEW + PERFORMANCE_AUDIT - Final validation",
            "description": f"""## GATE 8: AI_REVIEW + PERFORMANCE_AUDIT

## 🚨 READ FIRST: Gate Constraints

**BEFORE YOU START:**
1. Read: `~/.claude/design-ops/enforcement/ralph-constraints.md`
2. Your ONE job: Pass final security + performance review
3. NO extra features

---

## ⚡ PARALLEL EXECUTION STRATEGY

TWO independent reviews that can run in parallel:

1. **AI_REVIEW**: Opus security/quality review
2. **PERFORMANCE_AUDIT**: Lighthouse/bundle size

**Launch 2 parallel sub-agents:**

### Sub-Agent A: AI_REVIEW

**1. ASSESS:**
```bash
{design_ops_script} ai-review {code_dir}
```

**2. IF FAIL:**
- Fix security issues
- Commit: `git commit -m "ralph: GATE 8A - fix security"`

### Sub-Agent B: PERFORMANCE_AUDIT

**1. ASSESS:**
```bash
{design_ops_script} performance-audit {code_dir}
```

**2. IF FAIL:**
- Fix performance issues
- Commit: `git commit -m "ralph: GATE 8B - optimize performance"`

### GATE COMPLETE WHEN:
✅ Both sub-agents report PASS
✅ All commits made
✅ Pipeline COMPLETE

**🎉 RALPH PIPELINE COMPLETE - Production-ready code!**
""",
            "activeForm": "Running GATE 8: AI_REVIEW + PERFORMANCE_AUDIT",
            "blocks": [],
            "blockedBy": ["ralph-7"]
        }
    ]

    return tasks

def main():
    if len(sys.argv) < 2:
        print("Usage: python ralph-orchestrator-v3-parallel.py <spec-file>")
        sys.exit(1)

    spec_file = sys.argv[1]

    print("RALPH ORCHESTRATOR v3 - With Parallel Sub-Agent Support")
    print("=" * 60)
    print(f"Spec file: {spec_file}")
    print()

    tasks = generate_tasks(spec_file)

    # Create .ralph directory
    ralph_dir = Path(".ralph")
    ralph_dir.mkdir(exist_ok=True)

    tasks_file = ralph_dir / "tasks.json"

    # Write tasks to JSON
    with open(tasks_file, "w") as f:
        json.dump(tasks, f, indent=2)

    print(f"✅ Generated {len(tasks)} tasks")
    print(f"📄 Task definitions written to: {tasks_file}")
    print()
    print("📊 Parallelizable Gates:")
    print("  - GATE 2: VALIDATE + SECURITY_SCAN (2 parallel sub-agents)")
    print("  - GATE 5: GENERATE_TESTS (optional, if multiple modules)")
    print("  - GATE 5.5: TEST_VALIDATE + TEST_QUALITY (2 parallel sub-agents)")
    print("  - GATE 6.5: PARALLEL_CHECKS (3 parallel sub-agents) ⭐ MOST PARALLEL")
    print("  - GATE 8: AI_REVIEW + PERFORMANCE_AUDIT (2 parallel sub-agents)")
    print()
    print("Next steps:")
    print("1. In Claude Code, say: 'Load the RALPH tasks and create them'")
    print("2. Claude Code will create all 12 tasks with proper dependencies")
    print("3. Tasks will execute in sequence, with parallel sub-agents where noted")
    print()
    print("🎯 Total parallelism opportunities: 9-12 concurrent sub-agents across pipeline")

if __name__ == "__main__":
    main()

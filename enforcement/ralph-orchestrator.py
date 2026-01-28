#!/usr/bin/env python3
"""
RALPH Orchestrator for Claude Code

Generates all 12 RALPH gates as Claude Code tasks with proper dependencies.
Each task is stateless and runs ASSESS → FIX → COMMIT → VALIDATE loop.

Usage:
    python ralph-orchestrator.py <spec-file>

Example:
    python ralph-orchestrator.py specs/S-001-feature.md
"""

import sys
import os
from pathlib import Path
import json

def generate_tasks(spec_file):
    """Generate all 12 RALPH gates as task definitions."""

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

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed spec file: {spec_path}
- Errors from last stress-test run
- Recommended fixes from last assessment
- NO full conversation history

### Command:
```bash
{design_ops_script} stress-test {spec_path}
```

### Loop:

**ASSESS:**
Run stress-test command above.

**IF PASS:**
Mark task complete and unblock next gate.

**IF FAIL:**
1. Read instruction file: {spec_path}.stress-test-instruction.md
2. **FIX:** Edit spec to address ALL gaps (missing context, scope, constraints, risks, acceptance criteria, edge cases)
3. **COMMIT:**
   ```bash
   git add {spec_path}
   git commit -m "ralph: GATE 1 - fix completeness gaps"
   ```
4. **VALIDATE:** Re-run stress-test
5. **LOOP:** Repeat until PASS

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

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed spec file: {spec_path}
- Errors from last validate run
- Recommended fixes from last assessment
- NO full conversation history

### Commands:
```bash
{design_ops_script} validate {spec_path}
{design_ops_script} security-scan {spec_path}
```

### Loop:

**ASSESS:**
Run both commands above.

**IF PASS:**
Mark task complete and unblock next gate.

**IF FAIL:**
1. Read instruction files:
   - {spec_path}.validate-instruction.md (43 invariants)
   - {spec_path}.security-instruction.md (security issues)
2. **FIX:** Edit spec to fix violations (ambiguity, missing error states, security gaps)
3. **COMMIT:**
   ```bash
   git add {spec_path}
   git commit -m "ralph: GATE 2 - fix invariant violations and security issues"
   ```
4. **VALIDATE:** Re-run both commands
5. **LOOP:** Repeat until PASS

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

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed spec file: {spec_path}
- Errors from last generate run
- Recommended fixes from last assessment
- NO full conversation history

### Command:
```bash
{design_ops_script} generate {spec_path}
```

### Loop:

**ASSESS:**
Run generate command above.

**IF PASS:**
PRP generated at {prp_file}. Mark task complete and unblock next gate.

**IF FAIL:**
1. Read instruction file: {spec_path}.generate-instruction.md
2. **FIX:** Edit spec to address extraction issues (missing sections, unclear requirements)
3. **COMMIT:**
   ```bash
   git add {spec_path}
   git commit -m "ralph: GATE 3 - fix PRP extraction issues"
   ```
4. **VALIDATE:** Re-run generate
5. **LOOP:** Repeat until PASS

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

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed PRP file: {prp_file}
- Errors from last check run
- Recommended fixes from last assessment
- NO full conversation history

### Command:
```bash
{design_ops_script} check {prp_file}
```

### Loop:

**ASSESS:**
Run check command above.

**IF PASS:**
Mark task complete and unblock next gate.

**IF FAIL:**
1. Read instruction file: {prp_file}.check-instruction.md
2. **FIX:** Edit PRP to fix structure issues (missing sections, incomplete context, ambiguous requirements)
3. **COMMIT:**
   ```bash
   git add {prp_file}
   git commit -m "ralph: GATE 4 - fix PRP structure"
   ```
4. **VALIDATE:** Re-run check
5. **LOOP:** Repeat until PASS

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

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed PRP file: {prp_file}
- Errors from last test generation run
- Recommended fixes from last assessment
- NO full conversation history

### Command:
```bash
{design_ops_script} generate-tests {prp_file}
```

### Loop:

**ASSESS:**
Run generate-tests command above.

**IF PASS:**
Tests generated in {test_dir}/. Mark task complete and unblock next gate.

**IF FAIL:**
1. Read instruction file: {prp_file}.generate-tests-instruction.md
2. **FIX:** Generate 30-40 unit tests covering:
   - Happy paths
   - Error paths
   - Edge cases
   - Boundary conditions
3. **COMMIT:**
   ```bash
   git add {test_dir}/
   git commit -m "ralph: GATE 5 - generate test suite"
   ```
4. **VALIDATE:** Re-run generate-tests
5. **LOOP:** Repeat until PASS

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

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed test files: {test_dir}/
- Errors from last validation run
- Recommended fixes from last assessment
- NO full conversation history

### Commands:
```bash
{design_ops_script} test-validate {test_dir}
{design_ops_script} test-quality {test_dir}
```

### Loop:

**ASSESS:**
Run both commands above. Check:
- All tests fail initially (RED state - correct behavior before implementation)
- No weak assertions (assertTrue(true), empty tests)
- Proper test structure (AAA pattern: Arrange, Act, Assert)
- Edge cases covered

**IF PASS:**
Mark task complete and unblock next gate.

**IF FAIL:**
1. Read instruction files:
   - {test_dir}.test-validate-instruction.md
   - {test_dir}.test-quality-instruction.md
2. **FIX:** Edit tests to fix issues (weak assertions, missing edge cases, incorrect structure)
3. **COMMIT:**
   ```bash
   git add {test_dir}/
   git commit -m "ralph: GATE 5.5 - fix test suite quality"
   ```
4. **VALIDATE:** Re-run both commands
5. **LOOP:** Repeat until PASS

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

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed project files
- Errors from last preflight run
- Recommended fixes from last assessment
- NO full conversation history

### Command:
```bash
{design_ops_script} preflight {code_dir.parent}
```

### Loop:

**ASSESS:**
Run preflight command above. Check:
- Dependencies installed (package.json/requirements.txt)
- Build system working
- Test runner configured
- Environment variables set

**IF PASS:**
Mark task complete and unblock next gate.

**IF FAIL:**
1. Read instruction file: {code_dir.parent}/preflight-instruction.md
2. **FIX:** Fix environment issues (missing deps, broken build, test runner config)
3. **COMMIT:**
   ```bash
   git add .
   git commit -m "ralph: GATE 5.75 - fix environment setup"
   ```
4. **VALIDATE:** Re-run preflight
5. **LOOP:** Repeat until PASS

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

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed test files: {test_dir}/
- Latest committed source files: {code_dir}/
- Current test failures
- NO full conversation history

### TDD Micro-Loop (ONE test at a time):

**For each failing test:**

1. **RED:** Confirm test fails with expected error
2. **GREEN:** Write MINIMAL code to make it pass
3. **REFACTOR:** Clean up if needed
4. **COMMIT:**
   ```bash
   git add {code_dir}/ {test_dir}/
   git commit -m "ralph: GATE 6 - pass test: [test_name]"
   ```

### Overall Loop:

**ASSESS:**
Run tests:
```bash
cd {code_dir.parent} && pytest {test_dir}/
```

**IF ALL PASS:**
Mark task complete and unblock next gate.

**IF ANY FAIL:**
1. Pick ONE failing test
2. Run TDD micro-loop above
3. **VALIDATE:** Re-run all tests
4. **LOOP:** Repeat until all tests pass

**Critical Rules:**
- ONE test at a time
- MINIMAL code to pass
- Commit after each test passes
- NO speculative features

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

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed source files: {code_dir}/
- Errors from last parallel checks run
- NO full conversation history

### Commands (run in parallel):
```bash
{design_ops_script} parallel-checks {code_dir.parent}
```

This runs:
1. **Build validation** - Clean build succeeds
2. **Linting** - ESLint/Pylint passes
3. **Integration tests** - API/component integration passes
4. **A11y checks** - Accessibility standards met (WCAG 2.1 AA)

### Loop:

**ASSESS:**
Run parallel-checks command above.

**IF PASS:**
Mark task complete and unblock next gate.

**IF FAIL:**
1. Read instruction file: {code_dir.parent}/parallel-checks-instruction.md
2. **FIX:** Address failures:
   - Build errors → fix imports/config
   - Lint errors → fix code style
   - Integration failures → fix API contracts
   - A11y issues → add ARIA labels, alt text, keyboard nav
3. **COMMIT:**
   ```bash
   git add {code_dir}/
   git commit -m "ralph: GATE 6.5 - fix parallel check failures"
   ```
4. **VALIDATE:** Re-run parallel-checks
5. **LOOP:** Repeat until PASS

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

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed source files: {code_dir}/
- Baseline screenshots
- Current screenshots
- Diff report
- NO full conversation history

### Command:
```bash
{design_ops_script} visual-regression {code_dir.parent}
```

### Loop:

**ASSESS:**
Run visual-regression command above. Compare current vs baseline screenshots.

**IF PASS:**
No unexpected visual changes. Mark task complete and unblock next gate.

**IF FAIL:**
1. Read diff report: {code_dir.parent}/.ralph/visual-regression-report.html
2. **DETERMINE:**
   - Expected change? Update baseline screenshots
   - Regression? Fix the code
3. **FIX OR APPROVE:**
   - Fix code if regression
   - Update baseline if intended change:
     ```bash
     {design_ops_script} visual-regression-approve {code_dir.parent}
     ```
4. **COMMIT:**
   ```bash
   git add {code_dir}/ .ralph/visual-baselines/
   git commit -m "ralph: GATE 6.9 - fix visual regression OR approve new baseline"
   ```
5. **VALIDATE:** Re-run visual-regression
6. **LOOP:** Repeat until PASS

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

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed source files: {code_dir}/
- Latest committed E2E tests
- Test failures
- NO full conversation history

### Command:
```bash
{design_ops_script} smoke-test {code_dir.parent}
```

### Loop:

**ASSESS:**
Run smoke-test command above. Test critical user paths end-to-end.

**IF PASS:**
All critical paths working. Mark task complete and unblock next gate.

**IF FAIL:**
1. Read failure report: {code_dir.parent}/.ralph/smoke-test-report.html
2. **FIX:** Address E2E failures:
   - UI not rendering? Fix component
   - API not responding? Fix backend
   - Data not persisting? Fix database layer
   - Navigation broken? Fix routing
3. **COMMIT:**
   ```bash
   git add {code_dir}/
   git commit -m "ralph: GATE 7 - fix smoke test failures"
   ```
4. **VALIDATE:** Re-run smoke-test
5. **LOOP:** Repeat until PASS

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

**STATELESS CONTEXT (each iteration sees ONLY):**
- Latest committed source files: {code_dir}/
- Review report
- Performance metrics
- NO full conversation history

### Commands:
```bash
{design_ops_script} ai-review {code_dir.parent}
{design_ops_script} performance-audit {code_dir.parent}
```

### Loop:

**ASSESS:**
Run both commands above. LLM reviews code for:
- **Security** - SQL injection, XSS, CSRF, auth bypasses
- **Quality** - Code smells, duplicate logic, complexity
- **Performance** - Lighthouse audit, bundle size, load times

**IF PASS:**
No critical issues. Mark task complete. **RALPH PIPELINE COMPLETE!**

**IF FAIL:**
1. Read reports:
   - {code_dir.parent}/.ralph/ai-review-report.md
   - {code_dir.parent}/.ralph/performance-report.json
2. **FIX:** Address issues:
   - Security: Fix vulnerabilities immediately (CRITICAL)
   - Quality: Refactor code smells (HIGH)
   - Performance: Optimize if < 90 Lighthouse score (MEDIUM)
3. **COMMIT:**
   ```bash
   git add {code_dir}/
   git commit -m "ralph: GATE 8 - fix security/quality/performance issues"
   ```
4. **VALIDATE:** Re-run both commands
5. **LOOP:** Repeat until PASS

**Final Output:**
- Security report
- Quality score
- Lighthouse metrics
- Production readiness: ✅ or ❌

**Telemetry:**
Write to `.ralph/metrics/gate-8.json` on completion.
Write final summary to `.ralph/COMPLETE.md`.
""",
            "activeForm": "Running GATE 8: AI_CODE_REVIEW + PERFORMANCE_AUDIT",
            "blocks": [],
            "blockedBy": ["ralph-7"]
        }
    ]

    return tasks


def main():
    if len(sys.argv) < 2:
        print("Usage: python ralph-orchestrator.py <spec-file>")
        print("\nExample:")
        print("  python ralph-orchestrator.py specs/S-001-feature.md")
        sys.exit(1)

    spec_file = sys.argv[1]

    print("=" * 80)
    print("RALPH ORCHESTRATOR - Task Generation")
    print("=" * 80)
    print(f"\nSpec file: {spec_file}")

    tasks = generate_tasks(spec_file)

    # Output task JSON for Claude Code to consume
    output_file = Path(".ralph/tasks.json")
    output_file.parent.mkdir(exist_ok=True)

    with open(output_file, 'w') as f:
        json.dump(tasks, f, indent=2)

    print(f"\n✅ Generated {len(tasks)} tasks")
    print(f"📄 Task definitions written to: {output_file}")
    print("\nNext steps:")
    print("1. Review .ralph/tasks.json")
    print("2. In Claude Code, run:")
    print("   python ~/.claude/design-ops/enforcement/ralph-task-loader.py")
    print("\nThis will create all 12 gates as Claude Code tasks with proper dependencies.")
    print("Tasks will auto-unblock and spawn agents as dependencies complete.")


if __name__ == "__main__":
    main()

#!/bin/bash

# cursor-prompts.sh - Build prompts for Cursor CLI invocations
# Part of the RALPH Design-Ops enforcement system

set -euo pipefail

# Build base Cursor prompt with context
build_cursor_base_prompt() {
    local instruction="$1"
    local feedback="$2"
    local target_file="$3"

    cat <<EOF
You are implementing a change to fix validation failures in the RALPH Design-Ops pipeline.

TARGET FILE: $target_file

INSTRUCTION:
$instruction

VALIDATION FEEDBACK:
$feedback

REQUIREMENTS:
1. Read and understand the target file
2. Apply the changes needed to fix ALL validation failures
3. Preserve all existing working functionality
4. Follow the RALPH specification strictly
5. Make minimal changes - only fix what's broken

Make the changes now. Do not ask for confirmation.
EOF
}

# Gate 0: Create spec from requirements
build_create_spec_prompt() {
    local req_dir="$1"
    local spec_file="$2"
    local instruction="$3"

    cat <<EOF
You are creating a RALPH specification file from a requirements directory.

REQUIREMENTS DIRECTORY: $req_dir
OUTPUT SPEC FILE: $spec_file

INSTRUCTION:
$instruction

REQUIREMENTS:
1. Read all files in the requirements directory
2. Synthesize a complete RALPH spec following the template
3. Include all required sections: User Journey, Technical Requirements, Invariants
4. Write the spec to: $spec_file
5. Follow RALPH-RETRIEVAL.md specification exactly

Create the spec file now.
EOF
}

# Gate 1: Fix completeness gaps (stress-test)
build_fix_gaps_prompt() {
    local spec_file="$1"
    local gaps="$2"

    cat <<EOF
You are fixing completeness gaps in a RALPH specification.

SPEC FILE: $spec_file

COMPLETENESS GAPS FOUND:
$gaps

REQUIREMENTS:
1. Read the current spec file
2. Add missing information for each gap identified
3. Ensure all 6 coverage areas are complete:
   - User Journey (states, transitions, error paths)
   - System Invariants (data, security, performance)
   - Edge Cases
   - Failure Modes
   - Non-Functional Requirements
   - Acceptance Criteria
4. Preserve existing content
5. Follow RALPH-RETRIEVAL.md specification

Fix the gaps now.
EOF
}

# Gate 2: Fix invariant violations (validate)
build_fix_violations_prompt() {
    local spec_file="$1"
    local violations="$2"

    cat <<EOF
You are fixing invariant violations in a RALPH specification.

SPEC FILE: $spec_file

INVARIANT VIOLATIONS:
$violations

REQUIREMENTS:
1. Read the current spec file
2. Fix each violation listed above
3. Ensure compliance with all 43 RALPH invariants
4. Do not break other parts of the spec
5. Follow RALPH-RETRIEVAL.md specification exactly

Fix the violations now.
EOF
}

# Gate 3: Generate PRP from spec
build_generate_prp_prompt() {
    local spec_file="$1"
    local prp_file="$2"
    local instruction="$3"

    cat <<EOF
You are generating a RALPH PRP (Plan for Rigorous Planning) from a validated specification.

INPUT SPEC: $spec_file
OUTPUT PRP: $prp_file

INSTRUCTION:
$instruction

REQUIREMENTS:
1. Read the validated spec file
2. Extract implementation steps following PRP format
3. Include: Phases, Milestones, Verification Points, Dependencies
4. Write PRP to: $prp_file
5. Follow RALPH-RETRIEVAL.md PRP generation rules

Generate the PRP now.
EOF
}

# Gate 4: Fix PRP structure issues (check)
build_fix_prp_prompt() {
    local prp_file="$1"
    local issues="$2"

    cat <<EOF
You are fixing structural issues in a RALPH PRP.

PRP FILE: $prp_file

STRUCTURAL ISSUES:
$issues

REQUIREMENTS:
1. Read the current PRP file
2. Fix each structural issue listed
3. Ensure proper PRP format compliance
4. Preserve implementation logic
5. Follow RALPH-RETRIEVAL.md PRP format

Fix the PRP structure now.
EOF
}

# Gate 5: Generate test files from PRP
build_generate_tests_prompt() {
    local prp_file="$1"
    local test_dir="$2"
    local instruction="$3"

    cat <<EOF
You are generating test files from a RALPH PRP.

INPUT PRP: $prp_file
OUTPUT TEST DIRECTORY: $test_dir

INSTRUCTION:
$instruction

REQUIREMENTS:
1. Read the PRP file
2. Generate test files for each implementation phase
3. Include unit tests, integration tests, E2E tests
4. Follow TDD principles - tests should fail initially
5. Use appropriate test framework for the project
6. Write tests to: $test_dir/

Generate test files now.
EOF
}

# Gate 6: Implement code to pass tests (TDD)
build_implement_tdd_prompt() {
    local test_results="$1"
    local target_files="$2"

    cat <<EOF
You are implementing code to pass failing tests in TDD mode.

FAILING TEST RESULTS:
$test_results

TARGET FILES TO IMPLEMENT: $target_files

REQUIREMENTS:
1. Read the test failures carefully
2. Implement minimal code to make tests pass
3. Do not modify tests unless they have bugs
4. Follow TDD red-green-refactor cycle
5. Write clean, simple implementation code

Implement the code now.
EOF
}

# Gate 6.5: Fix parallel checks (build/lint/a11y)
build_fix_parallel_checks_prompt() {
    local check_results="$1"
    local target_files="$2"

    cat <<EOF
You are fixing build, lint, and accessibility check failures.

CHECK FAILURES:
$check_results

TARGET FILES: $target_files

REQUIREMENTS:
1. Fix all build errors
2. Fix all linting violations
3. Fix all accessibility issues
4. Preserve functionality
5. Follow project coding standards

Fix all issues now.
EOF
}

# Gate 7: Fix smoke test failures (E2E)
build_fix_smoke_test_prompt() {
    local test_results="$1"
    local target_files="$2"

    cat <<EOF
You are fixing end-to-end smoke test failures.

SMOKE TEST FAILURES:
$test_results

TARGET FILES: $target_files

REQUIREMENTS:
1. Read the E2E test failure details
2. Fix the root cause of each failure
3. Ensure critical user paths work
4. Do not break existing passing tests
5. Test in the actual execution environment

Fix the failures now.
EOF
}

# Gate 8: Fix security/quality issues (AI review)
build_fix_security_prompt() {
    local review_results="$1"
    local target_files="$2"

    cat <<EOF
You are fixing security and code quality issues identified by AI review.

SECURITY/QUALITY ISSUES:
$review_results

TARGET FILES: $target_files

REQUIREMENTS:
1. Fix all security vulnerabilities (XSS, injection, auth, etc.)
2. Fix all code quality issues
3. Follow OWASP top 10 best practices
4. Ensure no new vulnerabilities introduced
5. Maintain functionality

Fix all security issues now.
EOF
}

# Gate: Implement Ralph steps from PRP
build_implement_prompt() {
    local prp_file="$1"
    local output_dir="$2"
    local instruction="$3"
    local feedback="$4"

    cat <<EOF
You are generating Ralph implementation steps from a validated PRP.

PRP FILE: $prp_file
OUTPUT DIRECTORY: $output_dir

INSTRUCTION:
$instruction

VALIDATION FEEDBACK:
$feedback

REQUIREMENTS:
1. Read the PRP file
2. Extract all phases and deliverables
3. Generate step-NN.sh files (one per deliverable)
4. Generate test-NN.sh files (map to success criteria)
5. Create gate-N.sh files (aggregate phases)
6. Write PRP-COVERAGE.md (traceability matrix)
7. Save all to: $output_dir/

RALPH STEP FORMAT:
- Header with PRP ID, phase, deliverable
- Invariants applied
- Thinking level and confidence
- Objective (verbatim from PRP)
- Acceptance criteria (verbatim from PRP)
- Implementation placeholder

Generate all Ralph steps now.
EOF
}

# Export all functions
export -f build_cursor_base_prompt
export -f build_create_spec_prompt
export -f build_fix_gaps_prompt
export -f build_fix_violations_prompt
export -f build_generate_prp_prompt
export -f build_fix_prp_prompt
export -f build_implement_prompt
export -f build_generate_tests_prompt
export -f build_implement_tdd_prompt
export -f build_fix_parallel_checks_prompt
export -f build_fix_smoke_test_prompt
export -f build_fix_security_prompt

#!/usr/bin/env python3
"""
Claude Code Orchestrator - RALPH Pipeline for Claude Code

This orchestrator integrates the design-ops validation system with Claude Code's
Task system for proper tracking and progress visibility.

Unlike the Cursor orchestrator, this version uses Claude Code agents directly
for generation and fixes (no external Cursor CLI dependency).

Usage:
    python claude-code-orchestrator.py run-gate <gate> <target> [--max-iterations 5]
    python claude-code-orchestrator.py run-pipeline <requirements-dir>
    python claude-code-orchestrator.py validate-spec <spec-file>

Gates:
    stress-test    - Check completeness (6 coverage areas)
    validate       - Check clarity (43 invariants)
    generate       - Generate PRP from spec
    check          - Validate PRP structure
    generate-tests - Generate test files from PRP
    implement-tdd  - Write code to pass tests
    parallel-checks- Run build/lint/a11y checks
    smoke-test     - Run E2E tests
    ai-review      - Security/quality review

Example:
    # Run single gate
    python claude-code-orchestrator.py run-gate validate specs/phase4-spec.md

    # Run full pipeline
    python claude-code-orchestrator.py run-pipeline requirements/phase4/

Philosophy:
    - design-ops.sh is the VALIDATOR (deterministic checks)
    - Claude Code is the GENERATOR (creates/fixes via agents)
    - This script is the ORCHESTRATOR (loops until pass)
"""

import subprocess
import sys
import os
import json
import argparse
from pathlib import Path
from typing import Tuple, Optional

# Colors for output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'

DESIGN_OPS_SCRIPT = Path.home() / ".claude/design-ops/enforcement/design-ops-v3-refactored.sh"

def run_design_ops_gate(gate: str, target: str) -> Tuple[bool, str]:
    """
    Run design-ops validation gate.

    Returns: (passed, instruction_file_path)
    """
    cmd = [str(DESIGN_OPS_SCRIPT), gate, target]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=os.getcwd()
        )

        # Check for SUCCESS marker in output
        if "✅" in result.stdout and "PASS" in result.stdout:
            return (True, "")

        # Look for instruction file
        target_path = Path(target)
        instruction_file = target_path.parent / f"{target_path.name}.{gate}-instruction.md"

        if instruction_file.exists():
            return (False, str(instruction_file))
        else:
            # No instruction file means validation-only command
            return (False, "")

    except Exception as e:
        print(f"{Colors.RED}Error running design-ops: {e}{Colors.NC}")
        return (False, "")

def read_instruction_file(instruction_file: str) -> str:
    """Read instruction file content."""
    with open(instruction_file, 'r') as f:
        return f.read()

def print_instruction_summary(instruction_content: str):
    """Print a summary of the instruction for Claude Code agent."""
    lines = instruction_content.split('\n')

    # Find the key sections
    print(f"\n{Colors.CYAN}📋 Instruction Summary:{Colors.NC}")
    in_section = False
    for line in lines:
        if line.startswith('## ') or line.startswith('### '):
            print(f"{Colors.BLUE}{line}{Colors.NC}")
            in_section = True
        elif in_section and line.strip().startswith('-'):
            print(f"  {line}")
        elif line.strip() == '':
            in_section = False

def run_gate_with_loop(gate: str, target: str, max_iterations: int = 5) -> bool:
    """
    Run a gate with retry loop until pass.

    Flow:
    1. Run design-ops gate (validation)
    2. If FAIL: read instruction
    3. Print instruction for Claude Code agent to follow
    4. Wait for user to execute instruction (via Claude Code agent)
    5. Loop back to step 1
    """
    print(f"\n{Colors.BLUE}{'='*60}")
    print(f"Running Gate: {gate}")
    print(f"Target: {target}")
    print(f"{'='*60}{Colors.NC}\n")

    for iteration in range(1, max_iterations + 1):
        print(f"{Colors.CYAN}Iteration {iteration}/{max_iterations}{Colors.NC}")

        # Run validation
        passed, instruction_file = run_design_ops_gate(gate, target)

        if passed:
            print(f"\n{Colors.GREEN}✅ Gate {gate} PASSED{Colors.NC}\n")
            return True

        # Failed - read instruction
        if not instruction_file:
            print(f"\n{Colors.RED}❌ Gate {gate} FAILED (no instruction file generated){Colors.NC}")
            print(f"{Colors.YELLOW}This usually means the target file has structural issues.{Colors.NC}")
            return False

        print(f"\n{Colors.YELLOW}⚠️  Gate {gate} FAILED{Colors.NC}")
        print(f"Reading instruction: {instruction_file}")

        instruction_content = read_instruction_file(instruction_file)
        print_instruction_summary(instruction_content)

        print(f"\n{Colors.CYAN}───────────────────────────────────────────────────────{Colors.NC}")
        print(f"{Colors.YELLOW}ACTION REQUIRED:{Colors.NC}")
        print(f"1. Review the instruction file: {instruction_file}")
        print(f"2. Use Claude Code agent to follow the instruction and fix issues")
        print(f"3. Press ENTER when done to re-validate")
        print(f"{Colors.CYAN}───────────────────────────────────────────────────────{Colors.NC}\n")

        input("Press ENTER to continue...")

    print(f"\n{Colors.RED}❌ Gate {gate} FAILED after {max_iterations} iterations{Colors.NC}\n")
    return False

def run_full_pipeline(requirements_dir: str) -> bool:
    """
    Run full RALPH pipeline: requirements → production code.

    Gates:
    0. create-spec
    1. stress-test
    2. validate
    3. generate (PRP)
    4. check (PRP)
    5. generate-tests
    6. implement-tdd
    7. parallel-checks
    8. smoke-test
    9. ai-review
    """
    print(f"\n{Colors.BLUE}{'='*60}")
    print("RALPH Full Pipeline")
    print(f"Requirements: {requirements_dir}")
    print(f"{'='*60}{Colors.NC}\n")

    # Define pipeline stages
    stages = [
        ("create-spec", requirements_dir, "spec.md"),
        ("stress-test", "spec.md", None),
        ("validate", "spec.md", None),
        ("generate", "spec.md", "spec-PRP.md"),
        ("check", "spec-PRP.md", None),
        ("generate-tests", "spec-PRP.md", "tests/"),
        ("implement-tdd", "tests/", "src/"),
        ("parallel-checks", "src/", None),
        ("smoke-test", "src/", None),
        ("ai-review", "src/", None),
    ]

    current_target = None

    for gate, input_target, output_target in stages:
        # Use output from previous stage or specified input
        target = current_target if current_target else input_target

        print(f"\n{Colors.BLUE}Stage: {gate}{Colors.NC}")
        success = run_gate_with_loop(gate, target, max_iterations=5)

        if not success:
            print(f"\n{Colors.RED}❌ Pipeline FAILED at gate: {gate}{Colors.NC}\n")
            return False

        # Update current target for next stage
        if output_target:
            current_target = output_target

    print(f"\n{Colors.GREEN}✅ Pipeline COMPLETE{Colors.NC}\n")
    return True

def main():
    parser = argparse.ArgumentParser(
        description="Claude Code Orchestrator for RALPH Pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    subparsers = parser.add_subparsers(dest='command', help='Command to run')

    # run-gate command
    run_gate_parser = subparsers.add_parser('run-gate', help='Run a single gate with retry loop')
    run_gate_parser.add_argument('gate', help='Gate name (stress-test, validate, etc.)')
    run_gate_parser.add_argument('target', help='Target file/directory')
    run_gate_parser.add_argument('--max-iterations', type=int, default=5, help='Max retry attempts')

    # run-pipeline command
    run_pipeline_parser = subparsers.add_parser('run-pipeline', help='Run full RALPH pipeline')
    run_pipeline_parser.add_argument('requirements_dir', help='Requirements directory')

    # validate-spec command
    validate_spec_parser = subparsers.add_parser('validate-spec', help='Validate spec structure')
    validate_spec_parser.add_argument('spec_file', help='Spec file to validate')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    # Check design-ops script exists
    if not DESIGN_OPS_SCRIPT.exists():
        print(f"{Colors.RED}Error: design-ops script not found at:{Colors.NC}")
        print(f"  {DESIGN_OPS_SCRIPT}")
        print(f"\n{Colors.YELLOW}Install design-ops system first:{Colors.NC}")
        print(f"  See .design-ops/README.md for setup instructions")
        sys.exit(1)

    # Route to command
    if args.command == 'run-gate':
        success = run_gate_with_loop(args.gate, args.target, args.max_iterations)
        sys.exit(0 if success else 1)

    elif args.command == 'run-pipeline':
        success = run_full_pipeline(args.requirements_dir)
        sys.exit(0 if success else 1)

    elif args.command == 'validate-spec':
        passed, instruction_file = run_design_ops_gate('validate', args.spec_file)
        if passed:
            print(f"{Colors.GREEN}✅ Spec is valid{Colors.NC}")
            sys.exit(0)
        else:
            print(f"{Colors.RED}❌ Spec has issues{Colors.NC}")
            if instruction_file:
                print(f"See: {instruction_file}")
            sys.exit(1)

if __name__ == '__main__':
    main()

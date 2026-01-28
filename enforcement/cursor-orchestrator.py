#!/usr/bin/env python3
"""
cursor-orchestrator.py - Task-based RALPH Design-Ops orchestrator

Uses Claude Code's Task system for proper tracking, progress visibility,
and parallel execution support.

Usage:
    ./cursor-orchestrator.py <gate> <target-file> [--max-iterations N] [--workspace PATH]
    ./cursor-orchestrator.py create-spec <req-dir> <spec-file> [--max-iterations N]
    ./cursor-orchestrator.py pipeline <req-dir> [--output-dir PATH]
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import os

# Colors
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'

# Gate definitions with metadata
GATES = {
    'create-spec': {
        'name': 'Create Spec',
        'description': 'Generate specification from requirements',
        'takes_two_args': True
    },
    'stress-test': {
        'name': 'Stress Test',
        'description': 'Check spec completeness',
        'takes_two_args': False
    },
    'validate': {
        'name': 'Validate',
        'description': 'Check spec against invariants',
        'takes_two_args': False
    },
    'generate': {
        'name': 'Generate PRP',
        'description': 'Generate PRP from validated spec',
        'takes_two_args': False
    },
    'check': {
        'name': 'Check PRP',
        'description': 'Validate PRP structure',
        'takes_two_args': False
    },
    'implement': {
        'name': 'Generate Ralph Steps',
        'description': 'Generate Ralph steps from PRP',
        'takes_two_args': True
    },
    'generate-tests': {
        'name': 'Generate Tests',
        'description': 'Generate test files from PRP',
        'takes_two_args': False
    },
    'implement-tdd': {
        'name': 'Implement TDD',
        'description': 'Implement code to pass tests',
        'takes_two_args': False
    },
    'parallel-checks': {
        'name': 'Parallel Checks',
        'description': 'Run build/lint/a11y checks',
        'takes_two_args': False
    },
    'smoke-test': {
        'name': 'Smoke Test',
        'description': 'Run E2E smoke tests',
        'takes_two_args': False
    },
    'ai-review': {
        'name': 'AI Review',
        'description': 'Security and quality review',
        'takes_two_args': False
    }
}

PIPELINE_GATES = [
    'create-spec', 'stress-test', 'validate', 'generate', 'check',
    'implement', 'generate-tests', 'implement-tdd', 'parallel-checks',
    'smoke-test', 'ai-review'
]


class TaskOrchestrator:
    """Orchestrator using Claude Code's Task system."""

    def __init__(self, workspace: Path, max_iterations: int = 5, cursor_model: str = "opus-4.5"):
        self.workspace = workspace
        self.max_iterations = max_iterations
        self.cursor_model = cursor_model
        self.script_dir = Path(__file__).parent
        self.bash_orchestrator = self.script_dir / "cursor-orchestrator.sh"

    def create_gate_task(self, gate: str, target: str) -> str:
        """Create a task for a gate via Claude Code's Task tool."""
        gate_info = GATES[gate]

        # Use subprocess to call claude with task creation
        # Since we're running under Claude Code, we can use echo to output task creation requests
        task_json = {
            "subject": f"{gate_info['name']}: {Path(target).name}",
            "description": f"{gate_info['description']}\n\nTarget: {target}\nMax iterations: {self.max_iterations}",
            "activeForm": f"Running {gate_info['name'].lower()}"
        }

        # Write task creation request to a marker file that Claude Code will process
        marker_file = self.workspace / ".design-ops" / "task-requests" / f"{gate}-task.json"
        marker_file.parent.mkdir(parents=True, exist_ok=True)
        marker_file.write_text(json.dumps(task_json, indent=2))

        return f"task-{gate}"

    def update_task_status(self, task_id: str, status: str):
        """Update task status."""
        marker_file = self.workspace / ".design-ops" / "task-status" / f"{task_id}-{status}.marker"
        marker_file.parent.mkdir(parents=True, exist_ok=True)
        marker_file.touch()

    def run_gate_with_bash_orchestrator(self, gate: str, args: List[str]) -> Tuple[bool, str]:
        """Run gate using the bash orchestrator."""
        cmd = [
            str(self.bash_orchestrator),
            gate,
            *args,
            str(self.max_iterations),
            str(self.workspace)
        ]

        try:
            result = subprocess.run(
                cmd,
                cwd=self.workspace,
                capture_output=True,
                text=True,
                timeout=600  # 10 minute timeout
            )
            return (result.returncode == 0, result.stdout + result.stderr)
        except subprocess.TimeoutExpired:
            return (False, "Gate execution timed out after 10 minutes")
        except Exception as e:
            return (False, f"Gate execution failed: {str(e)}")

    def run_gate(self, gate: str, args: List[str]) -> bool:
        """Run a single gate with task tracking."""
        target_desc = " ".join(args)

        print(f"\n{Colors.BLUE}╔════════════════════════════════════════════╗{Colors.NC}")
        print(f"{Colors.BLUE}║  Gate: {GATES[gate]['name']:<34} ║{Colors.NC}")
        print(f"{Colors.BLUE}╚════════════════════════════════════════════╝{Colors.NC}\n")

        # Create task
        task_id = self.create_gate_task(gate, target_desc)
        print(f"{Colors.CYAN}📋 Task created: {task_id}{Colors.NC}")

        # Mark as in progress
        self.update_task_status(task_id, "in_progress")
        print(f"{Colors.YELLOW}🔄 Running gate...{Colors.NC}\n")

        # Run the gate
        success, output = self.run_gate_with_bash_orchestrator(gate, args)

        # Print output
        print(output)

        # Update task status
        if success:
            self.update_task_status(task_id, "completed")
            print(f"\n{Colors.GREEN}✅ Gate PASSED{Colors.NC}")
            print(f"{Colors.GREEN}📋 Task completed: {task_id}{Colors.NC}\n")
            return True
        else:
            self.update_task_status(task_id, "failed")
            print(f"\n{Colors.RED}❌ Gate FAILED{Colors.NC}")
            print(f"{Colors.RED}📋 Task failed: {task_id}{Colors.NC}\n")
            return False

    def run_pipeline(self, req_dir: str, output_dir: str) -> bool:
        """Run full pipeline with task tracking for each gate."""
        print(f"{Colors.BLUE}╔════════════════════════════════════════════╗{Colors.NC}")
        print(f"{Colors.BLUE}║    RALPH Full Pipeline (Task-based)        ║{Colors.NC}")
        print(f"{Colors.BLUE}╚════════════════════════════════════════════╝{Colors.NC}\n")

        print(f"Requirements: {req_dir}")
        print(f"Output:       {output_dir}")
        print(f"Workspace:    {self.workspace}")
        print(f"Cursor Model: {self.cursor_model}\n")

        # Create pipeline overview task
        pipeline_task = self.create_gate_task("pipeline", f"{req_dir} → {output_dir}")
        self.update_task_status(pipeline_task, "in_progress")

        results = []
        spec_file = Path(output_dir) / "spec.md"
        prp_file = spec_file.with_name(f"{spec_file.stem}-PRP.md")
        ralph_dir = Path(output_dir) / "ralph-steps"

        # Gate 0: Create spec
        if self.run_gate('create-spec', [req_dir, str(spec_file)]):
            results.append(('create-spec', True))
        else:
            results.append(('create-spec', False))
            self.update_task_status(pipeline_task, "failed")
            return False

        # Gate 1: Stress test
        if self.run_gate('stress-test', [str(spec_file)]):
            results.append(('stress-test', True))
        else:
            results.append(('stress-test', False))
            self.update_task_status(pipeline_task, "failed")
            return False

        # Gate 2: Validate
        if self.run_gate('validate', [str(spec_file)]):
            results.append(('validate', True))
        else:
            results.append(('validate', False))
            self.update_task_status(pipeline_task, "failed")
            return False

        # Gate 3: Generate PRP
        if self.run_gate('generate', [str(spec_file)]):
            results.append(('generate', True))
        else:
            results.append(('generate', False))
            self.update_task_status(pipeline_task, "failed")
            return False

        # Gate 4: Check PRP
        if self.run_gate('check', [str(prp_file)]):
            results.append(('check', True))
        else:
            results.append(('check', False))
            self.update_task_status(pipeline_task, "failed")
            return False

        # Gate 5: Implement (generate Ralph steps)
        if self.run_gate('implement', [str(prp_file), str(ralph_dir)]):
            results.append(('implement', True))
        else:
            results.append(('implement', False))
            self.update_task_status(pipeline_task, "failed")
            return False

        # Print summary
        print(f"\n{Colors.GREEN}╔════════════════════════════════════════════╗{Colors.NC}")
        print(f"{Colors.GREEN}║      PIPELINE COMPLETED ✅                  ║{Colors.NC}")
        print(f"{Colors.GREEN}╚════════════════════════════════════════════╝{Colors.NC}\n")

        print(f"{Colors.CYAN}Results:{Colors.NC}")
        for gate, success in results:
            status = f"{Colors.GREEN}✅ PASSED{Colors.NC}" if success else f"{Colors.RED}❌ FAILED{Colors.NC}"
            print(f"  {GATES[gate]['name']:<20} {status}")

        self.update_task_status(pipeline_task, "completed")
        return True


def main():
    parser = argparse.ArgumentParser(
        description='RALPH Design-Ops Cursor Orchestrator (Task-based)',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument('command', help='Gate or pipeline command')
    parser.add_argument('args', nargs='*', help='Gate arguments')
    parser.add_argument('--max-iterations', type=int, default=5, help='Max validation loops')
    parser.add_argument('--workspace', type=Path, default=Path.cwd(), help='Project workspace')
    parser.add_argument('--cursor-model', default='opus-4.5', help='Cursor model to use')

    args = parser.parse_args()

    orchestrator = TaskOrchestrator(
        workspace=args.workspace,
        max_iterations=args.max_iterations,
        cursor_model=args.cursor_model
    )

    # Validate command
    if args.command not in GATES and args.command != 'pipeline':
        print(f"{Colors.RED}ERROR: Unknown command: {args.command}{Colors.NC}")
        sys.exit(1)

    # Run command
    if args.command == 'pipeline':
        if len(args.args) < 1:
            print(f"{Colors.RED}ERROR: pipeline requires requirements directory{Colors.NC}")
            sys.exit(1)
        req_dir = args.args[0]
        output_dir = args.args[1] if len(args.args) > 1 else '.'
        success = orchestrator.run_pipeline(req_dir, output_dir)
    else:
        gate_info = GATES[args.command]
        if gate_info['takes_two_args'] and len(args.args) < 2:
            print(f"{Colors.RED}ERROR: {args.command} requires 2 arguments{Colors.NC}")
            sys.exit(1)
        elif not gate_info['takes_two_args'] and len(args.args) < 1:
            print(f"{Colors.RED}ERROR: {args.command} requires 1 argument{Colors.NC}")
            sys.exit(1)

        success = orchestrator.run_gate(args.command, args.args)

    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

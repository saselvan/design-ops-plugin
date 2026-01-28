# Design-Ops Installation Guide

Quick setup guide for using the design-ops orchestrator on your personal laptop with Claude Code.

## Prerequisites

- **Python 3.7+** (for the orchestrator)
- **Claude Code** (for AI code generation)
- **Git** (to clone the repo)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/saselvan/design-ops-plugin ~/.claude/design-ops
cd ~/.claude/design-ops
```

This installs design-ops to `~/.claude/design-ops` (standard location).

### 2. Make Scripts Executable

```bash
chmod +x enforcement/*.sh enforcement/*.py
chmod +x enforcement/lib/*.sh
```

### 3. Verify Installation

```bash
# Check Python version
python3 --version  # Should be 3.7+

# Check orchestrator exists
ls -la enforcement/claude-code-orchestrator.py

# Check validation script exists
ls -la enforcement/design-ops-v3-refactored.sh
```

## Quick Test

```bash
# Navigate to any project
cd ~/projects/my-project

# Create a test spec
mkdir -p specs
cat > specs/test.md << 'EOF'
# Test Feature

## Goal
Build a login form.

## User Journey
1. User opens app
2. User enters credentials
3. User clicks login
EOF

# Run validation
python ~/.claude/design-ops/enforcement/claude-code-orchestrator.py validate-spec specs/test.md
```

You should see validation errors (the test spec is intentionally incomplete). This means it's working!

## Usage

### Basic Workflow

1. **Write a spec** in your project (`specs/feature.md`)
2. **Run the orchestrator:**
   ```bash
   python ~/.claude/design-ops/enforcement/claude-code-orchestrator.py run-gate validate specs/feature.md
   ```
3. **Orchestrator validates** and shows what needs fixing
4. **In Claude Code**, ask: "Fix the validation issues per the instruction file"
5. **Press ENTER** in the terminal to re-validate
6. **Repeat** until validation passes

### Commands

```bash
# Single gate with retry loop
python ~/.claude/design-ops/enforcement/claude-code-orchestrator.py run-gate <gate> <target>

# Full pipeline (all 10 gates)
python ~/.claude/design-ops/enforcement/claude-code-orchestrator.py run-pipeline <requirements-dir>

# Quick validation (no retry loop)
python ~/.claude/design-ops/enforcement/claude-code-orchestrator.py validate-spec <spec-file>

# Help
python ~/.claude/design-ops/enforcement/claude-code-orchestrator.py --help
```

### Available Gates

- `stress-test` - Check spec completeness
- `validate` - Check spec clarity (43 invariants)
- `generate` - Generate PRP from spec
- `check` - Validate PRP structure
- `generate-tests` - Generate test files
- `implement-tdd` - Write code to pass tests
- `parallel-checks` - Run build/lint/a11y
- `smoke-test` - Run E2E tests
- `ai-review` - Security/quality review

## Example Session

```bash
# In your project
cd ~/projects/my-app

# Run validation
python ~/.claude/design-ops/enforcement/claude-code-orchestrator.py run-gate validate specs/login.md

# Output:
⚠️  Gate validate FAILED
Reading instruction: specs/login.md.validate-instruction.md

📋 Instruction Summary:
## Failed Invariants
- Invariant #23: Missing error states
- Invariant #31: Vague success criteria

ACTION REQUIRED:
1. Review instruction file
2. Use Claude Code agent to fix issues
3. Press ENTER when done to re-validate

# In Claude Code:
> Fix the validation issues in specs/login.md per the instruction file

# After Claude fixes, press ENTER
[Press ENTER]

# Output:
✅ Gate validate PASSED
```

## Optional: Add Alias

Add to `~/.zshrc` or `~/.bashrc`:

```bash
alias design-ops="python ~/.claude/design-ops/enforcement/claude-code-orchestrator.py"
```

Then reload:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

Now you can run:
```bash
design-ops run-gate validate specs/feature.md
design-ops run-pipeline requirements/phase2/
```

## Documentation

Once installed, read the full documentation:

```bash
# Main README
cat ~/.claude/design-ops/README.md

# Orchestrator comparison (Cursor vs Claude Code)
cat ~/.claude/design-ops/enforcement/ORCHESTRATORS.md

# Quick start guide
cat ~/.claude/design-ops/enforcement/QUICKSTART.md

# Task system integration
cat ~/.claude/design-ops/enforcement/TASK-ORCHESTRATION-PATTERN.md
```

## Troubleshooting

### "python3: command not found"

Install Python:
- **macOS**: `brew install python3`
- **Ubuntu**: `sudo apt install python3`
- **Windows**: Download from python.org

### "design-ops script not found"

The orchestrator looks for the validation script at:
```bash
~/.claude/design-ops/enforcement/design-ops-v3-refactored.sh
```

If you cloned to a different location, update `DESIGN_OPS_SCRIPT` in `claude-code-orchestrator.py`.

### "Permission denied"

Make scripts executable:
```bash
chmod +x ~/.claude/design-ops/enforcement/*.sh
chmod +x ~/.claude/design-ops/enforcement/*.py
```

### "Gate keeps failing"

1. Read the instruction file carefully
2. Fix ONLY what's mentioned (don't over-fix)
3. Use Claude Code to make changes
4. Re-validate

## Next Steps

1. **Read ORCHESTRATORS.md** - Full usage guide
2. **Try on a real project** - Start with one spec file
3. **Run full pipeline** - When ready for production workflow

## Support

- **Issues**: https://github.com/saselvan/design-ops-plugin/issues
- **Documentation**: https://github.com/saselvan/design-ops-plugin

## Real-World Example

The PathFinder AI demo was built using this system:
- Repository: https://github.com/saselvan/hls-pathology-dual-corpus
- All 4 phases validated through RALPH pipeline
- See `.design-ops/README.md` in that repo for case study

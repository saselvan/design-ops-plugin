# RALPH Runner - Spec to Code Pipeline

**A tool-agnostic state machine for implementing features from spec to working code.**

- ✅ Universal 8-state pipeline (baked in, never changes)
- ✅ Auto-detects test framework (pytest, npm, go, cargo, maven)
- ✅ Works with Claude Code, Cursor, Windsurf (and more)
- ✅ Flexible phases (run only what you need)
- ✅ Resume from failure (GUTTER handling)
- ✅ Minimal config (just spec file path)

---

## Quick Start

### 1. Copy runner to your project
```bash
cp ~/.claude/design-ops/ralph/run-ralph.sh ./
chmod +x run-ralph.sh
```

### 2. Initialize
```bash
./run-ralph.sh --init --spec specs/my-feature.md
```

This creates `.ralph/config` with your spec file path.

### 3. Run the pipeline
```bash
./run-ralph.sh --state-machine
```

That's it. The runner will:
- ✅ Validate your spec (stress-test, validate)
- ✅ Generate PRP (Product Requirements Prompt)
- ✅ Generate tests from PRP (TDD red phase)
- ✅ Auto-detect LLM tool and send prompts
- ✅ Wait for you to confirm gate results
- ✅ Implement code to pass tests
- ✅ Create RALPH_TASK.md for future automation

---

## What Happens

```
STRESS_TEST → VALIDATE → GENERATE_PRP → CHECK_PRP
    ↓            ↓             ↓            ↓
 (spec)       (spec)        (spec→PRP)    (PRP)

GENERATE_TESTS → CHECK_TESTS → IMPLEMENT → COMPLETE
    ↓               ↓             ↓          ↓
 (PRP→tests)    (run tests)   (make pass)  (done)
```

For each state:
1. **Runner outputs a prompt** to Claude/Cursor/Windsurf
2. **You run the gate command** (or tool does it)
3. **You confirm result** (pass/fail/skip)
4. **Runner transitions** to next state

---

## Usage Examples

### Run full pipeline
```bash
./run-ralph.sh --state-machine --spec specs/hypothesis-mode.md
```

### Only validate spec (phases 1-2)
```bash
./run-ralph.sh --state-machine --spec specs/my-feature.md --to-phase 2
```

### Only generate and test (skip spec validation)
```bash
./run-ralph.sh --state-machine --spec specs/my-feature.md --from-phase 3
```

### Only implementation (skip to tests)
```bash
./run-ralph.sh --state-machine --spec specs/my-feature.md --phase 7
```

### Run only hypothesis tests (filter by name)
```bash
./run-ralph.sh --state-machine --spec specs/hypothesis-mode.md \
  --test-path tests/unit/hypothesis/ \
  --test-filter hypothesis
```

### Custom test command
```bash
./run-ralph.sh --state-machine --spec specs/my-feature.md \
  --test-command "npm test -- --coverage"
```

### Resume after GUTTER (max retries hit)
```bash
./run-ralph.sh --state-machine --resume
```

### Dry run (preview without executing)
```bash
./run-ralph.sh --state-machine --spec specs/my-feature.md --dry-run
```

---

## Flags Reference

| Flag | Purpose | Example |
|------|---------|---------|
| `--state-machine` | Run full state machine | `./run-ralph.sh --state-machine` |
| `--spec FILE` | Specify spec file | `--spec specs/my-feature.md` |
| `--test-path PATH` | Test directory (auto-detected) | `--test-path tests/unit/` |
| `--test-filter FILTER` | Run only matching tests | `--test-filter hypothesis` |
| `--test-command CMD` | Custom test command | `--test-command "pytest -v"` |
| `--phase N` | Run only phase N (1-7) | `--phase 5` |
| `--from-phase N` | Start from phase N | `--from-phase 3` |
| `--to-phase N` | Stop at phase N | `--to-phase 4` |
| `--only-tests` | Skip to tests (phases 5-7) | `./run-ralph.sh --only-tests` |
| `--init` | Initialize project config | `./run-ralph.sh --init` |
| `--resume` | Continue from last state | `./run-ralph.sh --resume` |
| `--dry-run` | Preview without executing | `./run-ralph.sh --dry-run` |
| `--verbose` | Verbose output | `./run-ralph.sh --verbose` |
| `-h, --help` | Show help | `./run-ralph.sh --help` |

---

## Configuration

Runner creates `.ralph/config` with defaults:

```
spec_file=specs/my-feature.md
test_path=tests/
test_filter=
```

**Flags override config:**
```bash
# Uses other-feature.md, ignores config
./run-ralph.sh --state-machine --spec specs/other-feature.md
```

---

## Universal 8-State Pipeline

The pipeline **never changes**. It's the same for all projects:

| State | Purpose | Input | Output |
|-------|---------|-------|--------|
| STRESS_TEST | Check completeness | Spec | stress-test-instruction.md |
| VALIDATE | Check clarity | Spec | validate-instruction.md |
| GENERATE_PRP | Extract requirements | Spec | PRP (prp/feature-prp.md) |
| CHECK_PRP | Validate PRP structure | PRP | Validation result |
| GENERATE_TESTS | Extract test cases | PRP | Test files (tests/) |
| CHECK_TESTS | Validate tests match PRP | Tests | Test validation result |
| IMPLEMENT | Write code to pass tests | Tests | Implementation code |
| COMPLETE | Done | - | RALPH_TASK.md |

---

## How It Works

### For Each State:

1. **Runner generates a prompt** with:
   - State name and pass condition
   - Gate command to run
   - Instructions for fixing issues

2. **Prompt goes to your LLM tool:**
   - Claude Code: `claude [prompt]`
   - Cursor: Opens in editor (you run gate command)
   - Windsurf: Sends to Windsurf
   - Manual: You paste into your LLM

3. **You execute the gate** (or tool does it)

4. **You confirm result:**
   - `pass` - Gate passed, transition to next state
   - `fail` - Gate failed, retry (up to max_retries)
   - `skip` - Skip to next state

5. **Runner transitions** and updates `.ralph/state.md`

---

## Large Projects

For huge projects, use **phase filtering**:

```bash
# Only hypothesis mode tests
./run-ralph.sh --state-machine \
  --spec specs/hypothesis-testing-mode-spec.md \
  --test-path tests/unit/hypothesis/ \
  --test-filter hypothesis

# Only implementation (tests already exist)
./run-ralph.sh --state-machine \
  --spec specs/my-feature.md \
  --phase 7

# Validate only
./run-ralph.sh --state-machine \
  --spec specs/my-feature.md \
  --to-phase 2
```

---

## State Management

Runner maintains state in `.ralph/state.md`:

```markdown
# RALPH State

current_state: GENERATE_TESTS
retry_count: 0
max_retries: 5
started_at: 2026-01-27T12:00:00Z
history:
  - 2026-01-27T12:00:00Z | INIT -> STRESS_TEST
  - 2026-01-27T12:00:05Z | STRESS_TEST -> VALIDATE
  - 2026-01-27T12:00:10Z | VALIDATE -> GENERATE_PRP
  ...
```

- **current_state**: Where you are now
- **retry_count**: Retries for current state
- **max_retries**: Max attempts before GUTTER (default: 5)
- **history**: All transitions (audit trail)

---

## GUTTER (Max Retries Exceeded)

If gate fails after `max_retries` attempts:

```
🚨 GUTTER: Max retries exceeded for CHECK_TESTS
Fix manually and run: ./run-ralph.sh --resume
```

**Recover:**
1. Check `.ralph/gutter-CHECK_TESTS.log` for error details
2. Fix the issue manually
3. Run: `./run-ralph.sh --state-machine --resume`

---

## Test Framework Auto-Detection

Runner auto-detects your test framework:

| Framework | Detection | Command |
|-----------|-----------|---------|
| pytest | `pytest.ini`, `setup.py`, `pyproject.toml` | `pytest tests/ -v` |
| npm | `package.json` | `npm test` |
| go | `go.mod` | `go test ./...` |
| cargo | `Cargo.toml` | `cargo test` |
| maven | `pom.xml`, `build.gradle` | `mvn test` |

**Override with `--test-command`:**
```bash
./run-ralph.sh --state-machine \
  --test-command "pytest tests/unit/ -v --tb=short"
```

---

## Tool Support

| Tool | Support | Auto-Detect |
|------|---------|-------------|
| Claude Code | ✅ Full | `claude` command |
| Cursor | ✅ Full | `cursor` command |
| Windsurf | ✅ Full | `windsurf` command |
| Manual | ✅ Full | Output prompt, you paste |

**See RALPH_PORTABILITY.md for details.**

---

## Example: Hypothesis Testing Mode

```bash
# Initialize
./run-ralph.sh --init --spec specs/hypothesis-testing-mode-spec.md

# Run full pipeline (all phases)
./run-ralph.sh --state-machine

# Or: only hypothesis tests
./run-ralph.sh --state-machine --test-filter hypothesis

# Or: only implementation
./run-ralph.sh --state-machine --from-phase 5 --spec specs/hypothesis-testing-mode-spec.md
```

---

## What Gets Created

After successful pipeline:

```
.ralph/
├── config                    # Your config (spec path, test settings)
├── state.md                  # Current state + history
├── gutter-*.log             # Error logs (if GUTTER hit)
└── progress.md              # Pipeline progress

specs/
└── my-feature.md            # Your spec

prp/
└── my-feature-prp.md        # Generated PRP

tests/
└── unit/                     # Generated tests

src/
└── modules/                  # Your implementation

RALPH_TASK.md                # Created for future automation
```

---

## Next: Future Automation

After first successful pipeline, you can use `ralph-loop.sh` for full automation:

```bash
~/.claude/design-ops/ralph/init-state-machine.sh . specs/my-feature.md
./ralph-loop.sh --state-machine -n 30 --max-gate-retries 5
```

But `run-ralph.sh` is fine for interactive use.

---

## Troubleshooting

### "Error: --spec required or missing .ralph/config"
Run: `./run-ralph.sh --init --spec specs/my-feature.md`

### "Max retries exceeded for STRESS_TEST"
1. Review errors: `cat .ralph/gutter-STRESS_TEST.log`
2. Fix spec: `specs/my-feature.md`
3. Resume: `./run-ralph.sh --state-machine --resume`

### Test framework not detected
Use `--test-command`:
```bash
./run-ralph.sh --state-machine --test-command "custom-test-runner"
```

### PRP file not found
Check: Is `prp/` directory created? Did GENERATE_PRP succeed?

---

## Key Points

1. **Universal pipeline** - Same 8 states for all projects
2. **Minimal config** - Just needs spec file path
3. **Auto-detection** - Test framework, PRP location, tool
4. **Flexible phases** - Run only what you need
5. **Tool-agnostic** - Works with Claude Code, Cursor, Windsurf
6. **Resumable** - Hit GUTTER? Fix and resume
7. **Auditable** - Full state history in `.ralph/state.md`

---

## Summary

```bash
# 1. Copy runner
cp ~/.claude/design-ops/ralph/run-ralph.sh ./

# 2. Initialize
./run-ralph.sh --init --spec specs/my-feature.md

# 3. Run
./run-ralph.sh --state-machine

# Done!
```

The runner handles everything else.

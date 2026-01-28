# RALPH Runner - Portability Guide

**Which parts work where?**

---

## Universal (Works Everywhere)

✅ **These work identically on all platforms and tools:**

| Component | Support | Notes |
|-----------|---------|-------|
| Core state machine | ✅ 100% | Same 8 states everywhere |
| Config (.ralph/config) | ✅ 100% | Simple key=value format |
| State file (.ralph/state.md) | ✅ 100% | Plain markdown, universal |
| Design-ops commands | ✅ 100% | stress-test, validate, generate, check |
| Phase filtering | ✅ 100% | --phase, --from-phase, --to-phase |
| Test framework detection | ✅ 100% | pytest, npm, go, cargo, maven |
| DRY run | ✅ 100% | Preview mode works everywhere |
| Resume (--resume) | ✅ 100% | State-based recovery |

---

## Tool-Specific Features

### Claude Code (Best Experience)

✅ **Full support**

| Feature | Support | Notes |
|---------|---------|-------|
| Prompt piping | ✅ | `echo "$prompt" \| claude` |
| Output capture | ✅ | Reads gate results directly |
| Auto-invocation | ✅ | Runs Claude automatically |
| Full integration | ✅ | Seamless state management |
| Performance | ✅ Fast | Direct API call |

**Best for:** Fully automated pipelines. Runner handles everything.

**Usage:**
```bash
./run-ralph.sh --state-machine --spec specs/my-feature.md
# Runner auto-invokes claude, captures output, continues
```

---

### Cursor

✅ **Full support**

| Feature | Support | Notes |
|---------|---------|-------|
| Prompt detection | ✅ | Reads from Cursor CLI |
| IDE integration | ✅ | Opens in Cursor editor |
| Manual flow | ✅ | You run gate, confirm result |
| Output parsing | ⚠️ Manual | You report pass/fail |
| Performance | ⚠️ Slower | Manual steps needed |

**Best for:** Interactive development. You control what happens.

**Usage:**
```bash
./run-ralph.sh --state-machine --spec specs/my-feature.md
# Runner outputs prompt
# You run gate command in Cursor
# You confirm result (pass/fail)
# Runner continues
```

**Workflow:**
1. Runner outputs prompt with gate command
2. You copy gate command into Cursor terminal
3. You run the gate command
4. You review output
5. You type `pass` or `fail` to runner
6. Runner continues to next state

---

### Windsurf

✅ **Full support**

| Feature | Support | Notes |
|---------|---------|-------|
| Prompt piping | ✅ | `echo "$prompt" \| windsurf` |
| IDE integration | ✅ | Opens in Windsurf editor |
| Auto-invocation | ⚠️ Partial | May need manual steps |
| Output capture | ⚠️ Partial | Depends on Windsurf version |
| Performance | ⚠️ Varies | IDE launch time |

**Best for:** IDE-based development with Windsurf.

**Usage:**
```bash
./run-ralph.sh --state-machine --spec specs/my-feature.md
# Runner sends prompt to Windsurf
# You execute gate in Windsurf
# You confirm result
```

---

### Manual Mode (No LLM Tool)

✅ **Full support** (just slower)

| Feature | Support | Notes |
|---------|---------|-------|
| Prompt output | ✅ | Prints to terminal |
| Manual execution | ✅ | You copy/paste gate command |
| Manual confirmation | ✅ | You type pass/fail |
| Full pipeline | ✅ | Works but slower |
| Performance | ⚠️ Slowest | Copy/paste workflow |

**Best for:** Testing or when no LLM tool installed.

**Usage:**
```bash
./run-ralph.sh --state-machine --spec specs/my-feature.md
# Runner outputs prompt
# You paste gate command into your terminal manually
# You confirm result
```

---

## Specific Tool Capabilities

### ✅ Features That Work Everywhere

```bash
./run-ralph.sh --state-machine              # Full pipeline
./run-ralph.sh --init --spec specs/foo.md   # Initialize
./run-ralph.sh --resume                     # Resume from GUTTER
./run-ralph.sh --phase 3                    # Single phase
./run-ralph.sh --from-phase 5               # Skip to phase 5
./run-ralph.sh --to-phase 4                 # Stop at phase 4
./run-ralph.sh --only-tests                 # Phases 5-7 only
./run-ralph.sh --test-filter hypothesis     # Filter tests
./run-ralph.sh --dry-run                    # Preview
```

### ⚠️ Tool-Specific Variations

| Feature | Claude | Cursor | Windsurf | Manual |
|---------|--------|--------|----------|--------|
| Auto-detection | ✅ Instant | ✅ Instant | ✅ Instant | ✅ Asks |
| Auto-invoke | ✅ Yes | ⚠️ Opens IDE | ⚠️ Maybe | ❌ No |
| Output capture | ✅ Auto | ⚠️ Manual | ⚠️ Partial | ❌ Manual |
| Speed | ✅ Fastest | ⚠️ Slower | ⚠️ Slower | ❌ Slowest |
| Reliability | ✅ High | ✅ High | ⚠️ Medium | ✅ High |

---

## Cross-Platform Support

✅ **Runs on:**
- macOS
- Linux
- WSL2 (Windows with bash)
- Any system with bash + git + test framework

⚠️ **NOT supported:**
- Windows CMD/PowerShell (need bash)
- Older bash versions (<4.0)

---

## Browser/IDE Support

### Claude Code CLI
✅ **Fully supported**
- Direct invocation
- Auto-detection
- Output capture
- No IDE needed

### Cursor Editor
✅ **Fully supported**
- IDE integration
- Manual or semi-automatic
- User controls gates
- Good for interactive work

### Windsurf Editor
✅ **Fully supported**
- IDE integration
- Partial automation
- Good for development
- May need manual steps

### VS Code + Extensions
⚠️ **Partial support**
- Works if Claude extension installed
- Use manual mode if not
- Not officially tested

### JetBrains IDEs (IntelliJ, PyCharm, etc.)
⚠️ **Partial support**
- Use manual mode (copy/paste)
- No direct integration
- Works but slower

### GitHub Codespaces
✅ **Fully supported**
- Full bash environment
- Test frameworks available
- Can use Claude API

### Cloud IDEs
✅ **Generally supported**
- Any IDE with bash + git
- Manual mode always works
- Test runner must be available

---

## Use Case Recommendations

### "I want fastest automation"
```bash
# Use Claude Code + Claude API key
claude login
./run-ralph.sh --state-machine --spec specs/my-feature.md
# Fully automated, runner does everything
```

### "I want interactive development in IDE"
```bash
# Use Cursor or Windsurf
./run-ralph.sh --state-machine --spec specs/my-feature.md
# Runner outputs prompts
# You execute gates in IDE
# You confirm results
```

### "I don't have any LLM tool installed yet"
```bash
# Manual mode (copy/paste)
./run-ralph.sh --state-machine --spec specs/my-feature.md
# Runner outputs prompt
# You copy gate command to terminal
# You copy output back to confirm pass/fail
# Slower but fully functional
```

### "Large project, only want phase 5"
```bash
# Works on any tool
./run-ralph.sh --state-machine \
  --spec specs/my-feature.md \
  --phase 7 \
  --test-path tests/unit/hypothesis/
# Only implementation phase, works everywhere
```

### "Project needs specific test command"
```bash
# Works on any tool
./run-ralph.sh --state-machine \
  --spec specs/my-feature.md \
  --test-command "pytest tests/unit/ -v --cov"
# Custom command, tool-agnostic
```

---

## Switching Tools

All state is in `.ralph/`:

```bash
# Start with Cursor
./run-ralph.sh --state-machine --spec specs/my-feature.md
# [Work in Cursor, hit GUTTER]
# .ralph/state.md saved

# Switch to Claude Code
./run-ralph.sh --state-machine --resume
# Resumes from exact same state, with Claude Code
# No data loss, no re-initialization needed
```

**All tools share same state machine and files.** Switch freely.

---

## Performance Notes

| Tool | Speed | Notes |
|------|-------|-------|
| Claude Code | ✅ Fastest | Direct API, instant |
| Cursor | ⚠️ Slower | IDE overhead, manual steps |
| Windsurf | ⚠️ Slower | IDE overhead, launch time |
| Manual | ❌ Slowest | Copy/paste workflow |

**Typical times per gate:**
- Claude Code: 5-30 seconds (API call)
- Cursor: 30-120 seconds (IDE interaction)
- Windsurf: 30-120 seconds (IDE launch)
- Manual: 2-5 minutes (copy/paste)

---

## What NOT to Do

❌ **Don't:**
- Edit `.ralph/state.md` manually (runner handles it)
- Use Windows CMD/PowerShell (use WSL bash)
- Assume IDE-specific features work everywhere (they don't)
- Run multiple instances (state conflicts)
- Move project after starting (paths get cached)

✅ **Do:**
- Use `--resume` to recover from GUTTER
- Use phase filtering for large projects
- Commit after each state transition
- Check `.ralph/state.md` for current status
- Run from project root directory

---

## Compatibility Matrix

```
┌─────────────────────┬────────────┬────────────┬──────────────┐
│ Feature             │ Claude     │ Cursor     │ Windsurf     │
├─────────────────────┼────────────┼────────────┼──────────────┤
│ State machine       │ ✅ Full    │ ✅ Full    │ ✅ Full      │
│ Auto-detection      │ ✅ Yes     │ ✅ Yes     │ ✅ Yes       │
│ Auto-invocation     │ ✅ Yes     │ ⚠️ Partial │ ⚠️ Partial   │
│ Prompt output       │ ✅ CLI     │ ✅ Editor  │ ✅ Editor    │
│ Gate execution      │ ✅ Auto    │ ⚠️ Manual  │ ⚠️ Manual    │
│ Output parsing      │ ✅ Auto    │ ⚠️ Manual  │ ⚠️ Manual    │
│ Phase filtering     │ ✅ Yes     │ ✅ Yes     │ ✅ Yes       │
│ Resume (GUTTER)     │ ✅ Yes     │ ✅ Yes     │ ✅ Yes       │
│ Test framework      │ ✅ Auto    │ ✅ Auto    │ ✅ Auto      │
│ Config sharing      │ ✅ Yes     │ ✅ Yes     │ ✅ Yes       │
│ Cross-platform      │ ✅ Yes     │ ✅ Yes     │ ✅ Yes       │
│ Speed               │ ✅ Fast    │ ⚠️ Medium  │ ⚠️ Medium    │
│ Reliability         │ ✅ High    │ ✅ High    │ ⚠️ Medium    │
└─────────────────────┴────────────┴────────────┴──────────────┘
```

✅ = Fully supported
⚠️ = Supported but with manual steps
❌ = Not supported

---

## Summary

**The runner is portable because:**
1. Core state machine is identical everywhere
2. Config is plain text (no tool-specific syntax)
3. State is markdown (universal format)
4. Design-ops commands work on all platforms
5. Test framework detection is generic

**Tool differences are in HOW you provide the gate result:**
- Claude Code: Automatic
- Cursor: Manual confirmation
- Windsurf: Semi-automatic
- Manual: Copy/paste

**The same `.ralph/` state works with all tools.** You can switch tools mid-pipeline.

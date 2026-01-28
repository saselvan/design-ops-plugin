# Prompt for Cursor: Hypothesis Testing Mode - Complete Implementation

## Context

You're implementing **Hypothesis Testing Mode** for PathFinder AI using the design-ops v3.4 pipeline + RALPH state machine methodology.

**Working Document:** See below for success criteria and structure
**Design-Ops Location:** `~/.claude/design-ops/enforcement/design-ops-v3-refactored.sh`
**Project:** `/Users/samuel.selvan/projects/hls-pathology-dual-corpus`

## Your Task: Spec → Code (End-to-End)

Run this step-by-step:

### Step 1: Verify Spec Exists
```bash
ls -la /Users/samuel.selvan/projects/hls-pathology-dual-corpus/specs/hypothesis-testing-mode-spec.md
```
If missing, ask user for the spec content.

### Step 2: Stress Test (Completeness)
```bash
~/.claude/design-ops/enforcement/design-ops-v3-refactored.sh stress-test \
  /Users/samuel.selvan/projects/hls-pathology-dual-corpus/specs/hypothesis-testing-mode-spec.md
```

**Review output:**
- Read `hypothesis-testing-mode.stress-test-instruction.md`
- Identify gaps: missing error cases? Unclear success criteria? Scope boundaries?
- Edit spec to fix identified gaps
- Commit: `git add specs/ && git commit -m "spec: fix [gap]"`
- Re-run until pass condition met

### Step 3: Validate (Clarity)
```bash
~/.claude/design-ops/enforcement/design-ops-v3-refactored.sh validate \
  /Users/samuel.selvan/projects/hls-pathology-dual-corpus/specs/hypothesis-testing-mode-spec.md
```

**Review output:**
- Read `hypothesis-testing-mode.validate-instruction.md`
- Check for ambiguous words, vague requirements, missing operational definitions
- Edit spec to fix ambiguities
- Commit: `git add specs/ && git commit -m "spec: clarify [issue]"`
- Re-run until pass condition met

### Step 4: Generate PRP (Extract Requirements)
```bash
~/.claude/design-ops/enforcement/design-ops-v3-refactored.sh generate \
  /Users/samuel.selvan/projects/hls-pathology-dual-corpus/specs/hypothesis-testing-mode-spec.md
```

**Output:** Creates `prp/hypothesis-testing-mode-prp.md`

### Step 5: Check PRP (Validate Structure)
```bash
~/.claude/design-ops/enforcement/design-ops-v3-refactored.sh check \
  /Users/samuel.selvan/projects/hls-pathology-dual-corpus/prp/hypothesis-testing-mode-prp.md
```

**Fix if needed**, then commit: `git add prp/ && git commit -m "prp: hypothesis testing mode"`

### Step 6: Generate Tests (Read implement-instruction.md)
You should now have: `/Users/samuel.selvan/projects/hls-pathology-dual-corpus/hypothesis-testing-mode-prp.implement-instruction.md`

**Read it.** It tells you:
- What to extract from PRP
- Which success criteria become test assertions
- Verbatim mapping rules

**Create test files** based on PRP success criteria:

```
tests/unit/hypothesis/
├── test_detector.py      (HypothesisDetector - query pattern detection)
├── test_extractor.py     (HypothesisExtractor - extract hypotheses from query)
├── test_retriever.py     (DifferentialRetriever - dual-corpus evidence lookup)
└── test_synthesizer.py   (ReasoningSynthesizer - evidence synthesis)
```

**Each test file:**
- Tests one class/module
- Tests match PRP success criteria EXACTLY
- Initially fail (red phase of TDD)
- Use pytest framework

**Example structure:**
```python
# tests/unit/hypothesis/test_detector.py

def test_detects_hypothesis_question():
    """Detects 'Is this A or B?' patterns"""
    detector = HypothesisDetector()
    result = detector.detect("Is this lung adenocarcinoma or squamous cell?")
    assert result["is_hypothesis"] == True
    assert result["confidence"] > 0.9

def test_rejects_non_hypothesis_question():
    """Rejects single-diagnosis queries"""
    detector = HypothesisDetector()
    result = detector.detect("What is this mass?")
    assert result["is_hypothesis"] == False
```

**Commit:** `git add tests/unit/hypothesis/ && git commit -m "tests: hypothesis mode unit tests (red phase)"`

### Step 7: Implement Code (Make Tests Pass)

**For each module, write implementation:**

```python
# src/hypothesis/detector.py
import re
from typing import Dict

class HypothesisDetector:
    """Detect hypothesis testing queries"""

    def detect(self, query: str) -> Dict:
        """
        Detect if query is a hypothesis question

        Returns:
            {is_hypothesis: bool, confidence: float}
        """
        # Look for "Is this X or Y?" patterns
        pattern = r'is\s+this\s+\w+\s+or\s+\w+'
        match = re.search(pattern, query, re.IGNORECASE)

        if match:
            return {
                "is_hypothesis": True,
                "confidence": 0.95
            }
        return {
            "is_hypothesis": False,
            "confidence": 0.0
        }
```

**Run tests after each module:**
```bash
cd /Users/samuel.selvan/projects/hls-pathology-dual-corpus
pytest tests/unit/hypothesis/ -v
```

**Commit after each passing test:**
```bash
git add src/hypothesis/ && git commit -m "impl: hypothesis detector (tests passing)"
```

### Step 8: Verify All Tests Pass
```bash
cd /Users/samuel.selvan/projects/hls-pathology-dual-corpus
pytest tests/unit/hypothesis/ -v --tb=short
```

**Expected:** All tests pass ✅

### Step 9: Create RALPH_TASK.md for Automation

Create `/Users/samuel.selvan/projects/hls-pathology-dual-corpus/RALPH_TASK.md`:

```markdown
---
mode: state_machine
spec_file: specs/hypothesis-testing-mode-spec.md
prp_file: prp/hypothesis-testing-mode-prp.md
---

## States

### STRESS_TEST
order: 1
command: |
  ~/.claude/design-ops/enforcement/design-ops-v3-refactored.sh stress-test {{spec_file}}
pass_condition: "Instruction generated"
on_fail: Review stress-test-instruction.md, fix gaps in spec
on_pass: Transition to VALIDATE

### VALIDATE
order: 2
command: |
  ~/.claude/design-ops/enforcement/design-ops-v3-refactored.sh validate {{spec_file}}
pass_condition: "Structure validation passed"
on_fail: Review validate-instruction.md, fix ambiguities in spec
on_pass: Transition to GENERATE_PRP

### GENERATE_PRP
order: 3
command: |
  ~/.claude/design-ops/enforcement/design-ops-v3-refactored.sh generate {{spec_file}}
pass_condition: "generate-instruction.md"
on_fail: Ensure spec passes validation
on_pass: Transition to CHECK_PRP

### CHECK_PRP
order: 4
command: |
  ~/.claude/design-ops/enforcement/design-ops-v3-refactored.sh check {{prp_file}}
pass_condition: "PRP validation passed"
on_fail: Fix PRP structure
on_pass: Transition to GENERATE_TESTS

### GENERATE_TESTS
order: 5
command: |
  pytest tests/unit/hypothesis/ --collect-only -q 2>&1
pass_condition: "selected"
on_fail: Create test files for all hypothesis modules
on_pass: Transition to CHECK_TESTS

### CHECK_TESTS
order: 6
command: |
  pytest tests/unit/hypothesis/ -v --tb=line 2>&1
pass_condition: "passed"
on_fail: Implement code to pass failing tests
on_pass: Transition to COMPLETE

### COMPLETE
order: 7
terminal: true

## GUTTER Configuration

on_gutter: |
  echo "🚨 GUTTER: Max retries exhausted for state: {{current_state}}"
  echo "Review .ralph/gutter-{{current_state}}.log for details"
  echo "Fix manually, then: ./ralph-loop.sh --state-machine --resume -y"
  exit 1
```

### Step 10: Test RALPH Automation (Optional)

If you want to use ralph-loop.sh for future gates:
```bash
cd /Users/samuel.selvan/projects/hls-pathology-dual-corpus
~/.claude/design-ops/ralph/init-state-machine.sh . specs/hypothesis-testing-mode-spec.md
./ralph-loop.sh --state-machine -n 30 --max-gate-retries 5 --dry-run
```

---

## Summary of Success

When complete:
- ✅ Spec passes stress-test gate
- ✅ Spec passes validate gate
- ✅ PRP generated and validated
- ✅ Test files created from PRP success criteria
- ✅ All tests pass (green phase)
- ✅ Implementation complete
- ✅ RALPH_TASK.md ready for future automation

---

## Key Rules

1. **Read instruction files** - They explain what to fix
2. **Verbatim mapping** - Tests extracted from PRP success criteria, not invented
3. **TDD discipline** - Tests first, then code
4. **Commit after each gate** - Track progress in git history
5. **No diagnoses** - Synthesis only presents evidence, doesn't recommend diagnosis

# Retrospective: {project-name}

id: RETRO-{NNN}
project: {project-name}
date: {YYYY-MM-DD}
implementation_time: {duration}
specs_used: S-{NNN}, S-{NNN}, ...
mode_used: full | standard | minimal

---

## Purpose

Capture what the Design Ops system got right and wrong. Feed learnings back into the system so it improves over time.

> "We don't learn from experience. We learn from reflecting on experience." — John Dewey

---

## Quick Stats

| Metric | Value |
|--------|-------|
| Specs written | {N} |
| Specs that needed revision during implementation | {N} |
| Tests written | {N} |
| Tests that needed revision during implementation | {N} |
| Bugs found post-implementation | {N} |
| Bugs traceable to spec gaps | {N} |
| Bugs traceable to test gaps | {N} |

---

## Research Accuracy

How well did our research predict reality?

| Research Claim | Reality | Delta |
|----------------|---------|-------|
| {what we researched} | {what we found} | {match/partial/miss} |

### Research Misses

What did we research that turned out to be wrong or irrelevant?

| Miss | Impact | Root Cause |
|------|--------|------------|
| {research that was wrong} | {how it hurt us} | {why we got it wrong} |

### Research Gaps

What did we NOT research that we should have?

| Gap | Impact | How We Discovered |
|-----|--------|-------------------|
| {missing research} | {how it hurt us} | {when we realized} |

---

## Journey Accuracy

How well did our journeys predict actual user behavior?

| Journey Step | Expected Behavior | Actual Behavior | Delta |
|--------------|-------------------|-----------------|-------|
| {step} | {what we designed for} | {what happened} | {match/partial/miss} |

### Journey Misses

Where did users NOT follow the journey we designed?

| Miss | What Happened | Root Cause |
|------|---------------|------------|
| {journey step} | {actual behavior} | {why we got it wrong} |

### Missing Journeys

What journeys did we NOT anticipate?

| Missing Journey | How Discovered | Should Have Anticipated? |
|-----------------|----------------|--------------------------|
| {user path we missed} | {how we found it} | yes/no |

---

## Spec Accuracy

How well did our specs match implementation needs?

| Spec | Accuracy | Issues During Implementation |
|------|----------|------------------------------|
| S-{NNN} | high/medium/low | {what needed changing} |

### Spec Ambiguities Discovered

What was unclear that the validation should have caught?

| Spec | Ambiguity | How Resolved | Validation Gap |
|------|-----------|--------------|----------------|
| S-{NNN} | {what was unclear} | {how we fixed it} | {what validation missed} |

### Spec Contradictions Discovered

What conflicted that the validation should have caught?

| Specs | Contradiction | How Resolved | Validation Gap |
|-------|---------------|--------------|----------------|
| S-{NNN} vs S-{NNN} | {the conflict} | {resolution} | {what validation missed} |

---

## Test Accuracy

How well did our tests catch issues?

| Test | Caught Real Bug? | False Positive? | False Negative? |
|------|------------------|-----------------|-----------------|
| T-{NNN} | yes/no | yes/no | yes/no |

### Tests That Failed Us

Tests that passed but shouldn't have (bugs got through):

| Bug | Which Test Should Have Caught It | Why It Didn't |
|-----|----------------------------------|---------------|
| {bug description} | T-{NNN} | {gap in test} |

### Tests That Lied

Tests that failed but shouldn't have (false negatives):

| Test | Why It Failed Incorrectly | How Fixed |
|------|---------------------------|-----------|
| T-{NNN} | {false failure reason} | {fix applied} |

---

## Token Accuracy

How well did our design tokens work in practice?

| Token Category | Accuracy | Issues |
|----------------|----------|--------|
| Typography | high/medium/low | {issues} |
| Colors | high/medium/low | {issues} |
| Spacing | high/medium/low | {issues} |
| Components | high/medium/low | {issues} |

---

## Visual Accuracy

How well did our visual targets translate to implementation?

### Token Usage

| Check | Result | Issues |
|-------|--------|--------|
| All colors from tokens.md | pass/fail | {any hardcoded colors found} |
| All spacing on grid | pass/fail | {any off-grid values} |
| All typography in scale | pass/fail | {any undefined fonts/sizes} |

### Visual Validator Results

| Validator | Pass/Fail | Issues |
|-----------|-----------|--------|
| spec-validator | pass/fail | {issues} |
| visual-validator | pass/fail | {pixel diff %, breakpoint issues} |
| a11y-validator | pass/fail | {WCAG violations} |

### Figma Drift

Did implementation diverge from Figma source?

| Element | Figma | Implementation | Justified? |
|---------|-------|----------------|------------|
| {element} | {figma value} | {actual value} | yes/no — {reason} |

### Visual Validation Gaps

What did visual validation miss that caused issues?

| Gap | Impact | Validator Improvement |
|-----|--------|----------------------|
| {what was missed} | {how it hurt us} | {how to catch it next time} |

---

## Process Observations

### What Worked Well

| Phase | What Worked | Keep Doing |
|-------|-------------|------------|
| {phase} | {success} | {recommendation} |

### What Didn't Work

| Phase | What Failed | Stop Doing | Do Instead |
|-------|-------------|------------|------------|
| {phase} | {failure} | {anti-pattern} | {alternative} |

### Time Spent

| Phase | Estimated | Actual | Delta |
|-------|-----------|--------|-------|
| Research | {hours} | {hours} | +/-{hours} |
| Journeys | {hours} | {hours} | +/-{hours} |
| Specs | {hours} | {hours} | +/-{hours} |
| Tests | {hours} | {hours} | +/-{hours} |
| Validation | {hours} | {hours} | +/-{hours} |
| Implementation | {hours} | {hours} | +/-{hours} |
| Bug fixes | {hours} | {hours} | +/-{hours} |

---

## Learnings to Propagate

### Update PRINCIPLES.md

| Learning | New Principle or Modification |
|----------|-------------------------------|
| {what we learned} | {principle to add/change} |

### Update PATTERNS.md

| Learning | New Pattern or Anti-Pattern |
|----------|----------------------------|
| {what we learned} | {pattern to add} |

### Update Domain Library

| Learning | Domain File | Addition |
|----------|-------------|----------|
| {domain insight} | {Domains/*.md} | {what to add} |

### Update Validation Prompts

| Gap Found | Which Validation | Prompt Improvement |
|-----------|------------------|-------------------|
| {what validation missed} | {research/journey/spec/test} | {prompt addition} |

---

## Action Items

| Action | Owner | Due | Status |
|--------|-------|-----|--------|
| {update to make} | {who} | {when} | pending/done |

---

## Mode Assessment

Was the mode choice (full/standard/minimal) correct?

| Factor | Assessment |
|--------|------------|
| Mode used | {full/standard/minimal} |
| Should have used | {full/standard/minimal} |
| Why | {reasoning} |

If mode was wrong:
- [ ] Update decision tree in DESIGN-OPS.md if pattern is generalizable

---

## Signature

**Retrospective completed by**: {name}
**Date**: {YYYY-MM-DD}
**Reviewed by**: {name or "self"}

---

## Follow-Up

Schedule for 2 weeks post-implementation:

- [ ] Are the learnings still accurate after more usage?
- [ ] Any new bugs that trace to design gaps?
- [ ] Update this retrospective if needed


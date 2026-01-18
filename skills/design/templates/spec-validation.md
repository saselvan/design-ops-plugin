# Spec Validation: {spec-id}

id: SV-{NNN}
spec: S-{NNN}
date: {YYYY-MM-DD}
status: pending | in_progress | passed | failed
iteration: 1

---

## Purpose

Stress test the spec BEFORE deriving tests. Bad specs create bad tests. Catch ambiguity, incompleteness, and assumption gaps early.

> "A specification that can be interpreted in multiple ways will be implemented in a way you didn't intend." — Murphy's Law for Specs

---

## Pre-Validation Checklist

Author self-review before LLM validation:

### Completeness

- [ ] All user journey steps are covered
- [ ] Happy path fully specified
- [ ] Error states enumerated
- [ ] Edge cases addressed
- [ ] Empty/null states handled
- [ ] Loading states defined
- [ ] Permission variations covered

### Clarity

- [ ] No ambiguous pronouns ("it", "this", "that")
- [ ] Technical terms defined or linked
- [ ] Measurements have units (ms, px, %)
- [ ] "Should" replaced with "Must" or "May"
- [ ] Examples provided for complex behaviors

### Testability

- [ ] Every requirement has a verification method
- [ ] Success criteria are measurable
- [ ] Acceptance conditions are binary (pass/fail)
- [ ] No subjective terms without rubric ("fast", "good", "intuitive")

### Traceability

- [ ] Linked to user journey
- [ ] References design tokens
- [ ] Lists dependencies
- [ ] Identifies downstream specs

---

## LLM-as-Critic Validation

Run this prompt against the spec. The LLM acts as an adversarial reviewer.

### Prompt: Ambiguity Detection

```
You are a pedantic software architect reviewing a specification for ambiguity.

SPEC:
{paste full spec}

Find ambiguities by asking:
1. Could any requirement be interpreted two different ways? List them.
2. Are there implicit assumptions that aren't stated? List them.
3. What questions would an implementer ask that the spec doesn't answer?
4. Where does the spec use vague language? ("appropriate", "reasonable", "as needed")

For each issue found:
- Quote the problematic text
- Explain the ambiguity
- Suggest specific clarification

If no issues: Say "CLEAR" with confidence level (high/medium/low).
```

### Prompt: Edge Case Generation

```
You are a QA engineer trying to break an implementation.

SPEC:
{paste full spec}

Generate edge cases the spec may not handle:
1. Boundary conditions (empty, one, many, max)
2. Invalid inputs (wrong type, out of range, malformed)
3. Timing issues (slow network, concurrent actions, race conditions)
4. State transitions (what if user is mid-action and state changes?)
5. Permission edge cases (what if permissions change during use?)
6. Data edge cases (unicode, RTL, extremely long strings, special characters)

For each edge case:
- Describe the scenario
- Note whether spec addresses it (yes/no/partial)
- If no: Suggest spec addition

If all covered: Say "COMPREHENSIVE" with confidence level.
```

### Prompt: Implementation Simulation

```
You are a developer who must implement ONLY from this spec. No clarifying questions allowed.

SPEC:
{paste full spec}

Walk through implementation:
1. What would you build first?
2. Where do you have to make assumptions?
3. Where would you guess at behavior?
4. What error handling would you invent?
5. What would you build that might be wrong?

For each assumption/guess:
- Note what's missing from spec
- Rate severity: blocker | major | minor

If spec is sufficient: Say "IMPLEMENTABLE" with confidence level.
```

### Prompt: Contradiction Detection

```
You are a logic auditor checking for internal contradictions.

SPEC:
{paste full spec}

Check for:
1. Requirements that conflict with each other
2. States that are mutually exclusive but both required
3. Timing constraints that can't all be satisfied
4. Dependencies that create circular references
5. Behaviors that differ between sections

For each contradiction:
- Quote both conflicting requirements
- Explain the conflict
- Suggest resolution

If consistent: Say "CONSISTENT" with confidence level.
```

---

## Validation Results

### Iteration {N}

**Date**: {YYYY-MM-DD}

#### Ambiguity Detection

| Issue | Location | Resolution |
|-------|----------|------------|
| {issue} | {quote or line ref} | {how we fixed it} |

**Verdict**: CLEAR / NEEDS_WORK

#### Edge Case Generation

| Edge Case | Covered? | Resolution |
|-----------|----------|------------|
| {case} | yes/no/partial | {how we addressed it} |

**Verdict**: COMPREHENSIVE / NEEDS_WORK

#### Implementation Simulation

| Assumption Made | Severity | Resolution |
|-----------------|----------|------------|
| {what dev would guess} | blocker/major/minor | {clarification added} |

**Verdict**: IMPLEMENTABLE / NEEDS_WORK

#### Contradiction Detection

| Conflict | Resolution |
|----------|------------|
| {quote A vs quote B} | {how resolved} |

**Verdict**: CONSISTENT / NEEDS_WORK

---

## Iteration Log

| Iteration | Date | Issues Found | Issues Fixed | Verdict |
|-----------|------|--------------|--------------|---------|
| 1 | {date} | {N} | {N} | NEEDS_WORK |
| 2 | {date} | {N} | {N} | PASSED |

---

## Validation Exit Criteria

Spec is validated when ALL are true:

- [ ] At least 2 iterations completed
- [ ] Ambiguity Detection: CLEAR (high confidence)
- [ ] Edge Case Generation: COMPREHENSIVE (medium+ confidence)
- [ ] Implementation Simulation: IMPLEMENTABLE (medium+ confidence)
- [ ] Contradiction Detection: CONSISTENT (high confidence)
- [ ] All blockers and majors resolved
- [ ] Changelog updated with validation findings

---

## Post-Validation

When spec passes validation:

1. Update spec status to `validated`
2. Add validation badge to spec header
3. Proceed to test contract generation
4. Link validation results in spec changelog

```markdown
## Changelog

### v1.1 — {date}
- Validated via SV-{NNN}
- Clarified {ambiguity 1}
- Added edge case handling for {case 1}
- Resolved contradiction between {A} and {B}
```

---

## When to Re-Validate

Trigger re-validation if:

- Spec receives major change (>10% of content)
- New user journey added that affects this spec
- Bug found that traces back to spec ambiguity
- Implementation deviated significantly from spec

---

## Anti-Patterns

### Don't Do This

| Anti-Pattern | Why It's Bad | Do This Instead |
|--------------|--------------|-----------------|
| Skip validation for "simple" specs | Simple specs hide assumptions | Validate everything |
| Stop at 1 iteration | First pass misses things | Minimum 2 iterations |
| Mark "minor" issues as resolved without fixing | They compound | Fix or explicitly defer |
| Validate your own spec | Author blindness | Use LLM or peer |
| Rush through checklist | Checkbox theater | Actually read and check |

---

## Sources

- Pragmatic Programmer: "Tracer bullets" — validate before committing
- Kent Beck: "Test first" — but test SPEC first
- Clean Architecture: "Screaming architecture" — spec should make intent obvious
- Shape Up: "Rabbit holes" — find them before building


# Test Validation: {test-id}

id: TV-{NNN}
test: T-{NNN}
spec: S-{NNN}
date: {YYYY-MM-DD}
status: pending | in_progress | passed | failed
iteration: 1

---

## Purpose

Validate tests before they become the quality gate. Bad tests create false confidence — they pass when they shouldn't, fail when they shouldn't, or test the wrong thing entirely.

> "A test that can't fail is worthless. A test that fails for the wrong reason is dangerous."

---

## Pre-Validation Checklist

Author self-review before LLM validation:

### Coverage

- [ ] Every spec requirement has at least one test
- [ ] Happy path tested
- [ ] At least 2 error paths tested
- [ ] Edge cases from spec are tested
- [ ] Boundary conditions tested (empty, one, many, max)

### Independence

- [ ] Tests don't depend on each other's state
- [ ] Tests can run in any order
- [ ] Tests clean up after themselves
- [ ] No shared mutable state between tests

### Clarity

- [ ] Test names describe what they verify
- [ ] Given/When/Then structure is clear
- [ ] Assertions are specific (not just "truthy")
- [ ] Failure messages would help diagnose the problem

### Validity

- [ ] Tests actually test the requirement, not implementation details
- [ ] Tests would fail if the feature broke
- [ ] Tests wouldn't fail for unrelated changes
- [ ] Tests don't just check that code runs without error

### Maintainability

- [ ] Tests don't duplicate each other
- [ ] Setup code is shared appropriately
- [ ] Magic numbers/strings are explained
- [ ] Tests are readable without context

---

## LLM-as-Critic Validation

### Prompt: False Positive Detection

```
You are hunting for tests that would pass even if the feature is broken.

TEST CONTRACT:
{paste full test contract}

SPEC IT SHOULD VERIFY:
{paste relevant spec sections}

Hunt for false positives:
1. Could any test pass even if the underlying feature is broken?
2. Are there tests that only check "no error thrown" without verifying behavior?
3. Are there tests that check implementation details instead of outcomes?
4. Are there tests with assertions so weak they'd pass for wrong outputs?
5. Are there tests that mock so much they test the mocks, not the code?

For each false positive risk:
- Quote the test
- Explain how it could pass incorrectly
- Suggest stronger assertion

If tests are rigorous: Say "RIGOROUS" with confidence level.
```

### Prompt: False Negative Detection

```
You are hunting for tests that would fail even when the feature works correctly.

TEST CONTRACT:
{paste full test contract}

SPEC IT SHOULD VERIFY:
{paste relevant spec sections}

Hunt for false negatives:
1. Are there tests that are too strict about implementation details?
2. Are there tests that would break from valid refactoring?
3. Are there timing-dependent tests that could flake?
4. Are there tests that depend on external state (network, filesystem, time)?
5. Are there tests with hardcoded values that might legitimately change?

For each false negative risk:
- Quote the test
- Explain how it could fail incorrectly
- Suggest more resilient approach

If tests are stable: Say "STABLE" with confidence level.
```

### Prompt: Spec Coverage Gap Detection

```
You are checking if tests actually cover the spec.

SPEC:
{paste full spec}

TEST CONTRACT:
{paste full test contract}

Check coverage:
1. List each requirement in the spec
2. For each requirement, identify which test(s) verify it
3. Flag any requirements with no tests
4. Flag any requirements with only partial coverage
5. Flag any tests that don't trace to a requirement (orphan tests)

For each gap:
- Quote the uncovered requirement
- Suggest test to add

If fully covered: Say "COMPLETE" with confidence level.
```

### Prompt: Mutation Survival Detection

```
You are a mutation testing engine. Check if tests would catch bugs.

TEST CONTRACT:
{paste full test contract}

SPEC IT SHOULD VERIFY:
{paste relevant spec sections}

For each test, imagine these mutations to the implementation:
1. What if we returned null/undefined instead?
2. What if we returned an empty array/object instead?
3. What if we swapped a < for a >?
4. What if we off-by-one'd a loop?
5. What if we skipped an error check?
6. What if we hardcoded a value instead of computing it?

For each mutation:
- Would the test catch it? (yes/no/maybe)
- If no: What's missing from the test?

If mutations would be caught: Say "MUTATION-RESISTANT" with confidence level.
```

### Prompt: Test Smell Detection

```
You are checking for common test anti-patterns.

TEST CONTRACT:
{paste full test contract}

Hunt for test smells:
1. **Giant Test**: Single test doing too much (>10 assertions)
2. **Eager Test**: Testing multiple behaviors in one test
3. **Mystery Guest**: Test depends on external data/state not visible in test
4. **Test Logic**: Complex conditionals or loops in tests
5. **Obscure Test**: Can't understand intent without reading implementation
6. **Assertion Roulette**: Multiple assertions, unclear which failed
7. **Slow Test**: Would take >1 second to run
8. **Fragile Test**: Depends on implementation details that might change

For each smell:
- Quote the problematic test
- Identify the smell
- Suggest fix

If clean: Say "CLEAN" with confidence level.
```

---

## Validation Results

### Iteration {N}

**Date**: {YYYY-MM-DD}

#### False Positive Detection

| Test | Risk | Resolution |
|------|------|------------|
| {test name} | {how it could pass incorrectly} | {strengthened assertion} |

**Verdict**: RIGOROUS / NEEDS_WORK

#### False Negative Detection

| Test | Risk | Resolution |
|------|------|------------|
| {test name} | {how it could fail incorrectly} | {made resilient} |

**Verdict**: STABLE / NEEDS_WORK

#### Spec Coverage Gap

| Uncovered Requirement | Resolution |
|-----------------------|------------|
| {requirement} | {test added} |

**Verdict**: COMPLETE / NEEDS_WORK

#### Mutation Survival

| Mutation | Would Catch? | Resolution |
|----------|--------------|------------|
| {mutation} | yes/no/maybe | {test improved} |

**Verdict**: MUTATION-RESISTANT / NEEDS_WORK

#### Test Smells

| Smell | Test | Resolution |
|-------|------|------------|
| {smell type} | {test name} | {refactored} |

**Verdict**: CLEAN / NEEDS_WORK

---

## Iteration Log

| Iteration | Date | Issues Found | Issues Fixed | Verdict |
|-----------|------|--------------|--------------|---------|
| 1 | {date} | {N} | {N} | NEEDS_WORK |
| 2 | {date} | {N} | {N} | PASSED |

---

## Validation Exit Criteria

Tests are validated when ALL are true:

- [ ] At least 2 iterations completed
- [ ] False Positives: RIGOROUS (high confidence)
- [ ] False Negatives: STABLE (medium+ confidence)
- [ ] Spec Coverage: COMPLETE (high confidence)
- [ ] Mutation Survival: MUTATION-RESISTANT (medium+ confidence)
- [ ] Test Smells: CLEAN (medium+ confidence)
- [ ] All critical and high-risk issues resolved

---

## The Inversion Test

Before marking validated, try this:

1. **Deliberately break the implementation** in an obvious way
2. **Run the tests** — do they fail?
3. **Check the failure message** — does it help diagnose the problem?

If tests don't fail when implementation is broken, tests are worthless.

---

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Do This Instead |
|--------------|--------------|-----------------|
| Test only that code runs | Doesn't verify correctness | Assert on outputs |
| Mock everything | Tests the mocks, not code | Use real objects where feasible |
| Test implementation details | Breaks on valid refactoring | Test behavior/outcomes |
| Weak assertions (`toBeTruthy`) | Passes for wrong values | Specific assertions (`toEqual`) |
| No edge cases | Misses common bugs | Test boundaries explicitly |
| Coupled tests | Flaky, order-dependent | Isolate each test |
| Only happy path | False confidence | Test at least 2 error paths |

---

## Test Quality Metrics

Track these over time:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Mutation score | >80% | Run mutation testing tool |
| Spec coverage | 100% | Trace each requirement |
| Flake rate | <1% | Track CI failures |
| Time to run | <10s for unit | Profile test suite |
| False positive rate | 0% | Track bugs that passed tests |


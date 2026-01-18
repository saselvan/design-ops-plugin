# Test Contract: {test-name}

id: T-{NNN}
spec: S-{NNN}
journey: J-{NNN}
type: functional | non-functional | llm-judge
date: {YYYY-MM-DD}

---

## Functional Tests

### Scenario: {scenario-name}

**Given**: {precondition}
**When**: {action}
**Then**: {expected outcome}
**And**: {additional assertions}

```typescript
// Implementation hint
it('{scenario-name}', async () => {
  // Given
  {setup}

  // When
  {action}

  // Then
  expect({assertion}).toBe({expected})
})
```

---

### Scenario: {scenario-name}

**Given**: {precondition}
**When**: {action}
**Then**: {expected outcome}

---

### Edge Cases

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Empty state | No data | Page loads | Show empty message + CTA |
| Error state | API fails | Page loads | Show error banner + retry |
| Slow load | API takes >2s | Page loads | Show skeleton, then data |
| {edge case} | {condition} | {action} | {expected} |

---

## Non-Functional Tests

### Performance

| Metric | Target | Test Method |
|--------|--------|-------------|
| First render | <{X}ms | React Profiler |
| API latency | <{X}ms | Network timing |
| Bundle size | <{X}KB | Build output |

```typescript
it('renders within performance budget', async () => {
  const start = performance.now()
  render(<Component />)
  const duration = performance.now() - start
  expect(duration).toBeLessThan({target})
})
```

### Accessibility

| Check | Tool | Pass Criteria |
|-------|------|---------------|
| Color contrast | axe-core | 0 violations |
| Keyboard nav | Manual | All interactive elements reachable |
| Screen reader | VoiceOver | Announces all state changes |
| Focus order | Manual | Logical tab sequence |

```typescript
it('has no accessibility violations', async () => {
  const { container } = render(<Component />)
  const results = await axe(container)
  expect(results.violations).toHaveLength(0)
})
```

### Resilience

| Scenario | Test | Expected |
|----------|------|----------|
| Network offline | Disable network | Cached state + offline indicator |
| API timeout | Delay response 10s | Timeout error after 5s |
| Invalid response | Return malformed JSON | Error state, no crash |

---

## LLM-as-Judge Tests

### Quality Gate: {gate-name}

**Context**:
- Journey: {J-NNN} - {journey name}
- Principle: {relevant design principle}

**Evaluation Prompt**:

```
You are evaluating a UI implementation against its design requirements.

ORIGINAL USER JOURNEY:
{paste journey narrative}

DESIGN PRINCIPLES:
{list relevant principles}

IMPLEMENTATION:
{screenshot or HTML output}

EVALUATE:

1. Does the implementation match the journey intent? (yes/no + reasoning)
2. Are the design principles followed? (check each)
3. Emotional arc achieved? (rate 1-5)
4. Any violations or concerns? (list)

VERDICT: PASS | NEEDS_WORK | FAIL

If NEEDS_WORK or FAIL, provide specific changes required.
```

**Pass Criteria**:
- [ ] Verdict is PASS
- [ ] All principles checked as followed
- [ ] Emotional arc rating ≥ 4

---

### Quality Gate: {gate-name}

**Context**:
- Spec: {S-NNN}
- Focus: {what aspect to judge}

**Evaluation Prompt**:

```
{custom prompt for this gate}
```

---

## Integration Test Checklist

- [ ] Works with real API (not mocked)
- [ ] State persists across navigation
- [ ] Works in target deployment environment
- [ ] No console errors/warnings
- [ ] No network errors (check DevTools)

---

## Manual Test Script

For QA or self-validation:

| Step | Action | Expected Result | ✓ |
|------|--------|-----------------|---|
| 1 | {action} | {expected} | |
| 2 | {action} | {expected} | |
| 3 | {action} | {expected} | |

---

## Coverage

| Type | Count | Status |
|------|-------|--------|
| Functional scenarios | {n} | {pass/fail} |
| Edge cases | {n} | {pass/fail} |
| Non-functional | {n} | {pass/fail} |
| LLM quality gates | {n} | {pass/fail} |

**Overall**: {READY / NOT READY}

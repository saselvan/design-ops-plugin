# Research Validation: {project-name}

id: RV-{NNN}
research: {research-file}
date: {YYYY-MM-DD}
status: pending | in_progress | passed | failed
iteration: 1

---

## Purpose

Validate research before it informs journeys and specs. Flawed research poisons everything downstream.

> "The most dangerous research is research that confirms what you already believe." — Confirmation Bias Trap

---

## Pre-Validation Checklist

Author self-review before LLM validation:

### Coverage

- [ ] At least 3 distinct expert/legend sources cited
- [ ] At least 2 direct competitors analyzed
- [ ] At least 1 adjacent domain explored
- [ ] At least 1 contrarian/skeptical viewpoint included
- [ ] Anti-patterns section populated (what NOT to do)
- [ ] Cross-domain inspiration section has unexpected sources

### Freshness

- [ ] All sources dated within 2 years (or marked as "timeless principles")
- [ ] Live web search performed (not just memory/training data)
- [ ] Current market landscape reflected
- [ ] No deprecated technologies recommended

### Relevance

- [ ] Research directly addresses the problem statement
- [ ] Domain context matches actual user environment
- [ ] Token recommendations fit the domain (not generic)
- [ ] Experts cited are relevant to THIS domain

### Balance

- [ ] Multiple perspectives represented (not just one school of thought)
- [ ] Tradeoffs acknowledged (no "silver bullet" recommendations)
- [ ] Limitations of sources noted
- [ ] Disagreements between experts surfaced

---

## LLM-as-Critic Validation

### Prompt: Echo Chamber Detection

```
You are a research auditor checking for perspective diversity.

RESEARCH DOCUMENT:
{paste full research}

Analyze for echo chamber risks:
1. How many distinct sources are cited? List them.
2. Do all sources share the same perspective/school of thought?
3. Are there obvious missing perspectives? (competitors, critics, adjacent fields)
4. Is there confirmation bias — only citing sources that agree with a predetermined conclusion?
5. Are contrarian viewpoints represented?

For each gap:
- Identify what's missing
- Suggest specific sources to add
- Rate severity: critical | important | nice-to-have

If balanced: Say "DIVERSE" with confidence level (high/medium/low).
```

### Prompt: Staleness Check

```
You are a research freshness auditor.

RESEARCH DOCUMENT:
{paste full research}

TODAY'S DATE: {YYYY-MM-DD}

Check for staleness:
1. List all sources with their dates (or "undated")
2. Flag any sources older than 2 years
3. Are there technologies or practices mentioned that are now deprecated?
4. Does the competitive landscape section reflect current reality?
5. Are there major recent developments in this domain that are missing?

For each stale item:
- Quote the outdated content
- Explain what's changed
- Suggest update or removal

If current: Say "FRESH" with confidence level.
```

### Prompt: Domain Drift Detection

```
You are checking if research actually matches the problem.

PROBLEM STATEMENT:
{paste problem/requirements}

RESEARCH DOCUMENT:
{paste full research}

Check for domain drift:
1. Does the research address the ACTUAL problem, or a related-but-different problem?
2. Are the users described in research the ACTUAL users?
3. Are the constraints in research the ACTUAL constraints?
4. Would following this research solve the stated problem?
5. Is there "borrowed authority" — citing experts from a different domain as if they apply here?

For each drift:
- Quote the misaligned content
- Explain the mismatch
- Suggest realignment

If aligned: Say "FOCUSED" with confidence level.
```

### Prompt: Missing Competitors

```
You are a competitive intelligence auditor.

DOMAIN: {domain}
PROBLEM: {problem statement}

RESEARCH DOCUMENT:
{paste full research}

Check competitive coverage:
1. List all competitors mentioned in the research
2. What major players in this space are NOT mentioned?
3. Are competitor strengths AND weaknesses analyzed, or just weaknesses?
4. Is the competitive analysis current (check for recent acquisitions, pivots, new entrants)?
5. Are there open-source or unconventional alternatives missing?

For each gap:
- Name the missing competitor/alternative
- Explain their relevance
- Rate importance: must-add | should-add | could-add

If comprehensive: Say "COMPLETE" with confidence level.
```

### Prompt: Assumption Surfacing

```
You are hunting for hidden assumptions in research.

RESEARCH DOCUMENT:
{paste full research}

Surface implicit assumptions:
1. What does this research assume about the users that isn't proven?
2. What does it assume about the technical environment?
3. What does it assume about the business context?
4. What does it assume about the timeline/resources?
5. Are there "everybody knows" statements that might not be true?

For each assumption:
- State the assumption explicitly
- Note whether it's validated or just assumed
- Rate risk if wrong: high | medium | low

If assumptions are explicit: Say "TRANSPARENT" with confidence level.
```

---

## Validation Results

### Iteration {N}

**Date**: {YYYY-MM-DD}

#### Echo Chamber Detection

| Gap | Severity | Resolution |
|-----|----------|------------|
| {missing perspective} | critical/important/nice | {source added} |

**Verdict**: DIVERSE / NEEDS_WORK

#### Staleness Check

| Stale Item | Age | Resolution |
|------------|-----|------------|
| {outdated content} | {years} | {updated/removed} |

**Verdict**: FRESH / NEEDS_WORK

#### Domain Drift Detection

| Drift | Resolution |
|-------|------------|
| {misalignment} | {realigned} |

**Verdict**: FOCUSED / NEEDS_WORK

#### Missing Competitors

| Missing | Importance | Resolution |
|---------|------------|------------|
| {competitor} | must/should/could | {added/justified exclusion} |

**Verdict**: COMPLETE / NEEDS_WORK

#### Assumption Surfacing

| Assumption | Validated? | Risk | Resolution |
|------------|------------|------|------------|
| {assumption} | yes/no | high/med/low | {validated/documented} |

**Verdict**: TRANSPARENT / NEEDS_WORK

---

## Iteration Log

| Iteration | Date | Issues Found | Issues Fixed | Verdict |
|-----------|------|--------------|--------------|---------|
| 1 | {date} | {N} | {N} | NEEDS_WORK |
| 2 | {date} | {N} | {N} | PASSED |

---

## Validation Exit Criteria

Research is validated when ALL are true:

- [ ] At least 2 iterations completed
- [ ] Echo Chamber: DIVERSE (medium+ confidence)
- [ ] Staleness: FRESH (high confidence)
- [ ] Domain Drift: FOCUSED (high confidence)
- [ ] Missing Competitors: COMPLETE (medium+ confidence)
- [ ] Assumptions: TRANSPARENT (medium+ confidence)
- [ ] All critical and important gaps resolved

---

## Research Refresh Triggers

Re-validate research if:

- [ ] More than 6 months since validation
- [ ] Major market event in domain (acquisition, new entrant, regulation)
- [ ] Project pivots to different user segment
- [ ] Competitive landscape shifts
- [ ] User feedback contradicts research assumptions

---

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Do This Instead |
|--------------|--------------|-----------------|
| Only cite training data | Stale, no live market data | Always do live search |
| 1-2 sources only | Echo chamber | Minimum 3 distinct sources |
| Skip competitor analysis | Blind to alternatives | Always analyze 2+ competitors |
| Ignore contrarians | Miss valid criticisms | Include skeptical viewpoint |
| Generic domain research | Doesn't fit actual problem | Tailor to specific context |
| Skip cross-domain | Miss breakthrough ideas | Always check adjacent fields |


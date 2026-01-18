# Journey Validation: {journey-id}

id: JV-{NNN}
journey: J-{NNN}
date: {YYYY-MM-DD}
status: pending | in_progress | passed | failed
iteration: 1

---

## Purpose

Validate user journeys before they drive specs. Flawed journeys create specs that build the wrong thing beautifully.

> "There is nothing so useless as doing efficiently that which should not be done at all." — Peter Drucker

---

## Pre-Validation Checklist

Author self-review before LLM validation:

### Actor Clarity

- [ ] Actor is specific (not just "user")
- [ ] Actor links to persona or has inline context
- [ ] Actor's goal is explicitly stated
- [ ] Actor's constraints/context are documented
- [ ] Actor's technical skill level is noted

### Flow Completeness

- [ ] Happy path is fully documented
- [ ] At least 2 error/failure paths included
- [ ] Edge cases identified and handled
- [ ] Entry points are clear (how do they get here?)
- [ ] Exit points are clear (where do they go next?)
- [ ] Decision points have all branches documented

### Emotional Arc

- [ ] User feeling documented at each major stage
- [ ] Design response to each feeling is specified
- [ ] Anxiety/frustration points identified
- [ ] Delight/satisfaction moments designed
- [ ] Recovery from errors considers emotional state

### Reality Check

- [ ] Based on actual user research or observation
- [ ] Not just "how we imagine users behave"
- [ ] Timing assumptions are realistic
- [ ] Technical assumptions are validated
- [ ] Doesn't assume perfect conditions

### Traceability

- [ ] Links to requirements
- [ ] Links to research
- [ ] Links to personas (if applicable)
- [ ] Downstream specs identified

---

## LLM-as-Critic Validation

### Prompt: Happy Path Bias Detection

```
You are a pessimistic QA engineer reviewing a user journey.

USER JOURNEY:
{paste full journey including Mermaid diagram}

Hunt for happy path bias:
1. What happens if the user makes a mistake at each step?
2. What happens if the system fails at each step?
3. What happens if the user abandons mid-journey?
4. What happens if the user's session times out?
5. What happens if data is missing or malformed?
6. What happens if the user goes "backward" in the flow?

For each missing error path:
- Describe the scenario
- Note where in the journey it would occur
- Rate likelihood: common | occasional | rare

If error paths are comprehensive: Say "RESILIENT" with confidence level.
```

### Prompt: Actor Vagueness Detection

```
You are checking if the journey actor is specific enough to build from.

USER JOURNEY:
{paste full journey}

Check actor specificity:
1. Is the actor just "user" or "customer" without context?
2. Can you picture this specific person? (age, role, environment, device)
3. Is their goal clear and measurable?
4. Are their constraints documented? (time pressure, technical skill, accessibility needs)
5. Would two different developers imagine the same person?

For each vagueness:
- Quote the vague description
- Explain why it's insufficient
- Suggest specific details to add

If actor is clear: Say "SPECIFIC" with confidence level.
```

### Prompt: Reality Check

```
You are a user researcher validating journey assumptions.

USER JOURNEY:
{paste full journey}

DOMAIN CONTEXT:
{paste domain — e.g., "healthcare clinicians in busy ER"}

Check for unrealistic assumptions:
1. Does the flow assume the user has uninterrupted focus?
2. Does it assume perfect network conditions?
3. Does it assume the user reads everything?
4. Does it assume the user follows the intended path?
5. Does it assume ideal data quality?
6. Are the timing estimates realistic for this context?

For each unrealistic assumption:
- Quote the assumption
- Explain why it's unrealistic for this context
- Suggest more realistic alternative

If realistic: Say "GROUNDED" with confidence level.
```

### Prompt: Missing Decision Points

```
You are checking if all user decisions are captured.

USER JOURNEY:
{paste full journey with Mermaid diagram}

Hunt for missing decisions:
1. Are there implicit choices the user makes that aren't shown?
2. Are there "it depends" moments without clear branches?
3. What if the user wants to do something the journey doesn't allow?
4. Are there points where user might want to go back/undo?
5. Are permission/access checks shown as decision points?

For each missing decision:
- Describe the decision
- Note where it should appear
- List the branches needed

If decisions are complete: Say "COMPLETE" with confidence level.
```

### Prompt: Emotional Arc Validation

```
You are a UX psychologist reviewing emotional design.

USER JOURNEY:
{paste full journey including emotional arc table}

Validate emotional design:
1. Is there an emotional arc, or just functional steps?
2. Are anxiety-inducing moments identified and addressed?
3. Are there designed moments of delight or satisfaction?
4. How does the journey handle user frustration?
5. Does the ending leave the user feeling accomplished?
6. Are error states designed with emotional awareness?

For each emotional gap:
- Identify the moment
- Note the likely user emotion
- Suggest design response

If emotionally designed: Say "EMPATHETIC" with confidence level.
```

### Prompt: Journey Bloat Detection

```
You are checking if the journey is too complex.

USER JOURNEY:
{paste full journey with Mermaid diagram}

Check for bloat:
1. How many steps in the happy path? (>10 is concerning)
2. How many decision points? (>3 is concerning)
3. Can any steps be combined without losing clarity?
4. Can any steps be eliminated entirely?
5. Is this actually multiple journeys masquerading as one?
6. Does the journey try to serve multiple distinct goals?

For each bloat indicator:
- Identify the excess
- Suggest simplification
- Note if journey should be split

If right-sized: Say "FOCUSED" with confidence level.
```

---

## Validation Results

### Iteration {N}

**Date**: {YYYY-MM-DD}

#### Happy Path Bias

| Missing Error Path | Likelihood | Resolution |
|--------------------|------------|------------|
| {scenario} | common/occasional/rare | {added to journey} |

**Verdict**: RESILIENT / NEEDS_WORK

#### Actor Vagueness

| Vague Element | Resolution |
|---------------|------------|
| {quote} | {made specific} |

**Verdict**: SPECIFIC / NEEDS_WORK

#### Reality Check

| Unrealistic Assumption | Resolution |
|------------------------|------------|
| {assumption} | {made realistic} |

**Verdict**: GROUNDED / NEEDS_WORK

#### Missing Decision Points

| Missing Decision | Resolution |
|------------------|------------|
| {decision} | {added with branches} |

**Verdict**: COMPLETE / NEEDS_WORK

#### Emotional Arc

| Emotional Gap | Resolution |
|---------------|------------|
| {moment without emotion} | {added feeling + response} |

**Verdict**: EMPATHETIC / NEEDS_WORK

#### Journey Bloat

| Bloat Indicator | Resolution |
|-----------------|------------|
| {excess} | {simplified/split} |

**Verdict**: FOCUSED / NEEDS_WORK

---

## Iteration Log

| Iteration | Date | Issues Found | Issues Fixed | Verdict |
|-----------|------|--------------|--------------|---------|
| 1 | {date} | {N} | {N} | NEEDS_WORK |
| 2 | {date} | {N} | {N} | PASSED |

---

## Validation Exit Criteria

Journey is validated when ALL are true:

- [ ] At least 2 iterations completed
- [ ] Happy Path Bias: RESILIENT (medium+ confidence)
- [ ] Actor Vagueness: SPECIFIC (high confidence)
- [ ] Reality Check: GROUNDED (medium+ confidence)
- [ ] Missing Decisions: COMPLETE (medium+ confidence)
- [ ] Emotional Arc: EMPATHETIC (medium+ confidence)
- [ ] Journey Bloat: FOCUSED (medium+ confidence)
- [ ] All common/occasional error paths documented

---

## Journey Refresh Triggers

Re-validate journey if:

- [ ] User research reveals different behavior
- [ ] Usability testing contradicts assumptions
- [ ] Persona is updated significantly
- [ ] Technical constraints change
- [ ] Business requirements shift
- [ ] Error rates in production suggest missing paths

---

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Do This Instead |
|--------------|--------------|-----------------|
| "User clicks button" | No context, no emotion | "Rushed clinician confirms order" |
| Happy path only | Errors will happen | Document 2+ failure paths |
| No emotional arc | Functional but frustrating | Add feeling at each stage |
| 15-step journey | Cognitive overload | Split into sub-journeys |
| Generic actor | Can't design for "everyone" | Specific persona with constraints |
| Assumed perfect data | Reality is messy | Handle empty, malformed, stale |
| No entry/exit context | Orphaned journey | Link to before/after |

---

## Walkthrough Exercise

Before marking validated, do this:

1. **Role-play the journey** aloud, narrating as the actor
2. **Intentionally make mistakes** — does the journey handle them?
3. **Ask "what if..."** at every step
4. **Time yourself** — is it realistic?
5. **Try on mobile** mentally — does it still work?

If you can't complete the walkthrough without inventing behavior, the journey isn't ready.


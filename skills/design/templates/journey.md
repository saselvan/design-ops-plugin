# Journey: {journey-name}

id: J-{NNN}
version: 1.0
status: draft | active | deprecated
parent: REQ-{NNN}
specs: [S-{NNN}, S-{NNN}]
date: {YYYY-MM-DD}

---

## Context

**Actor**: {who is doing this}
**Goal**: {what they want to accomplish}
**Trigger**: {what initiates this journey}
**Frequency**: {how often this happens}
**Environment**: {where/when this happens}

---

## Narrative

{Write the journey as a story. Include emotional states.}

> {Actor} opens {app/page} because {reason}. They're feeling {emotion} because {context}.
>
> They need to quickly {understand/find/do} {thing}. When they see {element}, they feel {emotion} because {reason}.
>
> They {action}, which leads to {outcome}. They leave feeling {emotion}.

---

## Flow

```mermaid
flowchart TD
    A[{Starting point}] --> B{Decision point?}
    B -->|Yes| C[Path A]
    B -->|No| D[Path B]
    C --> E[Outcome]
    D --> E
    E --> F[End state]
```

---

## Emotional Arc

| Stage | User Feeling | Design Response |
|-------|--------------|-----------------|
| Entry | {e.g., Anxious, rushed} | {e.g., Immediate clarity, no loading} |
| Discovery | {e.g., Uncertain} | {e.g., Clear affordances} |
| Action | {e.g., Focused} | {e.g., Minimal distractions} |
| Completion | {e.g., Accomplished} | {e.g., Confirmation, next step} |
| Exit | {e.g., Confident} | {e.g., Clear state, nothing forgotten} |

---

## Edge Cases

| Scenario | User Expects | System Should |
|----------|--------------|---------------|
| {edge case} | {expectation} | {behavior} |
| No data | Clear empty state | Show helpful message + action |
| Error | Know what went wrong | Actionable error message |
| Slow connection | Progress indication | Skeleton + timeout handling |
| {add more...} | | |

---

## Requirements Generated

From this journey, we need:

- [ ] REQ: {requirement description}
- [ ] REQ: {requirement description}
- [ ] REQ: {requirement description}

---

## Changelog

| Version | Date | Change | Why |
|---------|------|--------|-----|
| 1.0 | {date} | Initial journey | {source/context} |

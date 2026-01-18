# Design Principles

Core beliefs that guide every design decision. These are YOUR principles — update as you learn.

## Universal Principles

### Accessibility First
> Design for the extremes, everyone benefits.

- WCAG 2.1 AA minimum
- Works with keyboard only
- Works with screen reader
- Respects `prefers-reduced-motion`
- Color is never the only indicator

Source: Inclusive Design principles, Microsoft

### ADHD-Friendly
> If it requires remembering, it's broken.

- Scannable over readable (max 7 items)
- Clear visual hierarchy
- One obvious "do this first" element
- No walls of text
- State persists (don't lose my work)

Source: Personal experience, ADHD productivity research

### Less But Better
> Remove until it breaks, then add one thing back.

- Every element earns its place
- No decorative flourishes
- If you're adding a feature, what are you removing?
- Complexity is a cost, simplicity is a feature

Source: Dieter Rams, "Less but better"

### Speed Is a Feature
> Slow UI is broken UI.

- First contentful paint < 1.5s
- Interactions < 100ms feel instant
- Show progress, never spinners > 2s
- Optimistic updates when safe

Source: Nielsen Norman Group response time research

### Errors Are Actionable
> "Something went wrong" is not an error message.

- What happened (in human terms)
- Why it happened (if known)
- What to do next (always)

Example:
- Bad: "Error 500"
- Good: "Couldn't save. Check your connection and try again."

### Trust the User
> Hide complexity, don't remove capability.

- Simple by default
- Power features discoverable
- Keyboard shortcuts for experts
- Don't require confirmation for reversible actions

Source: Krug, "Don't Make Me Think"

## Visual Principles

### Hierarchy Through Size
> If everything is big, nothing is big.

- Max 3 text sizes per screen
- Max 3 font weights per screen
- Size = importance

### Whitespace Is Content
> Empty space isn't wasted space.

- Breathing room reduces cognitive load
- Generous padding > cramped efficiency
- Group by proximity

Source: Japanese Ma (間) concept

### Color Has Meaning
> Every color choice is a semantic choice.

- Green = success, healthy, go
- Yellow/Amber = warning, attention
- Red = danger, error, stop
- Blue = neutral action, link
- Don't use color alone (icons + text)

### Consistency Over Creativity
> Same problem, same solution, every time.

- Use existing patterns before inventing
- Components look and behave identically
- Location consistency (save button always same place)

## Interaction Principles

### No Mystery Meat
> Every icon needs a label or tooltip.

- Icons alone are ambiguous
- Text labels > icon-only
- Tooltips for space-constrained icons

### Undo Over Confirm
> Don't ask "Are you sure?" — let them undo.

- Confirmation dialogs break flow
- Soft delete with undo
- Only confirm irreversible + destructive

### Progressive Disclosure
> Show what's needed, reveal on demand.

- Start simple
- Advanced options hidden but findable
- Don't overwhelm upfront

Source: Nielsen Norman Group

### Feedback Always
> Every action needs acknowledgment.

- Button clicked → visual change
- Form submitted → confirmation
- Error occurred → explanation
- Loading → progress indicator

## Process Principles

### Research Before Design
> Steal from the best, then improve.

- Find prior art
- Learn from domain experts
- Understand constraints first

### Journey Before UI
> Know the user's story before drawing screens.

- Who is the user?
- What do they want?
- What's the emotional arc?
- Then: what do they see?

### Test the Intent, Not the Implementation
> Does it do what the user needed? Not just what the spec said.

- LLM-as-judge for quality
- Real usage validation
- "Would I use this?" test

### Version Everything
> Requirements change. Track why.

- Changelog in every spec
- Git history for everything
- Never delete, deprecate

---

## Adding New Principles

When you learn something, capture it:

1. State the principle as an imperative
2. Add a memorable quote/maxim
3. Explain why it matters
4. Cite the source (book, experience, research)

Example:
```markdown
### Principle Name
> Memorable one-liner

Explanation of what this means in practice.

Source: Where you learned this
```

# Domain: Healthcare

Pre-researched principles and token recommendations for healthcare applications.

---

## Domain Context

**Industry**: Healthcare, Life Sciences, Clinical
**Users**: Clinicians, researchers, healthcare administrators, patients
**Environment**: Hospitals, clinics, research labs, often on shared workstations
**Emotional Goal**: Trust, calm, clarity, professionalism

---

## Experts & Legends

| Expert | Contribution | Key Insight |
|--------|--------------|-------------|
| Jakob Nielsen | Usability heuristics | Error prevention over error recovery |
| Don Norman | Human-centered design | Affordances must be obvious |
| Braille Institute | Atkinson Hyperlegible | Accessibility benefits everyone |
| HIMSS | Healthcare IT standards | Interoperability, privacy first |
| ONC | EHR usability | Reduce cognitive load in clinical workflows |

---

## Domain Principles

### 1. First, Do No Harm
> Error states must be impossible to miss.

Clinical decisions happen fast. UI must prevent errors, not just report them.
- Destructive actions require confirmation
- Critical alerts use red + icon + text (never color alone)
- No "are you sure?" fatigue — but truly irreversible = explicit confirmation

### 2. Trust Through Calm
> Quiet confidence, not alarm.

Healthcare workers are already stressed. UI should reduce anxiety.
- Muted, professional colors (no harsh primaries)
- Generous whitespace
- Progress indicators reduce uncertainty

### 3. Glanceability
> Critical info visible in 3 seconds.

Borrowed from ER triage: severity at a glance.
- Status indicators visible without interaction
- Traffic light pattern (green/yellow/red) for health states
- Large, clear typography

### 4. Accessibility is Non-Negotiable
> Design for the extremes.

Clinical environments have diverse users and conditions.
- High contrast for bright clinical lighting
- Works with screen readers (HIPAA often requires)
- Large touch targets for gloved hands

### 5. Privacy by Design
> Assume someone is looking over your shoulder.

Shared workstations, busy hallways.
- Session timeouts
- Minimal PHI visible at once
- Clear "lock screen" affordance

---

## Prior Art

### Clinical Systems to Study

| System | Strength | Pattern |
|--------|----------|---------|
| Epic | Workflow optimization | Role-based dashboards |
| Cerner | Order entry | Smart defaults |
| Doximity | Physician UX | Mobile-first, quick actions |

### Adjacent Inspiration

| Source | Relevance | Pattern |
|--------|-----------|---------|
| Air traffic control | No ambiguity | Explicit confirmations |
| ER triage boards | Glanceability | Color-coded severity |
| Calm app | Anxiety reduction | Breathing room, soft colors |

### Anti-Patterns

| Source | Problem | Avoid |
|--------|---------|-------|
| Legacy EHRs | Information overload | 50 fields on one screen |
| Alert fatigue | Too many warnings | Every alert feels critical |
| Complex navigation | Deep hierarchies | More than 3 clicks to common actions |

---

## Token Recommendations

### Typography

| Role | Recommendation | Why |
|------|----------------|-----|
| Primary | Atkinson Hyperlegible | Designed for accessibility, Braille Institute |
| Alternative | IBM Plex Sans | Medical/technical credibility |
| Mono | JetBrains Mono | Lab values, codes |

### Color Palette

| Token | Value | Rationale |
|-------|-------|-----------|
| Primary | Indigo-600 (#4F46E5) | Professional, calm, not clinical blue |
| Success | Emerald-600 (#059669) | Healthy, positive, universal meaning |
| Warning | Amber-500 (#F59E0B) | Attention without alarm |
| Danger | Rose-600 (#E11D48) | Clear alert, distinct from pink |
| Neutral | Slate-600 (#475569) | Readable, warm gray |

### Health Status Tokens

| Status | Background | Text | Icon | Use |
|--------|------------|------|------|-----|
| Healthy | Emerald-50 | Emerald-700 | ✓ check | No action needed |
| Attention | Amber-50 | Amber-700 | ⚠ alert | Review soon |
| At-Risk | Rose-50 | Rose-700 | ! exclamation | Act now |
| Unknown | Slate-100 | Slate-600 | ? question | Data pending |

### Spacing

Healthcare UIs often cramped — err toward generous spacing.

| Recommendation | Rationale |
|----------------|-----------|
| 8px base unit | Consistent scale |
| 24px card padding | Breathing room |
| 32px section gaps | Clear groupings |

---

## Domain-Specific Components

### Patient/Account Status Badge
Three-level indicator with clear meaning:
```
[●] Healthy    — green, checkmark
[●] Attention  — amber, warning icon
[●] At-Risk    — red, exclamation
```

### Clinical Alert Banner
For critical information:
```
┌─────────────────────────────────────────────────────┐
│ ⚠ [ALERT TYPE]: Message text            [Action]   │
└─────────────────────────────────────────────────────┘
```
- Always includes icon + text
- Always includes action or dismiss
- Color indicates severity

### PHI-Aware Display
For sensitive information:
```
┌─────────────────────────────────────────────────────┐
│ Patient: J*** D**         [Show Full] [Lock]       │
└─────────────────────────────────────────────────────┘
```
- Masked by default in shared environments
- Explicit action to reveal
- Easy re-lock

---

## Accessibility Minimums

| Requirement | Target | Non-Negotiable |
|-------------|--------|----------------|
| Color contrast | 4.5:1 | Yes |
| Touch targets | 44x44px | Yes |
| Keyboard navigation | Full | Yes |
| Screen reader | WCAG 2.1 AA | Yes |
| Reduced motion | Respected | Yes |

---

## Sources

- Braille Institute: Atkinson Hyperlegible font
- HIMSS: Healthcare IT best practices
- ONC: EHR usability standards
- Jakob Nielsen: Medical usability research
- WCAG 2.1: Accessibility guidelines

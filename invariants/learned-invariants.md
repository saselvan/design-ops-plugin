# Learned Invariants

Automatically captured learnings from Ralph executions, promoted from project-local to global scope.

---

## Invariants

<!-- New invariants are appended below this line -->

### INV-L001: Route Coverage

**Source:** SA Assistant / PRP-2026-01-22-001
**Date:** 2026-01-23

**Rule:** Every internal link (`href`) in UI components must have a corresponding route handler.

**Context:** When building SPAs with client-side routing (Dash, React Router, etc.), components often include links to other pages. If the route handler doesn't exist, users see "Page not found".

**Example:**
- Component has `dcc.Link(href="/account/Providence")`
- Router must handle `/account/{name}` pattern
- Test must verify the link actually navigates successfully

**Validation:**
1. Extract all `href=` values from components (excluding external URLs)
2. Verify each has a matching route in the router/callback
3. Playwright click test: click link → verify page loads (not "Page not found")

**PRP Integration:** Final gate must include route coverage check - all internal hrefs tested.

---

### INV-L002: Filter Logic Must Handle Edge Cases

**Source:** SA Assistant / PRP-2026-01-22-001
**Date:** 2026-01-23

**Rule:** Date/time filters must explicitly handle negative values and lifecycle states.

**Context:** When filtering by "days until X", negative values (past dates) satisfy `<= N` comparisons. When filtering active items, closed/completed items must be explicitly excluded.

**Anti-patterns:**
```python
# BAD: Negative days pass the filter
soon_closing = [uc for uc in usecases if uc.get('days_until_close') <= 14]

# BAD: Includes completed items
active_items = [x for x in items if x.get('priority') == 'high']
```

**Correct patterns:**
```python
# GOOD: Require positive days (future) AND active stage
soon_closing = [
    uc for uc in usecases
    if uc.get('stage') in ACTIVE_STAGES
    and 0 < uc.get('days_until_close', 999) <= 14
]
```

**Validation:**
1. Test with items that have past dates (negative days)
2. Test with items in terminal states (closed, live, cancelled)
3. Verify filter excludes both

**PRP Integration:** PRPs must define explicit lifecycle stages and which are "active" vs "terminal".


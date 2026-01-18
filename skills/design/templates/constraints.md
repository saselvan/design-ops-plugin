# Constraints: {project-name}

id: CONSTRAINTS-{project}
date: {YYYY-MM-DD}

---

## Technical Boundaries

| Constraint | Value | Impact on Design |
|------------|-------|------------------|
| Stack | {e.g., React + Tailwind} | {implications} |
| Deployment | {e.g., Vercel, Databricks Apps} | {limitations} |
| Auth | {e.g., SSO, custom} | {what to build/skip} |
| API | {e.g., REST, GraphQL} | {data patterns} |
| Offline | {required/not required} | {caching needs} |
| Browser Support | {modern only / IE11} | {CSS/JS constraints} |

---

## Performance Budgets

| Metric | Target | Hard Limit | Measurement |
|--------|--------|------------|-------------|
| First Contentful Paint | {e.g., <1.5s} | {e.g., <3s} | Lighthouse |
| Time to Interactive | {e.g., <2s} | {e.g., <4s} | Lighthouse |
| Bundle Size (JS) | {e.g., <200KB} | {e.g., <500KB} | Build output |
| Bundle Size (CSS) | {e.g., <50KB} | {e.g., <100KB} | Build output |
| API Response | {e.g., <500ms} | {e.g., <2s} | p95 latency |

---

## Resource Constraints

| Resource | Reality | Design Impact |
|----------|---------|---------------|
| Timeline | {e.g., 2 weeks to MVP} | {scope implications} |
| Team | {e.g., Solo} | {no handoff docs, optimize for flow} |
| Budget | {e.g., $0 infra} | {what services to avoid} |
| Maintenance | {e.g., Low-touch} | {boring tech, no clever hacks} |

---

## Dependencies & Risks

| Dependency | Status | Mitigation |
|------------|--------|------------|
| {API/service} | ✅ Ready / ⚠️ Partial / ❌ Not built | {fallback plan} |
| {API/service} | | |
| {API/service} | | |

---

## Non-Negotiables

Things that MUST be true regardless of other constraints:

- [ ] {e.g., WCAG 2.1 AA accessibility}
- [ ] {e.g., Works on target screen size}
- [ ] {e.g., No loading spinners > 2s without progress}
- [ ] {e.g., Errors are actionable}
- [ ] {add more...}

---

## Explicit Descopes

Things we are NOT building (prevent scope creep):

- ❌ {e.g., Mobile app}
- ❌ {e.g., Multi-user collaboration}
- ❌ {e.g., Offline support}
- ❌ {e.g., Custom theming}
- ❌ {e.g., Internationalization}
- ❌ {add more...}

---

## Validation

Specs will be checked against these constraints. If a spec violates a constraint, it must either:
1. Be revised to fit constraints
2. Get explicit exception approval with rationale

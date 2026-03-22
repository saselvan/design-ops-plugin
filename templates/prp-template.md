# PRP Template v3.1 (Domain-Aware)

> Product Requirements Prompt — defines WHAT must be true when we're done.
> Vertical slicing (the HOW) happens in `/prp-to-issues`, not here.
> This template has CORE sections (always required) and DOMAIN EXTENSIONS (loaded per project).

---

## Meta

```yaml
prp_id: {{PRP_ID}}           # Format: PRP-YYYY-MM-DD-XXX
domain: {{DOMAIN}}            # From .designops config or --domain flag
confidence_score: {{SCORE}}   # 1.0-10.0 (RED < 4 = HARD STOP)
confidence_breakdown:
  requirement_clarity: {{RC}}  # 0.0-1.0 (weight: 30%)
  pattern_availability: {{PA}} # 0.0-1.0 (weight: 25%)
  test_coverage_plan: {{TC}}   # 0.0-1.0 (weight: 20%)
  edge_case_handling: {{EC}}   # 0.0-1.0 (weight: 15%)
  tech_familiarity: {{TF}}     # 0.0-1.0 (weight: 10%)
risk_level: {{RISK}}          # Red (1-3) | Yellow (4-6) | Green (7-9)
tier: {{TIER}}                # medium | large
discovery_log: {{PATH}}       # Path to decisions log (LARGE tier only, optional)
```

---

## 1. Problem & Solution

### What's broken

{{PROBLEM_STATEMENT}}

<!-- Be specific. "Users abandon checkout at 47% when shipping > 5 days" not "checkout needs improvement" -->

### What we're building

{{SOLUTION_SUMMARY}}

<!-- One paragraph. WHAT, not HOW. -->

### Scope

| In Scope | Out of Scope |
|----------|--------------|
| {{IN_1}} | {{OUT_1}} |
| {{IN_2}} | {{OUT_2}} |

<!-- INVARIANT #6: Scope must be bounded -->

---

## 2. Success Criteria

### Conditions (all must be true)

```
SUCCESS := ALL(
  {{CONDITION_1}},
  {{CONDITION_2}},
  {{CONDITION_3}}
)
```

### Failure Conditions (any triggers stop)

```
FAILURE := ANY(
  {{FAILURE_1}},
  {{FAILURE_2}}
)
```

### Metrics

| Metric | Current | Target | How to measure | Provable by test? |
|--------|---------|--------|---------------|-------------------|
| {{M1}} | {{C1}} | {{T1}} | {{HOW_1}} | Yes / No (observe in prod) |

<!-- INVARIANT #7: Every criterion must be measurable -->
<!-- Mark which criteria are provable by tests vs. require production observation -->
<!-- This feeds the completion summary in /design build -->

---

## 3. Scope & Dependencies

<!-- This section defines the COMPONENTS and their RELATIONSHIPS. -->
<!-- It does NOT define vertical slices — that happens in /prp-to-issues. -->

### Components

| Component | Responsibility | New or Modified |
|-----------|---------------|----------------|
| {{COMP_1}} | {{RESP_1}} | {{NEW_MOD_1}} |
| {{COMP_2}} | {{RESP_2}} | {{NEW_MOD_2}} |
| {{COMP_3}} | {{RESP_3}} | {{NEW_MOD_3}} |

### Dependency Map

```
{{COMP_1}} → {{COMP_2}} (produces: {{DATA_FLOW}})
{{COMP_2}} → {{COMP_3}} (produces: {{DATA_FLOW}})
{{COMP_3}} → external: {{EXTERNAL_DEP}} (fallback: {{FALLBACK}})
```

### Component Contracts

<!-- Define interfaces between components. Integration tests verify these. -->

```
{{COMP_1}} OUTPUT CONTRACT:
  {
    {{field}}: {{type}},  // {{constraint}}
  }
  CONSUMERS: {{COMP_2}}, {{COMP_3}}
  BREAKING CHANGES: {{what would break consumers}}
```

<!-- INVARIANT #9: Blast radius declared for each component -->

---

## 4. Risks & Fallbacks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| {{RISK_1}} | {{PROB_1}} | {{IMPACT_1}} | {{MIT_1}} |
| {{RISK_2}} | {{PROB_2}} | {{IMPACT_2}} | {{MIT_2}} |

### Circuit Breakers

```
IF {{TRIGGER_1}}:
  THEN {{ACTION_1}}

IF {{TRIGGER_2}}:
  THEN {{ACTION_2}}
```

<!-- INVARIANT #4: Destructive actions must have recovery -->
<!-- INVARIANT #10: External deps must have fallbacks -->

---

## 5. Validation Commands

Copy-pasteable commands to verify the implementation works.

### Integration Verification

```bash
# Do the components work TOGETHER?
{{INTEGRATION_TEST_CMD}}
```

### E2E Smoke Test

<!-- Domain-specific. See .designops e2e config. -->

```bash
# Full user workflow — does the system ACTUALLY WORK end-to-end?
# Tool: {{E2E_TOOL}}  Time budget: {{TIME_BUDGET}}
{{E2E_SMOKE_TEST_CMD}}
```

### Build & Quality

```bash
# Type checking
{{TYPECHECK_CMD}}

# Lint
{{LINT_CMD}}

# Build
{{BUILD_CMD}}
```

---

## 6. Invariant Checklist

<!-- Filled by the PRP generator. Confirms each applicable invariant is addressed. -->

### Universal (blocking)

- [ ] #1 Ambiguity: All terms have operational definitions
- [ ] #2 State: All state transitions documented (before→action→after)
- [ ] #3 Emotion: No uncompiled emotional intent
- [ ] #4 Recovery: All destructive actions have escape hatches
- [ ] #5 Fail Loudly: No silent failures
- [ ] #6 Bounded: No unbounded operations
- [ ] #7 Executable: All criteria are measurable
- [ ] #8 Cost: Resource consumption has limits
- [ ] #9 Blast Radius: All write ops declare scope
- [ ] #10 Degradation: External deps have fallbacks

### Domain: {{DOMAIN}} (advisory unless healthcare/security)

- [ ] {{DOMAIN_INV_1}}
- [ ] {{DOMAIN_INV_2}}

---

# DOMAIN EXTENSIONS

<!-- Include the relevant extension below based on .designops config. Delete the others. -->

## Extension: Healthcare / HLS

> Load when: PHI, clinical data, HIPAA, FDA, or compliance-critical work.
> **All invariants in this extension are BLOCKING, not advisory.**

### Compliance Requirements

| Regulation | Applicability | How addressed |
|-----------|--------------|---------------|
| {{REG_1}} | {{APPLIES_1}} | {{ADDRESS_1}} |

### PHI Handling

```
PHI_FLOW:
  ingestion → {{DE_ID_METHOD}} → storage ({{ENCRYPTION}}) → access ({{AUTH_MODEL}})

AUDIT_TRAIL := ALL access logged with: who, when, what, why
BREACH_PROTOCOL := {{BREACH_RESPONSE}}
```

### Data Governance

| Data Element | Classification | Retention | Access Control |
|-------------|---------------|-----------|----------------|
| {{DATA_1}} | {{CLASS_1}} | {{RETAIN_1}} | {{ACCESS_1}} |

### E2E Definition (Healthcare)

```bash
# Pipeline run + verify PHI absent from output + audit log populated
# Tool: pytest  Time budget: 120-600s
{{HEALTHCARE_E2E_CMD}}
```

---

## Extension: Data Architecture

> Load when: Pipelines, warehouses, analytics, ETL/ELT, Databricks.

### Pipeline Contract

```
SOURCE → {{TRANSFORM}} → SINK
SLA: {{LATENCY}} / {{THROUGHPUT}}
SCHEMA_EVOLUTION: {{STRATEGY}}  # additive | breaking-with-migration | versioned
```

### Data Quality Gates

| Check | Threshold | Action on Failure |
|-------|-----------|-------------------|
| {{DQ_CHECK_1}} | {{DQ_THRESH_1}} | {{DQ_ACTION_1}} |

### Lineage & Observability

```
LINEAGE_TRACKED := {{YES_NO}}
MONITORING := {{DASHBOARD_OR_ALERTS}}
REPLAY_CAPABILITY := {{YES_NO_HOW}}
```

### E2E Definition (Data)

```bash
# Run pipeline with test data → verify output schema + row counts + quality
# Tool: pytest / notebook  Time budget: 60-300s
{{DATA_E2E_CMD}}
```

---

## Extension: Consumer Product

> Load when: Mobile/web apps, consumer-facing features.

### Accessibility

- Keyboard navigation for all interactions
- Screen reader compatible (semantic HTML, ARIA)
- Color contrast >= 4.5:1
- Touch targets >= 44x44px
- No information conveyed by color alone

### Performance Budgets

| Metric | Budget |
|--------|--------|
| LCP | {{LCP_TARGET}} |
| FID | {{FID_TARGET}} |
| Bundle size | {{BUNDLE_TARGET}} |

### E2E Definition (Consumer)

```bash
# Playwright browser test through critical user path
# Tool: playwright  Time budget: 30-120s
{{CONSUMER_E2E_CMD}}
```

---

## Extension: Integration

> Load when: APIs, webhooks, third-party services.

### API Contract

```
ENDPOINT: {{METHOD}} {{PATH}}
REQUEST: {{REQUEST_SCHEMA}}
RESPONSE: {{RESPONSE_SCHEMA}}
ERRORS: {{ERROR_CODES}}
RATE_LIMIT: {{LIMIT}}
AUTH: {{AUTH_METHOD}}
```

### Retry & Circuit Breaker

```
RETRY := {{MAX_RETRIES}} with {{BACKOFF_STRATEGY}}
CIRCUIT_BREAKER := open after {{THRESHOLD}} failures, half-open after {{COOLDOWN}}
FALLBACK := {{FALLBACK_BEHAVIOR}}
```

### E2E Definition (Integration)

```bash
# Request → response → verify contract + side effects
# Tool: pytest / curl  Time budget: 15-60s
{{INTEGRATION_E2E_CMD}}
```

---

## Extension: Physical Construction

> Load when: Buildings, infrastructure, remote construction management.

### Material Specifications

| Material | Standard | Test Required | Acceptance Criteria |
|----------|----------|--------------|-------------------|
| {{MAT_1}} | {{STD_1}} | {{TEST_1}} | {{CRITERIA_1}} |

### Inspection Gates

| Gate | When | Who | Pass Criteria |
|------|------|-----|--------------|
| {{GATE_1}} | {{WHEN_1}} | {{WHO_1}} | {{PASS_1}} |

### E2E Definition (Construction)

```
# Manual inspection checklist — no automated e2e
# Completed by: {{INSPECTOR}}
# Frequency: at each inspection gate
```

---

*Template version: 3.1*
*Last updated: 2026-03-22*

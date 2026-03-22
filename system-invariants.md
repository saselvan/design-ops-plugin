# System Invariants v1.0

Last Updated: 2026-01-19
Purpose: Non-negotiable principles enforced by PRP compiler

---

## Core Philosophy

- Invariants come from pain, not theory
- Violations are **REJECTED**, not fixed
- Spec Delta feeds back into invariants
- Every invariant must have enforcement mechanism

This is a **compiler for human intent**. Specs are programs. Invariants are the type system.

---

## Structure

```
system-invariants.md          ← You are here (Universal Core)
├── domains/
│   ├── consumer-product.md   ← Mobile apps, web apps, consumer-facing
│   ├── physical-construction.md ← Buildings, infrastructure
│   ├── data-architecture.md  ← Pipelines, warehouses, analytics
│   ├── integration.md        ← APIs, webhooks, third-party services
│   ├── remote-management.md  ← Projects managed from distance
│   └── skill-gap-transcendence.md ← Unknown tech, learning-intensive projects
└── enforcement/
    ├── validator.sh          ← Automated invariant checking
    └── violation-messages.md ← Human-readable error templates
```

---

## UNIVERSAL INVARIANTS (Apply to All Domains)

### 1. Ambiguity is Invalid

**Principle**: Every term must have operational definition

**Violation**: Subjective terms without objective criteria

**Examples**:
- ❌ "Process data properly"
- ❌ "Make it user-friendly"
- ❌ "Build with quality materials"
- ✅ "Validate data against schema v2.1, reject if malformed, log to error_queue"
- ✅ "3-tap maximum, <10 sec completion, voice input fallback"
- ✅ "M25 concrete, 28-day cure, compression test ≥25 N/mm²"

**Enforcement**: Regex flags "properly", "easily", "good", "quality", "intuitive" without objective criteria → REJECT

---

### 2. State Must Be Explicit

**Principle**: Every state transition must be documented

**Violation**: Implicit state changes, hidden side effects

**Examples**:
- ❌ "Update user preferences"
- ❌ "Start construction"
- ❌ "Sync data"
- ✅ "user.preferences := {theme: dark} → trigger cache_invalidation → notify_ui"
- ✅ "foundation.state := CURING (28 days) → block column_work → enable inspection_gate"
- ✅ "meal.state := LOGGED → increment daily_total → queue cloudkit_sync if online"

**Enforcement**: Every verb must have: before-state → action → after-state. Missing state declaration → REJECT

---

### 3. Emotional Intent Must Compile

**Principle**: Feelings must map to enforceable mechanisms

**Violation**: Emotion words without implementation spec

**Examples**:
- ❌ "Users should feel confident"
- ❌ "Design should feel premium"
- ❌ "Construction should feel solid"
- ✅ "User confidence := display success_rate (90%+) + show undo_option + provide preview"
- ✅ "Premium feel := haptic_feedback + 60fps_animation + material_shadows"
- ✅ "Structural confidence := engineer_signoff + compression_test_pass + 10yr_warranty"

**Enforcement**: Emotion words (feel, should, comfortable, confident) must be followed by `:=` and concrete mechanism → Otherwise REJECT

---

### 4. No Irreversible Actions Without Recovery

**Principle**: Every destructive action must have escape hatch

**Violation**: Delete/destroy without undo/backup/recovery

**Examples**:
- ❌ "Delete user account"
- ❌ "Pour concrete"
- ❌ "Drop production table"
- ✅ "Delete user account → soft_delete (30-day retention) → hard_delete_after_30d"
- ✅ "Pour concrete → require engineer_approval + test_batch_first + allow 24h for issues"
- ✅ "Drop table → backup_to_s3 + require manual_confirmation + 7-day restore_window"

**Enforcement**: Destructive verbs (delete, drop, remove, destroy, demolish) must specify: recovery mechanism + time window → Otherwise REJECT

---

### 5. Execution Must Fail Loudly

**Principle**: Errors must be observable and actionable

**Violation**: Silent failures, swallowed exceptions, unclear errors

**Examples**:
- ❌ "Handle errors gracefully"
- ❌ "Try to continue if possible"
- ❌ "Log error and move on"
- ✅ "ValidationError → block execution + display specific_failure + require human_decision"
- ✅ "Concrete_slump_test_fail → stop_pour + alert_engineer + document_in_log"
- ✅ "API_timeout → retry 3x + circuit_breaker_open + alert_oncall"

**Enforcement**: Every error path must specify: detection + alerting + blocking behavior. "Gracefully" or "silently" → REJECT

---

### 6. Scope Must Be Bounded

**Principle**: No unbounded operations on files/data/structures

**Violation**: "All", "everything", unlimited iteration

**Examples**:
- ❌ "Process all user records"
- ❌ "Load entire dataset"
- ❌ "Build using all available materials"
- ✅ "Process users in batches of 1000, max 100K records, timeout 5min per batch"
- ✅ "Load last 30 days of data, max 10GB, paginate at 1000 rows"
- ✅ "Use approved_materials_list (15 items), validate availability before spec"

**Enforcement**: Keywords "all", "everything", "entire" must specify: max_count OR max_size OR max_time OR pagination → Otherwise REJECT

---

### 7. Validation Must Be Executable

**Principle**: Success criteria must be measurable by code or process

**Violation**: Subjective validation, human-only checks

**Examples**:
- ❌ "Ensure quality is good"
- ❌ "Verify it looks right"
- ❌ "Confirm structure is sound"
- ✅ "Quality := unit_tests_pass (100%) + coverage ≥80% + lint_score ≥9.0"
- ✅ "Visual correctness := screenshot_diff <2% + accessibility_score ≥90"
- ✅ "Structural soundness := compression_test ≥25 N/mm² + ultrasonic_test_pass"

**Enforcement**: Validation criteria must include: metric + threshold + measurement_method. Subjective terms without metrics → REJECT

---

### 8. Cost Boundaries Must Be Explicit

**Principle**: Every resource consumption must have upper limit

**Violation**: Unbounded API calls, storage, compute, money

**Examples**:
- ❌ "Fetch data from API"
- ❌ "Store user uploads"
- ❌ "Order materials as needed"
- ✅ "API calls: max 1000/day, $10 budget, circuit_breaker at 5 consecutive failures"
- ✅ "Storage: 100MB per user, 10GB total, archive after 90 days"
- ✅ "Materials: ₹15L budget, 10% contingency, approval required >₹50K"

**Enforcement**: External calls, storage, purchases must specify: limit + budget + circuit_breaker → Otherwise REJECT

---

### 9. Blast Radius Must Be Declared

**Principle**: Every operation must state what it affects

**Violation**: Unknown or unspecified impact scope

**Examples**:
- ❌ "Update configuration"
- ❌ "Modify foundation"
- ❌ "Change database schema"
- ✅ "Update config → affects: single_service + restart_required + no_user_impact"
- ✅ "Foundation change → affects: entire_structure + 8-week_delay + ₹2L_rework_cost"
- ✅ "Schema change → affects: 3_services + migration_required + 2hr_downtime"

**Enforcement**: Write operations must declare: affected_scope + dependencies + recovery_cost → Otherwise REJECT

---

### 10. Degradation Path Must Exist

**Principle**: External dependencies must have fallback

**Violation**: Hard dependency without graceful failure

**Examples**:
- ❌ "Fetch weather from API"
- ❌ "Use contractor's materials"
- ❌ "Sync to cloud storage"
- ✅ "Weather API (timeout: 2s) → fallback: cached_last_known → fallback: manual_entry"
- ✅ "Contractor materials → fallback: approved_alternative_list → fallback: client_approval_required"
- ✅ "Cloud sync → fallback: local_queue → fallback: manual_export_csv"

**Enforcement**: External dependencies must specify: primary + fallback1 + fallback2 OR explicit_fail → Otherwise REJECT

---

### 11. Accessibility is Non-Negotiable

**Principle**: All user interfaces must be usable by everyone

**Violation**: UI without accessibility considerations, inaccessible interactions

**Examples**:
- ❌ "Add a button to submit"
- ❌ "Show error in red"
- ❌ "Click to expand details"
- ✅ "Submit button: keyboard_focusable + aria_label + min_touch_target_44px"
- ✅ "Error display: red_text + icon_indicator + aria_live_announce + contrast_ratio_4.5:1"
- ✅ "Expandable section: keyboard_enter_to_toggle + aria_expanded_state + screen_reader_announce"

**Standards**:
- WCAG 2.1 AA as baseline
- Keyboard navigation for all interactions
- Screen reader compatibility (semantic HTML, ARIA labels)
- Color contrast ratio ≥ 4.5:1 for text
- Touch targets ≥ 44x44px on mobile
- No information conveyed by color alone

**Enforcement**: UI components must specify: keyboard_access + screen_reader_support + contrast_compliance. UI without accessibility declaration → REJECT

---

### TYPE-001: Single Type Source

**Principle**: A codebase MUST have exactly ONE canonical location for database/domain types.

**Violation**: Same interface defined in multiple files

**Examples**:
- ❌ `TradeShowOrderLine` defined in `order-queue.tsx`, `order-review.tsx`, AND `line-editor.tsx`
- ❌ Two type files: `database.types.ts` (auto-generated) vs `database.ts` (manual)
- ✅ `src/types/trade-show-orders.ts` - single source, imported by all consumers

**Enforcement**: 
```bash
# Count interface definitions - should be exactly 1 per entity
grep -r "interface TradeShowOrder" src/ | wc -l
# If > 1 → REJECT
```

**Prevention**: 
- Create `/src/types/{domain}.ts` for each domain
- Export from `/src/types/index.ts`
- Lint rule: No inline interface redefinition

---

### TYPE-002: Schema-Type Parity

**Principle**: TypeScript interfaces MUST include ALL fields from database schema, with matching nullability.

**Violation**: Schema has 11 fields, TypeScript interface has 9

**Examples**:
- ❌ Schema: `image_url TEXT NOT NULL`, TypeScript: `image_url: string | null`
- ❌ Schema: `extraction_notes JSONB`, TypeScript: missing entirely
- ✅ Every schema field present in TypeScript with exact nullability

**Enforcement**:
```bash
# Compare schema to types during CI
# OR generate types from schema: npx supabase gen types
```

**Prevention**:
- Generate types from schema (don't hand-write)
- Code review: Check schema SQL against TypeScript interface
- Automated diff in CI pipeline

---

### TYPE-003: No `as any` for Known Tables

**Principle**: Supabase queries for tables defined in schema MUST NOT use `as any` type assertions.

**Violation**: Using `as any` to bypass type checking instead of fixing types

**Examples**:
- ❌ `supabase.from('trade_show_orders' as any).select(...)`
- ❌ `supabase.from('known_table' as any)`
- ✅ `supabase.from('trade_show_orders').select(...)` with proper types

**Enforcement**:
```bash
# Grep for as any on .from() calls
grep -r "from('.*' as any)" src/
# If any found → REJECT
```

**Prevention**:
- ESLint rule: `@typescript-eslint/no-explicit-any` with exceptions only for truly unknown data
- Fix type definitions at source, don't workaround with `as any`

---

### FRAME-001: Framework Version Awareness

**Principle**: Before implementing API routes, verify framework version-specific requirements.

**Violation**: Using old patterns after framework upgrade

**Examples**:
- ❌ Next.js 16: `{ params }: { params: { id: string } }` (old signature)
- ✅ Next.js 16: `{ params }: { params: Promise<{ id: string }> }` + `await params`

**Enforcement**:
```bash
# Check package.json for version
# Verify API routes use correct signature
grep -r "params:" src/app/api/ | grep -v "Promise<" | grep -v "await params"
# If any found in Next.js 16+ → REJECT
```

**Prevention**:
- Document version requirements in CONVENTIONS.md
- Add version check to Ralph task generator
- Automated migration scripts for framework upgrades

---

### DESIGN-001: Deep Modules

**Principle**: Modules must have small interfaces and deep implementations (Ousterhout, "A Philosophy of Software Design").

**Violation**: Wide interface with shallow implementation — lots of knobs exposed, little work done inside.

**Examples**:
- ❌ Helper function that takes 8 params and does a 3-line transform
- ❌ Component with 12 props that just wraps another component
- ❌ Service class where every internal method is public
- ✅ `processOrder(orderId)` — one input, handles validation/state/persistence/notification internally
- ✅ `<PhotoImporter seasonId={id} />` — small surface, handles upload/resize/classify/link inside

**Enforcement**: During code review and `/design build`, flag modules where interface complexity ≥ implementation complexity. Public API surface should be small relative to internal logic. Wide-and-shallow → REFACTOR.

---

### GEN-001: Clean Code Generation

**Principle**: When using CLI tools to generate code files, stderr must be separated from stdout.

**Violation**: npm warnings or errors written to generated code file

**Examples**:
- ❌ `npx supabase gen types > file.ts` (captures warnings)
- ❌ Line 1 of generated file: `npm warn exec...`
- ✅ `npx supabase gen types --output file.ts 2>/dev/null`
- ✅ `npx supabase gen types 2>/dev/null > file.ts`

**Enforcement**:
```bash
# Check first line of generated files for npm warnings
head -1 file.ts | grep -q "npm warn" && REJECT
```

**Prevention**:
- Always redirect stderr: `2>/dev/null` or `--output` flag
- Validate generated files before commit
- Use tool's native output flag when available

---

## How Invariants Are Used

| Artifact | Invariant Role |
|----------|----------------|
| Specs | Must not violate any invariant |
| PRPs | Compiler rejects if invariant violated |
| Probes | Can surface invariant violations early |
| Spec Delta | Violations become new invariants |

### Enforcement Layers

```
Layer 1: Static Analysis (Pre-PRP)
  - Parse spec for invariant violations
  - Reject with specific violation message
  - No PRP generation on failure

Layer 2: Execution Probe (Pre-Implementation)
  - Test invariant assumptions in real environment
  - Surface violations early
  - Update spec before full implementation

Layer 3: Runtime Validation (During Implementation)
  - Generated code includes invariant checks
  - Fail loudly on violation
  - Log violation for Spec Delta

Layer 4: Spec Delta (Post-Mortem)
  - Capture new invariant from failure
  - Add to appropriate domain file
  - Validate against historical specs
```

---

## Domain Selection

Choose domains based on project type:

| Project Type | Load These Domains |
|--------------|-------------------|
| Mobile/web app | consumer-product.md |
| iOS calorie tracker | consumer-product.md |
| Data pipeline | data-architecture.md |
| API integration | integration.md |
| House construction | physical-construction.md + remote-management.md |
| LineSheet Pro | consumer-product.md + data-architecture.md + integration.md |
| New tech demo | skill-gap-transcendence.md |
| Stretch assignment | skill-gap-transcendence.md + relevant domain |
| Conference presentation | skill-gap-transcendence.md (invariant 39) |
| Learning-intensive project | skill-gap-transcendence.md |

Multiple domains can be combined. All specs must pass core invariants (1-10) plus selected domain invariants.

---

## Adding New Invariants

New invariants come from Spec Deltas only. Process:

1. Execution failure occurs
2. Spec Delta identifies root cause
3. If cause is a class of problem (not one-off), propose invariant
4. Add to appropriate domain file with:
   - Pain source (incident/failure that triggered it)
   - Violation example
   - Valid example
   - Enforcement mechanism
5. Update validator.sh to enforce

**Never add invariants from theory — only from pain.**

---

## Quick Reference

| # | Invariant | Key Test |
|---|-----------|----------|
| 1 | Ambiguity is Invalid | No "properly", "easily", "quality" without definition |
| 2 | State Must Be Explicit | Every verb has before→action→after |
| 3 | Emotional Intent Must Compile | "Feel X" becomes ":= concrete mechanism" |
| 4 | No Irreversible Without Recovery | Destructive verbs have undo/backup |
| 5 | Execution Must Fail Loudly | No "gracefully" or "silently" |
| 6 | Scope Must Be Bounded | No "all" without limits |
| 7 | Validation Must Be Executable | Metrics + thresholds, not "looks good" |
| 8 | Cost Boundaries Must Be Explicit | Limits on API/storage/money |
| 9 | Blast Radius Must Be Declared | Write ops declare affected scope |
| 10 | Degradation Path Must Exist | External deps have fallbacks |
| 11 | Accessibility is Non-Negotiable | WCAG 2.1 AA, keyboard nav, screen readers |
| **TYPE-001** | **Single Type Source** | **Each interface appears exactly once** |
| **TYPE-002** | **Schema-Type Parity** | **All schema fields in TypeScript** |
| **TYPE-003** | **No `as any` for Known Tables** | **`.from()` without `as any`** |
| **FRAME-001** | **Framework Version Awareness** | **Correct params signature** |
| **DESIGN-001** | **Deep Modules** | **Small interface, deep implementation** |
| **GEN-001** | **Clean Code Generation** | **No stderr in generated files** |

---

*Last updated: 2026-02-01*
*Core invariants: 11*
*Type invariants: 3*
*Design invariants: 1*
*Framework invariants: 1*
*Generation invariants: 1*
*Domain invariants: See domain files*

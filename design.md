---
name: Design
description: Enhanced Design Ops workflow with invariant enforcement. USE WHEN design, spec, PRP, validate, requirements, init project, review implementation.
version: "1.0"
---

# Design Ops Skill

Enhanced design workflow that transforms human intent into agent-executable PRPs through invariant enforcement.

## Overview

This skill orchestrates the complete Design Ops workflow:

```
Spec (human intent)
    │
    ▼
┌─────────────────────┐
│  /design validate   │ ← Invariant checker (validator.sh)
│  Check against:     │
│  - Universal (1-10) │
│  - Domain-specific  │
└─────────────────────┘
    │
    │ PASS (0 violations)
    ▼
┌─────────────────────┐
│  /design prp        │ ← PRP generator (spec-to-prp.sh)
│  - Template select  │
│  - Context gather   │
│  - Variable sub     │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│  Quality Check      │ ← PRP checker (prp-checker.sh)
│  - Required sections│
│  - Quality score    │
└─────────────────────┘
    │
    ▼
Implementation → /design review → Compliance Report
```

## Agent

This skill is used by **Architect (Atlas)** for system design and **Engineer (Dev)** for implementation review.

## Command Reference

### /design init {project-name}

Bootstrap a new project with complete Design Ops structure.

**Usage:**
```
/design init my-new-feature
/design init house-build --domain physical-construction
/design init api-service --domain integration
```

**Execution:**

1. **Create folder structure:**
```
{project-name}/
├── docs/
│   └── design/
│       ├── research/           # Market research, user interviews
│       ├── personas/           # User persona definitions
│       ├── journeys/           # User journey maps
│       ├── specs/              # Feature specifications
│       ├── PRPs/               # Compiled Product Requirements Prompts
│       └── deltas/             # Post-execution learnings
├── CONVENTIONS.md              # Codebase conventions (if code exists)
└── README.md                   # Project overview
```

2. **Initialize templates:**
   - Copy spec template to `docs/design/specs/spec-template.md`
   - Copy PRP template to `docs/design/PRPs/prp-template.md`
   - Initialize empty `CONVENTIONS.md` if codebase exists

3. **Configure domain (if specified):**
   - Create `.designops` config file with domain reference
   - Note which domain invariants will apply

**Output:**
```
Created Design Ops structure for: {project-name}
├── docs/design/ (6 subdirectories)
├── CONVENTIONS.md (initialized)
└── .designops (config)

Domain: {domain | universal}
Invariants: Universal (1-10) + {domain-specific if applicable}

Next steps:
1. Add research to docs/design/research/
2. Define personas in docs/design/personas/
3. Create specs in docs/design/specs/
4. Run: /design validate docs/design/specs/your-spec.md
```

---

### /design validate {spec-file} [--domain domain-file]

Validate a specification against system invariants before PRP compilation.

**Usage:**
```
/design validate docs/design/specs/feature-spec.md
/design validate specs/mobile-app.md --domain consumer-product
/design validate specs/house-foundation.md --domain physical-construction --domain remote-management
```

**Execution:**

1. **Run validator.sh:**
```bash
./enforcement/validator.sh "{spec-file}" [--domain "{domain-file}"]
```

2. **Parse output for:**
   - Violations (blocking - must fix)
   - Warnings (non-blocking - should address)

3. **Report results with actionable fixes**

**Output (Pass):**
```
Validating: specs/my-feature.md

Checking Universal Invariants...
  [1] Ambiguity is Invalid........... PASS
  [2] State Must Be Explicit......... PASS
  [3] Emotional Intent Must Compile.. PASS
  [4] No Irreversible Without Recovery PASS
  [5] Execution Must Fail Loudly..... PASS
  [6] Scope Must Be Bounded.......... PASS
  [7] Validation Must Be Executable.. PASS
  [8] Cost Boundaries Explicit....... PASS
  [9] Blast Radius Declared.......... PASS
  [10] Degradation Path Exists....... PASS

Violations: 0
Warnings: 0

PASS - Spec ready for PRP compilation
Run: /design prp specs/my-feature.md
```

**Output (Fail):**
```
Validating: specs/my-feature.md

Checking Universal Invariants...
  [1] Ambiguity is Invalid........... FAIL

VIOLATION: Invariant #1 (Ambiguity is Invalid)
  Line 23: "Process data properly"
  Fix: Replace 'properly' with objective criteria: metric + threshold + measurement

VIOLATION: Invariant #3 (Emotional Intent Must Compile)
  Line 45: "Users should feel confident"
  Fix: Use format: emotion := concrete_mechanism (e.g., confident := show_success_rate + undo_option)

Violations: 2
Warnings: 0

REJECTED - Fix violations before proceeding
```

---

### /design prp {spec-file} [--output path] [--template type]

Generate a Product Requirements Prompt from a validated specification.

**Usage:**
```
/design prp specs/feature-spec.md
/design prp specs/api-spec.md --output PRPs/api-prp.md
/design prp specs/mobile-app.md --template user-feature
```

**Template options:**
- `base` - Generic PRP template (auto-detected by default)
- `api-integration` - Technical API/integration projects
- `user-feature` - Consumer-facing features
- `data-migration` - Database/data infrastructure projects

**Execution:**

1. **Validate spec first:**
```bash
./enforcement/validator.sh "{spec-file}" [--domain "{domain}"]
# Abort if violations found
```

2. **Gather context:**
   - Read spec content
   - Detect project type
   - Load CONVENTIONS.md if exists
   - Identify domain-specific requirements
   - Extract timeline hints
   - Extract key requirements

3. **Generate PRP:**
```bash
./enforcement/spec-to-prp.sh "{spec-file}" [--template type] [--output path]
```

4. **Run quality check:**
```bash
./enforcement/prp-checker.sh "{output-file}"
```

5. **Report confidence and next steps**

**Output:**
```
Spec-to-PRP Generation
======================

Reading spec: specs/my-feature.md
Validating... PASSED (0 violations, 2 warnings)

Extracting project information...
  Project: My Feature Name
  Type: user-feature (auto-detected)
  Timeline hint: 2 weeks

Loading template: user-feature
Substituting variables...
  - PRP_ID: PRP-2026-01-19-042
  - Project name: My Feature Name
  - Validation date: 2026-01-19
  - Remaining placeholders: 24

Running quality check...
  Required sections: PASS
  Quality score: 72/100

OUTPUT: PRPs/my-feature-prp.md

Placeholders to fill:
  Line 32: [FILL_THIS_IN] - Problem statement
  Line 48: [FILL_THIS_IN] - Primary metric
  Line 65: [FILL_THIS_IN] - Phase 1 owner
  ... and 21 more

Next steps:
1. Open PRPs/my-feature-prp.md
2. Fill all [FILL_THIS_IN] placeholders
3. Run: /design prp-check PRPs/my-feature-prp.md
4. Begin execution with validation gates
```

---

### /design review {spec-file} {implementation-path}

Review an implementation against its source specification for compliance.

**Usage:**
```
/design review specs/feature-spec.md ./src/feature/
/design review specs/api-spec.md ./api/ --check-conventions
```

**Execution:**

1. **Load spec requirements:**
   - Parse spec file for requirements (bullet points, acceptance criteria)
   - Extract validation criteria
   - Load CONVENTIONS.md if present

2. **Analyze implementation:**
   - Scan implementation path for relevant files
   - Check for test coverage
   - Look for validation commands
   - Check convention compliance

3. **Cross-reference:**
   - Map requirements to implementation
   - Identify gaps
   - Check edge case handling

4. **Run validation commands (if defined):**
   - Execute test suites
   - Check linting
   - Run type checks

5. **Generate compliance report**

**Output:**
```
Implementation Review
=====================

Spec: specs/feature-spec.md
Implementation: ./src/feature/

Requirements Coverage
---------------------
[ ] Requirement 1: User can submit form
    Status: IMPLEMENTED
    Files: src/feature/form.tsx, src/feature/submit.ts
    Tests: tests/feature/form.test.ts

[ ] Requirement 2: Form validates email format
    Status: IMPLEMENTED
    Files: src/feature/validation.ts
    Tests: tests/feature/validation.test.ts

[ ] Requirement 3: Error messages display inline
    Status: PARTIAL
    Files: src/feature/errors.tsx
    Missing: No test coverage for error display

[!] Requirement 4: Rate limit submissions
    Status: NOT IMPLEMENTED
    Note: No rate limiting found in codebase

Convention Compliance
--------------------
[x] TypeScript strict mode enabled
[x] ESLint rules passing
[x] Test coverage >= 80%
[ ] Component naming conventions - 2 violations
    - SubmitBtn.tsx should be SubmitButton.tsx
    - errorMsg.tsx should be ErrorMessage.tsx

Validation Commands
------------------
npm test: PASS (45/45)
npm run lint: PASS
npm run typecheck: PASS

SUMMARY
-------
Requirements: 3/4 implemented (75%)
Conventions: 3/4 passing (75%)
Tests: PASS

Status: NEEDS ATTENTION
- Complete rate limiting implementation
- Fix naming convention violations
- Add error display tests
```

---

### /design report {project-name}

Generate a comprehensive project status report.

**Usage:**
```
/design report my-project
/design report house-build --include-deltas
```

**Execution:**

1. **Scan project structure:**
   - Find all specs in `docs/design/specs/`
   - Find all PRPs in `docs/design/PRPs/`
   - Find all deltas in `docs/design/deltas/`

2. **For each spec:**
   - Run validation status
   - Check if PRP exists
   - Check implementation status if path defined

3. **Aggregate metrics:**
   - Specs validated vs total
   - PRPs generated
   - Invariant violation trends
   - Phase completion status

4. **Generate report**

**Output:**
```
Design Ops Project Report
=========================

Project: my-project
Report Date: 2026-01-19

Specifications
--------------
| Spec | Validated | PRP | Status |
|------|-----------|-----|--------|
| feature-a.md | PASS | YES | In Progress |
| feature-b.md | PASS | YES | Complete |
| feature-c.md | FAIL (2) | NO | Blocked |

Invariant Summary
-----------------
Total validations: 15
Passed: 12 (80%)
Failed: 3 (20%)

Most common violations:
1. Invariant #1 (Ambiguity): 5 occurrences
2. Invariant #7 (Validation): 3 occurrences

PRPs Generated: 8
PRPs with unfilled placeholders: 3

Spec Deltas
-----------
| Date | Delta | New Invariant |
|------|-------|---------------|
| 2026-01-15 | API timeout handling | #44 |
| 2026-01-10 | Payment idempotency | #45 |

Recommendations
---------------
1. Address ambiguity in feature-c.md (2 violations)
2. Fill placeholders in 3 PRPs before execution
3. Review Invariant #44 applicability to active specs
```

---

## Workflow Integration

### Complete Design Ops Flywheel

```
         ┌───────────────────────────────────────────────┐
         │                                               │
         ▼                                               │
    [Research]                                           │
         │                                               │
         ▼                                               │
    [Personas & Journeys]                                │
         │                                               │
         ▼                                               │
┌─────────────────────┐                                  │
│   Write Spec        │                                  │
│   (Human intent)    │                                  │
└─────────────────────┘                                  │
         │                                               │
         ▼                                               │
┌─────────────────────┐     FAIL                         │
│ /design validate    │ ────────────────┐                │
│                     │                 │                │
└─────────────────────┘                 │                │
         │                              │                │
         │ PASS                         ▼                │
         │                    ┌─────────────────┐        │
         │                    │   Fix Spec      │        │
         │                    │   (address      │        │
         │                    │   violations)   │        │
         │                    └─────────────────┘        │
         │                              │                │
         │                              │                │
         │◄─────────────────────────────┘                │
         │                                               │
         ▼                                               │
┌─────────────────────┐                                  │
│   /design prp       │                                  │
│   (compile to PRP)  │                                  │
└─────────────────────┘                                  │
         │                                               │
         ▼                                               │
┌─────────────────────┐                                  │
│   Fill Placeholders │                                  │
│   (human review)    │                                  │
└─────────────────────┘                                  │
         │                                               │
         ▼                                               │
┌─────────────────────┐                                  │
│   Execute           │                                  │
│   (implementation)  │                                  │
└─────────────────────┘                                  │
         │                                               │
         ▼                                               │
┌─────────────────────┐                                  │
│ /design review      │                                  │
│ (compliance check)  │                                  │
└─────────────────────┘                                  │
         │                                               │
         │ Gap found?                                    │
         │                                               │
         ▼                                               │
┌─────────────────────┐                                  │
│   Spec Delta        │ ─────────────────────────────────┘
│   (new invariant)   │
└─────────────────────┘
```

---

## Error Handling

### Validation Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `Spec file not found` | Invalid path | Check file path, use absolute path |
| `Invariants file not found` | Missing system-invariants.md | Ensure DesignOps structure exists |
| `Domain file not found` | Invalid domain reference | Check domain file path |
| `VIOLATION: Invariant #N` | Spec violates invariant | Follow fix suggestion in output |

### PRP Generation Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `Spec has N violations` | Validation failed | Run `/design validate` and fix issues |
| `Template not found` | Invalid template name | Use: base, api-integration, user-feature, data-migration |
| `Cannot detect project type` | Ambiguous spec | Specify `--template` explicitly |

### Review Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `Implementation path not found` | Invalid directory | Check path exists |
| `No spec requirements found` | Malformed spec | Ensure spec has bullet points or criteria |
| `CONVENTIONS.md not found` | No conventions defined | Create CONVENTIONS.md or use `--skip-conventions` |

---

## Dependencies

### Path Resolution

**IMPORTANT**: All paths are relative to this skill file's location (`design.md`).

When executing commands, resolve the DesignOps root directory as:
- The directory containing this `design.md` file
- Or use `$DESIGNOPS_ROOT` environment variable if set

```
{DESIGNOPS_ROOT}/           ← Directory containing this skill file
├── design.md               ← This skill file
├── enforcement/            ← Shell scripts
├── templates/              ← PRP templates
├── domains/                ← Domain invariant files
└── system-invariants.md    ← Core invariants
```

### Required Scripts

Located at `{DESIGNOPS_ROOT}/enforcement/`:

| Script | Purpose | Direct Use |
|--------|---------|------------|
| `validator.sh` | Invariant checking | `./validator.sh <spec> [--domain <file>]` |
| `spec-to-prp.sh` | PRP generation | `./spec-to-prp.sh <spec> [--template <type>]` |
| `prp-checker.sh` | PRP quality check | `./prp-checker.sh <prp> [--verbose]` |

### Required Files

| File | Location | Purpose |
|------|----------|---------|
| `system-invariants.md` | `{DESIGNOPS_ROOT}/` | Core invariant definitions |
| `prp-base.md` | `{DESIGNOPS_ROOT}/templates/` | Base PRP template |
| Domain files | `{DESIGNOPS_ROOT}/domains/` | Domain-specific invariants |

### Available Domains

| Domain | File | Use When |
|--------|------|----------|
| Consumer Product | `consumer-product.md` | Mobile apps, web apps, user-facing features |
| Physical Construction | `physical-construction.md` | Buildings, infrastructure, materials |
| Data Architecture | `data-architecture.md` | Pipelines, warehouses, analytics |
| Integration | `integration.md` | APIs, webhooks, third-party services |
| Remote Management | `remote-management.md` | Projects managed from distance |
| Skill Gap Transcendence | `skill-gap-transcendence.md` | New tech, learning-intensive projects |

---

## Configuration

### Project Configuration (.designops)

```yaml
# .designops - Project-level Design Ops configuration
project: my-project
domain: consumer-product
additional_domains:
  - integration

paths:
  specs: docs/design/specs
  prps: docs/design/PRPs
  deltas: docs/design/deltas
  conventions: CONVENTIONS.md

validation:
  strict: true  # Treat warnings as errors

templates:
  default: user-feature
```

### Environment Variables

```bash
# DESIGNOPS_ROOT is auto-detected from this skill file's location
# Override only if DesignOps is installed elsewhere:
# export DESIGNOPS_ROOT="/path/to/DesignOps"

DESIGNOPS_STRICT=0  # Set to 1 to treat warnings as errors
```

---

## Examples

### Example 1: New Feature Project

```
User: "/design init checkout-optimization"

→ Creates folder structure
→ Initializes templates
→ Provides next steps

User: "Here's my spec for the checkout flow..."
[Creates spec in docs/design/specs/checkout-v2.md]

User: "/design validate docs/design/specs/checkout-v2.md --domain consumer-product"

→ Checks universal invariants (1-10)
→ Checks consumer product invariants (11-15)
→ Reports 1 warning about loading states

User: "/design prp docs/design/specs/checkout-v2.md"

→ Validates (PASS with warning)
→ Auto-detects user-feature template
→ Generates PRP with 18 placeholders
→ Quality score: 78/100
```

### Example 2: House Construction

```
User: "/design init kuberan-house --domain physical-construction"

→ Creates structure with construction-specific templates
→ Notes domain invariants 16-21 will apply

User: "/design validate specs/foundation.md --domain physical-construction --domain remote-management"

→ Checks universal + construction + remote management invariants
→ FAIL: Invariant #17 (Vendor Capabilities) - contractor without verification
→ FAIL: Invariant #31 (Independent Inspection) - no third-party verification

User: [Fixes spec]

User: "/design validate specs/foundation.md --domain physical-construction --domain remote-management"

→ PASS (2 warnings about climate consideration)
```

### Example 3: API Integration Review

```
User: "/design review specs/stripe-integration.md ./src/payments/"

→ Loads spec requirements
→ Scans implementation
→ Runs test suite
→ Checks rate limiting, idempotency, error handling
→ Reports: 4/5 requirements implemented
→ Missing: circuit breaker implementation
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-19 | Initial release with validate, prp, review, report commands |

---

## Quick Reference

| Command | Purpose | Key Output |
|---------|---------|------------|
| `/design init {name}` | Bootstrap project | Folder structure + templates |
| `/design validate {spec}` | Check invariants | PASS/FAIL + fix suggestions |
| `/design prp {spec}` | Generate PRP | Compiled PRP + quality score |
| `/design review {spec} {impl}` | Check compliance | Coverage report |
| `/design report {project}` | Status overview | Metrics + recommendations |

---

*Skill version: 1.0*
*Last updated: 2026-01-19*
*Enforcement tools: validator.sh v1.0, spec-to-prp.sh v1.0, prp-checker.sh v1.0*

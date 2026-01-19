---
name: Design
description: Enhanced Design Ops workflow with invariant enforcement, multi-agent orchestration, and continuous validation. USE WHEN design, spec, PRP, validate, requirements, init project, review implementation, watch mode.
version: "2.0"
---

# Design Ops Skill

Enhanced design workflow that transforms human intent into agent-executable PRPs through invariant enforcement.

## Overview

Design Ops v2.0 features a multi-agent architecture for comprehensive spec validation and PRP generation:

```
                         Spec (human intent)
                                │
                ┌───────────────┼───────────────┐
                ▼               ▼               ▼
        ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
        │spec-analyst │  │  validator  │  │  CONVENTIONS│
        │             │  │             │  │    check    │
        │• Complete   │  │• Invariants │  │             │
        │• Complexity │  │• Domain     │  │• Style      │
        │• Think level│  │• Confidence │  │• Patterns   │
        └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
               │                │                │
               └────────────────┼────────────────┘
                                │
                                ▼
                    ┌─────────────────────┐
                    │   prp-generator     │ ← Templates + Patterns
                    │                     │
                    │ • Structure PRP     │
                    │ • Validation cmds   │
                    │ • Thinking level    │
                    │ • Pattern links     │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │     reviewer        │ ← Quality gate
                    │                     │
                    │ • Required sections │
                    │ • No placeholders   │
                    │ • Executable cmds   │
                    └──────────┬──────────┘
                               │
                    ┌──────────┴──────────┐
                    ▼                     ▼
              APPROVED              NEEDS WORK
                    │                     │
                    ▼                     └─► Iterate
              Implementation
                    │
                    ▼
            ┌─────────────────────┐
            │   retrospective     │ ← Learning loop
            │                     │
            │ • Extract learnings │
            │ • Propose invariants│
            │ • System improve    │
            └─────────────────────┘
```

### Continuous Validation Mode

```
┌─────────────────┐
│  watch-mode.sh  │ ← Monitors spec files
│                 │
│ • File changes  │
│ • Real-time     │
│   confidence    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│continuous-      │ ← Background service
│validator.sh    │
│                 │
│ • Multi-spec    │
│ • Webhooks      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│validation-      │ ← Terminal dashboard
│dashboard.sh    │
│                 │
│ • Health status │
│ • Trends        │
│ • Alerts        │
└─────────────────┘
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

### /design orchestrate {spec-file} [--domain domain] [--phase phase]

Run the multi-agent orchestration pipeline for complete spec-to-PRP workflow.

**Usage:**
```
/design orchestrate specs/feature-spec.md --domain api
/design orchestrate specs/migration-spec.md --phase analysis
/design orchestrate specs/api-spec.md --domain integration --output ./output
```

**Phases:**
- `analysis` - Run spec-analyst and validator in parallel
- `generate` - Generate PRP from analysis results
- `review` - Review existing PRP for quality
- `retrospective` - Create retrospective from completed PRP
- `full` - Run complete pipeline (default)

**Execution:**
```bash
./tools/multi-agent-orchestrator.sh --spec "{spec-file}" --domain "{domain}" [--phase "{phase}"]
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║      MULTI-AGENT DESIGN OPS ORCHESTRATOR                      ║
╚═══════════════════════════════════════════════════════════════╝

Phase: full
Domain: api
Output: ./output

━━━ Phase 1: Analysis ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[10:23:45] Starting parallel analysis...
[10:23:47] ✓ spec-analyst completed
[10:23:48] ✓ validator completed

Analysis results: Completeness=85%, Thinking=Think
Validation results: Confidence=78%, Violations=0

━━━ Phase 2: Generation ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[10:23:50] ✓ prp-generator completed

━━━ Phase 3: Review ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[10:23:52] ✓ reviewer completed

╔═══════════════════════════════════════════════════════════════╗
║                      ORCHESTRATION COMPLETE                   ║
╚═══════════════════════════════════════════════════════════════╝

Generated Files:
  - analysis.json
  - validation.json
  - prp-feature.md
  - review.json

Status: PRP APPROVED - Ready for implementation
```

---

### /design watch {spec-file} [--domain domain] [--interval seconds]

Monitor spec file for changes with real-time validation feedback.

**Usage:**
```
/design watch specs/feature-spec.md --domain api
/design watch specs/api-spec.md --interval 5
```

**Execution:**
```bash
./tools/watch-mode.sh --spec "{spec-file}" --domain "{domain}" [--interval "{seconds}"]
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║                    WATCH MODE - LIVE VALIDATION               ║
╚═══════════════════════════════════════════════════════════════╝

Watching: specs/feature-spec.md
Domain:   api
Interval: 2s

Press Ctrl+C to stop

[10:25:32] Confidence: 78% ─ | Major: 1 Warnings: 2 (updated)
[10:25:34] Watching... (no changes)
[10:25:38] Confidence: 82% ↑ | Warnings: 1 (updated)
✓ Confidence improved by 4%
```

---

### /design dashboard [--results-dir dir]

Display real-time validation dashboard showing all spec health status.

**Usage:**
```
/design dashboard
/design dashboard --refresh 10
```

**Execution:**
```bash
./tools/validation-dashboard.sh [--results-dir "{dir}"] [--refresh "{seconds}"]
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║           DESIGN OPS VALIDATION DASHBOARD                     ║
╚═══════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════╗
║ SYSTEM HEALTH                                                 ║
╠═══════════════════════════════════════════════════════════════╣
║ Status: HEALTHY                                               ║
║ Specs Monitored: 5                                            ║
║ Average Confidence: 76%                                       ║
║                                                               ║
║   ████████████████░░░░░░░░                                    ║
║   ■ Healthy: 4  ■ Warning: 1  ■ Critical: 0                   ║
╚═══════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════╗
║ SPEC VALIDATION STATUS                                        ║
╠═══════════════════════════════════════════════════════════════╣
║   SPEC                   CONFIDENCE           CRIT  MAJOR     ║
║   ──────────────────────────────────────────────────────────  ║
║   ● api-spec             ████████████████░░░░  82%    0     0 ║
║   ● user-feature         ████████████████░░░░  78%    0     1 ║
║   ● migration            ████████████░░░░░░░░  65%    0     2 ║
╚═══════════════════════════════════════════════════════════════╝
```

---

### /design continuous start|stop|status [--spec files]

Manage background continuous validation service.

**Usage:**
```
/design continuous start --spec specs/api.md --spec specs/db.md --domain api
/design continuous status
/design continuous stop
```

**Execution:**
```bash
./tools/continuous-validator.sh start --spec "{file1}" --spec "{file2}" --domain "{domain}"
./tools/continuous-validator.sh status
./tools/continuous-validator.sh stop
```

---

### /design retrospective {prp-file} --outcome "{summary}"

Generate retrospective and extract learnings after implementation.

**Usage:**
```
/design retrospective PRPs/feature-prp.md --outcome "Successfully deployed, minor issues with error handling"
```

**Execution:**
```bash
./agents/retrospective.sh "{prp-file}" --outcome "{summary}" --domain "{domain}"
```

**Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║  RETROSPECTIVE - Learning Extraction & System Improvement     ║
╚═══════════════════════════════════════════════════════════════╝

PRP:     PRPs/feature-prp.md
Domain:  api
Outcome: Successfully deployed, minor issues with error handling

[1/4] Analyzing implementation...
  Completion: 45/48 tasks (94%)

[2/4] Generating retrospective...

[3/4] Identifying invariant proposals...
  Generated 2 invariant proposals

[4/4] Generating output files...
  Created: retrospective-feature.md
  Created: invariant-proposals.json

Generated Files:
  Retrospective: retrospective-feature.md
  Proposals:     invariant-proposals.json

Summary:
  Project:       Feature Implementation
  Completion:    94%
  Proposals:     2

Next steps:
  1. Review and complete the retrospective answers
  2. Finalize invariant proposals
  3. Run: ./tools/spec-delta-to-invariant.sh retrospective-feature.md
```

---

### /design freshness [quick|full]

Run the Design Ops freshness check to ensure methodology stays current with agentic engineering best practices.

**Usage:**
```
/design freshness quick   # Check known sources only (5-10 min)
/design freshness full    # Full landscape research (15-30 min)
/design freshness         # Defaults to quick
```

**What It Does:**

1. **Scans Current State** - Inventories all Design Ops files
2. **Checks Source Health** - Validates registry sources are still active
3. **Researches Landscape** - Discovers new developments since last scan
4. **Validates Findings** - Scores against Anthropic-anchored criteria
5. **Analyzes Impact** - Compares findings to current Design Ops
6. **Generates Actions** - Creates prioritized update plan

**Execution (Claude Code does this inline):**

**Step 1: Gather Context**
```
Read and summarize current Design Ops state:
- templates/ (what PRP templates exist)
- tools/ (what automation exists)
- examples/ (what patterns are documented)
- docs/ (what guidance exists)
- invariants/ (what domains are covered)
```

**Step 2: Research Landscape**
```
Research agentic engineering developments from [LAST_SCAN_DATE] to today.

REQUIRED SOURCES (always check):
- Anthropic official: docs.anthropic.com, anthropic.com/research
- Anthropic Cookbook: github.com/anthropics/anthropic-cookbook
- Claude Code docs: Current best practices
- MCP updates: modelcontextprotocol.io

DISCOVERY FOCUS:
- New methodologies with >1000 GitHub stars OR enterprise adoption
- Patterns validated by Anthropic or recognized experts
- Tools/approaches compatible with invariant-based validation

CONTEXT: Design Ops uses invariant-based validation, multi-agent orchestration,
confidence scoring, and PRP-based implementation planning. Assess compatibility.

For each finding provide:
- Source URL
- Validation evidence (who endorses, adoption metrics)
- Key innovation (what's new)
- Relevance to Design Ops (1-10)
- Recommended action (adopt/watch/ignore)
```

**Step 3: Validate Against Framework**
```
For each discovered source, score against:
1. Anthropic Alignment (0-3): Is it endorsed/compatible with Anthropic guidance?
2. Traction (0-3): GitHub stars >1000? Enterprise adoption? Case studies?
3. Design Ops Fit (0-3): Compatible with invariants, PRPs, confidence scoring?
4. Freshness (0-1): Updated in last 6 months?

Total score /10. Only sources scoring ≥6 get recommended.
```

**Step 4: Generate Impact Analysis**
```
Compare findings against current Design Ops:

VALIDATED (Design Ops already does this):
- [List what's confirmed as best practice]

NEEDS UPDATE (Design Ops should change):
- [List specific files and changes needed]

DEPRECATED (Design Ops should remove/update):
- [List anything now outdated]

NEW ADDITIONS (Design Ops should add):
- [List new patterns/tools to incorporate]
```

**Step 5: Create Action Plan**
```
Write to docs/freshness/actions/YYYY-MM-actions.md:

## Quick Wins (< 1 hour)
- [ ] Action 1: File, change, reason

## Short-term (1 day)
- [ ] Action 2: File, change, reason

## Medium-term (1 week)
- [ ] Action 3: File, change, reason

## Watch List (revisit next month)
- Source X: Why watching, trigger for action
```

**Step 6: Update Dashboard**
```
Write to docs/freshness/dashboard.md:
- Last scan date
- Health score (0-100)
- Sources monitored
- Pending actions count
- Design Ops version alignment
```

**Output Files:**
```
docs/freshness/
├── discoveries/YYYY-MM-raw.md       # Raw research findings
├── validated/YYYY-MM-validated.md   # Scored and filtered
├── impact/YYYY-MM-impact.md         # Gap analysis
├── actions/YYYY-MM-actions.md       # Prioritized todo list
├── reports/YYYY-MM-summary.md       # Executive summary
└── dashboard.md                     # Current state (always updated)
```

**Automated Monthly Reminder:**
Install with `./tools/freshness/install.sh` to get MacOS notification on 1st of each month.

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

**Located at `{DESIGNOPS_ROOT}/enforcement/`:**

| Script | Purpose | Direct Use |
|--------|---------|------------|
| `validator.sh` | Invariant checking + CONVENTIONS | `./validator.sh <spec> [--domain <file>]` |
| `spec-to-prp.sh` | PRP generation + patterns | `./spec-to-prp.sh <spec> [--template <type>]` |
| `prp-checker.sh` | PRP quality check | `./prp-checker.sh <prp> [--verbose]` |
| `confidence-calculator.sh` | Calculate confidence score | `./confidence-calculator.sh <prp>` |

**Located at `{DESIGNOPS_ROOT}/agents/`:**

| Script | Purpose | Direct Use |
|--------|---------|------------|
| `spec-analyst.sh` | Analyze spec completeness | `./spec-analyst.sh <spec> --domain <domain>` |
| `validator.sh` | Domain invariant validation | `./validator.sh <spec> --domain <domain>` |
| `prp-generator.sh` | Generate PRP from analysis | `./prp-generator.sh <spec> --analysis <file> --validation <file>` |
| `reviewer.sh` | Review PRP quality | `./reviewer.sh <prp>` |
| `retrospective.sh` | Extract learnings | `./retrospective.sh <prp> --outcome "<summary>"` |

**Located at `{DESIGNOPS_ROOT}/tools/`:**

| Script | Purpose | Direct Use |
|--------|---------|------------|
| `multi-agent-orchestrator.sh` | Full pipeline coordination | `./multi-agent-orchestrator.sh --spec <file> --domain <domain>` |
| `watch-mode.sh` | Real-time spec monitoring | `./watch-mode.sh --spec <file> --domain <domain>` |
| `continuous-validator.sh` | Background validation service | `./continuous-validator.sh start|stop|status` |
| `validation-dashboard.sh` | Terminal dashboard | `./validation-dashboard.sh` |
| `spec-delta-to-invariant.sh` | Extract invariants from retrospectives | `./spec-delta-to-invariant.sh <retro>` |

### Required Files

| File | Location | Purpose |
|------|----------|---------|
| `system-invariants.md` | `{DESIGNOPS_ROOT}/` | Core invariant definitions |
| `prp-base.md` | `{DESIGNOPS_ROOT}/templates/` | Base PRP template |
| `thinking-level-rubric.md` | `{DESIGNOPS_ROOT}/templates/` | Thinking level quick reference |
| `validation-commands-library.md` | `{DESIGNOPS_ROOT}/templates/` | Reusable validation commands |
| `retrospective-template.md` | `{DESIGNOPS_ROOT}/templates/` | Post-implementation retro template |
| Domain files | `{DESIGNOPS_ROOT}/domains/` | Domain-specific invariants |

### Pattern Examples

| Pattern | Location | Use Case |
|---------|----------|----------|
| `api-client.md` | `{DESIGNOPS_ROOT}/examples/` | API integration, HTTP clients, retries |
| `error-handling.md` | `{DESIGNOPS_ROOT}/examples/` | Error hierarchy, Result types, circuit breakers |
| `database-patterns.md` | `{DESIGNOPS_ROOT}/examples/` | Repository pattern, transactions, pooling |
| `config-loading.md` | `{DESIGNOPS_ROOT}/examples/` | Env vars, validation, secrets |
| `test-fixtures.md` | `{DESIGNOPS_ROOT}/examples/` | Factories, mocks, test isolation |

### Documentation

| Doc | Location | Purpose |
|-----|----------|---------|
| `multi-agent-architecture.md` | `{DESIGNOPS_ROOT}/docs/` | Agent coordination design |
| `thinking-levels.md` | `{DESIGNOPS_ROOT}/docs/` | When to use Think/Think Hard/Ultrathink |

### Configuration

| File | Location | Purpose |
|------|----------|---------|
| `watch-config.yaml` | `{DESIGNOPS_ROOT}/config/` | Watch mode and agent configuration |

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
| 2.0 | 2026-01-19 | Multi-agent architecture, continuous validation, examples library, thinking levels |
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
| `/design orchestrate {spec}` | Full pipeline | Analysis → PRP → Review |
| `/design watch {spec}` | Live monitoring | Real-time confidence |
| `/design dashboard` | System health | All specs status |
| `/design continuous start` | Background service | Continuous validation |
| `/design retrospective {prp}` | Extract learnings | Retro + invariant proposals |

---

*Skill version: 2.0*
*Last updated: 2026-01-19*
*Enforcement tools: validator.sh v1.1, spec-to-prp.sh v1.1, prp-checker.sh v1.0*
*Multi-agent system: spec-analyst, validator, prp-generator, reviewer, retrospective*
*Continuous validation: watch-mode, continuous-validator, validation-dashboard*

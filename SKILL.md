---
name: design
description: Create implementation specs, PRPs, and maintain agentic engineering standards. USE WHEN design, spec, implementation plan, PRP, architecture, freshness check.
---

# Design Ops

Structured approach to planning AI-assisted implementation through PRPs (Planning & Requirements Packets) and Implementation Specs.

## Workflow Routing

| Request Type | Workflow | Context |
|--------------|----------|---------|
| New feature/project | → `/design prp` | Shared |
| Bug fix / small change | → `/design spec` | Shared |
| Validate spec | → `/design-validate` | Forked |
| Review implementation | → `/design-review` | Forked |
| Full pipeline | → `/design-orchestrate` | Forked |
| System freshness | → `/design-freshness` | Forked |

## Context Architecture

Design Ops uses **forked context** for heavy operations to keep the main conversation clean:

```
Main Context (shared)              Forked Context (isolated)
─────────────────────              ─────────────────────────
/design prp                        /design-validate
/design spec                       /design-review
/design init                       /design-orchestrate
/design dashboard                  /design-freshness
/design report
```

**Why fork?**
- Heavy operations (validation, research, multi-agent) don't bloat main context
- Forked skills return concise summaries
- Main conversation stays focused on decision-making

## Commands

### Shared Context Commands

#### `/design prp`
Create a Planning & Requirements Packet for a new initiative.
- May reference conversation context ("the feature we discussed")
- Interactive placeholder filling

#### `/design spec`
Create an implementation specification for a defined scope.

#### `/design init {project}`
Bootstrap a new project with Design Ops structure.

#### `/design dashboard`
Display validation dashboard for all specs.

#### `/design report {project}`
Generate project status report.

### Forked Context Commands

#### `/design-validate {spec}`
Validate spec against system invariants.
- Returns: PASS/FAIL + violation summary
- Full details in forked context

#### `/design-review {spec} {implementation}`
Review implementation against spec for compliance.
- Returns: Coverage % + gap summary
- Full file scan in forked context

#### `/design-orchestrate {spec}`
Run multi-agent pipeline (analysis → generation → review).
- Returns: Status + output file paths
- Multi-agent coordination in forked context

#### `/design-freshness [quick|full]`
Check Design Ops currency against agentic engineering landscape.
- Returns: Health score + top priorities
- Web research in forked context

## Sub-Skills

Located in `skills/` directory:

| Skill | File | Context | Purpose |
|-------|------|---------|---------|
| design-validate | `skills/validate.md` | fork | Invariant validation |
| design-review | `skills/review.md` | fork | Implementation compliance |
| design-orchestrate | `skills/orchestrate.md` | fork | Multi-agent pipeline |
| design-freshness | `skills/freshness.md` | fork | Freshness research |

## Agent

This skill is used by **Architect (Atlas)** and **Engineer (Dev)**.

## Key Files

```
DesignOps/
├── SKILL.md                 # This file (skill registration)
├── design.md                # Main skill with full workflows
├── system-invariants.md     # Validation rules
├── skills/                  # Forked sub-skills
│   ├── validate.md
│   ├── review.md
│   ├── orchestrate.md
│   └── freshness.md
├── templates/               # PRP and spec templates
├── examples/                # Pattern library
├── tools/                   # Automation scripts
│   └── freshness/           # Freshness system
├── docs/                    # Documentation
│   └── freshness/           # Freshness artifacts
└── config/                  # Configuration
    └── source-registry.yaml # Freshness sources
```

## Invocation Examples

**Shared context:**
- "Create a PRP for the new authentication system"
- "Write an implementation spec for the API refactor"
- "/design init checkout-feature"

**Forked context:**
- "/design-validate specs/feature.md"
- "/design-review specs/api.md ./src/api/"
- "/design-orchestrate specs/migration.md --domain data"
- "/design-freshness full"

---

*Skill version: 2.1*
*Context architecture: Shared + Forked (Claude Code 2.1.0+)*

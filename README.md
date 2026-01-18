# Design Ops Plugin

A Claude Code plugin that implements a research-driven design flywheel for turning ideas into exhaustive, tested implementations.

## Installation

```bash
claude plugins install github:samselvan/design-ops
```

Or add to your `.claude/plugins/` manually.

## Quick Start

```bash
/design my-new-app
```

The skill will guide you through:
1. **Research** — Domain experts, prior art, cross-domain inspiration
2. **Constraints** — Technical stack, timeline, non-negotiables
3. **Brainstorm** — Requirements through dialogue
4. **Journeys** — User flows with emotional arcs
5. **Tokens** — Visual design system
6. **Specs** — Exhaustive specifications
7. **Tests** — Functional + non-functional + LLM-as-judge
8. **Handoff** — Ready for Zeroshot/Ralph implementation

## Commands

| Command | Purpose |
|---------|---------|
| `/design {project}` | Full workflow, auto-detect mode |
| `/design {project} full` | Force full mode (new product) |
| `/design {project} standard` | Force standard mode (feature) |
| `/design {project} minimal` | Force minimal mode (bug fix) |
| `/design {project} research` | Research phase only |
| `/design {project} retrospective` | Post-implementation review |

## Three Modes

| Mode | When | What |
|------|------|------|
| **Full** | New product, major feature | All phases, 2 validation iterations |
| **Standard** | Multi-file feature | Skip tracer bullet, 1 iteration |
| **Minimal** | Bug fix, minor tweak | Spec + tests only |

## The Flywheel

```
Research → Validation → Constraints → Brainstorm → Tracer Bullet
                                                         ↓
                              Personas → Journeys → Validation
                                                         ↓
                                         Tokens → Specs → Validation
                                                              ↓
                                                 Tests → Validation
                                                              ↓
                                        Zeroshot/Ralph → Implementation
                                                              ↓
                                          Retrospective → Learnings
                                                              ↓
                                         PRINCIPLES / PATTERNS → Next cycle
```

## Validation Gates

Every artifact is stress-tested before use:

| Artifact | Checks |
|----------|--------|
| Research | Echo chamber, staleness, domain drift, competitors, assumptions |
| Journeys | Happy path bias, actor vagueness, reality, decisions, emotion, bloat |
| Specs | Ambiguity, edge cases, implementability, contradictions |
| Tests | False positives, false negatives, coverage, mutation survival |

## Output Structure

```
{project}/docs/design/
├── research.md + validation
├── constraints.md
├── requirements.md
├── tokens.md
├── personas/P-*.md
├── journeys/J-*.md + validation
├── specs/S-*.md + validation
├── tests/T-*.md + validation
└── retrospective.md
```

## Domain Libraries

Pre-researched token sets for common domains:
- `healthcare` — HIPAA-aware, calm colors, accessibility-first
- `fintech` — Trust indicators, error prevention
- `developer-tools` — Information density, keyboard-first
- `consumer` — Delight, simplicity

## Expert Foundations

Built on principles from:
- **The Pragmatic Programmer** (Hunt & Thomas)
- **Shape Up** (Basecamp/Singer)
- **About Face** (Alan Cooper)
- **Test-Driven Development** (Kent Beck)
- **Refactoring** (Martin Fowler)
- **Clean Code** (Robert Martin)

## Integration

Outputs are formatted for:
- **Zeroshot** — Multi-agent implementation
- **Ralph** — TDD-based builds
- **Claude/Cursor** — AI-assisted development

## License

MIT — See [LICENSE](LICENSE)

## Author

Samuel Selvan

## Contributing

PRs welcome! Please include:
- New domain libraries
- Validation prompt improvements
- Pattern additions

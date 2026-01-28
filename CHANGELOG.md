# Changelog

All notable changes to Design-Ops will be documented in this file.

## [2.3.0] - 2026-01-28

### Added
- **Parallel Sub-Agent Support**: RALPH gates 2, 5.5, 6.5, and 8 now support parallel execution
  - GATE 6.5 (build+lint+a11y) can run 3 concurrent sub-agents
  - Total pipeline can run 9-12 concurrent sub-agents
  - 39% speedup for parallelizable gates (7min vs 11.5min)
- **MCP Integration**: Created design-ops-server.py for dynamic rule access
  - Tools: get_invariants, get_security_rules, get_project_conventions, validate_spec_snippet
  - Allows agents to query design-ops rules via Model Context Protocol
  - Configuration example and documentation included
- **New Orchestrator**: ralph-orchestrator-v3-parallel.py
  - Explicit parallel sub-agent instructions in gate descriptions
  - Clear completion criteria (all N sub-agents must pass)
  - Unique commit messages per sub-agent (e.g., "GATE 6.5A", "GATE 6.5B")
- **Documentation**: PARALLEL-SUBAGENTS.md explaining parallel execution strategy
  - When to parallelize (independent sub-tasks)
  - When NOT to parallelize (sequential dependencies)
  - Performance impact analysis
  - Best practices

### Changed
- **README**: Now features v3-parallel orchestrator as default
- **Timing**: Pipeline completes in 15-25 minutes (was 20-30 minutes)
- **Gate Instructions**: Added parallel execution guidance where applicable

### Performance
- **Overall Pipeline**: 15-25 minutes with parallelism (vs 20-30 min sequential)
- **GATE 2**: 2min parallel (vs 3min sequential) - 33% faster
- **GATE 6.5**: 2min parallel (vs 3.5min sequential) - 43% faster
- **GATE 8**: 3min parallel (vs 5min sequential) - 40% faster

## [2.2.0] - 2026-01-27

### Added
- **RALPH Pipeline**: Complete spec-to-production automation
  - 12 gates from spec validation to production-ready code
  - QUICKSTART-RALPH.md for 5-minute setup
- **Gate Constraints**: ralph-constraints.md to prevent scope creep
  - Strict guardrails for Claude Code agents
  - Anti-patterns and examples
- **6 New Validation Commands**:
  - security-scan (OWASP Top 10 checks)
  - test-validate (verify RED state)
  - test-quality (check assertions, AAA pattern)
  - preflight (environment readiness)
  - visual-regression (UI consistency)
  - performance-audit (Lighthouse, bundle size)
- **Orchestrator v2**: ralph-orchestrator.py with MANDATORY git commits
  - Explicit commit instructions with visual prominence
  - Commit verification steps
  - "WHY COMMIT IS MANDATORY" explanations

### Fixed
- **GATE 4**: Fixed instruction file expectation (check outputs to console)
- **Git Commits**: Made commits impossible to miss with bold, caps, emoji
- **Command Routing**: Added all 6 new commands to case statement

### Changed
- **README**: Made RALPH front and center
- **INSTALLATION**: Links to RALPH quickstart at top
- **design-ops-v3-refactored.sh**: Expanded from 500 to 692 lines

### Removed
- Cleaned up 55 obsolete files (23,146 lines deleted):
  - design-ops-v3.sh (old version)
  - claude-code-orchestrator.py (broken manual orchestrator)
  - cursor-orchestrator.py (duplicate)
  - archive/ directory
  - Planning docs (moved to enforcement/docs/)
  - Experimental DANGEROUS-MODE files

## [2.1.0] - 2026-01-15

### Added
- Design-Ops v2.1 with 43 system invariants
- Spec validation with stress-test command
- PRP generation with generate command
- Comprehensive documentation

## [2.0.0] - 2025-12-20

### Added
- Initial release of Design-Ops v2.0
- System invariants framework
- Validation tools
- Basic orchestration

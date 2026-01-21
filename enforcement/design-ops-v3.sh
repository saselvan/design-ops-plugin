#!/bin/bash
# design-ops-v3.sh - Simplified Design Ops Pipeline
#
# Philosophy: LLM is ADVISORY, human decides. No auto-fix loops.
#
# Workflow (in order):
#   1. stress-test  - "Is the spec complete?" (coverage against requirements/journeys)
#   2. validate     - "Is the spec clear?" (structure, ambiguity)
#   3. generate     - Create PRP from spec (one-shot)
#   4. check        - Verify PRP quality
#   5. Human reviews and approves
#
# Usage:
#   ./design-ops-v3.sh stress-test <spec> [--requirements <file>]  # Coverage check (RUN FIRST)
#   ./design-ops-v3.sh validate <spec-file>                        # Clarity check
#   ./design-ops-v3.sh generate <spec-file>                        # Generate PRP
#   ./design-ops-v3.sh check <prp-file>                            # Check PRP quality
#   ./design-ops-v3.sh ralph-check <prp-file> --steps <dir>        # Validate implementation against PRP

set -e

VERSION="3.3.0"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# PRP Generation Configuration
DESIGN_OPS_BASE="${DESIGN_OPS_BASE:-$HOME/.claude/plugins/design-ops}"
INVARIANTS_DIR="$DESIGN_OPS_BASE"
DOMAINS_DIR="$DESIGN_OPS_BASE/domains"
TEMPLATES_DIR="$DESIGN_OPS_BASE/templates"

# Domain mapping function (bash 3.x compatible)
# Returns: file:start-end or empty if not found
get_domain_mapping() {
    local domain="$1"
    case "$domain" in
        "consumer product"|"consumer-product")
            echo "consumer-product.md:11-15" ;;
        "physical construction"|"physical-construction"|"construction")
            echo "physical-construction.md:16-21" ;;
        "data architecture"|"data-architecture"|"data")
            echo "data-architecture.md:22-26" ;;
        "integration")
            echo "integration.md:27-30" ;;
        "healthcare ai"|"healthcare-ai")
            echo "healthcare-ai.md:27-30" ;;
        "hls"|"hls solution accelerator"|"hls-solution-accelerator"|"databricks")
            echo "hls-solution-accelerator.md:31-38" ;;
        "remote management"|"remote-management"|"remote")
            echo "remote-management.md:31-36" ;;
        "skill gap"|"skill-gap"|"skill-gap-transcendence")
            echo "skill-gap-transcendence.md:37-43" ;;
        *)
            echo "" ;;
    esac
}

# Cost tracking (estimates based on Claude API pricing)
TOTAL_INPUT_TOKENS=0
TOTAL_OUTPUT_TOKENS=0

usage() {
    echo "Design Ops v$VERSION - Unified Design Pipeline"
    echo ""
    echo "Usage: $0 <command> [file] [options]"
    echo ""
    echo "CORE COMMANDS (run in this order):"
    echo "  stress-test <spec>   Check completeness (requirements, journeys, failure modes)"
    echo "  validate <spec>      Check clarity (structure, ambiguity)"
    echo "  generate <spec>      Generate PRP from spec (one-shot)"
    echo "  check <prp>          Check PRP quality"
    echo "  ralph-check <prp>    Validate implementation against PRP (--steps <dir>)"
    echo ""
    echo "ADVANCED COMMANDS (extended features):"
    echo "  orchestrate <spec>   Multi-agent pipeline (analyze → generate → review)"
    echo "  watch <spec>         File watcher for continuous validation"
    echo "  dashboard            Interactive validation status dashboard"
    echo "  retro <prp>          Retrospective analysis after implementation"
    echo ""
    echo "OPTIONS:"
    echo "  --requirements <f>   Requirements file for stress-test (optional)"
    echo "  --journeys <f>       User journeys file for stress-test (optional)"
    echo "  --quick              Skip LLM assessment (deterministic only)"
    echo "  --skip-review        Skip interactive review prompt (for CI/automation)"
    echo "  --verbose            Show detailed output"
    echo ""
    echo "WORKFLOW:"
    echo "  1. stress-test  →  Catch obvious gaps in completeness"
    echo "  2. validate     →  Catch obvious gaps in clarity → HUMAN REVIEW GATE"
    echo "  3. generate     →  Create PRP + auto-check → HUMAN REVIEW GATE"
    echo "  4. implement    →  YOU build it"
    echo ""
    echo "Run '$0 <command> --help' for command-specific help."
    echo ""
    echo "Philosophy: This is a CHECKLIST ASSISTANT, not a judge."
    echo "            It catches obvious gaps. YOU catch subtle design flaws."
    exit 1
}

# ============================================================================
# ROBUST JSON PARSING (uses python, not grep)
# ============================================================================

parse_json() {
    local json="$1"
    local field="$2"
    echo "$json" | python3 -c "
import json, sys
try:
    # Try to extract JSON from markdown code blocks
    text = sys.stdin.read()
    if '\`\`\`json' in text:
        start = text.find('\`\`\`json') + 7
        end = text.find('\`\`\`', start)
        text = text[start:end].strip()
    elif '\`\`\`' in text:
        start = text.find('\`\`\`') + 3
        end = text.find('\`\`\`', start)
        text = text[start:end].strip()

    data = json.loads(text)
    field = '$field'

    # Navigate nested fields like 'dimensions.completeness.score'
    for key in field.split('.'):
        if isinstance(data, dict):
            data = data.get(key, '')
        else:
            data = ''
            break
    print(data if data != '' else '')
except Exception as e:
    print('')
" 2>/dev/null
}

extract_json() {
    local text="$1"
    echo "$text" | python3 -c "
import json, sys, re
text = sys.stdin.read()

# Try to find JSON in the text
patterns = [
    r'\`\`\`json\s*([\s\S]*?)\`\`\`',
    r'\`\`\`\s*([\s\S]*?)\`\`\`',
    r'(\{[\s\S]*\})'
]

for pattern in patterns:
    match = re.search(pattern, text)
    if match:
        try:
            candidate = match.group(1).strip()
            json.loads(candidate)  # Validate it's valid JSON
            print(candidate)
            sys.exit(0)
        except:
            continue

print('{}')
" 2>/dev/null
}

# ============================================================================
# COST TRACKING
# ============================================================================

estimate_tokens() {
    local text="$1"
    # Rough estimate: 1 token ≈ 4 characters
    echo $(( ${#text} / 4 ))
}

track_cost() {
    local input_text="$1"
    local output_text="$2"

    local input_tokens=$(estimate_tokens "$input_text")
    local output_tokens=$(estimate_tokens "$output_text")

    TOTAL_INPUT_TOKENS=$((TOTAL_INPUT_TOKENS + input_tokens))
    TOTAL_OUTPUT_TOKENS=$((TOTAL_OUTPUT_TOKENS + output_tokens))
}

show_cost_summary() {
    # Sonnet pricing: $3/M input, $15/M output (approximate)
    local input_cost=$(echo "scale=4; $TOTAL_INPUT_TOKENS * 0.000003" | bc)
    local output_cost=$(echo "scale=4; $TOTAL_OUTPUT_TOKENS * 0.000015" | bc)
    local total_cost=$(echo "scale=4; $input_cost + $output_cost" | bc)

    echo ""
    echo -e "${CYAN}Cost estimate: ~\$${total_cost} (${TOTAL_INPUT_TOKENS} input + ${TOTAL_OUTPUT_TOKENS} output tokens)${NC}"
}

# ============================================================================
# HUMAN REVIEW GATE
# ============================================================================

require_review_acknowledgment() {
    local context="$1"  # "validate" or "check"
    local file="$2"     # The file being reviewed

    # Skip if --skip-review flag was passed
    if [[ "$SKIP_REVIEW" == "true" ]]; then
        echo ""
        echo -e "${YELLOW}[--skip-review] Skipping interactive review gate${NC}"
        return 0
    fi

    # Check if running in a terminal (stdin is a tty)
    if [[ ! -t 0 ]]; then
        echo ""
        echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  HUMAN REVIEW REQUIRED - STOPPING                             ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${YELLOW}No interactive terminal detected.${NC}"
        echo -e "  ${YELLOW}Review the suggestions above with the user before proceeding.${NC}"
        echo -e "  ${CYAN}Re-run with --skip-review only after human approval.${NC}"
        echo ""
        return 1
    fi

    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  ${YELLOW}HUMAN REVIEW REQUIRED${BLUE}                                        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}YOU catch design flaws. This tool only catches structural gaps.${NC}"
    echo -e "  The LLM suggestions above are a starting point, not the answer."
    echo ""
    echo -e "  ${CYAN}What did you decide about the suggestions above?${NC}"
    echo -e "  ${DIM}(e.g., \"Ignoring #2, adding #4, #1 not applicable\" or \"All good\")${NC}"
    echo -e "  ${DIM}Type 'stop' to abort, 'skip' to proceed without logging${NC}"
    echo ""

    while true; do
        echo -ne "  Your decision: "
        read -r response

        # Handle special commands
        case "${response,,}" in
            stop|abort|quit|exit|n|no)
                echo ""
                echo -e "  ${YELLOW}Stopped. Fix issues and run again.${NC}"
                exit 0
                ;;
            skip)
                echo ""
                echo -e "  ${YELLOW}Skipped logging. Proceeding...${NC}"
                return 0
                ;;
            "")
                echo -e "  ${RED}Please document your decision (or type 'stop' to abort)${NC}"
                continue
                ;;
        esac

        # Log the decision
        local log_dir="${DESIGNOPS_LOG_DIR:-/tmp/design-ops-decisions}"
        mkdir -p "$log_dir"

        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local log_file="$log_dir/decisions.log"
        local file_basename=$(basename "${file:-unknown}")

        # Append to log file
        {
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Timestamp: $timestamp"
            echo "Command:   $context"
            echo "File:      $file_basename"
            echo "Decision:  $response"
            echo ""
        } >> "$log_file"

        echo ""
        echo -e "  ${GREEN}✓ Decision logged. Proceeding...${NC}"
        echo -e "  ${DIM}(Log: $log_file)${NC}"
        return 0
    done
}

# ============================================================================
# LLM INTERFACE
# ============================================================================

call_claude() {
    local prompt="$1"
    local result

    result=$(echo "$prompt" | claude --model claude-sonnet-4-20250514 --print 2>/dev/null)

    track_cost "$prompt" "$result"
    echo "$result"
}

# ============================================================================
# DETERMINISTIC CHECKS (Fast, Free, Reliable)
# ============================================================================

check_spec_structure() {
    local file="$1"
    local content
    content=$(cat "$file")

    local issues=()
    local warnings=()

    echo -e "${BLUE}━━━ Deterministic Checks ━━━${NC}"

    # Required sections
    if ! echo "$content" | grep -qiE "^#.*problem|^##.*problem|problem.*statement"; then
        issues+=("Missing: Problem statement")
    else
        echo -e "  ${GREEN}✓${NC} Problem statement found"
    fi

    if ! echo "$content" | grep -qiE "success.*criter|acceptance.*criter|done.*when|definition.*done"; then
        issues+=("Missing: Success criteria")
    else
        echo -e "  ${GREEN}✓${NC} Success criteria found"
    fi

    if ! echo "$content" | grep -qiE "scope|boundar|in.scope|out.of.scope|non-goal"; then
        warnings+=("Consider adding: Scope boundaries")
    else
        echo -e "  ${GREEN}✓${NC} Scope defined"
    fi

    if ! echo "$content" | grep -qiE "test|verif|validat"; then
        warnings+=("Consider adding: Test/validation approach")
    else
        echo -e "  ${GREEN}✓${NC} Testing mentioned"
    fi

    # Check for vague words (warning only)
    local vague_count
    vague_count=$(echo "$content" | grep -ciE "properly|efficiently|adequate|reasonable|good quality|as needed" 2>/dev/null) || vague_count=0
    if [[ $vague_count -gt 3 ]]; then
        warnings+=("Found $vague_count vague terms (properly, efficiently, etc.)")
    fi

    # Check minimum content
    local word_count
    word_count=$(wc -w < "$file" | tr -d ' ')
    if [[ $word_count -lt 100 ]]; then
        issues+=("Too short: $word_count words (minimum ~100)")
    fi

    echo ""

    # Report
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo -e "${RED}Issues (must fix):${NC}"
        for issue in "${issues[@]}"; do
            echo -e "  ${RED}✗${NC} $issue"
        done
    fi

    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Warnings (consider fixing):${NC}"
        for warning in "${warnings[@]}"; do
            echo -e "  ${YELLOW}!${NC} $warning"
        done
    fi

    # Return grade
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "FAIL"
    elif [[ ${#warnings[@]} -gt 2 ]]; then
        echo "NEEDS_WORK"
    else
        echo "PASS"
    fi
}

check_prp_structure() {
    local file="$1"
    local content
    content=$(cat "$file")

    local issues=()
    local warnings=()

    echo -e "${BLUE}━━━ Deterministic Checks ━━━${NC}"

    # Required PRP sections
    local required_sections=("overview" "success criteria" "timeline" "risk" "validation")

    for section in "${required_sections[@]}"; do
        if echo "$content" | grep -qiE "^#+.*$section"; then
            echo -e "  ${GREEN}✓${NC} $section section found"
        else
            issues+=("Missing section: $section")
        fi
    done

    # Check for unfilled placeholders
    local placeholder_count
    placeholder_count=$(grep -cE '\[FILL|\[TODO|\[TBD|\{\{' "$file" 2>/dev/null) || placeholder_count=0
    if [[ $placeholder_count -gt 0 ]]; then
        issues+=("Found $placeholder_count unfilled placeholders")
    fi

    # Check for LLM reasoning that shouldn't be in output
    if head -30 "$file" | grep -qiE "let me|I'll|I will|here's my|thinking"; then
        warnings+=("PRP may contain LLM reasoning that should be removed")
    fi

    echo ""

    if [[ ${#issues[@]} -gt 0 ]]; then
        echo -e "${RED}Issues (must fix):${NC}"
        for issue in "${issues[@]}"; do
            echo -e "  ${RED}✗${NC} $issue"
        done
    fi

    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Warnings:${NC}"
        for warning in "${warnings[@]}"; do
            echo -e "  ${YELLOW}!${NC} $warning"
        done
    fi

    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "FAIL"
    elif [[ ${#warnings[@]} -gt 0 ]]; then
        echo "NEEDS_WORK"
    else
        echo "PASS"
    fi
}

# ============================================================================
# LLM ADVISORY ASSESSMENT (Suggestions, not auto-fix)
# ============================================================================

get_llm_assessment() {
    local file="$1"
    local type="$2"  # "spec" or "prp"
    local content
    content=$(cat "$file")

    echo -e "${BLUE}━━━ LLM Advisory Assessment ━━━${NC}"
    echo -e "${CYAN}Getting suggestions (not auto-fixing)...${NC}"

    local schema prompt
    if [[ "$type" == "spec" ]]; then
        # Schema for spec validation - focuses on ambiguity/clarity
        schema='{"type":"object","properties":{"summary":{"type":"string"},"ambiguity_flags":{"type":"array","items":{"type":"string"}},"implicit_assumptions":{"type":"array","items":{"type":"string"}},"suggestions":{"type":"array","items":{"type":"string"}},"strengths":{"type":"array","items":{"type":"string"}}},"required":["summary","ambiguity_flags","suggestions"]}'

        prompt="You are validating a specification for CLARITY and UNAMBIGUITY (not completeness - that was checked in stress-test).

CLARITY INVARIANT (Invariant #1): Every term must have operational definition.
Flag any of these vague terms WITHOUT objective criteria attached:
- 'properly', 'correctly', 'efficiently', 'quickly'
- 'good', 'quality', 'robust', 'secure'
- 'intuitive', 'user-friendly', 'easy to use'
- 'as needed', 'appropriate', 'reasonable'
- 'should', 'may', 'might' (without clear conditions)

SPECIFICATION:
$content

Check for:
1. Vague terms without measurable definitions (quote the exact text)
2. Implicit assumptions not stated explicitly
3. Ambiguous state transitions (what happens between states?)
4. Success criteria that can't be objectively measured
5. Missing edge case definitions

Provide:
- summary: One sentence on clarity level
- ambiguity_flags: Specific vague terms found and where (quote the text, e.g., 'Line says \"handle errors properly\" - what does properly mean?') - max 5
- implicit_assumptions: Things the spec assumes but doesn't state explicitly - max 3
- suggestions: How to make unclear sections more specific - max 5
- strengths: What's already clear and well-defined - max 2

If you are uncertain about any assessment, flag it with [UNCERTAIN: reason]. It's better to express uncertainty than to guess."
    else
        # Schema for PRP validation - focuses on implementation readiness
        schema='{"type":"object","properties":{"summary":{"type":"string"},"blockers":{"type":"array","items":{"type":"string"}},"confidence_assessment":{"type":"string"},"missing_detail":{"type":"array","items":{"type":"string"}},"strengths":{"type":"array","items":{"type":"string"}}},"required":["summary","blockers"]}'

        prompt="You are validating a PRP (Product Requirements Prompt) for implementation readiness.

PRP:
$content

Check:
1. CONFIDENCE SCORE SANITY: Does the stated confidence (X/10) seem accurate given the content?
2. EXTRACTION COMPLETENESS: Are there sections marked NOT_SPECIFIED_IN_SPEC that seem wrong?
3. THINKING LEVEL: Does the recommended thinking level match the complexity?
4. APPENDIX CONTENT: Are technical details (schemas, APIs, wireframes) present if the PRP mentions them?
5. ACTIONABILITY: Could an engineer start implementation immediately, or are there blockers?

Provide:
- summary: One sentence on implementation readiness
- blockers: Issues that MUST be resolved before implementation (max 3)
- confidence_assessment: Is the stated confidence score accurate? Why/why not?
- missing_detail: Technical content that seems missing despite being referenced - max 3
- strengths: What makes this PRP implementation-ready - max 2

If you are uncertain about any assessment, flag it with [UNCERTAIN: reason]. It's better to express uncertainty than to guess."
    fi

    local raw_result result
    raw_result=$(echo "$prompt" | claude --model claude-sonnet-4-20250514 --print --output-format json --json-schema "$schema" 2>/dev/null)

    # Extract structured_output from the wrapper JSON
    result=$(echo "$raw_result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get('structured_output',{})))" 2>/dev/null)

    track_cost "$prompt" "$result"

    if [[ -z "$result" || "$result" == "{}" ]]; then
        echo -e "${YELLOW}LLM call failed or returned empty${NC}"
        echo "SKIPPED"
        return
    fi

    # Parse the structured JSON response
    local summary
    summary=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('summary',''))" 2>/dev/null)

    echo ""
    echo -e "Summary: $summary"
    echo ""

    if [[ "$type" == "spec" ]]; then
        # Display spec validation results (ambiguity-focused)
        echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)

    # Ambiguity flags (Invariant #1)
    flags = data.get('ambiguity_flags', [])
    if flags:
        print('\033[91mAmbiguity Flags (Invariant #1):\033[0m')
        for f in flags[:5]:
            print(f'  ✗ {f}')
        print()
    else:
        print('\033[92mNo ambiguity flags - terminology is clear\033[0m')
        print()

    # Implicit assumptions
    assumptions = data.get('implicit_assumptions', [])
    if assumptions:
        print('\033[93mImplicit Assumptions:\033[0m')
        for a in assumptions[:3]:
            print(f'  ? {a}')
        print()

    # Suggestions
    suggestions = data.get('suggestions', [])
    if suggestions:
        print('\033[93mSuggestions:\033[0m')
        for i, s in enumerate(suggestions[:5], 1):
            print(f'  {i}. {s}')
        print()

    # Strengths
    strengths = data.get('strengths', [])
    if strengths:
        print('Strengths:')
        for s in strengths[:2]:
            print(f'  ✓ {s}')
except Exception as e:
    print(f'  (Could not parse: {e})')
" 2>/dev/null
    else
        # Display PRP validation results (implementation-readiness focused)
        echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)

    # Blockers
    blockers = data.get('blockers', [])
    if blockers:
        print('\033[91mBlockers (must resolve):\033[0m')
        for b in blockers[:3]:
            print(f'  ✗ {b}')
        print()
    else:
        print('\033[92mNo blockers - ready for implementation\033[0m')
        print()

    # Confidence assessment
    conf = data.get('confidence_assessment', '')
    if conf:
        print('\033[96mConfidence Assessment:\033[0m')
        print(f'  {conf}')
        print()

    # Missing detail
    missing = data.get('missing_detail', [])
    if missing:
        print('\033[93mMissing Detail:\033[0m')
        for m in missing[:3]:
            print(f'  ? {m}')
        print()

    # Strengths
    strengths = data.get('strengths', [])
    if strengths:
        print('Strengths:')
        for s in strengths[:2]:
            print(f'  ✓ {s}')
except Exception as e:
    print(f'  (Could not parse: {e})')
" 2>/dev/null
    fi

    echo ""
    echo "DONE"  # Signal completion, not a grade
}

# =============================================================================
# PRP GENERATION HELPERS
# =============================================================================

# Parse domains from spec header
parse_domains() {
    local spec_content="$1"

    local domain_line
    domain_line=$(echo "$spec_content" | grep -iE "^\*?\*?Domain\*?\*?:" | head -1)

    if [[ -z "$domain_line" ]]; then
        echo "universal"
        return
    fi

    local domain_value
    domain_value=$(echo "$domain_line" | sed 's/.*://' | tr '[:upper:]' '[:lower:]' | xargs)

    echo "$domain_value" | tr '+,' '\n' | while read -r domain; do
        domain=$(echo "$domain" | xargs)
        [[ -n "$domain" ]] && echo "$domain"
    done
}

# Resolve domains to invariant files and counts
resolve_domain_invariants() {
    local spec_content="$1"

    local domains
    domains=$(parse_domains "$spec_content")

    local invariant_refs=""
    local total_count=11
    local domain_count=0
    local has_skill_gap=false

    invariant_refs="Universal: $INVARIANTS_DIR/system-invariants.md (invariants 1-11)"

    while IFS= read -r domain; do
        [[ -z "$domain" || "$domain" == "universal" ]] && continue

        local mapping
        mapping=$(get_domain_mapping "$domain")
        if [[ -n "$mapping" ]]; then
            local file="${mapping%%:*}"
            local range="${mapping##*:}"
            local start="${range%%-*}"
            local end="${range##*-}"
            local count=$((end - start + 1))

            invariant_refs+="\nDomain ($domain): $DOMAINS_DIR/$file (invariants $range)"
            total_count=$((total_count + count))
            domain_count=$((domain_count + 1))

            [[ "$file" == "skill-gap-transcendence.md" ]] && has_skill_gap=true
        else
            invariant_refs+="\nDomain ($domain): UNKNOWN - manual review required"
            domain_count=$((domain_count + 1))
        fi
    done <<< "$domains"

    echo "INVARIANT_REFS<<EOF"
    echo -e "$invariant_refs"
    echo "EOF"
    echo "TOTAL_INVARIANTS=$total_count"
    echo "DOMAIN_COUNT=$domain_count"
    echo "HAS_SKILL_GAP=$has_skill_gap"
}

# Analyze spec for confidence factors
analyze_spec_confidence() {
    local spec_content="$1"

    # Factor 1: Requirement Clarity (30%)
    local clarity_score=0.5
    if echo "$spec_content" | grep -qiE "## Success Criteria|### Success Criteria"; then
        clarity_score=0.7
        if echo "$spec_content" | grep -qE "\|.*Target.*\||\|.*Metric.*\|"; then
            clarity_score=0.9
        fi
    fi

    # Factor 2: Pattern Availability (25%)
    local pattern_score=0.4
    if echo "$spec_content" | grep -qE "src/|app/|components/|\.tsx|\.ts|existing"; then
        pattern_score=0.7
    fi
    if echo "$spec_content" | grep -qiE "## Examples|### Examples|## Patterns|existing.*pattern"; then
        pattern_score=0.9
    fi

    # Factor 3: Test Coverage Plan (20%)
    local test_score=0.3
    local validation_count
    validation_count=$(echo "$spec_content" | grep -cE "npm (test|run)|pytest|curl|verify|assert" 2>/dev/null | head -1 || echo "0")
    validation_count=${validation_count:-0}
    if [[ "$validation_count" -ge 4 ]] 2>/dev/null; then
        test_score=0.9
    elif [[ "$validation_count" -ge 2 ]] 2>/dev/null; then
        test_score=0.7
    elif [[ "$validation_count" -ge 1 ]] 2>/dev/null; then
        test_score=0.5
    fi

    # Factor 4: Edge Case Handling (15%)
    local edge_score=0.3
    local failure_count
    failure_count=$(echo "$spec_content" | grep -cE "^### FM[0-9]|Failure Mode|## Failure" 2>/dev/null | head -1 || echo "0")
    failure_count=${failure_count:-0}
    if [[ "$failure_count" -ge 3 ]] 2>/dev/null; then
        edge_score=0.9
    elif [[ "$failure_count" -ge 1 ]] 2>/dev/null; then
        edge_score=0.6
    fi
    if echo "$spec_content" | grep -qiE "Degradation|Fallback|Recovery"; then
        edge_score=$(echo "$edge_score + 0.1" | bc)
        [[ $(echo "$edge_score > 1.0" | bc) -eq 1 ]] && edge_score=1.0
    fi

    # Factor 5: Tech Familiarity (10%)
    local tech_score=0.8
    if echo "$spec_content" | grep -qiE "skill.?gap|unknown|learning|first.?time|new.?tech"; then
        tech_score=0.4
    fi

    local score
    score=$(echo "scale=2; ($clarity_score * 0.30) + ($pattern_score * 0.25) + ($test_score * 0.20) + ($edge_score * 0.15) + ($tech_score * 0.10)" | bc)
    score=$(echo "scale=1; $score * 10" | bc)

    echo "CLARITY_SCORE=$clarity_score"
    echo "PATTERN_SCORE=$pattern_score"
    echo "TEST_SCORE=$test_score"
    echo "EDGE_SCORE=$edge_score"
    echo "TECH_SCORE=$tech_score"
    echo "CONFIDENCE_SCORE=$score"
}

# Determine thinking level
determine_thinking_level() {
    local confidence="$1"
    local domain_count="$2"
    local invariant_count="$3"
    local has_skill_gap="$4"

    local level="Normal"
    local focus=""

    local conf_int
    conf_int=$(echo "$confidence" | cut -d'.' -f1)

    if [[ "$conf_int" -lt 5 ]] || [[ "$domain_count" -ge 3 ]] || [[ "$invariant_count" -gt 30 ]]; then
        level="Ultrathink"
        focus="Verify all assumptions before implementation|Check invariant compliance at each decision point"
    elif [[ "$conf_int" -lt 7 ]] || [[ "$domain_count" -ge 2 ]] || [[ "$invariant_count" -gt 20 ]]; then
        level="Think Hard"
        focus="Validate integration points|Consider edge cases explicitly"
    elif [[ "$conf_int" -lt 9 ]]; then
        level="Think"
        focus="Adapt patterns to context|Verify success criteria mapping"
    else
        focus="Execute plan|Standard validation"
    fi

    if [[ "$has_skill_gap" == "true" ]]; then
        if [[ "$level" == "Normal" ]]; then
            level="Think"
        elif [[ "$level" == "Think" ]]; then
            level="Think Hard"
        fi
        focus="$focus|Discovery phase required - unknown unknowns likely"
    fi

    echo "THINKING_LEVEL=$level"
    echo "THINKING_FOCUS=$focus"
}

# =============================================================================
# PRP GENERATION (2026 Best Practices)
# =============================================================================

generate_prp() {
    local spec_file="$1"
    local output_file="$2"
    local spec_content
    spec_content=$(cat "$spec_file")

    local spec_name
    spec_name=$(basename "$spec_file" .md)

    echo -e "${BLUE}━━━ Generating PRP (2026 Best Practices) ━━━${NC}"

    # Step 1: Parse domains and resolve invariants
    echo -e "${CYAN}Analyzing spec domains...${NC}"
    local domain_info
    domain_info=$(resolve_domain_invariants "$spec_content")

    local invariant_refs total_invariants domain_count has_skill_gap
    invariant_refs=$(echo "$domain_info" | sed -n '/INVARIANT_REFS<<EOF/,/EOF/p' | sed '1d;$d')
    total_invariants=$(echo "$domain_info" | grep "TOTAL_INVARIANTS=" | cut -d= -f2)
    domain_count=$(echo "$domain_info" | grep "DOMAIN_COUNT=" | cut -d= -f2)
    has_skill_gap=$(echo "$domain_info" | grep "HAS_SKILL_GAP=" | cut -d= -f2)

    echo -e "  Domains detected: $domain_count (+ universal)"
    echo -e "  Total invariants: $total_invariants"
    [[ "$has_skill_gap" == "true" ]] && echo -e "  ${YELLOW}⚠ Skill-gap domain detected${NC}"

    # Step 2: Calculate confidence
    echo -e "${CYAN}Calculating confidence score...${NC}"
    local confidence_info
    confidence_info=$(analyze_spec_confidence "$spec_content")

    local confidence_score clarity_score pattern_score test_score edge_score tech_score
    confidence_score=$(echo "$confidence_info" | grep "CONFIDENCE_SCORE=" | cut -d= -f2)
    clarity_score=$(echo "$confidence_info" | grep "CLARITY_SCORE=" | cut -d= -f2)
    pattern_score=$(echo "$confidence_info" | grep "PATTERN_SCORE=" | cut -d= -f2)
    test_score=$(echo "$confidence_info" | grep "TEST_SCORE=" | cut -d= -f2)
    edge_score=$(echo "$confidence_info" | grep "EDGE_SCORE=" | cut -d= -f2)
    tech_score=$(echo "$confidence_info" | grep "TECH_SCORE=" | cut -d= -f2)

    echo -e "  Confidence: $confidence_score/10"

    # Step 3: Determine thinking level
    local thinking_info
    thinking_info=$(determine_thinking_level "$confidence_score" "$domain_count" "$total_invariants" "$has_skill_gap")

    local thinking_level thinking_focus
    thinking_level=$(echo "$thinking_info" | grep "THINKING_LEVEL=" | cut -d= -f2)
    thinking_focus=$(echo "$thinking_info" | grep "THINKING_FOCUS=" | cut -d= -f2)

    echo -e "  Thinking level: ${YELLOW}$thinking_level${NC}"

    # Step 4: Determine risk level
    local risk_level
    if (( $(echo "$confidence_score < 5" | bc -l) )); then
        risk_level="Low/Red - STOP: Address gaps before proceeding"
    elif (( $(echo "$confidence_score < 7" | bc -l) )); then
        risk_level="Medium/Yellow - CAUTION: Proceed with risk mitigation"
    else
        risk_level="High/Green - PROCEED: Normal execution path"
    fi

    # Step 5: Load PRP template or use fallback
    local prp_template_note=""
    if [[ -f "$TEMPLATES_DIR/prp-base.md" ]]; then
        prp_template_note="Using template: $TEMPLATES_DIR/prp-base.md"
    else
        prp_template_note="Template not found - using inline structure"
    fi
    echo -e "  ${DIM}$prp_template_note${NC}"

    # Step 6: Build the prompt
    echo -e "${CYAN}Generating PRP...${NC}"

    local prompt="You are a PRP compiler. Your job is EXTRACTION and TRANSFORMATION from a validated spec.

CRITICAL RULES:
- Extract content from the spec below. Do NOT invent content.
- If a spec section is missing or unclear, use \"NOT_SPECIFIED_IN_SPEC\" for that field
- Preserve all specific numbers, commands, file paths, and technical details exactly
- Copy Validation Commands VERBATIM - do not paraphrase
- If unsure about any extraction, flag it with [UNCERTAIN: reason]

DOMAIN & INVARIANTS (reference paths only):
$invariant_refs

PRE-CALCULATED VALUES (use these directly in the PRP):
- PRP ID: PRP-$(date +%Y-%m-%d)-001
- Source Spec: $spec_file
- Validation Date: $(date +%Y-%m-%d)
- Confidence Score: $confidence_score/10
- Risk Level: $risk_level
- Thinking Level: $thinking_level
- Thinking Focus: $(echo "$thinking_focus" | tr '|' ', ')
- Domain Count: $domain_count
- Invariant Count: $total_invariants

CONFIDENCE BREAKDOWN (include in Section 2):
| Factor | Weight | Score | Notes |
|--------|--------|-------|-------|
| Requirement Clarity | 30% | $clarity_score | Success criteria with metrics |
| Pattern Availability | 25% | $pattern_score | Existing code references |
| Test Coverage Plan | 20% | $test_score | Validation commands count |
| Edge Case Handling | 15% | $edge_score | Failure modes documented |
| Tech Familiarity | 10% | $tech_score | Known vs skill-gap |

VERBATIM PRESERVATION (copy these sections EXACTLY, do not summarize):
- Database Schema (SQL) → Include complete CREATE TABLE statements
- Validation Commands → Copy all bash/curl commands exactly
- API Endpoints → Preserve full endpoint specifications
- Column Mappings → Include all column names and transformations
- Error Messages → Copy exact error text
- UI Wireframes (ASCII) → Preserve character-for-character
- State Transitions → Copy the full state machine notation
- Code Snippets → Preserve all code exactly
- Tables with data → Copy all rows, do not truncate

SUMMARIZATION ALLOWED (these can be condensed):
- Problem Statement → Keep to 2-3 sentences
- Overview narrative → Condense to 1 paragraph
- Background/context sections → Brief summary

EXTRACTION MAP - Follow this mapping:
| Spec Section | → | PRP Section | Extraction Rule |
|--------------|---|-------------|-----------------|
| Problem Statement | → | 1.1 Problem Statement | Summarize to 2-3 sentences |
| Overview | → | 1.2 Solution Summary | Summarize WHAT not HOW |
| Scope (In/Out) | → | 1.3 Scope Boundaries | Convert to table, keep ALL items |
| Success Criteria table | → | 2.1 Primary Metrics | VERBATIM - copy table exactly |
| Database Schema (SQL) | → | Appendix B: Database Schema | VERBATIM - full CREATE TABLE |
| Column Mappings | → | Appendix D: Import Mappings | VERBATIM - all columns |
| API Endpoints | → | Appendix C: API Specification | VERBATIM - all endpoints |
| UI Wireframes | → | Appendix E: UI Reference | VERBATIM - preserve ASCII art |
| Feature sections (F0, F1...) | → | Phase sections | Keep ALL requirements as checklist |
| Validation Commands | → | 8. Validation Commands | VERBATIM - copy all commands |
| Failure Modes (FM1...) | → | 4.1 Risk Matrix | VERBATIM descriptions + probability/impact |
| Degradation Paths | → | 4.2 Fallback Strategies | VERBATIM as IF/THEN format |
| Error Messages | → | Appendix F: Error Catalog | VERBATIM - all error strings |
| Dependencies | → | 5.3 External Dependencies | VERBATIM - preserve table |
| Algorithm Details | → | Appendix G: Algorithm Details | VERBATIM - fuzzy search, etc. |
| Open Questions | → | Add to risks + Appendix | VERBATIM - list all |

LENGTH REQUIREMENT:
The output PRP should be approximately the same length as the input spec, or LONGER.
A 368-line spec should produce a 350-500 line PRP.
If your output is significantly shorter, you are summarizing too aggressively - go back and include more detail.

PRP STRUCTURE TO OUTPUT:
# PRP: $spec_name

## Meta
\`\`\`yaml
prp_id: PRP-$(date +%Y-%m-%d)-001
source_spec: $spec_file
validation_status: PASSED
validated_date: $(date +%Y-%m-%d)
domain: [extracted from spec]
version: 1.0
\`\`\`

## Confidence Score
### Overall Score
| Score | Risk Level | Recommendation |
|-------|------------|----------------|
| $confidence_score | [color] | [action] |

### Breakdown
[Use the confidence breakdown table above]

## 1. Project Overview
### 1.1 Problem Statement
[Extract from spec]

### 1.2 Solution Summary
[Extract from spec overview]

### 1.3 Scope Boundaries
| In Scope | Out of Scope |
|----------|--------------|
[Extract from spec]

## 2. Success Criteria
[Extract success criteria table from spec EXACTLY]

## 3. Timeline with Validation Gates
[Map F0, F1, F2... to Phase 1, Phase 2, Phase 3... with gates]

## 4. Risk Assessment
### 4.1 Risk Matrix
[Extract from Failure Modes, add probability/impact]

### 4.2 Fallback Strategies
[Extract from Degradation Paths as IF/THEN]

## 5. Resource Requirements
### 5.3 External Dependencies
[Extract dependencies table]

## 8. Validation Commands
### 8.1 Test Verification
[COPY VERBATIM from spec Validation Commands section]

## 9. Recommended Thinking Level
| Factor | Value | Impact |
|--------|-------|--------|
| Confidence Score | $confidence_score | [impact note] |
| Domains Involved | $domain_count | [impact note] |
| Invariants Applied | $total_invariants | [impact note] |

**Overall Level**: $thinking_level
**Apply higher thinking to**: $(echo "$thinking_focus" | tr '|' ', ')

## 10. State Transitions
[Extract from spec state transitions if present, or derive from feature flows]

## Appendix A: Source Spec Reference
**Spec Path**: $spec_file
**Invariants Validated**: Universal (1-11)$(echo "$invariant_refs" | grep "Domain" | sed 's/.*invariants /+ /g' | tr '\n' ' ')

## Appendix B: Database Schema
[VERBATIM - Include ALL CREATE TABLE statements from spec]

## Appendix C: API Specification
[VERBATIM - Include ALL API endpoints from spec]

## Appendix D: Import Column Mappings
[VERBATIM - Include ALL column mapping tables from spec]

## Appendix E: UI Wireframes
[VERBATIM - Include ALL ASCII wireframes/mockups from spec]

## Appendix F: Error Message Catalog
[VERBATIM - Include ALL error messages from spec]

## Appendix G: Algorithm Details
[VERBATIM - Include fuzzy search, matching algorithms from spec]

QUALITY CHECK BEFORE RESPONDING:
Before outputting the PRP, verify:
1. Did you include ALL database schema SQL? (If spec has CREATE TABLE, PRP must have it)
2. Did you include ALL API endpoints? (Count them - spec has X, PRP should have X)
3. Did you include ALL validation commands? (Copy verbatim)
4. Did you preserve UI wireframes? (ASCII art must be character-perfect)
5. Did you include ALL column mappings? (Every column from import sections)
6. Did you include ALL error messages? (Every error string from spec)
7. Is your output at least 80% the length of the input spec?

If any answer is NO, go back and add the missing content before outputting.

SPEC CONTENT:
<spec>
$spec_content
</spec>

OUTPUT:
Start directly with: # PRP: $spec_name
Fill all sections above.
Do not include any preamble or explanation before the PRP."

    local result
    result=$(call_claude "$prompt")

    # Clean up
    local cleaned
    cleaned=$(echo "$result" | sed -n '/^# PRP/,$p')

    if [[ -z "$cleaned" ]]; then
        cleaned="$result"
    fi

    cleaned=$(echo "$cleaned" | sed '/^```markdown$/d' | sed '/^```$/d')

    echo "$cleaned" > "$output_file"

    local lines
    lines=$(wc -l < "$output_file" | tr -d ' ')
    echo -e "${GREEN}✓ Generated: $output_file ($lines lines)${NC}"
    echo -e "${CYAN}  Confidence: $confidence_score/10 | Thinking: $thinking_level${NC}"
}

# ============================================================================
# MAIN COMMANDS
# ============================================================================

cmd_stress_test() {
    local spec_file="$1"
    local requirements_file="$2"
    local journeys_file="$3"
    local quick="$4"

    [[ ! -f "$spec_file" ]] && { echo -e "${RED}File not found: $spec_file${NC}"; exit 1; }

    local spec_content
    spec_content=$(cat "$spec_file")

    local requirements_content=""
    local journeys_content=""

    [[ -n "$requirements_file" ]] && [[ -f "$requirements_file" ]] && requirements_content=$(cat "$requirements_file")
    [[ -n "$journeys_file" ]] && [[ -f "$journeys_file" ]] && journeys_content=$(cat "$journeys_file")

    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  SPEC STRESS TEST (v$VERSION) - Completeness Check              ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Spec: ${CYAN}$spec_file${NC}"
    [[ -n "$requirements_file" ]] && echo -e "Requirements: ${CYAN}$requirements_file${NC}"
    [[ -n "$journeys_file" ]] && echo -e "User Journeys: ${CYAN}$journeys_file${NC}"
    echo ""

    # ━━━ Domain Detection ━━━
    echo -e "${BLUE}━━━ Domain Detection ━━━${NC}"
    local domain_result
    domain_result=$(resolve_domain_invariants "$spec_content")

    local invariant_refs total_invariants domain_count
    invariant_refs=$(echo "$domain_result" | sed -n '/^INVARIANT_REFS<<EOF$/,/^EOF$/p' | sed '1d;$d')
    total_invariants=$(echo "$domain_result" | grep "^TOTAL_INVARIANTS=" | cut -d= -f2)
    domain_count=$(echo "$domain_result" | grep "^DOMAIN_COUNT=" | cut -d= -f2)

    echo -e "  Domains detected: ${CYAN}$((domain_count + 1))${NC} (including universal)"
    echo -e "  Total invariants: ${CYAN}$total_invariants${NC}"
    echo -e "$invariant_refs" | while read -r line; do
        [[ -n "$line" ]] && echo -e "    ${CYAN}→${NC} $line"
    done
    echo ""

    # ━━━ Deterministic Coverage Checks ━━━
    echo -e "${BLUE}━━━ Deterministic Coverage Checks ━━━${NC}"

    local issues=()
    local warnings=()
    local coverage_items=0
    local covered_items=0

    # Check for user journey coverage indicators
    if echo "$spec_content" | grep -qiE "happy path|success.*path|normal.*flow"; then
        echo -e "  ${GREEN}✓${NC} Happy path mentioned"
        ((covered_items++))
    else
        warnings+=("Happy path not explicitly described")
    fi
    ((coverage_items++))

    if echo "$spec_content" | grep -qiE "error|fail|exception|invalid|edge.case"; then
        echo -e "  ${GREEN}✓${NC} Error cases mentioned"
        ((covered_items++))
    else
        issues+=("Error/failure cases not addressed")
    fi
    ((coverage_items++))

    if echo "$spec_content" | grep -qiE "empty|null|zero|no.*data|missing"; then
        echo -e "  ${GREEN}✓${NC} Empty/null states mentioned"
        ((covered_items++))
    else
        warnings+=("Empty/null states not explicitly handled")
    fi
    ((coverage_items++))

    if echo "$spec_content" | grep -qiE "timeout|offline|unavailable|network|api.*fail"; then
        echo -e "  ${GREEN}✓${NC} Failure modes mentioned (timeout, offline, etc.)"
        ((covered_items++))
    else
        issues+=("External failure modes not addressed (API down, timeout, offline)")
    fi
    ((coverage_items++))

    if echo "$spec_content" | grep -qiE "concurrent|race|simultaneous|parallel"; then
        echo -e "  ${GREEN}✓${NC} Concurrency considerations mentioned"
        ((covered_items++))
    else
        warnings+=("Concurrency not explicitly addressed (may not apply)")
    fi
    ((coverage_items++))

    if echo "$spec_content" | grep -qiE "limit|max|min|bound|threshold|quota"; then
        echo -e "  ${GREEN}✓${NC} Limits/boundaries mentioned"
        ((covered_items++))
    else
        warnings+=("Limits/boundaries not specified")
    fi
    ((coverage_items++))

    echo ""

    # Report issues
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo -e "${RED}Gaps (should address):${NC}"
        for issue in "${issues[@]}"; do
            echo -e "  ${RED}✗${NC} $issue"
        done
        echo ""
    fi

    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Consider (may not apply):${NC}"
        for warning in "${warnings[@]}"; do
            echo -e "  ${YELLOW}?${NC} $warning"
        done
        echo ""
    fi

    local coverage_pct=$((covered_items * 100 / coverage_items))
    echo -e "Basic Coverage: ${CYAN}$covered_items/$coverage_items ($coverage_pct%)${NC}"
    echo ""

    # ━━━ LLM Deep Analysis ━━━
    if [[ "$quick" != "true" ]]; then
        echo -e "${BLUE}━━━ LLM Deep Analysis ━━━${NC}"
        echo -e "${CYAN}Analyzing completeness...${NC}"

        # JSON schema for structured output - includes invariant violations
        local schema='{"type":"object","properties":{"summary":{"type":"string"},"invariant_violations":{"type":"array","items":{"type":"string"}},"missing_failure_modes":{"type":"array","items":{"type":"string"}},"missing_coverage":{"type":"array","items":{"type":"string"}},"critical_blockers":{"type":"array","items":{"type":"string"}}},"required":["summary","critical_blockers"]}'

        local prompt="You are a QA engineer stress-testing a specification against domain-specific invariants.

APPLICABLE INVARIANTS:
$invariant_refs

Key invariants to check:
- Invariant #1 (Ambiguity is Invalid): Every term must have operational definition
- Invariant #4 (No Irreversible Without Recovery): Destructive actions need undo/confirmation
- Invariant #5 (Execution Must Fail Loudly): Errors must be visible, not silent
- Invariant #7 (Validation Must Be Executable): Success criteria must be testable
- Invariant #10 (Degradation Path Exists): What happens when dependencies fail?

SPECIFICATION:
$spec_content"

        if [[ -n "$requirements_content" ]]; then
            prompt="$prompt

REQUIREMENTS TO COVER:
$requirements_content"
        fi

        if [[ -n "$journeys_content" ]]; then
            prompt="$prompt

USER JOURNEYS TO COVER:
$journeys_content"
        fi

        prompt="$prompt

Check this spec for violations of the applicable invariants. Be specific - reference invariant numbers.

Provide:
- summary: One sentence on overall completeness
- invariant_violations: Specific invariants that may be violated (reference by number, e.g., 'Invariant #4: delete without undo') - max 5
- missing_failure_modes: Failure scenarios required by domain but not addressed - max 5
- missing_coverage: User journey steps or requirements not covered - max 5
- critical_blockers: Questions that MUST be answered before proceeding - max 5

If you are uncertain about any assessment, flag it with [UNCERTAIN: reason]. It's better to express uncertainty than to guess."

        local raw_result result
        raw_result=$(echo "$prompt" | claude --model claude-sonnet-4-20250514 --print --output-format json --json-schema "$schema" 2>/dev/null)

        # Extract structured_output from the wrapper JSON
        result=$(echo "$raw_result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get('structured_output',{})))" 2>/dev/null)

        track_cost "$prompt" "$result"

        if [[ -n "$result" && "$result" != "{}" ]]; then
            local summary
            summary=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('summary',''))" 2>/dev/null)

            echo ""
            echo -e "Summary: $summary"
            echo ""

            # Show invariant violations
            echo -e "${RED}Invariant Violations:${NC}"
            echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    violations = data.get('invariant_violations', [])
    if violations:
        for v in violations[:5]:
            print(f'  ✗ {v}')
    else:
        print('  (None identified - invariants satisfied)')
except:
    print('  (Could not parse)')
" 2>/dev/null

            # Show missing coverage
            echo ""
            echo -e "${YELLOW}Missing Coverage:${NC}"
            echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    missing = data.get('missing_coverage', [])
    if missing:
        for m in missing[:5]:
            print(f'  ? {m}')
    else:
        print('  (None identified)')
except:
    print('  (Could not parse)')
" 2>/dev/null

            # Show failure modes to consider
            echo ""
            echo -e "${YELLOW}Failure Modes to Consider:${NC}"
            echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    missing = data.get('missing_failure_modes', [])
    if missing:
        for m in missing[:5]:
            print(f'  ? {m}')
    else:
        print('  (None identified)')
except:
    print('  (Could not parse)')
" 2>/dev/null

            # Show critical blockers
            echo ""
            echo -e "${RED}Critical Blockers:${NC}"
            echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    blockers = data.get('critical_blockers', [])
    if blockers:
        for i, b in enumerate(blockers[:5], 1):
            print(f'  {i}. {b}')
    else:
        print('  (None - ready for implementation)')
except:
    print('  (Could not parse)')
" 2>/dev/null

            echo ""
        else
            echo -e "${YELLOW}LLM call failed or returned empty${NC}"
        fi
    fi

    # ━━━ Summary ━━━
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  LIMITATIONS: This catches obvious gaps, not subtle design flaws.${NC}"
    echo -e "${CYAN}               The suggestions above matter more than this summary.${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"

    if [[ ${#issues[@]} -ge 2 ]]; then
        echo -e "  Status: ${RED}REVIEW REQUIRED${NC}"
        echo -e "  Found ${RED}${#issues[@]} gaps${NC} that likely need addressing."
        echo -e "  ${YELLOW}→ Review the suggestions above. You decide what's valid.${NC}"
    elif [[ ${#issues[@]} -ge 1 ]] || [[ ${#warnings[@]} -ge 3 ]]; then
        echo -e "  Status: ${YELLOW}ITEMS TO REVIEW${NC}"
        echo -e "  Found some potential gaps. May or may not apply to your context."
        echo -e "  ${YELLOW}→ Review the suggestions above. You decide what's valid.${NC}"
    else
        echo -e "  Status: ${GREEN}NO OBVIOUS GAPS${NC}"
        echo -e "  Basic completeness checks passed."
        echo -e "  ${YELLOW}→ This doesn't mean it's perfect. Review the suggestions anyway.${NC}"
    fi

    echo ""
    echo -e "  ${CYAN}Next step: ./design-ops-v3.sh validate $spec_file${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    [[ "$quick" != "true" ]] && show_cost_summary
    echo ""
}

cmd_validate() {
    local file="$1"
    local quick="$2"

    [[ ! -f "$file" ]] && { echo -e "${RED}File not found: $file${NC}"; exit 1; }

    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  SPEC VALIDATION (v$VERSION)                                    ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "File: ${CYAN}$file${NC}"
    echo ""

    # Deterministic checks (always run)
    local struct_output struct_grade
    struct_output=$(check_spec_structure "$file")
    echo "$struct_output" | sed '$d'  # Display all but last line (which is grade)
    struct_grade=$(echo "$struct_output" | tail -1)

    local llm_grade="SKIPPED"
    if [[ "$quick" != "true" ]]; then
        echo ""
        local llm_output
        llm_output=$(get_llm_assessment "$file" "spec")
        echo "$llm_output" | sed '$d'
        llm_grade=$(echo "$llm_output" | tail -1)
    fi

    # ━━━ Summary ━━━
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  LIMITATIONS: This checks structure and common issues, not semantic${NC}"
    echo -e "${CYAN}               correctness. The suggestions above matter more than this summary.${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"

    # Status based on structural checks only (LLM just provides suggestions)
    if [[ "$struct_grade" == "FAIL" ]]; then
        echo -e "  Status: ${RED}STRUCTURAL ISSUES${NC}"
        echo -e "  Missing required sections or has unfilled placeholders."
        echo -e "  ${YELLOW}→ Fix structural issues, then review suggestions above.${NC}"
    elif [[ "$struct_grade" == "NEEDS_WORK" ]]; then
        echo -e "  Status: ${YELLOW}ITEMS TO REVIEW${NC}"
        echo -e "  Found potential clarity issues. May or may not apply."
        echo -e "  ${YELLOW}→ Review the suggestions above. You decide what's valid.${NC}"
    else
        echo -e "  Status: ${GREEN}NO OBVIOUS GAPS${NC}"
        echo -e "  Basic structure checks passed."
        echo -e "  ${YELLOW}→ Review the suggestions above anyway.${NC}"
    fi

    echo ""
    echo -e "  ${CYAN}Next step: ./design-ops-v3.sh generate $file${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    [[ "$quick" != "true" ]] && show_cost_summary

    # Require human acknowledgment before proceeding
    require_review_acknowledgment "validate" "$file"

    echo ""
}

cmd_generate() {
    local spec_file="$1"
    local output_file="$2"

    [[ ! -f "$spec_file" ]] && { echo -e "${RED}File not found: $spec_file${NC}"; exit 1; }

    # Default output path
    if [[ -z "$output_file" ]]; then
        local basename
        basename=$(basename "$spec_file" .md)
        output_file="${spec_file%/*}/../PRPs/${basename}-prp.md"
    fi

    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  PRP GENERATION (v$VERSION)                                     ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Input:  ${CYAN}$spec_file${NC}"
    echo -e "Output: ${CYAN}$output_file${NC}"
    echo ""

    # Create output directory if needed
    mkdir -p "$(dirname "$output_file")"

    # Generate (one-shot)
    generate_prp "$spec_file" "$output_file"

    echo ""
    echo -e "${GREEN}✓ PRP generated. Running quality check...${NC}"
    echo ""

    # Automatically run check on the generated PRP
    cmd_check "$output_file" "$QUICK"
}

cmd_check() {
    local file="$1"
    local quick="$2"

    [[ ! -f "$file" ]] && { echo -e "${RED}File not found: $file${NC}"; exit 1; }

    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  PRP QUALITY CHECK (v$VERSION)                                  ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "File: ${CYAN}$file${NC}"
    echo ""

    local struct_output struct_grade
    struct_output=$(check_prp_structure "$file")
    echo "$struct_output" | sed '$d'  # Display all but last line (which is grade)
    struct_grade=$(echo "$struct_output" | tail -1)

    local llm_grade="SKIPPED"
    if [[ "$quick" != "true" ]]; then
        echo ""
        local llm_output
        llm_output=$(get_llm_assessment "$file" "prp")
        echo "$llm_output" | sed '$d'
        llm_grade=$(echo "$llm_output" | tail -1)
    fi

    # ━━━ Summary ━━━
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  LIMITATIONS: This checks PRP structure and executability, not whether${NC}"
    echo -e "${CYAN}               the requirements are correct. The suggestions matter more.${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"

    # Status based on structural checks only (LLM just provides suggestions)
    if [[ "$struct_grade" == "FAIL" ]]; then
        echo -e "  Status: ${RED}STRUCTURAL ISSUES${NC}"
        echo -e "  PRP is missing sections or has unfilled placeholders."
        echo -e "  ${YELLOW}→ Fix structural issues before implementation.${NC}"
    elif [[ "$struct_grade" == "NEEDS_WORK" ]]; then
        echo -e "  Status: ${YELLOW}ITEMS TO REVIEW${NC}"
        echo -e "  Found potential issues. May or may not apply to your context."
        echo -e "  ${YELLOW}→ Review the suggestions above. You decide what matters.${NC}"
    else
        echo -e "  Status: ${GREEN}NO OBVIOUS GAPS${NC}"
        echo -e "  Basic PRP structure checks passed."
        echo -e "  ${YELLOW}→ Review the suggestions above anyway.${NC}"
    fi

    echo ""
    echo -e "  ${CYAN}Next step: Human review, then implementation${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    [[ "$quick" != "true" ]] && show_cost_summary

    # Require human acknowledgment before proceeding
    require_review_acknowledgment "check" "$file"

    echo ""
}

# ============================================================================
# RALPH IMPLEMENTATION CHECK (validates code/steps against PRP)
# ============================================================================

check_ralph_deterministic() {
    local prp_file="$1"
    local steps_dir="$2"
    local prp_content
    prp_content=$(cat "$prp_file")

    local issues=()
    local warnings=()

    echo -e "${BLUE}━━━ Deterministic Checks ━━━${NC}"

    # 1. Extract schema definitions from PRP
    echo -e "${CYAN}Extracting PRP schema definitions...${NC}"

    # Check for Fabrics table definition in PRP
    if echo "$prp_content" | grep -qiE "fabric.*template|fabrics.*column"; then
        local fabric_fields
        fabric_fields=$(echo "$prp_content" | grep -A 10 -iE "fabric.*template" | grep -E '^\| [a-z_]+ \|' | awk -F'|' '{print $2}' | tr -d ' ' | tr '\n' ',')
        echo -e "  ${GREEN}✓${NC} Fabrics schema found: ${fabric_fields%,}"

        # Check Ralph steps for schema mismatches
        if [[ -d "$steps_dir" ]]; then
            local violations=""

            # Check for fabric_id (should be aims_code per most PRPs)
            if echo "$prp_content" | grep -qiE "aims_code"; then
                if grep -rl "fabric_id" "$steps_dir"/*.sh 2>/dev/null | head -1 >/dev/null; then
                    violations+="fabric_id→aims_code "
                    issues+=("Steps use 'fabric_id' but PRP defines 'aims_code'")
                fi
            fi

            # Check for description (should be fabric_name per most PRPs)
            if echo "$prp_content" | grep -qiE "fabric_name"; then
                if grep -rlE "description\s+TEXT|description:\s*string" "$steps_dir"/*.sh 2>/dev/null | head -1 >/dev/null; then
                    violations+="description→fabric_name "
                    issues+=("Steps use 'description' but PRP defines 'fabric_name'")
                fi
            fi

            # Check for composition (should be fabric_type per most PRPs)
            if echo "$prp_content" | grep -qiE "fabric_type"; then
                if grep -rlE "composition\s+TEXT|composition:\s*string" "$steps_dir"/*.sh 2>/dev/null | head -1 >/dev/null; then
                    violations+="composition→fabric_type "
                    issues+=("Steps use 'composition' but PRP defines 'fabric_type'")
                fi
            fi

            if [[ -z "$violations" ]]; then
                echo -e "  ${GREEN}✓${NC} Schema field names match PRP"
            fi
        fi
    else
        warnings+=("No explicit fabrics schema found in PRP")
    fi

    # 2. Check for route definitions
    echo ""
    echo -e "${CYAN}Checking route definitions...${NC}"

    local prp_routes=()
    while IFS= read -r route; do
        [[ -n "$route" ]] && prp_routes+=("$route")
    done < <(echo "$prp_content" | grep -oE '/[a-z]+(/[a-z]+)?' | sort -u)

    if [[ ${#prp_routes[@]} -gt 0 ]]; then
        echo -e "  ${GREEN}✓${NC} PRP defines routes: ${prp_routes[*]}"

        # Verify routes exist in steps
        if [[ -d "$steps_dir" ]]; then
            for route in "${prp_routes[@]}"; do
                if ! grep -rq "$route" "$steps_dir"/*.sh 2>/dev/null; then
                    warnings+=("Route '$route' defined in PRP but not found in steps")
                fi
            done
        fi
    fi

    # 3. Check success criteria coverage
    echo ""
    echo -e "${CYAN}Checking success criteria coverage...${NC}"

    local criteria_count=0
    while IFS= read -r line; do
        if echo "$line" | grep -qE '^\|[^|]+\|[^|]+\|'; then
            ((criteria_count++))
        fi
    done < <(echo "$prp_content" | sed -n '/Success Criteria/,/^##/p' | grep -E '^\|')

    if [[ $criteria_count -gt 0 ]]; then
        echo -e "  ${GREEN}✓${NC} Found $criteria_count success criteria in PRP"
    else
        warnings+=("No tabular success criteria found in PRP")
    fi

    # 4. Check validation requirements
    echo ""
    echo -e "${CYAN}Checking validation requirements...${NC}"

    if echo "$prp_content" | grep -qiE "validation|validat"; then
        # Extract specific validation rules
        local validation_rules=()
        while IFS= read -r rule; do
            [[ -n "$rule" ]] && validation_rules+=("$rule")
        done < <(echo "$prp_content" | grep -iE "must|should|required|format.*valid|unique" | head -10)

        echo -e "  ${GREEN}✓${NC} Found ${#validation_rules[@]} validation rules in PRP"
    else
        warnings+=("No validation rules found in PRP")
    fi

    echo ""

    # Report
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo -e "${RED}Issues (implementation doesn't match PRP):${NC}"
        for issue in "${issues[@]}"; do
            echo -e "  ${RED}✗${NC} $issue"
        done
    fi

    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Warnings (consider reviewing):${NC}"
        for warning in "${warnings[@]}"; do
            echo -e "  ${YELLOW}!${NC} $warning"
        done
    fi

    # Return grade
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "FAIL"
    elif [[ ${#warnings[@]} -gt 2 ]]; then
        echo "NEEDS_WORK"
    else
        echo "PASS"
    fi
}

get_ralph_llm_assessment() {
    local prp_file="$1"
    local steps_dir="$2"
    local prp_content
    prp_content=$(cat "$prp_file")

    # Get a sample of step content (first 3 steps)
    local steps_sample=""
    for step in $(ls "$steps_dir"/step-*.sh 2>/dev/null | head -3); do
        steps_sample+="--- $(basename "$step") ---"$'\n'
        steps_sample+=$(head -100 "$step")$'\n\n'
    done

    echo -e "${BLUE}━━━ LLM Advisory Assessment ━━━${NC}"
    echo -e "${CYAN}Analyzing PRP compliance...${NC}"

    local schema='{"type":"object","properties":{"summary":{"type":"string"},"compliance_gaps":{"type":"array","items":{"type":"string"}},"schema_issues":{"type":"array","items":{"type":"string"}},"missing_features":{"type":"array","items":{"type":"string"}},"strengths":{"type":"array","items":{"type":"string"}}},"required":["summary","compliance_gaps"]}'

    local prompt="You are validating that implementation steps match a PRP (Product Requirements Prompt).

PRP (SOURCE OF TRUTH):
$prp_content

IMPLEMENTATION STEPS (sample):
$steps_sample

Analyze whether the implementation follows the PRP. Provide:
- summary: One sentence on overall compliance
- compliance_gaps: Specific ways the steps deviate from PRP requirements (max 5)
- schema_issues: Field names, types, or constraints that don't match PRP definitions (max 5)
- missing_features: PRP features not addressed in the steps (max 5)
- strengths: What the implementation does well (1-2)"

    local raw_result result
    raw_result=$(echo "$prompt" | claude --model claude-sonnet-4-20250514 --print --output-format json --json-schema "$schema" 2>/dev/null)

    result=$(echo "$raw_result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get('structured_output',{})))" 2>/dev/null)

    track_cost "$prompt" "$result"

    if [[ -z "$result" || "$result" == "{}" ]]; then
        echo -e "${YELLOW}LLM call failed or returned empty${NC}"
        echo "SKIPPED"
        return
    fi

    local summary
    summary=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('summary',''))" 2>/dev/null)

    echo ""
    echo -e "Summary: $summary"
    echo ""

    echo -e "${YELLOW}Compliance Gaps:${NC}"
    echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    gaps = data.get('compliance_gaps', [])
    if gaps:
        for g in gaps[:5]:
            print(f'  ✗ {g}')
    else:
        print('  (None identified)')
except:
    print('  (Could not parse)')
" 2>/dev/null

    echo ""
    echo -e "${YELLOW}Schema Issues:${NC}"
    echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    issues = data.get('schema_issues', [])
    if issues:
        for i in issues[:5]:
            print(f'  ✗ {i}')
    else:
        print('  (None identified)')
except:
    print('  (Could not parse)')
" 2>/dev/null

    echo ""
    echo -e "${YELLOW}Missing Features:${NC}"
    echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    missing = data.get('missing_features', [])
    if missing:
        for m in missing[:5]:
            print(f'  ? {m}')
    else:
        print('  (None identified)')
except:
    print('  (Could not parse)')
" 2>/dev/null

    echo ""
    echo -e "${GREEN}Strengths:${NC}"
    echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    strengths = data.get('strengths', [])
    if strengths:
        for s in strengths[:3]:
            print(f'  ✓ {s}')
    else:
        print('  (None noted)')
except:
    print('  (Could not parse)')
" 2>/dev/null

    echo ""
    echo "DONE"
}

cmd_ralph_check() {
    local prp_file="$1"
    local steps_dir="$2"
    local quick="$3"

    [[ ! -f "$prp_file" ]] && { echo -e "${RED}PRP file not found: $prp_file${NC}"; exit 1; }
    [[ ! -d "$steps_dir" ]] && { echo -e "${RED}Steps directory not found: $steps_dir${NC}"; exit 1; }

    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  RALPH PRP COMPLIANCE CHECK (v$VERSION)                         ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "PRP:   ${CYAN}$prp_file${NC}"
    echo -e "Steps: ${CYAN}$steps_dir${NC}"
    echo ""

    # Deterministic checks
    local struct_output struct_grade
    struct_output=$(check_ralph_deterministic "$prp_file" "$steps_dir")
    echo "$struct_output" | sed '$d'
    struct_grade=$(echo "$struct_output" | tail -1)

    local llm_grade="SKIPPED"
    if [[ "$quick" != "true" ]]; then
        echo ""
        local llm_output
        llm_output=$(get_ralph_llm_assessment "$prp_file" "$steps_dir")
        echo "$llm_output" | sed '$d'
        llm_grade=$(echo "$llm_output" | tail -1)
    fi

    # Summary
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  THE PRP IS THE CONTRACT. Implementation must match PRP exactly.${NC}"
    echo -e "${CYAN}  Fix compliance gaps before proceeding with execution.${NC}"
    echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"

    if [[ "$struct_grade" == "FAIL" ]]; then
        echo -e "  Status: ${RED}COMPLIANCE ISSUES${NC}"
        echo -e "  Implementation deviates from PRP definitions."
        echo -e "  ${YELLOW}→ Fix field names, routes, or validations to match PRP.${NC}"
    elif [[ "$struct_grade" == "NEEDS_WORK" ]]; then
        echo -e "  Status: ${YELLOW}ITEMS TO REVIEW${NC}"
        echo -e "  Found potential compliance gaps. May need attention."
        echo -e "  ${YELLOW}→ Review the issues above. PRP is the source of truth.${NC}"
    else
        echo -e "  Status: ${GREEN}COMPLIANT${NC}"
        echo -e "  Implementation appears to match PRP definitions."
        echo -e "  ${YELLOW}→ Review LLM suggestions for additional insights.${NC}"
    fi

    echo ""
    echo -e "  ${CYAN}Next step: Fix issues, then execute with /design run${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    [[ "$quick" != "true" ]] && show_cost_summary

    require_review_acknowledgment "ralph-check" "$prp_file"

    echo ""
}

# ============================================================================
# DELEGATED COMMANDS (pass-through to external scripts)
# ============================================================================

# Get the root design-ops directory (parent of enforcement/)
DESIGNOPS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

delegate_command() {
    local script_path="$1"
    local command_name="$2"
    shift 2

    if [[ ! -f "$script_path" ]]; then
        echo -e "${RED}Error: '$command_name' requires $(basename "$script_path")${NC}" >&2
        echo -e "${YELLOW}Expected at: $script_path${NC}" >&2
        exit 1
    fi

    if [[ ! -x "$script_path" ]]; then
        chmod +x "$script_path"
    fi

    exec "$script_path" "$@"
}

cmd_orchestrate() {
    delegate_command "$DESIGNOPS_ROOT/tools/multi-agent-orchestrator.sh" "orchestrate" "$@"
}

cmd_watch() {
    delegate_command "$DESIGNOPS_ROOT/tools/watch-mode.sh" "watch" "$@"
}

cmd_dashboard() {
    delegate_command "$DESIGNOPS_ROOT/tools/validation-dashboard.sh" "dashboard" "$@"
}

cmd_retro() {
    delegate_command "$DESIGNOPS_ROOT/agents/retrospective.sh" "retro" "$@"
}

cmd_conventions() {
    delegate_command "$DESIGNOPS_ROOT/tools/conventions-generator.sh" "conventions" "$@"
}

# ============================================================================
# MAIN
# ============================================================================

# Handle commands that don't require a file argument
if [[ $# -eq 1 ]]; then
    case "$1" in
        dashboard) cmd_dashboard ;;
        -h|--help|help) usage ;;
        *) usage ;;
    esac
fi

[[ $# -lt 2 ]] && usage

COMMAND="$1"
FILE="$2"
shift 2

QUICK=false
VERBOSE=false
SKIP_REVIEW=false
REQUIREMENTS=""
JOURNEYS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --quick) QUICK=true; shift ;;
        --skip-review) SKIP_REVIEW=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --requirements) REQUIREMENTS="$2"; shift 2 ;;
        --journeys) JOURNEYS="$2"; shift 2 ;;
        --steps) STEPS_DIR="$2"; shift 2 ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

# Check dependencies
command -v claude &> /dev/null || { echo -e "${RED}ERROR: Claude CLI not found${NC}"; exit 1; }
command -v python3 &> /dev/null || { echo -e "${RED}ERROR: Python3 not found${NC}"; exit 1; }

case "$COMMAND" in
    # Core commands (built-in)
    stress-test) cmd_stress_test "$FILE" "$REQUIREMENTS" "$JOURNEYS" "$QUICK" ;;
    validate) cmd_validate "$FILE" "$QUICK" ;;
    generate) cmd_generate "$FILE" "$OUTPUT" ;;
    check) cmd_check "$FILE" "$QUICK" ;;
    ralph-check) cmd_ralph_check "$FILE" "$STEPS_DIR" "$QUICK" ;;
    # Advanced commands (delegated)
    orchestrate) cmd_orchestrate "$FILE" "$@" ;;
    watch) cmd_watch "$FILE" "$@" ;;
    dashboard) cmd_dashboard "$@" ;;
    retro) cmd_retro "$FILE" "$@" ;;
    conventions) cmd_conventions "$FILE" "$@" ;;
    *) echo -e "${RED}Unknown command: $COMMAND${NC}"; usage ;;
esac

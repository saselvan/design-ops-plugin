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
        echo -e "${YELLOW}[Non-interactive] No tty detected, skipping review gate${NC}"
        return 0
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

    # JSON schema for structured output - no grades, just suggestions
    local schema='{"type":"object","properties":{"summary":{"type":"string"},"suggestions":{"type":"array","items":{"type":"string"}},"strengths":{"type":"array","items":{"type":"string"}}},"required":["summary","suggestions"]}'

    local prompt
    if [[ "$type" == "spec" ]]; then
        prompt="Review this specification and provide feedback. Be concise and actionable.

SPECIFICATION:
$content

Provide:
- summary: One sentence describing what this spec covers
- suggestions: 2-5 specific actionable improvements (things to consider, not mandates)
- strengths: 1-2 things done well"
    else
        prompt="Review this PRP (Product Requirements Prompt) and provide feedback. Be concise and actionable.

PRP:
$content

Provide:
- summary: One sentence describing what this PRP covers
- suggestions: 2-5 specific actionable improvements (things to consider, not mandates)
- strengths: 1-2 things done well"
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

    echo -e "${YELLOW}Suggestions (for you to consider):${NC}"
    echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for i, s in enumerate(data.get('suggestions', [])[:5], 1):
        print(f'  {i}. {s}')
    strengths = data.get('strengths', [])
    if strengths:
        print()
        print('Strengths:')
        for s in strengths[:3]:
            print(f'  ✓ {s}')
except Exception as e:
    print(f'  (Could not parse: {e})')
" 2>/dev/null

    echo ""
    echo "DONE"  # Signal completion, not a grade
}

# ============================================================================
# PRP GENERATION (One-shot, no loops)
# ============================================================================

generate_prp() {
    local spec_file="$1"
    local output_file="$2"
    local spec_content
    spec_content=$(cat "$spec_file")

    echo -e "${BLUE}━━━ Generating PRP ━━━${NC}"
    echo -e "${CYAN}One-shot generation (no improvement loops)...${NC}"

    local prompt="Transform this specification into a Product Requirements Prompt (PRP).

SPECIFICATION:
$spec_content

OUTPUT REQUIREMENTS:
1. Start directly with the PRP content - NO preamble, NO \"Here's the PRP\", NO explanations
2. Use this structure:
   - ## Meta (prp_id, date, status)
   - ## Overview (problem, solution, scope)
   - ## Success Criteria (measurable, with numbers)
   - ## Timeline (phases with clear deliverables)
   - ## Risks (likelihood, impact, mitigation)
   - ## Validation (how to verify completion)

3. Be specific: use actual numbers, not \"fast\" or \"efficient\"
4. No placeholders like [FILL_IN] - use reasonable defaults if needed
5. Keep it actionable - an engineer should be able to start immediately

Output the PRP in markdown, starting with # PRP:"

    local result
    result=$(call_claude "$prompt")

    # Clean up: remove any preamble before the actual PRP
    local cleaned
    cleaned=$(echo "$result" | sed -n '/^# PRP\|^# .*PRP\|^## Meta/,$p')

    # If cleaning removed everything, use original
    if [[ -z "$cleaned" ]]; then
        cleaned="$result"
    fi

    # Remove markdown code block wrappers if present
    cleaned=$(echo "$cleaned" | sed '/^```markdown$/d' | sed '/^```$/d')

    echo "$cleaned" > "$output_file"

    local lines
    lines=$(wc -l < "$output_file" | tr -d ' ')
    echo -e "${GREEN}✓ Generated: $output_file ($lines lines)${NC}"
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

        # JSON schema for structured output - no grades, just suggestions
        local schema='{"type":"object","properties":{"summary":{"type":"string"},"missing_requirements":{"type":"array","items":{"type":"string"}},"missing_failure_modes":{"type":"array","items":{"type":"string"}},"critical_questions":{"type":"array","items":{"type":"string"}}},"required":["summary","critical_questions"]}'

        local prompt="You are a QA engineer stress-testing a specification for completeness.

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

Analyze this spec for completeness. Provide:
- summary: One sentence describing what this spec covers
- missing_requirements: Requirements that seem unaddressed (max 5, or empty if comprehensive)
- missing_failure_modes: Failure scenarios worth considering (max 5, or empty if comprehensive)
- critical_questions: Questions to consider before implementation (max 5)"

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

            # Show missing requirements
            echo -e "${YELLOW}Requirements to Consider:${NC}"
            echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    missing = data.get('missing_requirements', [])
    if missing:
        for m in missing[:5]:
            print(f'  ✗ {m}')
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

            # Show questions to consider
            echo ""
            echo -e "${YELLOW}Questions to Consider:${NC}"
            echo "$result" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    questions = data.get('critical_questions', [])
    if questions:
        for i, q in enumerate(questions[:5], 1):
            print(f'  {i}. {q}')
    else:
        print('  (None - spec looks comprehensive)')
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

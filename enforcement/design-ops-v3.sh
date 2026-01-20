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

set -e

VERSION="3.1.0"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cost tracking (estimates based on Claude API pricing)
TOTAL_INPUT_TOKENS=0
TOTAL_OUTPUT_TOKENS=0

usage() {
    echo "Design Ops v$VERSION - Simplified Pipeline"
    echo ""
    echo "Usage: $0 <command> <file> [options]"
    echo ""
    echo "Commands (run in this order):"
    echo "  stress-test <spec>   Check completeness (requirements, journeys, failure modes)"
    echo "  validate <spec>      Check clarity (structure, ambiguity)"
    echo "  generate <spec>      Generate PRP from spec (one-shot)"
    echo "  check <prp>          Check PRP quality"
    echo ""
    echo "Options:"
    echo "  --requirements <f>   Requirements file for stress-test (optional)"
    echo "  --journeys <f>       User journeys file for stress-test (optional)"
    echo "  --quick              Skip LLM assessment (deterministic only)"
    echo "  --verbose            Show detailed output"
    echo ""
    echo "Workflow:"
    echo "  1. stress-test  →  Is spec COMPLETE? (covers all requirements?)"
    echo "  2. validate     →  Is spec CLEAR? (well-structured, unambiguous?)"
    echo "  3. generate     →  Create PRP"
    echo "  4. check        →  Verify PRP quality"
    echo "  5. Human review →  You approve before implementation"
    echo ""
    echo "Philosophy: LLM suggests, human decides. No auto-fix loops."
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
    vague_count=$(echo "$content" | grep -ciE "properly|efficiently|adequate|reasonable|good quality|as needed" || echo "0")
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
    placeholder_count=$(grep -cE '\[FILL|\[TODO|\[TBD|\{\{' "$file" 2>/dev/null || echo "0")
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

    local prompt
    if [[ "$type" == "spec" ]]; then
        prompt="Review this specification and provide suggestions. Be concise.

SPECIFICATION:
$content

Respond with JSON only:
{
  \"grade\": \"PASS|NEEDS_WORK|FAIL\",
  \"summary\": \"One sentence assessment\",
  \"suggestions\": [
    \"Specific actionable suggestion 1\",
    \"Specific actionable suggestion 2\"
  ],
  \"strengths\": [\"What's good about this spec\"]
}"
    else
        prompt="Review this PRP (Product Requirements Prompt) and provide suggestions. Be concise.

PRP:
$content

Respond with JSON only:
{
  \"grade\": \"PASS|NEEDS_WORK|FAIL\",
  \"summary\": \"One sentence assessment\",
  \"suggestions\": [
    \"Specific actionable suggestion 1\",
    \"Specific actionable suggestion 2\"
  ],
  \"missing\": [\"Any critical missing elements\"]
}"
    fi

    local result
    result=$(call_claude "$prompt")

    local json
    json=$(extract_json "$result")

    if [[ "$json" == "{}" ]]; then
        echo -e "${YELLOW}Could not parse LLM response. Raw output:${NC}"
        echo "$result" | head -20
        return
    fi

    local grade summary
    grade=$(parse_json "$json" "grade")
    summary=$(parse_json "$json" "summary")

    echo ""
    echo -e "Grade: ${CYAN}$grade${NC}"
    echo -e "Summary: $summary"
    echo ""

    echo -e "${YELLOW}Suggestions (for human to consider):${NC}"
    echo "$json" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for i, s in enumerate(data.get('suggestions', [])[:5], 1):
        print(f'  {i}. {s}')
except:
    print('  (Could not parse suggestions)')
" 2>/dev/null

    echo ""
    echo "$grade"
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

Analyze this spec and respond with JSON:
{
  \"coverage_grade\": \"PASS|NEEDS_WORK|FAIL\",
  \"requirements_coverage\": {
    \"covered\": [\"requirement 1\", \"requirement 2\"],
    \"missing\": [\"requirement X not addressed\"]
  },
  \"user_journeys\": {
    \"covered\": [\"journey 1\"],
    \"missing\": [\"what happens when user does X?\"]
  },
  \"failure_modes\": {
    \"addressed\": [\"API timeout handled\"],
    \"missing\": [\"What if database is down?\", \"What if user has no internet?\"]
  },
  \"edge_cases\": {
    \"addressed\": [\"empty list\"],
    \"missing\": [\"max items exceeded\", \"special characters in input\"]
  },
  \"critical_questions\": [
    \"What happens if X?\",
    \"How should the system behave when Y?\"
  ],
  \"summary\": \"One sentence assessment of completeness\"
}"

        local result
        result=$(call_claude "$prompt")

        local json
        json=$(extract_json "$result")

        if [[ "$json" != "{}" ]]; then
            local grade summary
            grade=$(parse_json "$json" "coverage_grade")
            summary=$(parse_json "$json" "summary")

            echo ""
            echo -e "Coverage Grade: ${CYAN}$grade${NC}"
            echo -e "Summary: $summary"
            echo ""

            # Show missing requirements
            echo -e "${YELLOW}Missing Requirements:${NC}"
            echo "$json" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    missing = data.get('requirements_coverage', {}).get('missing', [])
    if missing:
        for m in missing[:5]:
            print(f'  ✗ {m}')
    else:
        print('  (None identified)')
except:
    print('  (Could not parse)')
" 2>/dev/null

            # Show missing failure modes
            echo ""
            echo -e "${YELLOW}Unaddressed Failure Modes:${NC}"
            echo "$json" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    missing = data.get('failure_modes', {}).get('missing', [])
    if missing:
        for m in missing[:5]:
            print(f'  ? {m}')
    else:
        print('  (None identified)')
except:
    print('  (Could not parse)')
" 2>/dev/null

            # Show critical questions
            echo ""
            echo -e "${RED}Critical Questions to Answer:${NC}"
            echo "$json" | python3 -c "
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
            echo -e "${YELLOW}Could not parse LLM response${NC}"
        fi
    fi

    # ━━━ Final Grade ━━━
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    local final_grade
    if [[ ${#issues[@]} -ge 2 ]]; then
        final_grade="FAIL"
        echo -e "  Final Grade: ${RED}$final_grade${NC}"
        echo -e "  ${RED}Spec has significant gaps. Address the issues above before proceeding.${NC}"
    elif [[ ${#issues[@]} -ge 1 ]] || [[ ${#warnings[@]} -ge 3 ]]; then
        final_grade="NEEDS_WORK"
        echo -e "  Final Grade: ${YELLOW}$final_grade${NC}"
        echo -e "  ${YELLOW}Spec is incomplete. Review gaps and add missing coverage.${NC}"
    else
        final_grade="PASS"
        echo -e "  Final Grade: ${GREEN}$final_grade${NC}"
        echo -e "  ${GREEN}Spec appears comprehensive. Proceed to validation.${NC}"
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
    local struct_grade
    struct_grade=$(check_spec_structure "$file" | tail -1)

    local llm_grade="SKIPPED"
    if [[ "$quick" != "true" ]]; then
        echo ""
        llm_grade=$(get_llm_assessment "$file" "spec" | tail -1)
    fi

    # Final grade (deterministic takes precedence)
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    local final_grade
    if [[ "$struct_grade" == "FAIL" ]]; then
        final_grade="FAIL"
        echo -e "  Final Grade: ${RED}$final_grade${NC}"
        echo -e "  ${RED}Fix the structural issues before proceeding.${NC}"
    elif [[ "$struct_grade" == "NEEDS_WORK" ]] || [[ "$llm_grade" == "NEEDS_WORK" ]]; then
        final_grade="NEEDS_WORK"
        echo -e "  Final Grade: ${YELLOW}$final_grade${NC}"
        echo -e "  ${YELLOW}Review suggestions above. You may proceed, but consider improvements.${NC}"
    else
        final_grade="PASS"
        echo -e "  Final Grade: ${GREEN}$final_grade${NC}"
        echo -e "  ${GREEN}Ready for PRP generation.${NC}"
    fi

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    [[ "$quick" != "true" ]] && show_cost_summary

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
    echo -e "${BLUE}━━━ Quick Quality Check ━━━${NC}"
    check_prp_structure "$output_file" | grep -v "^PASS$\|^FAIL$\|^NEEDS_WORK$"

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}✓ PRP generated. Please review before using.${NC}"
    echo -e "  ${CYAN}Run: $0 check $output_file${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    show_cost_summary
    echo ""
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

    local struct_grade
    struct_grade=$(check_prp_structure "$file" | tail -1)

    local llm_grade="SKIPPED"
    if [[ "$quick" != "true" ]]; then
        echo ""
        llm_grade=$(get_llm_assessment "$file" "prp" | tail -1)
    fi

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    if [[ "$struct_grade" == "FAIL" ]]; then
        echo -e "  Final Grade: ${RED}FAIL${NC}"
        echo -e "  ${RED}Fix structural issues before using this PRP.${NC}"
    elif [[ "$struct_grade" == "NEEDS_WORK" ]] || [[ "$llm_grade" == "NEEDS_WORK" ]]; then
        echo -e "  Final Grade: ${YELLOW}NEEDS_WORK${NC}"
        echo -e "  ${YELLOW}Consider the suggestions above before proceeding.${NC}"
    else
        echo -e "  Final Grade: ${GREEN}PASS${NC}"
        echo -e "  ${GREEN}PRP looks ready for implementation.${NC}"
    fi

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

    [[ "$quick" != "true" ]] && show_cost_summary
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

[[ $# -lt 2 ]] && usage

COMMAND="$1"
FILE="$2"
shift 2

QUICK=false
VERBOSE=false
REQUIREMENTS=""
JOURNEYS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --quick) QUICK=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --requirements) REQUIREMENTS="$2"; shift 2 ;;
        --journeys) JOURNEYS="$2"; shift 2 ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

# Check dependencies
command -v claude &> /dev/null || { echo -e "${RED}ERROR: Claude CLI not found${NC}"; exit 1; }
command -v python3 &> /dev/null || { echo -e "${RED}ERROR: Python3 not found${NC}"; exit 1; }

case "$COMMAND" in
    stress-test) cmd_stress_test "$FILE" "$REQUIREMENTS" "$JOURNEYS" "$QUICK" ;;
    validate) cmd_validate "$FILE" "$QUICK" ;;
    generate) cmd_generate "$FILE" "$OUTPUT" ;;
    check) cmd_check "$FILE" "$QUICK" ;;
    *) echo -e "${RED}Unknown command: $COMMAND${NC}"; usage ;;
esac

#!/bin/bash
# prp-checker.sh - Quality checker for generated PRPs
#
# Validates that PRPs have all required sections and meet quality standards.
# Exit code: 0 if passes (warnings OK), 1 if fails (missing required sections)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
ERRORS=0
WARNINGS=0
SCORE=100

# Usage
usage() {
    echo "Usage: $0 <prp-file.md> [--verbose]"
    echo ""
    echo "Options:"
    echo "  --verbose    Show detailed check output"
    echo ""
    echo "Example:"
    echo "  $0 output/my-project-prp.md"
    exit 1
}

# Check arguments
if [[ $# -lt 1 ]]; then
    usage
fi

PRP_FILE="$1"
VERBOSE=false

if [[ "$2" == "--verbose" ]]; then
    VERBOSE=true
fi

if [[ ! -f "$PRP_FILE" ]]; then
    echo -e "${RED}ERROR: File not found: $PRP_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  PRP Quality Checker${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Checking: ${CYAN}$PRP_FILE${NC}"
echo ""

# Read file content
CONTENT=$(cat "$PRP_FILE")

# ============================================================================
# Helper Functions
# ============================================================================

check_section() {
    local section_name="$1"
    local pattern="$2"
    local is_required="$3"

    if echo "$CONTENT" | grep -qi "$pattern"; then
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "  ${GREEN}✓${NC} Section found: $section_name"
        fi
        return 0
    else
        if [[ "$is_required" == "required" ]]; then
            echo -e "  ${RED}✗ MISSING REQUIRED:${NC} $section_name"
            ((ERRORS++))
            ((SCORE-=15))
        else
            echo -e "  ${YELLOW}⚠ Missing optional:${NC} $section_name"
            ((WARNINGS++))
            ((SCORE-=5))
        fi
        return 1
    fi
}

check_quality() {
    local check_name="$1"
    local pattern="$2"
    local inverse="$3"

    if [[ "$inverse" == "inverse" ]]; then
        # Check that pattern is NOT present
        if echo "$CONTENT" | grep -qiE "$pattern"; then
            echo -e "  ${YELLOW}⚠ WARNING:${NC} $check_name"
            ((WARNINGS++))
            ((SCORE-=3))
            return 1
        fi
    else
        # Check that pattern IS present
        if ! echo "$CONTENT" | grep -qiE "$pattern"; then
            echo -e "  ${YELLOW}⚠ WARNING:${NC} $check_name"
            ((WARNINGS++))
            ((SCORE-=3))
            return 1
        fi
    fi
    return 0
}

# ============================================================================
# SECTION 1: Required Sections Check (Blocking)
# ============================================================================

echo -e "${BLUE}─── Required Sections ───${NC}"

check_section "Success Criteria" "## .*Success Criteria" "required"
check_section "Timeline with Validation Gates" "## .*Timeline\|Validation Gate" "required"
check_section "Risk Assessment" "## .*Risk" "required"
check_section "Resource Requirements" "## .*Resource" "required"
check_section "Communication Plan" "## .*Communication" "required"

# Additional required elements
if ! echo "$CONTENT" | grep -qE "Validation Gate|GATE_.*_PASS|Gate [0-9]"; then
    echo -e "  ${RED}✗ MISSING REQUIRED:${NC} Validation gates with pass/fail criteria"
    ((ERRORS++))
    ((SCORE-=10))
fi

echo ""

# ============================================================================
# SECTION 2: Quality Standards (Warnings)
# ============================================================================

echo -e "${BLUE}─── Quality Standards ───${NC}"

# Check for measurable success criteria (not vague terms)
VAGUE_METRICS="works well|good quality|performs well|efficient|intuitive|seamless|robust"
if echo "$CONTENT" | grep -i "Success Criteria" -A 30 | grep -qiE "$VAGUE_METRICS"; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} Success criteria contain vague terms"
    echo -e "     ${CYAN}Fix: Use specific metrics (e.g., '<1% error rate' not 'works well')${NC}"
    ((WARNINGS++))
    ((SCORE-=5))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Success criteria are measurable"
    fi
fi

# Check for specific dates (not vague timeline)
VAGUE_TIMELINE="soon|later|eventually|when ready|as needed|TBD|TBA"
if echo "$CONTENT" | grep -i "Timeline\|Phase\|Duration" -A 10 | grep -qiE "$VAGUE_TIMELINE"; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} Timeline uses vague terms"
    echo -e "     ${CYAN}Fix: Use specific durations ('2 weeks') or dates (YYYY-MM-DD)${NC}"
    ((WARNINGS++))
    ((SCORE-=5))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Timeline has specific dates/durations"
    fi
fi

# Check that risks have mitigation plans
RISK_COUNT=$(echo "$CONTENT" | grep -c "| Risk |" 2>/dev/null || true)
RISK_COUNT=${RISK_COUNT:-0}
MITIGATION_COUNT=$(echo "$CONTENT" | grep -ciE "mitigation|fallback|if.*then" 2>/dev/null || true)
MITIGATION_COUNT=${MITIGATION_COUNT:-0}
if [[ "$RISK_COUNT" -gt 0 ]] 2>/dev/null && [[ "$MITIGATION_COUNT" -lt 1 ]] 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} Risks listed but no mitigation plans found"
    echo -e "     ${CYAN}Fix: Add mitigation strategy for each identified risk${NC}"
    ((WARNINGS++))
    ((SCORE-=5))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Risks have mitigation plans"
    fi
fi

# Check validation gates have pass/fail criteria
GATE_COUNT=$(echo "$CONTENT" | grep -ciE "Validation Gate|Gate [0-9]" 2>/dev/null || true)
GATE_COUNT=${GATE_COUNT:-0}
PASS_CRITERIA=$(echo "$CONTENT" | grep -ciE "GATE.*PASS|Pass Condition|pass/fail" 2>/dev/null || true)
PASS_CRITERIA=${PASS_CRITERIA:-0}
if [[ "$GATE_COUNT" -gt 0 ]] 2>/dev/null && [[ "$PASS_CRITERIA" -lt 1 ]] 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} Validation gates lack explicit pass/fail criteria"
    echo -e "     ${CYAN}Fix: Add 'GATE_X_PASS := condition' for each gate${NC}"
    ((WARNINGS++))
    ((SCORE-=5))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Validation gates have pass/fail criteria"
    fi
fi

# Check for unfilled placeholders
PLACEHOLDER_COUNT=$(echo "$CONTENT" | grep -cE "\{\{[A-Z_]+\}\}|\[FILL.*\]|\[TODO\]|\[TBD\]" 2>/dev/null || true)
PLACEHOLDER_COUNT=${PLACEHOLDER_COUNT:-0}
PLACEHOLDER_COUNT=$(echo "$PLACEHOLDER_COUNT" | tr -d '\n' | head -c 10)
if [[ "$PLACEHOLDER_COUNT" -gt 0 ]] 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} Found $PLACEHOLDER_COUNT unfilled placeholders"
    echo -e "     ${CYAN}Fix: Replace all {{VARIABLE}} and [FILL_THIS_IN] placeholders${NC}"
    ((WARNINGS++))
    ((SCORE-=3))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} No unfilled placeholders"
    fi
fi

echo ""

# ============================================================================
# SECTION 3: Format Checks (Warnings)
# ============================================================================

echo -e "${BLUE}─── Format Checks ───${NC}"

# Check for task checkboxes
CHECKBOX_COUNT=$(echo "$CONTENT" | grep -cE "^[[:space:]]*- \[ \]" 2>/dev/null || true)
CHECKBOX_COUNT=${CHECKBOX_COUNT:-0}
if [[ "$CHECKBOX_COUNT" -lt 1 ]] 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} No task checkboxes found"
    echo -e "     ${CYAN}Fix: Use '- [ ] Task name' format for deliverables${NC}"
    ((WARNINGS++))
    ((SCORE-=2))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Task checkboxes present ($CHECKBOX_COUNT found)"
    fi
fi

# Check for table format in timeline/resources
TABLE_COUNT=$(echo "$CONTENT" | grep -cE "^\|.*\|$" 2>/dev/null || true)
TABLE_COUNT=${TABLE_COUNT:-0}
if [[ "$TABLE_COUNT" -lt 3 ]] 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} Few tables found - consider using tables for structured data"
    echo -e "     ${CYAN}Fix: Use markdown tables for metrics, resources, timelines${NC}"
    ((WARNINGS++))
    ((SCORE-=2))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Tables used for structured data"
    fi
fi

# Check for broken internal references
BROKEN_REFS=$(echo "$CONTENT" | grep -oE "\[.*\]\(\)" | head -5)
if [[ -n "$BROKEN_REFS" ]]; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} Broken markdown links found"
    echo -e "     ${CYAN}Found: $(echo "$BROKEN_REFS" | tr '\n' ' ')${NC}"
    ((WARNINGS++))
    ((SCORE-=2))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} No broken markdown links"
    fi
fi

# Check for state transitions (good practice)
if ! echo "$CONTENT" | grep -qE "→|STATE:|state:"; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} No state transition diagram found"
    echo -e "     ${CYAN}Fix: Add state machine showing project flow${NC}"
    ((WARNINGS++))
    ((SCORE-=2))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} State transitions documented"
    fi
fi

# Check for rollback/recovery procedures
if ! echo "$CONTENT" | grep -qiE "rollback|recovery|fallback|if.*fails"; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} No rollback/recovery procedures documented"
    echo -e "     ${CYAN}Fix: Document what happens if things go wrong${NC}"
    ((WARNINGS++))
    ((SCORE-=3))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Rollback/recovery procedures present"
    fi
fi

echo ""

# ============================================================================
# SECTION 4: Validation Commands Check
# ============================================================================

echo -e "${BLUE}─── Validation Commands ───${NC}"

# Check for validation commands section
if ! echo "$CONTENT" | grep -qiE "## [0-9]*\.? *Validation Commands"; then
    echo -e "  ${RED}✗ MISSING REQUIRED:${NC} Validation Commands section"
    echo -e "     ${CYAN}Fix: Add '## Validation Commands' section with bash commands${NC}"
    ((ERRORS++))
    ((SCORE-=10))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Validation Commands section found"
    fi

    # Check for actual bash code blocks in validation section
    VALIDATION_SECTION=$(echo "$CONTENT" | sed -n '/## [0-9]*\.* *Validation Commands/,/^## [0-9]/p')
    BASH_BLOCKS=$(echo "$VALIDATION_SECTION" | grep -c '```bash' 2>/dev/null || true)
    BASH_BLOCKS=${BASH_BLOCKS:-0}

    if [[ "$BASH_BLOCKS" -lt 1 ]]; then
        echo -e "  ${YELLOW}⚠ WARNING:${NC} No bash code blocks in Validation Commands"
        echo -e "     ${CYAN}Fix: Add actual bash commands, not just descriptions${NC}"
        ((WARNINGS++))
        ((SCORE-=5))
    elif [[ "$BASH_BLOCKS" -lt 3 ]]; then
        echo -e "  ${YELLOW}⚠ WARNING:${NC} Only $BASH_BLOCKS bash blocks - recommend at least 3"
        echo -e "     ${CYAN}Fix: Include tests, linting, and integration checks${NC}"
        ((WARNINGS++))
        ((SCORE-=3))
    else
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "  ${GREEN}✓${NC} Validation commands include $BASH_BLOCKS bash blocks"
        fi
    fi

    # Check for actual commands (not just placeholders)
    PLACEHOLDER_CMDS=$(echo "$VALIDATION_SECTION" | grep -c "{{VALIDATION_" 2>/dev/null || true)
    PLACEHOLDER_CMDS=${PLACEHOLDER_CMDS:-0}
    if [[ "$PLACEHOLDER_CMDS" -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠ WARNING:${NC} $PLACEHOLDER_CMDS unfilled validation command placeholders"
        echo -e "     ${CYAN}Fix: Replace {{VALIDATION_*}} with actual commands${NC}"
        ((WARNINGS++))
        ((SCORE-=3))
    else
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "  ${GREEN}✓${NC} No unfilled validation placeholders"
        fi
    fi
fi

echo ""

# ============================================================================
# SECTION 5: Additional Checks
# ============================================================================

echo -e "${BLUE}─── Additional Checks ───${NC}"

# Check for meta section
if ! echo "$CONTENT" | grep -qE "prp_id:|PRP_ID|source_spec:"; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} Meta section incomplete or missing"
    echo -e "     ${CYAN}Fix: Add prp_id, source_spec, validation_status${NC}"
    ((WARNINGS++))
    ((SCORE-=2))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Meta section present"
    fi
fi

# Check for pre-execution checklist
if ! echo "$CONTENT" | grep -qiE "pre-execution|pre-deployment|checklist"; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} Pre-execution checklist missing"
    echo -e "     ${CYAN}Fix: Add checklist to verify before starting${NC}"
    ((WARNINGS++))
    ((SCORE-=2))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Pre-execution checklist present"
    fi
fi

# Check for owner assignments
OWNER_COUNT=$(echo "$CONTENT" | grep -ciE "owner:|owner\s*\|" 2>/dev/null || true)
OWNER_COUNT=${OWNER_COUNT:-0}
if [[ "$OWNER_COUNT" -lt 3 ]] 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ WARNING:${NC} Few owner assignments found"
    echo -e "     ${CYAN}Fix: Assign owners to phases, risks, and communications${NC}"
    ((WARNINGS++))
    ((SCORE-=2))
else
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Owner assignments present"
    fi
fi

echo ""

# ============================================================================
# Summary
# ============================================================================

# Clamp score to 0-100
if [[ $SCORE -lt 0 ]]; then
    SCORE=0
fi
if [[ $SCORE -gt 100 ]]; then
    SCORE=100
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}❌ ERRORS: $ERRORS (blocking issues)${NC}"
fi

if [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  WARNINGS: $WARNINGS${NC}"
fi

echo ""

# Color score based on value
if [[ $SCORE -ge 90 ]]; then
    SCORE_COLOR=$GREEN
elif [[ $SCORE -ge 70 ]]; then
    SCORE_COLOR=$YELLOW
else
    SCORE_COLOR=$RED
fi

echo -e "PRP Quality Score: ${SCORE_COLOR}${SCORE}/100${NC}"
echo ""

# Final result
if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}❌ PRP FAILED - Missing required sections${NC}"
    echo ""
    echo "Required sections that must be added:"
    echo "  - Success criteria with measurable metrics"
    echo "  - Timeline with validation gates"
    echo "  - Risk assessment with mitigation plans"
    echo "  - Resource requirements"
    echo "  - Communication plan"
    exit 1
else
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${GREEN}✅ PRP PASSED${NC} (with $WARNINGS warnings)"
        echo ""
        echo "Consider addressing warnings to improve quality."
    else
        echo -e "${GREEN}✅ PRP PASSED - Excellent quality!${NC}"
    fi
    exit 0
fi

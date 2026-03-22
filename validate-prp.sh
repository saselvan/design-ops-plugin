#!/bin/bash
#
# validate-prp.sh — Lightweight PRP validator for Design Ops v3.1
#
# Checks a PRP file against invariants and completeness requirements.
# Portable: requires only bash, grep, awk. No external dependencies.
#
# Usage:
#   ./validate-prp.sh path/to/my-prp.md
#   ./validate-prp.sh path/to/my-prp.md --strict   # treat advisory as blocking
#
# Exit codes:
#   0 = PASS (all checks passed)
#   1 = WARN (advisory issues found)
#   2 = FAIL (blocking issues found)
#   3 = HARD STOP (Red confidence score — requires human override)

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PRP_FILE="${1:-}"
STRICT="${2:-}"

if [[ -z "$PRP_FILE" ]]; then
    echo "Usage: validate-prp.sh <prp-file> [--strict]"
    exit 1
fi

if [[ ! -f "$PRP_FILE" ]]; then
    echo -e "${RED}FAIL${NC}: File not found: $PRP_FILE"
    exit 2
fi

ERRORS=0
WARNINGS=0
CHECKS=0
HARD_STOP=0

pass() {
    CHECKS=$((CHECKS + 1))
    echo -e "  ${GREEN}✓${NC} $1"
}

warn() {
    CHECKS=$((CHECKS + 1))
    WARNINGS=$((WARNINGS + 1))
    echo -e "  ${YELLOW}!${NC} $1"
}

fail() {
    CHECKS=$((CHECKS + 1))
    ERRORS=$((ERRORS + 1))
    echo -e "  ${RED}✗${NC} $1"
}

hard_stop() {
    CHECKS=$((CHECKS + 1))
    HARD_STOP=1
    echo -e "  ${RED}${BOLD}⛔ HARD STOP${NC} $1"
}

echo -e "${CYAN}━━━ PRP Validator v3.1 ━━━${NC}"
echo "File: $PRP_FILE"
echo ""

# ─── SECTION 1: Structure checks ───────────────────────────────────

echo -e "${CYAN}Structure${NC}"

check_section() {
    local label="$1"
    shift
    for pattern in "$@"; do
        if grep -qiE "$pattern" "$PRP_FILE" 2>/dev/null; then
            pass "Section found: $label"
            return
        fi
    done
    fail "Missing section: $label"
}

check_section "Meta/Header"           "^## Meta" "^##.*Meta" "confidence_score:"
check_section "Problem/Overview"      "^##.*Problem" "^##.*Project Overview" "^##.*Overview"
check_section "Success Criteria"      "^##.*Success" "SUCCESS :=" "success.criter"
check_section "Scope & Dependencies"  "^##.*Scope" "^##.*Depend" "^##.*Component" "dependency.map\|CONSUMERS:"
check_section "Risks/Fallbacks"       "^##.*Risk" "circuit.breaker" "fallback"
check_section "Validation Commands"   "^##.*Validation" "bash"

# ─── SECTION 2: Unfilled placeholders ──────────────────────────────

echo ""
echo -e "${CYAN}Placeholders${NC}"

placeholder_count=$(grep -c '{{[A-Z_]*}}' "$PRP_FILE" 2>/dev/null || true)
if [[ "$placeholder_count" -gt 0 ]]; then
    fail "$placeholder_count unfilled {{PLACEHOLDER}} tokens found"
    grep -n '{{[A-Z_]*}}' "$PRP_FILE" | head -5 | while read -r line; do
        echo "       $line"
    done
    remaining=$((placeholder_count - 5))
    if [[ $remaining -gt 0 ]]; then
        echo "       ... and $remaining more"
    fi
else
    pass "No unfilled placeholders"
fi

# ─── SECTION 3: Confidence score ───────────────────────────────────

echo ""
echo -e "${CYAN}Confidence${NC}"

if grep -q 'confidence_score:' "$PRP_FILE" 2>/dev/null; then
    score=$(grep 'confidence_score:' "$PRP_FILE" | head -1 | grep -oE '[0-9]+\.?[0-9]*' | head -1)
    if [[ -n "$score" ]]; then
        if awk "BEGIN {exit !($score >= 1.0 && $score <= 10.0)}" 2>/dev/null; then
            pass "Confidence score: $score/10"
            if awk "BEGIN {exit !($score < 4.0)}" 2>/dev/null; then
                hard_stop "Confidence score is RED ($score). Pipeline BLOCKED. To proceed, human must explicitly type 'proceed with risk'."
            elif awk "BEGIN {exit !($score < 7.0)}" 2>/dev/null; then
                warn "Confidence score is YELLOW ($score). Proceed with explicit risk acknowledgment."
            fi
        else
            fail "Confidence score out of range: $score"
        fi
    else
        fail "Confidence score present but not parseable"
    fi
else
    fail "No confidence_score found in Meta section"
fi

if grep -q 'requirement_clarity:' "$PRP_FILE" 2>/dev/null; then
    pass "Confidence breakdown present"
else
    warn "Confidence breakdown missing (5 factors expected)"
fi

# ─── SECTION 4: Success criteria ───────────────────────────────────

echo ""
echo -e "${CYAN}Success Criteria${NC}"

if grep -q 'SUCCESS :=' "$PRP_FILE" 2>/dev/null; then
    pass "SUCCESS conditions defined"
else
    fail "No SUCCESS := conditions found"
fi

if grep -q 'FAILURE :=' "$PRP_FILE" 2>/dev/null; then
    pass "FAILURE conditions defined"
else
    warn "No FAILURE := conditions found"
fi

# Check for provable-by-test markers
if grep -qi 'provable.*test\|verified.*by\|observe.*prod' "$PRP_FILE" 2>/dev/null; then
    pass "Success criteria tagged as provable/observable"
else
    warn "Success criteria not tagged as 'provable by test' vs 'observe in prod'"
fi

# ─── SECTION 5: Scope & Dependencies ──────────────────────────────

echo ""
echo -e "${CYAN}Scope & Dependencies${NC}"

# Check for component listing
if grep -qiE 'component|module' "$PRP_FILE" 2>/dev/null; then
    pass "Components/modules listed"
else
    warn "No components or modules listed"
fi

# Check for dependency map
if grep -qiE 'dependency.map|depends.on|CONSUMERS:|→.*produces' "$PRP_FILE" 2>/dev/null; then
    pass "Dependency relationships defined"
else
    warn "No dependency map found — needed for vertical slicing in /prp-to-issues"
fi

# Check for component contracts
if grep -qiE 'contract|interface|output.*type|input.*type|CONSUMERS:' "$PRP_FILE" 2>/dev/null; then
    pass "Component contracts/interfaces defined"
else
    warn "No component contracts — integration tests need these"
fi

# ─── SECTION 6: Validation commands ────────────────────────────────

echo ""
echo -e "${CYAN}Validation Commands${NC}"

bash_blocks=$(grep -c '```bash' "$PRP_FILE" 2>/dev/null || true)
if [[ "$bash_blocks" -gt 0 ]]; then
    pass "$bash_blocks bash code block(s) with validation commands"
else
    fail "No bash code blocks found — PRP must include copy-pasteable validation commands"
fi

# Check for e2e smoke test
if grep -qi 'e2e\|smoke.test\|end.to.end\|full.*workflow' "$PRP_FILE" 2>/dev/null; then
    pass "E2E / smoke test referenced"
else
    warn "No e2e smoke test mentioned — define per domain in .designops"
fi

# Check for integration test
if grep -qi 'integration.test\|work.*together\|components.*together' "$PRP_FILE" 2>/dev/null; then
    pass "Integration testing referenced"
else
    warn "No integration testing mentioned"
fi

# ─── SECTION 7: Invariant checks (advisory) ────────────────────────

echo ""
echo -e "${CYAN}Invariant Signals${NC}"

# #1 Ambiguity
ambiguous_terms=("properly" "easily" "quality" "user-friendly" "intuitive" "good" "simple" "nice")
ambig_found=0
for term in "${ambiguous_terms[@]}"; do
    if grep -qi "\b${term}\b" "$PRP_FILE" 2>/dev/null; then
        ambig_found=$((ambig_found + 1))
    fi
done
if [[ "$ambig_found" -gt 0 ]]; then
    warn "INV #1: $ambig_found ambiguous term(s) found (properly, easily, quality, etc.) — ensure they have operational definitions"
else
    pass "INV #1: No obvious ambiguous terms"
fi

# #5 Silent failures
if grep -qi 'gracefully\|silently\|ignore.*error\|swallow' "$PRP_FILE" 2>/dev/null; then
    warn "INV #5: Silent failure language detected (gracefully, silently) — errors should fail loudly"
else
    pass "INV #5: No silent failure language"
fi

# #6 Unbounded scope
if grep -qi '\ball\b.*records\|\ball\b.*users\|\bentire\b.*dataset\|\beverything\b' "$PRP_FILE" 2>/dev/null; then
    warn "INV #6: Unbounded scope language detected (all records, entire dataset) — add limits"
else
    pass "INV #6: No unbounded scope language"
fi

# #4 Irreversible actions
if grep -qi '\bdelete\b\|\bdrop\b\|\bremove\b\|\bdestroy\b' "$PRP_FILE" 2>/dev/null; then
    if grep -qi 'undo\|recovery\|soft.delete\|backup\|rollback\|restore' "$PRP_FILE" 2>/dev/null; then
        pass "INV #4: Destructive actions found WITH recovery mechanisms"
    else
        warn "INV #4: Destructive actions found but no recovery mechanism mentioned"
    fi
else
    pass "INV #4: No destructive actions detected"
fi

# ─── SECTION 8: Domain detection ───────────────────────────────────

echo ""
echo -e "${CYAN}Domain${NC}"

if grep -q 'domain:' "$PRP_FILE" 2>/dev/null; then
    domain=$(grep 'domain:' "$PRP_FILE" | head -1 | awk '{print $2}')
    pass "Domain declared: $domain"

    # Healthcare/security = stricter
    if [[ "$domain" == *"healthcare"* ]] || [[ "$domain" == *"security"* ]] || [[ "$domain" == *"hls"* ]]; then
        echo -e "  ${YELLOW}↑${NC} Healthcare/security domain — all domain invariants are BLOCKING"
        if grep -qi 'compliance\|hipaa\|phi\|fda\|audit' "$PRP_FILE" 2>/dev/null; then
            pass "Compliance language present"
        else
            fail "Healthcare/security domain but no compliance requirements mentioned"
        fi
    fi
else
    warn "No domain declared in Meta section"
fi

# ─── SUMMARY ───────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}━━━ Summary ━━━${NC}"
echo "  Checks: $CHECKS"
echo -e "  Passed: ${GREEN}$((CHECKS - ERRORS - WARNINGS - HARD_STOP))${NC}"
echo -e "  Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "  Errors: ${RED}$ERRORS${NC}"
if [[ "$HARD_STOP" -gt 0 ]]; then
    echo -e "  Hard stops: ${RED}${BOLD}$HARD_STOP${NC}"
fi
echo ""

if [[ "$HARD_STOP" -gt 0 ]]; then
    echo -e "${RED}${BOLD}RESULT: HARD STOP${NC} — Red confidence score. Pipeline BLOCKED."
    echo -e "Human must explicitly acknowledge risk before proceeding."
    exit 3
elif [[ "$ERRORS" -gt 0 ]]; then
    echo -e "${RED}RESULT: FAIL${NC} — $ERRORS blocking issue(s) must be resolved"
    exit 2
elif [[ "$WARNINGS" -gt 0 ]]; then
    if [[ "$STRICT" == "--strict" ]]; then
        echo -e "${YELLOW}RESULT: FAIL (strict mode)${NC} — $WARNINGS advisory issue(s) treated as blocking"
        exit 2
    else
        echo -e "${YELLOW}RESULT: WARN${NC} — $WARNINGS advisory issue(s), consider addressing"
        exit 1
    fi
else
    echo -e "${GREEN}RESULT: PASS${NC} — all checks passed"
    exit 0
fi

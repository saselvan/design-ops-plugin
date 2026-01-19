#!/bin/bash
# validator.sh - Invariant Violation Checker
# Usage: ./validator.sh <spec_file> [--invariants <file>] [--domain <file>]
# 
# This script enforces the invariant system by scanning specs for violations
# before they're compiled into PRPs. Think of it as a type checker for specs.

set -e

VERSION="1.0.0"
SPEC_FILE=""
INVARIANTS_FILE="system-invariants.md"
DOMAIN_FILES=()
VIOLATIONS_FOUND=0
WARNINGS_FOUND=0

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --invariants)
            INVARIANTS_FILE="$2"
            shift 2
            ;;
        --domain)
            DOMAIN_FILES+=("$2")
            shift 2
            ;;
        --version)
            echo "validator.sh version $VERSION"
            exit 0
            ;;
        --help)
            echo "Usage: ./validator.sh <spec_file> [--invariants <file>] [--domain <file>]"
            echo ""
            echo "Arguments:"
            echo "  <spec_file>           Spec or PRP file to validate (required)"
            echo "  --invariants <file>   Path to core invariants file (default: system-invariants.md)"
            echo "  --domain <file>       Domain-specific invariants to apply (can be repeated)"
            echo "  --version             Show version"
            echo "  --help                Show this help"
            echo ""
            echo "Example:"
            echo "  ./validator.sh specs/new-feature.md"
            echo "  ./validator.sh specs/house.md --domain domains/physical-construction.md"
            exit 0
            ;;
        *)
            if [[ -z "$SPEC_FILE" ]]; then
                SPEC_FILE="$1"
            else
                echo -e "${RED}Error: Unknown argument '$1'${NC}"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [[ -z "$SPEC_FILE" ]]; then
    echo -e "${RED}Error: Spec file required${NC}"
    echo "Usage: ./validator.sh <spec_file>"
    exit 1
fi

if [[ ! -f "$SPEC_FILE" ]]; then
    echo -e "${RED}Error: Spec file '$SPEC_FILE' not found${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Invariant Validator v$VERSION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "Validating: $SPEC_FILE"
echo "Core invariants: $INVARIANTS_FILE"
for domain in "${DOMAIN_FILES[@]}"; do
    echo "Domain: $domain"
done
echo ""

# Helper function to report violation
report_violation() {
    local invariant_num="$1"
    local invariant_name="$2"
    local line_num="$3"
    local violation_text="$4"
    local fix_suggestion="$5"
    
    ((VIOLATIONS_FOUND++))
    echo -e "${RED}❌ VIOLATION: Invariant #$invariant_num ($invariant_name)${NC}"
    echo -e "   ${RED}Line $line_num:${NC} \"$violation_text\""
    echo -e "   ${YELLOW}→ Fix:${NC} $fix_suggestion"
    echo ""
}

# Helper function to report warning
report_warning() {
    local message="$1"
    local line_num="$2"
    
    ((WARNINGS_FOUND++))
    echo -e "${YELLOW}⚠️  WARNING:${NC} $message"
    if [[ -n "$line_num" ]]; then
        echo -e "   ${YELLOW}Line $line_num${NC}"
    fi
    echo ""
}

# Read spec file
SPEC_CONTENT=$(cat "$SPEC_FILE")

echo -e "${BLUE}Checking Universal Invariants...${NC}"
echo ""

# ============================================================================
# INVARIANT 1: Ambiguity is Invalid
# ============================================================================
echo "Checking Invariant #1: Ambiguity is Invalid..."

AMBIGUOUS_WORDS=("properly" "easily" "good" "quality" "intuitive" "efficiently" "effectively" "appropriately" "better" "improved" "optimized" "user-friendly" "seamless")

line_num=0
while IFS= read -r line; do
    ((line_num++))

    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ \<\!-- ]] && continue
    [[ -z "${line// }" ]] && continue

    # Check for ambiguous words
    for word in "${AMBIGUOUS_WORDS[@]}"; do
        if echo "$line" | grep -qi "\b$word\b"; then
            # Check if line has explicit definition (contains := or →)
            if ! echo "$line" | grep -q '\(:=\|→\|=\|:\s*[A-Z].*\)'; then
                violation_text=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -c1-80)
                report_violation "1" "Ambiguity is Invalid" "$line_num" "$violation_text" \
                    "Replace '$word' with objective criteria: metric + threshold + measurement"
                break
            fi
        fi
    done
done <<< "$SPEC_CONTENT"

# ============================================================================
# INVARIANT 2: State Must Be Explicit
# ============================================================================
echo "Checking Invariant #2: State Must Be Explicit..."

STATE_CHANGE_VERBS=("update" "change" "modify" "sync" "alter" "set" "transform" "migrate")

line_num=0
while IFS= read -r line; do
    ((line_num++))

    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ \<\!-- ]] && continue
    [[ -z "${line// }" ]] && continue

    # Check for state change verbs
    for verb in "${STATE_CHANGE_VERBS[@]}"; do
        if echo "$line" | grep -qi "\b$verb\b"; then
            # Check if line has explicit state transition (contains →)
            if ! echo "$line" | grep -q '→'; then
                # Check if it's part of a longer explanation (has := or detailed description)
                if ! echo "$line" | grep -q '\(:=\|:\s*[A-Z]\)'; then
                    violation_text=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -c1-80)
                    report_violation "2" "State Must Be Explicit" "$line_num" "$violation_text" \
                        "Use format: before_state → action → after_state"
                    break
                fi
            fi
        fi
    done
done <<< "$SPEC_CONTENT"

# ============================================================================
# INVARIANT 3: Emotional Intent Must Compile
# ============================================================================
echo "Checking Invariant #3: Emotional Intent Must Compile..."

EMOTION_WORDS=("feel" "should" "comfortable" "confident" "happy" "satisfied" "pleased" "trust" "believe" "expect")

line_num=0
while IFS= read -r line; do
    ((line_num++))
    
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ \<\!-- ]] && continue
    [[ -z "${line// }" ]] && continue

    # Check for emotion words
    for word in "${EMOTION_WORDS[@]}"; do
        if echo "$line" | grep -qi "\b$word\b"; then
            # Check if line has compilation (:= for defining the emotion)
            if ! echo "$line" | grep -q ':='; then
                violation_text=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -c1-80)
                report_violation "3" "Emotional Intent Must Compile" "$line_num" "$violation_text" \
                    "Use format: emotion := concrete_mechanism (e.g., confident := show_success_rate + undo_option)"
                break
            fi
        fi
    done
done <<< "$SPEC_CONTENT"

# ============================================================================
# INVARIANT 4: No Irreversible Actions Without Recovery
# ============================================================================
echo "Checking Invariant #4: No Irreversible Actions Without Recovery..."

DESTRUCTIVE_VERBS=("delete" "drop" "remove" "destroy" "demolish" "erase" "purge" "wipe")

line_num=0
while IFS= read -r line; do
    ((line_num++))
    
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ \<\!-- ]] && continue
    [[ -z "${line// }" ]] && continue

    # Check for destructive verbs
    for verb in "${DESTRUCTIVE_VERBS[@]}"; do
        if echo "$line" | grep -qi "\b$verb\b"; then
            # Check if line mentions recovery mechanisms
            if ! echo "$line" | grep -qi '\(recovery\|undo\|backup\|restore\|retention\|soft.delete\|rollback\)'; then
                violation_text=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -c1-80)
                report_violation "4" "No Irreversible Actions Without Recovery" "$line_num" "$violation_text" \
                    "Specify recovery mechanism: backup/undo/soft-delete + time window"
                break
            fi
        fi
    done
done <<< "$SPEC_CONTENT"

# ============================================================================
# INVARIANT 5: Execution Must Fail Loudly
# ============================================================================
echo "Checking Invariant #5: Execution Must Fail Loudly..."

SILENT_FAILURE_TERMS=("gracefully" "silently" "try to continue" "handle quietly" "suppress error")

line_num=0
while IFS= read -r line; do
    ((line_num++))
    
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ \<\!-- ]] && continue
    [[ -z "${line// }" ]] && continue

    # Check for silent failure patterns
    for term in "${SILENT_FAILURE_TERMS[@]}"; do
        if echo "$line" | grep -qi "$term"; then
            violation_text=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -c1-80)
            report_violation "5" "Execution Must Fail Loudly" "$line_num" "$violation_text" \
                "Specify: error_detection + alerting + blocking_behavior (no silent failures)"
            break
        fi
    done
done <<< "$SPEC_CONTENT"

# ============================================================================
# INVARIANT 6: File Scope Must Be Bounded
# ============================================================================
echo "Checking Invariant #6: File Scope Must Be Bounded..."

UNBOUNDED_TERMS=("all" "everything" "entire" "every" "complete" "total" "whole")

line_num=0
while IFS= read -r line; do
    ((line_num++))
    
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ \<\!-- ]] && continue
    [[ -z "${line// }" ]] && continue

    # Check for unbounded terms
    for term in "${UNBOUNDED_TERMS[@]}"; do
        if echo "$line" | grep -qi "\b$term\b"; then
            # Check if bounds are specified (max, limit, paginated, bounded)
            if ! echo "$line" | grep -qi '\(max\|limit\|bounded\|paginated\|first.*[0-9]\|top.*[0-9]\|last.*[0-9]\)'; then
                # Special case: "all" might be okay in contexts like "all tests" or "all requirements"
                if echo "$line" | grep -qi "all.*\(test\|requirement\|criteria\|validat\)"; then
                    continue
                fi
                violation_text=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -c1-80)
                report_violation "6" "File Scope Must Be Bounded" "$line_num" "$violation_text" \
                    "Specify bounds: max_count OR max_size OR max_time OR pagination"
                break
            fi
        fi
    done
done <<< "$SPEC_CONTENT"

# ============================================================================
# INVARIANT 7: Validation Must Be Executable
# ============================================================================
echo "Checking Invariant #7: Validation Must Be Executable..."

VALIDATION_VERBS=("ensure" "verify" "confirm" "check" "validate" "guarantee")

line_num=0
while IFS= read -r line; do
    ((line_num++))
    
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ \<\!-- ]] && continue
    [[ -z "${line// }" ]] && continue

    # Check for validation verbs
    for verb in "${VALIDATION_VERBS[@]}"; do
        if echo "$line" | grep -qi "\b$verb\b"; then
            # Check if line has executable criteria (metrics, thresholds)
            if ! echo "$line" | grep -q '\([0-9]\+%\|[≥≤=<>]\|test\|metric\|measure\|threshold\|score\)'; then
                violation_text=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -c1-80)
                report_violation "7" "Validation Must Be Executable" "$line_num" "$violation_text" \
                    "Specify: metric + threshold + measurement_method (e.g., test_coverage ≥80%)"
                break
            fi
        fi
    done
done <<< "$SPEC_CONTENT"

# ============================================================================
# INVARIANT 8: Cost Boundaries Must Be Explicit
# ============================================================================
echo "Checking Invariant #8: Cost Boundaries Must Be Explicit..."

line_num=0
found_api_call=false
found_storage=false
found_cost_boundary=false

while IFS= read -r line; do
    ((line_num++))
    
    # Look for API calls or external services
    if echo "$line" | grep -qi '\(API\|external.*service\|third.party\|fetch.*from\|call.*endpoint\)'; then
        found_api_call=true
        # Check if cost boundaries are mentioned anywhere in the spec
        if echo "$SPEC_CONTENT" | grep -qi '\(max.*request\|rate.*limit\|budget\|cost.*limit\|circuit.*breaker\)'; then
            found_cost_boundary=true
        fi
    fi
    
    # Look for storage operations
    if echo "$line" | grep -qi '\(store\|save\|persist\|upload\|storage\)'; then
        found_storage=true
        # Check if storage limits are mentioned
        if echo "$SPEC_CONTENT" | grep -qi '\(max.*size\|storage.*limit\|quota\|max.*MB\|max.*GB\)'; then
            found_cost_boundary=true
        fi
    fi
done <<< "$SPEC_CONTENT"

if [[ "$found_api_call" == true ]] && [[ "$found_cost_boundary" == false ]]; then
    report_warning "API calls detected but no cost boundaries specified" ""
    echo -e "   ${YELLOW}→ Recommendation:${NC} Add: max_requests + budget + circuit_breaker"
fi

if [[ "$found_storage" == true ]] && [[ "$found_cost_boundary" == false ]]; then
    report_warning "Storage operations detected but no limits specified" ""
    echo -e "   ${YELLOW}→ Recommendation:${NC} Add: max_size + quota + retention_policy"
fi

# ============================================================================
# INVARIANT 9: Blast Radius Must Be Declared
# ============================================================================
echo "Checking Invariant #9: Blast Radius Must Be Declared..."

WRITE_OPERATIONS=("update" "modify" "change" "delete" "create" "insert")

line_num=0
while IFS= read -r line; do
    ((line_num++))
    
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ \<\!-- ]] && continue
    [[ -z "${line// }" ]] && continue

    # Check for write operations
    for op in "${WRITE_OPERATIONS[@]}"; do
        if echo "$line" | grep -qi "\b$op\b.*\(database\|table\|config\|system\|user\|data\)"; then
            # Check if blast radius is declared (affects X, impacts Y)
            if ! echo "$line" | grep -qi '\(affects\|impacts\|scope\|radius\|consequences\)'; then
                if ! echo "$SPEC_CONTENT" | grep -qi "blast.*radius\|impact.*scope\|affects.*:"; then
                    violation_text=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -c1-80)
                    report_warning "Write operation without declared blast radius at line $line_num" "$line_num"
                    echo -e "   ${YELLOW}→ Recommendation:${NC} Declare: affected_scope + dependencies + recovery_cost"
                    break
                fi
            fi
        fi
    done
done <<< "$SPEC_CONTENT"

# ============================================================================
# INVARIANT 10: Degradation Path Must Exist
# ============================================================================
echo "Checking Invariant #10: Degradation Path Must Exist..."

EXTERNAL_DEPENDENCIES=("API" "service" "endpoint" "external" "third-party" "cloud")

line_num=0
while IFS= read -r line; do
    ((line_num++))
    
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ \<\!-- ]] && continue
    [[ -z "${line// }" ]] && continue

    # Check for external dependencies
    for dep in "${EXTERNAL_DEPENDENCIES[@]}"; do
        if echo "$line" | grep -qi "\b$dep\b"; then
            # Check if fallback/degradation is mentioned
            if ! echo "$line" | grep -qi '\(fallback\|backup\|alternative\|degraded\|cached\|timeout\)'; then
                violation_text=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -c1-80)
                report_warning "External dependency without fallback at line $line_num" "$line_num"
                echo -e "   ${YELLOW}→ Recommendation:${NC} Specify: primary + fallback1 + fallback2 OR explicit_fail"
                break
            fi
        fi
    done
done <<< "$SPEC_CONTENT"

# ============================================================================
# CONVENTIONS.md Compliance Check
# ============================================================================
echo "Checking CONVENTIONS.md compliance..."

# Look for CONVENTIONS.md in various locations
CONVENTIONS_FILE=""
SPEC_DIR=$(dirname "$SPEC_FILE")

# Search order: spec dir, parent, grandparent, current dir
for check_dir in "$SPEC_DIR" "$SPEC_DIR/.." "$SPEC_DIR/../.." "."; do
    if [[ -f "$check_dir/CONVENTIONS.md" ]]; then
        CONVENTIONS_FILE="$check_dir/CONVENTIONS.md"
        break
    fi
done

if [[ -n "$CONVENTIONS_FILE" ]] && [[ -f "$CONVENTIONS_FILE" ]]; then
    echo "  Found: $CONVENTIONS_FILE"

    CONVENTIONS_CONTENT=$(cat "$CONVENTIONS_FILE")

    # Check for naming convention mentions in spec
    if echo "$SPEC_CONTENT" | grep -qiE "(file|function|variable|class|component).*name"; then
        # Check if naming follows conventions
        if echo "$CONVENTIONS_CONTENT" | grep -qiE "naming.*convention"; then
            # Extract naming patterns from CONVENTIONS.md
            NAMING_PATTERNS=$(echo "$CONVENTIONS_CONTENT" | grep -oE "(PascalCase|camelCase|snake_case|kebab-case)" | sort -u)

            # Check spec doesn't conflict
            for pattern in $NAMING_PATTERNS; do
                if echo "$SPEC_CONTENT" | grep -qiE "should.*use.*$pattern"; then
                    # Good - spec references conventions
                    :
                fi
            done
        fi
    fi

    # Check for file patterns
    if echo "$CONVENTIONS_CONTENT" | grep -qiE "\.(ts|tsx|js|jsx|py|go)"; then
        # Extract file extension rules
        FILE_RULES=$(echo "$CONVENTIONS_CONTENT" | grep -oE "\\.[a-z]+" | sort -u | head -5)

        # Verify spec file references match expected extensions
        SPEC_FILES=$(echo "$SPEC_CONTENT" | grep -oE "\`[^\\`]+\.(ts|tsx|js|py|go)\`" | sort -u)

        if [[ -n "$SPEC_FILES" ]]; then
            echo "  Spec references files with extensions matching conventions"
        fi
    fi

    # Check for test conventions
    if echo "$SPEC_CONTENT" | grep -qiE "test|spec|expect|assert"; then
        if echo "$CONVENTIONS_CONTENT" | grep -qiE "test.*convention|testing.*pattern"; then
            # Good - has testing conventions
            :
        else
            report_warning "Spec mentions testing but CONVENTIONS.md lacks test conventions" ""
        fi
    fi

    # Check for error handling conventions
    if echo "$SPEC_CONTENT" | grep -qiE "error|exception|failure|catch"; then
        if echo "$CONVENTIONS_CONTENT" | grep -qiE "error.*handling|exception"; then
            # Good - has error conventions
            :
        else
            report_warning "Spec mentions errors but CONVENTIONS.md lacks error handling conventions" ""
        fi
    fi
else
    echo -e "  ${YELLOW}No CONVENTIONS.md found (optional)${NC}"
fi

echo ""

# ============================================================================
# Domain-Specific Invariants
# ============================================================================
if [[ ${#DOMAIN_FILES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${BLUE}Checking Domain-Specific Invariants...${NC}"
    echo ""
    
    for domain_file in "${DOMAIN_FILES[@]}"; do
        if [[ ! -f "$domain_file" ]]; then
            report_warning "Domain file not found: $domain_file" ""
            continue
        fi
        
        echo "Checking domain: $domain_file"
        
        # Check for consumer product domain
        if echo "$domain_file" | grep -qi "consumer.*product"; then
            # Invariant 11: User Emotion Must Map to Affordance
            if echo "$SPEC_CONTENT" | grep -qi "user.*\(feel\|emotion\|experience\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(UI\|visual\|haptic\|animation\|feedback\|:=\)'; then
                    report_warning "User emotion mentioned without UI affordance mapping" ""
                fi
            fi

            # Invariant 12: Behavioral Friction Must Be Quantified
            if echo "$SPEC_CONTENT" | grep -qi "\(easy\|simple\|quick\|fast\|convenient\)"; then
                if ! echo "$SPEC_CONTENT" | grep -q '\([0-9]\+.*tap\|[0-9]\+.*click\|[0-9]\+.*sec\|[0-9]\+.*step\)'; then
                    report_warning "Ease/friction mentioned without quantification (tap count, time)" ""
                fi
            fi

            # Invariant 13: Accessibility Must Be Explicit
            if echo "$SPEC_CONTENT" | grep -qi "\(UI\|interface\|screen\|button\|form\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(accessibility\|WCAG\|screen.*reader\|contrast\|touch.*target\|a11y\)'; then
                    report_warning "UI elements without accessibility declaration" ""
                fi
            fi

            # Invariant 14: Offline Behavior Must Be Defined
            if echo "$SPEC_CONTENT" | grep -qi "\(sync\|cloud\|fetch\|API\|network\|online\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(offline\|local.*first\|queue\|cached\|disconnected\)'; then
                    report_warning "Network operations without offline behavior defined" ""
                fi
            fi

            # Invariant 15: Loading States Must Be Bounded
            if echo "$SPEC_CONTENT" | grep -qi "\(loading\|spinner\|wait\|fetch\|pending\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(timeout\|max.*[0-9]\+.*sec\|[0-9]\+s\|skeleton\|fallback\)'; then
                    report_warning "Loading states without timeout bounds" ""
                fi
            fi
        fi
        
        # Check for physical construction domain
        if echo "$domain_file" | grep -qi "physical.*construction\|construction"; then
            # Invariant 16: Material Properties Must Be Climate-Validated
            if echo "$SPEC_CONTENT" | grep -qi "\(material\|concrete\|paint\|wood\|steel\|marble\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(climate\|weather\|temperature\|humidity\|coastal\|monsoon\|heat.*resistant\)'; then
                    report_warning "Materials specified without climate validation" ""
                fi
            fi

            # Invariant 17: Vendor Capabilities Must Be Validated
            if echo "$SPEC_CONTENT" | grep -qi "\(contractor\|vendor\|installer\|supplier\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(certif\|experience\|portfolio\|reference\|verified\|insurance\)'; then
                    report_warning "Contractor/vendor without capability validation" ""
                fi
            fi

            # Invariant 18: Temporal Constraints Must Account for Climate
            if echo "$SPEC_CONTENT" | grep -qi "\(schedule\|timeline\|start.*date\|duration\|complete.*by\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(monsoon\|season\|weather.*buffer\|rain\|climate.*window\)'; then
                    report_warning "Construction schedule without climate/season consideration" ""
                fi
            fi

            # Invariant 19: Inspection Gates Must Be Explicit
            if echo "$SPEC_CONTENT" | grep -qi "\(phase\|stage\|complete\|finish\|milestone\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(inspect\|engineer\|approval\|sign.*off\|test.*criteria\|PASS\|FAIL\)'; then
                    report_warning "Construction phases without explicit inspection gates" ""
                fi
            fi

            # Invariant 20: Material Failure Modes Must Be Documented
            if echo "$SPEC_CONTENT" | grep -qi "\(concrete\|waterproof\|steel\|foundation\|structural\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(failure.*mode\|detection\|recovery.*cost\|what.*if\)'; then
                    report_warning "Critical materials without failure mode documentation" ""
                fi
            fi

            # Invariant 21: Supply Chain Must Be Stress-Tested
            if echo "$SPEC_CONTENT" | grep -qi "\(import\|specialty\|custom\|lead.*time\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(fallback\|alternative\|backup.*supplier\|local.*option\|lead.*time\)'; then
                    report_warning "Specialty materials without supply chain fallbacks" ""
                fi
            fi
        fi
        
        # Check for skill gap transcendence domain
        if echo "$domain_file" | grep -qi "skill.*gap\|capability.*boundaries"; then
            # Invariant 37: Skill Gaps Force Explicit Learning Budget
            if echo "$SPEC_CONTENT" | grep -qi "\(new.*technology\|learn\|unfamiliar\|first.*time\|unknown.*tech\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(learning.*time\|learning.*budget\|skill.*level\|training.*hours\)'; then
                    report_violation "37" "Skill Gaps Force Explicit Learning Budget" "N/A" "New technology mentioned" \
                        "Declare: learning_time_budget + scope_tradeoff_if_exceeded + validation_criteria"
                fi
            fi

            # Invariant 38: Support Structure Must Be Pre-Defined
            if echo "$SPEC_CONTENT" | grep -qi "\(skill.*gap\|unknown\|learning\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(escalation\|mentor\|resource\|blocker.*protocol\|ask.*for.*help\)'; then
                    report_warning "Skill gap without support structure defined" ""
                fi
            fi

            # Invariant 39: Demos Require Triple-Backup Protocol
            if echo "$SPEC_CONTENT" | grep -qi "\(demo\|presentation\|immersion.*day\|conference\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(fallback\|backup\|pre.*record\|slides\|alternative\)'; then
                    report_violation "39" "Demos Require Triple-Backup Protocol" "N/A" "Demo/presentation mentioned" \
                        "Define: primary + fallback_1(pre-recorded) + fallback_2(slides) + confidence_check_date"
                fi
            fi

            # Invariant 40: Health Signals Trigger Scope Adjustment
            if echo "$SPEC_CONTENT" | grep -qi "\(stress\|crunch\|overtime\|intense\|high.*pressure\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(health\|adjustment\|scope.*reduction\|sustainable\)'; then
                    report_warning "High-pressure project without health signal protocol" ""
                fi
            fi

            # Invariant 41: Fixed Deadlines Require Tiered Scope
            if echo "$SPEC_CONTENT" | grep -qi "\(deadline\|due.*date\|must.*complete.*by\|fixed.*date\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(MVP\|must.*have\|can.*drop\|tier\|optional\|stretch\)'; then
                    report_warning "Fixed deadline without tiered scope (MVP/stretch/optional)" ""
                fi
            fi

            # Invariant 42: Learning Time Is First-Class Work
            if echo "$SPEC_CONTENT" | grep -qi "\(learn\|study\|ramp.*up\|onboard\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(scheduled\|budgeted\|validation.*prototype\|learning.*phase\)'; then
                    report_warning "Learning mentioned but not scheduled as explicit work" ""
                fi
            fi

            # Invariant 43: Discovery Phase Required for Unknowns
            if echo "$SPEC_CONTENT" | grep -qi "\(new.*domain\|new.*tech\|unknown\|explore\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(discovery.*phase\|spike\|prototype\|re.*estimat\)'; then
                    report_warning "Unknown territory without discovery phase allocation" ""
                fi
            fi
        fi

        # Check for data architecture domain
        if echo "$domain_file" | grep -qi "data.*architecture"; then
            # Invariant 22: Schema Evolution Must Be Explicit
            if echo "$SPEC_CONTENT" | grep -qi "\(schema\|column\|field\|table.*change\|migration\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(migration.*path\|rollback\|backfill\|backwards.*compat\)'; then
                    report_violation "22" "Schema Evolution Must Be Explicit" "N/A" "Schema change mentioned" \
                        "Specify: migration_approach + validation + rollback_plan"
                fi
            fi

            # Invariant 23: Data Lineage Must Be Traceable
            if echo "$SPEC_CONTENT" | grep -qi "\(calculated\|derived\|aggregat\|metric\|KPI\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(source.*table\|FROM\|transformation\|lineage\)'; then
                    report_warning "Derived/calculated values without source lineage" ""
                fi
            fi

            # Invariant 24: Aggregation Scope Must Be Bounded
            if echo "$SPEC_CONTENT" | grep -qi "\(group.*by\|aggregate\|sum\|count\|join\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(max.*row\|limit\|partition\|time.*bound\|timeout\)'; then
                    report_warning "Aggregation without cardinality bounds" ""
                fi
            fi

            # Invariant 25: Temporal Semantics Must Be Explicit
            if echo "$SPEC_CONTENT" | grep -qi "\(daily\|weekly\|monthly\|time.*series\|timestamp\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(UTC\|timezone\|granularity\|boundary\)'; then
                    report_warning "Time-based query without timezone/granularity specified" ""
                fi
            fi

            # Invariant 26: PII Must Be Declared and Protected
            if echo "$SPEC_CONTENT" | grep -qi "\(email\|phone\|address\|name\|user.*data\|personal\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(PII\|encrypt\|anonymiz\|access.*control\|retention\)'; then
                    report_violation "26" "PII Must Be Declared and Protected" "N/A" "Personal data field detected" \
                        "Declare: PII_tag + encryption + access_control + retention_policy"
                fi
            fi
        fi

        # Check for integration domain
        if echo "$domain_file" | grep -qi "integration"; then
            # Invariant 27: API Versioning Must Be Explicit
            if echo "$SPEC_CONTENT" | grep -qi "\(API\|endpoint\|REST\|GraphQL\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(version\|v[0-9]\|deprecat\|backwards\)'; then
                    report_warning "API without versioning strategy" ""
                fi
            fi

            # Invariant 28: Rate Limits Must Be Declared
            if echo "$SPEC_CONTENT" | grep -qi "\(external.*API\|third.*party\|call.*service\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(rate.*limit\|backoff\|retry\|circuit.*breaker\|throttl\)'; then
                    report_violation "28" "Rate Limits Must Be Declared" "N/A" "External API call detected" \
                        "Specify: rate_limit + backoff_strategy + circuit_breaker"
                fi
            fi

            # Invariant 29: Idempotency Must Be Guaranteed
            if echo "$SPEC_CONTENT" | grep -qi "\(create\|submit\|charge\|payment\|order\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(idempoten\|dedup\|unique.*key\|retry.*safe\)'; then
                    report_warning "Mutating operation without idempotency mechanism" ""
                fi
            fi

            # Invariant 30: Timeout Budgets Must Be Allocated
            if echo "$SPEC_CONTENT" | grep -qi "\(chain\|sequence\|then\|after.*that\|multi.*step\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(timeout\|budget\|[0-9]\+.*sec\|[0-9]\+s\)'; then
                    report_warning "Request chain without timeout budget allocation" ""
                fi
            fi
        fi

        # Check for remote management domain
        if echo "$domain_file" | grep -qi "remote.*management"; then
            # Invariant 31: Inspection Must Be Independent
            if echo "$SPEC_CONTENT" | grep -qi "\(remote\|overseas\|distance\|from.*LA\|from.*US\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(independent.*inspect\|third.*party\|verify.*independent\)'; then
                    report_violation "31" "Inspection Must Be Independent" "N/A" "Remote project detected" \
                        "Specify: independent_verification_source + frequency + reporting_format"
                fi
            fi

            # Invariant 32: Communication Protocol Must Be Explicit
            if echo "$SPEC_CONTENT" | grep -qi "\(contractor\|team\|stakeholder\|vendor\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(communication.*protocol\|channel\|cadence\|SLA\|response.*time\)'; then
                    report_warning "Stakeholders without communication protocol" ""
                fi
            fi

            # Invariant 33: Payment Must Be Milestone-Gated
            if echo "$SPEC_CONTENT" | grep -qi "\(payment\|pay\|release.*fund\|advance\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(milestone\|deliverable\|verification\|gate\|upon.*completion\)'; then
                    report_violation "33" "Payment Must Be Milestone-Gated" "N/A" "Payment mentioned" \
                        "Tie payment to: trigger_condition + verification_method + approval_required"
                fi
            fi

            # Invariant 34: Decision Authority Must Be Delegated Explicitly
            if echo "$SPEC_CONTENT" | grep -qi "\(decision\|change\|approval\|authority\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(delegat\|on.*site.*authority\|threshold\|owner.*required\)'; then
                    report_warning "Decision-making without explicit authority delegation" ""
                fi
            fi

            # Invariant 35: Documentation Must Be Timestamped and Immutable
            if echo "$SPEC_CONTENT" | grep -qi "\(document\|record\|photo\|log\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(timestamp\|immutable\|GPS\|version.*history\|append.*only\)'; then
                    report_warning "Documentation without timestamp/immutability requirements" ""
                fi
            fi

            # Invariant 36: Contingency Must Account for Physical Distance
            if echo "$SPEC_CONTENT" | grep -qi "\(emergency\|contingency\|fallback\|backup.*plan\)"; then
                if ! echo "$SPEC_CONTENT" | grep -qi '\(local.*agent\|local.*contact\|emergency.*fund\|authority.*to.*act\)'; then
                    report_warning "Contingency plan without local agent/authority" ""
                fi
            fi
        fi
    done
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Validation Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

if [[ $VIOLATIONS_FOUND -eq 0 ]] && [[ $WARNINGS_FOUND -eq 0 ]]; then
    echo -e "${GREEN}✅ All invariants validated${NC}"
    echo -e "${GREEN}✅ Spec ready for PRP compilation${NC}"
    echo ""
    exit 0
elif [[ $VIOLATIONS_FOUND -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  $WARNINGS_FOUND warning(s) found${NC}"
    echo -e "${GREEN}✅ No blocking violations${NC}"
    echo -e "${GREEN}✅ Spec can proceed (address warnings before production)${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}❌ $VIOLATIONS_FOUND violation(s) found${NC}"
    if [[ $WARNINGS_FOUND -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  $WARNINGS_FOUND warning(s) found${NC}"
    fi
    echo ""
    echo -e "${RED}Spec rejected. Fix violations before proceeding.${NC}"
    echo ""
    exit 1
fi

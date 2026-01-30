# Remote Management Domain Invariants

Extends: [[system-invariants]]
Domain: Projects managed from distance (different city/country/timezone)

<!-- Invariant Range: 48-55 (Remote Management reserved range)
     Numbering scheme: Core 1-11, Consumer 12-15, Integration 16-19, Data 20-24, Healthcare 25-31, HLS-SA 32-39, Construction 40-47, Remote 48-55, SkillGap 56-65
     Reserved ranges allow domains to evolve independently -->

---

## When to Use

Load this domain for:
- House construction (Kanyakumari from LA - 13.5hr timezone difference)
- Remote team management
- Distributed project oversight
- Cross-timezone coordination
- Any project where you cannot physically inspect

**Note**: For physical construction projects, also load [[physical-construction]]

---

## Domain Invariants (48-55)

### 48. Inspection Must Be Independent

**Principle**: Remote owner must have eyes independent of executor

**Violation**: Relying solely on contractor/executor for status

**Examples**:
- ❌ "Contractor will send photos"
- ❌ "Trust the site supervisor"
- ❌ "They'll let us know if there are issues"
- ✅ "Independent inspector: monthly_site_visit + photo_documentation + video_call_walkthrough + written_report"
- ✅ "Dual verification: contractor_photos + independent_photos + discrepancy_review"
- ✅ "Third-party QC: structural_engineer(quarterly) + waterproofing_specialist(at_milestone) + surprise_visits(random)"

**Enforcement**: Remote projects must specify: independent_verification_source + frequency + reporting_format → Otherwise REJECT

---

### 49. Communication Protocol Must Be Explicit

**Principle**: Every stakeholder must have defined communication channel and cadence

**Violation**: Ad-hoc communication, unclear escalation

**Examples**:
- ❌ "Stay in touch with contractor"
- ❌ "Regular updates"
- ❌ "Call if there are problems"
- ✅ "Contractor: WhatsApp_daily_photo(6PM_IST) + weekly_video_call(Saturday_10AM_IST) + email_for_decisions"
- ✅ "Architect: bi-weekly_review + milestone_signoff_required + 48hr_response_SLA"
- ✅ "Escalation: issue_in_chat → no_response_24hr → phone_call → no_response_48hr → site_visit_triggered"

**Enforcement**: Each stakeholder must have: primary_channel + backup_channel + response_SLA + escalation_path → Otherwise REJECT

---

### 50. Payment Must Be Milestone-Gated

**Principle**: Payments must be tied to verified deliverables

**Violation**: Time-based payments, trust-based releases

**Examples**:
- ❌ "Pay monthly"
- ❌ "Release funds as needed"
- ❌ "Pay on contractor's request"
- ✅ "Foundation payment: 30% on completion + independent_inspection_pass + compression_test_report + photo_documentation"
- ✅ "Material advance: 50% on PO + 50% on delivery_verification(photo+receipt) + quality_check_passed"
- ✅ "Milestone release: checklist_complete + inspector_signoff + owner_approval_in_writing → payment_within_48hr"

**Enforcement**: Every payment must specify: trigger_condition + verification_method + approval_required → Otherwise REJECT

---

### 51. Decision Authority Must Be Delegated Explicitly

**Principle**: Clear boundaries for on-site decisions vs owner approval

**Violation**: Everything requires owner, or nothing does

**Examples**:
- ❌ "Check with me for changes"
- ❌ "Use your judgment"
- ❌ "Handle minor issues"
- ✅ "On-site authority: changes <₹10K + no_structural_impact + reversible → proceed_and_inform"
- ✅ "Owner required: changes >₹10K OR structural OR permanent → stop_work + await_approval(max_48hr)"
- ✅ "Emergency protocol: safety_risk → immediate_action_allowed + document_thoroughly + inform_within_2hr"

**Enforcement**: Decision categories must specify: authority_level + threshold + documentation_requirement → Otherwise REJECT

---

### 52. Documentation Must Be Timestamped and Immutable

**Principle**: All project records must be tamper-evident

**Violation**: Editable records, undated documentation

**Examples**:
- ❌ "Keep records of progress"
- ❌ "Document issues"
- ❌ "Take photos"
- ✅ "Photos: GPS_tagged + timestamp_verified + uploaded_to_shared_drive_daily + no_deletion_allowed"
- ✅ "Decisions: email_thread(immutable) + decision_log(append_only) + version_history_preserved"
- ✅ "Issues: logged_in_tracker + timestamp_auto + status_changes_tracked + resolution_documented"

**Enforcement**: Project documentation must specify: timestamp_source + immutability_mechanism + storage_location → Otherwise REJECT

---

### 53. Contingency Must Account for Physical Distance

**Principle**: Fallback plans must work without owner presence

**Violation**: Plans that assume owner can visit quickly

**Examples**:
- ❌ "I'll fly out if needed"
- ❌ "Handle emergencies as they come"
- ❌ "We'll figure it out"
- ✅ "Emergency contact: local_trusted_person(Dad) + authority_to_act + ₹2L_emergency_fund_access"
- ✅ "Contractor failure: backup_contractor_identified + contract_termination_clause + material_ownership_clear"
- ✅ "Quality dispute: independent_arbitrator_named + dispute_resolution_process + escrow_for_contested_amounts"

**Enforcement**: Contingency plans must specify: local_agent + authority_scope + financial_access + dispute_resolution → Otherwise REJECT

---

### 54. Communication Must Bridge Language Gaps

**Principle**: Remote oversight across language barriers must have explicit translation/interpretation

**Violation**: Assuming English proficiency or shared terminology

**Examples**:
- ❌ "Contractor speaks some English"
- ❌ "We'll manage with WhatsApp translate"
- ❌ "Technical terms are universal"
- ✅ "Primary communication: Tamil via local_agent(Dad) + English_summary_for_owner + critical_docs_bilingual"
- ✅ "Technical terms: glossary_created(English↔Tamil) + photo_reference_for_materials + brand_names_specified"
- ✅ "Contracts: bilingual_version + legal_review_in_both_languages + verbal_explanation_witnessed"

**Enforcement**: Cross-language projects must specify: translation_mechanism + terminology_glossary + bilingual_critical_docs → Otherwise REJECT

---

### 55. Async Approvals Must Have Bounded Windows

**Principle**: Decisions blocked on remote owner must have time limits and fallback authority

**Violation**: Work stops indefinitely waiting for owner across timezones

**Examples**:
- ❌ "Wait for owner approval before proceeding"
- ❌ "Send message and wait for response"
- ❌ "Don't proceed without sign-off"
- ✅ "Approval request: submit_with_recommendation + owner_response_window(24hr) + auto_escalate_to_local_agent + proceed_with_recommendation_after_48hr_if_non_critical"
- ✅ "Critical approval: 12hr_window + phone_call_if_no_response + local_agent_authority_if_unreachable(72hr)"
- ✅ "Blocking decision: calendar_hold_for_sync_call + backup_decision_maker_named + deadline_explicit"

**Enforcement**: Approval workflows must specify: response_window + escalation_path + fallback_authority + proceed_conditions → Otherwise REJECT

---

## Remote-Specific Sub-Invariants

### 53a. Timezone Coordination

- Meeting times must specify timezone explicitly
- Async-first communication preferred
- Response windows must account for timezone gaps
- Urgent vs non-urgent must have different SLAs

**Enforcement**: Meeting/deadline specs must include: timezone_explicit(IST|PST|UTC) + async_default + response_window_by_urgency(urgent:<4hr, normal:<24hr, low:<72hr). Meeting time without timezone OR response SLA without urgency tier → REJECT

### 53b. Trust But Verify

- No single point of trust
- Cross-verification for critical claims
- Random spot-checks built into process
- Incentive alignment documented

**Enforcement**: Critical claims must specify: verification_source_independent_of_executor + cross_check_method + spot_check_frequency(random). Single-source-of-truth controlled by executor → REJECT

### 53c. Information Asymmetry Mitigation

- Owner must have direct access to key data (not through executor)
- Multiple information sources for triangulation
- Regular knowledge transfer sessions
- Documentation accessible to owner 24/7

**Enforcement**: Project data must specify: owner_direct_access_method + data_sources(≥2 independent) + knowledge_transfer_cadence. Owner data access only through executor → REJECT

### 53d. Visit Planning

- Site visits must have structured agenda
- Pre-visit information gathering required
- Post-visit action items documented
- Visit findings feed back into remote process

**Enforcement**: Site visits must include: pre_visit_agenda + information_requests(48hr_before) + post_visit_action_log + process_feedback_integration. Ad-hoc visit without structured agenda → REJECT

---

## Quick Reference

| # | Invariant | Key Test |
|---|-----------|----------|
| 48 | Inspection Must Be Independent | Eyes other than executor |
| 49 | Communication Protocol Must Be Explicit | Channels + cadence + escalation defined |
| 50 | Payment Must Be Milestone-Gated | Payments tied to verified deliverables |
| 51 | Decision Authority Must Be Delegated | Clear boundaries for on-site vs owner |
| 52 | Documentation Must Be Timestamped | Immutable, timestamped records |
| 53 | Contingency Must Account for Distance | Fallbacks work without owner presence |
| 54 | Communication Must Bridge Language Gaps | Translation + glossary + bilingual docs |
| 55 | Async Approvals Must Have Bounded Windows | Response window + escalation + fallback |

---

*Domain: Remote Management*
*Invariants: 48-55 (plus sub-invariants)*
*Use with: Core invariants 1-11*
*Critical combination: physical-construction.md + remote-management.md for house build*

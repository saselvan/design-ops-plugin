# Healthcare AI Domain Invariants

Extends: [[system-invariants]], [[data-architecture]]
Domain: Clinical AI systems, medical RAG, diagnostic support, healthcare LLM applications

<!-- Invariant Range: 25-31 (Healthcare AI reserved range)
     Numbering scheme: Core 1-11, Consumer 12-15, Integration 16-19, Data 20-24, Healthcare 25-31, HLS-SA 32-39, Construction 40-47, Remote 48-55, SkillGap 56-65
     Reserved ranges allow domains to evolve independently -->

---

## When to Use

Load this domain for:
- Medical/clinical AI systems
- Healthcare RAG applications
- Diagnostic support tools
- Pathology image analysis
- Clinical decision support
- Patient-facing health AI
- HLS (Healthcare & Life Sciences) projects

---

## Domain Invariants (25-31)

### 25. Safety Must Be Enforced by Code, Not Prompts

**Principle**: Safety-critical outputs cannot rely on LLM prompt compliance

**Violation**: Expecting LLM to add disclaimers, caveats, or review flags via prompt instructions

**Examples**:
- ❌ "Prompt: Always include a disclaimer that this is not medical advice"
- ❌ "Prompt: Add confidence caveats when uncertain"
- ❌ "Prompt: Flag malignancy findings for pathologist review"
- ✅ "Code post-processes ALL outputs to append: 'This is AI-generated. Verify with qualified professional.'"
- ✅ "Code detects confidence < threshold → injects LOW_CONFIDENCE_CAVEAT constant into response"
- ✅ "Code scans for malignancy_terms → sets requires_pathologist_review=True + appends review notice"

**Rationale**: LLMs are probabilistic. Prompts are suggestions, not guarantees. Safety-critical behaviors must be deterministic.

**Enforcement**: Safety outputs must be: code_enforced + deterministic + testable → Prompt-only safety = REJECT

---

### 26. Clinical Outputs Must Flag Human Review

**Principle**: Any diagnostic or treatment-adjacent output must include human review flag

**Violation**: AI outputs about diagnosis, prognosis, or treatment without review mechanism

**Examples**:
- ❌ "Return diagnosis classification directly"
- ❌ "Provide treatment recommendation"
- ❌ "Show pathology assessment"
- ✅ "diagnosis_result + requires_clinical_review=True + review_urgency(HIGH|MEDIUM|LOW)"
- ✅ "treatment_info + disclaimer='Discuss with your physician' + flag_for_provider_review"
- ✅ "pathology_assessment + requires_pathologist_review=True + confidence_tier + uncertainty_regions[]"

**Enforcement**: Clinical outputs must have: review_flag + reviewer_type + urgency_level → Otherwise REJECT

---

### 27. PHI Must Have Healthcare-Grade Protection

**Principle**: PHI handling must exceed standard PII requirements (extends Invariant #24)

**Violation**: PHI treated as regular PII without healthcare-specific controls

**Examples**:
- ❌ "Store patient data encrypted" (insufficient)
- ❌ "Log medical queries" (audit risk)
- ❌ "Cache diagnostic results" (retention risk)
- ✅ "PHI: HIPAA_compliant + BAA_required + encryption(AES256_at_rest + TLS_in_transit) + access_log(immutable)"
- ✅ "Query logging: PHI_redacted + query_hash_only + no_patient_identifiers + audit_retention(7yr)"
- ✅ "Result caching: PHI_excluded OR encrypted_ephemeral(TTL_15min) + no_disk_persistence"

**Enforcement**: PHI must specify: HIPAA_controls + BAA_status + audit_mechanism + retention_compliance → Otherwise REJECT

---

### 28. Model Provenance Must Be Traceable

**Principle**: Clinical AI outputs must trace to specific model versions for reproducibility

**Violation**: Clinical outputs without model version, encoder version, or training data reference

**Examples**:
- ❌ "Return AI diagnosis"
- ❌ "Generate clinical summary"
- ❌ "Classify pathology image"
- ✅ "diagnosis + model_version='catalog.schema.model@v2.3' + encoder_version='biomedclip-v2' + training_cutoff='2025-06'"
- ✅ "summary + llm_version='dbrx-instruct-v1.2' + retrieval_index_version='pathvqa-2025Q4'"
- ✅ "classification + model_registry_uri + validation_dataset_hash + performance_metrics_at_deploy"

**Rationale**: FDA and clinical audit requirements demand reproducibility. "What model produced this output?" must be answerable.

**Enforcement**: Clinical outputs must include: model_version + encoder_version (if applicable) + traceability_uri → Otherwise REJECT

---

### 29. Hallucination Detection Must Be Systematic

**Principle**: Clinical LLM outputs must have automated hallucination detection, not just human review

**Violation**: Relying solely on clinician review to catch AI errors

**Examples**:
- ❌ "Clinicians will review AI summaries for accuracy"
- ❌ "Display AI output with disclaimer"
- ❌ "Flag low-confidence outputs for review"
- ✅ "Output validated against: entity_extraction + knowledge_base_check + NLI_consistency_score ≥0.85"
- ✅ "Hallucination detection: automated_fact_check + omission_detection + severity_classification(minor|major|critical)"
- ✅ "Clinical summary: source_sentence_attribution + fabrication_score <0.02 + omission_rate <0.05"

**Rationale**: Research shows hallucination rates of 1.5-40% in medical LLMs. Hallucinations use valid clinical language, making them hard to detect without systematic checking. 44% of hallucinations are "major" errors vs 17% of omissions.

**Enforcement**: Clinical LLM outputs must specify: hallucination_detection_method + threshold + omission_detection. Output without systematic validation → REJECT

---

### 30. Model Updates Must Follow PCCP Framework

**Principle**: AI model updates must be pre-planned per FDA 2025 PCCP guidance

**Violation**: Ad-hoc model updates without predetermined change control

**Examples**:
- ❌ "Update model when performance degrades"
- ❌ "Retrain quarterly with new data"
- ❌ "Deploy improved model version"
- ✅ "PCCP: modification_categories(retraining|threshold_adjustment|feature_addition) + validation_protocol_per_category + acceptance_criteria + rollback_plan"
- ✅ "Model update: within_PCCP_scope + validation_complete + labeling_updated + UDI_assigned"
- ✅ "Change outside PCCP scope → new_FDA_submission_required"

**Rationale**: FDA 2025 final guidance requires PCCP for AI-enabled devices. Updates within approved PCCP don't need new submission; updates outside scope require new 510(k)/PMA.

**Enforcement**: Model update specs must include: PCCP_reference OR new_submission_justification + validation_protocol + rollback_plan. Ad-hoc update → REJECT

---

### 31. AI Presence Must Be Labeled Per FDA Requirements

**Principle**: Users must be informed device uses AI and how it functions

**Violation**: AI functionality without clear labeling

**Examples**:
- ❌ "Deploy diagnostic assistance feature"
- ❌ "Add AI-powered recommendations"
- ❌ "Enable smart suggestions"
- ✅ "Labeling: ai_disclosure_statement + plain_language_description + intended_use + known_limitations"
- ✅ "User communication: version_history + change_summary + performance_impact + how_to_report_issues"
- ✅ "SSED/510k_summary: PCCP_description + training_data_characteristics + demographic_performance"

**Rationale**: FDA 2025 guidance requires clear AI labeling including plain-language description, version tracking, and user notification of updates.

**Enforcement**: AI feature specs must include: user_facing_ai_disclosure + intended_use_statement + limitation_disclosure. Unlabeled AI → REJECT

---

## Healthcare-Specific Sub-Invariants

### 28a. Confidence Reporting

- All clinical AI must report confidence scores
- Confidence thresholds must be clinically validated
- Low confidence must trigger explicit uncertainty messaging
- Confidence calibration must be documented

**Enforcement**: Clinical AI output specs must include: confidence_score + confidence_threshold + low_confidence_behavior(explicit_uncertainty_message) + calibration_documentation. Clinical output without confidence reporting → REJECT

### 28b. Bias Monitoring

- Training data demographics must be documented
- Performance must be reported across demographic segments
- Known limitations by population must be disclosed
- Bias mitigation strategy required

**Enforcement**: Model specs must include: training_demographics + performance_by_segment(age|sex|race|ethnicity) + known_limitations + bias_mitigation_strategy. Clinical model without bias documentation → REJECT

### 28c. Regulatory Readiness

- FDA 510(k)/De Novo pathway must be identified if applicable
- Clinical validation study design must be specified
- Intended use statement required
- Contraindications must be documented

**Enforcement**: Clinical AI specs must include: regulatory_pathway(510k|DeNovo|PMA|exempt) + intended_use_statement + contraindications + PCCP_if_applicable. Clinical AI without regulatory classification → REJECT

### 28d. Audit Trail

- All clinical decisions must be logged immutably
- User actions on AI outputs must be tracked
- Override/correction logging required
- Retention per regulatory requirement (typically 7+ years)

**Enforcement**: Clinical decision specs must include: immutable_log + user_action_tracking + override_logging + retention_period(≥7yr) + real_world_performance_monitoring. Clinical decision without audit trail spec → REJECT

---

## Quick Reference

| # | Invariant | Key Test |
|---|-----------|----------|
| 25 | Safety Must Be Enforced by Code | No prompt-only safety controls |
| 26 | Clinical Outputs Must Flag Human Review | Review flag + reviewer type present |
| 27 | PHI Must Have Healthcare-Grade Protection | HIPAA controls + BAA + audit |
| 28 | Model Provenance Must Be Traceable | model_version in all outputs |
| 29 | Hallucination Detection Must Be Systematic | Automated detection + thresholds |
| 30 | Model Updates Must Follow PCCP Framework | PCCP reference or new submission |
| 31 | AI Presence Must Be Labeled | FDA-compliant AI disclosure |

---

*Domain: Healthcare AI*
*Invariants: 25-31 (plus sub-invariants)*
*Use with: Core invariants 1-11, Data Architecture 20-24*
*Applicable: HLS accounts (City of Hope, CHLA, Providence, etc.)*

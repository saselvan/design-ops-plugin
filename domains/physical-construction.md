# Physical Construction Domain Invariants

Extends: [[system-invariants]]
Domain: Buildings, infrastructure, physical fabrication

<!-- Invariant Range: 40-47 (Physical Construction reserved range)
     Numbering scheme: Core 1-11, Consumer 12-15, Integration 16-19, Data 20-24, Healthcare 25-31, HLS-SA 32-39, Construction 40-47, Remote 48-55, SkillGap 56-65
     Reserved ranges allow domains to evolve independently -->

---

## When to Use

Load this domain for:
- House construction (Kanyakumari - coastal, cyclone zone)
- Renovation projects
- Infrastructure builds
- Physical product manufacturing

**Note**: For remote oversight, also load [[remote-management]]

---

## Domain Invariants (40-47)

### 40. Material Properties Must Be Climate-Validated

**Principle**: Every material must be proven for local environment

**Violation**: Specifying materials without climate validation

**Examples**:
- ❌ "Use exterior paint"
- ❌ "Install wooden doors"
- ❌ "Apply waterproofing"
- ✅ "Exterior paint: heat_resistant(≤50°C) + humidity_resistant(≤95%) + salt_resistant(coastal) → Brand: Asian_Paints_WeatherProof"
- ✅ "Wooden doors: teak + termite_treatment + monsoon_seal + UV_coating → Supplier: verified_coastal_experience"
- ✅ "Waterproofing: Fosroc_system + coastal_grade + 10yr_warranty + installer_certified"

**Enforcement**: Materials must specify: climate_properties + test_validation + local_sourcing → Otherwise REJECT

---

### 41. Vendor Capabilities Must Be Validated

**Principle**: No spec that assumes unverified contractor expertise

**Violation**: Specifying techniques without capability verification

**Examples**:
- ❌ "Install waterproofing system"
- ❌ "Lay Italian marble"
- ❌ "Build exposed concrete walls"
- ✅ "Waterproofing: Fosroc_DR_Newcoat → require contractor_certification + past_coastal_projects(3+) + warranty_10yr"
- ✅ "Italian marble: contractor_marble_experience(5yr+) + reference_projects(2) + insurance_coverage"
- ✅ "Exposed concrete: contractor_portfolio_review + test_panel_first + finish_approval_gate"

**Enforcement**: Specialty work must specify: required_certification + past_projects + insurance → Otherwise REJECT

---

### 42. Temporal Constraints Must Account for Climate

**Principle**: Scheduling must consider weather/seasons

**Violation**: Calendar dates without climate consideration

**Examples**:
- ❌ "Start construction in June"
- ❌ "Complete in 6 months"
- ❌ "Foundation by December"
- ✅ "Start: post-monsoon(Oct-Nov) + pre-summer(before_March) → window: Oct15-Feb28"
- ✅ "Duration: 6mo_base + 2mo_monsoon_buffer + 1mo_material_delay_buffer = 9mo_total"
- ✅ "Foundation: complete_before_monsoon(May) + 28-day_cure_buffer + inspection_gate"

**Enforcement**: Schedules must include: season_constraints + weather_buffers + monsoon_plan → Otherwise REJECT

---

### 43. Inspection Gates Must Be Explicit

**Principle**: Every phase must have validation checkpoint

**Violation**: No inspection, unclear inspector, no failure plan

**Examples**:
- ❌ "Complete foundation"
- ❌ "Inspector will check"
- ❌ "Quality to be verified"
- ✅ "Foundation complete → structural_engineer_signoff + compression_test(≥25N/mm²) + photo_documentation → PASS: proceed_to_columns | FAIL: remediation_plan_required"
- ✅ "Waterproofing → independent_inspector + water_test(24hr) + warranty_activation → FAIL: redo_at_contractor_cost"
- ✅ "Electrical → licensed_inspector + continuity_test + grounding_test → FAIL: rework_before_concealment"

**Enforcement**: Phase completion must specify: who_inspects + test_criteria + pass/fail_actions → Otherwise REJECT

---

### 44. Material Failure Modes Must Be Documented

**Principle**: Every material must state how it can fail and recovery cost

**Violation**: No failure analysis for critical materials

**Examples**:
- ❌ "Use M25 concrete for foundation"
- ❌ "Install marble flooring"
- ❌ "Apply waterproof coating"
- ✅ "M25 concrete: failure_mode(insufficient_strength) → detection(compression_test) → recovery(demolish+repour, ₹8L, +8wk)"
- ✅ "Marble flooring: failure_mode(cracking) → detection(visual) → recovery(replace_section, ₹2L, +2wk)"
- ✅ "Waterproofing: failure_mode(leakage) → detection(monsoon_test) → recovery(reapply, ₹50K, +1wk)"

**Enforcement**: Critical materials must specify: failure_mode + detection_method + recovery_cost → Otherwise REJECT

---

### 45. Supply Chain Must Be Stress-Tested

**Principle**: Material specs must include sourcing constraints

**Violation**: Specifying materials without availability validation

**Examples**:
- ❌ "Use Italian marble"
- ❌ "Install imported fixtures"
- ❌ "Source specialty lumber"
- ✅ "Italian marble: lead_time(8wk) + monsoon_shipping_risk + storage_needs(dry_warehouse) → fallback: Rajasthani_marble(2wk)"
- ✅ "Fixtures: local_availability_verified + 2_supplier_quotes + 4wk_delivery → fallback: alternative_equivalent"
- ✅ "Teak doors: supplier_confirmed + advance_booking(12wk) + storage_at_site → fallback: local_hardwood"

**Enforcement**: Imported/specialty materials must specify: lead_time + risks + fallbacks + storage → Otherwise REJECT

---

### 46. Cyclone Resistance Must Be Designed In

**Principle**: Coastal construction must meet IS 15498 cyclone-resistant standards

**Source**: IS 15498:2004 - Guidelines for Improving Cyclonic Resistance of Low Rise Houses; Tamil Nadu Combined Development and Building Rules 2019

**Violation**: Construction without wind load analysis or cyclone considerations

**Examples**:
- ❌ "Build standard residential design"
- ❌ "Use flat roof for simplicity"
- ❌ "Standard door and window sizes"
- ✅ "Wind load analysis per IS 875-3 with cyclonic factor + design for 200 km/h wind speed"
- ✅ "Hip/pyramidal roof with 22°-30° slope + secured roof-to-wall connections + no overhangs >600mm"
- ✅ "Windows: impact-resistant glass OR shutters + smaller openings on windward side + reinforced frames"
- ✅ "Foundation: pile foundation OR raised mound (1.2-1.5m) if in surge zone + anchor bolts for superstructure"

**Enforcement**: Coastal construction must specify: wind_load_design(IS_875-3) + roof_pitch(22-30°) + connection_details + surge_elevation_if_applicable → Otherwise REJECT

---

### 47. CRZ Compliance Must Be Verified

**Principle**: Construction must comply with Coastal Regulation Zone norms

**Source**: Tamil Nadu CRZ notification; Ministry of Environment guidelines

**Violation**: Building without CRZ clearance in coastal areas

**Examples**:
- ❌ "Build house near beach"
- ❌ "Start construction, get permits later"
- ❌ "Previous owner had approval"
- ✅ "CRZ classification: CRZ-II + setback_verified(50m from HTL) + CZMP_approved + SEIAA_clearance"
- ✅ "CRZ-III area: no_construction_in_NDZ(0-200m) OR traditional_dwelling_exemption_verified"
- ✅ "Existing structure: regularization_status_confirmed + compliance_certificate_obtained"

**Enforcement**: Coastal construction must specify: CRZ_zone_classification + setback_compliance + clearance_status → Otherwise REJECT

---

## Construction-Specific Sub-Invariants

### 45a. Concrete Specifications

- Grade must be specified (M20, M25, M30)
- Cure time must be enforced (typically 28 days)
- Slump test required before pour
- Compression test required after cure

**Enforcement**: Concrete specs must include: grade(M20|M25|M30) + cure_time(≥28d) + slump_test_before_pour + compression_test_after_cure + coastal_additive_if_applicable(salt_resistant). Concrete pour without grade + cure time + test requirements → REJECT

### 45b. Steel Specifications

- Grade must be specified (Fe415, Fe500, Fe550)
- Mill certificate required
- No site welding without engineer approval
- Lap length per structural drawings

**Enforcement**: Steel specs must include: grade(Fe415|Fe500|Fe550) + mill_certificate_required + no_site_welding_without_approval + lap_length_per_drawing + corrosion_protection_if_coastal. Steel work without grade + mill certificate requirement → REJECT

### 45c. Waterproofing Specifications

- System must be specified (not just "waterproof")
- Warranty period required (minimum 5 years)
- Water test before concealment
- Drainage path must be defined

**Enforcement**: Waterproofing specs must include: system_name(not generic "waterproof") + warranty_period(≥5yr) + water_test_before_concealment + drainage_path_defined. Generic "waterproofing" without system + warranty + test → REJECT

### 45d. Coastal Corrosion Protection

- All exposed metal must have marine-grade coating or galvanization
- Concrete cover increased for coastal exposure (per IS 456)
- Stainless steel or coated fasteners required within 5km of coast
- 5-year coating renewal schedule required

**Enforcement**: Coastal construction must specify: metal_protection_system + concrete_cover_increase + fastener_specification + maintenance_schedule. Exposed metal within 5km of coast without corrosion protection plan → REJECT

---

## Quick Reference

| # | Invariant | Key Test |
|---|-----------|----------|
| 40 | Material Properties Must Be Climate-Validated | Materials have climate specs |
| 41 | Vendor Capabilities Must Be Validated | Contractors have verified credentials |
| 42 | Temporal Constraints Must Account for Climate | Schedule includes monsoon buffer |
| 43 | Inspection Gates Must Be Explicit | Every phase has pass/fail criteria |
| 44 | Material Failure Modes Must Be Documented | Failure + detection + recovery cost |
| 45 | Supply Chain Must Be Stress-Tested | Lead times + fallbacks documented |
| 46 | Cyclone Resistance Must Be Designed In | Wind load + roof pitch + connections |
| 47 | CRZ Compliance Must Be Verified | Zone classification + setback + clearance |

---

*Domain: Physical Construction*
*Invariants: 40-47 (plus sub-invariants)*
*Use with: Core invariants 1-11*
*Often combined with: remote-management.md*

<!-- TEMPLATE: remove this line once the document is filled in -->
# Requirements: <Use-case title>

<!-- guidance: Copy to use-cases/<id>/01-requirements/requirements.md. This file is the evidence artifact for gate G2.
     Requirements drive the architecture (AP-01). Every material component and ADR must trace back here, and every Must FR and NFR must trace forward to a test.
     T1: short FR/NFR lists; the traceability matrix may be FR → component only. T2+: the full matrix is required. T3+: every NFR has a test ID before G8. -->

- **Use-case ID:** <id>
- **Version / date:** v0.1 / YYYY-MM-DD
- **Baselined from:** 00-intake/use-case-brief.md (date)

## Functional Requirements

<!-- guidance: One testable behavior per row. Priority uses MoSCoW: Must / Should / Could / Won't (this release). The acceptance criterion must be observable. "Works correctly" is not observable. Source = OBJ-, stakeholder, CON-, or regulation. -->

| ID | Statement | Priority | Source | Acceptance criterion |
|---|---|---|---|---|
| FR-001 | (example) The system extracts supplier, amount, currency, and due date from an inbound PDF invoice | Must | OBJ-01, AP Ops lead | On EVAL-001, field-level exact match ≥ 95% for amount and currency |
| FR-002 | | | | |

### Human-in-the-loop and side-effect requirements

<!-- guidance: List every action that writes to a business system, sends a message, or spends money, and state who approves it. These drive tier, threat model, and AP-14 deterministic controls. -->

| FR ID | Action / side effect | Target system | Approval required? (who) | Reversible? | Deterministic control |
|---|---|---|---|---|---|
| FR-00x | (example) Post invoice to ERP | ERP AP module | Yes: AP clerk | Yes, within 24 h | Amount ≤ PO value check in code |

## Non-Functional Requirements

<!-- guidance: Each NFR must be measurable: metric, target, percentile or conditions, where it is measured, and how. Categories: Performance, Availability, Scalability, Security, Privacy, Compliance, AI Quality, Cost, Operability, Portability, Accessibility.
     Status: Proposed / Agreed / Conflict / Withdrawn. Mark a conflict with nfr-validation and name the resolution owner. -->

| ID | Category | Metric | Target | Percentile / conditions | Measurement point | Method | Source | Test ID | Status |
|---|---|---|---|---|---|---|---|---|---|
| NFR-001 | (example) Performance | End-to-end extraction latency | ≤ 8 s | p95, 20 concurrent docs, ≤ 10 pages | API gateway ingress → result persisted | Load test with tracing | AP Ops SLA | TST-010 | Proposed |
| NFR-002 | (example) AI Quality | Unsupported-claim rate in summaries | ≤ 2% | Per release, on EVAL set | Offline evaluation harness | Calibrated LLM judge + 10% human audit | Risk owner | EVAL-003 | Proposed |
| NFR-003 | (example) Cost | Inference cost per document | ≤ $0.04 | Monthly average | Token metering at AI gateway | Cost dashboard | Finance | TST-030 | Proposed |

### NFR conflicts

| Conflict | NFRs involved | Options | Resolution / owner | Status |
|---|---|---|---|---|
| (example) Larger model improves quality but breaks cost target | NFR-002, NFR-003 | Routing; relax cost; accept quality risk | Product owner | Open |

## Constraints and Assumptions

<!-- guidance: Carry forward each input from the brief and add any new ones found during requirements work. Treatment must match standards/architecture-principles.md §2. Never violate a CON or PRH silently. If one makes a requirement infeasible, record the conflict and the decision owner. -->

### Constraints, prohibitions, preferences, investments, and open decisions

| ID | Category | Statement | Source | Treatment | Affected requirements | Conflict? (decision owner) |
|---|---|---|---|---|---|---|
| CON-001 | Mandatory constraint | (example) Data stays in national region | Policy §4 | Respected; all components in-region | NFR-00x | No |
| PRH-001 | Prohibition | (example) No public SaaS LLM endpoints | CISO | Excluded from technology options | — | No |
| PREF-001 | Preference | (example) LangGraph | Eng lead | Evaluated in ADR-00x | FR-00x | — |
| INV-001 | Existing investment | (example) n8n platform | Platform team | Reuse assessed in solution design | FR-00x | — |
| DEC-001 | Open decision | (example) Model hosting | Kickoff | ADR-00x | NFR-001, NFR-003 | — |

### Assumptions

| ID | Assumption | Impact if wrong | Confidence (H/M/L) | Validation method | Owner | Deadline | Status |
|---|---|---|---|---|---|---|---|
| ASM-001 | (example) ≤ 5k docs/day for 12 months | Capacity and cost re-plan | M | Portal log analysis | AP Ops lead | Before MS-02 | Open |

## Traceability

<!-- guidance: One row per requirement (FR, NFR, and material CON). Use "—" only where the link genuinely doesn't apply, and give the reason in Notes. An empty Component or Test cell for a Must FR or NFR fails G2/G7.
     Keep this matrix consistent with the component catalogue (solution-design.md), the ADRs, and the verification matrix (test-and-evaluation-plan.md). -->

| Requirement | Priority | Component(s) | ADR(s) | Test / Eval ID(s) | Threat ID(s) | Notes |
|---|---|---|---|---|---|---|
| FR-001 | Must | (example) C-03 Extraction service | ADR-002 | EVAL-001, TST-004 | T-004 | |
| NFR-001 | — | C-01, C-03 | ADR-002 | TST-010 | — | |
| CON-001 | — | All | ADR-001 | TST-040 (region policy check) | — | |

### Orphan check

- [ ] Every Must FR and NFR has at least one component and at least one test
- [ ] Every component in the catalogue appears in at least one row (no orphan components)
- [ ] No row references a Withdrawn requirement or a Superseded ADR as current

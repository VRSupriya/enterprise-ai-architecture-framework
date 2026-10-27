# Requirements: Field Service Assistant (TEST FIXTURE review)

Source: the fixture's R1–R4 and NFR-A–D, restated as testable requirements by the board in round 1. Proposed targets are `ASM` until the (fictional) sponsor confirms them.

## Functional Requirements

| ID | Statement | Priority | Source | Acceptance criterion |
|---|---|---|---|---|
| FR-001 | Answer technician questions about equipment manuals, with citations (doc id, revision, page) | Must | R1 | On EVAL-001: recall@5 and citation correctness ≥ sponsor thresholds; abstains when no answer exists |
| FR-002 | Answer questions about an asset's maintenance history, within the technician's entitlement | Must | R1 | On EVAL-002: correct records returned; zero out-of-entitlement rows (TST-I5) |
| FR-003 | Create a follow-up work order from the conversation after the technician confirms the exact fields | Must | R2, Q-001 | Median < 2 min from request to ERP ack (OBJ-02); zero duplicates under fault injection (TST-R1) |
| FR-004 | Update the status of an existing work order, using allowed transitions only, after confirmation | Must | R3 | Disallowed transitions rejected by code (TST-A4); confirmation required (TST-A5) |
| FR-005 | Escalate to a human dispatcher on request, with a context packet; works without the model | Must | R4 | Dispatcher receives the packet; works with the model disabled (TST-R3) |

### Human-in-the-loop and side-effect requirements

| FR ID | Action / side effect | Target system | Approval required? (who) | Reversible? | Deterministic control |
|---|---|---|---|---|---|
| FR-003 | Create work order | ERP via n8n | Yes: technician confirms exact payload | Yes (cancel via status) | ≤ 3 per conversation; priority allow-list (no EMERGENCY; routed to dispatcher); asset exists; idempotency key |
| FR-004 | Update status | ERP via n8n | Yes: technician | Yes | Allowed-transition table; entitlement check |
| FR-005 | Teams post to dispatch | Teams | No (user-initiated, templated) | N/A | Fixed channel; typed template; no free-form links |
| — | Delete work order | — | Not provided (Q-002) | — | Tool removed |

## Non-Functional Requirements

| ID | Category | Metric | Target | Percentile / conditions | Measurement point | Method | Source | Test ID | Status |
|---|---|---|---|---|---|---|---|---|---|
| NFR-001 | Performance | Q&A time to first token / full answer | ≤ 4 s / ≤ 15 s | p95, peak + 2× headroom | API edge | Load test with tracing | NFR-A → ASM (F-RE-03) | TST-P4 | Proposed |
| NFR-002 | Performance | Request → draft WO shown; confirm → ERP ack | ≤ 10 s; ≤ 5 s | p95, excluding declared ERP incidents | API edge | Load test | NFR-A, OBJ-02 → ASM | TST-P4 | Proposed |
| NFR-003 | Availability | Valid turns answered with full service (degraded-mode availability tracked separately, F-BRD-21) | ≥ 99.5 % | Working-hours window (to confirm), 28-day rolling | API edge | SLO monitoring | NFR-B → ASM | TST-R3 | Proposed |
| NFR-004 | Integrity | Duplicate ERP writes caused by retries or re-planning | 0 | All fault-injection runs | ERP reconciliation | Fault injection + daily reconciliation | F-RE-01 | TST-R1, TST-R2 | Proposed |
| NFR-005 | Residency | Customer/asset data processed or stored outside the mandated region | 0 resources | All environments | Azure resource inventory | Azure Policy compliance | CON-002 | TST-D1 | Proposed |
| NFR-006 | Auditability | WO changes traceable to technician, confirmation, agent/prompt/model version, ERP txn | 100 % | Sampled monthly by internal audit | Audit store | Trace-back test | CON-003 | TST-A6 | Proposed |
| NFR-007 | Security | Consequential writes without a valid parameter-bound confirmation | 0 | Adversarial suite | Command service | Injection + tamper tests | F-SE-04 | TST-A5, TST-I1, TST-I2 | Proposed |
| NFR-008 | Cost / bounds | Model calls per turn; tokens per turn; daily spend | ≤ 3; ≤ 30k; alert at 150 %, stop at 300 % of baseline | Per turn / per day | Gateway metering | Limit-exhaustion tests | F-RE-02, ASM-P07 | TST-P1 | Proposed |
| NFR-009 | Privacy | Customer identifiers in general telemetry | 0 | Seeded-PII test | App Insights | Log query | F-DK-04 | TST-D2 | Proposed |
| NFR-010 | Recovery | Service RTO / state RPO / index RTO | ≤ 4 working h / ≤ 15 min / ≤ 24 h | — | Restore drill | DR drill before go-live | F-RE-07 | TST-R4 | Proposed |

### NFR conflicts

| Conflict | NFRs involved | Options | Resolution / owner | Status |
|---|---|---|---|---|
| Regional model deployment may have lower quota or later models than Global/Data Zone | NFR-005 vs NFR-001/003 | Regional deployment; written ruling that a data zone counts as in-region; smaller in-region model | Residency policy owner (Q-IN-02) | Open |
| Cross-region DR vs residency | NFR-010 vs NFR-005 | Zone-redundant single region; second compliant region if one exists | CISO + residency owner | Open |
| Audit completeness vs data minimization in logs | NFR-006 vs NFR-009 | Separate audit store (structured fields) from metadata-only telemetry | Resolved by design (ADR-002) | Closed |

## Constraints and Assumptions

| ID | Category | Statement | Source | Treatment | Affected requirements | Conflict? (decision owner) |
|---|---|---|---|---|---|---|
| CON-001 | Mandatory constraint | Azure is the mandated cloud | CIO memo | All components Azure-native; Pinecone rejected (ADR-004) | All | Pinecone-on-Azure interpretation is moot once it is rejected |
| CON-002 | Mandatory constraint | Customer/asset data stays in-region | Residency policy | Regional deployments + Azure Policy (ADR-003) | NFR-005 | **Yes: the implemented `eastus` model breaks it (F-BRD-01)** |
| CON-003 | Mandatory constraint | Work-order changes auditable | Internal audit | Audit store + identity propagation (ADR-002) | NFR-006 | Breached by the current implementation (F-BRD-03) |
| INV-001 | Existing investment | n8n ERP create/update flows | Platform | Retained as the only ERP write adapter (ADR-002) | FR-003, FR-004 | — |
| PREF-001 | Preference | LangGraph multi-agent on AKS | Draft design | Rejected (ADR-001); runtime per ADR-005 | All | — |
| PREF-002 | Preference | Pinecone | Draft design | Rejected (ADR-004) | FR-001 | — |
| PREF-003 | Preference | Custom AI gateway | Draft design | Rejected in favor of APIM (ADR-006) | All | — |
| DEC-001 | Open decision | Model region | §5 | ADR-003 | NFR-005 | — |

### Assumptions

| ID | Assumption | Impact if wrong | Confidence (H/M/L) | Validation method | Owner | Deadline | Status |
|---|---|---|---|---|---|---|---|
| ASM-001 | R1+R2 automation can deliver −40 % calls | Business case | L | Call-reason analysis (slice S0) | Sponsor | Before MS-02 | Open |
| ASM-002 | Manual corpus < 50k pages | Search tier sizing | M | Corpus inventory | Asset engineering | Before MS-02 | Open |
| ASM-003 | Python team, no agent-framework experience | Favors the simpler design | H | Stated | Eng lead | — | Accepted |
| ASM-004 | Technician confirms every write (Q-001) | Approval design, tier | M | Sponsor decision | Sponsor | Before MS-03 | Open |
| ASM-005 | n8n flows can accept an idempotency key and actor id | ADR-002 fallback | M | Inspect flows in non-prod | ERP/integration team | Slice S0 | Open |
| ASM-006 | The team has limited platform-engineering capacity (inferred; not stated in ASM-003, per DBT-07) | Strengthens ADR-005 but doesn't decide it | L | Ask the engineering lead | Eng lead | Before MS-01 | Open |

## Traceability

| Requirement | Priority | Component(s) | ADR(s) | Test / Eval ID(s) | Threat ID(s) | Notes |
|---|---|---|---|---|---|---|
| FR-001 | Must | C-02, C-03, C-08 | ADR-001, ADR-004 | EVAL-001, TST-I1 | T-001 | |
| FR-002 | Must | C-02, C-04 | ADR-001 | EVAL-002, TST-I5 | T-004 | |
| FR-003 | Must | C-02, C-05, C-06, C-09 | ADR-002 | TST-A4, TST-A5, TST-R1 | T-001, T-002, T-003 | |
| FR-004 | Must | C-05, C-06, C-09 | ADR-002 | TST-A2, TST-A4 | T-003 | |
| FR-005 | Must | C-07 | ADR-001 | TST-R3, TST-I4 | T-009 | Model-free path |
| NFR-001 | — | C-02, C-08 | ADR-001, ADR-005 | TST-P4 | — | |
| NFR-002 | — | C-05, C-06 | ADR-002 | TST-P4 | — | |
| NFR-003 | — | All | ADR-005, ADR-006 | TST-R3 | — | |
| NFR-004 | — | C-05, C-06, C-11 | ADR-002 | TST-R1, TST-R2 | T-002 | |
| NFR-005 | — | All | ADR-003 | TST-D1 | T-005 | |
| NFR-006 | — | C-05, C-09 | ADR-002 | TST-A6 | T-007 | |
| NFR-007 | — | C-05 | ADR-002 | TST-A5, TST-I1, TST-I2 | T-001, T-008 | |
| NFR-008 | — | C-02, C-08 | ADR-001, ADR-006 | TST-P1 | T-010 | |
| NFR-009 | — | C-02 | ADR-003 | TST-D2 | T-005 | |
| NFR-010 | — | All | ADR-005 | TST-R4 | — | |

### Orphan check

Every Must FR and every NFR maps to at least one component and one test. Components C-01 to C-09 each trace to at least one requirement.

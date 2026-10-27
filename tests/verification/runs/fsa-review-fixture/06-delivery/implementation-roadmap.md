# Implementation Roadmap: Field Service Assistant remediation (TEST FIXTURE)

This roadmap uses relative sequencing only; no calendar dates have been agreed. Owners are roles (fictional), and the plan migrates the system in thin slices with security and observability built in from the first slice.

## Workstreams

| ID | Workstream | Owner role | Key outputs |
|---|---|---|---|
| WS-01 | Containment and platform | Platform lead | Writes disabled behind a flag, in-region model, APIM, managed identity, policy |
| WS-02 | Data and retrieval | Data lead | AI Search index, ingestion, governed history views, EVAL-001 |
| WS-03 | Conversation and command services | Solution lead | C-02, C-05, confirmation UX, audit store |
| WS-04 | Integration | ERP/integration lead | n8n contract (idempotency key, actor), escalation flow |
| WS-05 | Security and validation | Security lead | Identity (OBO), PEP, adversarial suite |
| WS-06 | Reliability and operations | Reliability lead | SLOs, alerts, runbooks, DR drill, Container Apps and IaC |

## Milestones

| ID | Milestone | Exit criterion |
|---|---|---|
| MS-00 | Containment complete | Delete tool removed, write retries at 0, write flag off, content logging stopped; TST-A1 passes |
| MS-01 | Slice S0: decisions and evidence | ASM-001, ASM-005, Q-001 and Q-IN-02 answered; EVAL sets drafted |
| MS-02 | Slice S1: read-only pilot | Pilot gate in the test plan passes |
| MS-03 | Slice S2: confirmed work-order create | Write gate passes |
| MS-04 | Slice S3: status update and production readiness | Production gate passes; G9/G10 |
| MS-05 | Decommission | Multi-agent graph, custom gateway, Pinecone and AKS retired (T-State 3) |

## Dependencies

| Item | Depends on | Blocking? |
|---|---|---|
| ADR-003 regional deployment | Q-IN-02 ruling; model availability in the region | Yes, for MS-02 |
| ADR-002 n8n write path | ASM-005 (n8n accepts key and actor) | Yes, for MS-03; fallback recorded |
| OBO identity | ERP/n8n token support | No; fallback identity available |
| ADR-005 Container Apps | Condition checks (a)–(d) | Yes, for MS-04 |

### Platform prerequisites
- [ ] Mandated region named, plus Azure Policy assignments (allowed locations, deny Global SKUs, deny public access)
- [ ] APIM instance available, existing or new (Q-IN-01)
- [ ] Spoke VNet, private DNS, firewall allowlist
- [ ] Separate subscriptions per environment, and an ERP sandbox reachable through non-prod n8n

## Backlog

| ID | Item | Traces to | Acceptance criterion |
|---|---|---|---|
| BL-01 | Remove `erp_delete_work_order`; set write retries to 0; add a write feature flag | F-BRD-05/06 | TST-A1 passes; flag tested |
| BL-02 | Regional Azure OpenAI deployment via IaC, plus policy | ADR-003, NFR-005 | TST-D1 passes |
| BL-03 | APIM + managed identity; disable key auth; retire the gateway | ADR-006 | TST-S1 passes |
| BL-04 | Metadata-only telemetry; redacted capture store with TTL | F-BRD-11, NFR-009 | TST-D2 passes |
| BL-05 | Ingestion pipeline + AI Search hybrid index with provenance | ADR-004, FR-001 | Supersession test; EVAL-001 threshold |
| BL-06 | Governed history views + typed read tools with entitlement | F-BRD-07, FR-002 | TST-I5, TST-P3 pass |
| BL-07 | C-02 Conversation Service: intent and extraction steps, context assembly, ≤ 3 LLM calls | ADR-001, T-001 | TST-I1/I2, TST-P1 pass |
| BL-08 | C-05 Command Service: policy, confirmation token, idempotency, audit | ADR-002, T-002/007/008 | TST-A4–A6, TST-R1 pass |
| BL-09 | n8n contract v1: idempotency key + actor + error codes | ADR-002, ASM-005 | Integration test in ERP sandbox |
| BL-10 | Escalation adapter (model-free) | FR-005, T-009 | TST-R3, TST-I4 pass |
| BL-11 | Container Apps environment, IaC, environments | ADR-005, F-BRD-14 | IaC review; conditions (a)–(d) verified |
| BL-12 | SLOs, alerts, runbooks, DR drill | NFR-003, NFR-010 | Alert-fire test; TST-R4 passes |

### Environment and CI/CD
- Every resource is defined in IaC (Bicep or Terraform), with policy-as-code checks and a scheduled drift check.
- The pipeline promotes dev → test → prod, with an approval step before prod.
- Prompts, model pins, tool schemas and limits are versioned and deployed as one unit. EVAL-001/002 run on every change.

## Operational Readiness

| SLO | Alert | Owner | Runbook |
|---|---|---|---|
| NFR-001 latency | p95 burn rate | Reliability on-call (TBD; Q-RE) | `runbooks/latency.md` (to write in BL-12) |
| NFR-003 availability | Error-budget burn | Reliability on-call | `runbooks/degraded-mode.md` (to write) |
| NFR-004 duplicates | Any duplicate found in reconciliation | Solution lead | `runbooks/duplicate-wo.md` (to write) |
| NFR-008 cost | Spend at 150 % / 300 % of baseline | Platform lead | `runbooks/spend.md` (to write) |

These runbooks are not written yet. They are tracked in BL-12, and G9 can't pass without them.

## Rollout and Rollback

- **Rollout:** read-only pilot with one crew. Writes then follow in shadow mode, where drafts are shown but not submitted, for one crew. After that, writes are enabled for the pilot crew, followed by a staged expansion.
- **Rollback triggers** (from the test plan): any duplicate WO, any write without a valid token, p95 above 1.5× the target for 30 minutes, or groundedness down more than 5 points. When a trigger fires, the write flag goes off immediately and the APIM backend and images revert to the previous version.

## Risks

| ID | Risk | Mitigation |
|---|---|---|
| RSK-01 | Model not available regionally in the mandated region | Escalate as a constraint conflict (ADR-003) |
| RSK-02 | n8n can't carry the idempotency key | Fallback in ADR-002 |
| RSK-03 | Retrieval quality unknown | EVAL-001 gate before the pilot |
| RSK-04 | Container Apps conditions fail | Re-open ADR-005 |

<!-- TEMPLATE: remove this line once the document is filled in -->
# Implementation Roadmap: <Use-case title>

<!-- guidance: Copy to use-cases/<id>/06-delivery/implementation-roadmap.md. This file is the evidence for gate G9 and is produced by the implementation-roadmap skill.
     Use relative sequencing (MS-01 → MS-02, "Sprint +2", "after MS-03"). Do NOT invent calendar dates. Add dates only when the delivery owner supplies them, and cite the source.
     T1: a short list of milestones and a rollback note. T2: all sections. T3+: the operational-readiness chain must be complete, and rollout must be staged with numeric triggers. -->

- **Use-case ID / version:** <id> / v0.1 · **Tier:** T2 · **Date:** YYYY-MM-DD · **Delivery owner:** <name, role>
- **Design baseline:** 02-design/solution-design.md (version) · ADRs in force: ADR-001…

## Workstreams

| ID | Workstream | Scope (components C-) | Lead (team) | Key outputs |
|---|---|---|---|---|
| WS-01 | (example) Platform and environments | C-01, gateway onboarding | Platform team | Environments, IaC, pipelines |
| WS-02 | (example) Extraction and evaluation | C-03, EVAL-001 | AP product team | Prompts v1, eval harness |
| WS-03 | (example) Integration and approval UI | C-04, C-05 | ERP integration team | ERP connector, approval screen |

## Milestones

<!-- guidance: Each milestone has an exit criterion that someone can observe. Link it to the gates it satisfies. -->

| ID | Milestone | Sequence (relative) | Exit criterion | Gates / evidence |
|---|---|---|---|---|
| MS-01 | (example) Platform prerequisites in place | First | Dev and test environments provisioned through IaC; gateway access approved | — |
| MS-02 | (example) Offline evaluation passes | After MS-01 | EVAL-001 ≥ 95% observed | G8 |
| MS-03 | (example) Pilot with one AP team | After MS-02 + readiness checklist complete | Pilot release criteria met | G9 |
| MS-04 | (example) General availability | After MS-03 + 2 weeks stable | Production approval recorded | G10 |

## Dependencies

| Dependency | Needed by | Provider (team / vendor) | Status | Risk if late |
|---|---|---|---|---|
| (example) AI gateway onboarding | MS-01 | Enterprise AI platform | Requested | Blocks WS-02 |

### Platform prerequisites

- [ ] (example) In-region model endpoint available and quota approved (CON-001)
- [ ] Identity: workload identities and RBAC roles created
- [ ] Secrets store and key rotation configured
- [ ] Logging / tracing sink with retention approved for the data classification
- [ ] Network paths and egress allow-lists approved

## Backlog

<!-- guidance: Epic- or feature-level items. Every item traces to a requirement, ADR, threat, or finding. The acceptance criterion must be testable. -->

| ID | Item | Workstream | Trace IDs | Acceptance criterion | Milestone | Status |
|---|---|---|---|---|---|---|
| BL-001 | (example) Deterministic payee validation against vendor master | WS-03 | FR-004, T-001, ADR-003 | TST-021 passes; mismatched payee blocks posting | MS-02 | Not started |

## Environments and CI/CD

| Environment | Purpose | Data allowed | Promotion gate |
|---|---|---|---|
| (example) Dev | Build | Synthetic only | Unit + contract tests |
| (example) Staging | Eval, adversarial, integration | Masked production sample | Release criteria (test plan) |
| (example) Production | Live | Production | G10 approval |

- **Pipeline:** <build → test → eval → security scan → deploy; tool>
- **IaC:** <tool, repo, review rule>
- **Versioned artifacts (model, prompt, tool schema, agent config):** <where versioned; how promoted together>

## Operational Readiness

<!-- guidance: Every SLO must have an alert, an owner, and a runbook. A broken chain means G9 is not passed. -->

| SLO / signal | Alert (condition) | Owner (on-call) | Runbook | Status |
|---|---|---|---|---|
| (example) p95 latency ≤ 8 s (NFR-001) | p95 > 8 s for 10 min | AP Platform on-call | runbooks/latency.md | Not ready |
| (example) Extraction accuracy (weekly sample) | < 92% | AP product owner | runbooks/quality-drift.md | Not ready |
| (example) Daily cost | > 150% of budget | Platform owner | runbooks/cost-spike.md | Not ready |

- [ ] Support model and escalation path agreed (L1/L2/L3)
- [ ] DR procedure documented and tested (T3+), or the test is scheduled before go-live with an owner
- [ ] Cost budgets and quotas configured
- [ ] Re-evaluation cadence and retirement criteria defined

## Rollout and Rollback

| Stage | Exposure | Advance when | Roll back when (numeric) | Rollback action |
|---|---|---|---|---|
| (example) Shadow | 0% (output not used) | Accuracy ≥ 95% over 500 docs | — | — |
| (example) Pilot | 1 team, ~10% volume | 2 weeks; override rate < 10% | Accuracy < 90% over 200 docs; error rate > 2% for 15 min | Feature flag off → manual queue |
| (example) GA | 100% | — | Same as pilot | Revert model/prompt version via pipeline |

## Ownership and Skills

| Area | Owning team | Skills needed | Gap / plan |
|---|---|---|---|
| (example) Prompt and eval maintenance | AP product team | Eval design, prompt versioning | Training before MS-02 |

## Risks

| ID | Delivery risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| RSK-0xx | (example) Gateway onboarding delayed | M | H | Request at kickoff; use a dev sandbox in the interim | Delivery owner |

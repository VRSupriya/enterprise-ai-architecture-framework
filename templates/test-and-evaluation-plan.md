<!-- TEMPLATE: remove this line once the document is filled in -->
# Test and Evaluation Plan: <Use-case title>

<!-- guidance: Copy to use-cases/<id>/05-validation/test-and-evaluation-plan.md. This file is the evidence for gate G8 (and feeds G9/G10). Required at T3/T4, and recommended at T2 for any AI step.
     HONEST STATUS RULE: Status is "Not run" until a result has actually been observed. Record a Pass or Fail only with a link to the observed evidence (run ID, report path, or date). A planned test is not a passed test. A claimed result without observed evidence blocks the gate.
     T2: matrix plus a small eval set. T3+: every section complete, with numeric thresholds. -->

- **Use-case ID / version:** <id> / v0.1 · **Tier:** T3 · **Date:** YYYY-MM-DD · **Test owner:** <name>

## Verification Matrix

<!-- guidance: One row per Must FR, every NFR, and every threat mitigation with a test ID. Type ∈ Unit, Integration, Contract, E2E, Eval (offline), Eval (online), Adversarial, Load, Resilience, DR, Security, Compliance, Manual review. Status ∈ Not run / Pass / Fail. -->

| Requirement / threat | Test ID | Type | Environment | Pass criterion | Status | Evidence (when observed) |
|---|---|---|---|---|---|---|
| (example) FR-001 | EVAL-001 | Eval (offline) | Staging | Amount and currency exact match ≥ 95% on EVAL-001 v1 | Not run | — |
| (example) NFR-001 | TST-010 | Load | Perf env | p95 ≤ 8 s at 20 concurrent docs for 30 min | Not run | — |
| (example) T-001 | TST-021 | Adversarial | Staging | 0 payee changes reach ERP across the injection suite | Not run | — |

## AI Evaluation

### Datasets

<!-- guidance: Provenance matters. Record where the cases came from, who labeled them, and whether they contain personal data (use placeholders or synthetic data where required). Keep eval data separate from any data used to build prompts or few-shot examples. -->

| Eval set ID | Purpose | Source / provenance | Size (and rationale) | Labeling method / labeler | Sensitive data handling | Version | Refresh cadence |
|---|---|---|---|---|---|---|---|
| EVAL-001 | (example) Field extraction accuracy | 600 production invoices, stratified by top-30 suppliers | 600: ±2% at 95% CI | Dual-labeled by AP clerks, adjudicated | Bank details masked | v1 | Quarterly + on new supplier layout |

### Metrics and thresholds

| Metric | Definition | Eval set | Threshold (release) | Threshold (alert in production) | Linked NFR/FR |
|---|---|---|---|---|---|
| (example) Field exact match | Exact match per field, macro-averaged | EVAL-001 | ≥ 95% | < 92% on weekly sample | FR-001 |
| (example) Unsupported-claim rate | Claims not grounded in source | EVAL-003 | ≤ 2% | > 3% | NFR-002 |

### Judge calibration (if an LLM or model is used as a judge)

- **Judge model and prompt version:**
- **Calibration set:** <n cases with human labels> · **Agreement with humans:** <metric, e.g., Cohen's κ ≥ 0.7 required>
- **Known judge biases checked (position, verbosity, self-preference):**
- **Human audit sample per release:** <e.g., 10% of judged cases>

## Adversarial Testing

<!-- guidance: Derive cases from the threat model. Each case links a T- ID. T3+: the red team's cases (round-*/red-team-architect.md) are included. -->

| Test ID | Threat ID | Technique | Ingestion path | Expected safe behavior | Pass criterion | Status |
|---|---|---|---|---|---|---|
| TST-021 | T-001 | (example) Hidden-text instruction in a PDF to change the payee | DF-01 | Proposal flagged; deterministic payee check rejects it | 0 successful changes / 50 variants | Not run |

Coverage checklist: [ ] direct injection · [ ] indirect injection on every content path · [ ] tool misuse / parameter tampering · [ ] excessive agency · [ ] data exfiltration via output · [ ] denial of wallet (loops, oversized inputs) · [ ] jailbreak of content policy

## Performance and Load

| Test ID | Scenario | Load profile | Metric and target | Environment | Status |
|---|---|---|---|---|---|
| TST-010 | (example) Peak month-end | Ramp to 20 concurrent, hold 30 min | p95 ≤ 8 s; error rate < 0.5% | Perf env, production-like quotas | Not run |

## Resilience and DR

| Test ID | Failure injected | Expected behavior | Target (RTO/RPO, degraded mode) | Status |
|---|---|---|---|---|
| TST-050 | (example) Model provider returns 429/5xx for 10 min | Queue backs off; jobs complete within SLA after recovery; no duplicate ERP posts | 0 lost jobs; 0 duplicates | Not run |
| TST-051 | (example) Region failover | Restore from backup in secondary region | RTO ≤ 4 h, RPO ≤ 15 min | Not run |

## Release Criteria

<!-- guidance: All thresholds are numeric. Release proceeds only when every gating row is Pass with observed evidence, or is formally waived by the named approver. -->

| Criterion | Threshold | Gating? | Evidence |
|---|---|---|---|
| (example) All Must FR tests | 100% Pass | Yes | |
| (example) EVAL-001 field exact match | ≥ 95% | Yes | |
| (example) Adversarial suite | 0 Critical/High failures | Yes | |
| (example) Load test p95 | ≤ 8 s | Yes | |

### Rollback triggers (production)

| Trigger | Threshold and window | Action | Decided by |
|---|---|---|---|
| (example) Extraction accuracy on audited sample | < 90% over 200 docs | Route 100% to manual queue; roll back prompt/model version | On-call product owner |
| (example) Error rate | > 2% for 15 min | Roll back deployment | On-call engineer |
| (example) Cost per document | > 2× target for 24 h | Throttle and investigate | Platform owner |

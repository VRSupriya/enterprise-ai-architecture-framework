# Debate Record: fsa-review-fixture (TEST FIXTURE)

- **Chair:** Coordinator · **Date:** 2026-10-27 · **Rounds:** 1 independent review (7 specialists, red team blind), plus 1 targeted rebuttal round (DBT-03)
- A majority vote is not evidence. Every outcome below cites a requirement, constraint, rubric clause, or finding evidence.

## Proposal

The proposal under review is the drafted six-agent LangGraph system on AKS: Pinecone, a custom AI gateway, direct ERP REST writes, and an Azure OpenAI deployment that the implementation places in `eastus` (`tests/fixtures/field-service-assistant/`).

Binding constraints: CON-001 (Azure), CON-002 (in-region data), CON-003 (auditable work-order changes). Existing investment: INV-001 (n8n ERP flows).

## Objections

| ID | Raised by | Objection | Evidence | Response | Outcome | Rationale |
|---|---|---|---|---|---|---|
| DBT-01 | AG, SA, RT, RE, SE | Multi-agent (ladder rung 7) is unjustified; the paths can be enumerated | F-AG-01 ladder walk; F-RT-10; F-RE-04 latency arithmetic | No specialist defended rung 7 | Accepted | Fails `agentic-ai-design-principles.md` §1.1/§1.2; AP-03 |
| DBT-02 | SA, RE, RT (vs AG) | Shape: "workflow with LLM steps" (AG, SA) vs "workflow **or** a single bounded agent" (RT, RE) | F-AG-01 rung table; F-SA D1 alternative | AG already rejects rung 6 *now*. It re-opens only for a read-only R1 agent, and only if EVAL-001 shows that fixed retrieval fails multi-hop questions. RT and RE accept that condition, since their objection targeted multi-agent. | Accepted (AG shape + evaluation-gated trigger) | The evidence asymmetry favours the lower rung (AP-03). Reversibility comes from the trigger (AP-11). → ADR-001 |
| DBT-03 | IN vs RT | Runtime: Container Apps (IN, F-IN-05) vs "AKS acceptable" (RT) | round-2 rebuttals | RT conceded the substance. Its earlier line only said AKS does not breach CON-001. RT added 4 conditions. IN named 3 AKS triggers. | Accepted with conditions | Workload ≈ 0.07 req/s at 5× peak. There are 2 stateless services and no GPU. AP-03/AP-06. → ADR-005 |
| DBT-04 | DK (High) vs SE, RT, AG (Critical) | Severity of the indirect-injection → write-tool path | F-DK-05, F-SE-05, F-RT-07, F-AG-10 | DK pre-agreed to Critical "if no deterministic confirmation gate exists". None exists in the baseline. | Critical | Severity rubric: an exploitable injection path that leads to write actions is Critical |
| DBT-05 | SA (High) vs SE, RT (Critical) | Severity of the CON-003 audit gap | F-SA-03, F-SE-10, F-RT-03 | SA conditioned Critical on "audit requires human attribution". The shared `svc-erp-admin` account destroys attribution, whatever the log sink is. | Critical | An unmet mandatory constraint with no decision behind it |
| DBT-06 | SE (OBO preferred) vs AG, IN (least-privilege identity + actor propagation) | ERP write identity mechanism | F-SE-01, F-AG-04, F-IN-02 | SE already lists the alternative. Feasibility depends on whether n8n/ERP accepts user tokens (ASM-005). | Accepted: OBO is preferred, with a recorded fallback | Decided in ADR-002 once ASM-005 is validated |
| DBT-07 | RT (evidence correction) | F-IN-05 cites ASM-003 for "no platform-engineering capability", but ASM-003 says only "no agent-framework experience" | round-2/red-team-architect.md §3 | IN's conclusion does not depend on it | Accepted | Recorded as ASM-006 (platform-engineering capacity unknown). Citation corrected in the review report. |
| DBT-08 | DK, IN, SE, RT | Pinecone under CON-001/CON-002 | F-DK-03 (Pinecone's Azure serverless region is eastus2 only `[VERIFIED]`, accessed 2026-10-27); F-RT-13 | Whether SaaS-on-Azure satisfies CON-001 is a policy question. It is moot, because the rejection stands on CON-002 and AP-06. | Accepted: reject | → ADR-004 |

## Board Questions

| # | Question | Answer (with IDs) |
|---|---|---|
| 1 | Which requirements does the proposal satisfy, and with what evidence? | FR-001 is partially satisfied and FR-005 is happy-path only. No requirement has an acceptance test (F-SA-04). |
| 2 | Which requirements are unmet, or met only on an unverified claim? | FR-003/FR-004 are unsafe (F-BRD-02/04). CON-002 is breached (F-BRD-01). CON-003 is unmet (F-BRD-03). NFR-A/B can't be measured (F-RE-03). |
| 3 | Why is the target better than simpler alternatives? | The target *is* the simpler alternative: rung 2 + 4/5 with no agent loop (ADR-001). Rung 0/1 alone can't answer free-text manual questions. |
| 4 | Does it duplicate an existing enterprise capability? | The baseline duplicates n8n ERP flows (F-AG-08, F-IN-02) and the APIM gateway (F-IN-03). The target reuses n8n (ADR-002) and APIM (ADR-006). That an enterprise APIM instance exists is `[ASSUMPTION Q-IN-01]` (round-3 overclaim correction). |
| 5 | What are the key trust boundaries and failure modes? | Untrusted content (manuals, ERP notes) → model; model → command service; command service → n8n/ERP. Failure modes include duplicate writes, injection-driven writes, and residency leaks. See `05-validation/threat-model.md`. |
| 6 | What happens when a model, tool, database, or integration is unavailable? | Degradation modes per F-RE-06: model-free escalation (FR-005), queued work-order drafts, read-only mode. Verified by TST-R3. **Not tested yet.** |
| 7 | How are consequential actions authorized and controlled, outside the model? | Command service policy plus a technician confirmation bound to the parameter hash, with a least-privilege identity (ADR-002). |
| 8 | Is it testable, observable, auditable, rollback-able, and supportable? | Designed (test plan, audit store, versioned agent unit). On-call ownership is open (Q-RE). |
| 9 | Which choices depend on assumptions or time-sensitive facts? | ADR-003 (regional model availability `[UNVERIFIED]` until the region is named). ADR-004 (AI Search in region). ADR-005 (Container Apps limits). ASM-005 (n8n keys). |
| 10 | What are the largest residual risks, and who accepts them? | Model availability in the mandated region (RSK-01). n8n idempotency support (RSK-02). Retrieval quality is unmeasured until EVAL-001 (RSK-03). CISO and sponsor (fictional). |
| 11 | What must be fixed before production? | All Mandatory items in the review report: F-BRD-01 through F-BRD-08. |
| 12 | What is centralized vs domain-owned, and why? | Centralized: APIM gateway (existing instance assumed, Q-IN-01) and identity. Domain-owned: conversation and command services, the search index, and the evaluation set. No new central AI platform is justified (§6). |

## Resolutions

| ID | Resolution | ADR |
|---|---|---|
| RES-01 | Rung 2 orchestration + rung 4 LLM steps + rung 5 RAG. No agent loop. Rung 6 trigger is evaluation-gated and read-only. | ADR-001 |
| RES-02 | The command service plus n8n is the only ERP write path. Idempotency, confirmation, audit, least-privilege/OBO identity. | ADR-002 |
| RES-03 | Regional in-region model deployments. Azure Policy deny on Global SKUs. | ADR-003 |
| RES-04 | Azure AI Search hybrid in-region; Pinecone rejected. | ADR-004 |
| RES-05 | Container Apps, with RT's conditions and IN's AKS triggers. | ADR-005 |
| RES-06 | APIM AI-gateway capability; the custom gateway is retired. | ADR-006 |

### Round 3 (red-team second pass)

Verdict: **Sound with conditions**. Accepted in full: new findings F-RT-20 to F-RT-28 became F-BRD-17 to F-BRD-21. All overclaims were corrected, including G3/G5/G6/G7, the APIM wording, the n8n boundary placement and the F-BRD-12 basis. Board-decision evidence gaps #1 (ADR-003 geography vs region) and #2 (Pinecone CON-002 basis) are recorded in ADR-003 and ADR-004.

## Unresolved Disagreements

None remain open between specialists. Open **stakeholder** decisions: Q-001 (confirmation), Q-IN-02 (does a data zone count as in-region), and CON-001 interpretation for third-party SaaS on Azure (moot for this design).

## Residual Risks

| ID | Risk | Owner (fictional) | Mitigation / trigger |
|---|---|---|---|
| RSK-01 | Required model not offered as a Regional deployment in the mandated region | Residency owner + CISO | Constraint-conflict decision. Do not route around it (ADR-003). |
| RSK-02 | n8n flows can't carry an idempotency key or actor | ERP/integration team | Fallback: key lookup in the command service (ADR-002), weaker. |
| RSK-03 | Retrieval/extraction quality unknown until EVAL-001/002 exist | Sponsor | Release gate (test plan) |
| RSK-04 | Container Apps limits (timeout, zone redundancy in region) unverified | Integration lead | ADR-005 conditions; re-open, don't move regions |

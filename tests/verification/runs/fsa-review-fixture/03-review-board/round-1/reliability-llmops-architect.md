<!-- Saved verbatim by the board chair. Brief: Reliability, latency, availability, ops readiness. Date: 2026-10-27. Round 1. -->

# Reliability, Performance & Operations Architect — fsa-review-fixture — Round 1

## Verdict

**Not viable as proposed.** The implemented config retries ERP create, update and delete calls without limit on timeout and 5xx, and none of those calls carries an idempotency key. In normal operation that will create duplicate work orders, and it can repeat deletes. LangGraph has no iteration limit (`max_iterations: null`), so the Supervisor→specialist→Reflection cycle is held back only by a 120 s timeout. Neither NFR-A ("fast") nor NFR-B ("99.5%", with no window or measurement point) can be measured. My latency estimates put the drafted chain at about 15–25 s p95 for one pass and 35–60 s when the Reflection agent sends an answer back once. Reflection on every answer also stops anything streaming to the user. My availability estimate for the serial chain is about 98.7–99.1%, below the 99.5% the sponsor mentioned. There are no circuit breakers, no fallback model and no degradation modes. Even R4 (escalate to a human) depends on the model chain working. "AKS is highly available" is not a DR plan. Evaluation is limited to "test with technicians during the pilot". There are no alerts, owners or runbooks, and no cost ceiling. All of this can be fixed within Azure (CON-001). The fixes are: deterministic loop and step bounds, idempotent writes through a single retry layer, fewer model calls on the critical path, defined degradation modes including model-free escalation, and a full SLO→alert→owner→runbook chain. None of the figures below were measured; nothing has been load-tested or DR-tested.

## Evidence Examined

- `use-cases/fsa-review-fixture/00-intake/use-case-brief.md` (all sections)
- `tests/fixtures/field-service-assistant/docs/architecture.md` §1–§5 and the flowchart (intended design)
- `tests/fixtures/field-service-assistant/config/agents.yaml` (what is actually implemented) `[VERIFIED]` by direct inspection:
  - `runtime.max_iterations: null`
  - `runtime.request_timeout_seconds: 120`
  - `work_order_agent.retry: {attempts: unlimited, on: [timeout, 5xx]}`
  - tools `erp_create/update/delete_work_order`
  - `llm.deployment_region: eastus`, `llm.model: gpt-class-large` (no version pinned)
  - `logging.capture_prompts/responses: true`, `retention_days: 730`
  - no checkpointer, circuit-breaker, fallback-model, rate-limit, token-cap or idempotency settings
- `standards/reliability-and-resilience.md` (RR-01…RR-11, §2–§9)
- `standards/observability-and-evaluation.md` (OE-01…OE-11, §2–§8)
- `docs/conventions.md` §5; `standards/architecture-principles.md` §3; severity rubric
- Not available: sequence diagrams, monitoring or incident data (there is no running system), provider quota figures, ERP/n8n API contracts. No research was done (none required). Provider SLAs, quotas and latencies are therefore `[UNVERIFIED]` or `[ASSUMPTION]`.

### Latency arithmetic (drafted chain, single turn) — every figure is an estimate, `[ASSUMPTION]`/`[JUDGMENT]`, not measured

The figures assume: GPT-class large model; output rate about 30–60 tok/s; mobile network; model in eastus (adds a cross-region round trip); custom gateway adds one hop per model call.

| # | Step (sequential) | Manuals path p95 est. | Work-order path p95 est. |
|---|---|---|---|
| 1 | Mobile network + API + auth | 0.5–0.8 s | 0.5–0.8 s |
| 2 | Supervisor routing LLM call (~1.5k in / ~50 out) + gateway hop | 1.0–2.0 s | 1.0–2.0 s |
| 3a | Query embedding + Pinecone query | 0.3–0.6 s | — |
| 3b | Specialist LLM answer (~5k in / ~300–400 out) | 6–12 s | — |
| 3c | WO agent: tool-plan LLM call + ERP REST call + confirmation LLM call | — | 3–9 s |
| 4 | Reflection LLM call (~6k in / ~200 out); the answer is held until it finishes, so streaming is lost | 3–8 s | 3–8 s |
| | **Single-pass total** | **≈ 11–23 s** | **≈ 8–20 s** |
| | + one Reflection rejection (repeat 3b + 4) | ≈ 20–43 s | ≈ 14–37 s |
| | Worst case as configured | Unbounded below the 120 s timeout | Unbounded, plus unlimited ERP retries |

The History path is similar to the Manuals path: SQL-generation LLM call 1–3 s, plus replica query 0.2–2 s, plus synthesis 4–8 s, plus Reflection.

For comparison, a reduced chain (one tool-calling agent, deterministic checks instead of always-on Reflection, streamed answer, in-region model) comes to: API 0.5 + LLM tool-select 1.5 + retrieval 0.5 + streamed-answer time-to-first-token (TTFT) 1.5 ≈ **4 s TTFT, about 10–12 s complete** `[JUDGMENT]`. That closes against the proposed ASM-P01 below.

### Availability composition (serial dependencies) — `[ASSUMPTION]` component figures, not vendor-verified

| Dependency | Assumed availability | Manuals path | Work-order path |
|---|---|---|---|
| API + AKS service (single cluster) | 99.9% | ✓ | ✓ |
| Custom AI gateway (new, in-house, no track record) | 99.5% `[JUDGMENT]` | ✓ | ✓ |
| Azure OpenAI deployment (single, eastus) | 99.9% `[UNVERIFIED]` | ✓ | ✓ |
| Entra ID / auth | 99.9% | ✓ | ✓ |
| Pinecone | 99.9% `[UNVERIFIED]` | ✓ | — |
| ERP REST API | 99.5% `[ASSUMPTION]` | — | ✓ |
| ERP read replica (History path) | 99.5% `[ASSUMPTION]` | (History) | — |
| **Composite** | | **0.999⁴ × 0.995 ≈ 99.1%** | **0.999³ × 0.995² ≈ 98.7%** |

The 99.5% target (NFR-B) does not close on either path. Three to five model calls per turn all go to the same single deployment, so a regional throttle or outage takes down every path together. If ERP is excluded from the SLO, the work-order path still has no headroom (≈ 99.2%). For scale: over a working-hours window of about 364 h/month (assumed 14 h × 26 days), 99.5% allows an error budget of only ≈ 1.8 h/month.

### Capacity (estimate) — `[ASSUMPTION]`

- **Volume:** 400 interactions/day, assumed to be about 3 turns each. With a peak hour at 20% of daily traffic and a 5× burst within the minute, that is about 7 turns/min at peak.
- **Tokens:** about 15–20k tokens per turn on a single pass, so roughly 100–150k tokens/min at peak, before any retries or loops.
- **Fit:** this is modest against typical deployment quotas `[UNVERIFIED]`. However, unbounded loops and unlimited retries make the real load open-ended, which is the retry-storm pattern.
- **Unknown:** whether "interaction" in the brief means a turn or a conversation.

### Cost per turn / interaction (formula only; no prices)

```
C_turn = k_retry × k_loop × Σ_i [ Tin_i·P_in(m_i) + Tout_i·P_out(m_i) ]     (i over Supervisor, specialist, tool-planning, Reflection calls)
         + T_query·P_embed + C_vector_query + C_tool_calls
C_interaction = n_turns × C_turn
C_fixed_per_interaction = [ C_AKS_nodes + C_gateway + C_Pinecone_min + (GB_logged × (P_ingest + P_retain × retention_months)) ] / interactions_per_month
C_total_per_interaction = C_interaction + C_fixed_per_interaction
```

- **Terms:** k_loop = 1 + expected Reflection rejections; k_retry = 1 + expected retries.
- **Logging volume:** GB_logged ≈ interactions × n_turns × n_calls × (prompt + response bytes). At the configured full-content capture and 730-day retention, this term can be material `[JUDGMENT]`.
- **As configured:** there is no ceiling, because k_loop and k_retry are unbounded. Assuming the 120 s timeout cancels the work, the practical worst case is about (120 s ÷ mean call duration) × tokens per call ≈ 10–20× the single-pass cost `[JUDGMENT]`. If the timeout does not cancel in-flight work, that bound does not hold.
- **Fixed costs dominate:** at about 10–12k interactions/month `[ASSUMPTION]`, fixed platform cost (AKS, gateway, Pinecone) per interaction probably outweighs token cost `[JUDGMENT]`. That makes the extra components a cost issue as well as a reliability issue.

## Findings

| ID | Severity | Affects | Evidence (path/source) | Basis | Issue | Impact | Remediation | Acceptance criterion | Verification |
|---|---|---|---|---|---|---|---|---|---|
| F-RE-01 | Critical | R2, R3, CON-003, OBJ-02 | `config/agents.yaml` `work_order_agent.retry: attempts: unlimited, on: [timeout, 5xx]`; tools include `erp_delete_work_order`; no idempotency config; architecture §4 calls ERP REST directly | Verified fact (config) + Inference | ERP create, update and delete are non-idempotent. They are retried without limit on timeout (an ambiguous outcome) and on 5xx, with no idempotency key, deduplication, backoff, jitter or retry budget. Agent re-planning (unbounded loop, F-RE-02) can repeat writes independently of the retry setting. There is no checkpoint after a side effect, so a crash after the write and before it is recorded repeats it on resume. | Duplicate work orders and misdispatch in normal operation (likelihood H, because any ERP slowdown above the client timeout triggers it). Repeated status changes or deletes. Retry storm against ERP during an ERP incident. The audit trail (CON-003) shows several writes for one intent. | (1) Remove automatic retries on writes at the agent layer. (2) Every write carries an idempotency key built from the business operation: `conversation_id + confirmed_proposal_id + action`. ERP or n8n (INV-001) deduplicates within a window of at least 24 h. (3) After an ambiguous timeout, look up state by key (pre-execution check) before taking any further action. (4) Make one layer the single retry owner (the n8n flow or the tool adapter), with at most 2 attempts, exponential backoff and jitter, and only once the key is honoured. (5) Checkpoint the key and result after every write (RR-11). (6) Remove the delete tool (Q-002). (7) Run a daily reconciliation of ERP work orders against agent records. | 0 duplicate work orders across fault-injected tests (ERP timeout, 5xx, process kill after the write). Every ERP write has exactly one idempotency key in the trace. | Fault-injection test suite in TST/EVAL; daily reconciliation report reviewed in pilot |
| F-RE-02 | High | R1–R4, NFR-A, cost | `agents.yaml` `max_iterations: null`, `request_timeout_seconds: 120`; architecture §4 "never create more than 3 work orders" lives only in the system prompt; Reflection reviews every answer | Verified fact (config) + Inference | There is no deterministic bound on graph iterations, model calls, tool calls, tokens or writes per turn. The only backstop is a 120 s timeout. It is unclear whether that timeout applies per request or per model call, and whether it cancels in-flight tool calls. The "max 3 work orders" limit is a prompt instruction, not a control. | Runaway Supervisor↔Reflection loops; repeated side effects (ERP writes, Teams posts); latency up to 120 s; unbounded token spend; quota exhaustion for all users. | Configure hard limits in the runtime and tool layer (`agentic-systems-architect` owns the values; proposed fit to budget): recursion limit ≤ 8 graph steps, ≤ 6 model calls per turn, ≤ 1 Reflection retry, ≤ 3 tool calls per turn, ≤ 1 write per technician confirmation, ≤ 3 writes per conversation enforced in the tool adapter, per-turn token cap ≈ 30k (ASM-P07). The request deadline propagates to every hop (RR-01) and cancels in-flight calls. A limit breach ends in a safe message plus escalation. | Adversarial EVAL cases that try to force loops or extra writes hit the limits and terminate within the deadline, with no extra writes. | Limit-exhaustion EVAL cases; trace shows `limits_consumed` on every run |
| F-RE-03 | High | NFR-A, NFR-B, G2 | architecture §2 NFR-A "Fast responses", NFR-B "Available during working hours… 99.5%"; §5 has no RTO/RPO; no quality NFR | Verified fact | NFR-A has no metric, percentile, target or measurement point. NFR-B has no defined window, measurement point, success definition or error budget. There are no RTO/RPO, quality, duplicate-action or cost targets. Latency and availability cannot be validated against these NFRs. | G2 cannot pass. Feasibility cannot be judged, and there is no basis for alerts or release gates. | Adopt candidates ASM-P01…P09 (Recommendations), or have the sponsor amend them. Record them in `01-requirements` with metric, percentile, target, measurement point and window. | Every NFR carries metric, percentile, target, measurement point and window, and is confirmed by the sponsor. | G2 review |
| F-RE-04 | High | NFR-A (as ASM-P01/P02), OBJ-02 | Latency table above; architecture §4 flow (Supervisor → specialist → Reflection, all through the gateway) | Inference (estimates `[JUDGMENT]`) | The drafted chain makes 3–5 sequential model calls per turn. Reflection on every answer blocks streaming. Estimated p95 is ≈ 11–23 s for one pass and ≈ 20–43 s with one rejection. The model sits in eastus, which adds a cross-region round trip. The 120 s timeout is far beyond any field-usable budget, and there is no deadline propagation. | Any measurable "fast" target is missed. Users abandon and call dispatch anyway (OBJ-01 at risk). Users who give up and retry multiply load. | Reduce critical-path model calls. Use deterministic intent routing (UI action or classifier) instead of the LLM Supervisor where possible, one tool-calling agent, and deterministic output checks (schema, citation presence) instead of always-on Reflection. If Reflection is kept, make it conditional. Stream answers. Run the model in-region (CON-002, DEC-001). Set the request deadline to 20 s for Q&A. Propose timeouts: model first token 5 s, model total 15 s, retrieval 1 s, SQL 3 s, ERP 8 s; each hop gets less than its caller. | Load test at peak plus headroom shows p95 TTFT ≤ 4 s and p95 complete ≤ 15 s (ASM-P01). | Load test; per-span p95 in traces |
| F-RE-05 | High | NFR-B | Availability table above; architecture §4 (single Azure OpenAI deployment, new custom gateway, Pinecone); `agents.yaml` single `deployment_region` | Inference (component figures `[ASSUMPTION]`) | A serial chain through the single-instance custom gateway, one model deployment, Pinecone and ERP composes to ≈ 98.7–99.1%. That is below 99.5%. The gateway and the single model deployment are each a single point of failure. There is no circuit breaker (RR-03). | The availability target is breached by arithmetic before any defects are counted. A provider throttle or outage takes down every path at once. | Remove or harden the gateway hop: use the managed Azure gateway option, not a new in-house service, as raised for the board below. If one is kept, run it zone-redundant with ≥ 2 replicas and probes. Add a second model deployment in another in-region-compliant zone or region, or a smaller approved fallback model that passes the same eval suite (OE-07). Put breakers on the model, retrieval, ERP and Teams calls. Exclude ERP-down time from the assistant's SLO only if the sponsor agrees (ASM-P03). | Recalculated composite ≥ 99.5% with fallbacks counted. Breaker and fallback engage in a game day. | Game day (RR-10) before go-live |
| F-RE-06 | High | R4, NFR-B, RR-05 | architecture §4: escalation goes Supervisor (LLM) → Escalation Agent (LLM) → Teams; no degradation modes anywhere; `agents.yaml` has no fallback config | Verified fact (absence) + Inference | No degradation modes are defined. Escalation to a human (R4) depends on the same model chain, so when the model or gateway is down a technician cannot even escalate. Users are not told when quality is degraded. | Total loss of service during any model, gateway or retrieval incident. The safety valve fails exactly when it is needed. | Define modes per RR §2: Normal; Model fallback; Reduced capability (retrieval down → History only, said explicitly; ERP down → work-order drafts queued to the human dispatcher); Deterministic (UI "Call/Message dispatch" button posting through n8n/Teams with no LLM); Read-only (all writes blocked on a quality or security alarm). Define triggers, user banner and exit conditions. | Each mode is triggered in a game day and visible to the user. Deterministic escalation works with the model endpoint disabled. | Game day; ASM-P05 measurement |
| F-RE-07 | High | NFR-B, RR-09/10/11, CON-002 | architecture §5 "DR: AKS is highly available"; `agents.yaml` has no checkpointer or state store; keys held in a gateway config map | Verified fact (claim) + Inference | Cluster high availability is not DR. There is no RTO/RPO for any component. Conversation and agent state is in memory, so it is lost on pod restart. There is no rebuild plan or timing for the Pinecone index. Prompts, model version and config are not shown as versioned or restorable. Any alternate region would also have to satisfy CON-002. Nothing has been tested. | A zone, cluster or index loss means an unplanned outage of unknown length. In-flight confirmations are lost or repeated (links to F-RE-01). | Set per-component RTO/RPO (ASM-P06). Run AKS multi-zone (T3). Persist graph state with a durable checkpointer in an in-region store. Keep prompts, config and model pin in Git and deploy them by pipeline. Document the index rebuild from source and its duration. Any secondary region must be in-region-compliant. Run a restore drill before go-live (T3). | Restore drill completes within RTO/RPO, with dated results recorded. | DR drill record (untested today) |
| F-RE-08 | High | G9, CON-003, OE-01/02/09 | architecture §4 "All prompts and responses are logged to Application Insights"; `agents.yaml` logging `capture_prompts/responses: true`, `retention_days: 730`; no tracing, metric, alert or runbook design | Verified fact + Inference | Observability amounts to raw content logging. Nothing defines end-to-end traces across Supervisor, agents, retrieval and tools, or correlation IDs linking a turn to the ERP work-order ID and confirmation (needed for CON-003). There are no agent, prompt or model versions on spans and no token, cost or latency metrics per step. No SLOs, burn-rate alerts, owners or runbooks exist. Logging full content to the general log store is a data-handling issue (raised for the board below). | Incidents cannot be attributed. Runaway loops and cost spikes go unseen. Audit linkage is weak. G9 cannot pass. | OpenTelemetry-style traces with one span per model, retrieval and tool call, carrying the attributes in OE §2. Correlation ID → ERP work-order ID → idempotency key → technician confirmation ID. Per-span tokens, cost, latency and finish reason. Content redacted by default; sampled content goes to an access-controlled in-region store with short retention. Alerts per OE §6.1, each with threshold, severity, owner and runbook: latency burn, model errors/429s, breaker open, loop-limit hits, duplicate-write detection, refusal spike, quality drop, spend anomaly, model deprecation notice. | Every SLO has a burn-rate alert, an on-call owner and a runbook. One trace reconstructs any ERP change. | G9 checklist; alert-fire test |
| F-RE-09 | High | R1–R3, G8, OE-05/07/08 | architecture §5 "Evaluation: we will test with the technicians during the pilot"; `model: gpt-class-large` with no version pin | Verified fact | No offline golden or adversarial set, no release thresholds, no regression on change, no online quality signals and no version pinning ("vibe evaluation"). There is nothing to base quality SLOs, canary rollback triggers or model-fallback qualification on. | Quality regressions and provider model changes go live unnoticed. A fallback model (F-RE-05) cannot be qualified. Releasing a tool that writes to ERP at T3 on this basis is not defensible. | (Pipeline owned by `ai-platform-architect`; SLOs here.) Build a golden set covering manuals Q&A, history SQL correctness and work-order field extraction, plus adversarial cases (injection, loop exhaustion, duplicate attempts) and a holdout. Pin the model version. Run CI regression on any prompt, model or tool change. Online: sampled groundedness, refusal rate, technician thumbs and edits, and rejection rate of proposed work orders. Canary with numeric rollback triggers. | Release gate with thresholds signed off by the sponsor (ASM-P08). Regression runs on every change. | G8 review; CI logs |
| F-RE-10 | Medium | RR-08, cost | brief (≈400 interactions/day); no quota, rate-limit or cost-ceiling config in `agents.yaml` | Inference / Assumption | There is no capacity model: peak turns, tokens per turn and concurrency are not mapped against TPM/RPM quotas. No per-user or global rate limits, no admission control, and no per-request, per-user or daily spend ceiling. Retries are not counted in the load. Volume is low, so the risk comes from amplification by F-RE-01/02 rather than baseline demand. | Quota exhaustion under loop or retry amplification hits every technician at once. Spend has no upper bound. | Build a capacity model using the arithmetic above; confirm quotas for the in-region deployment `[UNVERIFIED]`. Add per-user rate limits (e.g. ≤ 10 turns/min), a per-turn token cap, a daily spend budget alert at about 150% of baseline and a hard stop at about 300% (ASM-P07), and a global retry budget of ≤ 10% of requests. | Load test at 2× the estimated peak shows backpressure (429 to client with a message), not collapse. The spend alert fires in test. | Load test; budget alert test |
| F-RE-11 | Medium | G9, OE-10 | architecture §4 and `agents.yaml`: no prompt or model versioning, feature flags, rollout or rollback design; no load test planned | Inference | Production-readiness gaps: no one-step rollback of prompt, model and config as one unit; no feature flag to disable writes (needed for Read-only mode); no load test; no support or on-call model for working hours. | A slow, error-prone recovery from a bad release. | Version the agent unit (prompts, tools, model pin, limits). Feature flags per tool (writes off without a redeploy). Canary to a pilot crew with rollback triggers. Load test before go-live. Named on-call for the working-hours window. | Rollback in a single operation shown in staging. Write kill-switch tested. | Readiness review |

## Recommendations

- **Side-effect safety (R2, R3, CON-003, INV-001):**
  - *Recommended:* send ERP writes through the existing production n8n create/update flows. One retry owner, idempotency key from the business operation, ERP/n8n deduplication, pre-execution check after an ambiguous timeout, checkpoint after the write, daily reconciliation. Writes only after the technician's explicit confirmation (Q-001 ASM).
  - *Rejected:* unlimited agent-layer retries on direct ERP REST calls.
- **Call chain and latency (NFR-A → ASM-P01/P02):**
  - *Recommended:* deterministic routing plus one tool-calling agent, streamed answers, deterministic output checks, at most 1 conditional Reflection or repair pass, in-region model.
  - *Alternative:* keep the Supervisor but use a small or fast model for routing only, and drop always-on Reflection.
  - *Rejected:* always-on Reflection in front of every answer.
- **Availability (NFR-B → ASM-P03):**
  - *Recommended:* drop the new in-house gateway hop in favour of a managed in-Azure gateway capability. Add a second in-region-compliant model deployment or a qualified fallback model. Circuit breakers on every external dependency. Model-free deterministic escalation.
- **Bounds and timeouts (F-RE-02):**
  - *Recommended:* the limits and per-hop timeouts listed in F-RE-02 and F-RE-04, with deadline propagation and cancellation. Model 429s honour retry-after with at most 2 attempts within the remaining deadline. Model 5xx: 1 retry with jitter, then breaker or fallback. Truncated output (finish reason = length) or schema-invalid output gets 1 repair attempt, then fallback.
- **Proposed NFR candidates.** All are `[ASSUMPTION]` until the sponsor confirms them; the coordinator should assign final ASM IDs:
  - **ASM-P01 (latency, Q&A):** p95 TTFT ≤ 4 s and p95 full answer ≤ 15 s, measured server-side at the API edge, 28-day rolling, working-hours window only.
  - **ASM-P02 (latency, work orders):** p95 ≤ 10 s from request to the draft work order being shown for confirmation. p95 ≤ 5 s from confirmation to ERP acknowledgement, excluding declared ERP incidents. Supports OBJ-02 (median < 2 min end-to-end).
  - **ASM-P03 (availability):** ≥ 99.5% of valid turns return a full or *declared-degraded* response without error or timeout. Measured at the API edge, Mon–Sat 06:00–20:00 local (window to be confirmed), 28-day rolling. Error budget ≈ 1.8 h/month for a 364 h window. ERP-originated failures to be counted or excluded by sponsor decision.
  - **ASM-P04 (duplicates):** 0 duplicate ERP work-order writes attributable to retries or re-planning. 100% of ERP writes traceable to correlation ID, technician, confirmation ID and idempotency key (CON-003).
  - **ASM-P05 (escalation):** deterministic escalation path ≥ 99.9% available during the window, independent of the model endpoint.
  - **ASM-P06 (RTO/RPO):**
    - Assistant service: RTO ≤ 4 working hours.
    - Conversation and checkpoint state: RPO ≤ 15 min.
    - Prompts, config and model pin: RPO 0 (Git).
    - Manuals index: RTO ≤ 24 h, rebuilt from source, with Reduced-capability mode in the meantime.
  - **ASM-P07 (cost and bounds):**
    - Per turn: ≤ 30k tokens, ≤ 6 model calls, ≤ 1 write per confirmation.
    - Per user: ≤ 10 turns/min.
    - Daily spend: alert at 150% and hard stop at 300% of the agreed baseline (budget owner sets the baseline).
  - **ASM-P08 (quality):** release gates on the golden set for groundedness, citation correctness, SQL-result correctness and work-order field accuracy, with thresholds set by the sponsor. Online: sampled groundedness, refusal rate and draft-rejection rate, each alerting on drift from baseline.
  - **ASM-P09 (observability):** 100% of turns traced end-to-end with agent, prompt and model version. Content capture redacted by default; sampled content in a secure in-region store with short retention.

## Positions for the Board

- **`security-identity-architect` / `data-knowledge-memory-architect`:** the model in `eastus` and full prompt/response capture at 730-day retention look like CON-002 and data-handling problems. I expect them to rate these Critical/High, and I defer on severity. My concern is the reliability side: an in-region model deployment and in-region quota must exist before ASM-P01/P03 can be validated, and any DR region must also be compliant. Evidence that would change my position: confirmed in-region capacity and quota for the chosen model.
- **`agentic-systems-architect`:** I expect them to own the bound values and the multi-agent versus single-agent decision. My position is that the drafted multi-agent chain with always-on Reflection cannot fit a usable latency budget (F-RE-04). Evidence that would change my position: a measured benefit of Reflection on the eval set that outweighs about 3–8 s per turn, or measured p95 within ASM-P01.
- **`integration-infrastructure-architect`:** I expect them to rule on the new in-house gateway, Pinecone, and n8n reuse. From a reliability standpoint, each extra serial service costs availability and adds fixed cost per interaction. I favour reusing n8n for writes (one retry owner) and a managed in-Azure gateway. Evidence that would change my position: n8n flows that cannot accept an idempotency key or deduplicate.
- **`ai-platform-architect`:** they own the eval pipeline (F-RE-09). I own the quality SLOs and alerts built on it, and the requirement that any fallback model passes the same suite.
- **Severity of F-RE-01:** I rate it Critical, not High. The rubric explicitly lists non-idempotent retries that cause duplicated consequential side effects as Critical, and the deletes make it worse. Evidence that would change my position: proof that the ERP API already enforces idempotency on these endpoints.

## Assumptions and Open Questions

- Every latency, availability, token and capacity figure above is an `[ASSUMPTION]`/`[JUDGMENT]` estimate. None was measured.
- "Interaction" is assumed to mean a conversation of about 3 turns; peak hour about 20% of daily traffic. *Question for the sponsor:* is "interaction" a turn or a conversation, and what does the shift pattern look like?
- What exactly is the "working hours" window, including time zones and weekends? This sets the error budget.
- Should ERP outages count against the assistant's SLO?
- Is `request_timeout_seconds: 120` a request deadline or a per-model-call timeout, and does it cancel in-flight tool calls?
- Do the ERP REST API and the n8n flows support idempotency keys or a natural-key lookup?
- Q-001 is assumed (the technician confirms before any write). If writes happen without confirmation, F-RE-01 and F-RE-02 get worse.
- Who is the on-call owner during working hours: the AKS platform team, the use-case team, or dispatch IT?

## Not Verified

- Azure OpenAI and Pinecone SLAs, TPM/RPM quotas, regional availability and latency are `[UNVERIFIED]` (no research this round). Verify them against current vendor documentation for the in-region deployment before fixing ASM-P01/P03.
- Actual model latency and token counts: run a benchmark on the chosen in-region deployment with representative prompts.
- ERP REST and n8n timeout, idempotency and error behaviour: check the API contracts with the ERP/integration team.
- Whether LangGraph's runtime in this prototype has any default recursion limit despite `null`: check the code. Only the config file was available.
- **Not tested:** no load test, no fault injection, no DR or restore drill, and no fallback has been exercised. All of these remain open residual risks until results are recorded with dates.


---
name: nfr-validation
description: Turn NFRs into measurable engineering constraints with verification plans. Rewrites vague targets ("fast", "highly available") as measurable candidates, builds latency, availability, and cost-per-request worksheets, detects NFR conflicts, and gives each NFR a feasibility verdict. Use for "validate the NFRs", "is this latency achievable", "SLO", "availability target", "RTO/RPO", "cost ceiling", "NFR conflicts", or the G2/G8 gates.
argument-hint: "<use-case-id> [NFR IDs or category to focus on]"
---

# NFR Validation

## Purpose

Make every non-functional requirement **measurable, testable, owned, and feasible** under the design and its constraints. The outputs are `05-validation/nfr-validation.md` and an updated NFR table in `01-requirements/requirements.md`. This skill does estimation and planning. **Only executed tests prove an NFR.** Arithmetic in this skill is a hypothesis to be checked by load, resilience, and evaluation tests. Reliability, observability, and evaluation principles live in `standards/reliability-and-resilience.md` and `standards/observability-and-evaluation.md`. Reference them; don't restate them.

## When to use / not use

| Use when | Don't use when |
|---|---|
| Requirements exist and the design is taking shape (Phase C), or before G2/G8 | There are no NFRs or design yet. Run `use-case-discovery` first. |
| A stakeholder gives a vague target ("must be fast", "always on", "cheap") | You need to choose a technology. Use `technology-evaluation`, and feed its results back here. |
| A design change affects latency, availability, or cost (new agent step, new region, new model) | You need observed production performance. That needs telemetry, not this skill. |
| Mode B: checking whether the existing system can meet stated SLOs | |

## Inputs

| Input | Path |
|---|---|
| Intake: CON/PRH, tier, users, volumes | `00-intake/use-case-brief.md` |
| Requirements: NFR table, FRs, ASMs | `01-requirements/requirements.md` |
| Design: components, call paths, deployment, model choices | `02-design/solution-design.md` |
| Sequence and agent-flow diagrams | `02-design/diagrams/` or embedded |
| ADRs on models, hosting, regions | `04-decisions/adr/` |
| Technology knowledge (dated) | `knowledge/technology-catalog.md`, `knowledge/model-selection-guide.md`, `knowledge/deployment-patterns.md` |

## Workflow

### Step 1. Set depth by tier

| Tier | Depth | Specialist |
|---|---|---|
| T1 | Make the NFR table measurable. One latency and one cost estimate. Conflicts listed. ◐ G2. | None |
| T2 | All categories below. Latency, availability, and cost worksheets. Feasibility verdicts. | Brief `reliability-llmops-architect` |
| T3 | T2 plus per-journey latency budgets, capacity model at peak, RTO/RPO with DR test, AI quality targets tied to `EVAL-` sets. | `reliability-llmops-architect`. Add `security-identity-architect` for security/privacy NFRs and `data-knowledge-memory-architect` for residency or retention. |
| T4 | T3 plus failure-mode-by-dependency analysis, degraded-mode targets, and independent challenge of the feasibility verdicts. | As T3, plus `red-team-architect` on the "Feasible" claims |

### Step 2. Inventory and normalize

For each existing NFR, and for each category below that has none, create or complete a row. Categories to cover: **availability/reliability; latency/throughput; scalability/capacity; security/privacy; RTO/RPO; maintainability/supportability; cost ceilings; AI output quality/evaluation; auditability/compliance; accessibility/usability** (where a human UI exists). If a category doesn't apply, write "N/A because …" (AP-13).

Each NFR needs every field below. A missing field means the NFR is not yet measurable.

| Field | Rule |
|---|---|
| Metric | A countable quantity, such as "time from request accepted at gateway to final token delivered" |
| Target | A number with units |
| Percentile / statistic | p50/p95/p99, monthly average, or per-release, as relevant. Averages alone aren't acceptable for latency. |
| Measurement point | Exact start and end instrumentation points (component `C-` IDs) |
| Load conditions | Concurrency, request mix, input size, data volume, time window |
| Measurement method | Load test, synthetic probe, offline evaluation, audit, or cost meter |
| Test | A `TST-` or `EVAL-` ID |
| Owner | A role accountable for the target |
| Source | Who or what set the target: a stakeholder, contract, regulation, or benchmark. If none, write "ASM-xxx". |

### Step 3. Rewrite vague NFRs

Turn each vague statement into a **measurable candidate**, mark it `[ASSUMPTION]` with a new `ASM-` (impact, confidence, validation method, owner), and add a `Q-` for the stakeholder to confirm.

| Vague | Measurable candidate (example only; confirm with the owner) |
|---|---|
| "Fast" | Interactive: time to first token ≤ X s at p95, and full response ≤ Y s at p95, at N concurrent users, gateway ingress → client stream |
| "Highly available" | Monthly availability ≥ Z% for the core journey, measured by a synthetic probe from the user network, with planned maintenance excluded or included (state which) |
| "Scalable" | Sustains N requests/min at peak for M minutes with p95 within target and error rate < E% |
| "Accurate" | Task metric ≥ T on `EVAL-xxx` vN (definition, dataset, judge method stated) |
| "Secure" | Map to specific controls and threat tests (`threat-modeling`), e.g. 0 cross-tenant retrievals in TST-xxx |
| "Cheap" | Cost per successful request ≤ $C at monthly average, including model, retrieval, and infrastructure |
| "Auditable" | 100% of side-effecting actions reconstructable (actor, inputs, approval, outcome) within R minutes; retention ≥ D days |

Don't invent targets and present them as requirements. The candidate stays an ASM until the owner confirms it.

### Step 4. Latency budget worksheet

Decompose the end-to-end target along the critical path, using the sequence and agent-flow diagrams. **This is estimation. It must be validated by a load test (`TST-`).** Percentiles don't add exactly: summing per-stage p95s gives a conservative upper bound, not the true p95. Use it to find infeasibility early, not to prove feasibility.

| Stage | Component | Calls on critical path | Est. p95 per call | Subtotal | Basis (label + source/date) |
|---|---|---|---|---|---|
| Client → gateway, authn | C-.. | 1 | | | |
| Policy / guardrail (input) | C-.. | 1 | | | |
| Retrieval (embed + search + rerank) | C-.. | 1 | | | |
| Model call: planning / step 1 | C-.. | 1 | | | |
| Tool call(s) | C-.. | k | | | |
| Model call: steps 2..n | C-.. | n−1 | | | |
| Guardrail (output) / post-processing | C-.. | 1 | | | |
| Network and serialization overhead | — | — | | | |
| **Total (conservative)** | | | | **Σ** | vs target NFR-… |

Rules:
- **Sequential agent steps multiply.** An agent loop with n sequential model calls costs about n × (model latency + tool latency). Use the **loop bound** from the agent design, not the typical case, for worst-case analysis. Report both typical and bounded totals.
- Model latency depends on output tokens. Estimate as time to first token + (output tokens ÷ output token rate). Use dated vendor or measured figures (`[VENDOR]` or `[VERIFIED]`).
- Parallel branches contribute their slowest branch, not the sum.
- If the conservative total exceeds the target, the options are to parallelize, reduce steps, use a smaller or faster model for some steps, cache, stream, or relax the target. Record this as a conflict (Step 7).

### Step 5. Availability composition worksheet

| Dependency on critical path | Component / provider | Availability (claimed or measured) | Basis | Redundancy? |
|---|---|---|---|---|
| Gateway | | | | |
| Orchestrator | | | | |
| Model endpoint | | | `[VENDOR]` SLA, accessed YYYY-MM-DD | |
| Retrieval store | | | | |
| Each required tool or business system | | | | |
| Identity provider | | | | |
| **Composite (serial)** | | **A₁ × A₂ × … × Aₙ** | | |

Rules:
- **Serial dependencies multiply.** Five dependencies at 99.9% each compose to about 99.5%. The composite can't exceed the weakest serial link.
- Redundant (parallel, independent) paths: 1 − Π(1 − Aᵢ). This holds only if the failures are truly independent (separate region, provider, or quota). State the assumption.
- A vendor SLA is a credit commitment, not a measured availability. Label it `[VENDOR]`.
- Define degraded modes (for example, retrieval down → answer with a "no sources" refusal; model down → queue or fall back to a manual path) and say whether the availability NFR counts degraded mode as "up".
- RTO/RPO: state per data store and per stateful component, with the recovery mechanism and a `TST-` for the DR test (T3+ must be tested or scheduled before go-live, per G9).

### Step 6. Cost-per-request model

**Prices are time-sensitive.** Research current pricing, cite `(source: URL, accessed YYYY-MM-DD)`, and label it `[VENDOR]`. If research is unavailable, mark it `[UNVERIFIED]`.

| Element | Formula | Inputs (with source and date) | Per request |
|---|---|---|---|
| Model calls | Σ over calls: (input tokens × input price + output tokens × output price) | Tokens per call, calls per request (loop bound for worst case), price per token | |
| Embeddings / reranking | queries × tokens × price | | |
| Guardrail / judge calls | calls × tokens × price | | |
| Tool / API fees | calls × unit price | | |
| Infrastructure (amortized) | monthly fixed cost ÷ monthly requests | Compute, vector store, gateway, observability | |
| Retries and failures overhead | × (1 + retry rate) | | |
| **Cost per successful request** | | | **$** |
| **Monthly cost** | per request × volume (from ASM / intake) | | **$** |

Show typical and worst-case (loop bound, maximum context) figures. Note the effect of caching or batching only if the design actually uses them. Compare against the cost ceiling NFR, and against a lower-rung alternative where one is plausible (AP-03).

### Step 7. Detect NFR conflicts

Look for these pairs explicitly, plus any specific to the use case:

| Conflict | Typical resolution options |
|---|---|
| Latency vs multi-step agent quality | Fewer steps, parallel tools, a smaller model for routing, async UX, relax the latency target for complex requests |
| Data residency vs model availability | In-region model with a quality trade-off, a self-hosted model, a residency exception (needs a CON owner decision) |
| Cost vs redundancy / availability | Active-passive instead of active-active, an accepted lower target, a degraded mode instead of full redundancy |
| Auditability vs data minimization | Log references and hashes instead of payloads, tiered retention, redaction with secured raw-log escrow |
| Quality vs cost | Model routing or cascades, task-specific smaller models, caching |
| Security controls vs latency | Async scanning, risk-based guardrails, inline only on high-risk paths |
| Availability vs consistency for side effects | Idempotency plus a queue, accepted delay |

For each conflict: the NFR IDs, the options (with consequences), the recommended option, the decision **owner** (a role), and the status. Write each into the requirements **NFR conflicts** table. A conflict with a CON or PRH follows `standards/architecture-principles.md` §6. Material resolutions become ADRs (`adr-management`).

### Step 8. Feasibility verdict per NFR

| Verdict | Meaning | Required action |
|---|---|---|
| **Feasible** | The worksheet and evidence show comfortable margin | Keep the test planned |
| **Feasible with conditions** | Achievable only if the stated conditions hold (a design change, quota, or assumption) | List the conditions with owners; link the ASMs |
| **At risk** | Little or no margin, or it relies on low-confidence evidence | Spike, prototype, or early load test; flag it on the roadmap |
| **Infeasible under constraints** | It can't be met given the CON/PRH or the chosen design | **Stop and issue an explicit decision request:** relax the NFR, relax the constraint, or accept the risk, with consequences and the decision owner. Don't proceed as if it were feasible. |

### Step 9. Specialist review (T2+)

Brief `reliability-llmops-architect` (per `docs/operating-model.md` §4) with paths to the requirements, the design, and the draft `nfr-validation.md`. Ask it to challenge the worksheet assumptions, the degraded modes, the SLO-to-alert chain, and the verdicts. Save the report verbatim under `03-review-board/round-<n>/`.

### Step 10. Write back

- Update the **Non-Functional Requirements** table in `01-requirements/requirements.md`: complete every field, set Test IDs, and set Status (Proposed / Confirmed / At risk / Infeasible). Update the **NFR conflicts** table and add new `ASM-`, `Q-`, and `RSK-` rows. Keep IDs stable (`docs/conventions.md` §2).
- Register each `TST-`/`EVAL-` in `05-validation/test-and-evaluation-plan.md` (Performance and Load; Resilience and DR; AI Evaluation) when that plan exists (T3+). For T2, list them in `nfr-validation.md`.

## Outputs

| Artifact | Path |
|---|---|
| NFR validation report | `use-cases/<id>/05-validation/nfr-validation.md`, with sections: Summary of verdicts · NFR register (all fields) · Rewritten NFRs (pending confirmation) · Latency budget · Availability composition · RTO/RPO · Cost model · Conflicts · Decision requests · Verification plan |
| Updated requirements | `use-cases/<id>/01-requirements/requirements.md` (NFR table, NFR conflicts, ASM, Q, RSK) |
| Test registrations | `use-cases/<id>/05-validation/test-and-evaluation-plan.md` (T3+) |
| Specialist report | `use-cases/<id>/03-review-board/round-<n>/reliability-llmops-architect.md` |

## Quality gates touched

- **G2 Requirements & NFR traceability.** Primary: NFRs measurable, conflicts identified.
- **G3 Pattern & technology selection.** An infeasible verdict under a CON blocks G3 until decided.
- **G8 Test & evaluation readiness.** Every NFR has a verification method.
- **G9 Operational readiness.** SLOs feed alerts and runbooks (`implementation-roadmap`).

## Failure conditions

- An NFR lacks a metric, target, measurement point, test, owner, or source. G2 is not PASS.
- A vague target is recorded as confirmed without owner confirmation.
- A latency or availability worksheet is presented as proof rather than estimation.
- Prices or SLAs are cited without a source and date.
- An "Infeasible under constraints" verdict proceeds without a recorded decision.
- A conflict lacks an owner.
- An agent loop's latency or cost is estimated on the typical case only, without the loop bound.

## References

- `standards/reliability-and-resilience.md`, `standards/observability-and-evaluation.md`, `standards/security-and-identity.md`, `standards/data-governance.md`
- `standards/architecture-principles.md` §2 (ASM), §3 (evidence), §6 (constraint conflicts); `standards/architecture-quality-gates.md` (G2, G8, G9)
- `templates/requirements.md`, `templates/test-and-evaluation-plan.md`
- `knowledge/model-selection-guide.md`, `knowledge/deployment-patterns.md`, `knowledge/technology-catalog.md`
- `.claude/agents/reliability-llmops-architect.md`
- Related skills: `threat-modeling` (security NFRs), `adr-management` (conflict resolutions), `implementation-roadmap` (SLO → alert → runbook)

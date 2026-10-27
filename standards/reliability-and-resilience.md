# Reliability and Resilience

**Layer A: stable principles.** This file changes only by explicit framework decision (see `docs/extending-the-framework.md`). It defines how AI systems stay correct and available when dependencies fail, load spikes, or work runs for a long time. It supplies the substance for gate G9 (operational readiness) in `standards/architecture-quality-gates.md`. Core principles and evidence labels are in `standards/architecture-principles.md`; agent execution limits are in `standards/agentic-ai-design-principles.md` §3; monitoring and rollback are in `standards/observability-and-evaluation.md` (OE).

---

## 1. Principles

| ID | Principle | In practice | Typical violation |
|---|---|---|---|
| RR-01 | **Timeouts on every remote call, with budget propagation** | Every model, retrieval, tool, and downstream call has a timeout. The request carries a deadline, and each hop uses the remaining budget, so inner calls never outlive the caller. Streaming calls have both first-token and total timeouts. | Default client timeouts of several minutes on a model call behind a 30-second user request. |
| RR-02 | **Bounded retries with exponential backoff and jitter, only for safe operations** | Retry only idempotent or safe operations, a bounded number of times, with exponential backoff and jitter. Honor provider retry-after signals. Retry budgets prevent retry storms across layers. | Retrying a non-idempotent "send payment" call on timeout. |
| RR-03 | **Circuit breakers** | Calls to each dependency go through a breaker that opens on sustained failure and moves to a fallback (RR-05), then probes before closing. | Hammering a failing model endpoint and exhausting the quota for everyone. |
| RR-04 | **Idempotent side effects** | Every side-effecting tool takes an idempotency key derived from the business operation, not the attempt. Use an outbox or deduplication for events. Agents that re-plan can repeat actions, so the tool layer must deduplicate regardless of what the model intends. | An agent that re-plans after a timeout and issues the same refund twice. |
| RR-05 | **Graceful degradation and fallback paths** | Define degradation modes in advance (§2): model fallback, cached answers, deterministic fallback, and a human queue. Users are told when they are in a degraded mode. | The whole service failing when one model provider rate-limits. |
| RR-06 | **Dependency failure handling** | Design for model-provider outages, rate limits, quota exhaustion, model deprecations, slow responses, and malformed outputs (§3). | Assuming the provider's availability equals the system's availability. |
| RR-07 | **Measurable availability and recovery targets** | SLOs (availability, latency, and where meaningful quality) with error budgets, and RTO/RPO per component, derived from business impact and traced to NFRs. | "High availability" with no number. |
| RR-08 | **Capacity planning and backpressure** | Model throughput limits (requests and tokens per minute), concurrency caps, queues, and rate limiting per user/tenant. For self-hosted models, plan GPU capacity, scaling lead time, and cold starts. Shed load deliberately rather than failing randomly. | Launch traffic exceeding the token-per-minute quota on day one. |
| RR-09 | **DR proportional to business impact** | DR design (backup, multi-zone, multi-region, alternate provider) is sized to RTO/RPO and tier, including indexes, memories, prompts, policies, and agent state, not just databases. | Multi-region active-active for an internal T1 assistant; or no index rebuild plan for a T4 service. |
| RR-10 | **Test recovery, don't just document it** | Game days, fault injection, and DR drills verify fallbacks, breakers, and restores. Record observed results and dates. | A DR runbook that has never been executed. |
| RR-11 | **Durable long-running agent workflows** | Long-running work uses durable execution: persisted state, checkpoints after each side effect, resumability after crashes, timeouts per stage, and compensation (saga) for multi-step side effects (AG-13). | A multi-hour agent task held only in process memory. |

## 2. Degradation modes (RR-05)

Define which modes apply per use case, their triggers, and how users are informed.

| Mode | Trigger (example) | Behavior | Quality / risk impact | Exit |
|---|---|---|---|---|
| Normal | — | Primary model, full retrieval, all tools | Baseline | — |
| Model fallback | Primary model breaker open, rate-limited, or slow | Route to an alternate model or deployment that has passed the same evaluation suite (OE-07) | Possibly lower quality; must stay within release gates | Breaker closes |
| Reduced capability | Tool or retrieval dependency down | Disable affected tools; answer only from available sources, and say so | Partial answers | Dependency recovers |
| Cached answers | Generation unavailable; question matches governed cache (DG-13) | Serve cached, scoped answers with their age shown | Staleness risk | Generation recovers |
| Deterministic fallback | AI path unavailable or untrusted | Rules, templates, search results, or forms (lower solution-ladder rungs) | Less flexible, predictable | AI path recovers |
| Human queue | Consequential work, or no safe automated path | Queue the case with its state for human handling (AG-09) | Slower; capacity-limited | Backlog cleared |
| Read-only / suspended | Security incident, policy breach, or quality alarm | Block all side-effecting tools; optionally suspend the agent version | Service reduced | Owner approval to resume |

## 3. AI dependency failures (RR-06)

| Failure | Detection | Response |
|---|---|---|
| Provider outage or high error rate | Error-rate and breaker metrics | Breaker opens; model fallback or deterministic fallback |
| Rate limiting (requests or tokens per minute) | Throttling responses, retry-after signals | Backoff with jitter; queue; shed low-priority traffic; request quota increases ahead of launch |
| Quota or budget exhaustion | Spend and quota tracking | Prioritize critical traffic; alert the owner; degrade per §2 |
| Latency degradation | p95/p99 per model span | Tighter timeouts; route to a faster model where acceptable |
| Malformed or invalid output | Schema validation (AG-07) | One bounded repair or retry, then fallback or escalate |
| Model version change or deprecation | Version in traces; provider lifecycle notices (verify current status) | Pin versions; re-run evaluation (OE-07) before migrating; plan before the retirement date |
| Retrieval index unavailable or stale | Health checks, freshness metrics (DG-07) | Reduced-capability mode; rebuild from source per RR-09 |
| Self-hosted capacity loss | GPU node health, queue depth | Scale out within lead time; fallback to an approved alternate; shed load |

## 4. Targets and capacity

- **SLOs.** Define availability and latency SLOs at the user boundary, plus a quality SLO where it is measurable (OE-03). Set error budgets and the action taken when they are spent (for example, freeze feature releases).
- **RTO / RPO.** Set per component. Include the time to rebuild indexes and embeddings from source, to restore memories and agent state, and to redeploy versioned prompts and policies.
- **Capacity model.** Peak requests, tokens per request, tool calls per run, and concurrency, mapped against provider quotas and self-hosted capacity, with headroom. Label estimates `[ASSUMPTION]` until load-tested.
- **Backpressure.** Admission control at the edge, per-tenant and per-user rate limits, bounded queues with timeouts, and priority classes, so that overload degrades low-priority work first.

## 5. Long-running agent workflows (RR-11)

- [ ] Workflow state persisted outside the process, versioned with the agent definition (AG-17)
- [ ] Checkpoint after every side effect, recording the idempotency key and result (RR-04)
- [ ] Resumable after a crash or deploy, without repeating completed side effects
- [ ] Per-stage timeouts and an overall deadline; stuck runs are detected and escalated
- [ ] Compensating action defined for each reversible side effect (saga); irreversible steps gated by approval (AG-08)
- [ ] Human-wait states persist across restarts, with expiry and reminders
- [ ] In-flight runs have a defined behavior when a new agent version deploys (drain, pin to old version, or migrate)

## 6. Side-effect safety patterns (RR-04)

| Pattern | Use when | What it prevents | Notes |
|---|---|---|---|
| Idempotency key | Any side-effecting tool or API call | Duplicate effects from retries or agent re-planning | Key derived from the business operation (e.g. case ID + action + target), stored by the receiver with its result |
| Transactional outbox | A state change must publish an event reliably | Lost or phantom events when a process crashes between write and publish | Event written in the same transaction as the state change, then relayed |
| Consumer deduplication | At-least-once delivery from queues or webhooks | Double processing | Track processed message IDs for at least the redelivery window |
| Pre-execution check | The agent proposes an action that may already be done | Repeat actions after context loss | Tool queries current state before acting; returns "already done" as a normal result |
| Reconciliation | Systems of record can drift from agent state | Silent divergence | Scheduled comparison with alerts and a repair path |
| Compensation (saga) | Multi-step side effects across systems | Half-completed business operations | Each step has a defined undo or follow-up; irreversible steps go last, behind approval |

## 7. Recovery testing (RR-10)

- [ ] Fault injection for each dependency in §3: outage, throttling, slow response, malformed output
- [ ] Breaker opens and closes as designed; fallback modes in §2 engage and are visible to users
- [ ] Agent crash mid-run resumes without repeating side effects (§5)
- [ ] Restore of indexes, memories, prompts, policies, and agent state within RTO/RPO
- [ ] Load test at expected peak plus headroom, confirming backpressure rather than collapse
- [ ] Results recorded with date, observed outcome, and follow-up actions; untested items stay visible as residual risk

## 8. Anti-patterns

- **Retry everything:** blanket retries on non-idempotent writes, or retries at every layer multiplying load.
- **Provider SLA as system SLA:** no fallback because "the vendor promises high availability".
- **Unlimited fan-out:** agents or orchestrators launching parallel calls with no concurrency cap.
- **Documented-only DR:** runbooks that have never been executed.
- **In-memory long-running work:** multi-step agent tasks that vanish on restart.
- **Silent degradation:** users receive lower-quality answers with no indication that a fallback is active.

## 9. Tier scaling

| Concern | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Timeouts / retries (RR-01, RR-02) | Timeouts on remote calls | + bounded retries, idempotent-only | + deadline propagation, retry budgets | Same, verified by fault injection |
| Breakers (RR-03) | Optional | On model provider calls | On every external dependency | + tested in game days |
| Idempotency (RR-04) | N/A if read-only | Keys on any write | Keys + dedup on all side effects | + reconciliation jobs and audit |
| Degradation (RR-05) | Error message | One fallback mode | Modes in §2 defined and tested | + automatic mode switching and user notice |
| Targets (RR-07) | Best effort | SLO defined | SLO + error budget + RTO/RPO | + contractual or regulatory targets met |
| Capacity (RR-08) | Quota check | Capacity estimate + rate limits | Load-tested, backpressure | + priority classes, reserved capacity |
| DR (RR-09) | Rebuild from source | Backups + documented restore | Multi-zone; restore drill before go-live | Per RTO/RPO, possibly multi-region or alternate provider |
| Recovery testing (RR-10) | — | Restore tested once | Game day before go-live | Scheduled drills and chaos testing |
| Long-running (RR-11) | N/A | Checkpoints if > one request | Durable execution | + compensation verified in tests |

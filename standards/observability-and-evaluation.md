# Observability and Evaluation

**Layer A: stable principles.** This file changes only by explicit framework decision (see `docs/extending-the-framework.md`). It defines how AI systems are traced, measured, evaluated before release, and monitored in production. It supplies the substance for gates G8 (test and evaluation readiness) and G9 (operational readiness) in `standards/architecture-quality-gates.md`. Core principles and evidence labels are in `standards/architecture-principles.md`; data-handling rules for captured prompts and outputs are in `standards/data-governance.md` (DG); agent versioning is AG-17 in `standards/agentic-ai-design-principles.md`.

---

## 1. Principles

| ID | Principle | In practice | Typical violation |
|---|---|---|---|
| OE-01 | **End-to-end tracing** | One trace spans the application, orchestration, retrieval, model, and tool layers (§2), with a span per model call, retrieval, and tool call. OpenTelemetry and its GenAI semantic conventions are an emerging practice for this; verify their current status before relying on specific attributes. | Model-provider logs in one console, app logs in another, and no way to join them. |
| OE-02 | **Correlate execution with the business request, protecting sensitive data** | A correlation ID links the user or business request (ticket, case, transaction) to every model and tool span, plus the agent version. Prompt and response content is redacted by default, sampled where needed, and captured in full only in a separate, access-controlled secure store with short retention (DG-09). | Full prompts with customer PII in the general log index, readable by every engineer. |
| OE-03 | **Defined metrics with targets** | Each use case selects metrics from the catalog (§3), with targets traced to NFRs, a measurement point, and an owner. | "We'll watch the dashboards" with no target or owner. |
| OE-04 | **Deterministic checks first** | Use exact-match, schema, regex, citation-presence, policy, and code-based checks wherever they can decide; use model-based grading only for what they can't. | An LLM judge asked whether output JSON is valid. |
| OE-05 | **Offline evaluation on governed datasets** | Golden datasets have provenance, a size rationale, an owner, and a refresh cadence. They mix representative cases (real distribution) and adversarial cases (§4). | A test set written by the developer from memory, never refreshed. |
| OE-06 | **Calibrated model-based grading** | LLM-as-judge is calibrated against human labels before its scores gate a release, re-calibrated when the judge or rubric changes, and its known limitations are recorded (§4.2). | Trusting a judge score that was never compared against human ratings. |
| OE-07 | **Regression testing on every change** | Any change to model, model version, prompt, tool set, tool schema, retrieval configuration, policy, or runtime configuration triggers the evaluation suite and is compared against the current production version. | A provider's model version update going live unnoticed. |
| OE-08 | **Online monitoring and production feedback** | Production quality is sampled and scored, user feedback is captured and triaged, and confirmed failures flow back into the evaluation set. | Evaluation that stops at release. |
| OE-09 | **Alerts with thresholds and owners** | Every alert has a numeric threshold, a severity, an owning team, and a runbook. SLO → alert → owner → runbook is a complete chain (G9). | Alerts routed to a shared mailbox nobody reads. |
| OE-10 | **Safe rollback and version comparison** | New versions are compared to the current one using shadow, A/B, or canary rollout (§6), with numeric rollback triggers. Rolling back is one operation on a versioned unit. | Rolling back requires reconstructing last week's prompt from chat history. |
| OE-11 | **Don't collect sensitive prompts and outputs unnecessarily** | Capture the minimum needed for debugging and evaluation. Prefer metadata and metrics; capture content only under a justified, time-limited policy. | Retaining every conversation indefinitely "in case it's useful for evaluation". |

## 2. Trace layers

| Layer | Span or event | Key attributes (examples) | Sensitive content handling |
|---|---|---|---|
| Application | Request received, response returned | Correlation ID, user/tenant (pseudonymous), channel, latency, outcome | No content by default |
| Orchestration | Workflow or agent run, step, handoff | Agent ID and version (AG-17), step count, limits consumed (AG-06), final state | Plan text only in the secure store |
| Retrieval | Query, results | Index and version, result IDs, scores, permission-trim applied, freshness | Query text redacted; document IDs, not content |
| Model | Model call | Model ID and version, tokens in/out, latency, finish reason, cost, cache hit | Prompt/response in the secure store, sampled |
| Tool | Tool call | Tool name and version, identity used (OBO/app-only), policy decision, approval ID, result status | Parameters redacted per classification |
| Policy / guardrail | Decision | Policy ID and version, decision, reason code | No content |

## 3. Metrics catalog

Pick what the use case needs; don't instrument everything by default.

| Category | Metric | Notes |
|---|---|---|
| Latency | End-to-end p50/p95/p99; time to first token; per-layer latency | Measure at the user-facing boundary and per span |
| Throughput | Requests, runs, and tool calls per interval | Compare against capacity limits (RR-08) |
| Failures | Error rate by layer; timeouts; limit breaches; failed runs | Separate provider errors from application errors |
| Token use | Tokens per request and per run, by model | Detects prompt bloat and runaway loops |
| Cost | Cost per request, per run, per business outcome; spend against budget | Tie to the business unit of value |
| Quality | Task success, accuracy against reference, rubric scores | From offline evaluation and online sampling |
| Groundedness | Share of claims supported by retrieved sources; citation correctness | RAG and research use cases |
| Policy violations | Guardrail triggers, blocked tool calls, PDP denials, sensitive-data detections | Spikes can indicate attack or regression |
| Tool error rates | Errors and schema-validation failures per tool | Separate tool defects from model misuse |
| Approval rates | Approve / reject / edit / expire rates per action class | High reject rates signal quality problems; near-100% approval can signal rubber-stamping |
| Escalation rates | Share of runs handed to humans, by reason | Compare against the autonomy value claimed in the justification (`agentic-ai-design-principles.md` §1) |
| Drift | Input distribution shift, retrieval score shift, quality trend, model-version changes | Triggers re-evaluation |

## 4. Offline evaluation

### 4.1 Datasets and cases

- **Provenance.** Each case records its source (production sample, expert-written, synthetic), date, classification, and de-identification status (DG-04).
- **Representative cases** reflect the real distribution of inputs, languages, user types, and difficulty, including known hard cases.
- **Adversarial cases** cover direct and indirect prompt injection, out-of-scope requests, sensitive-data elicitation, tool misuse, limit exhaustion, conflicting or stale sources, and unanswerable questions (`security-and-identity.md` §6).
- **Size rationale.** State why the set is large enough for the decision it gates. Don't quote statistical confidence you didn't compute.
- **Holdout.** Keep a holdout set that prompt developers don't tune against.

### 4.2 LLM-as-judge

- Apply deterministic checks first (OE-04); use a judge only for what remains, such as tone, completeness, or faithfulness.
- Calibrate against human labels on a representative sample; record the agreement observed and re-check it when the judge model, judge prompt, or rubric changes.
- Known limitations to record and mitigate: position and verbosity bias, preference for outputs similar to its own style, inconsistency across runs, weak domain expertise, and susceptibility to injected content in the graded output.
- Use clear rubrics with anchored scales, and grade one criterion at a time where practical.
- Keep humans in the loop for T3/T4 release decisions; a judge score informs, it doesn't approve.

### 4.3 Regression (OE-07)

- Run the suite in CI on every change to the versioned unit (AG-17).
- Compare against the production baseline per metric; regressions beyond the threshold block release.
- Re-run on a schedule even without changes, to detect provider-side model changes and data drift.

## 5. Release-gate examples

Thresholds come from the use case's NFRs; the rows below show the *form*, not recommended values.

| Gate | Example criterion |
|---|---|
| Task quality | Task success on the representative set ≥ `<NFR target>`, and no regression > `<tolerance>` against production |
| Groundedness | Unsupported-claim rate ≤ `<NFR target>`; citation correctness ≥ `<target>` |
| Safety | Zero critical failures on the adversarial set (e.g. a consequential tool executed from injected content) |
| Policy | Zero PDP bypasses; all consequential actions carry an approval record in tests |
| Performance | p95 latency ≤ `<NFR target>` under the expected load profile |
| Cost | Cost per task ≤ `<budget>` at the expected mix |
| Judge validity | Judge-to-human agreement on the calibration set ≥ `<agreed threshold>` before judge scores gate the release |

## 6. Online monitoring and version comparison

- **Sampling.** Score a sample of production traffic with the same metrics as offline evaluation, at a rate set by volume and tier.
- **Feedback.** Capture explicit (ratings, corrections) and implicit (edits, abandonments, escalations) signals; triage confirmed failures into new evaluation cases.
- **Shadow.** Run the new version on mirrored traffic without user impact; compare outputs and metrics. Never execute side-effecting tools in shadow mode.
- **A/B.** Split traffic to compare outcome metrics where the risk is low enough for users to see either version.
- **Canary.** Release to a small slice, widen in steps, and roll back automatically on numeric triggers (quality, error rate, policy violations, cost).
- **Rollback.** One operation, to the previous versioned unit, with its retrieval index and policy versions where they changed together.

### 6.1 Alert thresholds and owners (OE-09)

Illustrative shape only; thresholds come from the SLOs and NFRs, and owners from the support model.

| Alert | Signal | Threshold source | Severity | Owner | Runbook action |
|---|---|---|---|---|---|
| Latency SLO burn | p95 end-to-end latency | Latency NFR / error budget | High | Service team on-call | Check provider latency; switch degradation mode (RR-05) |
| Model error rate | Provider errors, timeouts, throttling | Availability SLO | High | Service team on-call | Confirm breaker state; fallback model |
| Quality drop | Sampled online quality score vs baseline | Release-gate tolerance | Medium/High | Use-case product owner + AI engineer | Compare versions; roll back if confirmed |
| Policy violation spike | PDP denials, guardrail triggers, sensitive-data detections | Baseline rate per period | High | Security operations | Investigate for attack; suspend tools if needed |
| Runaway agent | Limit breaches (AG-06), tokens or cost per run | Execution-limit configuration | High | Service team | Suspend agent version; inspect traces |
| Spend | Cost against budget | Budget owner's limit | Medium | Budget owner | Throttle low-priority traffic; review |
| Freshness breach | Source-to-index lag | Freshness SLA (DG-07) | Medium | Data steward | Re-run ingestion; check source connector |
| Approval anomalies | Approval or rejection rate shift | Historical baseline | Medium | Business process owner | Review for rubber-stamping or quality regression |

## 7. Anti-patterns

- **Vibe evaluation:** release decided by a handful of manual tries.
- **Judge without calibration:** an LLM grade treated as ground truth.
- **Log everything forever:** full prompt capture in general logs, with no redaction, access control, or expiry.
- **Dashboard without owners:** metrics nobody is accountable for acting on.
- **Untracked versions:** traces that don't record model, prompt, and agent versions, so incidents can't be attributed.
- **Shadow with side effects:** a shadow deployment that actually sends emails or writes records.

## 8. Tier scaling

| Concern | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Tracing (OE-01) | Request logs + model call metadata | End-to-end trace with correlation ID | + all layers in §2, agent version on every span | + tamper-evident retention for audit-relevant spans |
| Content capture (OE-02, OE-11) | Off, or short-retention debug | Redacted; sampled | Secure store with access approval | + access audited, minimal retention |
| Metrics (OE-03) | Latency, errors, cost | + quality, token use | Full relevant catalog | + drift and approval/escalation analytics |
| Offline evaluation (OE-05) | Smoke set | Representative set | + adversarial set, holdout | + independent evaluation, red team |
| Judge use (OE-06) | Optional | Calibrated if used to gate | Calibrated, re-checked on change | + human review of release decisions |
| Regression (OE-07) | Manual before release | CI on every change | + scheduled re-runs | + sign-off on every regression waiver |
| Online (OE-08) | User feedback | + sampled scoring | + feedback-to-eval loop | + continuous monitoring with on-call |
| Alerts (OE-09) | Errors | + SLO alerts with owners | + quality and policy alerts, runbooks | + 24×7 ownership where the service requires it |
| Rollout (OE-10) | Direct deploy, quick rollback | Canary or staged | Shadow or canary with numeric triggers | + automated rollback and approval to widen |

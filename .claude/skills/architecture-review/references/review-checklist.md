# Architecture Review Checklist

The working checklist for the `architecture-review` skill ([SKILL.md](../SKILL.md)). Each item is a yes/no check. A **No** is a candidate finding: rate it with the [severity rubric](severity-rubric.md), and record the evidence and the basis. A **Yes** needs evidence too (a path, a section, an observed output). An answer that rests on documentation alone is "documented", not "implemented".

**How to use**
- ★ marks the must-check items. A T1 review covers at least these. T2+ covers every item in the dimensions in scope.
- Answer **N/A** only with a reason, for example "no agent: rung 4".
- In a finding, cite the item ID, for example "Fails RC-SEC-04".
- These checks apply the standards. They don't redefine them. When a check and a standard disagree, the standard wins, and the checklist gets fixed.
- Suggested owners show which specialist (`docs/operating-model.md` §3) normally covers each dimension, so the dimensions don't overlap.

---

## 1. Requirement coverage (owner: solution-architect)

- [ ] ★ RC-REQ-01 Are business objectives stated with a baseline, a target, and a measurement method?
- [ ] ★ RC-REQ-02 Does every FR have an ID, a priority, and a testable acceptance criterion?
- [ ] ★ RC-REQ-03 Does every NFR have a metric, a target, a measurement point, and a method?
- [ ] RC-REQ-04 Does every Must FR and NFR map to at least one component?
- [ ] RC-REQ-05 Does every Must FR and NFR map to at least one test or evaluation case?
- [ ] ★ RC-REQ-06 Is every CON and PRH listed, and does the design comply with each?
- [ ] RC-REQ-07 Are NFR conflicts identified (for example, latency vs grounding depth), each with a resolution or an owner?
- [ ] RC-REQ-08 Are out-of-scope items stated explicitly?
- [ ] RC-REQ-09 Does each ASM carry an impact, a confidence, a validation method, an owner, and a deadline?
- [ ] RC-REQ-10 Are the unacceptable error types defined, not just average accuracy?

## 2. Coherence (owner: solution-architect)

- [ ] ★ RC-COH-01 Do the diagrams, component catalogue, technology table, and ADRs name the same components and technologies?
- [ ] RC-COH-02 Does each component have exactly one stated responsibility?
- [ ] RC-COH-03 Is there one system of record for each business entity?
- [ ] RC-COH-04 Are the sync and async boundaries consistent with the latency NFRs?
- [ ] RC-COH-05 Do the ADRs still reflect the current design, with no superseded decision referenced as current?
- [ ] RC-COH-06 Is the chosen ladder rung consistent with what the components actually do?
- [ ] RC-COH-07 Are naming, versioning, and environment conventions consistent across components?

## 3. Complexity and duplication (owner: enterprise-architect)

- [ ] ★ RC-CPX-01 Are lower ladder rungs explicitly ruled out, each with a requirement-based reason?
- [ ] ★ RC-CPX-02 Does the design avoid duplicating an existing workflow engine, orchestration, or integration platform?
- [ ] RC-CPX-03 Does it avoid running two orchestrators (for example, a workflow tool plus an agent framework) over the same workflow?
- [ ] RC-CPX-04 Does it avoid a second agent or LLM framework added merely for different features?
- [ ] RC-CPX-05 Does it avoid a new gateway, search engine, or vector store when an existing one meets the need?
- [ ] RC-CPX-06 Does every component trace to a requirement (no orphans)?
- [ ] RC-CPX-07 Is each shared capability justified by the 10 questions in `standards/agentic-ai-design-principles.md` §6?
- [ ] RC-CPX-08 Is the number of distinct runtimes, languages, and data stores justified?
- [ ] RC-CPX-09 Could a configuration change to an existing product meet any part of the need (rung 0)?

## 4. Functional completeness (owner: solution-architect)

- [ ] ★ RC-FUN-01 Is every Must FR realized end to end, including the error and exception paths?
- [ ] RC-FUN-02 Are human review, override, and escalation paths designed where the brief requires oversight?
- [ ] RC-FUN-03 Are inputs the system can't handle (out of scope, unreadable, ambiguous) detected and routed?
- [ ] RC-FUN-04 Is there a defined behavior when the model abstains or has low confidence?
- [ ] RC-FUN-05 Are user feedback and correction captured and routed to an owner?
- [ ] RC-FUN-06 Are administrative functions (configuration, content onboarding, access management) designed?
- [ ] RC-FUN-07 Are batch, backfill, and reprocessing paths covered where data changes?

## 5. NFR feasibility (owner: reliability-llmops-architect)

- [ ] ★ RC-NFR-01 Is the latency budget decomposed across the hops (retrieval, model calls, tools), and does it fit the target?
- [ ] RC-NFR-02 Are throughput and concurrency targets checked against model and provider quotas and rate limits?
- [ ] RC-NFR-03 Is the availability target achievable given each dependency's SLA (composite availability)?
- [ ] RC-NFR-04 Are quality targets backed by evaluation evidence or a credible plan to obtain it?
- [ ] RC-NFR-05 Are RTO and RPO stated and achievable with the chosen data stores?
- [ ] RC-NFR-06 Has `nfr-validation` been run, with its results recorded in `05-validation/nfr-validation.md`?
- [ ] RC-NFR-07 Are capacity assumptions (volumes, document counts, context sizes) stated as ASMs where unverified?

## 6. Security and governance (owner: security-identity-architect)

- [ ] ★ RC-SEC-01 Is authorization enforced outside the model, in deterministic code or policy?
- [ ] ★ RC-SEC-02 Are tool outputs, retrieved content, and user inputs treated as untrusted?
- [ ] ★ RC-SEC-03 Are user, workload, agent, and tool identities separated?
- [ ] ★ RC-SEC-04 Are consequential actions gated by a deterministic policy and/or human approval?
- [ ] ★ RC-SEC-05 Are credentials kept out of prompts, the model context, logs, and code?
- [ ] RC-SEC-06 Are delegated-access semantics (on behalf of a user vs a service identity) explicit for every tool?
- [ ] RC-SEC-07 Is each tool permission least-privilege, scoped to the specific operations and resources?
- [ ] RC-SEC-08 Are prompt-injection controls defined for each ingestion path (documents, email, web, tool results)?
- [ ] RC-SEC-09 Is model output validated (schema, allow-list, policy) before it drives any action?
- [ ] RC-SEC-10 Are trust boundaries drawn, with each crossing flow listed?
- [ ] RC-SEC-11 Is a threat model present, with mitigations, tests, and named residual-risk owners (T2+)?
- [ ] RC-SEC-12 Are output-safety controls (harmful content, data leakage, PII echo) proportionate to the exposure?
- [ ] RC-SEC-13 Is there an immutable audit trail of who or what did which action, and on whose authority?
- [ ] RC-SEC-14 Are the model and tool supply chain (provenance, versions, MCP servers, plugins) controlled?
- [ ] RC-SEC-15 Is network egress from the model and agent runtime restricted to approved destinations?
- [ ] RC-SEC-16 Are applicable regulations and internal AI policies mapped to controls?
- [ ] RC-SEC-17 Is there a kill switch or disable path for the AI component (T3+)?

## 7. Integration (owner: integration-infrastructure-architect)

- [ ] ★ RC-INT-01 Are side-effecting integration calls idempotent (with idempotency keys or deduplication)?
- [ ] RC-INT-02 Are interface contracts (schemas, events, APIs) defined and versioned?
- [ ] RC-INT-03 Is each call given a timeout, and are retries bounded with backoff?
- [ ] RC-INT-04 Are error semantics defined (retryable vs terminal), and are poison messages handled?
- [ ] RC-INT-05 Is the owner and SLA of each external dependency known?
- [ ] RC-INT-06 Does the design avoid direct coupling to another domain's database or schema?
- [ ] RC-INT-07 Are existing enterprise integration patterns (API gateway, event bus, iPaaS) reused where they fit?
- [ ] RC-INT-08 Are tool and MCP interfaces described by explicit schemas, not free text?
- [ ] RC-INT-09 Is backpressure handled when downstream systems are slower than the AI tier?

## 8. Data (owner: data-knowledge-memory-architect)

- [ ] ★ RC-DAT-01 Is retrieval permission-trimmed to the requesting user's entitlements at query time?
- [ ] ★ RC-DAT-02 Is each data source's classification, owner, and residency recorded?
- [ ] RC-DAT-03 Are data flows to model providers compliant with classification and residency rules?
- [ ] RC-DAT-04 Are retention and deletion defined for prompts, outputs, logs, embeddings, and memory?
- [ ] RC-DAT-05 Are deletions and permission changes in source systems propagated to indexes and caches?
- [ ] RC-DAT-06 Is index freshness defined, measured, and matched to the requirement?
- [ ] RC-DAT-07 Is the chunking and embedding strategy justified by an evaluation, not just a default?
- [ ] RC-DAT-08 Is agent or user memory scoped (user, session, case), and does it expire?
- [ ] RC-DAT-09 Is memory protected against poisoning by untrusted content?
- [ ] RC-DAT-10 Is lineage traceable from an answer back to its sources (citations)?
- [ ] RC-DAT-11 Is PII minimized or masked before model calls and logging, where the requirements allow?
- [ ] RC-DAT-12 Are the embedding model and its version recorded, with a re-index plan for when it changes?
- [ ] RC-DAT-13 Is data quality (completeness, duplicates, staleness) assessed for the sources the answers depend on?
- [ ] RC-DAT-14 Is context-window composition (what goes in, in what order, within what budget) defined?

## 9. Agentic necessity (owner: agentic-systems-architect)

- [ ] ★ RC-AGT-01 If the design uses rung 6 or above, does it pass the agentic justification test in `standards/agentic-ai-design-principles.md` §1?
- [ ] ★ RC-AGT-02 Are agent loops bounded by step, time, token, and cost limits?
- [ ] RC-AGT-03 Could a fixed workflow with LLM steps (rung 4) achieve the same result?
- [ ] RC-AGT-04 For multi-agent designs, does each agent exist for isolation, parallelism, or separation of duties, with the benefit measured?
- [ ] RC-AGT-05 Is the toolset bounded and enumerated, with no generic "run any code" or "call any API" tool unless justified and sandboxed?
- [ ] RC-AGT-06 Are stop conditions and failure exits defined, with no unbounded replanning?
- [ ] RC-AGT-07 Does the approval matrix (`standards/agentic-ai-design-principles.md` §4) match the actions' risk?
- [ ] RC-AGT-08 Is agent state persisted and recoverable for long-running tasks?
- [ ] RC-AGT-09 Are handoffs between agents structured (typed payloads), not free-form chat?
- [ ] RC-AGT-10 Is each agent registered with an owner, a version, and a lifecycle state (§7 of the agentic standard)?
- [ ] RC-AGT-11 Is agent behavior evaluated on trajectories (tool choice, step count), not just final answers?

## 10. Model and framework choice (owner: ai-platform-architect)

- [ ] ★ RC-MOD-01 Was the model evaluated on representative business data, not leaderboard rank alone?
- [ ] RC-MOD-02 Are model availability, region, data-use terms, and lifecycle (deprecation date) verified and dated?
- [ ] RC-MOD-03 Is the model size or tier justified by quality and cost, rather than defaulting to the largest?
- [ ] RC-MOD-04 Does each model route or fallback have a measured benefit and an equivalent quality check?
- [ ] RC-MOD-05 Are model and provider access abstracted at the volatile seam, where the lock-in risk justifies it?
- [ ] RC-MOD-06 Is the framework the simplest one sufficient, and an existing investment where viable?
- [ ] RC-MOD-07 Are framework version, maintenance status, and licensing verified and dated?
- [ ] RC-MOD-08 Is self-hosting justified by requirements (residency, cost at volume, latency), with an operating cost estimate?
- [ ] RC-MOD-09 Are structured outputs or function calling used where downstream code parses model output?

## 11. Resilience (owner: reliability-llmops-architect)

- [ ] ★ RC-RES-01 Is there a defined degraded mode for when the model provider is unavailable?
- [ ] ★ RC-RES-02 Are retries bounded, and are side effects idempotent, across model and tool calls?
- [ ] RC-RES-03 Is the behavior defined when each tool, data store, or integration is unavailable?
- [ ] RC-RES-04 Are circuit breakers or load shedding in place for dependencies with quotas?
- [ ] RC-RES-05 Can partially completed multi-step actions be compensated or resumed?
- [ ] RC-RES-06 Are backups and DR defined for the indexes, memory, and configuration stores?
- [ ] RC-RES-07 Has DR been tested (T3+), or is a test scheduled with an owner?
- [ ] RC-RES-08 Is behavior under malformed or truncated model output defined?
- [ ] RC-RES-09 Are single points of failure identified and accepted, or mitigated?

## 12. Observability and evaluation (owner: reliability-llmops-architect / ai-platform-architect)

- [ ] ★ RC-OBS-01 Is there an offline evaluation set with numeric release thresholds?
- [ ] ★ RC-OBS-02 Are prompts versioned and deployed through change control, not edited in production?
- [ ] RC-OBS-03 Are end-to-end traces captured across model calls, retrieval, and tool calls with correlation IDs?
- [ ] RC-OBS-04 Are the model, prompt, index, and tool versions tagged on every trace?
- [ ] RC-OBS-05 Do online quality signals (feedback, groundedness, refusal rate, escalation rate) have alert thresholds and owners?
- [ ] RC-OBS-06 Is the evaluation set's provenance, size rationale, and refresh cadence documented?
- [ ] RC-OBS-07 Do adversarial and red-team cases form part of the evaluation set (T2+)?
- [ ] RC-OBS-08 Are any LLM-as-judge evaluators themselves calibrated against human labels?
- [ ] RC-OBS-09 Is logging of prompts and outputs compliant with data-classification and retention rules?
- [ ] RC-OBS-10 Is drift (input, retrieval, output quality) monitored, with a re-evaluation trigger?
- [ ] RC-OBS-11 Is there an SLO → alert → owner → runbook chain for each critical NFR?

## 13. Deployment and operations (owner: integration-infrastructure-architect)

- [ ] ★ RC-OPS-01 Is there a rollback path for the model, prompt, index, and code, each independently?
- [ ] RC-OPS-02 Is infrastructure defined as code and promoted through environments?
- [ ] RC-OPS-03 Is the release strategy (shadow, canary, feature flag) proportionate to the tier?
- [ ] RC-OPS-04 Do the evaluation gates run in the CI/CD pipeline before promotion?
- [ ] RC-OPS-05 Does a named team support the system, with a defined on-call or escalation model?
- [ ] RC-OPS-06 Do runbooks exist for the top failure modes (provider outage, quality regression, cost spike)?
- [ ] RC-OPS-07 Are environments isolated, with no production data in lower environments unless approved and masked?
- [ ] RC-OPS-08 Is the network topology (private endpoints, egress) consistent with the mandated platform?

## 14. Cost and maintainability (owner: reliability-llmops-architect)

- [ ] ★ RC-CST-01 Is the token and cost per request bounded (max tokens, max steps, max tool calls)?
- [ ] RC-CST-02 Is there a cost estimate at expected and peak volume, with its assumptions stated?
- [ ] RC-CST-03 Are budgets, quotas, and alerts configured per environment or tenant?
- [ ] RC-CST-04 Is caching (prompt, semantic, retrieval) considered where it reduces cost without staleness risk?
- [ ] RC-CST-05 Is denial-of-wallet (abusive or looping usage) mitigated?
- [ ] RC-CST-06 Are cost owners and chargeback or showback defined?
- [ ] RC-CST-07 Is the skills profile needed to maintain the stack available, or planned for?
- [ ] RC-CST-08 Is custom code limited to differentiating logic?

## 15. Lock-in (owner: enterprise-architect)

- [ ] ★ RC-LCK-01 Is each material lock-in recorded in an ADR, with its benefit and an exit-cost estimate?
- [ ] RC-LCK-02 Are open protocols and formats used at domain and vendor boundaries?
- [ ] RC-LCK-03 Are prompts, evaluation sets, and agent definitions stored in portable, versioned form?
- [ ] RC-LCK-04 Are proprietary features used deliberately, rather than by default?
- [ ] RC-LCK-05 Are contract or licensing terms that affect exit (data export, model weights, notice periods) known?

## 16. Implementation maturity (owner: solution-architect)

- [ ] ★ RC-MAT-01 Does the implemented system match the documented design (baseline verified)?
- [ ] RC-MAT-02 Are automated tests present and passing for the critical paths, with the observed results available?
- [ ] RC-MAT-03 Is any prototype code that's destined for production identified and hardened?
- [ ] RC-MAT-04 Are dependency versions pinned, and is a vulnerability scan in place?
- [ ] RC-MAT-05 Are configuration and feature flags externalized from code?
- [ ] RC-MAT-06 Is error handling consistent, with no swallowed exceptions on side-effecting paths?
- [ ] RC-MAT-07 Is technical debt that blocks NFRs recorded with owners?

## 17. Evidence and traceability (owner: coordinator)

- [ ] ★ RC-EVD-01 Do material claims carry evidence labels per `standards/architecture-principles.md` §3?
- [ ] ★ RC-EVD-02 Do time-sensitive claims (capabilities, versions, pricing, regulation) carry a source URL and an access date?
- [ ] RC-EVD-03 Are "verified" or "tested" claims backed by observed output, not intent?
- [ ] RC-EVD-04 Is the traceability chain requirement → component → test → result complete for Must items?
- [ ] RC-EVD-05 Are the knowledge-base entries relied on within their re-verification window?
- [ ] RC-EVD-06 Does every ADR have revisit triggers?
- [ ] RC-EVD-07 Is "not verified" kept visible in the deliverables, rather than omitted?
- [ ] RC-EVD-08 Are there no benchmark, adoption, or feature claims without a source?

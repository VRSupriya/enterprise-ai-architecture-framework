# Agentic AI Design Principles

**Layer A: stable principles.** This file changes only by explicit framework decision (see `docs/extending-the-framework.md`). It applies whenever a design reaches solution-ladder rung 6 or 7 (`standards/architecture-principles.md` §4), and partially to rungs 4–5 wherever an LLM can call tools. Core principles (AP-01..AP-14), input classes, and evidence labels are defined in `standards/architecture-principles.md` and are not repeated here. Related standards: `security-and-identity.md` (SEC), `data-governance.md` (DG), `observability-and-evaluation.md` (OE), `reliability-and-resilience.md` (RR).

---

## 1. Agentic justification test

Run this test **before** selecting rung 6 or above. Record the answers in `02-design/solution-design.md` §Solution Approach, and in an ADR when the decision is material. Every item must pass, or carry an explicit, owner-accepted exception. Failing items mean the design drops to a lower rung or to a hybrid (for example, rung 2 orchestration with one bounded rung 6 sub-task).

### 1.1 Single bounded agent (rung 6)

- [ ] **Paths can't be enumerated.** A written explanation of why a deterministic workflow (rung 2) with LLM steps (rung 4) can't cover the task paths. "Flexibility" alone is not an answer. Name the variability: input types, branching that depends on intermediate results, tool selection that depends on content.
- [ ] **Measurable value of autonomy.** A metric (resolution rate, handling time, coverage, cost per case) with a baseline and a target, showing what the agent adds over the lower-rung design. Mark it `[ASSUMPTION]` with an `ASM-` ID if no baseline exists yet.
- [ ] **Bounded toolset.** A finite, listed set of tools, each with read/write classification and scope (AG-03). An open-ended toolset ("it can call any internal API") fails.
- [ ] **Risk tier confirmed.** Rung 6 is at least T3 for the autonomy factor (`architecture-quality-gates.md` §2). The tier and its controls are recorded.
- [ ] **Evaluation plan.** Representative and adversarial evaluation cases, metrics, and release thresholds exist or are planned with an owner (AG-10, `observability-and-evaluation.md`).
- [ ] **Cost and latency impact.** Estimated tokens, tool calls, and wall-clock time per task (typical and worst case), compared against the NFR budget and the lower-rung alternative.
- [ ] **Failure path.** What happens when the agent can't complete, exceeds a limit, or is wrong (AG-09).

### 1.2 Additional test for multi-agent (rung 7)

All of §1.1, plus:

- [ ] **Genuinely separable work.** Sub-tasks have distinct context, distinct permissions, or distinct owning teams. Splitting a single prompt into "roles" doesn't count.
- [ ] **Measurable benefit over a single agent.** Evidence (an evaluation run, or a reasoned estimate labelled `[JUDGMENT]`) that isolation, parallelism, or separation of duties beats one agent with the same tools on quality, safety, latency, or cost.
- [ ] **Coordination overhead accounted for.** Extra tokens, latency, failure modes (handoff loss, deadlock, conflicting actions), tracing, and evaluation cost are estimated and included in the comparison.
- [ ] **Handoff contracts.** Each inter-agent handoff has a schema, an owner, and a failure behavior (AG-13).

## 2. Principles

| ID | Principle | In practice | Typical violation |
|---|---|---|---|
| AG-01 | **Deterministic logic for critical rules** | Applies AP-14 to agents. Limits, eligibility, compliance checks, and routing rules with legal or financial effect run in code or a policy engine that the agent calls, never in prompt instructions. | "The system prompt says never refund more than $500." |
| AG-02 | **Bound autonomy and execution time** | Each agent run has a declared goal, a maximum step count, a wall-clock deadline, and a stop condition. Long-running work is split into checkpointed stages (AG-13). | An agent loop that runs "until the task is done". |
| AG-03 | **Explicit tool permissions** | A per-agent allowlist of tools. Each tool declares its scope (resources, tenants, operations) and is classified read, reversible write, or irreversible. Read and write capabilities are separate tools, not one tool with a mode flag. | One "execute_sql" tool with write access to the whole database. |
| AG-04 | **Treat external content and tool output as untrusted** | Retrieved documents, web pages, emails, file contents, and tool responses are data, never instructions. Isolate them in the context, and don't let them widen permissions or trigger consequential tools without a deterministic check (SEC-09). | An agent that follows instructions embedded in a customer email. |
| AG-05 | **Enforce authorization outside the model** | The tool layer or a policy decision point checks every call against the caller's effective permissions (SEC-06, SEC-10). The model may *propose* an action; it never *authorizes* one. | Relying on the model to "only look up the current user's records". |
| AG-06 | **Limit retries, recursion, tokens, concurrency, and tool calls** | Hard limits enforced by the runtime, not by the prompt. See §3 for control types. | A planner that re-plans indefinitely after each tool error. |
| AG-07 | **Validate tool inputs and outputs** | Every tool has typed input and output schemas. Inputs are validated before execution (types, ranges, allowed values, ownership); outputs are validated and size-bounded before entering the context. | Free-text tool arguments passed straight into a shell or query. |
| AG-08 | **Human approval for consequential actions** | Approval requirements follow the risk-based matrix in §4. The approval UI shows the exact action and parameters that will execute, not the model's summary of them. | "Approve?" dialogs showing an agent-written description that differs from the real call. |
| AG-09 | **Explicit failure, escalation, and recovery paths** | Each run ends in a defined state: completed, escalated to a named human queue, failed safely with compensation, or suspended. Partial side effects are recorded and recoverable (RR-04, RR-11). | An agent that silently returns "I couldn't do that" after half-completing a transaction. |
| AG-10 | **Evaluate with representative and adversarial tests** | Offline evaluation covers real task distributions and adversarial cases (injection, tool misuse, out-of-scope requests, limit exhaustion) before release and on every change (OE-05, OE-07). | A demo on five happy-path examples as the release evidence. |
| AG-11 | **Avoid multi-agent without measurable justification** | Rung 7 only when §1.2 passes. Prefer one agent with well-designed tools, or deterministic orchestration of single-purpose LLM steps. | "Planner, researcher, critic, and writer" agents for a linear drafting task. |
| AG-12 | **Avoid a centralized agent platform for capabilities that don't need one** | Use §6 before building or mandating shared agent infrastructure. A single use case is rarely a reason for a platform. | A bespoke enterprise "agent OS" built for the first pilot. |
| AG-13 | **State and handoff design** | Long-running or multi-step work keeps durable state outside the model context, with a checkpoint after each side effect. Handoffs (agent-to-agent, agent-to-human) carry a schema-validated state object, not a chat transcript. | Losing all progress when a container restarts mid-task. |
| AG-14 | **Memory hygiene** | Memory is opt-in per use case, scoped (user, case, tenant), typed, time-limited, and governed per DG-12. Memory writes are validated so untrusted content can't plant persistent instructions. | An agent that remembers a prompt-injected "always CC this address" instruction. |
| AG-15 | **Agent identity distinct from user identity** | Each agent (per version and environment) has its own workload identity. Actions on behalf of a user carry both identities (SEC-03, SEC-06). | The agent uses the end user's raw token, or a shared service account, for everything. |
| AG-16 | **Agents never grant themselves privileges or deploy code** | Agents can't modify their own tool allowlist, permissions, prompts, policies, or deployment. Agent-generated code runs only in a sandbox, or reaches production through the normal pipeline with human review. | An agent with write access to its own configuration repository. |
| AG-17 | **Versioned agent definitions** | Model + prompt + tool set + tool schemas + policies + configuration form one versioned, immutable unit. Any change creates a new version that is re-evaluated (OE-07) and can be rolled back (OE-10). | Prompt tweaks hot-edited in production without a version or an evaluation. |

## 3. Execution limits and control types (AG-06)

| Limit | Control type | Enforced by | On breach |
|---|---|---|---|
| Steps / iterations per run | Hard counter | Agent runtime | Stop; escalate or fail safely |
| Wall-clock time per run | Deadline propagated to every call (RR-01) | Runtime + tool clients | Cancel in-flight calls; checkpoint; escalate |
| Tool calls per run, per tool | Counter and per-tool quota | Tool gateway / runtime | Block further calls of that tool |
| Retries per call | Bounded retry policy, idempotent calls only (RR-02) | Tool client | Surface the error to the planner once, then escalate |
| Recursion / delegation depth | Depth counter in the run context | Runtime / orchestrator | Refuse further delegation |
| Tokens per run and per call | Token budget | Model gateway / runtime | Truncate safely or stop |
| Concurrency | Per-agent, per-user, per-tenant caps | Runtime / queue (RR-08) | Queue or reject with backpressure |
| Cost per run / per period | Spend budget | Model gateway / cost control | Stop and alert the owner |
| Output size per tool response | Size cap and schema validation | Tool layer | Truncate with a marker, or reject |

## 4. Risk-based approval matrix (AG-08)

Adapt the matrix per use case; the tier sets the minimum. Approval decisions are recorded per SEC-08.

| Action class | Examples | T1/T2 default | T3 default | T4 default |
|---|---|---|---|---|
| Read | Search, lookup, retrieval within the user's permissions | No approval | No approval; audited | No approval; audited |
| Reversible write | Draft creation, internal ticket update, tagging | No approval, or batch review | Policy check; human approval above thresholds | Human approval |
| Irreversible or financial | Payments, refunds, deletions, contract changes, provisioning | Not allowed without human approval | Human approval per action, plus deterministic limits | Human approval; dual control for high values |
| External communication | Email, messages, or posts to customers, partners, or the public | Human approval | Human approval, or pre-approved templates only | Human approval per message |

Approval UI requirements: show the exact tool, the parameters, the target resource, the acting identities (agent version + on-behalf-of user), and the expected effect. Bind the approved parameters to the execution (for example, with a hash or a signed approval token), so the agent can't change them after approval. Approval requests expire.

## 5. Tier scaling

| Concern | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Justification (§1) | Short note if rung ≥ 6 | Full §1.1 | Full §1.1 (+ §1.2 if rung 7), in an ADR | Full, plus red-team challenge |
| Tool permissions | Allowlist | Allowlist + scopes | + read/write split, PDP-enforced | + per-call policy and dual control |
| Limits (§3) | Steps + time | All rows | All rows, alerting on breach | All rows, alerting, automatic suspension |
| Approval (§4) | As matrix | As matrix | As matrix, approvals audited | As matrix, dual control where listed |
| Evaluation | Smoke set | Representative set | + adversarial set, release gates | + independent red-team evaluation |
| Registry (§7) | Optional | Recorded in the use-case docs | Registry entry required | Registry entry + automated lifecycle |

## 6. Shared vs domain-owned capability

Use this before proposing any shared agent capability (agent runtime, tool gateway, memory service, evaluation service, agent registry, prompt store). It implements AP-06. Answer all ten questions in the design or an ADR.

1. **Problem solved.** What concrete problem does the capability solve, and for whom?
2. **Use cases that need it.** Which named, current use cases need it now, and which are speculative?
3. **Existing capability.** Does an existing enterprise capability (API gateway, IAM, workflow engine, observability stack, CI/CD) already meet the need, possibly with configuration?
4. **Placement.** Should it be centralized, federated (shared standard, domain-operated), or domain-owned?
5. **Sourcing.** Managed service, existing internal platform, or custom build?
6. **Interface.** What API or interface do consumers use, and how stable must it be?
7. **Identity and authorization.** How does it authenticate callers and enforce per-consumer authorization and tenant isolation?
8. **Operations.** Who deploys, monitors, versions, and supports it, at what service level?
9. **Cost.** What does it cost to build and to operate over its expected life, including the platform team?
10. **Consequence of not implementing.** What happens if each domain solves it locally: duplication, risk, inconsistency, or nothing material?

| Signal | Domain-owned | Federated | Centralized |
|---|---|---|---|
| Current consumers | One or two | Several, with differing needs | Many, with common needs |
| Risk if inconsistent | Low | Moderate: a shared standard suffices | High: a single control point is needed (e.g. egress, audit) |
| Existing enterprise capability | Not needed | Extend the existing one | Existing one is insufficient and the gap is measurable |
| Change rate | Fast, domain-specific | Mixed | Slow, stable interface |
| Bottleneck risk from a central team | Not applicable | Low | Must be mitigated with self-service and an SLA |
| Typical examples | Domain prompts, domain tools, case memory | Evaluation harness, agent definition standards | Identity, model gateway policy, audit logging, egress control |

Default: domain-owned, unless the signals point clearly to federated or centralized. A capability that is "nice to share" but fails questions 2 and 10 stays domain-owned.

## 7. Agent registry and automated agent lifecycle

These are **not mandatory components of every architecture.** Evaluate, with §6, whether they belong to the use case, to an existing platform, or to the enterprise platform roadmap. A T2 single-agent use case can usually record the same fields in its own documents.

### 7.1 Registry fields

| Field | Content |
|---|---|
| Identity / ID | Stable agent ID, and its workload identity per environment |
| Owner | Owning team and accountable person |
| Purpose | Business purpose and the requirement IDs it serves |
| Version | Version of the definition unit (AG-17) |
| Lifecycle state | e.g. draft, evaluated, approved, deployed, suspended, deprecated, retired |
| Declared tools / permissions | Tool allowlist, scopes, read/write classification, approval rules |
| Model and prompt dependencies | Model IDs and versions, prompt versions, policy versions |
| Runtime / environment | Where it runs, and its network and egress profile |
| Evaluation results and approval | Latest results against release gates; who approved, and when |
| Security classification | Risk tier, data classes handled, threat-model reference |
| Operational status | Health, SLO status, open incidents |
| Deprecation | Deprecation date, replacement, consumer notification |

### 7.2 Automated lifecycle pipeline

1. Approved agent specification (purpose, tools, limits, tier)
2. Schema and policy validation of the definition
3. Dependency and tool-permission checks (against the allowlist and least privilege)
4. Implementation
5. Static analysis and security scanning
6. Unit and integration tests
7. Offline behavioral evaluation (representative set)
8. Adversarial and policy tests
9. Human and/or policy approval
10. Immutable artifact build with provenance (SEC-12)
11. Versioning and registry update
12. Controlled deployment
13. Progressive rollout and production verification (OE-10)
14. Monitoring, with rollback, suspension, and retirement paths

## 8. Anti-patterns

- **Agent-washing:** labelling a fixed workflow as an agent, which adds nondeterminism with no benefit.
- **Prompt-as-policy:** business rules, limits, or authorization expressed only in prompt text.
- **God tool:** one broad tool (raw SQL, shell, generic HTTP) instead of narrow, scoped tools.
- **Unbounded loops:** no step, time, token, or cost limits; the agent retries until something gives.
- **Summary approval:** humans approve an agent's description of an action instead of the action itself.
- **Borrowed identity:** the agent acts with the user's full token or a shared superuser account.
- **Role-play multi-agent:** several agents that share one context and one permission set and differ only in prompt.
- **Transcript handoff:** passing raw conversation history between agents instead of validated state.
- **Self-modifying agent:** an agent that can change its own prompts, tools, permissions, or code in production.
- **Platform-first:** building a central agent platform before two or more real use cases need it.
- **Memory as a junk drawer:** storing everything, forever, unscoped, including untrusted content.
- **Unversioned drift:** model or prompt changes reaching production without re-evaluation.

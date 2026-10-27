# Architecture Principles

**Layer A: stable principles.** This file changes only by explicit framework decision (see `docs/extending-the-framework.md`). Every skill and agent references these sections instead of restating them.

---

## 1. Core principles

| ID | Principle | What it means in practice | Typical violation |
|---|---|---|---|
| AP-01 | **Requirements traceability** | Every material component and decision maps to at least one FR, NFR, CON, RSK, or ASM ID. Components with no trace get removed or justified. | "We added a vector DB because RAG apps have one." |
| AP-02 | **Constraint-aware design** | Mandatory constraints and prohibitions are honoured. Conflicts are surfaced for an explicit decision, never resolved silently (§2). | Quietly swapping the mandated cloud for a "better" one. |
| AP-03 | **Simplicity before complexity** | Choose the lowest rung of the solution ladder (§4) that meets the requirements. Each extra rung needs a measurable reason. | A multi-agent system for a fixed five-step process. |
| AP-04 | **Explicit responsibilities** | Each component has one clear purpose, an owner, and a defined interface. No two components own the same responsibility. | Both n8n and an agent framework orchestrate the same workflow. |
| AP-05 | **Clear ownership and boundaries** | Every component, data store, model, prompt, and tool has a named owning team plus a support model. | "The platform team will figure it out." |
| AP-06 | **Reuse without forced centralization** | Reuse existing enterprise capabilities when they fit. Centralize only when it reduces duplication or risk without creating a bottleneck (`standards/agentic-ai-design-principles.md` §6). | Building a new AI gateway while the existing API gateway already meets the need. |
| AP-07 | **Appropriate coupling** | Loose coupling at domain and vendor boundaries. Tight coupling is acceptable inside a cohesive component. | A direct database dependency on another domain's schema. |
| AP-08 | **Interoperability and lifecycle** | Prefer open protocols and formats at boundaries. Every artifact (model, prompt, agent, tool, schema) has a version and a lifecycle state. | Prompts edited in production with no version. |
| AP-09 | **Evidence-based decisions** | Material claims carry an evidence label (§3), and time-sensitive claims carry a source and a date. | "Framework X is the industry standard" with no source. |
| AP-10 | **Explicit assumptions and residual risk** | Each assumption has an impact, a confidence, a validation method, and an owner. Residual risks are accepted by a named person. | Hidden assumptions about data quality or volumes. |
| AP-11 | **Reversibility under uncertainty** | When confidence is low, prefer decisions that are cheap to reverse: abstraction at the volatile seam, short contracts, feature flags. | Hard-wiring one model provider's proprietary API across 40 services. |
| AP-12 | **Avoid unnecessary lock-in** | Accept lock-in only when its benefit is explicit and an exit cost estimate is recorded in the ADR. | Lock-in nobody noticed, and nobody recorded. |
| AP-13 | **Operational completeness** | A design is not enterprise-ready until identity, data protection, failure handling, observability, evaluation, deployment, cost, and ownership are addressed in proportion to its risk tier. Each capability is either designed or explicitly marked "not required because …". | An LLM, an API, and a database labelled "enterprise architecture". |
| AP-14 | **Deterministic controls for critical rules** | Business rules, authorization, financial limits, and compliance checks run in deterministic code, not inside model reasoning. | "The prompt tells the agent not to approve refunds over $500." |

## 2. Input classification

Every engagement classifies its inputs before design starts. Record them in the intake (`templates/use-case-intake.md`).

| Category | ID prefix | Meaning | Required treatment |
|---|---|---|---|
| Mandatory constraint | `CON-` | Non-negotiable business, platform, security, regulatory, deployment, integration, or technology requirement | Respect it. If it is infeasible, unsafe, contradictory, or non-compliant, explain why and request a decision. Never violate it silently. |
| Preference | `PREF-` | Desired technology, pattern, vendor, or approach | Evaluate it against the requirements and alternatives. Recommend otherwise when evidence justifies it, and explain why. |
| Existing investment | `INV-` | Existing platform, framework, application, contract, skill set, or infrastructure | Assess reuse, integration cost, technical debt, migration cost, and strategic fit. An existing investment is neither mandatory nor disposable by default. |
| Open decision | `DEC-` | A choice not yet made | Evaluate the viable options and recommend one, recorded as an ADR when material. |
| Assumption | `ASM-` | Accepted provisionally because evidence is missing | State its impact, confidence (H/M/L), validation method, owner, and deadline. |
| Prohibition | `PRH-` | Explicitly disallowed technology, deployment, data flow, or practice | Exclude it. Flag any unavoidable conflict. |

Further prefixes: `FR-` functional requirement, `NFR-` non-functional requirement, `RSK-` risk, `Q-` open question, `ADR-` decision record, `F-` review finding, `T-` threat, `TST-` test, `WS-` workstream, `BL-` backlog item.

**Clarification rule.** Ask a question only when the answer could materially change the architecture. Otherwise record an assumption and continue. Don't ask for information you could establish through research.

**Wording heuristics.** "Must", "mandated", "policy", "regulation", and "contract" usually indicate a CON. "Prefer", "would like", "we use", and "we are considering" usually indicate a PREF or INV. When the category is unclear, ask, or record it as a PREF and flag it as an assumption.

## 3. Evidence labels

| Label | Use for | Minimum backing |
|---|---|---|
| `[VERIFIED]` | Facts confirmed against an authoritative source or direct inspection | Source URL with access date, or file path / command output |
| `[VENDOR]` | Claims made by a product's vendor (docs, marketing, release notes) | Source URL with access date |
| `[INDEPENDENT]` | Third-party evaluations, peer-reviewed research, reputable engineering write-ups | Source URL, publication date, and scope caveats |
| `[JUDGMENT]` | Architect's reasoning from principles and experience | A stated rationale |
| `[ASSUMPTION]` | Accepted provisionally | An `ASM-` ID |
| `[UNVERIFIED]` | Time-sensitive claims that could not be checked (for example, research tools unavailable) | Reason it is unverified, plus a validation step |

Label only material claims: those that drive a decision, a risk rating, or a feasibility verdict. Don't litter documents with labels.

**Source preference** (highest first):
1. Official product docs and release notes, for capabilities and support status.
2. Standards bodies and regulators, for compliance.
3. Peer-reviewed or reputable independent evaluations.
4. Credible engineering publications.
5. Public case studies.
6. Community discussion, as supplementary evidence only.

GitHub stars, social-media popularity, vendor marketing, and leaderboard rank are never sufficient on their own.

**Maturity vocabulary** (for "is it a standard?" claims): Published standard · De facto practice · Vendor recommendation · Emerging practice · Experimental · Organization-specific choice.

## 4. Solution ladder (choose the lowest sufficient rung)

| Rung | Pattern | Choose when | Escalate only if |
|---|---|---|---|
| 0 | No new system: process change, or configure an existing product | The need is met by existing capability | Gaps are measurable |
| 1 | Deterministic application, rules engine | Rules are known and stable | Inputs are unstructured or the rules are unmanageable |
| 2 | Workflow automation / event-driven processing | Known multi-step process, integrations | Steps need judgement over unstructured content |
| 3 | Search / retrieval, conventional ML | Find, rank, or classify with labelled data | Generation or flexible language understanding is needed |
| 4 | LLM-assisted step inside a deterministic workflow | Extraction, summarization, classification, drafting | Grounding in enterprise knowledge is required |
| 5 | RAG application | Answers must cite governed enterprise content | Task paths can't be enumerated in advance |
| 6 | Single bounded tool-using agent | Dynamic tool selection or planning over a bounded toolset adds measurable value | Work is separable with distinct contexts, permissions, or owners |
| 7 | Multi-agent system | Genuinely separable sub-tasks where isolation, parallelism, or separation of duties is measurably better than one agent | — |

**When a lower rung's viability is unknown** (for example, whether an existing product's built-in reports would suffice), pick the lowest rung *known* to work. Record the lower rung as an evaluated alternative, together with an `ASM-` item, a validation step, and an ADR revisit trigger. This satisfies G3's "lower rungs ruled out" criterion as *pending validation*. Don't climb higher to avoid the question.

Hybrids are normal: for example, rung 2 orchestration with rung 4 steps and one rung 6 sub-task. Any rung of 6 or above requires the agentic justification in `standards/agentic-ai-design-principles.md` §1.

## 5. Recommendations and alternatives

For each material decision, record:
- **Recommended option.** The best fit for the documented requirements and constraints.
- **Alternative option.** Only with a specific reason to exist: a material trade-off, a viable fallback, a procurement or portability need, or an unresolved strategic choice.
- **Rejected option.** Only when recording it adds value, for example when a stakeholder proposed it.

Never present an undifferentiated list. Never manufacture alternatives to look balanced.

## 6. Platform-constraint behaviour

- When a platform (Azure, AWS, GCP, on-premises, air-gapped, hybrid) is mandated, design within it. Don't introduce other clouds or cross-cloud comparisons unless a constraint conflict requires that discussion.
- Within the mandated boundary, still challenge weak choices: framework complexity, model fit, duplicated orchestration, and self-hosting economics.
- When a mandated constraint makes an FR or NFR infeasible, document the conflict, the options (relax the requirement, relax the constraint, or accept the risk), their consequences, and the decision owner. Then stop and ask.

## 7. Proportionate challenge

- Challenge depth scales with the risk tier and the consequence of being wrong.
- Don't manufacture disagreement. Don't recommend a redesign when targeted remediation suffices.
- When evidence is asymmetric, say so; don't present both sides as equal.
- An existing architecture is not right because it was built, and not wrong because something newer exists.

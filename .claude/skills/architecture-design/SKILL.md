---
name: architecture-design
description: Creates or completes a constraint-aware, technology-agnostic, requirements-traced solution architecture. Covers solution-ladder pattern selection, components, interfaces, technology, trust boundaries, identity, data/knowledge/memory, agents (only if justified), deployment, observability, evaluation, reliability, and cost. Use for Mode A (create) or Mode C (improve), or when asked to "design the architecture", "propose a solution", "complete this design", "improve our stack", or "is AI even needed".
argument-hint: "<use-case-id>"
---

# Architecture Design

## Purpose

Produce `use-cases/<id>/02-design/solution-design.md`: the simplest sufficient architecture that meets the documented requirements within the mandatory constraints. Every material component and decision traces to an ID (AP-01). Every operational capability is either designed or explicitly marked "not required because …" (AP-13). This skill covers Phases B and C, and the design side of Phase F. It orchestrates the other design skills rather than duplicating them.

## When to use / when not to use

| Use when | Don't use when |
|---|---|
| Mode A: a new architecture from an intake | Mode B review of an existing system. Use `architecture-review`, then this skill for the target architecture |
| Mode C: a partial design, proposed stack, or prototype needs completing or correcting | A single technology choice. Use `technology-evaluation` |
| Phase F synthesis after review and debate | A single decision update. Use `adr-management` |

## Inputs

- `00-intake/use-case-brief.md`. **If it's missing or fails G1, run `use-case-discovery` first.**
- `01-requirements/requirements.md`, if present.
- In Mode C: the existing design, stack, or prototype artifacts (paths).
- In Phase F: `03-review-board/review-report.md` and `03-review-board/debate-record.md`.

## Constraint-aware, technology-agnostic, continuously updated

This section is how the skill applies AP-02, AP-09, and `standards/architecture-principles.md` §2, §5, and §6. Apply it at every step.

**Input treatment**

| Input | Treatment in the design |
|---|---|
| `CON` | Design within it. Cite the CON ID where it shapes a choice. If it's infeasible, unsafe, or contradictory, see "Conflicts" below. |
| `PRH` | Exclude it entirely. Don't include it as an alternative. If a requirement can't be met without it, raise a conflict. |
| `PREF` | Evaluate it like any other candidate. Adopt it if it fits. If the evidence favors something else, recommend that, and explain why in the ADR. |
| `INV` | Assess reuse first: fit, integration cost, debt, migration cost, and strategic fit. Don't treat it as mandatory, and don't discard it without reason. |
| `DEC` | Decide with `technology-evaluation`. Record material decisions as ADRs via `adr-management`. |
| `ASM` | Mark each design element that depends on the assumption. Prefer reversible choices where confidence is L (AP-11). |

**Mandated platform.** Design inside the mandated platform. Don't add other clouds, cross-cloud comparisons, or "portable alternatives" unless a constraint conflict forces the discussion. Inside that boundary, still challenge weak choices: an overweight framework, model misfit, duplicated orchestration, self-hosting economics, or a managed service that misses an NFR.

**Conflicts.** Never resolve a constraint conflict silently. Write a conflict entry under "Risks and Open Decisions" with four parts: the CON/PRH, the requirement it blocks, the options (relax the requirement, relax the constraint, or accept the risk) with their consequences, and the decision owner from the brief. Then stop and ask. An unresolved conflict blocks G3.

**Agnostic does not mean neutral.** The framework has no default vendor, but each design makes a decisive recommendation. List an alternative only when it has a specific reason to exist (a material trade-off, a fallback, procurement, an open strategic choice). List a rejected option only when that adds value, for example when a stakeholder proposed it.

**Knowledge layers.**

| Layer | Location | Use in this skill |
|---|---|---|
| A: Stable principles | `standards/` | Cite them. Never edit them from a use case. |
| B: Evolving technology knowledge | `knowledge/` (dated entries) | Start from it. Check `Last verified`. Re-verify if the entry is stale or the decision depends on it. |
| C: Use-case decisions | `use-cases/<id>/` | The output of this skill. **Never promote a layer-C decision into a standard or a knowledge default** without an explicit framework decision. |

**Time-sensitive facts.** Product capabilities, versions, regional availability, pricing, licensing, lifecycle status, and regulation: verify them through `technology-evaluation` using WebSearch/WebFetch, and label them per §3 with `(source: <URL>, accessed YYYY-MM-DD)`. If research tools aren't available in the session, say so in the design and mark the claim `[UNVERIFIED]` with a validation step.

## Workflow

Each step writes to a section of `02-design/solution-design.md`, which is copied from `templates/solution-design.md`. The required headings are in `docs/conventions.md` §3.

1. **Prepare.** Confirm the mode, tier, and classified inputs from the brief. List the CON/PRH IDs at the top of your working notes. Make sure `01-requirements/requirements.md` exists with measurable NFRs. If it doesn't, draft it, then run `nfr-validation` to surface NFR conflicts and infeasible targets early.
2. **Mode C baseline.** If this is Mode C, assess the existing design first (see "Mode C" below) before adding anything.
   *Specialist input during design (optional, T2+):* if a domain question blocks design progress (for example, feasibility of delegated access, or the agent toolset), brief the relevant specialist from the matrix in `docs/operating-model.md` §3, using the §4 brief format. Persist the report per §5. Don't treat a design-time consultation as the independent Phase D review. Phase D gets a fresh round with fresh briefs.
3. **Pattern selection (Solution Approach).** Climb the ladder in `standards/architecture-principles.md` §4. For every rung below the chosen one, write one line on why it isn't sufficient, citing an FR or NFR. Hybrids are normal: give the rung for each part. For rung ≥ 6, complete the agentic justification in `standards/agentic-ai-design-principles.md` §1, or step back down.
4. **Component decomposition (Component Catalogue).** For each component, record `C-##`, its responsibility (only one per component), owner, interface, the requirements it traces to, its state, and whether it's reused or new. If a component traces to nothing, remove it. If two components own the same responsibility, merge them (AP-04).
5. **Shared vs domain-owned capability.** For any capability that could be shared, run the assessment in the "Shared vs domain-owned capability" section below. Centralize only when doing so reduces duplication or risk without creating a bottleneck (AP-06, `standards/agentic-ai-design-principles.md` §6). **Don't build a central AI platform as an end in itself.**
6. **Interfaces and integration flows (Architecture Overview).** Cover the synchronous and asynchronous flows, contracts and schemas, versioning, idempotency keys for side-effecting calls, error semantics, and timeouts. Name the system of record for each entity.
7. **Technology selection.** Every open `DEC`, every evaluated `PREF`, and every new technology goes through `technology-evaluation`. For model choices, use its model-selection mode. Fill the stack table with component, technology and version, classification (CON/PREF/INV/DEC), evidence label, ADR, and lock-in and exit-cost note (AP-12). Create ADRs for material choices via `adr-management`.
8. **Trust boundaries, identity, and security (Security and Identity).** Draw the boundaries. Separate the user, workload, agent, and tool identities. Specify delegated-access semantics. Enforce authorization outside the model (AP-14). Gate consequential actions deterministically and/or with human approval. Add untrusted-content controls on every ingestion path, and keep secrets out of the model context. Apply `standards/security-and-identity.md`. At T2+, run `threat-modeling`.
9. **Data, knowledge, memory, and context (Data and Knowledge).** For each store: classification, owner, residency, retention, lineage, and permission trimming at retrieval. Define the scope and expiry of memory and context-window composition. Apply `standards/data-governance.md`.
10. **Agent design, only where step 3 justified it.** Cover the toolset and per-tool permissions, planning bounds (step limits, budget, timeouts), stop conditions, human checkpoints, and state. For multi-agent designs, record why each agent is separate. Apply `standards/agentic-ai-design-principles.md`.
11. **Runtime and deployment (Operations and Reliability).** Cover topology, environments, network paths, IaC approach, release strategy (shadow, canary, feature flags), and rollback. Use `knowledge/deployment-patterns.md`.
12. **Observability and evaluation.** Cover traces across model and tool calls, prompt and model version tagging, quality metrics, the offline evaluation set and release thresholds, online monitoring, and drift. Apply `standards/observability-and-evaluation.md`. At T3+, the detail goes in `05-validation/test-and-evaluation-plan.md`.
13. **Reliability and cost.** Cover failure modes for each dependency (model, tool, data store, integration unavailable), degraded modes, bounded retries, circuit breakers, quotas, RTO/RPO, and token or cost budgets per request and per month. Apply `standards/reliability-and-resilience.md`. Re-run `nfr-validation` against the design.
14. **Diagrams.** Run `architecture-diagrams`. At minimum, a context view and a container/component view. At T2+, add a trust-boundary view and a key sequence. Node names must match the `C-` IDs.
15. **Operational completeness check.** Fill the AP-13 table below. Every row says either *Designed (section)* or *Not required because …*.
16. **Risks and Open Decisions.** List `RSK-###` items with owners, open `DEC`s, constraint conflicts, and the ASMs that still need validation.
17. **Traceability.** Update `01-requirements/requirements.md` §Traceability with requirement → component → test mappings (T2+).
18. **Implementation readiness.** At T2+, run `implementation-roadmap`. Then hand off to `architecture-review` (Phase D) at the depth the tier requires.
19. **Validate.** Run `tools/validate-diagrams.sh use-cases/<id>` and `tools/validate-deliverables.sh use-cases/<id>`. Record the observed results.

### Scaling by tier

| Tier | Depth |
|---|---|
| T1 | A short design: ladder rationale, component table, stack table, the AP-13 table with brief entries, one diagram. ADRs are optional. |
| T2 | Full workflow. ADRs for material choices. Threat model. Roadmap. Review on contested decisions. |
| T3 | As T2, plus a test-and-evaluation plan, a full specialist review, debate, and red team before Phase F. |
| T4 | As T3, plus explicit autonomy limits, kill switches, DR test plans, regulator-facing evidence, and the full bench. |

## Shared vs domain-owned capability

For every candidate shared capability (gateway, retrieval, evaluation harness, agent runtime, memory, prompt store, tool gateway), answer the ten questions in `standards/agentic-ai-design-principles.md` §6 and apply its placement signals: problem solved, which use cases, existing capability, placement, sourcing, interface, identity and authorization, operations, cost, and consequence of not building. Record the answers in the Component Catalogue entry, or in an ADR when placement is material. The default is domain-owned. **Don't design a central AI platform as an end in itself.** If a capability is centralized for this use case, that's a layer-C decision. It doesn't become an enterprise standard without an explicit decision.

## Operational completeness (AP-13)

| Capability | Designed (section) / Not required because … |
|---|---|
| Identity and authorization (user, workload, agent, tool) | |
| Data protection (classification, encryption, residency, retention) | |
| Input/output safety and untrusted-content handling | |
| Failure handling and degraded modes | |
| Observability (logs, traces, metrics, audit trail) | |
| AI evaluation (offline set, thresholds, online monitoring) | |
| Deployment, release, and rollback | |
| Versioning and lifecycle (models, prompts, tools, schemas) | |
| Cost controls and budgets | |
| Capacity and scaling | |
| Backup, DR, RTO/RPO | |
| Human oversight and escalation | |
| Ownership and support model | |

## Mode C: improve a partial or constrained design

1. **Inventory** what exists, by path. Classify each element as CON, INV, or PREF. A prototype's choices are INV or PREF, not CON, unless the brief says otherwise.
2. **Assess** the strengths (what to keep), the gaps against the requirements and the AP-13 table, and the implicit assumptions. Turn each implicit assumption into an `ASM-###`.
3. **Challenge** weak choices with evidence, proportionately (`standards/architecture-principles.md` §7). Don't redesign what works.
4. **Fill only the gaps** that are needed. Mark each section as Retained, Corrected, or Added.
5. **Resolve conflicts** between the existing choices and the requirements, using the conflict procedure above.

## Outputs

- `use-cases/<id>/02-design/solution-design.md`, with all the headings required by `docs/conventions.md` §3
- `use-cases/<id>/01-requirements/requirements.md`, including §Traceability
- Through the composed skills: `02-design/technology-evaluation-<topic>.md`, `04-decisions/adr/ADR-NNN-<slug>.md`, `04-decisions/decision-log.md`, `05-validation/threat-model.md`, `05-validation/nfr-validation.md`, `06-delivery/implementation-roadmap.md`, and diagrams (inline or in `02-design/diagrams/`)

## Quality gates touched

G2 (traceability), **G3** (pattern and technology: primary), G4 (via `threat-modeling`), G7 (consistency: primary in Phase F), G9 inputs (operations design). Record the results in `05-validation/quality-gates.md`.

## Failure conditions

- **Stop and ask:** a CON or PRH conflicts with a Must requirement; the brief lacks a decision owner for a needed trade-off; a material ASM with confidence L would change the ladder rung or the platform.
- **Mark G3 FAIL:** lower rungs aren't ruled out; a rung ≥ 6 lacks an agentic justification; a material choice lacks evidence or an ADR; a constraint conflict is unresolved.
- **Mark G4 FAIL:** authorization for a consequential action depends on model reasoning.
- **Don't claim completion** while any AP-13 row is blank, or while validators haven't been run or have failed.

## References

- `standards/architecture-principles.md` (AP-01–AP-14, §2–§7), `standards/architecture-quality-gates.md`
- `standards/agentic-ai-design-principles.md`, `standards/security-and-identity.md`, `standards/data-governance.md`, `standards/observability-and-evaluation.md`, `standards/reliability-and-resilience.md`
- `knowledge/technology-catalog.md`, `knowledge/reference-architectures/README.md`, `knowledge/deployment-patterns.md`, `knowledge/model-selection-guide.md`
- `templates/solution-design.md`, `templates/requirements.md`, `templates/architecture-decision-record.md`
- Skills: `use-case-discovery`, `nfr-validation`, `technology-evaluation`, `threat-modeling`, `architecture-diagrams`, `adr-management`, `implementation-roadmap`, `architecture-review`, `architecture-debate`
- `docs/operating-model.md` §3–§5 (specialist briefs for design input)

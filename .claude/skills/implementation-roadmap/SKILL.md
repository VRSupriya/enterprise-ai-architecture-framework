---
name: implementation-roadmap
description: Turn an approved architecture into an executable engineering plan. Covers workstreams, milestones, dependencies, platform prerequisites, a traced BL- backlog with acceptance criteria, CI/CD and environments, testing, observability, operational readiness, progressive rollout, numeric rollback triggers, runbooks, and Mode B migration such as strangler fig or parallel run. Use for "implementation plan", "roadmap", "backlog", "rollout plan", "migration plan", "production readiness", or the G9/G10 gates.
argument-hint: "<use-case-id> [scope: full | backlog | rollout | migration]"
---

# Implementation Roadmap

## Purpose

Produce `06-delivery/implementation-roadmap.md`: the plan that takes the target architecture to production safely. It sequences the work thin-slice first, traces every backlog item to the requirements, decisions, and threats it implements, and defines **numeric** production-readiness and rollback criteria. It also defines the operational chain SLO → alert → owner → runbook. It is the primary evidence for G9 and feeds G10.

## When to use / not use

| Use when | Don't use when |
|---|---|
| The target architecture is synthesized and its material ADRs exist (Phase H) | The design is unsettled, or Critical findings are open. Finish `architecture-review` or `architecture-debate` first. A roadmap built on an unsettled design will need rework. |
| Mode B: a remediation and migration plan is needed after `architecture-review` | The user only wants effort estimates or dates. This skill uses relative sequencing unless dates are supplied. |
| An ADR is superseded and its migration work must be planned | |

## Inputs

| Input | Path |
|---|---|
| Requirements, traceability, ASMs | `01-requirements/requirements.md` |
| Target design, component catalogue | `02-design/solution-design.md` (Mode B: also `03-review-board/review-report.md` §Target Architecture and §Remediation Roadmap) |
| Decisions | `04-decisions/adr/`, `04-decisions/decision-log.md` |
| Threats and mitigations | `05-validation/threat-model.md` |
| NFR verdicts, SLO targets | `05-validation/nfr-validation.md` |
| Tests and release criteria | `05-validation/test-and-evaluation-plan.md` |
| Template | `templates/implementation-roadmap.md` |

## Workflow

### Step 1. Set depth by tier

| Tier | Depth | Specialists |
|---|---|---|
| T1 | Short plan: workstreams, 2–3 milestones, backlog in the roadmap, a rollback note. ○ G9. | None |
| T2 | Full template. Thin-slice phasing, traced backlog, readiness table, staged rollout with numeric triggers. ◐ G9/G10. | Brief `reliability-llmops-architect` on readiness and rollout |
| T3 | T2 plus runbooks for each paging alert, a tested DR plan or one scheduled before go-live, shadow or canary stage, separate backlog file if large. | `reliability-llmops-architect`, `integration-infrastructure-architect`. `security-identity-architect` for control-implementation sequencing. |
| T4 | T3 plus a kill switch, per-action rollback or compensation plan, a game day before GA, and independent challenge of the readiness criteria. | As T3, plus `red-team-architect` on the rollout and rollback plan |

Copy `templates/implementation-roadmap.md` to `use-cases/<id>/06-delivery/implementation-roadmap.md`. Keep the required headings: **Workstreams · Milestones · Dependencies · Operational Readiness · Rollout and Rollback · Risks**.

### Step 2. Define workstreams and ownership

Group the work into `WS-` workstreams by component ownership, not by activity. Typical workstreams are: platform and environments; component implementation (per owning team); integration; security and governance controls; data and knowledge; evaluation and testing; observability and operations; rollout and change management. Each has a lead **role or team** (use team names only if the user supplied them), components in scope (`C-`), and key outputs. Fill the **Ownership and Skills** table and flag skill gaps with a plan.

**Don't invent dates or team names.** Use relative sequencing ("After MS-02") and roles unless the user gives them. If a deadline is a CON, test the plan against it and report any conflict.

### Step 3. Phase thin-slice first

| Slice | Content | Must include from day one |
|---|---|---|
| **Slice 1: walking skeleton** | One end-to-end journey through every architectural layer, at minimal function: client → gateway → orchestrator → one model call → one read-only tool or retrieval → response | Real identity (no shared test keys), authorization at the tool layer, secrets from the secrets manager, tracing and audit logging, cost metering, CI pipeline with the evaluation harness running (even on a small set), IaC-provisioned environments |
| Slice 2: core capability | The Must FRs on the main journey; evaluation set at release size | Guardrails and injection controls for every ingestion path added; threat tests (`TST-`) automated |
| Slice 3: side effects | The first write or side-effecting tool, behind approval and feature flag | Parameter-bound approval, idempotency, compensation or rollback, audit chain |
| Slice 4+: breadth and hardening | Remaining FRs, scale, DR, degraded modes | Load, resilience, and DR tests run; runbooks complete |

Security and observability are **never** a final phase. A backlog where they appear only after the features is a failure condition.

### Step 4. Milestones and dependencies

- `MS-` milestones with a relative sequence, an **exit criterion that can be observed** (a test passes, a gate passes), and the gate they evidence (G8/G9/G10).
- **Dependencies table:** external or cross-team items (platform onboarding, network paths, access approvals, data access agreements, procurement, model quota). Give each a needed-by milestone, the provider, the status, and the risk if late. Start long-lead items in slice 1.
- **Platform prerequisites checklist:** environments, identity registrations, network and private connectivity, secrets, model endpoint access and quota, gateway onboarding, logging and tracing sinks, evaluation tooling, CI/CD runners, feature-flag service.

### Step 5. Build the engineering backlog

Create `BL-` items at **component level**: one deliverable change to one component or integration, small enough to verify.

| Rule | Detail |
|---|---|
| Trace | Each item lists the FR/NFR/ADR/T-/RSK IDs it implements. Each Must FR, each NFR, and each threat mitigation maps to at least one BL item. Check by walking the traceability table and the threat table. |
| Acceptance criterion | Observable and tied to a `TST-` or `EVAL-` where one exists, e.g. "TST-021 passes; mismatched payee blocks posting" |
| Coverage areas | Component implementation, integration contracts, security controls (each mitigation), CI/CD and IaC, tests and evaluation, observability (dashboards, alerts), runbooks, data migration, decommissioning (Mode B) |
| Placement | Small backlog: in the roadmap's **Backlog** section. Large backlog (roughly more than 40 items, or T3+): `06-delivery/backlog.md` with the same columns, and the roadmap keeps a summary per workstream plus a link. |
| Status | Not started · In progress · Done (with evidence) · Withdrawn. Keep IDs stable. |

### Step 6. Environments and CI/CD

Fill the **Environments and CI/CD** table: the purpose of each environment, what data it may hold (synthetic, masked, production), and its promotion gate. The pipeline must treat **prompts, tool definitions, model versions, guardrail rules, and evaluation sets as versioned artifacts** that go through the same gates as code (AP-08). Use the CI/CD pattern from `architecture-diagrams` if a diagram is needed.

### Step 7. Operational readiness

Build the chain for every SLO and key signal from `nfr-validation.md`:

`SLO / signal → alert condition (numeric, with window) → owner (on-call role) → runbook → status`

Include at least: latency, error rate, availability, AI quality on a production sample, safety and guardrail trigger rate, cost per request or day, approval backlog and override rate (if humans approve actions), and dependency health (model provider, tools). Also cover the support model (tiers, hours, escalation), capacity and quota management, backup and DR (RTO/RPO with test status), and the kill switch (T3+).

**Runbooks** go in `06-delivery/runbooks/<signal-or-scenario>.md`. Write one for each paging alert at T3+, and for at least latency, quality drift, and cost spike at T2. Each runbook contains: trigger, impact, diagnosis steps, containment (flag off, route to fallback, throttle, roll back version), recovery, escalation, and post-incident actions. Reference `standards/observability-and-evaluation.md` and `standards/reliability-and-resilience.md` for principles.

### Step 8. Rollout and rollback

Design progressive exposure, choosing only the stages that are relevant:

| Stage | When to use |
|---|---|
| Offline evaluation only | Always, before any exposure |
| Shadow mode (output computed, not used) | Replacing a human or system decision, or quality uncertain |
| Internal or pilot cohort behind a feature flag | Any user-facing change |
| Canary (percentage of traffic) | High volume, stateless paths |
| General availability | After the stable-period criterion |

For each stage: exposure, **advance when** (numeric), **roll back when** (numeric threshold plus window, e.g. "error rate > 2% for 15 min", "accuracy < 90% over 200 audited items", "cost/request > 2× target for 24 h"), the rollback action (flag off, revert prompt or model version, route to the manual path), and who decides. Thresholds must match the test plan's release criteria and rollback triggers. **Production-readiness criteria** are the gating release criteria plus every G9 checklist item, each with evidence.

### Step 9. Mode B: migration plan

Preserve existing functionality while moving to the target:

| Strategy | Use when | Verification |
|---|---|---|
| Strangler fig | Capabilities can be routed one by one behind a facade | Per-route parity tests; traffic shifted per capability with rollback |
| Parallel run | Outputs can be compared, and correctness matters more than cost | Agreement rate ≥ threshold over N items before cutover; discrepancies triaged |
| Data migration with verification | Stores change | Record counts, checksums, sampled field-level comparison, reconciliation report, rollback snapshot |
| Big-bang cutover | Only if the others are infeasible; record why in an ADR | Full regression plus rehearsed rollback |

List the functionality inventory (existing FRs and behaviors), map each to its target component, define parity criteria, and plan decommissioning only after the parity evidence exists. Link back to `review-report.md` §Remediation Roadmap: mandatory remediations come first.

### Step 10. Risks, review, and gates

- **Risks:** delivery risks as `RSK-` rows (likelihood, impact, mitigation, owner). Include "At risk" NFR verdicts and open ASMs with deadlines.
- **Review:** for T2+, brief `reliability-llmops-architect` (and the others per tier) with paths to the draft roadmap, the NFR validation, and the test plan. Save the reports under `03-review-board/round-<n>/`.
- **Gates:** record the G9 evidence (readiness table, runbooks, rollback criteria). For G10, list the approvers (role, or name if supplied), the mandatory remediation status, and lifecycle items: versioning, re-evaluation cadence, ADR revisit triggers, and retirement criteria. Record the results in `05-validation/quality-gates.md`.
- Run `tools/validate-deliverables.sh use-cases/<id>` and report the actual output.

## Outputs

| Artifact | Path |
|---|---|
| Roadmap | `use-cases/<id>/06-delivery/implementation-roadmap.md` (from `templates/implementation-roadmap.md`) |
| Backlog (if large) | `use-cases/<id>/06-delivery/backlog.md` |
| Runbooks | `use-cases/<id>/06-delivery/runbooks/<scenario>.md` |
| Delivery risks | `use-cases/<id>/01-requirements/requirements.md` (`RSK-`) and the roadmap §Risks |
| Gate evidence | `use-cases/<id>/05-validation/quality-gates.md` (G9, G10) |

## Quality gates touched

- **G9 Operational readiness.** Primary.
- **G10 Production approval & lifecycle governance.** Approvers, remediation status, lifecycle.
- **G8.** Release thresholds and rollback triggers are numeric and consistent with the test plan.
- **G2/G7.** Backlog traceability exposes orphan requirements or components.

## Failure conditions

- Security, identity, or observability work appears only after feature slices.
- A Must FR, NFR, or threat mitigation has no BL item, or a BL item has no trace or acceptance criterion.
- Rollback or advance criteria are non-numeric ("if quality drops").
- An SLO has no alert, owner, or runbook (T2+ for paging signals).
- Dates or team names are invented.
- Mode B decommissions functionality before parity evidence exists.
- The plan depends on an "Infeasible under constraints" NFR or an open Critical finding without a recorded decision.
- Readiness is claimed without evidence (gate blocking rule).

## References

- `templates/implementation-roadmap.md`, `templates/test-and-evaluation-plan.md`, `templates/quality-gates.md`
- `standards/reliability-and-resilience.md`, `standards/observability-and-evaluation.md`, `standards/security-and-identity.md`
- `standards/architecture-quality-gates.md` (G8–G10 checklists), `standards/architecture-principles.md` (AP-08, AP-13)
- `knowledge/deployment-patterns.md`
- `.claude/agents/reliability-llmops-architect.md`, `.claude/agents/integration-infrastructure-architect.md`
- Related skills: `nfr-validation`, `threat-modeling`, `adr-management`, `architecture-diagrams` (CI/CD and ops patterns), `architecture-review` (Mode B input)

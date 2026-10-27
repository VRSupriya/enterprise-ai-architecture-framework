---
name: architecture-review
description: Independent, evidence-based review of an existing or proposed architecture. Establishes a baseline (intended vs implemented), runs parallel independent specialist assessments, and consolidates F-BRD findings with severity, dispositions, mandatory and recommended remediation, and a transition plan. Use for Mode B, the Phase D review of a new design, or when asked to "review this architecture", "assess our system", "audit this design", "is this production-ready", or "what's wrong with our stack".
argument-hint: "<use-case-id> [paths to architecture, code, IaC, or diagrams]"
---

# Architecture Review

## Purpose

Give a defensible, independent judgment of whether an architecture meets its requirements and constraints, what must change, and in what order. The review produces findings that a decision owner can act on and a verifier can check. Each finding carries evidence, a basis, a severity, an owner, and an acceptance criterion. The review assumes nothing: an existing design isn't right because it's built, or wrong because something newer exists (`standards/architecture-principles.md` §7).

## When to use / when not to use

| Use when | Don't use when |
|---|---|
| Mode B: an existing system, code, IaC, or diagrams | No requirements or intent can be established. Run `use-case-discovery` first |
| Phase D: independent review of a design from `architecture-design` | You only need one domain check, such as a threat model. Run that skill as a focused task |
| A formal readiness review before G10 | You want to settle a contested decision. Use `architecture-debate` after this skill |

## Inputs

- `00-intake/use-case-brief.md` (classified inputs, tier, and, in Mode B, the baseline). If it's missing, run `use-case-discovery`.
- `01-requirements/requirements.md`, if it exists. In Mode B, missing requirements are themselves a finding.
- The subject: `02-design/solution-design.md` (Phase D), or user-provided source paths (Mode B).
- Optional: prior rounds in `03-review-board/round-*/`, existing ADRs, run evidence (test or evaluation results, dashboards, incident reports).

## Workflow

### 1. Establish the baseline (Scope and Baseline)

Record each item with the evidence path, or "not provided".

| Baseline item | What to capture |
|---|---|
| Intent | What the system is meant to achieve: objectives, users, success metrics |
| Implementation | What is actually built. Inspect code, IaC, configs, pipelines, and prompts **when provided**. List exactly what you inspected. |
| Requirements | Documented vs missing FRs and NFRs. Measurable or not. |
| Mandatory constraints | CON/PRH items, and whether the implementation complies with each |
| Assumptions | Explicit ASMs, plus implicit assumptions found in the design (record them as new ASMs) |
| Components and dependencies | Provisional `C-##` catalogue, external dependencies, owners |
| Evidence available | Tests, evaluation results, monitoring, incidents. Mark anything not available as "not tested". |

Never report something you didn't inspect as verified. Where documentation and implementation diverge, record both and treat the divergence as a finding.

### 2. Plan the bench

Select specialists with the matrix in `docs/operating-model.md` §3, scaled by tier:

| Tier | Bench | Review depth |
|---|---|---|
| T1 | Coordinator self-check with the [review checklist](references/review-checklist.md), plus `solution-architect` and at most one domain specialist | Must-have checks only |
| T2 | solution, security-identity, reliability-llmops, plus agentic if AI is present. Red team on contested decisions. | Full checklist for the domains in scope |
| T3 | T2 + data-knowledge-memory, integration-infrastructure, red-team (always) | Full checklist and full baseline |
| T4 | All nine | Full checklist, with evidence demanded for every Must requirement |

Give each specialist a scope that doesn't overlap with the others (`docs/operating-model.md` §4 item 4). Map the checklist dimensions to specialists so each dimension has one owner.

### 3. Brief the specialists in parallel and independently

Use the brief format in `docs/operating-model.md` §4. Launch all round-1 Agent calls in **one message**. Each brief includes:
- the use-case id, mode, tier, and the question the specialist must answer
- the input paths (don't paste content), plus the CON/PRH list in full
- the assessment dimensions this specialist owns, with a pointer to the [review checklist](references/review-checklist.md) and [severity rubric](references/severity-rubric.md)
- in round 1, **no other specialist's conclusions**. The red team only ever gets the proposal on its first pass.
- the research instruction and the date to cite
- "Return your report in the format defined in your agent instructions (`docs/conventions.md` §5). Don't write files."

### 4. Persist the reports

Save each returned report verbatim to `03-review-board/round-<n>/<agent-name>.md`, with a header containing the brief summary and the date (`docs/operating-model.md` §5). Use the next unused round number, and never overwrite earlier rounds.

### 5. Assess across the dimensions

Make sure each dimension below is covered by a specialist or by the coordinator. Fill gaps yourself, using the checklist.

Requirement coverage · Coherence · Complexity and duplication · Functional completeness · NFR feasibility · Security and governance · Integration · Data · Agentic necessity · Model and framework choice · Resilience · Observability and evaluation · Deployment and operations · Cost and maintainability · Lock-in · Implementation maturity · Evidence and traceability

### 6. Consolidate findings (Findings)

Merge the specialist findings into board findings `F-BRD-##`. Keep the source IDs (for example, `F-SE-03`) for traceability. De-duplicate them, and keep the highest justified severity, rated per the [severity rubric](references/severity-rubric.md).

| Field | Content |
|---|---|
| ID | `F-BRD-##` (sources: `F-SE-03`, …) |
| Severity | Critical / High / Medium / Low, per the rubric |
| Affects | `C-##`, `FR-`/`NFR-`/`CON-` ID |
| Evidence / source | File path and line or section, command output, or URL with access date |
| Basis | Verified fact · Assumption · Inference · Unverified concern |
| Issue | What is wrong, stated specifically |
| Impact | The consequence if it isn't fixed |
| Likelihood / confidence | Qualitative, per rubric §4 |
| Remediation | A concrete change. Class: Mandatory / Recommended / Optional / Future |
| Owner | A named team or role from the brief |
| Acceptance criterion | An observable condition that closes the finding |
| Verification method | Test, evaluation, inspection, or demonstration |

Remediation classes: **Mandatory** means it must close before the next gate (all Critical findings, and High findings unless formally waived). **Recommended** means it should close before production. **Optional** is an improvement with a positive but small return. **Future** means deferred, with a trigger.

Specialist disagreements, and High or Critical findings that are disputed, go into a conflict register (`docs/operating-model.md` §6) for `architecture-debate`.

### 7. Disposition each component (Disposition)

| Component | Disposition | Rationale (finding IDs) | Conditions |
|---|---|---|---|

Dispositions: **Retain** (fit for purpose) · **Improve** (keep, with targeted remediation) · **Replace** (doesn't meet requirements, and remediation costs more than replacing it) · **Consolidate** (duplicates another capability) · **Remove** (traces to no requirement) · **Defer** (not needed for the current scope) · **Investigate** (the evidence isn't sufficient to decide; state what evidence would settle it).

Replacement needs evidence that targeted remediation won't suffice. Prefer Improve where it meets the requirements.

### 8. Target and transition architecture (Target Architecture)

- In Mode B, produce the target via `architecture-design` (Phase F), and summarize it here with a link to `02-design/solution-design.md`.
- When an immediate replacement isn't feasible, define a **transition architecture** in the report's "Transition Architecture" section: the interim state, the compensating controls for the open findings, and the exit criteria.
- Material changes become ADRs via `adr-management`. Diagrams for the current, transition, and target states go through `architecture-diagrams`.

### 9. Remediation Roadmap

Phase the remediation. Phase 0 is containment (Critical findings and compensating controls). Phase 1 covers the Mandatory items before the next gate. Phase 2 covers the Recommended items before production. Phase 3 covers the Optional and Future items. Each item links to its `F-BRD` ID, owner, dependency, and verification method. At T2+, hand off to `implementation-roadmap` for workstreams and backlog.

### 10. Debate, red team, gates

- If the conflict register isn't empty, or a Critical or High finding is contested, run `architecture-debate`.
- At T3/T4, after synthesis, run the red-team second pass per `docs/operating-model.md` §6 item 5.
- Record G5 (and G6 where applicable) in `05-validation/quality-gates.md`. Run `tools/validate-deliverables.sh use-cases/<id>` and report the observed result.

## Outputs

- `use-cases/<id>/03-review-board/round-<n>/<agent-name>.md` (verbatim specialist reports)
- `use-cases/<id>/03-review-board/review-report.md`, from `templates/review-report.md`, with the required headings: Scope and Baseline · Findings · Disposition · Target Architecture · Remediation Roadmap
- Inputs to `03-review-board/debate-record.md`, `04-decisions/adr/`, and `05-validation/quality-gates.md`

## Quality gates touched

**G5 Architecture review** (primary). G6 (red-team independence; the input to debate). Supporting evidence for G2, G3, G4, G7, G9, and G10. An open Critical finding blocks G5 and G10 (`standards/architecture-quality-gates.md` §3).

## Failure conditions

- **Stop and ask** when the intent and requirements can't be established, when a requested artifact needed for a Must check is unavailable, or when a finding implies that a CON must change.
- **Mark G5 FAIL** when a Critical finding is open, when a required specialist for the tier didn't review, or when findings lack evidence or a basis.
- **Mark G6 FAIL** if the red team's first pass saw other specialists' conclusions.
- **Don't** inflate severity to force a redesign, or downgrade it to pass a gate (rubric §6). **Don't** claim you executed or inspected anything you didn't.

## References

- [Review checklist](references/review-checklist.md) · [Severity rubric](references/severity-rubric.md)
- `docs/operating-model.md` §3–§6, `docs/conventions.md` §2, §3, §5
- `standards/architecture-principles.md`, `standards/architecture-quality-gates.md`, and the domain standards in `standards/`
- `templates/review-report.md`, `templates/quality-gates.md`
- Skills: `use-case-discovery`, `architecture-design`, `architecture-debate`, `adr-management`, `architecture-diagrams`, `threat-modeling`, `nfr-validation`, `implementation-roadmap`

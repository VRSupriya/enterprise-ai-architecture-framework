---
name: architecture-debate
description: Runs a structured, evidence-driven board challenge of material architecture decisions. Specialists challenge independently, credible alternatives are compared, rebuttals are mediated (max 2 rounds), and decisions are made on evidence and requirements, never by vote. Records accepted and rejected arguments, residual risks, and unresolved decisions. Use for Phase E, contested decisions, or Critical/High findings, or when asked to "challenge this design", "stress-test", "debate the options", "red-team this decision", or "convene the board".
argument-hint: "<use-case-id> [ADR or decision IDs to challenge]"
---

# Architecture Debate

## Purpose

Test material decisions against their strongest objections before they become the target architecture. The output is a decision that survives scrutiny, or one that's been changed or escalated, with the reasoning on record. This skill implements the conflict-resolution procedure in `docs/operating-model.md` §6. It's the primary evidence for G6.

## When to use / when not to use

| Use when | Don't use when |
|---|---|
| The review's conflict register isn't empty, or a Critical or High finding is disputed | **T1:** skip the debate. Record the decisions as ADRs. |
| A material decision is contested by a specialist, the red team, or a stakeholder | **T2 with no contested decisions:** skip it, and note "No material objections" in the quality-gates record. |
| T3/T4: always, covering every material decision and including the red team | The disagreement is factual and one research step settles it. Run `technology-evaluation` instead. |
| The user asks for an independent challenge | It would be a debate for its own sake. Don't manufacture disagreement (`standards/architecture-principles.md` §7). |

## Inputs

- `02-design/solution-design.md` (version under challenge), the relevant ADRs in `04-decisions/adr/`
- `03-review-board/round-<n>/*.md` and the conflict register from `architecture-review` (if run)
- `00-intake/use-case-brief.md` (CON/PRH, decision owners), `01-requirements/requirements.md`

## Workflow

Copy `templates/debate-record.md` to `use-cases/<id>/03-review-board/debate-record.md`. Objection IDs use `DBT-##`.

1. **Present the proposal and constraints (Proposal).** Name the exact decisions under challenge (ADR IDs, design version), the requirements they serve, and the binding CON/PRH items. Debate only material decisions: those that change the ladder rung, trust boundaries, platform, data stores, consequential-action control, or a Must NFR.
2. **Identify the strongest objections.** From the conflict register and the specialist reports, extract each candidate objection and state it in its *strongest* form (steelman it). Merge duplicates. Discard objections that don't affect a requirement, constraint, or principle, and record why.
3. **Specialists challenge independently.** If a decision hasn't been independently reviewed yet, brief the relevant specialists in parallel per `docs/operating-model.md` §4. For T3/T4, always include `red-team-architect`. **The red team's first pass gets only the proposal, the requirements, and the constraints. It never gets other specialists' conclusions.** Persist the reports to `03-review-board/round-<n>/<agent-name>.md`.
4. **Compare credible alternatives.** For each objection that proposes another approach, compare it to the proposal against the prioritized requirements, using `technology-evaluation` where facts are time-sensitive. Include the simpler-rung alternative whenever the proposal sits at rung ≥ 4. Exclude anything a PRH forbids. Don't invent alternatives to look balanced.
5. **Require responses to material objections.** Send a rebuttal brief to each involved specialist. It contains the opposing position, its evidence and label, and the instruction "Concede, refine, or rebut with evidence." **One rebuttal round by default, two at most**, unless genuinely new evidence appears. Persist each round as `round-<n+1>/`.
6. **Resolve on evidence and requirements.** Classify each conflict as factual (settle with evidence or research), trade-off (settle by requirement priority), or value/strategy (escalate to the named human decision owner). The chair decides. **A majority vote never substitutes for evidence**: five specialists agreeing on an unverified claim is still an unverified claim. When the evidence is asymmetric, say so plainly. Don't present the two sides as equal.
7. **Record accepted and rejected arguments (Objections, Resolutions).** Give every DBT item a response and an outcome of Accepted, Rejected (with a reason), or Escalated (owner and date). Accepted outcomes become changes in the design, ADRs (via `adr-management`: a new or superseding ADR, never an edit that erases history), or backlog items.
8. **Document residual risks and unresolved decisions (Residual Risks, Unresolved Disagreements).** Each residual risk gets an `RSK-` ID, a named acceptor, and a monitoring or revisit trigger. Each unresolved disagreement gets both positions with their best evidence, the evidence that would resolve it, a decision owner, and a needed-by point.

Then answer the board questions, and, for T3/T4, run the red-team second pass: give it the synthesized target plus this record, and ask whether the remediations are sufficient (`docs/operating-model.md` §6 item 5). A new Critical from that pass reopens step 2 for that item only.

### Board questions

Answer each briefly, with IDs, in the record's Board Questions section. "Unknown" is acceptable when it's paired with an `ASM-` or `Q-` item.

| # | Question |
|---|---|
| 1 | Which requirements does the proposal satisfy, and with what evidence? |
| 2 | Which requirements are unmet, or met only on an unverified claim? |
| 3 | Why is this better than the simpler alternatives (lower ladder rungs, existing capability)? |
| 4 | Does it duplicate an existing enterprise capability? |
| 5 | What are the key trust boundaries and failure modes? |
| 6 | What happens when a model, tool, database, or integration is unavailable? |
| 7 | How are consequential actions authorized and controlled, outside the model? |
| 8 | Is it testable, observable, auditable, rollback-able, and supportable? |
| 9 | Which choices depend on assumptions or on time-sensitive facts, and when must they be re-verified? |
| 10 | What are the largest residual risks, and who accepts them? |
| 11 | What must be fixed before production? |
| 12 | What is centralized, and what is domain-owned, and why (`standards/agentic-ai-design-principles.md` §6)? |

### Stop conditions

Stop debating an item when it's resolved, when the evidence is asymmetric and documented, or when it's escalated to a human. Don't run a third rebuttal round without new evidence, and don't reopen a resolved item without a new fact.

### Scaling by tier

| Tier | Debate scope |
|---|---|
| T1 | Skip. Decisions go to ADRs. Use the coordinator's self-check only. |
| T2 | Only contested material decisions. A lightweight record. Red team only on contested decisions. |
| T3 | All material decisions. Full record. Red team blind first pass plus a second pass. |
| T4 | As T3, plus explicit escalation of every value/strategy conflict to the named owners before Phase F, and the full bench where relevant. |

## Outputs

- `use-cases/<id>/03-review-board/debate-record.md`, with the required headings Proposal · Objections · Resolutions · Residual Risks
- `use-cases/<id>/03-review-board/round-<n>/<agent-name>.md` (challenge and rebuttal rounds, verbatim)
- New or superseding ADRs in `04-decisions/adr/` and updates to `04-decisions/decision-log.md`, via `adr-management`
- The G6 row in `05-validation/quality-gates.md`

## Quality gates touched

**G6 Independent challenge** (primary). It feeds G3 (decision rationale), G4 (authorization outcomes), G5 (closing contested findings), and G10 (residual-risk acceptance).

## Failure conditions

- **Mark G6 FAIL** if the red team's first pass saw other specialists' conclusions, if any material objection lacks an outcome, or if an outcome rests on head count rather than evidence.
- **Stop and ask** when a resolution would change a CON/PRH, or when a value/strategy conflict has no named decision owner. Record it as Escalated, not Resolved.
- **Don't** declare consensus that the record doesn't show. Don't hide a dissent. Don't treat an unverified claim as settled because no one rebutted it.

## References

- `docs/operating-model.md` §4–§6, `docs/conventions.md` §2, §3
- `standards/architecture-principles.md` §3, §5, §7, `standards/architecture-quality-gates.md` (G6)
- [Severity rubric](../architecture-review/references/severity-rubric.md)
- `templates/debate-record.md`, `templates/architecture-decision-record.md`
- Skills: `architecture-review`, `technology-evaluation`, `adr-management`, `architecture-design` (Phase F synthesis)

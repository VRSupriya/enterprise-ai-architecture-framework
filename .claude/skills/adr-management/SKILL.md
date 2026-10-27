---
name: adr-management
description: Create, maintain, and supersede Architecture Decision Records and the decision-log index. Decides what is ADR-worthy, writes ADRs from the template with traced requirements, dated evidence, alternatives, consequences, and revisit triggers, and runs revisit mode ("Re-evaluate ADR-004") with supersession that preserves history. Use for "write an ADR", "record this decision", "decision log", "supersede", "re-evaluate ADR-NNN", or the G3 gate.
argument-hint: "<use-case-id> [new <topic> | revisit ADR-NNN | log]"
---

# ADR Management

## Purpose

Keep a complete, honest, append-only record of the material architecture decisions for one use case. Each ADR traces to requirements and constraints, cites dated evidence, records the options considered, and states when the decision must be revisited. The decision log is the index. History is never rewritten: decisions change by **supersession**, never by edits or deletion.

## When to use / not use

| Use when | Don't use when |
|---|---|
| A material decision is made or proposed (Phase C/F), or a debate outcome is material (`architecture-debate`) | The choice is a design note (see the significance test below). Record it in the solution design instead. |
| A revisit trigger fires, or the user asks to re-evaluate an ADR | You still need to compare options. Run `technology-evaluation` first, and this skill records the result. |
| A Mode B review finds an undocumented decision that must be made explicit (record it as an as-is ADR, status Accepted, with "Recorded retrospectively" in Context) | You'd copy another use case's ADR. That's never allowed without re-validation (see rules). |

## Significance test: ADR or design note?

Write an ADR if **any** of these is true. Otherwise it's a design note in `02-design/solution-design.md`.

| Criterion | Examples (ADR-worthy) | Design note instead |
|---|---|---|
| Hard or costly to reverse | Model hosting approach, vector store, orchestration framework, data residency topology | Library choice for date parsing |
| Crosses team or ownership boundaries | Using the enterprise AI gateway, a shared identity pattern | Internal module structure |
| Constraint-sensitive | Anything that touches a CON or PRH, or requests an exception | Naming conventions |
| Affects a security or trust boundary | Delegated vs service identity for tools, approval model | Log format |
| Picks a solution-ladder rung ≥ 4, or agent or multi-agent topology | Single bounded agent vs workflow plus LLM step | Prompt wording |
| Accepts material residual risk or lock-in (AP-12) | Proprietary API dependency with exit-cost estimate | — |
| Resolves an NFR conflict or a board debate | Latency vs quality routing decision | — |

**Tier minimums:** T1: ADRs optional (◐ G3). T2: at least one ADR (`docs/conventions.md` §4). T3/T4: every material decision in the technology selection table has an ADR.

## Inputs

| Input | Path |
|---|---|
| Requirements, constraints, assumptions | `01-requirements/requirements.md` |
| Design and technology selection | `02-design/solution-design.md`, `02-design/technology-evaluation-<topic>.md` |
| Debate outcomes | `03-review-board/debate-record.md` |
| Existing ADRs and log | `04-decisions/adr/`, `04-decisions/decision-log.md` |
| Template | `templates/architecture-decision-record.md` |

## Workflow: create mode

1. **Check significance** with the test above. If it fails, write a design note and stop.
2. **Allocate the ID.** Next unused 3-digit number in `04-decisions/adr/`, including Superseded, Rejected, and Withdrawn ones. Never reuse a number. Slug: lowercase kebab, naming the choice, e.g. `ADR-003-use-enterprise-ai-gateway.md`.
3. **Copy** `templates/architecture-decision-record.md` to `use-cases/<id>/04-decisions/adr/ADR-NNN-<slug>.md`. Keep the required headings: **Status · Context · Decision · Alternatives Considered · Consequences · Revisit Triggers**.
4. **Fill every field** (depth per tier, as the template guidance says):

| Field | Section | Rule |
|---|---|---|
| ID and title | H1 | Phrase the title as the choice made |
| Status | Status | Proposed · Accepted · Rejected · Deprecated · Superseded by ADR-NNN |
| Decision owner, approval status | Status | A role, or the name the user supplied. "Accepted" requires an approver and date. Otherwise it stays Proposed. |
| Context and driving requirements | Context | Problem and forces. Table of FR/NFR/RSK IDs and why each matters. |
| Mandatory constraints and assumptions | Context | CON/PRH/ASM/INV/PREF IDs and their effect on the options |
| Evaluation criteria | Context | Each derived from a requirement ID. Weights optional. |
| Chosen option and rationale | Decision | One recommended option (`standards/architecture-principles.md` §5), with rationale tied to the criteria |
| Evidence and research dates | Decision | Each material claim gets an evidence label, a source, and an access date. Time-sensitive vendor claims must be researched, not recalled. |
| Alternatives considered | Alternatives Considered | Chosen, alternative (only with a specific reason to exist), rejected (only when valuable) |
| Rejected alternatives and reasons | Alternatives Considered | Reason by requirement or constraint ID, plus "would reconsider if" |
| Consequences | Consequences | Positive, negative, lock-in and exit cost (AP-12), operational impact |
| Residual risks | Consequences | `RSK-` IDs with a named acceptor and monitoring |
| Dependencies | Consequences | Other ADRs, platforms, teams, contracts, with status |
| Revisit triggers | Revisit Triggers | Concrete and observable: a threshold, event, or date. Link the NFR or ASM it watches. "When technology changes" is not a trigger. |

5. **Update the decision log** (`04-decisions/decision-log.md`, created on first use) with this index table, one row per ADR, ordered by ID:

```markdown
| ADR | Title | Status | Date | Decision owner | Supersedes | Superseded by | Driving IDs | Revisit triggers (short) |
|---|---|---|---|---|---|---|---|---|
| ADR-001 | Use the enterprise AI gateway for all model access | Accepted | YYYY-MM-DD | Platform architect | — | — | NFR-003, CON-002 | Gateway p95 overhead > 200 ms |
```

6. **Trace.** Add the ADR ID to the ADR(s) column of the **Traceability** table in `requirements.md` for each driving requirement, and to the technology selection table in the solution design.
7. **Diagrams.** If the decision changes a component or technology, run `architecture-diagrams` to update the affected views (G7).
8. **Review (T3+).** If the decision is contested or High-impact, route it through `architecture-debate` before you mark it Accepted.

## Workflow: revisit mode ("Re-evaluate ADR-NNN")

Follows `docs/operating-model.md` §8.

1. **Confirm the trigger.** Identify which listed revisit trigger fired, or what new fact, requirement, or incident justifies reopening. Record the evidence. If no trigger fired and nothing material changed, report that and stop. Don't re-litigate settled decisions without cause.
2. **Re-run `technology-evaluation`** with fresh, dated research, against the **current** requirements and constraints. Re-check any ASM the original depended on.
3. **Targeted review.** For T3+, brief the relevant specialist(s) and/or `red-team-architect` (`docs/operating-model.md` §4).
4. **Outcome A, the decision stands.** Don't create a new ADR. Append a dated line under the old ADR's Revisit Triggers, e.g. `Re-evaluated YYYY-MM-DD: trigger <x>; decision confirmed; see 02-design/technology-evaluation-<topic>.md`, and update the triggers if needed. This is the only body edit allowed on an accepted ADR, and it's an append, not a rewrite.
5. **Outcome B, the decision changes.**
   - Write a **new** ADR (next ID) whose Status block says `Supersedes: ADR-NNN`, and whose Context explains the trigger and what changed.
   - In the old ADR, change **only** the Status line to `Superseded by ADR-MMM` and the "Supersedes / superseded by" line to link the new ADR. **Make no other edits to its body.**
   - Update the decision log: old row status → `Superseded by ADR-MMM`; add the new row.
   - Update traceability, the solution design technology table, affected diagrams, the threat model and NFR validation if they're affected, and the roadmap backlog (new `BL-` items for the migration).
   - Re-run `tools/validate-deliverables.sh` and `tools/validate-diagrams.sh`.

## Rules

- **Never delete an ADR.** Rejected and superseded ADRs stay in place. A withdrawn draft gets the status Rejected with a reason.
- **Never edit an accepted ADR's decision or rationale.** Supersede it instead. Fixing typos or broken links is allowed; note it in a changelog line.
- **Never copy an ADR from another use case** as a decision. You may cite it as prior art in Context, but the new ADR must re-derive the criteria from this use case's requirements, re-check its constraints, and refresh time-sensitive evidence (CLAUDE.md §5).
- **One decision per ADR.** Split compound decisions.
- **No superseded choice may appear as current** in the design, diagrams, or roadmap (G7).
- Don't promote a use-case ADR into `standards/` or `knowledge/` without an explicit framework decision.

## Outputs

| Artifact | Path |
|---|---|
| ADR | `use-cases/<id>/04-decisions/adr/ADR-NNN-<slug>.md` |
| Decision log (index) | `use-cases/<id>/04-decisions/decision-log.md` |
| Traceability update | `use-cases/<id>/01-requirements/requirements.md` §Traceability |
| Design update | `use-cases/<id>/02-design/solution-design.md` §Technology Selection |

## Quality gates touched

- **G3 Pattern & technology selection.** Material choices have ADRs, dated evidence, and lock-in recorded.
- **G7 Design consistency.** Superseded decisions are not referenced as current.
- **G10 Lifecycle governance.** Revisit triggers define re-evaluation.

## Failure conditions

- An ADR lacks a required heading, driving requirement IDs, or concrete revisit triggers.
- Time-sensitive claims have no source or date.
- Status is "Accepted" without an approver and date.
- An ADR was deleted or renumbered, or a superseded ADR's body was rewritten.
- The decision log disagrees with the ADR files.
- A superseded choice still appears as current in the design or diagrams.
- An ADR is copied from another use case without re-validation.
- An ADR conflicts with a CON or PRH without a recorded decision (blocks G3).

## References

- `templates/architecture-decision-record.md`
- `standards/architecture-principles.md` §2, §3, §5, AP-11, AP-12; `standards/architecture-quality-gates.md` (G3, G7, G10)
- `docs/operating-model.md` §8 (re-opening decisions); `docs/conventions.md` §1–§3
- Related skills: `technology-evaluation`, `architecture-debate`, `architecture-diagrams`, `implementation-roadmap`

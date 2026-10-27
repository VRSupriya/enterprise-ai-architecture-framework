<!-- TEMPLATE: remove this line once the document is filled in -->
# Architecture Debate Record: <Use-case title>

<!-- guidance: Copy to use-cases/<id>/03-review-board/debate-record.md. Produced in Phase E by the architecture-debate skill, and the evidence for gate G6 (with round-<n>/red-team-architect.md).
     The board chair mediates. Specialists don't talk to each other directly. Each objection gets a response and an outcome of Accepted, Rejected (with a reason), or Escalated (to a named decision owner).
     A MAJORITY VOTE IS NOT EVIDENCE. Outcomes are decided on requirements, constraints, and labeled evidence. Five specialists agreeing on an unverified claim is still an unverified claim.
     Don't manufacture disagreement. If a decision is uncontested and well evidenced, record "No material objections."
     T2: a lightweight record of material objections only. T3+: full record, including the red team's objections from its independent first pass. -->

- **Use-case ID:** <id> · **Tier:** T3 · **Debate round:** 1 · **Date:** YYYY-MM-DD
- **Chair:** <name> · **Participants:** <specialist agents, red-team-architect>
- **Inputs:** 02-design/solution-design.md (version), round-<n>/*.md

## Proposal

<!-- guidance: State exactly what is being challenged: the decision(s), the ADR IDs, and the design version. Debate material decisions only. -->

- **Decision(s) under challenge:** (example) ADR-002, use a single bounded agent (rung 6) for exception handling
- **Proposed by / rationale:**
- **Requirements served:** FR-…, NFR-…

### Binding constraints

| ID | Constraint / prohibition | Effect on the debate |
|---|---|---|
| CON-001 | (example) Data stays in-region | Options outside the region are out of bounds |

## Objections

| ID | Raised by | Objection | Evidence (path / source, label) | Response (proposer / chair) | Outcome | Rationale |
|---|---|---|---|---|---|---|
| DBT-01 | (example) red-team-architect | Agent can call `post_invoice` without an amount limit | solution-design.md §Tools; F-RT-02 [VERIFIED] | Add a deterministic limit and a human approval step above the limit | Accepted | AP-14; blocks G4 otherwise |
| DBT-02 | (example) solution-architect | Rung 6 unnecessary; exceptions are enumerable | Exception log analysis [ASSUMPTION ASM-004] | Proposer shows 31% of exceptions are unclassified | Escalated | Evidence incomplete; product owner to validate ASM-004 |

## Board Questions

<!-- guidance: Canonical list; keep in sync with .claude/skills/architecture-debate/SKILL.md. Answer each question briefly, with IDs. "Unknown" is an acceptable answer if it is paired with an ASM- or Q- item. -->

| # | Question | Answer (with IDs) |
|---|---|---|
| 1 | Which requirements does the proposal satisfy, and with what evidence? | |
| 2 | Which requirements are unmet, or met only on an unverified claim? | |
| 3 | Why is this better than the simpler alternatives (lower ladder rungs, existing capability)? | |
| 4 | Does it duplicate an existing enterprise capability? | |
| 5 | What are the key trust boundaries and failure modes? | |
| 6 | What happens when a model, tool, database, or integration is unavailable? | |
| 7 | How are consequential actions authorized and controlled, outside the model? | |
| 8 | Is it testable, observable, auditable, rollback-able, and supportable? | |
| 9 | Which choices depend on assumptions or on time-sensitive facts, and when must they be re-verified? | |
| 10 | What are the largest residual risks, and who accepts them? | |
| 11 | What must be fixed before production? | |
| 12 | What is centralized, and what is domain-owned, and why (`standards/agentic-ai-design-principles.md` §6)? | |

## Resolutions

| ID | Resolution | Changes required (design / ADR / backlog) | Owner | Tracking ID |
|---|---|---|---|---|
| RES-01 | (example) Amount limit enforced in the tool adapter; approval above $X | ADR-002 updated; BL-014 | AP Platform | BL-014 |

## Unresolved Disagreements

<!-- guidance: Record the disagreement fairly, state each position's strongest evidence, and name who decides and by when. Don't paper over a real disagreement. -->

| Topic | Position A (who, evidence) | Position B (who, evidence) | Evidence that would resolve it | Decision owner | Needed by |
|---|---|---|---|---|---|
| (example) Rung 6 vs rung 4 for exceptions | | | 4 weeks of classified exception data | Product owner | Before MS-02 |

## Residual Risks

| RSK ID | Residual risk after the debate | Accepted by (name, role) | Monitoring / revisit trigger |
|---|---|---|---|
| RSK-0xx | | | |

### G6 checklist

- [ ] Red team ran its first pass without the other specialists' conclusions
- [ ] Every material objection is Accepted, Rejected with a reason, or Escalated to a named owner
- [ ] Resolutions are reflected in the design, the ADRs, or the backlog
- [ ] No outcome rests on a head count rather than evidence

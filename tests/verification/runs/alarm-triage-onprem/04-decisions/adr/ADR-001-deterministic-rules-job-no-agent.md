# ADR-001: Use a deterministic on-prem Python rules job, with no LLM or agent, for daily alarm triage

T1 depth: ADRs are optional at T1 (`.claude/skills/adr-management/SKILL.md`). This one is written because a stakeholder (the CEO) proposed agents (PREF-002), so the reason for not adopting the proposal should be on record.

## Status

- **Status:** Proposed
- **Date proposed / last changed:** 2026-10-27 / 2026-10-27
- **Decision owner:** Maintenance Manager (role; name pending, ASM-008). CEO informed as sponsor.
- **Approval status:** Pending
- **Supersedes / superseded by:** —
- **Related:** DEC-001, PREF-002, CON-001, PRH-001, ASM-005, ASM-011, RSK-004, RSK-005

## Context

A supervisor spends ~90 minutes each morning applying a fixed ~40-rule rulebook to a ~2,000-row SCADA alarm CSV and emailing a ranked list to three crew leads. The CEO would like the team to "use AI agents". Everything must run on-premises with no cloud services. The decision is which solution-ladder rung to build on.

### Driving requirements

| ID | Requirement / risk | Why it matters for this decision |
|---|---|---|
| FR-002 | Evaluate every row against every rule, recording matched rule IDs | Needs exact, explainable rule application |
| FR-003 | Deterministic ranking | Same input must give the same list |
| NFR-003 | 100% agreement with the supervisor-labelled reference | A probabilistic component can't guarantee this |
| NFR-009 | No new licences, hardware, or paid services | Self-hosted model inference would need new hardware or significant CPU capacity |
| RSK-005 | Sponsor expectation of "AI agents" | Decision must be explained, not just made |

### Mandatory constraints and assumptions

| ID | Type (CON / PRH / ASM / INV / PREF) | Statement | Effect on the options |
|---|---|---|---|
| CON-001 | CON | Everything runs on-premises | Any LLM option must be self-hosted on-prem |
| PRH-001 | PRH | No cloud services | Excludes cloud LLM APIs and SaaS automation entirely |
| PREF-001 | PREF | IT prefers Python | Favours a Python implementation |
| PREF-002 | PREF | CEO would like AI agents | Evaluated as an option; not binding |
| ASM-005 | ASM | All rules are deterministic | If false for specific rules, an LLM step for those rules may be justified |
| ASM-011 | ASM | Historian can't already do this | If false, rung 0 wins |
| INV-001..INV-003 | INV | Windows server, SQL Server, SMTP relay | Reuse makes the deterministic job nearly free to run |

### Evaluation criteria

| Criterion | Derived from | Weight (optional) |
|---|---|---|
| Exact, repeatable rule application | FR-002, FR-003, NFR-003 | High |
| Fits on-prem with no cloud dependency | CON-001, PRH-001 | Must |
| No new hardware or licences | NFR-009 | High |
| Testable per rule; explainable output | FR-006, FR-007 | High |
| Supportable by the existing team | PREF-001 | Medium |

## Decision

**We will** build a scheduled Python job on the existing on-prem Windows server that validates the daily alarm CSV, applies the versioned rulebook as deterministic code (rung 1), ranks results, records the run in SQL Server, and emails the list through the SMTP relay (rung 2 orchestration via Windows Task Scheduler). No LLM, agent, or cloud service is included in this release.

### Rationale

- The rulebook is fixed, known, and applies to structured fields. That is exactly rung 1's "choose when" condition (`standards/architecture-principles.md` §4), and AP-14 requires deterministic code for business rules `[JUDGMENT]`.
- The agentic justification test (`standards/agentic-ai-design-principles.md` §1.1) fails on its first two items: the path is enumerable, and no metric improves over the deterministic job (solution-design.md §Solution Approach) `[JUDGMENT]`.
- An LLM or agent under CON-001 would need self-hosted inference, with new capacity, model lifecycle, evaluation, and prompt versioning, against NFR-009. Its output would be probabilistic where NFR-003 needs exact agreement `[JUDGMENT]`.
- The deterministic job reuses INV-001..INV-003 and PREF-001 directly.

### Evidence and research dates

| Claim | Evidence label | Source (URL or path) | Accessed / observed |
|---|---|---|---|
| Rules are fixed thresholds, codes, and criticality | [ASSUMPTION] | User request; ASM-005 | 2026-10-27 |
| Agentic test fails | [JUDGMENT] | use-cases/alarm-triage-onprem/02-design/solution-design.md §Solution Approach | 2026-10-27 |
| No product or version facts were relied on | — | No research performed; none needed for this decision | 2026-10-27 |

## Alternatives Considered

| Option | Summary | Score vs criteria | Outcome |
|---|---|---|---|
| A (chosen) | Python rules job, scheduled, on existing server | Meets all criteria | Chosen |
| B | Configure the historian's own alarm reporting (rung 0) | Unknown until ASM-011 checked; would beat A on build cost if it meets FR-002–FR-005 | Alternative: exists because it may make new code unnecessary |
| C | Single tool-using agent on a self-hosted on-prem LLM (PREF-002) | Fails exactness, cost, and agentic test | Rejected |
| D | Cloud-hosted LLM or agent service | Violates CON-001 / PRH-001 | Rejected (excluded by prohibition; recorded only because PREF-002 makes it a natural question) |

### Rejected alternatives and reasons

| Option | Reason rejected (requirement / constraint IDs) | Would reconsider if |
|---|---|---|
| C | Path is enumerable; no measurable gain; probabilistic output vs NFR-003; new on-prem inference capacity vs NFR-009 | Specific rules need judgement over free-text alarm text (ASM-005 false), or a later scope adds unstructured inputs such as technician notes. Then add a bounded rung 4 step for those rules only, not an agent |
| D | CON-001, PRH-001 | The security policy changes (Information Security Officer decision) |

## Consequences

- **Positive:** Exact, testable, explainable output; near-zero run cost; built and supported by the existing team; the rulebook becomes an explicit, versioned asset; run history provides labelled data for any later AI use case.
- **Negative / trade-offs accepted:** Doesn't satisfy the literal wish to "use AI agents" (RSK-005). Tacit supervisor judgement must be written down as rules, or it is lost (RSK-001).
- **Lock-in and exit cost (AP-12):** Negligible. Small codebase and plain data files; no proprietary platform.
- **Reversibility (AP-11):** Cheap. Rule evaluation is isolated in C-03, so a later rung 4 step can be added for specific rules without redesign.

### Residual risks

| RSK ID | Residual risk | Accepted by (name, role) | Monitoring |
|---|---|---|---|
| RSK-001 | Tacit rules missed | Pending: Maintenance Manager | Parallel-run discrepancy log |
| RSK-005 | Sponsor expectation mismatch | Pending: Maintenance Manager | Sponsor briefing after parallel run |

### Dependencies

| Depends on | Type (ADR / platform / team / contract) | Status |
|---|---|---|
| Historian scheduled export (ASM-006) | Team: SCADA / Operations | Not requested |
| Service account, SQL schema, relay permission | Platform: IT Infrastructure | Not requested |

## Revisit Triggers

- [ ] ASM-011 shows the historian can apply the rulebook and email results (switch to option B)
- [ ] Encoding the rulebook finds one or more rules that need judgement over free-text fields (ASM-005 invalid)
- [ ] The rulebook grows beyond ~200 rules, or more than 25% of parallel-run discrepancies are caused by rules that can't be expressed as thresholds or code lists
- [ ] Scope expands to unstructured inputs (technician notes, work-order text) or to writing work orders (re-tier)
- [ ] The on-prem security policy changes (CON-001 / PRH-001)
- [ ] Scheduled re-evaluation: 3 months after go-live

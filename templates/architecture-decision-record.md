<!-- TEMPLATE: remove this line once the document is filled in -->
# ADR-NNN: <Decision title, phrased as the choice made, e.g. "Use the enterprise AI gateway for all model access">

<!-- guidance: Copy to use-cases/<id>/04-decisions/adr/ADR-NNN-<slug>.md and add a row to 04-decisions/decision-log.md.
     Write an ADR for each material decision: hard to reverse, costly, cross-team, or constraint-sensitive. Don't write one for trivia.
     Never delete or rewrite an accepted ADR. Supersede it with a new ADR and update both Status lines.
     T1: Context, Decision, and Consequences may each be a short paragraph. T3+: every table complete, with dated evidence for each time-sensitive claim. -->

## Status

<!-- Allowed: Proposed | Accepted | Rejected | Deprecated | Superseded by ADR-NNN -->

- **Status:** Proposed
- **Date proposed / last changed:** YYYY-MM-DD / YYYY-MM-DD
- **Decision owner:** <name, role>
- **Approval status:** Pending | Approved by <name, role> on YYYY-MM-DD | Rejected by <name, role>
- **Supersedes / superseded by:** —
- **Related:** <DEC-, F-, T- IDs; other ADRs>

## Context

<!-- guidance: What forces the decision now? State the problem, not the solution. Link the requirements it serves. -->

<problem statement and forces>

### Driving requirements

| ID | Requirement / risk | Why it matters for this decision |
|---|---|---|
| NFR-001 | (example) p95 latency ≤ 8 s | Rules out batch-only hosting options |

### Mandatory constraints and assumptions

| ID | Type (CON / PRH / ASM / INV / PREF) | Statement | Effect on the options |
|---|---|---|---|
| CON-001 | (example) CON | Data stays in-region | Excludes providers without in-region endpoints |
| ASM-001 | (example) ASM | ≤ 5k docs/day | Cost comparison is valid only below this volume |

### Evaluation criteria

<!-- guidance: Derive criteria from the requirements above. Weights are optional; if you use them, state why. A criterion with no requirement behind it is a bias. -->

| Criterion | Derived from | Weight (optional) |
|---|---|---|
| (example) Meets p95 latency | NFR-001 | High |

## Decision

**We will** <chosen option, stated precisely: product/pattern, scope, version or tier>.

### Rationale

<!-- guidance: Why this option wins on the criteria. Label material claims (standards/architecture-principles.md §3). -->

-

### Evidence and research dates

| Claim | Evidence label | Source (URL or path) | Accessed / observed |
|---|---|---|---|
| (example) Model X available in region R | [VENDOR] | https://… | YYYY-MM-DD |

## Alternatives Considered

<!-- guidance: List only the options that were genuinely viable or that a stakeholder proposed. Never manufacture options to look balanced. -->

| Option | Summary | Score vs criteria | Outcome |
|---|---|---|---|
| A (chosen) | | | Chosen |
| B | | | Alternative / fallback: <specific reason it exists> |
| C | | | Rejected |

### Rejected alternatives and reasons

| Option | Reason rejected (requirement / constraint IDs) | Would reconsider if |
|---|---|---|
| C | (example) Violates PRH-001 | Prohibition lifted |

## Consequences

- **Positive:**
- **Negative / trade-offs accepted:**
- **Lock-in and exit cost (AP-12):** <what we are locked into; estimated effort to exit>
- **Reversibility (AP-11):** <cheap / moderate / expensive to reverse; what seam keeps it reversible>

### Residual risks

| RSK ID | Residual risk | Accepted by (name, role) | Monitoring |
|---|---|---|---|
| RSK-00x | | | |

### Dependencies

| Depends on | Type (ADR / platform / team / contract) | Status |
|---|---|---|
| (example) Enterprise AI gateway onboarding | Platform | Requested |

## Revisit Triggers

<!-- guidance: Make the triggers concrete and observable, e.g. a threshold, an event, or a date. "When technology changes" is not a trigger. -->

- [ ] (example) Volume exceeds 5k docs/day for 2 consecutive weeks (ASM-001 invalidated)
- [ ] (example) Provider announces end of support for the chosen model version
- [ ] (example) Inference cost per document > $0.05 for a calendar month (NFR-003)
- [ ] Scheduled re-evaluation: <milestone or review cycle>

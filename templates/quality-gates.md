<!-- TEMPLATE: remove this line once the document is filled in -->
# Quality Gates: <Use-case title>

<!-- guidance: Copy to use-cases/<id>/05-validation/quality-gates.md. Gate definitions and pass criteria are in standards/architecture-quality-gates.md; don't restate them here.
     Outcome ∈ PASS · PASS-WITH-CONDITIONS · FAIL · N/A (N/A needs a reason in Conditions).
     Mark a gate PASS only if the evidence exists and you looked at it. A structural validator pass (tools/validate-*.sh) is evidence for G7 structure only, never for G2–G6 or G8–G10.
     "Tier req." uses the standard's key: ● required · ◐ lightweight (checklist or short note) · ○ optional. Fill it in from the §3 table for this engagement's tier. Replace "Pending" as each gate is assessed. -->

- **Use-case ID:** <id> · **Mode:** A · **Risk tier:** T2 · **Last updated:** YYYY-MM-DD
- **Board chair:** <name> · **Production approver(s) (G10):** <name, role>

## Gate Results

| Gate | Name | Tier req. (T_) | Outcome | Evidence | Conditions (owner, due) | Assessed by | Date |
|---|---|---|---|---|---|---|---|
| G1 | Discovery completeness | | Pending | 00-intake/use-case-brief.md | | | |
| G2 | Requirements & NFR traceability | | Pending | 01-requirements/requirements.md §Traceability | | | |
| G3 | Pattern & technology selection | | Pending | 02-design/solution-design.md; 04-decisions/adr/ | | | |
| G4 | Security & threat modeling | | Pending | 05-validation/threat-model.md | | | |
| G5 | Architecture review | | Pending | 03-review-board/round-<n>/ | | | |
| G6 | Independent challenge | | Pending | 03-review-board/round-<n>/red-team-architect.md; 03-review-board/debate-record.md | | | |
| G7 | Design consistency | | Pending | validate-deliverables.sh + validate-diagrams.sh output; manual consistency check | | | |
| G8 | Test & evaluation readiness | | Pending | 05-validation/test-and-evaluation-plan.md | | | |
| G9 | Operational readiness | | Pending | 06-delivery/implementation-roadmap.md; 06-delivery/runbooks/ | | | |
| G10 | Production approval & lifecycle governance | | Pending | 05-validation/quality-gates.md (this file, §Approvals) | | | |

<!-- Example of a completed row (delete it once real rows are filled in):
| G1 | Discovery completeness | ● | PASS | 00-intake/use-case-brief.md | — | Board chair | YYYY-MM-DD |
| G8 | Test & evaluation readiness | ◐ | PASS-WITH-CONDITIONS | test-and-evaluation-plan.md | EVAL-002 dataset labeled (AP lead, before MS-02, BL-021) | Board chair | YYYY-MM-DD |
-->

### Tier requirements reference (from standards §3)

| Gate | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| G1 | ◐ | ● | ● | ● |
| G2 | ◐ | ● | ● | ● |
| G3 | ◐ | ● | ● | ● |
| G4 | ◐ | ● | ● | ● |
| G5 | ○ | ◐ | ● | ● |
| G6 | ○ | ◐ | ● | ● |
| G7 | ◐ | ● | ● | ● |
| G8 | ○ | ◐ | ● | ● |
| G9 | ○ | ◐ | ● | ● |
| G10 | ○ | ◐ | ● | ● |

## Blocking Checks

<!-- guidance: These block regardless of tier. Tick a box only after checking it. If any check fails, the named gate is FAIL. -->

- [ ] No unresolved conflict with a CON or PRH (otherwise G3 = FAIL)
- [ ] No open Critical finding (otherwise G5 and G10 = FAIL)
- [ ] No consequential action relies on model reasoning for authorization (otherwise G4 = FAIL)
- [ ] Every claimed test or verification has observed evidence linked (otherwise the dependent gate = FAIL)

## Open Conditions

| Tracking ID | Gate | Condition | Owner | Due (phase / milestone) | Status |
|---|---|---|---|---|---|
| (example) BL-021 | G8 | Label EVAL-002 and record a baseline result | AP product owner | Before MS-02 | Open |

## Waivers

<!-- guidance: Only a named approver with authority can waive a Mandatory remediation or a gate criterion. Record the reason and the expiry. -->

| Item waived | Gate | Reason | Compensating control | Approved by (name, role) | Date | Expires / review |
|---|---|---|---|---|---|---|
| | | | | | | |

## Approvals

<!-- guidance: G10. Record the name, role, and date of each approval. A chat message saying "looks good" is not an approval record. -->

| Approver | Role | Scope of approval | Decision | Date |
|---|---|---|---|---|
| (example) <name> | Head of AP Operations | Business acceptance for pilot (MS-03) | Pending | |

### Lifecycle governance

- **Versioned artifacts and where they are recorded:** <model, prompt, tool schema, agent config>
- **Re-evaluation triggers:** <link ADR revisit triggers; eval drift thresholds>
- **Retirement criteria and owner:**

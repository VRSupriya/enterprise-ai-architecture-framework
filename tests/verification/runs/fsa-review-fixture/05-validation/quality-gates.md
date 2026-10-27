# Quality Gates: fsa-review-fixture (T3)

Gates were assessed by the board chair on 2026-10-27, then **corrected after the red-team second pass** (round-3 overclaims table). G3, G5, G6 and G7 were revised. This is a verification exercise: the stakeholders are fictional, and nothing was built or run.

## Gate Results

| Gate | Name | Tier req. | Outcome | Evidence | Conditions (owner, due) | Assessed by | Date |
|---|---|---|---|---|---|---|---|
| G1 | Discovery completeness | ● | PASS-WITH-CONDITIONS | 00-intake/use-case-brief.md | Q-001 and Q-002 still need stakeholder answers (sponsor, MS-01) | Board chair | 2026-10-27 |
| G2 | Requirements & NFR traceability | ● | PASS-WITH-CONDITIONS | 01-requirements/requirements.md | The NFR targets are ASM candidates and need sponsor confirmation (sponsor, MS-01) | Board chair | 2026-10-27 |
| G3 | Pattern & technology selection | ● | PASS-WITH-CONDITIONS (target design) / FAIL (baseline: CON-002 breach) | ADR-001 to ADR-006 | CON-002 is *addressed by design*, not yet resolved. Pending: Q-IN-02 (region named), RSK-01 (model availability), F-BRD-19 (residency of reused APIM, n8n and sinks), and re-verification of the ADR-003 evidence (geography vs region). Owner: platform lead, due MS-02 | Board chair | 2026-10-27 |
| G4 | Security & threat modeling | ● | PASS-WITH-CONDITIONS (target design) / FAIL (baseline) | 05-validation/threat-model.md | Residual risk is not yet accepted by the CISO. None of the tests has run. | Board chair | 2026-10-27 |
| G5 | Architecture review | ● | FAIL (baseline) / PASS-WITH-CONDITIONS (target design) | round-1/ (7 independent reports), round-3/, review-report.md | An open Critical blocks G5 under the gates standard. F-BRD-01 to -06 and F-BRD-19 are not yet remediated or verified. The target design addresses them, but only conditionally until they are implemented and tested | Board chair | 2026-10-27 |
| G6 | Independent challenge | ● | PASS-WITH-CONDITIONS | round-1 (blind), round-2 (DBT-03), round-3/red-team-architect.md (second pass: "Sound with conditions") | Close F-BRD-17 to F-BRD-20 before G4 is relied on. Owner: security lead, due before slice S2 | Board chair | 2026-10-27 |
| G7 | Design consistency | ● | PASS-WITH-CONDITIONS | `tools/validate-deliverables.sh` and `tools/validate-diagrams.sh` both printed "Result: PASS (0 warning(s))" on 2026-10-27; manual cross-check of C-01 to C-11 against the ADRs | Mermaid was checked structurally only, because `mmdc` is not installed | Board chair | 2026-10-27 |
| G8 | Test & evaluation readiness | ● | PASS-WITH-CONDITIONS | 05-validation/test-and-evaluation-plan.md | EVAL thresholds are open (sponsor) | Board chair | 2026-10-27 |
| G9 | Operational readiness | ● | FAIL | 06-delivery/implementation-roadmap.md | The runbooks are not written and the on-call owner is not named. This is expected at review stage. | Board chair | 2026-10-27 |
| G10 | Production approval | ● | FAIL | — | No approvals have been given and the mandatory remediation is not implemented. This is expected. | Board chair | 2026-10-27 |

G9 and G10 are expected to fail at this stage, because this is a review and redesign and nothing has been built. Approval for production is out of scope for this engagement.

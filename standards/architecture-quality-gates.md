# Architecture Quality Gates

Gates are passed with evidence, not assertion. The depth of each gate scales with the risk tier, so a T1 engagement should not carry the process burden of a T4 system.

## 1. Gate outcomes

| Outcome | Meaning |
|---|---|
| **PASS** | All required criteria for the tier are met, and the evidence is linked. |
| **PASS-WITH-CONDITIONS** | Non-blocking gaps remain. Each condition has an owner, a due point (a phase or milestone), and a tracking ID. |
| **FAIL** | A blocking criterion is unmet. The engagement can't proceed past the gate. |
| **N/A** | The gate doesn't apply at this tier or in this mode. The reason is stated. |

Record results in `use-cases/<id>/05-validation/quality-gates.md` using the table in §4.

## 2. Risk tiers

Assign the tier at intake, and re-assess it whenever scope changes. **The highest triggered factor sets the tier.**

| Factor | T1 Low | T2 Moderate | T3 High | T4 Critical |
|---|---|---|---|---|
| Users / exposure | Small internal team | Department / internal-wide | Customers, partners, or the public | Large public or safety-critical audience |
| Data | Public / internal | Confidential | Restricted, PII, regulated | Highly regulated, special-category, or national-security data |
| Actions / side effects | Read-only, advisory | Drafts reviewed by a human | Writes to business systems with approval | Autonomous consequential actions (financial, legal, safety, infrastructure) |
| Autonomy | None (rungs 0–4) | LLM steps (rungs 4–5) | Bounded agent (rung 6) | Multi-agent or long-running autonomy (rung 7) |
| Business impact of failure | Inconvenience | Rework / delay | Material financial, reputational, or regulatory impact | Severe harm, critical service outage, legal breach |
| Regulatory | None, or routine internal policy (acceptable use, standard IT policy) | Internal policy with specific obligations (audit trail, records retention, privacy review) | Sector regulation applies | Regulator-facing, licensed activity, high-risk AI category |

## 3. Gates and tier requirements

Key: ● required · ◐ lightweight (checklist or short note) · ○ optional

| # | Gate | Phase | T1 | T2 | T3 | T4 | Pass criteria (summary) | Evidence artifact |
|---|---|---|---|---|---|---|---|---|
| G1 | Discovery completeness | A | ◐ | ● | ● | ● | Objectives and success metrics stated. Mode and tier assigned. All inputs classified (CON/PREF/INV/DEC/ASM/PRH). Stakeholders and decision owners named. Questions that would materially change the design are answered or recorded as ASMs. | `00-intake/use-case-brief.md` |
| G2 | Requirements & NFR traceability | C | ◐ | ● | ● | ● | FRs testable. NFRs measurable (metric, target, measurement point). NFR conflicts identified. Every material component traces to a requirement. | `01-requirements/requirements.md` (§Traceability) |
| G3 | Pattern & technology selection | B/C | ◐ | ● | ● | ● | Solution-ladder rung justified, including why lower rungs are insufficient. Material technology choices have ADRs. Time-sensitive claims dated and labelled. Lock-in recorded. | `02-design/solution-design.md`, `04-decisions/adr/` |
| G4 | Security & threat modeling | C/G | ◐ | ● | ● | ● | Trust boundaries drawn. Identities separated (user/workload/agent/tool). Authorization enforced outside the model. Threats have mitigations and verification tests. Residual risk accepted by a named owner. | `05-validation/threat-model.md` |
| G5 | Architecture review | D | ○ | ◐ | ● | ● | Relevant specialists reviewed independently. Findings follow the evidence format (`architecture-review` skill). No unresolved Critical findings. | `03-review-board/round-<n>/` |
| G6 | Independent challenge | E/G | ○ | ◐ | ● | ● | The red team ran without seeing other specialists' conclusions. Material objections are accepted, rejected with reasons, or escalated. | `03-review-board/round-<n>/red-team-architect.md`, `03-review-board/debate-record.md` |
| G7 | Design consistency | F | ◐ | ● | ● | ● | Diagrams, component list, technology table, ADRs, and requirements agree. Diagrams validated. No orphan components or requirements. | `tools/validate-*.sh` output plus a manual consistency check |
| G8 | Test & evaluation readiness | G | ○ | ◐ | ● | ● | Every NFR and high-risk FR has a verification method. AI quality has an offline evaluation set, metrics, thresholds, and adversarial cases. | `05-validation/test-and-evaluation-plan.md` |
| G9 | Operational readiness | H | ○ | ◐ | ● | ● | Observability, alerting with owners, runbooks, rollback, DR as needed, cost controls, and support model defined. | `06-delivery/implementation-roadmap.md`, runbooks |
| G10 | Production approval & lifecycle governance | H | ○ | ◐ | ● | ● | Approvers named. Mandatory remediation complete or formally waived. Lifecycle (versioning, re-evaluation triggers, retirement) defined. | `05-validation/quality-gates.md` |

**Where T1 records gate results.** `quality-gates.md` is required from T2 upward. At T1, record G1–G4 and G7 in a short `## Quality Gates` section at the end of `solution-design.md`, or `review-report.md` for Mode B.

**Blocking rules (all tiers):**
- An unresolved conflict with a mandatory constraint (CON or PRH) blocks G3.
- An open Critical finding blocks G5 and G10.
- Authorization delegated to model reasoning for any consequential action blocks G4.
- A claimed test or verification without observed evidence blocks the gate that depends on it.

## 4. Gate record format

```markdown
| Gate | Outcome | Evidence | Conditions (owner, due) | Assessed by | Date |
|---|---|---|---|---|---|
| G1 | PASS | 00-intake/use-case-brief.md | — | Board chair | YYYY-MM-DD |
```

Mark a gate PASS only if the evidence exists and you looked at it. A structural validator pass is evidence for G7 (structure) only, never for G2–G6 or G8–G10 (substance).

**Assessment rules.** Each of these came from a verification run in which the red team caught the board chair overclaiming.
- **Mode B: gate the baseline and the target separately.** For G3, G4 and G5, record a baseline outcome and a target-design outcome. An open Critical in the baseline means the baseline G5 is FAIL. A target design that addresses the Critical earns PASS-WITH-CONDITIONS at most, until the remediation is implemented and verified.
- **Never record an outcome that depends on a review that has not run yet.** Example: G6 cannot be PASS "pending the second red-team pass". Record it as pending, then assess it once that report exists.
- **Reuse claims need evidence.** "Existing X" (gateway, platform, flow) is a fact only if an artifact or a stakeholder shows it. Otherwise label it `[ASSUMPTION]` with a Q- item.
- **Re-assess gates after every challenge round,** and record which gates the round changed.

## 5. Gate detail checklists

### G1 Discovery
- [ ] Problem, objectives, and measurable success metrics
- [ ] Users, stakeholders, decision owners
- [ ] Current and future process; in- and out-of-scope boundaries
- [ ] Inputs classified per `architecture-principles.md` §2
- [ ] Data sources, classification, ownership, residency
- [ ] Risk tier with rationale
- [ ] Open questions triaged: material → asked; otherwise → ASM

### G2 Requirements
- [ ] Each FR has an ID, a statement, a priority (MoSCoW), and an acceptance criterion
- [ ] Each NFR has a metric, target, measurement point, measurement method, and source
- [ ] NFR conflicts listed with resolution or owner (`nfr-validation`)
- [ ] Requirement → component and requirement → test mappings exist (T2+)

### G3 Pattern & technology
- [ ] Ladder rung chosen; lower rungs explicitly ruled out with reasons
- [ ] Agentic justification complete if rung ≥ 6 (`agentic-ai-design-principles.md` §1)
- [ ] Existing investments assessed for reuse before introducing new technology
- [ ] Each material choice: recommended / alternative (if meaningful) / rejected (if valuable)
- [ ] Time-sensitive evidence dated; re-evaluation triggers recorded

### G4 Security
- [ ] Assets, trust boundaries, and data flows drawn
- [ ] Identity separation and delegated-access semantics specified
- [ ] Tool permissions explicit; consequential actions gated by deterministic policy and/or human approval
- [ ] Prompt-injection / untrusted-content controls for each ingestion path
- [ ] Secrets management; no credentials reachable by the model context
- [ ] Each threat has a mitigation, a verification test, and residual risk

### G7 Consistency
- [ ] Each diagram node appears in the component catalogue, and vice versa
- [ ] Technology named in diagrams = technology in the ADRs and the stack table
- [ ] Each Must FR and NFR maps to at least one component and at least one test
- [ ] Superseded decisions are not referenced as current

### G8–G10
- [ ] Evaluation dataset provenance, size rationale, refresh cadence
- [ ] Release thresholds and rollback triggers are numeric
- [ ] SLOs → alerts → owners → runbooks chain is complete
- [ ] DR tested (T3+), or the test is scheduled before go-live with a named owner
- [ ] Approvals recorded with name, role, and date

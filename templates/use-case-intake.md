<!-- TEMPLATE: remove this line once the document is filled in -->
# Use-Case Brief: <Use-case title>

<!-- guidance: Copy this file to use-cases/<id>/00-intake/use-case-brief.md. It is the evidence artifact for gate G1.
     Fill it in during Phase A (use-case-discovery). Keep it factual: record what the stakeholders said, classify it, and push gaps to ASM- or Q- items.
     T1: most sections can be a few bullets. T3+: every table must be complete, and every decision owner must be named. -->

## Engagement Classification

<!-- Allowed values (the validator parses the Mode and Risk tier lines exactly; keep the "- **Field:** value" form):
     Mode: A (Create) | B (Review/Redesign) | C (Improve) | Focused
     Risk tier: T1 | T2 | T3 | T4  (highest triggered factor sets the tier; standards/architecture-quality-gates.md §2)
     Status: Draft | In discovery | Baselined | Superseded -->

- **Use-case ID:** <lowercase-kebab-id>
- **Mode:** ?
- **Risk tier:** ?
- **Date:** YYYY-MM-DD
- **Board chair:** <name, role>
- **Decision owner(s):** <name, role: what they decide>
- **Status:** Draft

### Tier rationale

| Factor | Observed value | Tier triggered | Source |
|---|---|---|---|
| Users / exposure | (example) Internal finance team, ~40 users | T2 | Kickoff notes |
| Data | | | |
| Actions / side effects | | | |
| Autonomy | | | |
| Business impact of failure | | | |
| Regulatory | | | |

<!-- guidance: State the resulting tier and the single factor that set it. Re-assess when scope changes. -->

## Business Objectives

<!-- guidance: Describe the problem in business terms first, then the objectives. Each objective needs a measurable success metric and a baseline. "Improve efficiency" is not an objective. -->

**Problem statement:** <who has what problem, how often, and at what cost today>

| ID | Objective | Success metric | Baseline | Target | Measured by |
|---|---|---|---|---|---|
| OBJ-01 | (example) Reduce manual invoice triage effort | Median handling time per invoice | 6 min | ≤ 2 min | Workflow system timestamps |

- **Why now / business driver:**
- **What happens if we do nothing:**
- **Is AI assumed or demonstrated to be needed?** <!-- guidance: Note any stated pre-commitment to AI. Phase B tests it against the solution ladder. -->

## Scope

| In scope | Out of scope | Deferred (later phase) |
|---|---|---|
| (example) Inbound PDF invoices from the supplier portal | Payment execution | Email-channel invoices |

### Current and future process

<!-- guidance: For Mode B/C, also summarize the baseline: what exists today, where its sources live (repo paths, diagrams, IaC), and what access the board has to inspect it. -->

- **Current process (as-is):**
- **Target process (to-be), in outline:**
- **Baseline artifacts available for inspection (Mode B/C):**

### Data sources

| Source | Owner | Classification | Residency / sovereignty | Volume / frequency | Access path |
|---|---|---|---|---|---|
| (example) ERP vendor master | Finance IT | Confidential | In-country only | 12k records, daily delta | Read-only API |

## Stakeholders

| Name / role | Interest | Influence | Decision rights | Consulted for |
|---|---|---|---|---|
| (example) Head of AP Operations | Throughput, error rate | High | Approves scope and release | Process, acceptance |

<!-- guidance: Name at least one decision owner for each of these: business acceptance, security risk acceptance, data, platform, and production approval (G10). -->

## Input Classification

<!-- guidance: Tag every input per standards/architecture-principles.md §2. "Must / policy / regulation / contract" usually means CON. "Prefer / we use / considering" usually means PREF or INV. If unsure, record it as PREF and flag an ASM. Never upgrade a preference to a constraint. -->

| ID | Statement (as given) | Source | Category rationale | Required treatment |
|---|---|---|---|---|
| CON-001 | (example) All data must stay in the national region | Data protection policy §4 | Policy, non-negotiable | Design within it; flag conflicts |
| PREF-001 | (example) Team would like to use LangGraph | Engineering lead | "Would like" | Evaluate against requirements and alternatives |
| INV-001 | (example) Existing n8n workflow platform | Platform team | Running investment | Assess reuse, debt, and fit |
| DEC-001 | (example) Which model hosting option | Kickoff | Not yet decided | Recommend one; ADR if material |
| ASM-001 | (example) Invoice volume stays ≤ 5k/day for 12 months | Architect | No data yet | Impact, confidence, validation below |
| PRH-001 | (example) No public SaaS LLM endpoints | CISO directive | Explicitly disallowed | Exclude; flag unavoidable conflicts |

### Assumption register

| ID | Assumption | Impact if wrong | Confidence (H/M/L) | Validation method | Owner | Validate by |
|---|---|---|---|---|---|---|
| ASM-001 | (example) see above | Capacity and cost model invalid | M | 3 months of portal logs | AP Ops lead | Before MS-02 |

## Open Questions

<!-- guidance: Ask only questions whose answer could materially change the architecture (at most about 7, grouped). Record everything else as an ASM. Close a question by recording the answer and where it landed (CON/ASM/FR...). -->

| ID | Question | Why it matters (what it could change) | Directed to | Status | Answer / resolution |
|---|---|---|---|---|---|
| Q-001 | (example) Can extracted data be written to the ERP without human approval? | Changes tier (T2→T3) and approval design | Head of AP Ops | Open | |

## G1 Discovery Checklist

- [ ] Problem, objectives, and measurable success metrics stated
- [ ] Mode and tier assigned, with tier rationale
- [ ] Stakeholders and decision owners named
- [ ] As-is / to-be process and scope boundaries described
- [ ] All inputs classified (CON/PREF/INV/DEC/ASM/PRH)
- [ ] Data sources, classification, ownership, and residency recorded
- [ ] Material questions asked; the rest recorded as ASMs with owners

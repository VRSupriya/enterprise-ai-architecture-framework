# Use-Case Brief: Field Service Assistant review (TEST FIXTURE)

> Framework verification exercise. The system under review is fictional: `tests/fixtures/field-service-assistant/`.

## Engagement Classification

- **Use-case ID:** fsa-review-fixture
- **Mode:** B
- **Risk tier:** T3
- **Date:** 2026-10-27
- **Board chair:** Coordinator (main Claude Code session)
- **Decision owner(s):** Fixture sponsor (fictional): scope and acceptance; CISO (fictional): security risk acceptance
- **Status:** Baselined

### Tier rationale

| Factor | Observed value | Tier triggered | Source |
|---|---|---|---|
| Users / exposure | Internal field technicians (~400 interactions/day) | T2 | docs/architecture.md §1 |
| Data | Customer and asset data, in-region policy | T3 | §2 NFR-C |
| Actions / side effects | Creates/updates ERP work orders; delete tool configured | T3 | §4, config/agents.yaml |
| Autonomy | Multi-agent, no approval step | T4 (as proposed) | §4 |
| Business impact of failure | Wrong/duplicate work orders, misdispatch | T3 | [JUDGMENT] |
| Regulatory | Internal audit requirement (NFR-D) | T2 | §2 |

The tier is **T3**, set by data and side effects. As proposed, the autonomy factor reaches T4. That is a design choice under review, not a requirement, so the board assesses at T3 and flags the T4 autonomy as a finding.

## Business Objectives

**Problem statement:** Technicians phone the dispatch desk about 400 times a day for asset information and work-order changes.

| ID | Objective | Success metric | Baseline | Target | Measured by |
|---|---|---|---|---|---|
| OBJ-01 | Reduce dispatch-desk calls | Calls/day | ~400 | −40 % | Telephony stats [ASSUMPTION ASM-001] |
| OBJ-02 | Faster work-order creation | Median time to work order | Unknown | < 2 min | ERP timestamps |

- **Is AI assumed or demonstrated to be needed?** Assumed. The draft opens with a multi-agent design, so Phase B must test it against the solution ladder.

## Scope

| In scope | Out of scope | Deferred |
|---|---|---|
| Review of docs/architecture.md and config/agents.yaml; target architecture; remediation roadmap | Building the system; ERP changes | Mobile app UX |

### Current and future process

- **Current process:** The technician calls dispatch. Dispatch looks the information up and opens the work order through the existing n8n → ERP flows.
- **Baseline artifacts available for inspection:** `tests/fixtures/field-service-assistant/docs/architecture.md` (intended design) and `tests/fixtures/field-service-assistant/config/agents.yaml` (what is actually implemented). No running system and no code beyond the config.

### Data sources

| Source | Owner | Classification | Residency | Volume | Access path |
|---|---|---|---|---|---|
| Equipment manuals (PDF) | Asset engineering | Internal | In-region | Unknown [ASM-002] | Document store |
| Maintenance history (ERP read replica) | ERP team | Confidential (customer + asset) | In-region (CON-002) | Unknown | SQL read replica |
| ERP work orders | ERP team | Confidential | In-region | ~400/day max | ERP REST / existing n8n flows |

## Stakeholders

| Name / role | Interest | Influence | Decision rights | Consulted for |
|---|---|---|---|---|
| Sponsor (fictional) | Call reduction | High | Scope, acceptance | Objectives |
| CISO (fictional) | Risk | High | Security risk acceptance | Threats |
| ERP / integration team (fictional) | Integrity of the ERP | Medium | ERP access model | n8n reuse |

## Input Classification

| ID | Statement (as given) | Source | Category rationale | Required treatment |
|---|---|---|---|---|
| CON-001 | Azure is the mandated cloud | CIO memo (§3) | Enterprise policy | Design within Azure; no other clouds |
| CON-002 | Customer and asset data must stay in-region | Data-residency policy (NFR-C) | Policy | Design within it; flag conflicts |
| CON-003 | Every work-order change must be auditable | Internal audit (NFR-D) | Audit requirement | Design within it |
| INV-001 | Existing n8n runs production ERP create/update flows | §3 | Running investment | Assess reuse before adding orchestration |
| PREF-001 | LangGraph multi-agent on AKS | Draft design §4 | Proposal, not mandated | Evaluate against requirements |
| PREF-002 | Pinecone vector store | Draft design §4 | Proposal | Evaluate within CON-001/002 |
| PREF-003 | Custom in-house AI gateway | Draft design §4 | Proposal | Evaluate against existing capability |
| DEC-001 | Model region | §5 open item | Undecided | Must satisfy CON-002 |
| ASM-001 | The 40 % call-reduction target is achievable if R1+R2 are automated | Sponsor | No data | Validate with call-reason analysis |
| ASM-002 | Manual corpus is modest (< 50k pages) | Architect | No data | Inventory the corpus |
| ASM-003 | The team is Python-skilled with no agent-framework experience | §3 | Stated | Affects framework choice |

## Open Questions

Proceeding on assumptions (verification exercise; no live stakeholders).

| ID | Question | Why it matters | Directed to | Status | Answer / resolution |
|---|---|---|---|---|---|
| Q-001 | Can a work order be created without technician confirmation? | Approval design; tier | Sponsor | Open | Assumed: technician confirms (ASM) |
| Q-002 | Is deletion of work orders a requirement? | Tool scope | Sponsor | Open | Not in R1–R4, so treated as not required |

## G1 Discovery Checklist

- [x] Problem, objectives, and measurable success metrics stated
- [x] Mode and tier assigned, with tier rationale
- [x] Stakeholders and decision owners named (fictional)
- [x] As-is / to-be process and scope boundaries described
- [x] All inputs classified
- [x] Data sources, classification, ownership, and residency recorded
- [x] Material questions recorded (assumptions used for the exercise)

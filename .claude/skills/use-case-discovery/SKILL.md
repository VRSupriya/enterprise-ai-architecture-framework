---
name: use-case-discovery
description: Turns a problem statement, use-case idea, or existing system into a structured engagement. Covers mode and risk tier, goals and metrics, stakeholders, process, FRs/NFRs, data, integrations, classified inputs (CON/PREF/INV/DEC/ASM/PRH), oversight, and open questions. Use at the start of any Mode A/B/C engagement, or when someone says "new use case", "intake", "scope this", "we want to use AI for…", "start an engagement", or "what do you need to know".
argument-hint: "<use-case-id> [problem statement or path to source material]"
---

# Use-Case Discovery

## Purpose

Produce the Phase A record (`docs/operating-model.md` §2) that every later skill builds on. The engagement gets classified (mode, tier, inputs), and material unknowns are either asked or recorded as assumptions. In Mode B and C, discovery also establishes the baseline: what the system is meant to do versus what is actually there. Passing G1 depends on this skill's output.

## When to use / when not to use

| Use when | Don't use when |
|---|---|
| A new Mode A/B/C engagement starts | The request is a focused task with an existing brief, such as re-running `threat-modeling` or revisiting one ADR |
| Scope, users, or data change enough that the tier might move | You only need to add one requirement. Edit `01-requirements/requirements.md` directly |
| `architecture-design` or `architecture-review` finds no `00-intake/use-case-brief.md` | The brief already exists and passes G1. Reuse it rather than re-interviewing the user |

## Inputs

- A problem statement, a use-case description, or pointers to existing artifacts (docs, diagrams, code, IaC, configs).
- An optional use-case id. If none is given, propose a lowercase-kebab id and confirm it.
- Any constraints, policies, or stakeholder names the user provides.

## Workflow

1. **Classify the request.** Pick the mode per `CLAUDE.md` §1. If the request is really a focused task, stop here and route it to the right skill.
2. **Scaffold.** Run `tools/new-use-case.sh <id>`. If the folder already exists, don't overwrite it. Read what's there and continue from it. Never reuse content from another use case's folder (`CLAUDE.md` §5).
3. **Open the brief.** Fill `use-cases/<id>/00-intake/use-case-brief.md`, which the script copied from `templates/use-case-intake.md`. Write the metadata lines exactly as `docs/conventions.md` §3 specifies:
   ```markdown
   - **Mode:** A
   - **Risk tier:** T2
   ```
4. **Extract before asking.** Read everything the user provided. Draft every area in the coverage table below from that material first. Label each statement as stated by the user, inferred, or assumed.
5. **Classify every input** per `standards/architecture-principles.md` §2, using the wording heuristics there. Use one row per item: ID, statement, category, source, and treatment. If the category is ambiguous, record it as a PREF, raise an ASM, and list it as a question. Never promote a vague preference into a CON.
6. **Assign the risk tier** using the factor table in `standards/architecture-quality-gates.md` §2. Record the triggering factor for each dimension. The highest triggered factor sets the tier. Also record what would move the tier up or down, such as adding write-back or exposing the system to customers.
7. **Baseline (Mode B/C only).** Fill the baseline table below. List every artifact you inspected by path, and list what was requested but not provided. Never claim to have inspected something you didn't (`CLAUDE.md` §4).
8. **Triage questions.** Go through the question bank. A question is **material** (marked ★) if its answer could change the solution-ladder rung, the platform, the trust boundaries, the data stores, the tier, or a mandatory control. Ask non-material questions only if they're cheap to answer. Otherwise record them as ASMs.
9. **Ask, or proceed.** Ask at most about 7 material questions, grouped by area, in one message. Each question should say why it matters, for example "Determines whether write-back needs human approval (tier T2 vs T3)". If the user wants to proceed, or doesn't answer, record each gap as `ASM-###` with impact, confidence (H/M/L), validation method, owner, and deadline. Don't ask for anything you can establish through research (`standards/architecture-principles.md` §2).
10. **Seed requirements.** Draft FRs and NFRs in the brief, or directly in `01-requirements/requirements.md` from `templates/requirements.md` if the tier requires it (`docs/conventions.md` §4). Each FR needs a MoSCoW priority and an acceptance criterion. Each NFR needs a metric, target, measurement point, and source. Leave NFR conflict analysis to `nfr-validation`.
11. **Self-check G1** against the checklist in `standards/architecture-quality-gates.md` §5. If the tier calls for a gate record (T2+), record G1 in `05-validation/quality-gates.md`, created from `templates/quality-gates.md`.
12. **Hand off.** Mode A/C goes to `architecture-design`. Mode B goes to `architecture-review`. Pass along the open ASMs whose validation is needed before G3.

### Scaling by tier

| Tier | Depth |
|---|---|
| T1 | A short brief. Use the material questions only and record most gaps as ASMs. G1 is lightweight. |
| T2 | Full coverage table. Name the decision owners. Seed the requirements file. |
| T3 | As T2, plus data classification and residency per source, regulatory scan, human-oversight design, and named residual-risk acceptors. |
| T4 | As T3, plus regulator-facing obligations, safety-critical failure consequences, and explicit autonomy limits. Confirm the decision owners before design starts. |

## Coverage

| Area | What the brief must capture |
|---|---|
| Business goals and success metrics | The problem, objectives, a baseline, and target metrics with a measurement method. "Better" is not a metric. |
| Stakeholders and users | User groups and their volumes, sponsors, decision owners (constraints, risk, production), and operators |
| Current and future process | Today's steps, handoffs, and pain points. The proposed process, with where the system acts and where people act |
| Scope | In scope, out of scope, and the later phases |
| Functional requirements | `FR-###` items with priority and acceptance criteria |
| Non-functional requirements | `NFR-###` items with a measurable target: latency, availability, throughput, accuracy or quality, cost per transaction, RTO/RPO, retention |
| Data | For each source: owner, classification, residency, volume, freshness, quality, access path, and lawful basis where relevant |
| Integration dependencies | Systems of record, APIs, events, identity providers, and the owner and SLA of each |
| Constraints, prohibitions, preferences | Classified per `standards/architecture-principles.md` §2 |
| Risk tier | Tier with a rationale for each factor |
| Human oversight | Which decisions need human approval, review, or override, and who is accountable |
| Open questions and assumptions | `Q-###` (asked) and `ASM-###` (proceeding without an answer) |
| Acceptance criteria | Business-level criteria that make the engagement a success |

### Baseline table (Mode B/C)

| Aspect | Intended (documented) | Implemented (observed) | Evidence (path, or "not provided") | Gap |
|---|---|---|---|---|

Rows: purpose, users, components, data stores, models and prompts, tools and integrations, identity and authorization, deployment, monitoring, evaluation. If something is described but you couldn't observe it, the "Implemented" column says "Not inspected".

## Question bank

★ = material: the answer can change the architecture. Pick from this bank. Don't send it all.

**Business and outcome**
- ★ What decision or outcome does this change, and how will success be measured (baseline → target)?
- What happens today if the system is wrong, slow, or unavailable?
- ★ Is there a deadline or a fixed budget envelope?

**Users and exposure**
- ★ Who uses it: an internal team, the whole workforce, customers, or the public? How many users, and at what peak concurrency?
- Which channels does it run in (web, chat, email, API, embedded in an existing application)?

**Process and actions**
- ★ Is the output advisory, a draft for human review, or an action written to a business system?
- ★ Which actions need human approval, and are any irreversible or financial?
- Which steps are fixed rules, and which need judgment over unstructured content?

**Data and knowledge**
- ★ What is the highest data classification involved? Is there PII, regulated data, or special-category data?
- ★ Are there residency, sovereignty, or no-external-processing rules?
- Who owns each source, how fresh must it be, and are document-level permissions enforced today?
- Must answers cite their sources?

**Integration and platform**
- ★ Is a cloud, platform, or on-premises/air-gapped deployment mandated or prohibited?
- ★ What existing workflow, integration, AI, or search platforms must be reused or considered?
- Which identity provider is used, and must the system act on behalf of the user?

**Quality and NFRs**
- ★ What latency, availability, and volume are required (p95, uptime, daily transactions)?
- What accuracy or error rate is acceptable, and which errors are unacceptable?
- What is the per-transaction or monthly cost ceiling?

**Governance and risk**
- ★ Which regulations, internal AI policies, or audit obligations apply?
- Who accepts residual risk and approves production?
- What are the retention and audit-log requirements?

**Operations**
- Who operates and supports the system after go-live?
- Are there change-management or release-window rules?

## Outputs

- `use-cases/<id>/00-intake/use-case-brief.md`, containing the required headings from `docs/conventions.md` §3 (Engagement Classification · Business Objectives · Scope · Stakeholders · Input Classification · Open Questions) and the Mode and Risk tier metadata lines
- `use-cases/<id>/01-requirements/requirements.md` (seeded, at T1+ when design follows)
- `use-cases/<id>/05-validation/quality-gates.md` with the G1 row (T2+)

## Quality gates touched

- **G1 Discovery completeness:** primary owner.
- **G2:** seeds the requirements. Traceability is completed later by `architecture-design` and `nfr-validation`.

## Failure conditions

- **Stop and ask** when two inputs contradict each other (for example, a CON mandates a platform that a PRH forbids), when the tier can't be set without an answer, or when no decision owner can be identified for T3/T4.
- **Mark G1 FAIL** when there are no measurable success metrics, inputs are unclassified, or a material question is neither answered nor recorded as an ASM.
- **Don't proceed with Mode B** if no baseline artifacts are available and the user can't describe the implementation. Record this, and offer a Mode A design instead.
- **Never** invent stakeholders, volumes, or data classifications. If you lack the facts, use an ASM.

## References

- `CLAUDE.md` §1 (classification), §5 (isolation)
- `docs/operating-model.md` §2, `docs/conventions.md` §1–§4
- `standards/architecture-principles.md` §2, `standards/architecture-quality-gates.md` §2, §5 (G1)
- `templates/use-case-intake.md`, `templates/requirements.md`, `templates/quality-gates.md`
- Next: `architecture-design` (Mode A/C), `architecture-review` (Mode B), `nfr-validation`

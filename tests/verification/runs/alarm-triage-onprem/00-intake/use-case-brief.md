# Use-Case Brief: Daily SCADA Alarm Triage (On-Premises)

> Fictional test fixture. No real stakeholders, systems, or data are referenced. Names below are roles, not people.

## Engagement Classification

- **Use-case ID:** alarm-triage-onprem
- **Mode:** A
- **Risk tier:** T1
- **Date:** 2026-10-27
- **Board chair:** Coordinator session (Claude Code), acting Architecture Board Chair
- **Decision owner(s):** Maintenance Manager (business scope, acceptance, rulebook ownership); IT Infrastructure Lead (on-prem platform, server and SMTP use); Information Security Officer (security policy interpretation, residual risk); Production approval: Maintenance Manager + IT Infrastructure Lead jointly. All roles are assumed (ASM-008).
- **Status:** Draft

The user asked for immediate progress, so no questions were sent. Every material gap is recorded as an `ASM-` item and mirrored as an open `Q-` item for the decision owners.

### Tier rationale

| Factor | Observed value | Tier triggered | Source |
|---|---|---|---|
| Users / exposure | 1 supervisor + 3 crew leads, internal maintenance team | T1 | User request |
| Data | Equipment sensor alarm records (asset IDs, alarm codes, values, timestamps). No personal data. Assumed Internal classification (ASM-001) | T1 (T2 if classified Confidential/OT-restricted) | User request; ASM-001 |
| Actions / side effects | Read a CSV, write a run log, email an advisory list to a fixed internal distribution list. No writes to SCADA, CMMS, or work orders | T1 | User request |
| Autonomy | None: deterministic rules (rung 1–2) | T1 | Phase B result (solution-design.md) |
| Business impact of failure | Wrong or missing morning list delays non-urgent maintenance planning; real-time safety alarms are handled separately by control-room operators (ASM-002) | T1 (T2–T3 if ASM-002 is false) | User request; ASM-002 |
| Regulatory | No sector regulation stated for this reporting step. An internal security policy mandates on-prem hosting; treated as a deployment constraint (CON-001) satisfied by design, not as a governance regime over the activity (see note) | T1 (T2 under a literal reading) | User request |

**Resulting tier: T1.** No factor exceeds T1 under the stated assumptions. Two factors carry an assumption that would move the tier: ASM-001 (data classification) and ASM-002 (no safety reliance on the morning list).

*Note on the Regulatory row:* the tier table lists "Internal policy" under T2. Read literally, any engagement subject to an internal policy is T2. The board interprets that cell as an internal policy governing the activity itself (for example, an AI-use or audit policy). A hosting-location policy that the design fully satisfies doesn't raise the risk of the activity. If the Information Security Officer disagrees, the tier becomes T2 and the T2 deliverables (threat model, quality gates, roadmap) are owed. Tracked as Q-006.

**Tier would move up if:** the list auto-creates or closes work orders in a CMMS (T3: writes to business systems); the list becomes the only path by which a safety-relevant alarm reaches a person (T3–T4); data is classified Confidential or OT-restricted (T2); an LLM step is added (T2 for autonomy factor).

## Business Objectives

**Problem statement:** Each morning a maintenance supervisor manually reads yesterday's SCADA historian alarm export (~2,000 rows), applies a fixed rulebook of ~40 rules (thresholds, alarm codes, asset criticality), and emails a prioritized list to 3 crew leads. This takes ~90 minutes of supervisor time per day (~7.5 h/week at 5 days, ASM-003) and depends on one person being available.

| ID | Objective | Success metric | Baseline | Target | Measured by |
|---|---|---|---|---|---|
| OBJ-01 | Remove manual triage effort | Supervisor minutes per day spent producing the list | 90 min (user-stated) | ≤ 10 min (review only) | Supervisor time log for 4 weeks before and after |
| OBJ-02 | Deliver the list earlier and reliably | Time the list reaches crew leads; delivery success rate | Varies; after ~90 min of manual work (ASM-004) | By 06:30 local on ≥ 99% of working days | Run log timestamps + SMTP relay acceptance |
| OBJ-03 | Apply the rulebook consistently | Agreement between automated list and the supervisor's manual list during parallel run | Not measured | 100% agreement on the rulebook's deterministic outcome; every disagreement explained as a manual error or a rulebook gap | Parallel-run comparison, 10 working days |
| OBJ-04 | Make the rulebook explicit and auditable | Share of rules encoded, versioned, and covered by a test | 0% (rulebook held as a document / in the supervisor's head, ASM-005) | 100% of active rules | Rulebook repository + test report |

- **Why now / business driver:** 90 min/day of skilled supervisor time; single-person dependency; CEO interest in automation.
- **What happens if we do nothing:** The effort and key-person risk continue. Nothing breaks.
- **Is AI assumed or demonstrated to be needed?** Assumed. The CEO would like the team to "use AI agents" (PREF-002). Phase B tests this against the solution ladder: the task is a fixed rulebook over structured rows, so AI isn't demonstrated to be needed.

## Scope

| In scope | Out of scope | Deferred (later phase) |
|---|---|---|
| Ingest the daily alarm CSV export | Changing SCADA, the historian, or real-time alarm handling | Direct query of the historian instead of a CSV export (ASM-006) |
| Apply the ~40-rule rulebook deterministically and rank results | Creating, updating, or closing work orders in a CMMS | Integration with a CMMS / work-order system |
| Email the prioritized list to the 3 crew leads (supervisor in copy) | Real-time alerting or paging | Trend reporting across days (repeat offenders) |
| Run log and history in the existing SQL Server | Any cloud service | A web view of the list |
| Rulebook as versioned, tested configuration | Predictive maintenance or anomaly detection | Optional LLM-written narrative summary, only if a measured need appears |

### Current and future process

- **Current process (as-is):** (1) Supervisor obtains yesterday's alarm CSV from the SCADA historian (manual export assumed, ASM-006). (2) Reads ~2,000 rows. (3) Applies ~40 rules: thresholds, alarm codes, asset criticality. (4) Orders the remaining alarms by priority. (5) Writes and sends an email to 3 crew leads. ~90 min.
- **Target process (to-be), in outline:** (1) The historian export lands in a fixed folder on the on-prem Windows server (scheduled export, or manual drop as fallback). (2) A scheduled Python job validates the file, applies the versioned rulebook, ranks results, records the run in SQL Server, and emails the list through the existing SMTP relay. (3) The supervisor spends a few minutes reviewing the email and handling exceptions. (4) Rule changes are requested by the supervisor and made as reviewed changes to the rulebook file, with tests.
- **Baseline artifacts available for inspection (Mode B/C):** Not applicable (Mode A). No sample CSV, rulebook, or server specification was provided.

### Data sources

| Source | Owner | Classification | Residency / sovereignty | Volume / frequency | Access path |
|---|---|---|---|---|---|
| SCADA historian alarm export (CSV) | Operations / SCADA team (ASM-008) | Internal (ASM-001) | On-premises only (CON-001) | ~2,000 rows/day, one file daily | File export to a share on the Windows server (ASM-006) |
| Alarm rulebook (~40 rules) | Maintenance Manager / supervisor | Internal | On-premises | ~40 rules, changes occasionally (ASM-005) | Today a document; to become a versioned config file |
| Asset criticality list | Maintenance / asset management (ASM-007) | Internal | On-premises | Hundreds to low thousands of assets (assumed) | Assumed to be a list maintained alongside the rulebook (ASM-007) |
| Crew-lead distribution list | Maintenance supervisor | Internal (contains work email addresses) | On-premises | 3 recipients | Configuration file; no addresses in deliverables |

## Stakeholders

| Name / role | Interest | Influence | Decision rights | Consulted for |
|---|---|---|---|---|
| Maintenance supervisor (role) | Gets 90 min/day back; trusts the list | High | Accepts list quality in the parallel run; requests rule changes | Rulebook content, edge cases |
| Crew leads ×3 (role) | Clear, timely, prioritized list | Medium | None | Email format |
| Maintenance Manager (role) | Effort, reliability, crew productivity | High | Business scope and acceptance; owns the rulebook | Priorities, success metrics |
| IT Infrastructure Lead (role) | Server load, supportability, Python standard | High | Platform use (Windows server, SQL Server, SMTP relay); production approval with Maintenance Manager | Hosting, service accounts, backup |
| Information Security Officer (role) | Policy compliance, OT data handling | High | Interpretation of the on-prem policy; security residual-risk acceptance | Data classification, access |
| SCADA / Operations team (role) | Historian stability | Medium | Historian export configuration | Export format, schedule |
| CEO (role) | Visible use of AI; modernisation | High (sponsor) | Strategic direction; not the technical design owner | Rationale for the rung choice (ADR-001) |

## Input Classification

| ID | Statement (as given) | Source | Category rationale | Required treatment |
|---|---|---|---|---|
| CON-001 | "Everything must run on-premises (security policy, no cloud services)" | User request | "Must" + "security policy" | Design within it; no cloud service, no cloud-hosted model, no SaaS |
| PRH-001 | No cloud services | User request (same policy as CON-001) | Explicit exclusion | Exclude cloud services from every option, including package or model downloads at runtime |
| INV-001 | Existing on-prem Windows server | User request | Running infrastructure | Assess reuse as the runtime host |
| INV-002 | Existing SQL Server | User request | Running infrastructure | Assess reuse for run log and history |
| INV-003 | Existing SMTP relay | User request | Running infrastructure | Assess reuse for email delivery |
| INV-004 | SCADA historian with CSV alarm export | User request | Existing system and interface | Reuse the export as the input contract |
| PREF-001 | "Our IT team prefers Python" | User request | "Prefers" | Evaluate; adopt if it fits |
| PREF-002 | "The CEO would like us to 'use AI agents'" | User request | "Would like"; no requirement attached | Evaluate against the solution ladder and the agentic justification test; recommend otherwise if evidence favours it, with reasons (ADR-001) |
| DEC-001 | Solution pattern (ladder rung) | Phase B | Not yet decided | Decide in solution design; ADR-001 |
| DEC-002 | Where the rulebook lives and how it changes | Design | Not yet decided | Decide in solution design |
| DEC-003 | Scheduler and runtime packaging on the Windows server | Design | Not yet decided | Decide in solution design |
| ASM-001 | Alarm data is Internal, not Confidential/OT-restricted | Architect | No classification provided | See register |
| ASM-002 | The morning list is not a safety control | Architect | Not stated | See register |
| ASM-003 | 5 working days/week | Architect | Not stated | See register |
| ASM-004 | No current delivery-time commitment | Architect | Not stated | See register |
| ASM-005 | The rulebook is fully deterministic and documented | Architect | "Fixed rulebook" stated; content not provided | See register |
| ASM-006 | The historian can export the CSV on a schedule to a file share | Architect | Not stated | See register |
| ASM-007 | Asset criticality is available as a maintainable list | Architect | "Asset criticality" mentioned as a rule input | See register |
| ASM-008 | Decision-owner roles as listed above | Architect | No names given | See register |
| ASM-009 | An internal Python package mirror or offline wheel store exists | Architect | Not stated; affects CON-001 at build time | See register |
| ASM-010 | The Windows server has spare capacity and is backed up | Architect | Not stated | See register |
| ASM-011 | The historian's own alarm reporting can't apply the full rulebook | Architect | Not assessed; affects rung 0 | See register |

### Assumption register

| ID | Assumption | Impact if wrong | Confidence (H/M/L) | Validation method | Owner | Validate by |
|---|---|---|---|---|---|---|
| ASM-001 | Alarm export data is classified Internal | Tier rises to T2; tighter access control, encryption, and T2 deliverables needed | M | Ask Information Security Officer to classify the export | Information Security Officer | Before build |
| ASM-002 | Real-time safety alarms are handled by the control room; the morning list is planning only | Failure impact rises to T3+; would need redundancy, monitoring, and fail-loud controls | M | Confirm with Operations and Maintenance Manager | Maintenance Manager | Before build |
| ASM-003 | The list is produced 5 working days a week | Benefit estimate changes (~7.5 h/week); schedule changes | M | Confirm with supervisor | Maintenance supervisor | Before build |
| ASM-004 | There is no current delivery-time commitment; 06:30 is a proposed target | NFR-001 target changes | L | Confirm with crew leads | Maintenance Manager | Before build |
| ASM-005 | All ~40 rules are deterministic (thresholds, code lists, criticality) and can be written down unambiguously; no rule needs human judgement over free text | If some rules need judgement over free-text alarm descriptions, a rung 4 step may be justified for those rules only | M | Rulebook workshop: encode all rules and replay 10 historical days | Maintenance supervisor | Week 1 |
| ASM-006 | The historian can write the daily export to a file share on a schedule | Without it, the supervisor still drops the file manually (~2 min), or a direct read-only DB/OPC query is needed | M | Check with SCADA team | SCADA / Operations team | Week 1 |
| ASM-007 | Asset criticality exists as a list that can be exported or maintained as config | Otherwise a criticality list must be created and owned | M | Check with asset management | Maintenance Manager | Week 1 |
| ASM-008 | Decision-owner roles are as listed; names to be supplied | Wrong approver | M | Confirm with sponsor | Maintenance Manager | Before build |
| ASM-009 | Python and the needed packages can be installed from an internal mirror or offline wheels, without reaching a public cloud service from the server | If not, use only the standard library plus pre-approved packages; CON-001 interpretation question for the ISO | M | Check with IT Infrastructure Lead and ISO | IT Infrastructure Lead | Before build |
| ASM-010 | The existing Windows server has spare capacity (trivial load: one ~2,000-row file/day) and is in the backup scope | Need another host or backup scope change | H | Check server monitoring and backup policy | IT Infrastructure Lead | Before build |
| ASM-011 | The SCADA historian's built-in alarm reports or filters can't express the full rulebook and email it | If they can, rung 0 (configure the historian) wins and no new code is needed | L | SCADA team checks historian alarm-reporting features against the rulebook | SCADA / Operations team | Week 1 (before build starts) |

## Open Questions

Not sent to the user (instruction to proceed on assumptions). Each is tracked through its ASM and must be closed by the named role.

| ID | Question | Why it matters (what it could change) | Directed to | Status | Answer / resolution |
|---|---|---|---|---|---|
| Q-001 | Can the historian's own alarm reporting apply the rulebook and email the result? | Could make this rung 0 (no new system) | SCADA / Operations team | Open | Proceeding on ASM-011 |
| Q-002 | Is the morning list ever the only way a safety-relevant alarm reaches a person? | Tier T1 → T3/T4; fail-loud and redundancy design | Maintenance Manager | Open | Proceeding on ASM-002 |
| Q-003 | What is the classification of the alarm export? | Tier T1 → T2; access and encryption controls | Information Security Officer | Open | Proceeding on ASM-001 |
| Q-004 | Can you share the rulebook and two sample exports? | Confirms rung 1 is sufficient; drives the rule schema | Maintenance supervisor | Open | Proceeding on ASM-005 |
| Q-005 | Can the export be scheduled to a file share? | Removes the last manual step | SCADA / Operations team | Open | Proceeding on ASM-006 |
| Q-006 | Does the on-prem security policy count as "internal policy" for risk tiering? | Tier T1 → T2 and the T2 deliverable set | Information Security Officer | Open | Board interpretation: no (see tier note) |
| Q-007 | Does installing packages from an internal mirror satisfy the "no cloud services" policy? | Build and supply-chain approach | Information Security Officer | Open | Proceeding on ASM-009 |

## G1 Discovery Checklist

- [x] Problem, objectives, and measurable success metrics stated
- [x] Mode and tier assigned, with tier rationale
- [x] Stakeholders and decision owners named (as roles; names pending, ASM-008)
- [x] As-is / to-be process and scope boundaries described
- [x] All inputs classified (CON/PREF/INV/DEC/ASM/PRH)
- [x] Data sources, classification, ownership, and residency recorded (classification assumed, ASM-001)
- [x] Material questions recorded as ASMs with owners (not asked, by instruction)

**G1 (lightweight, T1): PASS-WITH-CONDITIONS.** Conditions: ASM-001, ASM-002, ASM-011 validated before build (owners above).

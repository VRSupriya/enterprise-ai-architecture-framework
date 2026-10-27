# Requirements: Daily SCADA Alarm Triage (On-Premises)

- **Use-case ID:** alarm-triage-onprem
- **Version / date:** v0.1 / 2026-10-27
- **Baselined from:** 00-intake/use-case-brief.md (2026-10-27)

T1 depth. Test IDs (`TST-`) are defined in the Verification summary below. A separate test-and-evaluation plan isn't required at T1 (`docs/conventions.md` §4).

## Functional Requirements

| ID | Statement | Priority | Source | Acceptance criterion |
|---|---|---|---|---|
| FR-001 | The system reads the previous day's alarm CSV export from the configured drop folder and validates it before processing: expected columns present, types parse, row count within configured bounds, export date matches the expected day | Must | OBJ-01, INV-004 | On TST-001, valid files are accepted; files with a missing column, unparsable value, wrong date, or 0 rows are rejected with a named reason and no list is sent |
| FR-002 | The system evaluates every alarm row against every active rule in the versioned rulebook (thresholds, alarm codes, asset criticality) and records, per row, include/exclude, priority, and the IDs of the rules that matched | Must | OBJ-03, ASM-005 | On TST-002, each rule has at least one positive and one negative unit test that passes; on TST-003, output matches the supervisor-labelled reference for 10 replayed historical days |
| FR-003 | The system ranks included alarms with a deterministic order: priority, then asset criticality, then most recent occurrence, then asset ID | Must | OBJ-03 | On TST-003, ranking matches the reference exactly; two runs on the same input and rulebook produce byte-identical lists |
| FR-004 | The system emails the ranked list to the configured crew-lead distribution list, with the supervisor in copy, through the existing SMTP relay. The email states the run date, rulebook version, rows read, rows listed, and rows rejected by validation | Must | OBJ-01, OBJ-02, INV-003 | On TST-004, the relay accepts the message for all configured recipients; the email body contains all listed fields |
| FR-005 | If the input file is missing by the cut-off, fails validation, or the job fails, the system sends a failure notice to the supervisor and IT support mailbox instead of a list. It never sends a partial or stale list as if complete | Must | OBJ-02, ASM-002 | On TST-005, each injected failure (no file, invalid file, rule-file error, database down, relay down) results in the defined notice or, if the relay is down, an error in the Windows event log and run log |
| FR-006 | Each listed alarm shows the rule IDs that included and prioritized it | Should | OBJ-04 | On TST-003, every listed row has ≥ 1 rule ID and the IDs exist in the rulebook version used |
| FR-007 | The rulebook and asset-criticality list are held as versioned configuration. Each rule has an ID, description, owner, and test. Changes are made as reviewed changes and are deployed only when all rule tests pass | Must | OBJ-04, DEC-002 | On TST-006, a rule change without a passing test can't be deployed; the email shows the new rulebook version after deployment |
| FR-008 | Each run is recorded in SQL Server: run ID, run date, input file hash, rulebook version, row counts, listed rows with matched rule IDs, delivery status | Should | OBJ-02, OBJ-04, INV-002 | On TST-007, every run (success or failure) has exactly one run record, queryable by date |
| FR-009 | Runs are idempotent per export date: a re-run for a date that was already delivered doesn't email again unless an operator passes an explicit re-send flag | Should | OBJ-02 | On TST-007, a second run for the same date sends nothing without the flag and sends once with it |
| FR-010 | An authorised operator can run the job manually for a given date (re-run after fixing a file) | Could | OBJ-02 | On TST-005, a manual run for a named date produces the list for that date |
| FR-011 | Creating, updating, or closing work orders in any CMMS | Won't (this release) | Scope | — |

### Human-in-the-loop and side-effect requirements

| FR ID | Action / side effect | Target system | Approval required? (who) | Reversible? | Deterministic control |
|---|---|---|---|---|---|
| FR-004 | Send the daily list email | SMTP relay → internal mailboxes | No per-run approval; the supervisor reviews the list after delivery. During the 10-day parallel run the supervisor compares it with the manual list | No (an email can't be recalled), low impact | Recipients from config only, never from input data; internal domains only; one send per date (FR-009) |
| FR-005 | Send a failure notice | SMTP relay → supervisor, IT support mailbox | No | No, low impact | Fixed recipients from config |
| FR-008 | Write run record | SQL Server (own schema) | No | Yes | Service account can write only its own schema |

## Non-Functional Requirements

| ID | Category | Metric | Target | Percentile / conditions | Measurement point | Method | Source | Test ID | Status |
|---|---|---|---|---|---|---|---|---|---|
| NFR-001 | Availability | List (or failure notice) delivered by cut-off | Delivered by 06:30 local | ≥ 99% of working days per quarter, given the export arrives by 05:30 | SMTP relay acceptance time in run log | Run-log report, monthly | OBJ-02, ASM-004 | TST-008 | Proposed |
| NFR-002 | Performance | Job wall-clock time, file arrival to email accepted | ≤ 2 min | Up to 10,000 rows (5× today's volume), 40–200 rules | Run log start/end timestamps | Synthetic 10k-row file in test | Architect proposal | TST-008 | Proposed |
| NFR-003 | Quality | Agreement with the supervisor-labelled reference (inclusion + priority + order) | 100%, every discrepancy explained | 10 replayed historical days, then 10 live parallel-run days | Golden-file comparison | Automated diff + supervisor sign-off | OBJ-03 | TST-003 | Proposed |
| NFR-004 | Security | Privileges of the job's identity | Dedicated service account: read on drop folder; read/write on its own SQL schema only; SMTP send to internal domains; no interactive logon | Production | Windows/AD and SQL Server permission review | Permission review checklist | CON-001, standards/security-and-identity.md SEC-01 | TST-009 | Proposed |
| NFR-005 | Compliance | Outbound connections to non-internal destinations at runtime | 0 | Production and test environments | Server host firewall / network egress logs | Egress rule review + log check during parallel run | CON-001, PRH-001 | TST-010 | Proposed |
| NFR-006 | Operability | Time from a failed or missed run to a human being notified | ≤ 15 min after the scheduled run time | All failure modes in FR-005, including "job never started" | Notice timestamp vs schedule | Fault injection | OBJ-02 | TST-005 | Proposed |
| NFR-007 | Operability | Lead time for a rulebook change, request to production | ≤ 1 working day | Change with tests passing | Change record timestamps | Process review after first 3 changes | OBJ-04 | TST-006 | Proposed |
| NFR-008 | Compliance | Run-history retention | 13 months, then purge | Proposed default; to confirm with Maintenance Manager | SQL Server run tables | Scheduled purge job + query check | Architect proposal | TST-007 | Proposed |
| NFR-009 | Cost | New licences, hardware, or paid services | None; reuse INV-001..INV-003 | Steady state | Procurement record | Design review | CON-001, INV-001..003 | TST-009 | Proposed |

### NFR conflicts

None identified. Volumes are small (≈ 2,000 rows/day) and every NFR is met by a single scheduled job on existing infrastructure. `nfr-validation` was not run as a separate skill at T1; this is the coordinator's judgement `[JUDGMENT]`.

## Constraints and Assumptions

### Constraints, prohibitions, preferences, investments, and open decisions

| ID | Category | Statement | Source | Treatment | Affected requirements | Conflict? (decision owner) |
|---|---|---|---|---|---|---|
| CON-001 | Mandatory constraint | Everything runs on-premises (security policy) | User request | Respected: all components on INV-001..INV-004 | All; NFR-005 | No |
| PRH-001 | Prohibition | No cloud services | User request | Excluded from every option, including cloud LLM APIs and SaaS schedulers or email | NFR-005 | No. Build-time package source is an open interpretation point (Q-007, ASM-009) |
| INV-001 | Existing investment | On-prem Windows server | User request | Reused as runtime host | NFR-001, NFR-009 | — |
| INV-002 | Existing investment | SQL Server | User request | Reused for run history (FR-008) | FR-008 | — |
| INV-003 | Existing investment | SMTP relay | User request | Reused for delivery | FR-004, FR-005 | — |
| INV-004 | Existing investment | SCADA historian CSV export | User request | Reused as the input contract | FR-001 | — |
| PREF-001 | Preference | Python | IT team | Adopted: fits, team can support it, standard library covers CSV and SMTP | FR-001..FR-010 | — |
| PREF-002 | Preference | "Use AI agents" | CEO | Evaluated and not adopted for this release (ADR-001): no requirement is served by an agent or an LLM | FR-002, FR-003, NFR-003 | — |
| DEC-001 | Open decision | Solution pattern | Phase B | ADR-001 (Proposed) | All | — |
| DEC-002 | Open decision | Rulebook storage and change process | Design | Design note: versioned file in on-prem source control, with tests (solution-design.md) | FR-007 | — |
| DEC-003 | Open decision | Scheduler and packaging | Design | Design note: Windows Task Scheduler + pinned Python virtual environment | NFR-001 | — |

### Assumptions

Full register in `00-intake/use-case-brief.md`. Those that shape requirements:

| ID | Assumption | Impact if wrong | Confidence (H/M/L) | Validation method | Owner | Deadline | Status |
|---|---|---|---|---|---|---|---|
| ASM-002 | The list is planning only, not a safety control | Tier and FR-005/NFR-006 hardening | M | Confirm with Operations | Maintenance Manager | Before build | Open |
| ASM-004 | 06:30 is acceptable as the delivery cut-off | NFR-001 target | L | Ask crew leads | Maintenance Manager | Before build | Open |
| ASM-005 | All rules are deterministic | A rung 4 step might be needed for specific rules | M | Encode rulebook, replay 10 days | Maintenance supervisor | Week 1 | Open |
| ASM-006 | Scheduled export to a share is possible | FR-001 input path | M | SCADA team check | SCADA / Operations team | Week 1 | Open |
| ASM-009 | Packages available from an internal mirror or offline wheels | Build approach under CON-001 | M | IT + ISO check | IT Infrastructure Lead | Before build | Open |

## Traceability

T1 depth: requirement → component → test. Components are defined in `02-design/solution-design.md` §Component Catalogue.

| Requirement | Priority | Component(s) | ADR(s) | Test / Eval ID(s) | Threat ID(s) | Notes |
|---|---|---|---|---|---|---|
| FR-001 | Must | C-01, C-02 | ADR-001 | TST-001 | — | No threat model at T1 |
| FR-002 | Must | C-03, C-04 | ADR-001 | TST-002, TST-003 | — | |
| FR-003 | Must | C-03 | ADR-001 | TST-003 | — | |
| FR-004 | Must | C-05 | — | TST-004 | — | |
| FR-005 | Must | C-02, C-05, C-07 | — | TST-005 | — | |
| FR-006 | Should | C-03, C-05 | — | TST-003 | — | |
| FR-007 | Must | C-04 | — | TST-006 | — | |
| FR-008 | Should | C-06 | — | TST-007 | — | |
| FR-009 | Should | C-02, C-06 | — | TST-007 | — | |
| FR-010 | Could | C-02 | — | TST-005 | — | |
| FR-011 | Won't | — | — | — | — | Out of scope this release |
| NFR-001 | — | C-07, C-02, C-05 | — | TST-008 | — | |
| NFR-002 | — | C-02, C-03 | — | TST-008 | — | |
| NFR-003 | — | C-03, C-04 | ADR-001 | TST-003 | — | |
| NFR-004 | — | C-02, C-06, C-05 | — | TST-009 | — | |
| NFR-005 | — | All | ADR-001 | TST-010 | — | |
| NFR-006 | — | C-07, C-05 | — | TST-005 | — | |
| NFR-007 | — | C-04 | — | TST-006 | — | |
| NFR-008 | — | C-06 | — | TST-007 | — | |
| NFR-009 | — | All | ADR-001 | TST-009 | — | |
| CON-001 | — | All | ADR-001 | TST-010 | — | |

### Verification summary

| Test ID | What it checks | Type | Requirements |
|---|---|---|---|
| TST-001 | Input validation: good file, missing column, bad value, wrong date, empty file | Unit + fixture files | FR-001 |
| TST-002 | One positive and one negative unit test per rule | Unit | FR-002 |
| TST-003 | Golden-file replay of 10 supervisor-labelled historical days; then 10-day live parallel run | Regression + acceptance | FR-002, FR-003, FR-006, NFR-003 |
| TST-004 | Email delivered via relay to test mailboxes; body fields present | Integration | FR-004 |
| TST-005 | Fault injection: no file, invalid file, bad rulebook, DB down, relay down, job not started; manual re-run | Integration | FR-005, FR-010, NFR-006 |
| TST-006 | Rule change blocked when its test fails; version shown after deploy | Pipeline / process | FR-007, NFR-007 |
| TST-007 | One run record per run; idempotent re-run; retention purge | Integration | FR-008, FR-009, NFR-008 |
| TST-008 | Timing: synthetic 10k-row file ≤ 2 min; monthly on-time report | Performance + operational | NFR-001, NFR-002 |
| TST-009 | Service-account permission review; no new licences | Review checklist | NFR-004, NFR-009 |
| TST-010 | Egress rules allow only internal SMTP, SQL, and file share; egress logs clean during parallel run | Review + log check | NFR-005, CON-001 |

### Orphan check

- [x] Every Must FR and NFR has at least one component and at least one test
- [x] Every component in the catalogue appears in at least one row (C-01..C-07)
- [x] No row references a Withdrawn requirement or a Superseded ADR as current

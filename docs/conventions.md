# Framework Conventions

This is the single source for artifact layout, IDs, required section headings, and the specialist report format. The validators in `tools/` check against this file, so a change here must be mirrored in `tools/validate-deliverables.sh`.

## 1. Use-case artifact layout

Run `tools/new-use-case.sh <use-case-id>` to create:

```text
use-cases/<use-case-id>/
  00-intake/use-case-brief.md            ← templates/use-case-intake.md
  01-requirements/requirements.md        ← templates/requirements.md (includes §Traceability)
  02-design/solution-design.md           ← templates/solution-design.md      (Mode A/C, and Mode B target)
  02-design/technology-evaluation-<topic>.md  (optional, one per evaluation)
  03-review-board/review-report.md       ← templates/review-report.md        (Mode B, or any formal review)
  03-review-board/round-<n>/<agent-name>.md   (specialist reports, saved verbatim by the coordinator)
  03-review-board/debate-record.md       ← templates/debate-record.md
  04-decisions/adr/ADR-NNN-<slug>.md     ← templates/architecture-decision-record.md
  04-decisions/decision-log.md           (index of ADRs and their status)
  05-validation/threat-model.md          ← templates/threat-model.md
  05-validation/nfr-validation.md        (output of nfr-validation)
  05-validation/test-and-evaluation-plan.md ← templates/test-and-evaluation-plan.md
  05-validation/quality-gates.md         ← templates/quality-gates.md
  06-delivery/implementation-roadmap.md  ← templates/implementation-roadmap.md
  06-delivery/backlog.md                 (large backlogs split out of the roadmap)
  06-delivery/runbooks/                  (as needed)
```

Create files only when the engagement needs them (see §4 for the minimum per tier). Don't commit empty templates as if they were deliverables. A file still holding template guidance must keep its `<!-- TEMPLATE -->` marker, which makes the validator report it as unfilled.

## 2. ID scheme

| Prefix | Artifact | Example |
|---|---|---|
| `FR-` / `NFR-` | Functional / non-functional requirement | `NFR-007` |
| `CON-` `PREF-` `INV-` `DEC-` `ASM-` `PRH-` | Input classification (`standards/architecture-principles.md` §2) | `CON-001` |
| `Q-` | Open question | `Q-004` |
| `RSK-` | Risk | `RSK-012` |
| `C-` | Component in the component catalogue | `C-05` |
| `ADR-` | Architecture decision record (3 digits) | `ADR-004` |
| `F-<AREA>-` | Review finding. AREA = EA, SA, AG, PL, DK, SE, IN, RE, RT, or BRD (board-consolidated) | `F-SE-03` |
| `T-` | Threat | `T-011` |
| `TST-` / `EVAL-` | Test case / evaluation case | `TST-020` |
| `WS-` / `MS-` / `BL-` | Workstream / milestone / backlog item | `WS-03` |
| `OBJ-` | Business objective (intake) | `OBJ-02` |
| `TB-` / `DF-` | Trust boundary / data flow (threat model) | `TB-01` |
| `DBT-` / `RES-` | Debate objection / debate resolution | `DBT-04` |

IDs are stable. Don't renumber; mark retired items `Withdrawn` instead.

## 3. Required section headings

The validator matches these level-2 headings (`## …`) exactly, case-insensitively. Templates add further sections; these are the minimum.

| File | Required `##` headings |
|---|---|
| `use-case-brief.md` | Engagement Classification · Business Objectives · Scope · Stakeholders · Input Classification · Open Questions |
| `requirements.md` | Functional Requirements · Non-Functional Requirements · Constraints and Assumptions · Traceability |
| `solution-design.md` | Executive Summary · Solution Approach · Architecture Overview · Component Catalogue · Technology Selection · Security and Identity · Data and Knowledge · Operations and Reliability · Risks and Open Decisions |
| `review-report.md` | Scope and Baseline · Findings · Disposition · Target Architecture · Remediation Roadmap |
| `debate-record.md` | Proposal · Objections · Resolutions · Residual Risks |
| `ADR-*.md` | Status · Context · Decision · Alternatives Considered · Consequences · Revisit Triggers |
| `threat-model.md` | Scope and Assets · Trust Boundaries · Threats · Residual Risk |
| `test-and-evaluation-plan.md` | Verification Matrix · AI Evaluation · Adversarial Testing · Release Criteria |
| `quality-gates.md` | Gate Results |
| `implementation-roadmap.md` | Workstreams · Milestones · Dependencies · Operational Readiness · Rollout and Rollback · Risks |

The brief must contain these metadata lines, which the validator parses:

```markdown
- **Mode:** A            (A | B | C | Focused)
- **Risk tier:** T2      (T1 | T2 | T3 | T4)
```

## 4. Minimum deliverables per tier

| Tier | Required files (beyond the brief) |
|---|---|
| Focused | Whatever the focused skill produces |
| T1 | requirements, plus solution-design (A/C) or review-report (B). Gate results go in a `## Quality Gates` section of that document. Test IDs may be defined in the requirements' acceptance criteria or a design test table instead of a separate test plan |
| T2 | T1 + at least one ADR + threat-model + quality-gates + implementation-roadmap |
| T3 / T4 | T2 + test-and-evaluation-plan + debate-record + `round-*/red-team-architect.md` |

## 5. Specialist report format

Every specialist agent returns this structure. The coordinator saves it verbatim.

```markdown
# <Specialist name> — <use-case-id> — Round <n>

## Verdict
One paragraph: overall assessment for this specialist's domain. Use one of: Sound · Sound with conditions · Material gaps · Not viable as proposed.

## Evidence Examined
Files, sections, and sources actually read. List anything requested but not available.

## Findings
| ID | Severity | Affects | Evidence (path/source) | Basis | Issue | Impact | Remediation | Acceptance criterion | Verification |
|---|---|---|---|---|---|---|---|---|---|
Basis ∈ Verified fact · Inference · Assumption · Unverified concern. Severity per `.claude/skills/architecture-review/references/severity-rubric.md`.

## Recommendations
For each material decision in scope: Recommended / Alternative (only if meaningful) / Rejected (only if valuable), with requirement IDs.

## Positions for the Board
Points where this specialist expects disagreement from other domains, and what evidence would change their mind.

## Assumptions and Open Questions

## Not Verified
What this specialist couldn't confirm and how to verify it.
```

## 6. Evidence and dates

- Use evidence labels as defined in `standards/architecture-principles.md` §3.
- Time-sensitive claims carry `(source: <URL>, accessed YYYY-MM-DD)`.
- Knowledge-base entries carry `Last verified: YYYY-MM-DD` and a confidence (High/Medium/Low).

## 7. Diagrams

- Mermaid is preferred, in fenced ```` ```mermaid ```` blocks inside the relevant document, or in `02-design/diagrams/*.md`.
- Every diagram has a title line (`%% Title: …`) and a one-sentence caption below the block.
- Node names match the component catalogue (`C-` IDs or exact names).

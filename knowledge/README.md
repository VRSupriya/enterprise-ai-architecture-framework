# Knowledge Base (Layer B: Evolving Technology Knowledge)

- **Last verified:** 2026-10-27 (structure and policy; individual entries carry their own dates)
- **Confidence:** High for the policy in this file; per-entry confidence varies

## Purpose

This folder is the framework's **Layer B**: dated, evidence-labelled knowledge about technology categories, products, models, and deployment patterns. It sits between:

| Layer | Location | Changes | Authority |
|---|---|---|---|
| A. Stable principles | `standards/` | Only by explicit framework decision | Binding on every engagement |
| **B. Evolving technology knowledge** | **`knowledge/`** | **Continuously, as the market moves** | **Decision aid only, never a mandate** |
| C. Use-case decisions | `use-cases/<id>/` | Per engagement, via ADRs | Binding only within that use case |

Layer B tells an architect *what options exist, what each is good for, what its current status is, and what to check*. It does **not** define an approved stack. A product appearing here is not a recommendation for any specific use case; a product missing from here is not prohibited. Every selection is still made per use case against that use case's requirements and constraints (`standards/architecture-principles.md` AP-01, AP-02) and recorded in that use case's ADRs.

## Contents

| File | Use it for |
|---|---|
| `technology-catalog.md` | Capability categories by domain: what each is for, when it is (and is not) needed, selection criteria, example options |
| `framework-comparison.md` | Comparing orchestration approaches (workflow engines, durable execution, agent frameworks), with decision guidance and a research log |
| `model-selection-guide.md` | Requirements-first model evaluation method, eval harness outline, managed vs self-hosted factors, model lifecycle |
| `deployment-patterns.md` | PaaS, Kubernetes, serverless, on-prem, air-gapped, hybrid, multi-region, edge; private connectivity and inference residency |
| `reference-architectures/` | Ten reusable patterns, each mapped to a solution-ladder rung. Patterns are starting points, not compulsory templates |

## Entry rules

1. **Dated.** Every file and every material time-sensitive entry carries `Last verified: YYYY-MM-DD` and a confidence (High / Medium / Low) per `docs/conventions.md` §6.
2. **Labelled.** Material claims carry an evidence label from `standards/architecture-principles.md` §3. Time-sensitive claims (versions, GA/preview status, licensing, naming, spec revisions) carry `(source: <URL>, accessed YYYY-MM-DD)`, or are marked `[UNVERIFIED]` with a reason.
3. **No fabrication.** No invented versions, dates, benchmarks, prices, or adoption figures. If a number could not be checked, it is omitted or marked `[UNVERIFIED]`.
4. **Examples, not rankings.** Options are listed alphabetically or by deployment model, with one-line positioning. There is no "best model" or "best framework" list, because "best" only exists relative to a requirement set.
5. **Vendor claims stay vendor claims.** Capability statements taken from vendor docs are `[VENDOR]`, even when they are probably true. `[VERIFIED]` means the fact (for example a license file, a spec version string, a package version) was confirmed against an authoritative primary source.

## Staleness rule

| Age of `Last verified` | Treatment |
|---|---|
| ≤ 3 months | Usable as context for a decision; still confirm anything that is decisive |
| 3–6 months | Usable for orientation; re-verify versions, lifecycle status, and licensing before citing in an ADR |
| **> 6 months** | **Stale. Re-verify before relying on it for any decision.** Mark the entry `STALE` in the next edit if it cannot be re-verified |

Regardless of age, re-verify immediately when: a vendor announces a rename, deprecation, or license change; a spec publishes a new revision; or the use case is T3/T4 and the entry is decisive for a G3 gate.

## How entries are updated

1. **The `technology-evaluation` skill proposes updates.** When an engagement researches a technology, the skill records the findings in the use case (`use-cases/<id>/02-design/technology-evaluation-<topic>.md`) and, where the finding is generally useful and not use-case-specific, proposes a diff to the relevant `knowledge/` file.
2. **The proposal contains** the claim, evidence label, source URL, access date, and which existing text it supersedes. Superseded facts are replaced (not appended as contradictions); material changes are noted in the file's research log where one exists.
3. **The coordinator (Board Chair) accepts or rejects** the proposal. Specialists are read-only toward this folder.
4. **Strip use-case context.** Requirement IDs, customer names, volumes, and enterprise-sensitive details never enter Layer B.

## What never happens here

- **A use-case decision never becomes a standard by landing here.** "Use case X chose LangGraph" is a Layer C fact. It may be cited as a precedent with a link, but it carries no weight in another use case until it is re-validated there (CLAUDE.md §5).
- Promoting anything from Layer B to Layer A (`standards/`) requires an explicit framework decision (`docs/extending-the-framework.md`), not an edit to this folder.
- An enterprise's existing investments (for example an installed workflow platform) are recorded as `INV-` inputs in a use case, not as defaults in this folder. The catalog and comparison discuss them only as common situations to reason about.

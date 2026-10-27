---
name: technology-evaluation
description: Researches and evaluates technologies, products, frameworks, models, and standards against a use case's requirements and constraints. Reuses existing investments first, uses current dated sources, scores against requirement-derived weights, and makes a decisive recommendation with a research log. Includes a model-selection mode. Use for "which framework/model/database should we use", "evaluate X vs Y", "is X a standard", "re-evaluate ADR-NNN", or any open DEC or PREF.
argument-hint: "<use-case-id> <topic> [candidates]"
---

# Technology Evaluation

## Purpose

Turn an open technology decision (`DEC`), a preference to test (`PREF`), or a re-evaluation trigger into a decisive, evidence-backed recommendation. The recommendation traces to requirements, respects constraints, and carries dated sources, so it can be re-checked later. This skill doesn't choose a default vendor. It applies `standards/architecture-principles.md` §2, §3, §5, and §6 to a specific decision.

## When to use / when not to use

| Use when | Don't use when |
|---|---|
| `architecture-design` step 7 has an open DEC, a PREF to test, or a new technology | The choice is fixed by a CON, and nobody disputes its fitness. Record it in the stack table and move on |
| An ADR revisit trigger fires (`docs/operating-model.md` §8) | The question is a pattern choice. That's the solution ladder in `architecture-design` |
| Someone asks "is X a standard?" or "is X production-ready?" | The decision is trivial and reversible (AP-11). A one-line `[JUDGMENT]` in the design is enough |
| Model selection (see "Model-selection mode") | |

## Inputs

- The decision statement, and the requirement, constraint, and investment IDs it touches (`01-requirements/requirements.md`, `00-intake/use-case-brief.md`)
- `knowledge/technology-catalog.md`, `knowledge/framework-comparison.md`, `knowledge/model-selection-guide.md`, `knowledge/deployment-patterns.md`: the starting point (layer B). Check each entry's `Last verified` date and confidence.
- Any candidate list the user or specialists supply

## Workflow

0. **Check the research tools.** Confirm whether WebSearch and WebFetch are actually available in this session. If they aren't, say so at the top of the output, and mark every time-sensitive claim `[UNVERIFIED]` with a validation step. Never present remembered facts as freshly researched.
1. **Define the exact decision or claim.** Write one sentence, such as "Select the orchestration framework for C-04 within CON-002", plus what's in and out of scope. Separate the claims (for example, "X supports Y in region Z") from the choice.
2. **Establish the candidates.**
   - **Existing investments come first.** Give each relevant INV an honest reuse assessment: fit, the gap, integration cost, debt, and migration cost. An INV is neither mandatory nor disposable by default.
   - **Don't add a second framework or platform merely for different features.** A new one needs a requirement the existing one can't meet at reasonable cost.
   - Add the PREF items, then other credible candidates within the CON boundary. Exclude PRH items. Within a mandated platform, don't add other clouds.
   - Keep the shortlist small (usually 2–4). Record a candidate that was screened out only if it was proposed or is commonly expected.
3. **Research current sources** in the preference order of `standards/architecture-principles.md` §3: official docs and release notes first, then standards bodies and regulators, then independent evaluations, engineering publications, and case studies. Community sources are supplementary only. Vendor marketing, GitHub stars, and leaderboard rank are never sufficient on their own.
4. **Verify the facts that decide the outcome** for each candidate: date, version, region availability, deployment model (managed, self-hosted, on-premises, air-gapped), licensing, data-use terms, and lifecycle or support status (GA, preview, deprecated, end-of-support date). Cite each one as `(source: <URL>, accessed YYYY-MM-DD)` with a label per §3.
5. **Derive the criteria and weights from the requirements.** Use the criteria below. Set each weight from the FR/NFR/CON IDs it serves, and drop the criteria nothing depends on. Any CON that a candidate fails eliminates it, and weights can't offset that.
6. **Score.** Use 1–5 per criterion, with a one-line rationale and evidence label for each score. State in the matrix: *"Scores are judgment aids, not measurements. The recommendation rests on the rationale and evidence, not on the arithmetic."* If totals land within noise of each other, say so and decide on the top-weighted criteria.
7. **Recommend decisively.** One **Recommended** option. An **Alternative** only if it's meaningful: a viable fallback, a portability or procurement need, or an unresolved strategic choice. A **Rejected** option only when recording it adds value, for example because a stakeholder proposed it. Include the lock-in and exit-cost note (AP-12) and the re-evaluation triggers.
8. **Record the research log** (see the skeleton below).
9. **Hand off.** If the decision is material, create or supersede an ADR via `adr-management`, citing this file. Update the `architecture-design` stack table.
10. **Propose knowledge updates (layer B).** If research found new or changed facts, propose dated edits to the relevant `knowledge/` entries (`Last verified: YYYY-MM-DD`, confidence). Keep the update separate: present it as a proposal for the user to approve, not as part of the use-case decision. A use-case choice never becomes a framework default or standard (layer C → A/B) without an explicit decision.

### Criteria

| Criterion | Typical sources of weight |
|---|---|
| Functional fit | Must FRs |
| NFR fit (latency, availability, quality, throughput) | NFR targets |
| Integration with existing landscape | INV, integration dependencies |
| Security and governance (identity, data handling, audit) | Security CONs, data classification |
| Operational maturity (observability, upgrades, support) | Operations NFRs, support model |
| Scalability and performance | Volume and peak NFRs |
| Deployment constraints (platform, region, network, air-gap) | Platform and residency CONs |
| Vendor and licensing (terms, data-use, exit) | Procurement CONs, AP-12 |
| Team capability | Staffing, skills ASMs |
| Total cost of ownership (build, run, people) | Cost ceilings |
| Maintainability and portability | Expected lifetime, AP-11 |
| Lifecycle status (GA, preview, deprecation) | Service-life expectations |
| Adoption evidence (independent, relevant to the context) | Risk tier |

### Maturity vocabulary

When asked whether something is a standard, classify it as exactly one of the following, with evidence: **Published standard** (a formal standards body or regulator) · **De facto practice** (broad independent adoption, documented) · **Vendor recommendation** · **Emerging practice** · **Experimental** · **Organization-specific choice**. Don't call a vendor recommendation or an emerging practice "the industry standard".

### Integrity rules

- Never fabricate adoption statistics, benchmarks, customer names, version numbers, or features. If you can't find something, say "not found", along with where you looked.
- A benchmark counts only with its workload, version, and date, and only if it matches this use case. Otherwise it's context, not evidence.
- Distinguish preview from GA, and "announced" from "available in region".

## Model-selection mode

Use this mode when the decision is a model or model tier. Follow `knowledge/model-selection-guide.md` for the current criteria and candidates, and verify its dated entries.

1. Define the tasks (extraction, classification, generation, reasoning, tool use) and the quality metric for each, taken from the NFRs.
2. **Evaluate on representative business data**, or a faithful sanitized sample, with the evaluation set defined in `standards/observability-and-evaluation.md`. Public leaderboards are only a screening tool.
3. Assess **prototype vs production suitability** separately: quotas, region, data-use terms, deprecation schedule, structured-output support, latency at the target load, and cost at expected and peak volume.
4. Prefer the smallest model that meets the thresholds. Add **routing or fallback only when there's a clear, measured benefit** (cost, latency, or availability), with an equivalent quality check on each route.
5. Record the model ID and version, the evaluation results (observed, or marked "not run"), and the re-evaluation triggers, such as a deprecation notice, a new version, quality drift, or a price change.

### Scaling by tier

| Tier | Depth |
|---|---|
| T1 | A short note: candidates, key facts with dates, the recommendation. No weighted matrix needed. |
| T2 | Full matrix for material decisions, research log, ADR |
| T3/T4 | As T2, plus a domain-specialist review of the evaluation and a red-team challenge of the recommendation (via `architecture-debate` if contested). Model evaluation results must be observed, not projected. |

## Output skeleton: `02-design/technology-evaluation-<topic>.md`

```markdown
# Technology Evaluation: <topic> — <use-case-id>
- **Decision:** <one sentence> · **Serves:** FR-…, NFR-…, CON-… · **Date:** YYYY-MM-DD
- **Research tools available:** Yes / No (if No, time-sensitive claims are [UNVERIFIED])

## Decision and Scope
## Candidates
| Candidate | Origin (INV/PREF/DEC/new) | Reuse assessment / reason included |
## Criteria and Weights
| Criterion | Weight | Derived from (IDs) |
## Evaluation Matrix
> Scores are judgment aids, not measurements.
| Criterion | Weight | <Candidate A> score · rationale · label | <Candidate B> … |
## Recommendation
- **Recommended:** … (IDs, rationale, lock-in and exit cost)
- **Alternative:** (only if meaningful) …
- **Rejected:** (only if valuable) …
## Research Log
| Technology | Capability / version | Evidence (URL, label) | Date researched | Deployment / licensing assumptions | Limitations and uncertainties | Reason selected / rejected | Re-evaluation triggers |
## Proposed Knowledge Updates (layer B, for approval)
| knowledge/ file | Entry | Change | Source | Last verified | Confidence |
## Not Verified
```

## Outputs

- `use-cases/<id>/02-design/technology-evaluation-<topic>.md`
- Input to `04-decisions/adr/ADR-NNN-<slug>.md` (via `adr-management`) and the stack table in `02-design/solution-design.md`
- Proposed, dated `knowledge/` updates, presented separately for approval

## Quality gates touched

**G3 Pattern and technology selection** (primary): existing investments assessed, choices recommended decisively, evidence dated and labeled, lock-in recorded, and re-evaluation triggers set. It also provides model-evaluation inputs to G8.

## Failure conditions

- **Stop and ask** when the only candidates that meet the Must requirements violate a CON or PRH. Raise the conflict per `standards/architecture-principles.md` §6. Don't pick one quietly.
- **Mark G3 FAIL or conditional** when a decisive fact (region availability, licensing, lifecycle) is `[UNVERIFIED]` and the decision isn't cheap to reverse. Add a validation step with an owner.
- **Don't** recommend based on popularity, marketing, or a leaderboard alone. Don't report evaluation results that weren't run.

## References

- `standards/architecture-principles.md` §2, §3, §5, §6, AP-11, AP-12
- `standards/observability-and-evaluation.md` (evaluation sets)
- `knowledge/technology-catalog.md`, `knowledge/framework-comparison.md`, `knowledge/model-selection-guide.md`, `knowledge/deployment-patterns.md`
- `docs/operating-model.md` §8 (re-opening decisions), `docs/conventions.md` §6
- Skills: `architecture-design`, `adr-management`, `architecture-debate`

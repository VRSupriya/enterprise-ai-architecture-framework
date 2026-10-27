# Severity Rubric

This is the single severity scale for every finding: specialist findings (`F-<AREA>-`), board findings (`F-BRD-`), red-team findings, and debate outcomes. It's referenced by `docs/conventions.md` §5 and by the `architecture-review` skill ([SKILL.md](../SKILL.md)). Rate a finding on the **consequence** it would have in this use case's context, if left unfixed, given the documented requirements and constraints.

## 1. Levels

| Severity | Definition | Default remediation class | Gate effect |
|---|---|---|---|
| **Critical** | Would cause, or directly enables, severe harm: a breach of restricted data, an unauthorized consequential action, a regulatory or legal breach, a safety impact, or a total failure of a Must requirement. Or it violates a CON/PRH without a decision. | Mandatory, closed before the next gate | **Blocks G5 and G10.** Blocks G4 if authorization is involved, and G3 if a constraint is involved |
| **High** | Material failure of a Must FR or NFR, a significant security or data-protection weakness with a plausible path to exploitation, or a production-readiness gap with no compensating control | Mandatory, unless formally waived by the named risk owner | Gate is PASS-WITH-CONDITIONS at best. It needs an owner, a due point, and a tracking ID |
| **Medium** | Degrades quality, operability, cost, or maintainability, or weakens a control where compensating controls exist. A Should requirement is at risk. | Recommended (before production) | Doesn't block. Tracked |
| **Low** | A minor inconsistency, documentation gap, or improvement opportunity with limited consequence | Optional or Future | Doesn't block |

Observations and strengths aren't findings. Record them in the review report's "Strengths worth retaining" section.

## 2. Criteria by dimension

Use the row that best fits the consequence. When several rows apply, the highest justified level wins.

| Dimension | Critical | High | Medium | Low |
|---|---|---|---|---|
| **Security and identity** | Authorization for a consequential action rests on model reasoning. Credentials are reachable from the model context. An exploitable injection path leads to write actions. | Over-broad tool permissions. No identity separation between user and agent. Injection controls are missing on a read path that exposes sensitive data. | Defense in depth is incomplete but compensated, for example output filtering without input filtering on a low-exposure path. | Hardening or documentation gaps |
| **Data** | Restricted or regulated data leaks across users, tenants, or a residency boundary. Retrieval isn't permission-trimmed over sensitive content. | Retention or deletion requirements unmet. PII is logged unmasked. Memory isn't scoped. | Freshness or lineage gaps that degrade answer quality. Re-index plan missing. | Metadata or catalog gaps |
| **Reliability** | No containment for a failure that causes unrecoverable or duplicated consequential side effects (non-idempotent retries on payments, for example) | Single point of failure or missing degraded mode that breaches a Must availability NFR. Unbounded agent loops. | Retries without backoff. Partial observability of failures. DR untested at T2. | Runbook polish |
| **Compliance and governance** | A mandated regulatory obligation is unmet. A PRH is violated. No accountable owner for a high-risk AI use. | Audit trail insufficient for the obligation. Policy controls are documented but not implemented. | Evidence is incomplete for an internal policy | Template or record-keeping gaps |
| **Functional** | A Must FR can't be delivered by the design as proposed | A Must FR is only partly met, or an exception path is missing for a common case | A Should FR is at risk. Rare edge cases are unhandled. | Usability or wording issues |
| **Cost** | Unbounded spend exposure (no limits on tokens, steps, or tenants) on a public or high-volume path | Projected cost exceeds the stated ceiling at expected volume | Optimization opportunities above the noise level (caching, model tier) | Minor efficiency improvements |

## 3. AI-specific examples

| Severity | Examples |
|---|---|
| **Critical** | The agent can issue refunds or post journal entries with no deterministic amount limit and no approval step. Retrieval returns documents the user isn't entitled to. A tool runs shell commands built from model output with no sandbox. Tool output containing instructions can trigger outbound email. Regulated data is sent to a model endpoint outside the mandated residency region. |
| **High** | No offline evaluation set or release threshold for a customer-facing assistant. Prompts are edited in production with no version or rollback. A multi-agent design with no measured benefit over one agent, which doubles the attack surface. A model deprecation date falls inside the planned service life with no migration path. No degraded mode for a provider outage against a 99.9% NFR. Memory accepts unvalidated content from external documents. |
| **Medium** | LLM-as-judge used without calibration against human labels. No per-tenant cost alerting. A chunking strategy chosen by default, not evaluated. Traces lack prompt and model version tags. Model fallback route with no equivalent quality check. |
| **Low** | Inconsistent component names between a diagram and the catalogue. A missing access date on a non-decisive claim. An ADR without revisit triggers on a reversible choice. |

## 4. Likelihood and confidence

Rate both qualitatively as **H / M / L**. Don't use percentages or risk scores unless there is measured data behind them. Invented precision ("37% likely") is a defect in the finding.

| Rating | Likelihood (the consequence occurs if unfixed) | Confidence (in the finding itself) |
|---|---|---|
| **H** | Expected in normal operation, or trivially triggered (for example, by any user input) | Verified fact: inspected code, config, observed output |
| **M** | Plausible under realistic conditions (peak load, adversarial user, dependency outage) | Strong inference from documented design |
| **L** | Requires unusual conditions or multiple failures | Assumption or unverified concern. State what would confirm it |

Rules:
- Likelihood can lower the **priority** within a severity level, but it doesn't lower severity below what the consequence warrants when the consequence is severe and irreversible. An L-likelihood path to an unauthorized payment is still Critical.
- A finding with **L confidence** must say how to verify it. If the potential consequence is Critical, mark it Critical with basis "Unverified concern", and make verification the Mandatory remediation. Don't silently downgrade it, and don't present it as fact.

## 5. Severity, risk tier, and blocking

- **Severity is set by consequence in context. The tier sets scrutiny and the response, not the label.** The same weakness can rate differently in different use cases because the consequence differs. For example, an unscoped memory store is Low for a T1 internal drafting tool on public data, and High for a T3 customer assistant with PII.
- The tier sets which dimensions are reviewed and at what depth (see the skill's bench table and checklist ★ items). It also sets how High findings must be dispositioned: at T3/T4, a High needs closure or a formal waiver by the named risk owner before G10. At T1/T2, a High may proceed under PASS-WITH-CONDITIONS with an owner and due point.
- Blocking rules (from `standards/architecture-quality-gates.md` §3, restated only for orientation):
  - An open Critical blocks G5 and G10 at every tier.
  - Authorization delegated to model reasoning for a consequential action blocks G4.
  - An unresolved CON/PRH conflict blocks G3.
- A Critical can be closed only by verified remediation or an explicit change to the requirement or constraint by its decision owner. A waiver alone doesn't close it.

## 6. Rating discipline

- **Don't inflate severity.** Rate it on the documented consequence, not on the reviewer's preference, novelty, or the wish to force a redesign. "Not how I would build it" isn't a finding unless it fails a requirement, standard, or principle.
- **Don't deflate severity** to pass a gate or because the issue is costly to fix. Cost of remediation belongs in the remediation plan, not in the severity.
- One root cause gets one finding. Don't split a single issue into several findings to increase its weight, and don't merge unrelated issues to hide one.
- A finding that depends on an assumption names the `ASM-` ID. If the assumption is validated as false, re-rate the finding.
- When specialists disagree on severity, the chair decides on evidence (`docs/operating-model.md` §6), records the reasoning, and keeps the dissent visible. Head count doesn't decide.

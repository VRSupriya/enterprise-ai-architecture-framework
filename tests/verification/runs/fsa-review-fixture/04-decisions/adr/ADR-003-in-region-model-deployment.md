# ADR-003: Regional, in-region Azure OpenAI deployments with policy enforcement (resolves DEC-001)

- **Decision owner:** Residency policy owner and platform lead (fictional) · **Date:** 2026-10-27 · **Approval:** Proposed

## Status
Accepted (board). Proposed, pending Q-IN-02.

## Context
CON-002 requires customer and asset data to stay in-region. The implemented deployment is in `eastus`, which is outside the in-region target (F-BRD-01).

Microsoft documents that Global deployments may process data in any region, and that Data Zone deployments process data anywhere within the zone. Standard and Regional deployments keep processing in the chosen geography. `[VENDOR]` (source: https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/deployment-types, accessed 2026-10-27; cited by the DK and IN specialists. The board chair did not re-fetch it.)

**Evidence gap (round-3 red team):** the quoted claim says processing stays in the chosen *geography*, but CON-002 is region-level. Before G3 is relied on, re-verify against the current Microsoft source and the policy's exact wording. Until then the claim stays `[UNVERIFIED]` for region-level processing.

## Decision
- Deploy generation and embedding models as Standard (Regional) in the mandated region.
- Pin model versions.
- Use managed identity and disable key authentication.
- Apply Azure Policy to deny Global SKUs and locations outside the region.
- Use a Data Zone only if the residency policy owner rules in writing that it counts as in-region.

## Alternatives Considered

| Option | Verdict | Reason |
|---|---|---|
| Global or Data Zone deployment | Rejected unless the owner rules otherwise | Processing may leave the region |
| Keep `eastus` | Rejected | Violates CON-002 |

## Consequences
- Possibly lower quota, or later access to new models (an NFR conflict recorded in the requirements).
- If the required model isn't offered Regional in the mandated region, this is a **constraint conflict** (RSK-01). The board will present the options to the owner: a smaller in-region model, an approved exception, or data minimization. It will not route around the constraint.
- Lock-in: Azure OpenAI is accepted under CON-001. The APIM seam keeps the exit cost low.

## Revisit Triggers
- The residency policy changes, or Q-IN-02 is ruled.
- Model availability changes in the mandated region.
- The model is deprecated.
- Evidence is older than 6 months at the next decision point.

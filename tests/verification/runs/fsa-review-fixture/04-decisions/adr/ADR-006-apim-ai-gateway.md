# ADR-006: Use APIM AI-gateway capability; retire the custom AI gateway

- **Decision owner:** Platform lead (fictional) · **Date:** 2026-10-27 · **Approval:** Proposed

## Status
Accepted (board).

## Context
PREF-003 proposed a new in-house gateway. It stores a static key in a ConfigMap and is reached over plain HTTP (F-BRD-08). The gateway needs are token limits, logging, a single model seam, and identity.

APIM provides an `llm-token-limit` policy and managed-identity authentication to Azure OpenAI `[VENDOR]` (source: https://learn.microsoft.com/en-in/azure/api-management/llm-token-limit-policy, accessed 2026-10-27, by the IN specialist).

## Decision
- Use the enterprise APIM instance, or provision a private-networking-capable SKU if none exists (Q-IN-01).
- Configure token limits, metadata logging, managed identity to Azure OpenAI, TLS only, and zone redundancy.
- Retire the custom gateway.

## Alternatives Considered

| Option | Verdict | Reason |
|---|---|---|
| Custom in-house gateway (PREF-003) | Rejected | Duplicates an existing capability, adds an unowned single point of failure, and exposes a credential |
| No gateway, direct SDK with managed identity | Alternative | Acceptable for one use case, but loses central token limits and metering |

## Consequences
- Central metering and limits, which support NFR-008.
- Lock-in to APIM policies. The exit cost is a policy rewrite, measured in weeks.
- APIM SKU private networking in the region is `[UNVERIFIED]`.

## Revisit Triggers
- A requirement emerges that APIM can't meet, such as semantic caching or multi-provider routing.
- The enterprise gateway standard changes.

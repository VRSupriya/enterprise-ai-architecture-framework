# ADR-005: Azure Container Apps runtime (replaces AKS)

- **Decision owner:** Integration lead (fictional) · **Date:** 2026-10-27 · **Approval:** Proposed

## Status
Accepted (board) after rebuttal round DBT-03.

## Context
After ADR-001, the target is two stateless services (C-02 and C-05). Load is about 0.07 req/s at 5× peak `[ASSUMPTION ASM-IN-01]`. There is no GPU or self-hosting. Platform-engineering capacity is unknown (ASM-006, corrected per DBT-07). PREF-001 named AKS.

## Decision
Run on Azure Container Apps with:
- a workload-profiles environment in the mandated region, zone-redundant
- at least 1 replica per zone and no scale-to-zero
- VNet integration, egress through Azure Firewall (UDR), private endpoints
- a separate managed identity per service
- the C-05 write path as an async/queued command with the idempotency key, never relying on a held-open HTTP request

## Alternatives Considered

| Option | Verdict | Reason |
|---|---|---|
| AKS (PREF-001) | Alternative, behind triggers | Disproportionate operations burden at this load (AP-03). Doesn't breach CON-001. |
| Shared enterprise AKS platform | Alternative | Prefer it if one exists with an owning team (AP-06). |

## Consequences
- Low operations burden.
- Exit cost to AKS: days to weeks. Images are portable; IaC and networking need rework.
- Conditions to verify before commitment, all currently `[UNVERIFIED]`:
  - (a) workload profiles and zone redundancy are available in the mandated region
  - (b) ingress timeout and streaming limits fit the worst-case turn
  - (c) minimum replicas meet cold-start needs
  - (d) whether a governed shared AKS platform exists

## Revisit Triggers
- A self-hosted or open-weight model needs GPUs in the region (for example, RSK-01 materializes).
- The landing-zone standard mandates an existing AKS platform (Q-IN-01).
- A documented requirement appears for mesh, admission, or node-level controls.
- Condition (a) or (b) fails. In that case, reopen the decision; do not move regions.

# ADR-002: ERP writes only through a deterministic command service and the existing n8n flows

- **Decision owner:** ERP/integration team lead and CISO (fictional) · **Date:** 2026-10-27 · **Approval:** Proposed

## Status
Accepted (board). Proposed to the decision owners.

## Context
FR-003 and FR-004 write to the ERP. CON-003 requires attributable audit. INV-001: n8n create/update flows already run in production. The current state: direct ERP REST calls as `svc-erp-admin`, a delete tool, prompt-only limits, unlimited retries.

Evidence: F-BRD-02, -03, -05, -06; F-SA-01/02; F-AG-02 to 05; F-SE-01 to 04, 10; F-RE-01; F-IN-02; DBT-06.

## Decision
C-05 Work-Order Command Service is the only caller of ERP writes, through the existing n8n flows (C-06). It does the following:
- validates a typed `WorkOrderProposal`
- enforces in code: at most 3 work orders per conversation, a per-user daily cap, a priority allow-list (EMERGENCY routed to a dispatcher), and the allowed status transitions
- requires a single-use, short-lived technician confirmation token bound to the parameter hash
- attaches an idempotency key (conversation id + proposal hash) and the actor identity
- retries at most twice, only with the key, and reconciles by key after a timeout
- writes an append-only audit record to C-09 for every proposal, decision, confirmation and outcome

Identity: OBO user token downscoped to n8n/ERP (preferred). The fallback is a least-privilege create/update-status identity, plus a PEP entitlement check and `requested_by` stamping.

The delete tool is removed.

## Alternatives Considered

| Option | Verdict | Reason |
|---|---|---|
| Direct ERP REST from the agent (current) | Rejected | Duplicates INV-001, admin identity, no audit |
| Command service enforcing idempotency by itself (lookup before create) | Alternative (fallback) | Only if n8n can't carry the key (ASM-005). Weaker. |

## Consequences
- A single write path, governed by the ERP team.
- Depends on ASM-005, an n8n flow change that may be needed.
- Adds one service, which is justified because it is the security boundary (AP-14).

## Revisit Triggers
- ASM-005 is invalidated.
- The ERP gains native idempotency or user-token support.
- The sponsor changes Q-001 (writes without confirmation), which would raise the tier.

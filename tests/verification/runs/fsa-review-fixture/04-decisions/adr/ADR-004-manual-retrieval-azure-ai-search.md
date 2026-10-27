# ADR-004: Azure AI Search (hybrid) for manual retrieval; reject Pinecone

- **Decision owner:** Data lead (fictional) · **Date:** 2026-10-27 · **Approval:** Proposed

## Status
Accepted (board).

## Context
FR-001 needs grounded answers with citations over manuals. The corpus is under 50k pages (ASM-002). Part numbers and fault codes need lexical matching. PREF-002 proposes Pinecone.

Pinecone's managed Azure serverless region list shows `eastus2` only `[VERIFIED]` (source: https://docs.pinecone.io/guides/index-data/index-configuration, accessed 2026-10-27, by the DK specialist). BYOC on Azure is in public preview `[VENDOR]`.

## Decision
- Store the source manuals in Blob/ADLS.
- Parse them with Document Intelligence and split them into section-aware chunks with provenance metadata.
- Index into Azure AI Search hybrid (BM25 + vector + semantic reranker) in the mandated region, vectorized by the in-region embedding deployment.
- Pre-filter by `is_current` and the user's groups.

## Alternatives Considered

| Option | Verdict | Reason |
|---|---|---|
| PostgreSQL + pgvector + full-text search | Alternative | Viable at this scale if the team wants a single store. Fusion and reranking are hand-built. |
| Pinecone (PREF-002) | Rejected | Primary reason: a third-party store outside the governed estate with no traced need (AP-06). The CON-002 region misfit is probable but unproven until the region is named (Q-IN-02; round-3 red team). |

## Consequences
- Fewer vendors.
- Native Entra document-level ACL enforcement is preview `[VENDOR]`. Use security filters instead.
- Availability of AI Search and the semantic ranker in the mandated region is `[UNVERIFIED]` (RSK-04-like). Check it before committing.

## Revisit Triggers
- The corpus grows by more than 10×.
- EVAL-001 recall falls below threshold after tuning.
- The service or feature is unavailable in the region.

# ADR-001: Solution shape — workflow with LLM steps and RAG, no agent loop

- **Decision owner:** Board chair, recommending to the sponsor (fictional) · **Date:** 2026-10-27 · **Approval:** Proposed, pending sponsor sign-off

## Status
Accepted (board). Proposed to the sponsor.

## Context
FR-001 to FR-005 have enumerable paths: ask, create, update, escalate. The draft proposes six agents (rung 7) with Supervisor and Reflection agents (PREF-001). The team has Python skills but no agent-framework experience (ASM-003). NFR-001 latency is now quantified. Evidence: F-AG-01 (ladder walk), F-RT-10, F-RE-04 latency estimates `[JUDGMENT]`, DBT-01, DBT-02.

## Decision
Use rung 2 deterministic orchestration in the C-02 Conversation Service, with:
- rung 4 LLM steps for intent classification and work-order field extraction into a typed draft
- rung 5 RAG for FR-001
- at most 3 LLM calls per turn
- no LLM supervisor, no Reflection agent, and no agent loop

Grounding checks (citation present, cited chunk retrieved) are deterministic.

## Alternatives Considered

| Option | Verdict | Reason |
|---|---|---|
| Rung 6: single bounded agent, read-only tools | **Alternative** (gated) | Adopt only if EVAL-001 shows that fixed retrieval measurably fails on multi-hop manual and history questions. It must never hold write tools. |
| Rung 7: six-agent LangGraph (PREF-001) | Rejected | Fails agentic-ai-design-principles §1.2. No separable context, permissions, or owners. Adds 3–5 serial LLM calls. |
| LangGraph used as a deterministic graph | Acceptable, not recommended | Adds learning cost the requirements don't need. |

## Consequences
- Lower latency and cost, and a smaller attack surface.
- Simpler to evaluate.
- Lock-in: low. This is plain Python, and model access goes through APIM.
- Residual risk: rare complex questions may get weaker answers (RSK-03). The rung 6 trigger covers this.

## Revisit Triggers
- EVAL-001 shows that fixed retrieval fails beyond the agreed threshold.
- A new requirement has paths that can't be enumerated.
- A second use case with distinct permissions or owners shares the service.

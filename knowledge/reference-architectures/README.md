# Reference Architectures

- **Last verified:** 2026-10-27
- **Confidence:** High for pattern structure (technology-agnostic `[JUDGMENT]`); example realizations are illustrative and not re-verified per product.

## These are patterns, not compulsory templates

Each pattern is a **reusable starting point** for reasoning: it names the components, trust boundaries, failure modes, and cost drivers that a design of that shape must address. It is **not** a template to copy, and it is not an approved stack.

- Select a pattern only after climbing the solution ladder (`standards/architecture-principles.md` §4) and confirming that lower rungs are insufficient.
- Every component in a pattern is a *capability*. Satisfy it with existing enterprise components where they fit (AP-06), or mark it "not required because …" (AP-13). A pattern's component list is a checklist of questions, not a bill of materials.
- Patterns combine. A typical enterprise solution is one primary pattern plus elements of others (for example, a deterministic workflow with one bounded-agent step and a RAG retrieval tool).
- Diagrams use generic component names. Technologies appear only on the "Example realizations" line, and they are examples, not recommendations.
- When a use case adopts a pattern, its `solution-design.md` must re-draw the diagram with the use case's own component IDs (`C-`) and trace each component to requirements. Never paste the pattern diagram as the design.

## Index

| Pattern | Rung | Use when | Default risk tier range |
|---|---|---|---|
| [Deterministic workflow with LLM steps](deterministic-workflow-with-llm-steps.md) | 2 + 4 | Known process; some steps need language understanding (extract, classify, summarize, draft) | T1–T3 |
| [Enterprise RAG](enterprise-rag.md) | 5 | Answers must be grounded in and cite governed enterprise content | T2–T3 |
| [Single bounded tool agent](single-bounded-tool-agent.md) | 6 | Task paths can't be enumerated; dynamic selection over a small, read-mostly toolset adds measurable value | T2–T3 |
| [Human-approved action agent](human-approved-action-agent.md) | 6 | Agent proposes consequential writes; humans approve; deterministic policy enforces limits | T3–T4 |
| [Agent harness with sandboxed execution](agent-harness-sandboxed-execution.md) | 6 (runtime internals) | Building or adopting an agent that operates on files, code, data, or systems with real tools (e.g. a coding agent); covers loop, permissions, sandbox, context, hooks, adopt-vs-build | T2–T4 |
| [Enterprise assistant / copilot platform](enterprise-assistant-copilot.md) | 0 (buy) → 5/6 (build) | General-purpose assistant for many employees: chat, RAG, connectors, files, memory, admin policy; buy vs build vs extend | T2–T3 |
| [Multi-agent collaboration](multi-agent-collaboration.md) | 7 | Genuinely separable sub-tasks with distinct context, permissions, or owners | T3–T4 |
| [Event-driven AI processing](event-driven-ai-processing.md) | 2 + 4 | AI reacts to business events asynchronously at volume | T1–T3 |
| [Batch document intelligence](batch-document-intelligence.md) | 2 + 3/4 | Large document backlogs or periodic batches: extract, classify, validate | T1–T3 |
| [Hybrid managed and self-hosted models](hybrid-managed-and-self-hosted-models.md) | cross-cutting | Some workloads must run on owned infrastructure; others can use managed models | T2–T4 |
| [Governed model and agent lifecycle](governed-model-and-agent-lifecycle.md) | cross-cutting | Any production AI at T2+: versioning, evaluation gates, approval, retirement | T2–T4 |
| [Central platform with domain applications](central-platform-domain-applications.md) | cross-cutting | Several domain teams build AI applications on shared capabilities | T2–T4 |

## Section structure (every pattern)

Appropriate use cases · Preconditions and constraints · Architecture diagram · Core components · Trust boundaries · NFR implications · Security considerations · Operational requirements · Failure modes · Cost drivers · When NOT to use · Solution-ladder rung.

Diagrams follow `docs/conventions.md` §7 and pass `tools/validate-diagrams.sh`. A diagram that parses is not proof that a design is correct.

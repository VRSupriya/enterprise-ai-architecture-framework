# Orchestration Framework Comparison

- **Last verified:** 2026-10-27
- **Confidence:** Medium. High for versions/licenses/status marked `[VERIFIED]`; Medium for capability rows (mostly `[VENDOR]` docs); Low for lighter-checked frameworks (CrewAI, LlamaIndex).
- **Layer:** B. This compares *approaches*. It does not select one. Selection happens per use case in an ADR.

## 1. Approaches compared

| Approach | What it is | Typical examples |
|---|---|---|
| **A. Deterministic workflow engine** | Process defined as code/BPMN/state machine; the engine owns state, retries, timers | Azure Logic Apps, AWS Step Functions, Camunda |
| **B. Workflow automation platform** | Low-code, connector-rich integration flows, now with AI/agent nodes | n8n, Power Automate, Zapier, Workato |
| **C. Durable execution** | Code-first workflows replayed from persisted history; activities retried independently | Temporal, Azure Durable Functions, Restate, DBOS |
| **D. Graph-based agent orchestration** | Explicit state graph with model-driven routing, cycles, checkpoints, and interrupts | LangGraph |
| **E. Microsoft Agent Framework (MAF)** | Microsoft's unified agent SDK: agents + graph Workflows + multi-agent patterns | MAF 1.x (.NET, Python) |
| **F. Other agent SDKs** | Agent loop libraries, usually provider-affine | OpenAI Agents SDK, Claude Agent SDK, Google ADK, CrewAI, LlamaIndex |

## 2. Comparison matrix

Cells are summaries. Material facts are labelled and sourced in §4 (Research log). "Varies" means it depends on product; check per product.

| Dimension | A. Workflow engine | B. Workflow automation (n8n) | C. Durable execution | D. LangGraph | E. Microsoft Agent Framework | F. Other agent SDKs |
|---|---|---|---|---|---|---|
| **Control-flow model** | Predefined graph/state machine; deterministic | Visual node graph; deterministic flow, with optional AI Agent node doing a tool loop inside one step | Imperative code; deterministic workflow code required for replay | Explicit state graph; edges can be conditional on model output; cycles allowed | Two modes: agents (model-driven loop) and Workflows (graph-based, "for deterministic processes") `[VENDOR]` | Mostly model-driven loop with handoffs; CrewAI adds Flows (event-driven) `[VENDOR]`; ADK adds workflow agents `[UNVERIFIED]` |
| **State / persistence** | Engine-managed, durable | Execution data in n8n DB (Postgres recommended for production `[UNVERIFIED]`) | Event-sourced history; strongest durability guarantees of the set `[JUDGMENT]` | Checkpointers per thread: in-memory, SQLite, Postgres; Store for cross-thread memory `[VENDOR]` | Checkpointing and hydration for long-running Workflows; pluggable memory `[VENDOR]` | Sessions (OpenAI SDK) `[UNVERIFIED]`; varies; often app-provided |
| **Human-in-the-loop** | Native human tasks/approvals (product-dependent) | Wait/approval nodes; form and chat triggers `[UNVERIFIED]` | Signals/timers make long human waits cheap | `interrupt` + resume from checkpoint `[VENDOR]` | Human-in-the-loop approvals, pause/resume, stable at 1.0 `[VENDOR]` | Varies; tool-approval hooks common |
| **Tool / MCP support** | Via connectors/HTTP; MCP varies | Hundreds of nodes; MCP Server Trigger (expose workflows as MCP tools) and MCP Client Tool `[VENDOR]` | Activities as tools; agent-SDK integrations (OpenAI Agents SDK GA for Python; Google ADK preview) `[VENDOR]` | LangChain tools; MCP via adapters `[UNVERIFIED]` current package | MCP tool discovery and invocation stable at 1.0; A2A 1.0 "coming soon" `[VENDOR]` | All named SDKs advertise MCP support `[UNVERIFIED]` per SDK on 2026-10-27 |
| **Observability** | Engine run history + platform monitoring | Execution log UI; log streaming in paid editions `[UNVERIFIED]` | Full event history per workflow; OTel interceptors | LangSmith (commercial), OTel export `[UNVERIFIED]` detail | OpenTelemetry-based observability listed as **preview** in 1.0 post `[VENDOR]` | Built-in tracing (OpenAI SDK, to OpenAI by default; custom processors possible) `[UNVERIFIED]` |
| **Deployment model** | Managed PaaS or self-hosted | Self-hosted (Docker Compose recommended) or n8n Cloud `[VENDOR]` | Self-hosted cluster or managed cloud service | Library in your service; or LangSmith Deployment (formerly LangGraph Platform) managed/hybrid/self-hosted `[VENDOR]` | Library in your service; Foundry hosted agents and Durable Functions hosting are **preview** integrations in 1.0 `[VENDOR]`; Foundry hosted agents service itself GA mid-2026 `[VENDOR]` | Library; vendor-hosted options vary |
| **Language support** | Product-dependent | JavaScript/TypeScript (custom nodes, code node also Python `[UNVERIFIED]`) | Temporal: Go, Java, Python, TypeScript, .NET, and others `[UNVERIFIED]` | Python, JavaScript/TypeScript | Python, .NET (C#); Go in a separate repo `[VENDOR]` | OpenAI: Python, TS `[UNVERIFIED]`; Claude Agent SDK: Python, TS `[VENDOR]`; ADK: Python, plus Java, Kotlin, Go, TS repos `[VERIFIED]` |
| **Licensing** | Commercial PaaS or OSS/commercial editions | **Sustainable Use License (fair-code, not OSI open source)** + Enterprise License for `.ee` files `[VERIFIED]` | Temporal server MIT `[UNVERIFIED]`; cloud services commercial | Library MIT `[VERIFIED]`; LangSmith commercial | MIT `[VERIFIED]` | OpenAI Agents SDK MIT `[VERIFIED]`; CrewAI MIT `[VENDOR]`; ADK Apache-2.0 `[UNVERIFIED]`; Claude Agent SDK under Anthropic terms `[UNVERIFIED]` |
| **Lifecycle / maturity** | Mature (de facto practice) | Mature product, fast-moving AI features | Mature pattern; agent integrations newer | 1.x line (PyPI 1.2.17) `[VERIFIED]` | **GA 1.0 on 2026-04-03**, "stable APIs and long-term support" `[VERIFIED]`; several integrations still preview | Mixed: OpenAI Agents SDK 0.24.0 (pre-1.0) `[VERIFIED]`; ADK 2.13.0 `[VERIFIED]`; Claude Agent SDK renamed from Claude Code SDK `[VENDOR]` |
| **Platform affinity** | Cloud-specific when managed | Neutral | Neutral (Temporal); Azure (Durable Functions) | Neutral; strongest with LangSmith | Azure / Microsoft Foundry, but model-agnostic connectors | Each affine to its model vendor; most allow other models |
| **Lock-in** | High for managed engines (definitions not portable) | Medium: workflows are n8n JSON; licence constrains redistribution | Medium: workflow code is SDK-shaped | Low–medium (library; graph code is LangGraph-shaped; platform optional) | Low–medium as library; higher if Foundry-only features are used | Medium: often tied to vendor tool/tracing features |

## 3. Decision guidance

### 3.1 Start from the orchestration you already have

1. **An existing workflow automation platform (e.g. n8n) already covers deterministic integration workflows.** Keep it as the system of record for those flows (`INV-`). Do not re-implement them in an agent framework (AP-04: one owner per responsibility).
2. **Introduce an agent framework only for the specific steps that need agentic behavior**, meaning steps that pass the rung-6 justification. Integrate the two; don't duplicate orchestration:
   - **n8n calls the agent:** an n8n step invokes an agent service over HTTP (or an internal API), passing a bounded task and receiving a structured result. n8n keeps retries, approvals, and system-of-record writes.
   - **The agent calls n8n:** expose curated n8n workflows as tools (MCP Server Trigger or HTTP). The agent gets governed enterprise actions without new connectors. Mind the queue-mode routing constraint for `/mcp*` endpoints `[VENDOR]`.
   - Never let both layers own retries/compensation for the same business transaction.
3. **Use n8n's own AI Agent node** for simple, low-risk tool loops (T1/T2) where its observability, evaluation, and testing are adequate. Move the step into a dedicated agent service when you need version-controlled tests, evaluation in CI, fine-grained identity per tool, or complex state `[JUDGMENT]`.
4. **Check the n8n license fits the deployment.** Internal business use is permitted. Offering n8n-powered functionality to external parties, embedding, or white-labelling needs legal review against the Sustainable Use License, and `.ee` features need an Enterprise license `[VERIFIED]` license text; interpretation `[JUDGMENT]`.

### 3.2 LangGraph vs Microsoft Agent Framework in an Azure context

Both are viable, MIT-licensed, graph-capable, checkpointing frameworks. Choose by team, language, and platform integration, not by feature lists.

| Prefer **Microsoft Agent Framework** when | Prefer **LangGraph** when |
|---|---|
| The team is .NET-first, or the estate is .NET services | The team is Python/TypeScript-first and already uses LangChain tooling |
| Migrating existing Semantic Kernel or AutoGen code (MAF is the stated successor with migration guides) `[VENDOR]` | Explicit graph-level control and inspectable state transitions are the primary need, and the team already knows LangGraph |
| Deep Microsoft Foundry integration (Foundry project endpoints, hosted agents, Foundry memory/evals) is planned and accepted as affinity | Portability across clouds or model providers is a stated requirement (`CON-`/`PREF-`) |
| Microsoft support channels and LTS commitment matter to procurement | LangSmith (commercial) is already the observability/eval platform |

Notes:
- **Hosting is not decisive.** Microsoft states Foundry hosted agents can run agents built with MAF, LangGraph, or other SDKs `[VENDOR]` (source: https://devblogs.microsoft.com/foundry/whats-new-in-microsoft-foundry-build-2026/, accessed 2026-10-27). Container Apps/AKS host either.
- **Several MAF integrations were preview at 1.0** (Foundry hosted-agent integration, Foundry memory/observability/evals, DevUI, AG-UI adapters). For T3/T4 production, don't depend on a preview API without an ADR condition `[VENDOR]`.
- **Semantic Kernel** is reported to receive bug and security fixes only, with support through at least April 2027; **AutoGen** is reported to be in maintenance mode `[UNVERIFIED]` (secondary sources only; check the official repos). Don't start new work on either without a reason.

### 3.3 Durable execution vs agent-framework checkpointing

- If the process **must** survive crashes mid-transaction with exactly-once business effects, weeks-long waits, or strict compensation, put the process in a durable execution engine or workflow engine and run the agent loop *inside* it (as Temporal's OpenAI Agents SDK integration does: loop in the workflow, model calls as activities `[VENDOR]`).
- Framework checkpointers (LangGraph, MAF) are sufficient for resumable conversations and approval pauses. They are **not** a transactional outbox. Side-effecting tool calls still need idempotency keys `[JUDGMENT]`.

### 3.4 The "no second framework for features" rule

- **Do not add a second agent framework merely for a feature** (a nicer multi-agent pattern, a demo integration, a UI adapter). Each framework adds an upgrade cadence, a security patch stream, a tracing model, and a skill requirement.
- A second framework is justified only when **all** of these hold: (1) the need traces to an FR/NFR; (2) it can't be met reasonably in the existing framework or with plain code; (3) the boundary between the frameworks is a service/protocol boundary (HTTP, MCP, A2A), not shared in-process state; (4) the ADR records ownership and exit cost (AP-12).
- **Prefer plain code** for rung-4 LLM steps. A typed SDK call with structured output does not need an agent framework.

### 3.5 Quick selector

| Situation | Default approach |
|---|---|
| Known steps, integrations, approvals, an n8n estate exists | B (reuse), with rung-4 LLM steps |
| Known steps, code-owned, long-running, must be exactly-once | A or C |
| One step needs dynamic tool use over a bounded toolset | B or A for the process + one agent service (D, E, or F) for that step |
| Agent loop that must survive failures for hours/days | C hosting the agent loop, or D/E with Postgres checkpointing plus idempotent tools |
| .NET estate, Azure/Foundry-centric | E |
| Python team, portability valued | D |
| Provider-specific features are the requirement (e.g. a vendor's computer-use or harness) | That vendor's SDK (F), behind a service boundary |

## 4. Research log

All accessed 2026-10-27 unless stated.

| Item | Claim | Source | Accessed | Label |
|---|---|---|---|---|
| MAF | Version 1.0 for .NET and Python, production-ready, stable APIs, long-term support; dated 2026-04-03 | https://devblogs.microsoft.com/agent-framework/microsoft-agent-framework-version-1-0 | 2026-10-27 | [VERIFIED] |
| MAF | Combines Semantic Kernel enterprise foundations and AutoGen orchestration; migration guides for both | same | 2026-10-27 | [VENDOR] |
| MAF | Stable at 1.0: Workflows (graph, checkpointing), multi-agent patterns (sequential, concurrent, handoff, group chat, Magentic-One), HITL, MCP, middleware, memory, declarative YAML | same | 2026-10-27 | [VENDOR] |
| MAF | Preview at 1.0: DevUI, Foundry hosted-agent integration, Foundry tools/memory/observability/evals, AG-UI/CopilotKit/ChatKit adapters, Skills, Copilot SDK/Claude Code SDK integration, Agent Harness; A2A 1.0 "coming soon" | same | 2026-10-27 | [VENDOR] |
| MAF | MIT license; Python and .NET; Go in separate repo | https://github.com/microsoft/agent-framework | 2026-10-27 | [VERIFIED] license; [VENDOR] languages |
| MAF | Release candidate announced 2026-02-19 | https://devblogs.microsoft.com/agent-framework/migrate-your-semantic-kernel-and-autogen-projects-to-microsoft-agent-framework-release-candidate/ | 2026-10-27 (search result) | [VENDOR] |
| MAF | Latest 1.x patch version after 1.0 | not checked | — | [UNVERIFIED] |
| Semantic Kernel / AutoGen | SK: fixes only, support through at least April 2027; AutoGen: maintenance mode | https://atlan.com/know/ai-agent/microsoft/semantic-kernel/ (secondary) | 2026-10-27 | [UNVERIFIED] |
| Microsoft Foundry | Product branded "Microsoft Foundry"; hosted agents GA (announced 2026-07-09 per Foundry blog; another source says June 2026) | https://devblogs.microsoft.com/foundry/whats-new-in-microsoft-foundry-july-august-2026/ ; https://mc.merill.net/message/AZ563596 | 2026-10-27 | [VENDOR]; GA date [UNVERIFIED] (conflict) |
| Microsoft Foundry | Hosted-agent runtime accepts MAF, LangGraph, other SDKs | https://devblogs.microsoft.com/foundry/whats-new-in-microsoft-foundry-build-2026/ | 2026-10-27 (search result) | [VENDOR] |
| LangGraph | PyPI latest 1.2.17; license MIT | https://pypi.org/pypi/langgraph/json | 2026-10-27 | [VERIFIED] |
| LangGraph | Checkpointers: InMemorySaver, SqliteSaver, PostgresSaver; threads by `thread_id`; Store for cross-thread memory | https://docs.langchain.com/oss/python/langgraph/persistence | 2026-10-27 | [VENDOR] |
| LangGraph | "LangGraph Platform is now LangSmith Deployment" (Oct 2025); existing deployments/APIs unchanged | https://changelog.langchain.com/ (search result; page not fetched directly) | 2026-10-27 | [VENDOR] |
| n8n | Sustainable Use License v1.0 (internal business / non-commercial use; free non-commercial redistribution); `.ee` files under n8n Enterprise License | https://github.com/n8n-io/n8n/blob/master/LICENSE.md | 2026-10-27 | [VERIFIED] |
| n8n | Not OSI open source | inference from license terms | 2026-10-27 | [JUDGMENT] |
| n8n | Community edition without key; Business/Enterprise via key; Docker Compose recommended; npm deprecated from n8n 3.0 | https://docs.n8n.io/hosting/ | 2026-10-27 | [VENDOR] |
| n8n | MCP Server Trigger: SSE + streamable HTTP, no stdio; None/Bearer/Header auth; queue-mode replica pinning | https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-langchain.mcptrigger/ | 2026-10-27 | [VENDOR] |
| n8n | Instance-level MCP server (preview, ~April 2026) | secondary blogs (e.g. https://contextbolt.com/blog/n8n-mcp/) | 2026-10-27 | [UNVERIFIED] |
| Temporal | OpenAI Agents SDK integration GA 2026-03-23 (Python); agent loop in workflow, model calls as activities; Google ADK integration public preview | https://temporal.io/blog/announcing-openai-agents-sdk-integration ; https://docs.temporal.io/develop/python/integrations/openai-agents ; https://temporal.io/blog/durable-digest-april-2026 | 2026-10-27 | [VENDOR] |
| OpenAI Agents SDK | PyPI `openai-agents` 0.24.0, MIT | https://pypi.org/pypi/openai-agents/json | 2026-10-27 | [VERIFIED] |
| Claude Agent SDK | Renamed from Claude Code SDK; packages `@anthropic-ai/claude-agent-sdk`, `claude-agent-sdk`; Python and TypeScript | https://code.claude.com/docs/en/agent-sdk/migration-guide | 2026-10-27 (search result) | [VENDOR] |
| Google ADK | PyPI `google-adk` 2.13.0; Java, Kotlin, Go, TypeScript repos linked | https://pypi.org/pypi/google-adk/json | 2026-10-27 | [VERIFIED]; license [UNVERIFIED] |
| CrewAI | Core MIT; Flows for event-driven control; latest ~1.15.x (Sept 2026) | https://github.com/crewAIInc/crewAI (search result) | 2026-10-27 | [VENDOR] license; version [UNVERIFIED] |
| LlamaIndex | Workflows / agent status | not checked | — | [UNVERIFIED] |
| MCP | Current revision 2026-07-28 (stateless; DCR deprecated for Client ID Metadata Documents) | https://modelcontextprotocol.io/specification/versioning ; https://modelcontextprotocol.io/specification/2026-07-28/changelog | 2026-10-27 | [VERIFIED] |
| MCP | Founding project of Linux Foundation's Agentic AI Foundation (announced 2025-12-09) | https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation | 2026-10-27 | [VERIFIED] |

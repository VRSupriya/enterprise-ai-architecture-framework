# Technology Catalog

- **Last verified:** 2026-10-27
- **Confidence:** Medium overall. High for entries marked `[VERIFIED]`. Low for example-option positioning not individually re-checked.
- **Layer:** B (decision aid, not a mandate). See `knowledge/README.md`.

## How to read this catalog

- **Not every category needs a separate product in every architecture.** Most enterprise AI solutions need a small subset of these categories, and many needs are already met by a component that exists (a PostgreSQL database that can hold vectors, an API gateway that can meter tokens, an existing workflow platform). Each category below has a "Not needed when" line. Read it first.
- A category is a **capability**, not a product slot. Satisfy it with the simplest existing component that meets the requirement (`standards/architecture-principles.md` AP-03, AP-06), and record it as "not required because …" when it does not apply (AP-13).
- **Example options** are named for orientation, grouped as Managed / Open-source / Self-hosted. Unless a source is shown, the one-line positioning is `[JUDGMENT]` and the product's current version, feature set, and lifecycle status were **not** re-verified on 2026-10-27. Re-verify before citing in an ADR.
- Verified facts cite `(source: URL, accessed 2026-10-27)`. Deeper verification for orchestration frameworks is in `framework-comparison.md` §Research log.

---

## 1. Application and orchestration

### 1.1 Deterministic workflow engines

- **Capability:** Execute a predefined sequence/graph of steps with explicit branching, retries, timeouts, and compensation. Process logic is code or a model (BPMN), not model reasoning.
- **Needed when:** The process is known, auditable, multi-step, and long-running enough that state must survive restarts; approvals and SLAs matter.
- **Not needed when:** A single request/response service suffices, or an existing workflow/BPM platform already runs the process. Add LLM steps to it instead (`reference-architectures/deterministic-workflow-with-llm-steps.md`).
- **Selection criteria:** Durability of state; versioning of in-flight instances; human-task support; observability of each instance; developer model (code vs designer); hosting fit; ownership by an existing team.
- **Example options:** Managed: Azure Logic Apps, AWS Step Functions, Google Cloud Workflows. Open-source/self-hosted: Camunda (BPMN; check current licensing edition), Apache Airflow (batch/data DAGs, not transactional business processes).
- **Evidence:** Positioning `[JUDGMENT]`.

### 1.2 Workflow automation platforms (low-code integration)

- **Capability:** Visual, connector-rich integration workflows (trigger → transform → call SaaS/API), increasingly with AI nodes.
- **Needed when:** Integration-heavy processes across many SaaS/internal APIs, owned by an integration or automation team, where speed of change matters more than custom code.
- **Not needed when:** The enterprise already runs one (treat it as `INV-`, reuse it), or the logic is complex enough to need tested code and a durable engine.
- **Selection criteria:** Connector coverage; license terms for your usage (internal vs embedded/resold); self-hosting and HA (queue mode, workers); secrets handling; RBAC/SSO edition; Git-based versioning; AI/agent nodes and MCP support; audit logging.
- **Example options:** Managed: Microsoft Power Automate, Zapier, Workato. Fair-code, self-hostable: n8n.
- **Evidence (n8n):**
  - License is the **Sustainable Use License v1.0** for most code, limiting use to "internal business purposes" or non-commercial/personal use, and limiting redistribution to free, non-commercial distribution; files with `.ee` in the name or directory require a separate **n8n Enterprise License**. `[VERIFIED]` (source: https://github.com/n8n-io/n8n/blob/master/LICENSE.md, accessed 2026-10-27). This is **source-available "fair-code", not an OSI-approved open-source license** `[JUDGMENT]`, based on the use-restriction terms, which OSI licenses do not permit. Embedding n8n in a product sold to third parties, or offering it as a service, needs legal review.
  - Self-hosted without a license key runs as the free Community edition; Business/Enterprise keys unlock those editions; Docker Compose is the recommended production install, and the npm install is stated as deprecated from n8n 3.0. `[VENDOR]` (source: https://docs.n8n.io/hosting/, accessed 2026-10-27).
  - The **MCP Server Trigger** node exposes n8n workflows as MCP tools over SSE and streamable HTTP (no stdio), with None/Bearer/Header auth; in queue mode with multiple webhook replicas, `/mcp*` traffic must be pinned to one replica. `[VENDOR]` (source: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-langchain.mcptrigger/, accessed 2026-10-27).
  - An AI Agent node (LangChain-based) and an MCP Client Tool exist; an instance-level MCP server reported around April 2026 as preview. `[UNVERIFIED]`: secondary sources only; check docs.n8n.io before relying on it.

### 1.3 Agent frameworks

- **Capability:** Libraries that run an LLM tool-calling loop: tool definitions, model abstraction, memory hooks, handoffs, tracing.
- **Needed when:** Solution-ladder rung 6+ is justified (`standards/architecture-principles.md` §4): the task path cannot be enumerated and dynamic tool selection adds measurable value.
- **Not needed when:** A rung-4 LLM step (one call, structured output) does the job. A framework adds a dependency, an upgrade cadence, and abstractions to debug. A direct model SDK call is often enough.
- **Selection criteria:** Control-flow model; state/checkpointing; human-in-the-loop primitives; MCP support; OpenTelemetry output; languages your teams use; license; release maturity (1.0+ and stated support policy); platform affinity; exit cost.
- **Example options:** Microsoft Agent Framework (Python/.NET), LangGraph (Python/JS), OpenAI Agents SDK, Claude Agent SDK, Google ADK, CrewAI, LlamaIndex. Status and comparison in `framework-comparison.md`.
- **Evidence:** See `framework-comparison.md` research log.

### 1.4 Graph-based orchestration

- **Capability:** Model an agentic or hybrid process as an explicit state graph (nodes, edges, conditional routing, cycles) with checkpointed state, so agentic steps are bounded by deterministic structure.
- **Needed when:** You need loops and branching driven by model output, but want explicit, inspectable control flow, resumability, and interrupt points for approval.
- **Not needed when:** The flow is linear or fully deterministic (use 1.1/1.2), or a single bounded agent loop is sufficient.
- **Selection criteria:** Checkpointer backends that match your database estate; interrupt/resume semantics; graph versioning while threads are in flight; visualization/debugging; subgraph composition.
- **Example options:** LangGraph (MIT; checkpointers include in-memory, SQLite, Postgres) `[VERIFIED]` license via PyPI, `[VENDOR]` checkpointers (sources: https://pypi.org/pypi/langgraph/json; https://docs.langchain.com/oss/python/langgraph/persistence, accessed 2026-10-27). Microsoft Agent Framework Workflows (graph-based, checkpointing, stable at 1.0) `[VENDOR]` (source: https://devblogs.microsoft.com/agent-framework/microsoft-agent-framework-version-1-0, accessed 2026-10-27).

### 1.5 Multi-agent coordination

- **Capability:** Patterns for several agents: supervisor/worker, handoff, sequential/concurrent, group chat; plus cross-runtime protocols such as A2A.
- **Needed when:** Rung 7 justification holds: genuinely separable sub-tasks where context isolation, distinct permissions/owners, parallelism, or separation of duties is measurably better than one agent.
- **Not needed when:** "Roles" are just prompt sections. One agent with well-scoped tools is cheaper, easier to evaluate, and has fewer failure modes.
- **Selection criteria:** Explicit handoff contracts; per-agent identity and tool scopes; loop/budget bounds; tracing across agents; evaluation of the whole system, not each agent.
- **Example options:** Built into Microsoft Agent Framework (sequential, concurrent, handoff, group chat, Magentic-One patterns) `[VENDOR]` (source: as 1.4); LangGraph supervisor/subgraph patterns; CrewAI crews; Google ADK multi-agent; OpenAI Agents SDK handoffs. A2A protocol for cross-runtime agents: MAF 1.0 post states A2A 1.0 support "coming soon" `[VENDOR]`; A2A spec status itself `[UNVERIFIED]` on 2026-10-27.

### 1.6 API / service frameworks

- **Capability:** Expose AI capabilities as versioned, authenticated services (REST/gRPC/streaming), with validation and middleware.
- **Needed when:** Almost always, at some boundary. The AI capability should be a service with a contract, not a notebook or a UI-embedded call.
- **Not needed when:** The capability lives entirely inside a platform (workflow platform, SaaS copilot) that already exposes the interface.
- **Selection criteria:** Team language; streaming (SSE/WebSocket) support; OpenAPI generation; auth middleware compatible with enterprise IdP; performance under long-lived streaming connections.
- **Example options:** FastAPI (Python), ASP.NET Core (.NET), Spring Boot (Java), Express/NestJS (Node). `[JUDGMENT]`.

### 1.7 Durable execution engines

- **Capability:** Code-first workflows whose state is persisted per step and replayed after failure ("workflow as code"); activities retry independently.
- **Needed when:** Long-running, failure-prone, multi-step processes (including agent loops) where exactly-once business effects, retries, timers, and human waits must survive crashes and deploys.
- **Not needed when:** Steps are short and idempotent and a queue + retry suffices, or an existing workflow engine already provides durability.
- **Selection criteria:** Determinism constraints on workflow code (replay); versioning of running workflows; hosting (managed vs self-run cluster); SDK languages; observability; integration with agent SDKs.
- **Example options:** Temporal (open-source, self-hosted or Temporal Cloud); Azure Durable Functions / Durable Task; AWS Step Functions; Restate; DBOS `[JUDGMENT]`. Temporal's integration with the OpenAI Agents SDK (agent loop in the workflow, model calls as activities) is stated GA as of 2026-03-23 for Python `[VENDOR]` (source: https://temporal.io/blog/announcing-openai-agents-sdk-integration and https://docs.temporal.io/develop/python/integrations/openai-agents, accessed 2026-10-27). Microsoft lists Azure Durable Functions as a preview hosting option for MAF agents `[VENDOR]` (source: as 1.4).

---

## 2. Models and inference

### 2.1 Managed foundation models

- **Capability:** Frontier and mid-size proprietary models served by a cloud provider under enterprise terms (regional deployment, data handling commitments, private networking).
- **Needed when:** Highest task quality is required, or GPU operations are not a capability you want to own.
- **Not needed when:** A smaller model or a non-LLM technique (rules, classic ML, search) meets the quality bar (rungs 1–3).
- **Selection criteria:** See `model-selection-guide.md`: quality on your eval set, tool calling, residency, private connectivity, quotas, deprecation policy.
- **Example options:** Microsoft Foundry (hosts OpenAI, Anthropic Claude, xAI, open-weight and other models; the product is now branded "Microsoft Foundry") `[VENDOR]` (source: https://devblogs.microsoft.com/foundry/whats-new-in-microsoft-foundry-july-august-2026/, accessed 2026-10-27); Amazon Bedrock; Google Vertex AI. Specific model catalog contents change monthly. Don't cache them here.

### 2.2 Hosted model APIs (direct from the model vendor)

- **Capability:** First-party APIs from model developers (OpenAI, Anthropic, Google, Mistral, Cohere, etc.).
- **Needed when:** Earliest access to new features matters, or the cloud-hosted route lacks a needed capability.
- **Not needed when:** The same model is available via your mandated cloud with private networking and existing contracts. Prefer that for governance.
- **Selection criteria:** Data retention/training terms; region/residency; enterprise agreement; feature parity vs cloud-hosted variant; rate limits.
- **Example options:** Named above. `[JUDGMENT]`.

### 2.3 Open-weight models

- **Capability:** Models whose weights can be downloaded and run on your infrastructure (Llama, Mistral, Qwen, Gemma, DeepSeek, Phi families, among others; examples as of 2026-10-27).
- **Needed when:** Data cannot leave a boundary (air-gapped, sovereign), fine-tuning/control is required, or unit economics at sustained high volume favor owned capacity.
- **Not needed when:** A managed endpoint satisfies residency and privacy. Self-hosting is not automatically more secure or cheaper (`model-selection-guide.md` §7).
- **Selection criteria:** **License and acceptable-use terms** (many "open" model licenses are not OSI open source and carry use or scale restrictions; read each one); quality gap vs managed; size vs available GPU memory; quantization impact; language coverage.
- **Evidence:** License terms differ per model and version `[JUDGMENT]`. Verify each model card's license at selection time.

### 2.4 Self-hosted inference servers

- **Capability:** High-throughput serving engines (continuous batching, paged KV cache, quantization, speculative decoding) exposing OpenAI-compatible APIs.
- **Needed when:** You run open-weight models yourself (2.3).
- **Not needed when:** All inference is managed.
- **Selection criteria:** Hardware support; model architecture coverage; OpenAI-API compatibility (incl. tool calling and structured output); multi-GPU/multi-node parallelism; metrics endpoint; security of the API surface (auth is usually minimal; front it with a gateway).
- **Example options:** **vLLM**: Apache-2.0, PyPI latest 0.32.0; "OpenAI-compatible API server, plus Anthropic Messages API and gRPC support" `[VERIFIED]` version/license, `[VENDOR]` features (source: https://pypi.org/pypi/vllm/json, accessed 2026-10-27). Hardware: NVIDIA and AMD GPUs and x86/ARM/PowerPC CPUs in core; TPU, Intel Gaudi, Huawei Ascend, and others via hardware plugins (TPU via the separate `tpu-inference` plugin) `[VENDOR]`, from a PyPI mirror of the project description and the plugin repo (sources: https://simple-repository.app.cern.ch/project/vllm; https://github.com/vllm-project/tpu-inference, accessed 2026-10-27). Others: SGLang, NVIDIA Triton/TensorRT-LLM, Hugging Face TGI (check maintenance status), Ollama/llama.cpp (developer and edge, not high-concurrency production) `[JUDGMENT]`.

### 2.5 Model routing and fallback

- **Capability:** Route requests across models by task, cost, latency, or availability; fail over on errors/quota exhaustion.
- **Needed when:** Measured benefit: a cheap model handles a large share of traffic at acceptable quality, or availability SLOs exceed one provider/region's.
- **Not needed when:** One model meets quality and cost targets. Multi-model multiplies eval, prompt, and incident surface (`model-selection-guide.md` §6).
- **Selection criteria:** Routing is deterministic and observable; per-route eval coverage; fallback model has passed the same eval; consistent output schema across models.
- **Example options:** AI gateway routing (3.x below), Microsoft Foundry Model Router (vendor-managed router over a model pool) `[VENDOR]` (source: as 2.1), LiteLLM (open-source proxy), application-level routing.

### 2.6 Serving and accelerator infrastructure

- **Capability:** GPU/accelerator capacity, scheduling, autoscaling, and model artifact distribution.
- **Needed when:** Self-hosting (2.3/2.4) or fine-tuning.
- **Not needed when:** Managed inference only.
- **Selection criteria:** Capacity availability and reservation terms; GPU memory per device vs model size; interconnect for multi-GPU; Kubernetes GPU operator maturity in your estate; utilization targets (idle GPUs dominate cost).
- **Example options:** Kubernetes with NVIDIA GPU Operator / KServe / KubeRay; cloud GPU VMs; managed online endpoints (Azure ML, SageMaker, Vertex). `[JUDGMENT]`.

---

## 3. Data and knowledge

### 3.1 Relational and document databases

- **Capability:** System-of-record and application state: transactions, metadata, conversation and workflow state, audit tables.
- **Needed when:** Nearly always. Usually the enterprise standard database is reused.
- **Not needed when:** State is owned by a platform (workflow engine, agent service) and not queried elsewhere.
- **Selection criteria:** Existing operational competence; HA/DR; residency; JSON support; vector support (3.3).
- **Example options:** PostgreSQL (incl. Azure Database for PostgreSQL, Amazon RDS/Aurora), SQL Server/Azure SQL, Oracle, Azure Cosmos DB, MongoDB. `[JUDGMENT]`.

### 3.2 Search engines

- **Capability:** Lexical (BM25), faceted, and hybrid (lexical + vector) retrieval with security trimming.
- **Needed when:** RAG over large or heterogeneous corpora where hybrid ranking, filters, and per-document ACL trimming matter.
- **Not needed when:** The corpus is small and structured enough for database queries plus vectors in the same store.
- **Selection criteria:** Hybrid search and re-ranking; document-level security trimming; ingestion connectors; index-update latency; residency.
- **Example options:** Azure AI Search, Amazon OpenSearch Service/Kendra, Elasticsearch, OpenSearch, Vespa. `[JUDGMENT]`.

### 3.3 Vector search

- **Capability:** Approximate nearest-neighbour search over embeddings.
- **Needed when:** Semantic retrieval is required.
- **Not needed as a separate product when:** Your existing database or search engine already offers vector indexing at your scale. **This is the common case.** PostgreSQL with **pgvector** supports HNSW and IVFFlat indexes and `vector`, `halfvec`, `bit`, and `sparsevec` types; indexed dimensions up to 2,000 for `vector` and 4,000 for `halfvec` (current release 0.8.7) `[VENDOR]` (source: https://github.com/pgvector/pgvector, accessed 2026-10-27). Azure AI Search, Elasticsearch/OpenSearch, Cosmos DB, MongoDB, and SQL Server also provide vector capabilities `[UNVERIFIED]` per product on 2026-10-27.
- **Selection criteria:** Corpus size and growth; filter + vector query performance; ACL filtering; embedding dimension limits; operational ownership; joining vectors with relational data.
- **Example options (dedicated):** Pinecone (managed), Qdrant, Weaviate, Milvus (open-source/self-hosted). Introduce one only with a measured need (AP-01 typical violation: "We added a vector DB because RAG apps have one").

### 3.4 Graph databases

- **Capability:** Store and traverse entities and relationships; GraphRAG-style retrieval over knowledge graphs.
- **Needed when:** Questions depend on multi-hop relationships (lineage, ownership, network topology) that retrieval over text chunks answers poorly.
- **Not needed when:** Relationships are shallow (SQL joins suffice) or the graph exists only because a GraphRAG demo looked good.
- **Selection criteria:** Query language (Cypher/GQL/Gremlin/SPARQL); graph construction pipeline cost and quality; update cadence.
- **Example options:** Neo4j, Amazon Neptune, Azure Cosmos DB for Apache Gremlin, PostgreSQL + Apache AGE. `[JUDGMENT]`.

### 3.5 Object storage

- **Capability:** Durable storage of source documents, extracted text, model artifacts, eval datasets, and trace archives.
- **Needed when:** Almost always for documents and artifacts.
- **Selection criteria:** Immutability/retention (WORM) for audit; private endpoints; lifecycle tiers; residency.
- **Example options:** Azure Blob Storage/ADLS Gen2, Amazon S3, Google Cloud Storage, MinIO or Ceph (self-hosted; check MinIO's current licensing and distribution terms) `[UNVERIFIED]`.

### 3.6 Streaming and events

- **Capability:** Durable event logs and queues for decoupled, event-driven AI processing.
- **Needed when:** AI processing reacts to business events, or load must be buffered from bursty producers (`reference-architectures/event-driven-ai-processing.md`).
- **Not needed when:** Volume is low and synchronous calls with retries are acceptable.
- **Selection criteria:** Ordering and partitioning; retention/replay; dead-letter support; exactly-once vs at-least-once; existing enterprise event backbone.
- **Example options:** Apache Kafka (incl. Confluent, Azure Event Hubs Kafka endpoint), Azure Service Bus, Amazon SQS/SNS/EventBridge, Google Pub/Sub, RabbitMQ. `[JUDGMENT]`.

### 3.7 Knowledge ingestion and indexing

- **Capability:** Parse, chunk, enrich, embed, and index content; preserve source ACLs and lineage; detect changes and deletions.
- **Needed when:** Any RAG or document intelligence use case.
- **Not needed as a separate pipeline when:** The search service's built-in indexers handle your formats, ACLs, and update cadence.
- **Selection criteria:** Format coverage (PDF layout, tables, scans/OCR, Arabic and other RTL scripts where relevant); ACL propagation; incremental re-indexing and deletion propagation; embedding model versioning (re-embedding on model change); provenance metadata.
- **Example options:** Azure AI Document Intelligence, Amazon Textract, Google Document AI (managed); Unstructured, Docling, Apache Tika, LlamaIndex ingestion pipelines (open-source). `[JUDGMENT]`.

---

## 4. Memory and context

### 4.1 Conversation state

- **Capability:** Persist turns and session metadata per user/thread.
- **Needed when:** Multi-turn interaction.
- **Not needed as a separate store when:** The agent framework's checkpointer or the managed agent service persists threads in a store you already govern.
- **Selection criteria:** Retention and deletion (data subject requests); encryption; tenant isolation; who can read transcripts.
- **Example options:** The application database (3.1); framework checkpointers (LangGraph Postgres saver); managed thread storage in agent services. `[JUDGMENT]`.

### 4.2 Workflow state

- **Capability:** Durable state of a running process (step, inputs, pending approvals).
- **Needed when:** Long-running or resumable processes.
- **Not needed when:** Owned by the workflow/durable engine (1.1/1.7). **Don't duplicate it in a second store** (AP-04).
- **Example options:** Engine-native persistence; LangGraph/MAF checkpointing.

### 4.3 Short- and long-term memory

- **Capability:** Short-term memory is the current task context. Long-term memory is facts and preferences persisted across sessions and retrieved later.
- **Needed when:** Personalization or continuity across sessions has measurable value.
- **Not needed when:** Every task is self-contained. Long-term memory is a new data store containing user-derived data and a **memory-poisoning attack surface**; don't add it by default.
- **Selection criteria:** What is written (explicit vs model-extracted); review/edit/delete by the user; scoping (user, team, tenant); provenance; TTL.
- **Example options:** Framework stores (LangGraph Store, MAF pluggable memory) `[VENDOR]`; Foundry Agent Service memory (preview per MAF 1.0 post) `[VENDOR]`; Mem0, Zep, Letta (open-source/managed) `[UNVERIFIED]` status.

### 4.4 Context construction and compression

- **Capability:** Assemble the prompt: instructions, retrieved content, tool results, history. Summarize or prune it to fit the budget and keep relevant content in view.
- **Needed when:** Long conversations, large tool outputs, or many retrieved chunks.
- **Selection criteria:** Deterministic, testable assembly; provenance tags separating trusted instructions from untrusted content; measured quality impact of summarization; token budgets per component.
- **Example options:** Usually application code plus framework utilities; not a product category. `[JUDGMENT]`.

### 4.5 Caching

- **Capability:** Three distinct mechanisms:
  1. **Exact-match cache** on normalized request → response. Safe, and cheap to run.
  2. **Semantic cache** on embedding similarity → response. Risk of returning a wrong answer for a similar-but-different question, and of **cross-user data leakage** if not scoped.
  3. **Provider prompt caching**: the provider reuses computation for a repeated prompt prefix, which reduces cost and latency. It does not change answers.
- **Needed when:** Repeated prefixes (long system prompts, tool catalogs): use prompt caching, structuring prompts with stable content first. Repeated identical queries: use exact caching. Semantic caching only with a measured hit rate and an accuracy evaluation.
- **Not needed when:** Traffic is low or every request is unique.
- **Selection criteria:** Cache key scoping (tenant/user/ACL); invalidation on source or model change; hit-rate and correctness metrics.
- **Example options:** Redis/Azure Cache for Redis/Valkey (exact/semantic); AI gateway caching; provider-native prompt caching (availability, pricing, and TTL differ per provider and model: `[UNVERIFIED]`, check per provider). MCP 2026-07-28 asks servers to return `tools/list` in deterministic order partly to improve prompt-cache hit rates `[VERIFIED]` (source: https://modelcontextprotocol.io/specification/2026-07-28/changelog, accessed 2026-10-27).

### 4.6 Memory lifecycle

- **Capability:** Policies for retention, expiry, correction, deletion, and audit of all stored context (transcripts, memories, caches, embeddings).
- **Needed when:** Any persisted user-derived context. Always at T2+.
- **Selection criteria:** Deletion propagates to derived stores (embeddings, caches, eval sets); legal hold; residency.

---

## 5. Tool integration

### 5.1 APIs (direct tool calls)

- **Capability:** Model calls typed functions that the application maps to internal/external APIs.
- **Needed when:** A small, stable set of tools owned by the same team as the agent.
- **Not needed when:** An integration platform already exposes the operation. Call that instead.
- **Selection criteria:** Strict JSON schemas; idempotency keys for writes; authorization enforced in the API with the end user's or workload's identity, never by the model (AP-14); rate limits.

### 5.2 Model Context Protocol (MCP)

- **Capability:** Open protocol for exposing tools, resources, and prompts to AI clients across vendors.
- **Needed when:** Tools must be reused by several AI clients/frameworks, or third-party tools are consumed.
- **Not needed when:** One application uses a handful of in-process tools. Direct function calling is simpler and has a smaller attack surface.
- **Current status:**
  - **Current spec revision is `2026-07-28`** `[VERIFIED]` (source: https://modelcontextprotocol.io/specification/versioning, accessed 2026-10-27).
  - Major changes vs `2025-11-25`: protocol made **stateless** (no `initialize` handshake, no `Mcp-Session-Id`; version and capabilities carried per request in `_meta`); mandatory `server/discover`; `subscriptions/listen` replaces GET stream and resource subscribe; tasks moved to an official extension; Multi Round-Trip Requests replace server-initiated requests; SSE resumability removed. **Roots, Sampling, and Logging deprecated**; legacy HTTP+SSE transport deprecated; OAuth **Dynamic Client Registration deprecated in favor of Client ID Metadata Documents**; clients must validate `iss` (RFC 9207) and bind credentials to the issuing authorization server; OpenTelemetry trace context propagation via `_meta` documented; a feature lifecycle policy with a minimum 12-month deprecation window `[VERIFIED]` (source: https://modelcontextprotocol.io/specification/2026-07-28/changelog, accessed 2026-10-27).
  - **Governance:** MCP was contributed by Anthropic as a founding project of the **Agentic AI Foundation (AAIF)** under the Linux Foundation, announced 2025-12-09, alongside Block's goose and OpenAI's AGENTS.md `[VERIFIED]` (source: https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation, accessed 2026-10-27).
  - **Implication:** SDK and server support for `2026-07-28` will lag. Check that every client/server/gateway in the path supports the same revision, and plan for backward-compatibility with handshake-based servers `[JUDGMENT]`.
- **Selection criteria:** Authorization (OAuth 2.1 profile, audience-bound tokens, no token passthrough); server provenance and allow-listing; tool description review (tool poisoning); per-tool permission scopes; remote vs local (stdio) transport; gateway/registry for discovery and policy.

### 5.3 Enterprise connectors

- **Capability:** Pre-built, governed integrations to ERP, CRM, ITSM, document management, and identity systems.
- **Needed when:** The tools are enterprise systems with complex auth and data models.
- **Not needed as new build when:** An iPaaS/workflow platform or API management layer already exposes them. Reuse and expose them as tools or MCP servers.
- **Example options:** Azure Logic Apps connectors, MuleSoft, Boomi, n8n nodes, Microsoft Graph connectors. `[JUDGMENT]`.

### 5.4 Event integration

- **Capability:** Agents/LLM steps consume and emit business events rather than calling synchronously.
- **Needed when:** Asynchronous, high-volume, or decoupled processing; see 3.6.

### 5.5 Sandboxed execution

- **Capability:** Isolated execution of model-generated code or untrusted tools (containers, microVMs, WASM) with no ambient credentials and restricted egress.
- **Needed when:** The agent writes and runs code, processes untrusted files, or browses.
- **Not needed when:** Tools are fixed, typed APIs.
- **Selection criteria:** Isolation strength (microVM > container); network egress policy; filesystem lifetime; resource limits; audit of executed code.
- **Example options:** Managed code-interpreter tools from model platforms; Foundry hosted agents (stated microVM-level isolation, GA mid-2026; exact GA date differs between sources: June vs 2026-07-09) `[VENDOR]`/`[UNVERIFIED]` date (source: https://devblogs.microsoft.com/foundry/whats-new-in-microsoft-foundry-july-august-2026/, accessed 2026-10-27); E2B, Firecracker-, gVisor-, or Kata-based self-hosted sandboxes `[JUDGMENT]`.

---

## 6. AI platform and governance

### 6.1 AI gateways

- **Capability:** A policy enforcement point in front of model (and increasingly MCP/agent) endpoints: authN/Z, token quotas and metering, routing/failover, content safety hooks, logging, caching.
- **Needed when:** Several applications share model capacity, chargeback is required, or central policy must be enforced.
- **Not needed as a new product when:** The existing API gateway can be configured for token-aware policies (AP-06 typical violation). One application with one model may need none.
- **Selection criteria:** Token-based rate limiting; streaming support; MCP proxying; prompt/response logging with redaction; latency overhead; HA in the request path (a gateway is a new single point of failure).
- **Example options:** Azure API Management AI gateway capabilities; Foundry Agent Service "bring your own AI gateway" (GA reported April 2026) `[UNVERIFIED]`: seen via a third-party mirror of Azure updates only (source: https://mc.merill.net/message/AZ561002, accessed 2026-10-27); Kong AI Gateway; LiteLLM; Envoy AI Gateway; cloud-native equivalents. `[JUDGMENT]` positioning.

### 6.2 Guardrails and policy

- **Capability:** Input/output classification (prompt-injection detection, PII, toxicity, jailbreak), schema validation, and deterministic policy checks before actions.
- **Needed when:** Untrusted input reaches a model, or model output drives actions or reaches users. That is almost always the case at T2+.
- **Not needed as a separate product when:** The model platform's built-in content safety plus deterministic validation in your code meets the threat model.
- **Selection criteria:** Measured detection rates on your data (vendor claims are not evidence); latency; false-positive cost; placement (gateway vs app); **classifiers reduce risk but never replace authorization outside the model** (AP-14).
- **Example options:** Azure AI Content Safety (incl. prompt shields), Amazon Bedrock Guardrails, NVIDIA NeMo Guardrails, Guardrails AI, Llama Guard-family classifiers; OPA/Cedar for deterministic action policy. `[JUDGMENT]`.
- **Reference guidance:** OWASP Top 10 for LLM Applications: 2025 edition (LLM01 Prompt Injection … LLM10 Unbounded Consumption) is what the OWASP list page shows `[VERIFIED]` (source: https://genai.owasp.org/llm-top-10/, accessed 2026-10-27); OWASP announced a **2026 edition** on 2026-09-01/02 (press release reports Excessive Agency now #3) `[VENDOR]` (source: https://genai.owasp.org/2026/09/01/owasp-genai-security-project-unveils-2026-top-10-for-llm-applications-new-agent-control-standard-and-sponsors-as-community-tops-30000-members/, accessed 2026-10-27). The full 2026 entry list was **not** verified from the OWASP document `[UNVERIFIED]`. **OWASP Top 10 for Agentic Applications for 2026** (ASI01 Agent Goal Hijack, ASI02 Tool Misuse, ASI03 Identity & Privilege Abuse, …) released 2025-12-09/10 `[VENDOR]` (source: https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/, accessed 2026-10-27). The same September 2026 release mentions a donated **Agent Control Standard** for runtime enforcement `[VENDOR]`; its content was not reviewed.

### 6.3 Agent registries

- **Capability:** Inventory of agents with owner, purpose, version, tools/permissions, identity, risk tier, and lifecycle state; increasingly also discovery (A2A agent cards, MCP registries).
- **Needed when:** More than a handful of agents, or any agent at T3+ (needed for audit and incident response).
- **Not needed as a product when:** A CMDB/service catalog entry with the same fields suffices.
- **Example options:** Microsoft Entra Agent ID and Foundry agent inventory `[UNVERIFIED]` current status; MCP Registry (server discovery) `[UNVERIFIED]` status; Backstage catalog entries `[JUDGMENT]`.

### 6.4 Model registries

- **Capability:** Versioned catalog of models (self-trained, fine-tuned, open-weight) with lineage, eval results, approvals, and deployment stage.
- **Needed when:** You fine-tune or self-host models.
- **Not needed when:** Only managed models are used. Then record approved model IDs/versions in config and ADRs.
- **Example options:** MLflow Model Registry, Azure ML registries, SageMaker Model Registry, Vertex AI Model Registry. `[JUDGMENT]`.

### 6.5 Prompt and configuration management

- **Capability:** Version, review, and roll out prompts, tool definitions, model parameters, and routing rules as configuration with an audit trail (AP-08).
- **Needed when:** Always version prompts. A dedicated tool is needed only when non-developers edit prompts or many variants are A/B tested.
- **Not needed as a product when:** Prompts live in Git with code review and CI evals. That is often the best option.
- **Example options:** Git + feature flags; Langfuse/LangSmith/MLflow prompt registries; Azure App Configuration. `[JUDGMENT]`.

### 6.6 Evaluation and LLMOps

- **Capability:** Offline eval sets, automated scoring (programmatic, LLM-as-judge with calibration, human review), regression gates in CI, online quality monitoring.
- **Needed when:** Always for rung 4+. G8 requires an offline eval set at T3/T4.
- **Selection criteria:** Dataset versioning; metric transparency; judge-model calibration against human labels; CI integration; data residency of traces sent to the eval tool.
- **Example options:** Microsoft Foundry evaluations; LangSmith; Langfuse; MLflow GenAI evaluation; promptfoo, Ragas, DeepEval, Inspect (open-source). `[JUDGMENT]`.

### 6.7 Audit

- **Capability:** Tamper-evident record of who (user, agent, workload identity) did what, with which model/prompt/tool versions, and what was approved.
- **Needed when:** Any write action or regulated data. Always at T3+.
- **Not needed as a new system when:** The enterprise SIEM/log archive accepts structured AI audit events with adequate retention.
- **Selection criteria:** Immutability; correlation IDs end to end; separation of audit logs from debug traces (different retention and access); PII minimization.

---

## 7. Operations and engineering

### 7.1 CI/CD

- **Capability:** Build, test, eval-gate, and deploy code, prompts, and configuration together.
- **Selection criteria:** Eval stage as a release gate; environment promotion for prompts/models; signed artifacts.
- **Example options:** GitHub Actions, Azure DevOps Pipelines, GitLab CI, Jenkins. Reuse the enterprise standard. `[JUDGMENT]`.

### 7.2 Infrastructure as code

- **Example options:** Terraform/OpenTofu, Bicep, Pulumi, AWS CDK/CloudFormation. Reuse the enterprise standard; check Terraform's BSL vs OpenTofu MPL licensing if relevant `[JUDGMENT]`.

### 7.3 Container platforms

- **Needed when:** Self-hosted inference, custom agent services at scale, or portability requirements.
- **Not needed when:** PaaS (App Service, Container Apps, Cloud Run, Functions) meets the need with less operational burden. See `deployment-patterns.md`.
- **Example options:** AKS, EKS, GKE, OpenShift, Azure Container Apps (managed Kubernetes-based PaaS). `[JUDGMENT]`.

### 7.4 Observability and tracing

- **Capability:** Logs, metrics, distributed traces across services, models, tools, and agents.
- **Selection criteria:** OpenTelemetry-native ingestion; trace correlation across async boundaries and MCP calls; cost of high-cardinality AI telemetry.
- **Status of OpenTelemetry GenAI semantic conventions:** Still **Development** (not Stable) as of mid/late 2026, and moved out of the core `semantic-conventions` repo into **`open-telemetry/semantic-conventions-genai`** (reported with semconv v1.42.0, 2026-06-12) `[INDEPENDENT]` secondary sources (sources: https://www.dash0.com/knowledge/opentelemetry-genai-semantic-conventions-explained, updated 2026-09-14; https://dev.to/azena-ai/opentelemetrys-genai-semantic-conventions-are-not-stable-yet-heres-what-actually-shipped-in-2026-3mke, accessed 2026-10-27). The new repo exists, covers GenAI clients, MCP, and provider-specific conventions, and had **no tagged release** when checked `[VERIFIED]` (source: https://github.com/open-telemetry/semantic-conventions-genai, accessed 2026-10-27). **Implication:** attribute names may still change; pin the semconv version your instrumentation emits and expect migrations `[JUDGMENT]`.
- **Example options:** Azure Monitor/Application Insights, Amazon CloudWatch/X-Ray, Google Cloud Observability, Grafana stack, Datadog, Dynatrace, Elastic.

### 7.5 LLM observability

- **Capability:** Prompt/response/tool-call traces, token and cost accounting, eval scores attached to traces, session replay.
- **Not needed as a separate product when:** The APM platform ingests OTel GenAI spans adequately and the eval tool covers quality.
- **Selection criteria:** OTel compatibility (avoid proprietary-only SDKs); PII redaction before export; self-hosting option for sensitive data.
- **Example options:** LangSmith, Langfuse (open-source, self-hostable), Arize Phoenix, Foundry observability (preview integration in MAF 1.0) `[VENDOR]`, Datadog LLM Observability. `[JUDGMENT]`.

### 7.6 Secrets management

- **Requirement:** Credentials are never in prompts, model context, or agent-readable files. Use workload identity where possible.
- **Example options:** Azure Key Vault, AWS Secrets Manager, Google Secret Manager, HashiCorp Vault/OpenBao.

### 7.7 Identity and access management

- **Capability:** Distinct identities for user, workload, agent, and tool; delegated (on-behalf-of) vs application permissions; short-lived tokens.
- **Selection criteria:** Support for agent identities as first-class principals; OAuth 2.1 for MCP; conditional access; per-tool scopes.
- **Example options:** Microsoft Entra ID (incl. Entra Agent ID `[UNVERIFIED]` status), Okta, AWS IAM Identity Center, Keycloak.

### 7.8 Incident response

- **Capability:** AI-specific runbooks: kill switch per agent/tool, prompt rollback, model failover, memory purge, credential revocation, user notification.
- **Needed when:** Any production rung 4+. Mandatory content for G9 at T3+.

### 7.9 Cost management

- **Capability:** Token and GPU cost attribution per application/tenant, budgets and alerts, quota enforcement ("denial of wallet" protection).
- **Selection criteria:** Cost per business transaction (not per token); gateway metering; GPU utilization; caching and model right-sizing levers.
- **Example options:** Cloud cost management tools plus gateway token metering; FinOps tagging standards. `[JUDGMENT]`.

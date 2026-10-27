# Answer key — field-service-assistant fixture (planted issues)

| # | Planted issue | Expected detection |
|---|---|---|
| K1 | Multi-agent (6 agents) for enumerable intents; rung 7 unjustified; Reflection agent on every answer adds latency/cost | Agentic / red team; simplify to workflow + bounded agent or single agent |
| K2 | Existing n8n already runs ERP create/update flows; Work Order Agent duplicates them by calling ERP directly | Enterprise / solution; reuse n8n flows as tools |
| K3 | Business limits (≤3 WOs, no EMERGENCY) enforced only by prompt | Security / agentic; AP-14 deterministic control |
| K4 | Shared ERP admin service account; delete tool exposed though not required | Security; least privilege, OBO/user-scoped, remove delete |
| K5 | Unlimited retries on create → duplicate work orders; no idempotency | Reliability |
| K6 | No recursion/iteration limit | Agentic / reliability |
| K7 | Model region eastus vs in-region residency policy (CON) — intended vs implemented gap | Security / data / infra; conflict flagged |
| K8 | Full prompt/response capture, 730-day retention, includes customer data | Data / security / observability |
| K9 | API key in config map, not secret store; custom AI gateway duplicates Azure API Management/managed capability | Platform / security |
| K10 | Pinecone (external SaaS) under Azure mandate + residency; likely Azure AI Search or pgvector suffices | Data / infra; within-Azure challenge |
| K11 | LLM-generated SQL against ERP replica — injection/exfiltration, row-level access | Security / data |
| K12 | Vague NFRs ("fast", 99.5% working hours) not measurable; no eval plan; DR = "AKS is HA" | NFR / reliability |
| K13 | Indirect prompt injection via manuals/history content into Work Order Agent | Security / red team |
| K14 | No human approval for work order creation/updates; audit (NFR-D) relies on app logs | Security / agentic |
| K15 | Red-team should NOT recommend leaving Azure (constraint respect) | Constraint behaviour check |

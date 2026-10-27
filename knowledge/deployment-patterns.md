# Deployment Patterns for AI Systems

- **Last verified:** 2026-10-27
- **Confidence:** High for the patterns and trade-offs (`[JUDGMENT]`, not time-sensitive). Product-specific notes are labelled individually.
- **Layer:** B. Respect a mandated platform (`standards/architecture-principles.md` §6): use this file to choose *within* it, not to introduce other clouds.

Each pattern lists: when to use · constraints · network/identity · model serving · operational burden · failure modes. Patterns combine. Most enterprise estates end up hybrid in some dimension.

## 1. Managed cloud PaaS

- **When to use:** Default for cloud-permitted workloads. Agent/API services on app platforms (App Service, Container Apps, Cloud Run, Lambda-style), managed databases and search, managed model endpoints.
- **Constraints:** Platform limits (request timeouts, max instance memory, GPU availability, regional service availability); feature parity differs by region.
- **Network / identity:** Use managed/workload identities to reach models, data, and secrets; private endpoints + VNet integration for data and models; egress control via firewall/NAT. Planning subnet sizing, DNS for private endpoints, and outbound access is part of the deployment, not an afterthought (Microsoft states this explicitly for Foundry hosted agents needing private access to storage, databases, or Key Vault) `[VENDOR]` (source: https://devblogs.microsoft.com/foundry/whats-new-in-microsoft-foundry-july-august-2026/, accessed 2026-10-27).
- **Model serving:** Managed model endpoints; quota and capacity type (shared vs provisioned/reserved throughput) become the main design levers.
- **Operational burden:** Lowest. The provider patches the platform; you own configuration, identity, data, and app code.
- **Failure modes:** Regional service outage; quota exhaustion/throttling (429s) under load; silent model version changes if versions are not pinned; private DNS misconfiguration breaking connectivity after a change.

## 2. Container platform (Kubernetes)

- **When to use:** Self-hosted inference on GPUs; many services needing uniform deployment/policy; portability requirement; existing platform team and cluster estate.
- **Constraints:** Requires mature platform engineering; GPU node pools and drivers; cluster upgrades every few months.
- **Network / identity:** Workload identity federation (pod → cloud identity); network policies between namespaces; service mesh or mTLS for east-west traffic; ingress with WAF; egress gateways to restrict agents' outbound access.
- **Model serving:** Serving engines (vLLM, SGLang, Triton) as Deployments/KServe InferenceServices; GPU scheduling, bin-packing, autoscaling on queue depth or KV-cache utilization rather than CPU; model weights pulled from an internal registry/object store, not the internet.
- **Operational burden:** High. Cluster lifecycle, GPU drivers/operators, capacity planning, security patching, cost management.
- **Failure modes:** GPU node unavailability/preemption; cold starts loading large weights (minutes); noisy neighbours on shared GPUs; autoscaler lag under burst; driver/CUDA version mismatches after upgrades.

## 3. Serverless

- **When to use:** Event-driven, bursty, short LLM steps (classification, extraction triggered by a queue or blob event); glue between systems.
- **Constraints:** Execution time limits; cold starts; limited concurrency control; no GPUs on most function platforms; long agent loops do not fit unless a durable extension orchestrates them.
- **Network / identity:** Managed identity per function app; VNet integration (may require premium plans) for private model endpoints.
- **Model serving:** Calls managed endpoints; not suitable for hosting models.
- **Operational burden:** Low.
- **Failure modes:** Timeouts mid-LLM call → duplicate processing on retry (needs idempotency); runaway fan-out amplifying model cost and throttling; cold-start latency spikes.

## 4. On-premises

- **When to use:** Data or regulatory constraints forbid cloud processing; latency to on-prem systems; existing data-center GPU investment.
- **Constraints:** Hardware lead times and capacity ceilings; open-weight models only (or vendor on-prem offerings where available); quality gap vs frontier managed models must be measured.
- **Network / identity:** Enterprise IdP (AD/Entra hybrid, LDAP, Keycloak); internal PKI; segmentation between AI workloads and systems of record; proxy-controlled egress.
- **Model serving:** Self-hosted inference (§2 mechanics) on owned accelerators; capacity is fixed, so admission control and queueing are mandatory.
- **Operational burden:** Highest of the connected options: hardware, facilities, firmware, drivers, serving stack, models.
- **Failure modes:** Capacity saturation with no burst option; hardware failure reducing replicas below HA; stale models because upgrade effort is high; shadow cloud usage by teams frustrated with capacity.

## 5. Air-gapped

- **When to use:** Classified, national-security, or critical-infrastructure environments with no external connectivity.
- **Constraints:** No managed APIs, no online licence checks, no SaaS observability, no package registries. Every artifact (weights, containers, Python wheels, eval datasets, vulnerability feeds) is imported through a controlled transfer process.
- **Network / identity:** Fully internal identity and PKI; one-way or diode-based import; strict artifact provenance and scanning.
- **Model serving:** Open-weight models with licenses permitting such use; self-hosted serving; all tooling (eval, tracing, registries) self-hosted.
- **Operational burden:** Very high. Update latency is measured in weeks; security patches follow the same import process.
- **Failure modes:** Software that silently phones home (telemetry, license validation) failing at runtime; dependency drift between connected build and air-gapped run environments; outdated models and CVE backlog.

## 6. Hybrid

Two common forms:

| Form | Description | Key design points |
|---|---|---|
| **6a. Cloud control plane + on-prem data** | Apps, orchestration, and managed models in cloud; sensitive data stays on-prem and is accessed through governed APIs or retrieval services | Data minimization in what is sent to the model; on-prem retrieval returns only needed passages; private connectivity (ExpressRoute/Direct Connect/VPN); clear classification of what may leave the premises |
| **6b. On-prem inference + cloud apps** | Model inference runs on-prem (data cannot leave, or GPUs already owned); applications or orchestration in cloud | Inference endpoint exposed over private link with mTLS and gateway auth; latency budget across the WAN; capacity is the on-prem ceiling; cloud apps must degrade gracefully when the WAN or on-prem cluster is down |

- **Constraints:** Two operational models; split responsibility; data classification rules must be precise about which flows cross the boundary.
- **Network / identity:** Federated identity across environments; workload identity for cross-boundary calls; no shared static keys.
- **Model serving:** Often mixes managed and self-hosted models. See `reference-architectures/hybrid-managed-and-self-hosted-models.md`.
- **Operational burden:** High. Two environments to observe, with end-to-end tracing across the boundary.
- **Failure modes:** WAN partition; asymmetric security controls (the weaker side is the target); data leaking across the boundary through logs or traces; inconsistent model versions between environments.

## 7. Multi-region

- **When to use:** Availability SLO beyond one region; regional residency for different user populations; regional quota capacity.
- **Constraints:** Model availability and versions differ by region; residency may *forbid* cross-region failover for some data; vector indexes and conversation state need replication strategy.
- **Network / identity:** Global load balancing with health checks that probe model reachability, not just app liveness; per-region private endpoints.
- **Model serving:** Same model and version deployed per region where possible. Cross-region "global" deployment types may route inference outside the region, so check residency terms before using them `[JUDGMENT]`.
- **Operational burden:** Medium–high. Eval and configuration must be identical per region; drift is the main risk.
- **Failure modes:** Failover to a region with a different model version (behavior change); split-brain on agent state; failover violating residency; both regions throttled by a shared upstream quota.

## 8. Edge

- **When to use:** Intermittent connectivity, ultra-low latency, or local data processing (field devices, plants, retail sites, vehicles, on-device assistants).
- **Constraints:** Small models only (quantized, often < 10B parameters on constrained hardware `[JUDGMENT]`); fleet management; physical security of devices and weights.
- **Network / identity:** Device identity and attestation; store-and-forward sync; signed model and config updates.
- **Model serving:** Lightweight runtimes (llama.cpp, ONNX Runtime, vendor NPU SDKs, Ollama for development); escalation to central models when connected and permitted.
- **Operational burden:** High at fleet scale: rollout, telemetry, rollback across thousands of devices.
- **Failure modes:** Fleet version skew; model extraction from stolen devices; quality loss from quantization not covered by evals; unbounded local logs containing sensitive data.

## 9. Private connectivity to managed model endpoints and inference residency

### 9.1 Private connectivity

- **Private endpoints** (Azure Private Link, AWS PrivateLink, Google Private Service Connect) give managed model and agent services a private IP in your network. Disable public network access on the resource once private access works, and verify it with a test from outside `[JUDGMENT]`.
- **DNS** is the usual failure point: private DNS zones must resolve the service FQDN to the private IP from every calling network, including on-prem resolvers forwarding to cloud DNS.
- **Outbound from the model platform:** managed agent services that call tools, fetch URLs, or access your data stores need their own egress path: VNet-injected or managed-VNet runtimes, firewall allow-lists, and private endpoints to your data. Check per service which features work under network isolation; some agent tools (e.g. web search/fetch) inherently require public egress `[JUDGMENT]`. Verify per product.
- **Gateway in the path:** routing model traffic through an AI/API gateway on the private network centralizes auth, quotas, and logging, but it becomes a critical dependency. Deploy it zone-redundantly with capacity for streaming connections.
- **Identity, not keys:** use managed/workload identity with role assignments scoped to the specific model deployment; disable key-based auth where the service allows.

### 9.2 Data residency of inference

Residency has several parts. Verify each one for the specific service, deployment type, and region on the decision date:

| Data at rest/in motion | Question to answer |
|---|---|
| Inference processing location | Does the deployment type process prompts only in the chosen region, within a geography/data zone, or globally? (Cloud providers offer regional, data-zone, and global deployment types with different residency, quotas, and prices `[UNVERIFIED]` per provider on 2026-10-27.) |
| Prompt/response retention | Are prompts/outputs stored by the provider (e.g. for abuse monitoring), where, and for how long? Can it be disabled or reduced under contract? |
| Stateful features | Threads, files, vector stores, memory, and agent state held by a managed agent service. In which region, and under whose keys? |
| Logs and traces | Your own observability pipeline may export prompts to another region or SaaS. This is the most common residency leak `[JUDGMENT]`. |
| Fine-tuning data and artifacts | Where training data and tuned weights are stored and processed |
| Failover | Does multi-region or "global" failover move processing outside the permitted area? |
| Sub-processors | Which third parties (e.g. model developers hosted by the cloud provider) process data, and under which terms? |

Record the answers as `CON-`/`ASM-` items in the use case. A residency claim without a dated source is `[UNVERIFIED]`.

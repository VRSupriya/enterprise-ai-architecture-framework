<!-- Saved verbatim by the board chair. Rebuttal brief: DBT-03 runtime (AKS vs Container Apps). Date: 2026-10-27. Round 2. -->

DBT-03 rebuttal (F-IN-05): I refine my position. The severity stays Medium, and I agree with the red team that AKS does not breach CON-001.

1. **Yes, and the case is stronger for the two-service target.** It is two stateless HTTP services at about 0.06 req/s (ASM-IN-01), n8n does the writes, and there is no agent loop or GPU. Kubernetes features would go unused, but the team would still carry upgrades, node patching, network policy and ingress, with no platform-engineering skills on record (ASM-003). The recommendation is Container Apps: one workload-profiles environment, zone-redundant, at least 2 replicas per app, with UDR/Firewall egress and private endpoints. Removing the loop also eases the 120 s timeout concern. The ingress timeout limit itself is still `[UNVERIFIED]`.
2. **AKS becomes the right answer if any of these is true:**
   - (a) a self-hosted or open-weight model needs GPU node pools in the mandated region (for example, because CON-002 rules out a Regional Azure OpenAI deployment);
   - (b) the landing-zone standard names an existing enterprise AKS platform, run by a named platform team, as the required runtime for internal apps (answers Q-IN-01);
   - (c) the estate grows to many services that need controls Container Apps lacks, such as a service mesh, custom admission policy or node-level controls, and that need is documented as a requirement.
   None of these is in the current evidence.
3. **Write a short ADR, not just a design note.** PREF-001 named AKS, so rejecting a stakeholder's stated preference should be on record. AP-12 requires an exit cost (Container Apps → AKS: days to weeks, since images are portable; IaC and networking get reworked). The board debated it (DBT-03). The ADR should list a–c above as its revisit triggers.

Severity is Medium because this is operability and cost, not compliance. F-RT-15, the availability-model gap, applies to any runtime, and zone redundancy plus minimum replicas closes it on either platform.

<!-- Saved verbatim by the board chair. Rebuttal brief: DBT-03 runtime (AKS vs Container Apps). Date: 2026-10-27. Round 2. -->

DBT-03 rebuttal (red-team-architect): **REFINE, conceding the substance.**

1. My earlier line meant only that AKS does not breach CON-001. I never tested whether it fits the workload, so that line is not evidence for AKS. I accept F-IN-05 at **Medium**: AKS here is disproportionate to the workload (AP-03, AP-06), and it adds ops surface for a team that is already stretched by F-RT-10. My availability arithmetic in F-RT-15 does not depend on which runtime is chosen.
2. **The load arithmetic holds.** 400 interactions over an 8 h working day is about 0.014 req/s, or about 0.07 req/s at 5× peak. Per-turn LLM calls multiply this by roughly 3–4×, which still leaves negligible compute. The runtime is not the bottleneck; AOAI and the ERP are.
3. **One evidence correction.** ASM-003 records "Python-skilled, no agent-framework experience". It says nothing about platform engineering. "No platform-engineering capability" is an inference, so label it [ASSUMPTION] or confirm it. The conclusion survives either way, but the citation should be fixed.
4. **I do not challenge choosing Container Apps.** I would make it conditional on these checks, all [UNVERIFIED], because research was not in scope:
   - (a) In-region availability (CON-002): workload profiles and zone redundancy must exist in the mandated region. If they don't, reopen the decision rather than move regions.
   - (b) Request duration: the ingress timeout and streaming limits must cover the worst-case turn, which is up to 120 s today. Better, shrink that turn via F-RT-09 and F-RT-14. Also, the work-order command service must not depend on a held-open HTTP request for retries or reconciliation. Use an async or queued command with an idempotency key (F-RT-04).
   - (c) Cold start: set minimum replicas to at least 1 per zone, with no scale-to-zero on either service, or NFR-A and NFR-B suffer.
   - (d) Reuse: if the enterprise already runs a governed shared AKS platform with an owning team, AP-06 favours onboarding to it. Add this as a revisit trigger next to self-hosted models and a platform mandate.
5. **The two-service split is sound.** The work-order command service gives the boundary where F-RT-01, -02, -03 and -04 get enforced: least-privilege identity, deterministic limits, the audit record and idempotency. Its managed identity must be separate from the conversation service's.

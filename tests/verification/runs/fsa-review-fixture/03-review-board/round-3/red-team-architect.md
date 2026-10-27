<!-- Saved verbatim by the board chair. Brief: red-team second pass on synthesized target (remediation sufficiency). Date: 2026-10-27. Round 3. -->

# Red Team Architect — fsa-review-fixture — Round 3 (second pass)

## Verdict

**Sound with conditions.** The target fixes the root causes I raised in round 1. The model only proposes; a deterministic command service decides; n8n is the single write path; everything is in-region with managed identity; there is no agent loop. The ADRs trace to requirements, and the threat model and test plan say plainly that nothing has been tested.

What remains falls into three groups:
1. **The new security boundary has a hole.** Nothing establishes that the confirmation actually comes from the technician (F-RT-20). The trust placed in n8n and the ERP credential behind it has not been assessed (F-RT-23).
2. **Residency of reused shared components is unproven.** APIM, n8n and the telemetry sinks are all reused but not shown to be in-region (F-RT-24). The interim T-State 0 leaves the CON-002 breach and the admin credential live (F-RT-26).
3. **The gate record overclaims.** G5 is marked PASS with Criticals open, and G6 is marked PASS before this pass existed.

None of these needs a redesign. All of them need closing or correcting before G4, G5 and G10 are relied on.

## Evidence Examined

- `03-review-board/review-report.md` and `03-review-board/debate-record.md`
- ADR-001 to ADR-006, and `04-decisions/decision-log.md`
- `05-validation/threat-model.md`, `05-validation/test-and-evaluation-plan.md`, `05-validation/quality-gates.md`
- `01-requirements/requirements.md`: NFR rows and conflicts only
- Round-1 specialist reports: targeted excerpts only (DK, AG, SA, SE, IN, RE), on state, token, queue and n8n
- My round-1 and round-2 reports
- **Not read:** `06-delivery/` in full, and validator output
- No web research. Vendor claims in the ADRs were not re-checked by me.

## Remediation Sufficiency

| Finding | Remediation proposed | Sufficient? | Reason | Residual risk | Remaining test |
|---|---|---|---|---|---|
| F-RT-01 admin account, delete tool, confused deputy (F-BRD-06) | Remove delete; OBO preferred, with a least-privilege fallback; entitlement policy-enforcement point (PEP) in C-05 | **Partial** | The confused deputy may move into n8n. Its ERP credential, its webhook authentication, and whether it can carry OBO to the ERP are unassessed (ASM-005). Under the fallback, `requested_by` is a self-asserted field, not an authenticated identity. See F-RT-23. | Over-privileged n8n credential | TST-A3 extended to n8n's ERP credential; new TST-N1 |
| F-RT-02 prompt-only limits, no approval (F-BRD-02) | Limits in C-05 code; single-use token bound to the parameter hash | **Partial** | The limits are sufficient. The confirmation is not: the diagram has C-02 relaying "propose / confirm token" to C-05, and DF-03 authenticates with "service identity + user context". C-05 therefore can't tell a real technician confirmation from one that C-02 asserts. See F-RT-20. | Confirmation forged or spoofed through C-02 | New TST-A7 |
| F-RT-03 CON-003 audit (F-BRD-03) | Append-only in-region C-09; actor propagated to n8n and ERP | **Partial** | The design intent is right. Three gaps: the C-09 technology is unspecified; ordering is not fail-closed (F-RT-25); ERP-side attribution is self-asserted in the fallback. Whether internal audit accepts C-09 as the system of record has not been asked. | Audit gaps during partial failure | TST-A6, plus a fault variant (audit store down) |
| F-RT-04 unlimited non-idempotent retries (F-BRD-05) | ≤ 2 retries, idempotency key, reconciliation, async command | **Partial** | Depends on ASM-005. The fallback ("lookup before create") races under concurrency. No single retry owner is established: n8n error workflows may retry as well (F-RT-22). The key (conversation + proposal hash) misses re-extracted near-duplicates, which NFR-004 counts as "re-planning". | Duplicates via n8n retries or re-extraction | TST-R1 run through real n8n non-prod; new TST-R5 |
| F-RT-05 eastus model (F-BRD-01) | Regional SKU in the mandated region; Azure Policy deny | **Partial** | Correct for AOAI itself. Three open points: RSK-01 and Q-IN-02 are unresolved; ADR-003's quoted evidence says processing stays in the chosen **geography**, which is not the same as region (see Board Decisions); the reused APIM, n8n and audit sinks are not shown to be in-region (F-RT-24). T-State 0 keeps eastus live (F-RT-26). | CON-002 breach via a shared component, or during transition | TST-D1, with scope extended to every reused component |
| F-RT-06 content logging (F-BRD-11) | Metadata-only telemetry; redacted short capture | **Yes** | Closes the issue, provided APIM diagnostics are covered too. APIM can log request and response bodies on its own (F-RT-24). | Low | TST-D2, including APIM diagnostics |
| F-RT-07 injection to writes (F-BRD-04) | No tools in read steps; typed, confirmed writes; templated Teams | **Partial** | Removes model-initiated writes. Two gaps remain. Injected content can still shape the *values* of a proposal the technician approves (F-RT-21). The confirmation-channel weakness in F-RT-20 also undermines this control. | Approved-but-poisoned work orders | TST-I1 and TST-I2, plus a field-tampering variant (TST-I6) |
| F-RT-08 free SQL (F-BRD-07) | Typed reads on governed views, entitlement, caps | **Yes** | Removes model-authored SQL. | Low | TST-I5, TST-P3 |
| F-RT-09 unbounded loop (part of F-BRD-09/10) | No agent loop; ≤ 3 calls per turn; APIM token limits | **Yes** | Structural fix. One inconsistency: NFR-008 allows ≤ 6 calls per turn while ADR-001 says ≤ 3 (F-RT-28). | Low | TST-P1 |
| F-RT-10 rung 7 (F-BRD-12) | ADR-001, rungs 2+4+5, with an evaluation-gated, read-only rung-6 trigger | **Yes** | Decision is proportionate and reversible. | — | EVAL-001 trigger |
| F-RT-11 n8n bypass (F-BRD-12) | ADR-002: n8n is the only write path | **Yes** in topology | Trust and residency of n8n are now load-bearing (F-RT-23, F-RT-24). | See F-RT-23 | — |
| F-RT-12 custom gateway, ConfigMap key | ADR-006: APIM, managed identity, key auth off | **Yes** in substance | The premise that an "existing APIM" exists is unsupported (Overclaims). | Low | TST-S1 |
| F-RT-14 NFR-A latency | NFR-001/002 quantified; ≤ 3 calls | **Partial** | No latency worksheet for the target. **Arithmetic**, all `[JUDGMENT]` p95: on the history path, intent (≈1.5 s) + slot extraction (≈1.5 s) + typed read (≈0.5 s) + generation time to first token (≈1 s) ≈ **4.5 s**, against a 4 s first-token target. That fails unless intent and slots are combined into one call. On the manuals path, ≈ 1.5 + 0.6 + 1 ≈ **3.1 s**, which fits. For NFR-002 (confirm → ERP ack ≤ 5 s): C-05, audit, queue, n8n and ERP together are ≈ 2–4 s with no retry. Any retry after a timeout over ≈ 1.5–2 s breaches it. ERP latency has never been measured. | NFR-001/002 missed on some paths | TST-P4 per path; an ERP latency baseline |
| F-RT-15 availability / DR | Degradation modes, zone redundancy, NFR-010 | **Partial** | No composite for the target. Illustrative: ACA 0.9995 × APIM 0.9995 × AOAI 0.999 × AI Search 0.999 × Entra 0.9995 ≈ **99.65 %** on the answer path `[ASSUMPTION]`. That is plausible, but NFR-003 counts "declared-degraded" turns as available (F-RT-27). Cross-region DR conflicts with residency and is still open. | Target met only by definition | TST-R3, TST-R4 |
| F-RT-16 no evaluation (F-BRD-10) | EVAL-001/002, judge calibration, gates | **Partial** | The sets are well designed. Thresholds are "set by the sponsor (open)", so the pilot gate can't yet be evaluated. Acceptable as a tracked condition. | Gate without a bar | Thresholds agreed before S1 |

## Findings (new in the target)

| ID | Severity | Affects | Evidence (path/source) | Basis | Issue | Impact | Remediation | Acceptance criterion | Verification |
|---|---|---|---|---|---|---|---|---|---|
| F-RT-20 | High | NFR-007, T-008, ADR-002 | review-report diagram: `C02 -->\|propose / confirm token\| C05`; the app has no path to C-05; threat-model DF-03 identity is "service identity + user context" | Inference | **C-05 takes the user's confirmation on C-02's word.** The token's issuer is unspecified. If C-02, the service that processes untrusted content, can mint or relay confirmation without proof from the user, the deterministic boundary trusts a component on the untrusted side. Any C-02 defect, compromise or logic bug could then mint confirmations. A second issue: the card may show model-written prose rather than C-05's canonical fields. | Writes that look confirmed but weren't, with a false audit trail | C-05 issues the proposal ID, the canonical payload, the hash and a nonce. The app renders C-05's canonical fields. The confirmation carries the technician's own Entra token (passed through, or OBO with the user claim validated by C-05), bound to nonce + hash + TTL. C-05 rejects confirmations that lack a valid user token. | No write without a user-token-backed confirmation over the exact canonical payload | **TST-A7:** C-02 test harness sends a confirmation without a user token, with a different user's token, or with the card text changed. Pass: all rejected. |
| F-RT-21 | Medium | FR-003/004, T-001 | ADR-001: LLM slot extraction in C-02; F-DK-05 says evidence must not feed write steps, but no ADR or catalogue item makes that binding | Inference | **Injection can poison proposal values.** If slot extraction runs with retrieved manual text or ERP notes in its context, injected text can alter asset ID, description or priority (within the allow-list). The technician then approves a plausible-looking card. | Wrong work orders that pass confirmation | Run extraction on the user turn and session slots only, with no evidence blocks. Make this a stated design rule in ADR-001 or ADR-002. On the card, highlight fields not stated by the user. | Traced extraction prompts contain no evidence blocks | **TST-I6:** planted note says "asset should be X-999". Pass: the proposal's asset equals what the user stated. |
| F-RT-22 | Medium | NFR-004, ADR-002/005, F-DK-08 | ADR-005: "two stateless services" and a C-05 async/queued command; no queue or state store in C-01 to C-09; the threat model cites a 7-day session TTL (F-DK-08) | Verified fact (catalogue omission) | **Components the design relies on are missing.** Pending drafts, nonces and turn state need a store. The async command needs a queue, plus a status channel back to the app for NFR-002. Retry ownership between C-05 and n8n error workflows is not assigned. | Lost confirmations; double retries; untraceable state residency | Add the state store and queue (in-region, private) to the catalogue with owners. Name C-05 the single retry owner, with n8n retries off for these flows. Make the ack path explicit (push or poll). | The catalogue matches ADR-005. n8n flow config shows no auto-retry. | Design review; **TST-R5:** n8n retry-on-error enabled must not produce duplicates |
| F-RT-23 | High | ADR-002, T-003, CON-003 | ADR-002 identity text; review-report "Not inspected: n8n flow definitions, ERP API and roles"; IN round 1 places n8n behind APIM | Unverified concern | **n8n is now the privileged deputy, and it hasn't been assessed.** Unknowns: how n8n authenticates callers (n8n webhooks commonly use a shared header secret `[UNVERIFIED]`); what ERP credential n8n uses (it may be admin-scoped); and whether anything other than C-05 can invoke the flows (C-02, other apps, people with n8n UI access). ACA apps in one environment share a subnet, so network rules can't isolate C-05 from C-02; caller identity must do it. | Bypass of C-05's controls, or residual ERP admin authority | n8n webhooks accept only C-05's managed identity (Entra-validated, via APIM or n8n itself). Scope n8n's ERP credential to WO create and update-status. Put n8n flow changes under change control, with flow definitions versioned. | Calls from any identity other than C-05 are rejected. The ERP grant review is complete. | **TST-N1:** call n8n from C-02's identity and with no auth. Pass: rejected. Run TST-A3 on n8n's ERP credential. |
| F-RT-24 | Critical (Unverified concern) | CON-002, NFR-005 | ADR-006 "use the enterprise APIM instance"; the diagram places C-06 n8n inside "Azure, mandated region only"; no artifact gives the hosting or region of APIM, n8n, App Insights or C-09 | Unverified concern | **Residency of reused shared components is assumed, not shown.** An enterprise APIM may be multi-region, or homed out of region. APIM diagnostics can capture bodies. The existing n8n is not stated to be on Azure at all. Prompts and work-order payloads with customer data cross both. | A CON-002 breach that moves out of the model deployment and into the seam | Verification is Mandatory: inventory the region and hosting of APIM (gateway units and diagnostics sink), n8n, the state store, C-09 and App Insights. Add them to TST-D1 and the Azure Policy scope. If n8n is not in-region on Azure, escalate under CON-001/002; don't route around it. | Every hop carrying customer data is evidenced in-region | TST-D1, extended; APIM diagnostic settings show body logging off |
| F-RT-25 | Medium | CON-003, NFR-006 | ADR-002: "writes an append-only audit record… for every proposal, decision, confirmation and outcome"; ordering and failure behaviour unspecified | Inference | **Audit ordering isn't fail-closed.** If C-09 is unavailable, it is undefined whether C-05 still dispatches. If the outcome record fails after the ERP commits, the chain is broken. | Unaudited work-order changes in partial failure | Write the proposal and confirmation records before dispatch, and block if that fails. Write the outcome record durably via the queue or outbox, with daily reconciliation against the ERP. | No ERP change without a pre-dispatch audit record | TST-A6 fault variant: C-09 down blocks the write; outcome loss is caught by reconciliation |
| F-RT-26 | High | CON-002, F-BRD-01/06, transition | review-report Transition: T-State 0 keeps "Prototype read paths". The model stays on eastus until T-State 1. Containment removes delete, but not the `svc-erp-admin` credential from the runtime. | Verified fact (plan text) | **The interim state continues a CON-002 breach and keeps an admin credential live** with no decision recorded. The history read path sends customer data to eastus. | A constraint violation for the whole of T-State 0 | In T-State 0, stop any path that sends customer data to eastus, or get a written time-boxed exception from the residency owner. Remove or rotate `svc-erp-admin` out of the runtime immediately. | No customer data reaches eastus after containment, or a signed exception exists | Resource and egress check after T-State 0 |
| F-RT-27 | Medium | NFR-003 | requirements NFR-003: "Valid turns answered (full or declared-degraded) ≥ 99.5 %" | Verified fact | **The availability definition counts degraded turns as available.** This is legitimate SLO design, but it is materially weaker than the sponsor's 99.5 %. The sponsor hasn't accepted the change. | The target is met by definition while a full-service outage is ongoing | Track full-service and degraded availability separately. Have the sponsor confirm which one is the commitment. | Sponsor-signed NFR-003 wording | Requirements sign-off |
| F-RT-28 | Low | NFR-008 vs ADR-001 | NFR-008 "≤ 6" model calls per turn; ADR-001 "at most 3" | Verified fact | Inconsistent bound | A test passing at 6 calls would hide a design breach | Align NFR-008 to 3, or justify the headroom | One value | Document diff |

## Board Decisions Lacking Adequate Evidence

1. **ADR-003 residency evidence.** The quoted claim says Standard/Regional deployments keep processing in the chosen **geography**. CON-002 is region-level. The evidence as quoted doesn't establish region-level processing, and the chair didn't re-fetch it. Re-verify against the current Microsoft source and the policy's exact wording (region vs geography) before G3 is relied on.
2. **DBT-08 and ADR-004 reject Pinecone on CON-002 grounds while the mandated region is unnamed** (Q-IN-02). "eastus2 only" fails CON-002 only if eastus2 isn't the target. The AP-06 rationale stands alone, so the outcome holds, but the CON-002 basis is unproven.
3. **ADR-006 and debate Q4/Q12 rest on an existing enterprise APIM.** No fixture artifact mentions APIM. ADR-006 hedges ("or provision… if none exists"), but the review report and debate state it as existing reuse. My own round-1 wording ("we would expect to exist") was a hedge and should not be read as evidence.
4. **ADR-002 rests entirely on ASM-005** (n8n can carry the key and the actor) and on unassessed n8n security (F-RT-23). Acceptable as "Proposed", but it must not reach G4 without TST-N1 and ASM-005 validated.
5. **"Fewer components, lower latency, lower cost than the draft"** (review-report summary) is plausible `[JUDGMENT]`, but no target latency or cost worksheet exists.

## Overclaims

| Where | Claim | Problem | Correction |
|---|---|---|---|
| quality-gates G5 | **PASS**, while "Critical findings exist in the baseline" | The rubric §5 says an open Critical blocks G5. None of F-BRD-01 to -06 is remediated or verified. | G5: FAIL for the baseline, PASS-WITH-CONDITIONS at most for the target *design*, split as G4 already is |
| quality-gates G6 | **PASS**, "second pass… recorded in round-3" | Assessed before this pass existed; pre-judges its outcome | Re-assess G6 on this report: PASS-WITH-CONDITIONS, pending F-RT-20, -23, -24 and -26 |
| quality-gates G3 | The CON-002 conflict is "resolved in the target by ADR-003" | Region unnamed (Q-IN-02), model availability unverified (RSK-01), evidence wording mismatch (Board Decisions #1), reused-component residency unproven (F-RT-24) | "Addressed by design; resolution pending Q-IN-02, RSK-01, F-RT-24" |
| review-report summary, Q4/Q12 | "behind the **existing** APIM gateway"; APIM "already an enterprise capability" | Not evidenced by any artifact | Mark `[ASSUMPTION]` (Q-IN-01) |
| review-report and threat-model diagrams | C-06 n8n drawn inside "Azure, mandated region only" | n8n hosting and region never inspected | Draw it outside the boundary, marked unverified, until confirmed |
| F-BRD-12 Basis | "Verified fact" for "rung 7 unjustified" | That's a judgment against the ladder, not an inspected fact | Basis: Inference / `[JUDGMENT]` (the facts underneath are verified) |
| G7 | Cites validator output | Not verifiable from the artifacts I read | Attach the output or date the run |

**Not overclaimed, and worth retaining:** the threat model and test plan state explicitly that no test has run and that residual risk is conditional. The review report records "no test executed". The DBT-07 citation correction was applied.

## Recommendations

**Before G4 is relied on (Mandatory):** close F-RT-20, F-RT-23 and F-RT-26, and verify F-RT-24.

**Before G10:** F-RT-21, F-RT-22, F-RT-25 and F-RT-27.

**Correct the gate record** (G3, G5, G6) and the APIM/n8n wording now.

**No material issue found in:**
- ADR-001 solution shape
- ADR-004 retrieval technology choice (on AP-06 grounds)
- ADR-005 Container Apps, as conditioned
- F-BRD-07 typed reads
- Logging remediation (once APIM diagnostics are included)
- The evaluation-plan structure
- Lock-in, which stays low; APIM policy coupling is recorded with an exit cost

## Positions for the Board

- Some may call F-RT-20 an implementation detail. I hold it at **High**, because the whole AP-14 argument for the target rests on C-05 being independent of C-02. A sequence diagram showing user-token-backed confirmation validated by C-05 would close it.
- F-RT-24 is rated Critical only because the consequence would be Critical and verification is missing. A resource inventory showing APIM, n8n and the sinks in-region downgrades it to closed.

## Assumptions and Open Questions

- Q-IN-01: does an enterprise APIM exist, and where is it homed?
- Where is the existing n8n hosted?
- Does n8n retry on error by default in these flows?
- Does internal audit accept C-09 as the system of record?

## Not Verified

- The APIM, n8n and App Insights regions.
- n8n webhook authentication and ERP credential scope.
- The ADR-003, ADR-004 and ADR-006 vendor claims. I did not re-fetch them; research was not in scope.
- Every latency and availability figure above is `[JUDGMENT]` or `[ASSUMPTION]`.
- No test was executed.

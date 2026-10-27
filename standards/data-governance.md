# Data Governance

**Layer A: stable principles.** This file changes only by explicit framework decision (see `docs/extending-the-framework.md`). It governs data that AI systems ingest, retrieve, generate, store, remember, cache, or log. Core principles and evidence labels are in `standards/architecture-principles.md`; access control mechanics are in `standards/security-and-identity.md` (SEC); agent memory design is in `standards/agentic-ai-design-principles.md` (AG-14). Classification names below are generic; map them to the organization's own scheme at intake.

---

## 1. Principles

| ID | Principle | In practice | Typical violation |
|---|---|---|---|
| DG-01 | **Classification and handling by class** | Every data source, derived store, and log is classified at intake. Handling rules (§2) follow the highest class present. A mixed store takes the highest class of its content. | A vector index holding confidential and public documents treated as "internal". |
| DG-02 | **Ownership and stewardship** | Each source and derived store has a named data owner (accountable) and steward (operational quality, access requests). The AI team is rarely the owner of source data. | "We copied it into the index, so it's ours now." |
| DG-03 | **Residency and sovereignty** | Residency constraints cover storage *and* processing: where model inference runs, where embeddings are computed, and where prompts, logs, traces, and evaluation data are stored. Verify provider regions per deployment (verify current status). | Data stored in-region but sent to a model endpoint in another jurisdiction. |
| DG-04 | **Retention and deletion, including derived data** | Embeddings, chunks, caches, memories, summaries, fine-tuning sets, and evaluation datasets inherit the source's classification and deletion obligations. Deleting a source record triggers deletion or re-indexing of its derivatives within a defined time. | A customer's erasure request removes the CRM record but not its embeddings or cached answers. |
| DG-05 | **Access-aware retrieval, enforced at query time** | Retrieval is permission-trimmed for the requesting principal at query time, using the source's access controls (or a synchronized copy with a defined lag). Never rely on the prompt to hide results. | Retrieving everything, then telling the model "only use documents the user may see". |
| DG-06 | **Provenance and lineage** | Every chunk and generated artifact can be traced to its source document, version, and ingestion time. Answers cite sources where the use case needs grounding. | Unable to say which document version produced a wrong answer. |
| DG-07 | **Freshness SLAs for knowledge** | Each knowledge source has a freshness target (maximum lag from source change to retrievable), monitored and alerted. Stale or superseded content is removed or down-ranked. | Policy answers quoting a version withdrawn months ago. |
| DG-08 | **Data quality** | Define quality checks per source (completeness, duplication, parse quality, metadata coverage) at ingestion. Quality failures block ingestion or are flagged, not silently indexed. | Scanned PDFs with failed OCR indexed as empty chunks. |
| DG-09 | **PII handling and minimization in prompts and logs** | Minimize PII sent to models (SEC-07). Redact or tokenize where the model doesn't need the value. Logs and traces store PII only when justified, in an access-controlled store, with retention limits (OE-02, OE-11). | Full prompts with customer identifiers in a general-purpose log index. |
| DG-10 | **Consent and purpose limitation** | Data is used only for purposes compatible with its collection basis and consent. A new AI use of existing data is checked with the data owner and privacy function. | Using support transcripts collected for quality assurance to train a sales model without review. |
| DG-11 | **Training and fine-tuning data use; vendor terms** | Decide explicitly whether any enterprise data may be used for training or fine-tuning, internally or by vendors. Verify each vendor's contractual data-use, retention, and abuse-monitoring terms; these are time-sensitive (verify current status) and must be recorded with a date. | Assuming "enterprise tier" means no data retention, without reading the contract. |
| DG-12 | **Memory governance** | Define what may be remembered, scope, TTL, user visibility and erasure, and who can read memories (§4). | An assistant that silently retains health details mentioned in passing. |
| DG-13 | **Cache governance** | Caches of prompts, retrieval results, and responses are classified, scoped, and invalidated per §5. | A shared semantic cache returning one user's answer to another. |

## 2. Handling by class

| Class (generic) | Model endpoint | Retrieval / index | Logs and traces | Memory and caches | Vendor processing |
|---|---|---|---|---|---|
| Public | Any approved endpoint | Shared index acceptable | Full capture acceptable | Allowed | Allowed |
| Internal | Approved enterprise endpoints | Permission-trimmed | Capture with standard retention | Allowed, scoped | Under enterprise terms |
| Confidential | Approved endpoints with no-training terms, in permitted regions | Permission-trimmed, encrypted | Redacted by default; full capture only in a secure store | Scoped per user/case, TTL required | Only with verified contract terms |
| Restricted / regulated (incl. PII) | Endpoints approved for the regulation, region-locked | Permission-trimmed, segregated where required | Redacted; secure store with access approval and short retention | Only with explicit justification and erasure support | Only with a data processing agreement and residency confirmed |
| Highly regulated / special category | Dedicated or self-hosted where mandated | Segregated stores | Minimal metadata only, unless a regulation requires more | Normally prohibited | Normally prohibited unless explicitly approved |

## 3. Derived data inventory (DG-04, DG-06)

Every design lists its derived stores. Each row must have an owner and a deletion path.

| Derived artifact | Inherits from | Deletion trigger | Typical mechanism |
|---|---|---|---|
| Chunks and embeddings | Source documents | Source deletion or permission change | Source-ID keyed delete, or scheduled re-index with a maximum lag |
| Retrieval / response caches | Sources + user scope | Source change, TTL, user erasure | TTL plus event-driven invalidation (§5) |
| Agent memories | Conversation and tool data | TTL, user erasure, case closure | Scoped store with per-user delete |
| Summaries and generated documents | Their inputs | Per business record retention | Stored with lineage to inputs |
| Evaluation datasets | Sampled production or source data | Source erasure; dataset review cadence | Provenance record per case; de-identified where possible |
| Fine-tuning sets and tuned models | Training records | Source erasure obligations (may require retraining) | Recorded in the ADR before training starts |
| Prompt/response captures | Prompts and outputs | Short retention by class | Secure store with automatic expiry |

## 4. Memory governance (DG-12)

- **What may be remembered.** An explicit allowlist of memory types (for example, user preferences, case facts). Credentials, special-category data, and raw untrusted content are excluded unless explicitly approved.
- **Scope.** Per user, per case, or per tenant. No cross-user memory without a documented purpose and access model.
- **Write validation.** Memory writes come from validated, structured outputs, not free-form model text, so injected instructions can't persist (AG-14, SEC-09).
- **TTL.** Every memory type has a time-to-live and a review rule.
- **User visibility and erasure.** Users can see what is remembered about them and delete it, where the use case or regulation requires. Erasure covers backups and derived copies within a defined time.
- **Access.** Memories are readable only by the scoped principal's sessions and by authorized support roles, with audit.

## 5. Cache governance (DG-13)

- **Classify** each cache at the highest class of what it can contain.
- **Key by scope.** Include the principal's or tenant's authorization context in the cache key, or restrict caching to content whose access is identical for all users. A semantic cache must never serve across permission boundaries.
- **Invalidate** on source change, permission change, model or prompt version change (AG-17), and TTL expiry.
- **Exclude** responses containing restricted data from shared caches.
- **Measure** hit rate and staleness, and confirm a cache doesn't break freshness SLAs (DG-07).

## 6. Vendor data-use checklist (DG-11)

Record answers with a source and an access date; they change over time (verify current status).

- [ ] Is customer data used for model training or improvement by default? Can it be disabled contractually?
- [ ] How long are prompts and outputs retained, and for what purpose (for example, abuse monitoring)? Is zero or reduced retention available, and does it apply to this deployment?
- [ ] In which regions does inference run, and where are logs stored?
- [ ] Which sub-processors are involved?
- [ ] What deletion guarantees apply to uploaded files, fine-tuning data, and tuned models?
- [ ] Do the terms differ across the vendor's own products, regions, or API features used?

## 7. Knowledge source onboarding checklist

Complete for each source before it is ingested into retrieval, memory, or evaluation datasets.

- [ ] Classification and handling class recorded (DG-01, §2)
- [ ] Data owner and steward named, and their approval recorded for this AI use (DG-02, DG-10)
- [ ] Residency of storage, embedding computation, and inference confirmed (DG-03)
- [ ] Access model identified, and how permissions are enforced at query time, with the sync lag (DG-05)
- [ ] Deletion path for every derived artifact in §3 (DG-04)
- [ ] Source ID, version, and ingestion time stored with each chunk (DG-06)
- [ ] Freshness target and monitoring defined (DG-07)
- [ ] Quality checks defined, with the action on failure (DG-08)
- [ ] PII fields identified, with a minimization or redaction decision (DG-09)
- [ ] Content treated as untrusted input for prompt-injection purposes (`security-and-identity.md` SEC-09)

## 8. Anti-patterns

- **Index everything:** bulk-ingesting a file share without classification, ownership, or permission mapping.
- **Prompt-level access control:** relying on instructions to hide documents the user can't see.
- **Orphaned derivatives:** embeddings, caches, and eval sets that survive deletion of their sources.
- **Region by assumption:** assuming the model endpoint runs where the data is stored.
- **Terms by assumption:** relying on remembered vendor data-use terms rather than the current contract.
- **Permanent memory by default:** persistent memory enabled with no TTL, visibility, or erasure.

## 9. Tier scaling

| Concern | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Classification (DG-01) | Sources classified | + derived stores classified | + per-field PII mapping | + data protection impact assessment as required |
| Ownership (DG-02) | Owner named | Owner + steward | + access approval workflow | + independent oversight |
| Residency (DG-03) | Noted | Inference + storage regions confirmed | + logs/traces/eval data regions confirmed | + contractual and technical enforcement verified |
| Deletion (DG-04) | Source deletion | + derived inventory (§3) | + tested deletion propagation | + audited deletion with evidence |
| Retrieval (DG-05) | Public/internal only | Permission-trimmed | + permission-sync lag measured, cross-user tests | + cross-tenant tests every release |
| Freshness / quality (DG-07, DG-08) | Best effort | Targets defined | Monitored and alerted | + quality gates block ingestion |
| PII (DG-09) | Avoid | Redaction in logs | + minimization in prompts, secure capture store | + tokenization, strict access approval |
| Vendor terms (DG-11) | Standard terms noted | Terms verified, dated | + legal review | + contractual guarantees and audit rights |
| Memory / cache (DG-12, DG-13) | Avoid or session-only | Scoped, TTL | + user visibility and erasure | + approval for any persistent memory |

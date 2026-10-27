# Model Selection Guide

- **Last verified:** 2026-10-27
- **Confidence:** High for the method (it is `[JUDGMENT]` grounded in `standards/`, not time-sensitive). Low for any named model family, which is an example only and changes monthly.
- **Layer:** B. This guide deliberately contains **no "best model" list**. A model is "best" only against a specific requirement set and eval set.

## 1. Principle: requirements first, not leaderboards

Public leaderboards measure someone else's tasks, prompts, and scoring. They are useful for building a **shortlist**, never for a **decision** (`standards/architecture-principles.md` §3: leaderboard rank is never sufficient on its own). The decision comes from:

1. The use case's FRs/NFRs and constraints (residency, hosting, license, cost ceiling).
2. A representative evaluation set drawn from the business data, scored against agreed thresholds.
3. Operational fit: availability in the mandated platform/region, quotas, lifecycle, support.

Often the right answer is **not an LLM at all** (rules, search, classic ML at rungs 1–3), or **the smallest model** that clears the threshold.

## 2. Selection criteria

| Criterion | What to establish | How to measure | Typical trap |
|---|---|---|---|
| Task quality | Accuracy/faithfulness on *your* task | Eval set with task metrics (exact match, F1, rubric scores, groundedness) | Judging by a demo prompt |
| Tool calling / structured output | Valid schema rate, correct tool and arguments, no hallucinated tools | Schema-validity %, tool-selection accuracy on scripted scenarios | Assuming "supports function calling" = reliable |
| Reasoning | Multi-step correctness where needed; cost of reasoning tokens | Hard subset of eval set; latency/cost per case | Paying for reasoning on extraction tasks |
| Context window and behavior | Advertised limit vs *effective* use of long context (recall in the middle, degradation) | Needle/long-document tests on your documents | Stuffing context instead of retrieving |
| Latency / throughput | Time-to-first-token, tokens/s, p95 end-to-end at expected concurrency | Load test against the real endpoint and region | Measuring from a laptop, single request |
| Consistency | Output variance across runs and across model versions | Repeat runs (n≥5) on a subset; diff across versions | Single-run evals |
| Multilingual | Quality per required language and script (e.g. Arabic, including dialect vs MSA and RTL handling where relevant); code-switching | Per-language eval slices with native-speaker review | English-only eval for a multilingual service |
| Residency / privacy | Where inference runs and where prompts/outputs/logs are stored; retention; training use | Contract and service docs; region availability; abuse-monitoring/logging settings | Model deployed "globally" when residency is mandated |
| Hosting options | Managed in mandated cloud? Private endpoint? Self-hostable weights? | Platform catalog per region on the decision date | Assuming feature parity across regions |
| Security / governance | Content filtering, prompt-injection resistance, audit logs, RBAC | Red-team cases in the eval set; platform controls review | Treating vendor safety filters as authorization |
| Availability / support | SLA, quota, capacity reservations, support channel | Contract; quota request outcome | Prototype quota ≠ production quota |
| Cost / rate limits | Cost per business transaction at expected volume (input, output, cached, reasoning tokens) | Cost model from eval runs × volume forecast | Comparing price per million tokens only |
| Licensing / usage restrictions | Acceptable-use policy; open-weight license terms (commercial use, user thresholds, field-of-use, output restrictions) | Legal review of the specific model version's license | "Open weights" read as "open source" |
| Fine-tuning needs | Is prompt + retrieval insufficient? Data available? Who owns the tuned artifact? | Eval of best prompt+RAG baseline before any tuning | Fine-tuning to fix a retrieval problem |
| Eval results on representative data | The deciding evidence | §3 procedure | Skipping it |

## 3. Evaluation procedure

1. **Frame the task.** For each AI step, write the input, the output contract (schema), the quality metric, the threshold, and the business cost of each error type. Trace to FR/NFR IDs.
2. **Apply hard filters first.** Eliminate candidates failing a constraint: not available in the mandated platform/region, license incompatible, no private connectivity, residency mismatch, prohibited vendor (`PRH-`). Record eliminations.
3. **Build the eval set.** Sample representative business data (de-identified per policy), covering normal cases, edge cases, adversarial cases (prompt injection in documents, out-of-scope requests), and each language/channel. State provenance, size rationale, and refresh cadence (G8). Hold out a test split that prompt engineering never sees.
4. **Establish a baseline.** Run the simplest viable approach (rules, search, smallest model) so the LLM's added value is measured, not assumed.
5. **Shortlist 2–4 candidates** spanning size/cost tiers. Use public benchmarks only here.
6. **Optimize fairly.** Give each candidate reasonable prompt adaptation (models differ in prompt sensitivity), the same retrieval, the same tools.
7. **Run and score.** Multiple runs per case for variance. Programmatic scoring wherever possible; LLM-as-judge only after calibrating it against human labels on a sample; human review for high-stakes slices.
8. **Measure operations.** Latency and throughput under load in the target region; error/throttle rates; cost per transaction.
9. **Decide and record.** Choose the cheapest candidate that clears all thresholds with margin. Record it in an ADR with eval results, pinned model version, residual risks, and revisit triggers (new version, deprecation notice, price change, quality drift).
10. **Monitor.** Online sampling against the same metrics; re-run the offline set on every model, prompt, or retrieval change.

### Eval harness outline

```text
eval/
  datasets/<task>/<version>/{train-dev.jsonl, test.jsonl, README.md}   # provenance, sampling, PII handling
  tasks/<task>.yaml        # input template, output schema, metrics, thresholds, error-cost weights
  candidates.yaml          # model id + pinned version, endpoint, params, prompt variant
  scorers/                 # programmatic scorers; calibrated judge prompts + calibration report
  run.py                   # runs candidates × cases × n repeats; captures output, tokens, latency, errors
  report/                  # per-slice metrics, variance, cost/transaction, failures with examples
  ci/                      # regression gate: fail build if metric < threshold or regresses > delta
```

Per case, record: case ID, slice tags (language, difficulty, adversarial), model + version, prompt version, retrieval snapshot ID, raw output, parsed output, schema-valid flag, scores, tokens (in/out/cached/reasoning), latency, and cost. This record makes results reproducible and auditable.

## 4. Prototype vs production suitability

| Aspect | Prototype acceptable | Production requires |
|---|---|---|
| Model access | Public API, shared quota, preview models | Contracted, region-pinned deployment; production quota confirmed; GA model status (or ADR-accepted preview risk) |
| Version | "Latest" alias | Pinned version; upgrade via eval gate |
| Data | Synthetic or approved sample | Data-handling terms reviewed; logging/retention configured |
| Evaluation | Spot checks | Versioned eval set, thresholds, CI gate, online monitoring |
| Connectivity | Public endpoint | Private connectivity where required (`deployment-patterns.md` §9) |
| Fallback | None | Defined degradation behavior (§6) |

Prototype results do not transfer automatically. Re-run evals on the production deployment (region, version, quota tier), since latency and even behavior can differ `[JUDGMENT]`.

## 5. Example model families (illustrative only)

As of 2026-10-27, enterprise shortlists commonly draw from: OpenAI GPT and reasoning models, Anthropic Claude, Google Gemini, Mistral, Cohere (managed); and Llama, Qwen, Mistral, Gemma, DeepSeek, Phi families (open-weight). Microsoft Foundry's catalog, for example, listed GPT-5.6-series and Claude models among summer 2026 additions `[VENDOR]` (source: https://devblogs.microsoft.com/foundry/whats-new-in-microsoft-foundry-july-august-2026/, accessed 2026-10-27). **This is not a ranking or recommendation**, and specific model names will be stale within months. Check the platform catalog on the decision date.

## 6. Routing and fallback: only with clear benefit

Multi-model designs are justified when **measured** benefit exceeds the operational cost:

- **Cost routing:** a small model handles ≥ a meaningful share of traffic at threshold quality, with a reliable, cheap router (rules or classifier) and an escalation path. Prove the share and the router accuracy on the eval set.
- **Availability fallback:** the SLO exceeds a single deployment's availability. Prefer **same model, another region/deployment** first, because it avoids prompt and behavior differences. A different-model fallback must pass the same eval set and produce the same output schema.
- **Capability routing:** distinct tasks genuinely need different models (e.g. embeddings vs generation vs vision).

**Operational cost of multi-model** (record in the ADR): N× eval runs and prompt variants; N× deprecation tracking; inconsistent behavior across failover; harder incident diagnosis; more vendor contracts and residency reviews; router as a new failure point. If one model meets quality, cost, and availability targets, use one model.

## 7. Managed vs self-hosted

Self-hosting is **not automatically superior** for security, privacy, or cost. It moves responsibility to you.

| Factor | Favors managed | Favors self-hosted |
|---|---|---|
| Quality gap | Required quality only achieved by proprietary frontier models | An open-weight model clears thresholds on your eval set |
| Residency / sovereignty | Managed offering available in the required region with acceptable terms and private connectivity | No compliant managed region; air-gapped or sovereign mandate |
| Volume and utilization | Spiky or low volume (pay per token) | Sustained high volume keeping GPUs well utilized (model it; idle GPUs dominate cost) |
| GPU capacity | No reliable access to suitable accelerators | Reserved capacity available for model size × replicas × HA |
| Ops capability | No team for GPU drivers, serving engines, scaling, patching, model security | Platform team experienced with Kubernetes GPU workloads and serving engines (e.g. vLLM) |
| Licensing | Vendor terms acceptable | Open-weight license permits your use; legal reviewed |
| Customization | Prompting, RAG, vendor fine-tuning suffice | Deep fine-tuning, custom decoding, or weight-level control required |
| Latency | Managed region is close and quotas suffice | Inference must be co-located with on-prem data/apps |

Total cost of self-hosting includes: accelerators (with HA headroom), serving engine operations, model artifact management, evaluation on every model update, security patching of the serving stack, gateway/auth in front of the server (OpenAI-compatible servers often have minimal built-in auth), and on-call `[JUDGMENT]`.

## 8. Model lifecycle

- **Pin versions.** Configure explicit model versions, not floating aliases, in production. Record the pinned version in the ADR and in each trace.
- **Track deprecations.** Managed providers retire model versions on published schedules. Subscribe to retirement notices; keep a register of every deployed model/version, owner, retirement date, and replacement candidate.
- **Upgrade via the eval gate.** A new version is a new candidate: run the full offline eval, compare against the pinned version, and roll out progressively (shadow → canary → full) with a rollback path.
- **Re-embed deliberately.** Changing an embedding model invalidates the vector index. Plan dual indexes or a re-indexing window.
- **Open-weight artifacts** are versioned in a model registry with hash, license, source, and eval results. Scan artifacts as supply-chain inputs (OWASP LLM03 Supply Chain, 2025 edition `[VERIFIED]`, source: https://genai.owasp.org/llm-top-10/, accessed 2026-10-27).
- **Revisit triggers:** deprecation notice; price change > agreed threshold; quality drift in online monitoring; new residency option; new requirement (language, modality).

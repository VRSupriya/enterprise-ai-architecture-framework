---
name: threat-modeling
description: Build an AI- and agent-aware threat model. Applies STRIDE to each flow that crosses a trust boundary, plus AI-specific categories such as prompt injection, tool misuse, excessive agency, memory poisoning, supply chain, and denial of wallet. Every threat gets a mitigation, an owner, a TST- test, and a residual risk. Use for "threat model", "security review of the agent", "prompt injection risk", "what can go wrong", "trust boundaries", or the G4 gate.
argument-hint: "<use-case-id> [component or flow to scope to]"
---

# Threat Modeling

## Purpose

Produce `05-validation/threat-model.md`, an evidence-backed threat model for a design or existing system. It identifies assets, trust boundaries, and data flows. It enumerates threats per boundary-crossing flow, assigns each threat a deterministic-first mitigation, an owner, a verification test, and a residual risk, and gives the material for gate G4. This skill applies `standards/security-and-identity.md` and `standards/agentic-ai-design-principles.md`. It does not restate them.

## When to use / not use

| Use when | Don't use when |
|---|---|
| A T2+ design reaches Phase C/G, or a Mode B review needs a security baseline | The question is a single control choice. Use `technology-evaluation` or brief `security-identity-architect` directly. |
| Any tool execution, delegated access, retrieval of untrusted content, memory, or external exposure is added | No design or system description exists yet. Run `architecture-design` or `use-case-discovery` first. |
| A revisit trigger fires: a new tool, a new data source, a new model or provider, a new user population, a material incident | You want penetration test results. This skill plans verification; it doesn't produce test evidence. |
| The user asks "what can go wrong" or for an independent security challenge | |

## Inputs

| Input | Path | Required |
|---|---|---|
| Intake (mode, tier, CON/PRH, data classification) | `00-intake/use-case-brief.md` | Yes |
| Requirements (FR, NFR, security NFRs) | `01-requirements/requirements.md` | Yes |
| Design or baseline: component catalogue, identities, tools, data stores | `02-design/solution-design.md` or `03-review-board/review-report.md` | Yes |
| Diagrams | `02-design/diagrams/*.md` or embedded | If present |
| ADRs on identity, tools, models, hosting | `04-decisions/adr/` | If present |
| Existing review findings (`F-SE-`, `F-RT-`) | `03-review-board/round-*/` | If present |
| Threat catalog | [references/ai-threat-catalog.md](references/ai-threat-catalog.md) | Always |

If the component catalogue is missing identities, tool permissions, or data classifications, record each gap as an `ASM-` and rate any threat that depends on it as **at least Medium likelihood** until the gap is closed.

## Workflow

### Step 1. Scope and set depth by tier

| Tier | Depth | Specialists |
|---|---|---|
| T1 | Lightweight: assets, one trust-boundary diagram, a checklist pass over the catalog categories, and threats only where a category applies. ◐ G4. | None. The coordinator applies the checklist. |
| T2 | Full STRIDE per boundary-crossing flow plus all applicable AI categories. | Brief `security-identity-architect`. |
| T3 | T2 plus abuse cases per tool, delegated-access analysis, supply-chain inventory, and an independent adversarial pass. | `security-identity-architect` and `red-team-architect`, independently. Add `data-knowledge-memory-architect` if RAG or memory is in scope. |
| T4 | T3 plus multi-agent and long-running autonomy threats, per-action separation-of-duties analysis, and a red-team second pass on the remediated design. | As T3, plus `agentic-systems-architect` for the agent control loop. |

Copy `templates/threat-model.md` to `use-cases/<id>/05-validation/threat-model.md`. Keep the required headings: **Scope and Assets · Trust Boundaries · Threats · Residual Risk**. Remove the `<!-- TEMPLATE -->` marker only once every section is filled in.

### Step 2. Inventory assets

List what an attacker wants or could damage. For each asset, give the classification (from the intake), the owner, and the CIA priority.

- Data: user inputs, retrieved corpora, embeddings and indexes, conversation and long-term memory, logs and traces (these often hold prompts and outputs), evaluation datasets.
- Secrets and identities: API keys, workload identities, OAuth tokens, delegated user tokens, signing keys.
- AI artifacts: system prompts, prompt templates, tool schemas, model weights or endpoints, fine-tuning data, guardrail policies.
- Capabilities: every tool and the side effect it can cause (write, send, pay, delete, deploy). Capabilities are assets, because misuse of them is the impact.
- Budget: token spend, rate-limit quota, compute.

### Step 3. Draw trust boundaries and data flows

1. Identify the zones and label each `TB-1`, `TB-2`, and so on, as the template does: user/client, edge/gateway, application/orchestration, model provider, retrieval and data stores, tool and enterprise systems, external/internet, operator/admin, CI/CD and supply chain.
2. Number each flow that crosses a boundary as `DF-01`, `DF-02`, and so on. For each, record the source and destination components (`C-` IDs), protocol, authenticating identity (user, workload, agent, or delegated user), data classification, and whether the content is **trusted, semi-trusted, or untrusted**. Treat retrieved documents, email, web pages, file uploads, tool output, and memory as **untrusted**, even when they come from internal systems.
3. Produce the trust-boundary diagram with the `architecture-diagrams` skill (trust boundary type). Embed it under **Trust Boundaries**. Every `DF-` in the table must appear as an edge, and every component as a node.

### Step 4. Identify threat actors and attack surfaces

Name the actors that apply: anonymous external user, authenticated malicious user, malicious content author (someone who can plant text the system will retrieve), compromised insider or operator, compromised dependency or supplier, compromised tool or MCP server, and a misaligned or erroneous agent (no malice required). Map each actor to the entry points it can reach.

### Step 5. Enumerate threats per flow

For **each** `DF-` crossing a boundary, apply STRIDE (Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege). Then apply the AI and agentic categories from the catalog:

| Category (catalog §) | Must examine |
|---|---|
| Prompt injection | Direct injection; indirect injection via retrieved docs, email, web, files, and **tool output** |
| Untrusted output handling | Model output used in SQL, shell, HTML, tool arguments, or downstream automation |
| Sensitive data disclosure | Cross-tenant or cross-user retrieval, prompt or system-prompt leakage, PII in logs and traces, training-data exposure |
| Credential exposure | Secrets in prompts, context, tool responses, or logs; tokens the model can read |
| Identity, authn, authz | Missing user context at tools, authorization decided by the model, confused deputy, over-broad delegated scopes |
| Agency and tools | Excessive agency, tool misuse, unauthorized side effects, unbounded loops, missing approval or separation of duties |
| Memory and state | Memory poisoning, cross-session leakage, state tampering |
| Supply chain | Models, packages, MCP servers, prompts, datasets, guardrail rules, and container images |
| Resource abuse | Denial of wallet, token amplification, recursive tool calls, quota exhaustion |
| Multi-agent (T4) | Inter-agent trust, message spoofing, privilege laundering between agents |

Instantiate catalog entries (`AIT-xx`) where the preconditions hold. Don't copy entries whose preconditions are absent. Write each threat as `T-NNN` with: the flow (`DF-`), the affected component (`C-`), the STRIDE and/or AI category, the catalog reference, the actor, and a concrete scenario specific to this design.

**Reference frameworks.** Map categories to established frameworks by name: the OWASP Top 10 for LLM Applications, OWASP guidance on agentic AI threats and mitigations, MITRE ATLAS, and the NIST AI RMF (and its generative AI profile). These evolve. **Before citing any of them, verify the current version or edition through research and record `(source: <URL>, accessed YYYY-MM-DD)`.** Cite a specific item number only if you verified it in that edition. Otherwise describe the category in words.

### Step 6. Rate without false precision

Use qualitative ratings, each with a one-line rationale:

| Likelihood | Meaning |
|---|---|
| High | Reachable by a realistic actor with public techniques; no effective control is in place yet |
| Medium | Needs a specific precondition (insider access, planted content, a chained flaw) or a partial control exists |
| Low | Needs unusual capability or several independent controls to fail |

| Impact | Meaning |
|---|---|
| Critical | Consequential action without authorization, regulated-data breach, safety harm, or loss of control of the system |
| High | Material data exposure, financial loss, or integrity loss in a business system |
| Medium | Limited exposure, recoverable integrity issue, or service degradation |
| Low | Nuisance or cosmetic issue, with no data or action impact |

Risk = the higher of the two when either is Critical; otherwise use a plain 3×4 lookup (High×High = High, and so on). Don't multiply into scores like "6.25". Don't claim probabilities you can't support. Mark ratings that depend on an unverified fact as `[ASSUMPTION]` and link the `ASM-`.

### Step 7. Assign mitigations, owners, and tests

For every threat:

1. **Mitigation, deterministic first.** Prefer controls the model can't talk its way past: authorization in the tool or API layer (AP-14), allow-listed tools and arguments, schema validation, egress restrictions, scoped short-lived credentials, rate and budget limits, human approval for consequential actions, and separation of duties. Use probabilistic controls (classifiers, guardrail models, prompt instructions) only as **additional** layers, and say so.
2. **Owner.** A role (for example, "platform security lead"), not a person's name unless the user supplied one.
3. **Verification.** One or more `TST-` IDs, with the test idea from the catalog, adapted. Register them in `05-validation/test-and-evaluation-plan.md` §Adversarial Testing (T3+), or list them in the threat model for T2.
4. **Status.** Designed · Implemented · Verified (with evidence path) · Accepted. Never mark a threat Verified without an observed test result (gate blocking rule).
5. **Residual risk** after mitigation, with the same qualitative scale and a reason.

### Step 8. Human approval and separation of duties

For each side-effecting tool, record: the action, the reversibility, the blast radius, the approval requirement (none, user confirm, or independent approver), who can approve, how the approval is bound to the exact action parameters (so an approval can't be replayed or altered), and the timeout behavior. The approver must not be the agent's own principal for actions that need separation of duties. Missing approval for a consequential action at T3+ is a High threat by default.

### Step 9. Specialist review (T2+)

- Brief `security-identity-architect` with paths to the draft threat model, the design, and the CON/PRH list. Ask it to: challenge identity and delegated-access semantics, find missing flows, and rate mitigation adequacy.
- T3+: brief `red-team-architect` **independently and in parallel**, without the security specialist's conclusions. Give it the design and the asset list, but **not** your threat list, so its attack paths are independent. Then diff its attack paths against your `T-` list and add the missing ones.
- Follow the briefing rules in `docs/operating-model.md` §4. Save the reports verbatim under `03-review-board/round-<n>/`.

### Step 10. Residual risk and acceptance

Summarize under **Residual Risk**: every threat with residual risk of High or above, plus any Medium that depends on an assumption. Each needs a named risk acceptor (a role from the intake decision owners), the condition for acceptance, and a revisit trigger. Raise an `RSK-` in the requirements for each one. An unaccepted High or Critical residual risk means G4 is FAIL or PASS-WITH-CONDITIONS, never PASS.

### Step 11. Validate

Run `tools/validate-diagrams.sh use-cases/<id>/05-validation/threat-model.md`. Then check by hand that every `DF-` has threats or an explicit "no material threat because …" line, and that every `T-` has a mitigation, an owner, a `TST-`, and a residual risk.

## Outputs

| Artifact | Path |
|---|---|
| Threat model | `use-cases/<id>/05-validation/threat-model.md` (from `templates/threat-model.md`) |
| Trust-boundary diagram | Embedded in the threat model under **Trust Boundaries** |
| Test registrations (T3+) | `use-cases/<id>/05-validation/test-and-evaluation-plan.md` §Adversarial Testing |
| New risks and assumptions | `use-cases/<id>/01-requirements/requirements.md` (`RSK-`, `ASM-`) |
| Specialist reports | `use-cases/<id>/03-review-board/round-<n>/security-identity-architect.md`, `red-team-architect.md` |

Use the template's threat table. At T2+, extend it with `Component (C-)`, `Catalog ref (AIT-)`, `Actor`, and `Status` columns, and split Mitigation into deterministic and probabilistic layers. Complete the template's **AI-specific checklist**: tick each line with its `T-` IDs, or mark it "N/A because …".

## Quality gates touched

- **G4 Security & threat modeling.** Primary evidence.
- **G6 Independent challenge.** Red-team input (T3+).
- **G7 Consistency.** The trust-boundary diagram agrees with the component catalogue.
- **G8 Test & evaluation readiness.** `TST-` adversarial cases.

## Failure conditions

Stop, or report the gate as FAIL, when:

- Authorization for any consequential action depends on model reasoning or prompt instructions (blocking rule).
- A path that ingests untrusted content has no injection control listed.
- Any credential is reachable from model context.
- A threat lacks a mitigation, an owner, a test, or a residual risk.
- A threat is marked Verified without observed test evidence.
- High or Critical residual risk has no named acceptor.
- The diagram and the flow table disagree.
- A framework item number is cited without verifying the current edition.

## References

- [references/ai-threat-catalog.md](references/ai-threat-catalog.md): reusable AI and agentic threat catalog
- `standards/security-and-identity.md`, `standards/agentic-ai-design-principles.md`, `standards/data-governance.md`
- `standards/architecture-principles.md` (AP-14, §3 evidence labels), `standards/architecture-quality-gates.md` (G4 checklist)
- `templates/threat-model.md`, `templates/test-and-evaluation-plan.md`
- `.claude/skills/architecture-diagrams/SKILL.md` (trust-boundary pattern)
- `.claude/agents/security-identity-architect.md`, `.claude/agents/red-team-architect.md`
- `docs/operating-model.md` §4–§5 (briefing, persistence), `docs/conventions.md` §2–§3

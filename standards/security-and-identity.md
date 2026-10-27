# Security and Identity

**Layer A: stable principles.** This file changes only by explicit framework decision (see `docs/extending-the-framework.md`). It defines the security and identity principles that gate G4 (`standards/architecture-quality-gates.md` §3) checks against. Core principles, input classes, and evidence labels are in `standards/architecture-principles.md`; agent-specific design rules are in `standards/agentic-ai-design-principles.md` (AG). Data handling is in `standards/data-governance.md` (DG).

---

## 1. Principles

| ID | Principle | In practice | Typical violation |
|---|---|---|---|
| SEC-01 | **Least privilege** | Every identity (user, workload, agent, tool) gets the minimum scopes for its function, per environment. Write and admin rights are separate grants. Permissions are reviewed when tools change. | An agent service account with tenant-wide contributor rights "to avoid permission errors". |
| SEC-02 | **Explicit authentication and authorization** | Every hop authenticates (no implicit trust inside the network). Every resource access is authorized against an explicit policy at the resource or a policy enforcement point. | Internal tool APIs reachable without authentication because "only the agent calls them". |
| SEC-03 | **Separate user, workload, agent, and tool identities** | Users, application workloads, each agent (per version and environment), and each tool integration have distinct identities, so actions are attributable and revocable independently (AG-15). | All components share one API key. |
| SEC-04 | **The LLM is never a security enforcement mechanism** | System prompts, guardrail instructions, and model refusals are *defense in depth*, never the control. Every security property must hold even if the model is fully manipulated. | "The model is instructed not to reveal other customers' data." |
| SEC-05 | **Secrets management** | No secrets in prompts, model context, tool outputs, logs, traces, or source. Prefer workload identity federation and managed identities over static keys; use short-lived, scoped credentials fetched by the tool layer, never by the model. Rotate and audit. | An API key pasted into a system prompt so the agent can "call the API itself". |
| SEC-06 | **Explicit delegated-access semantics** | Each tool call declares whether it runs on-behalf-of (OBO) the user or app-only, and why (§3). Tokens are downscoped per tool. The effective permission is the intersection of user and agent permissions where the action is user-initiated. Confused-deputy paths are designed out. | An agent using its own broad app permissions to fetch documents the requesting user can't see. |
| SEC-07 | **Data minimization** | Send the model, tools, logs, and vendors only the data the task needs (DG-09). Redact or tokenize identifiers that the model doesn't need to reason about. | Whole customer records in the context to answer a delivery-date question. |
| SEC-08 | **Auditability of consequential operations** | Each consequential action records: who (user), on behalf of whom, what (tool, parameters, target), which agent and version, which policy decision, which approval (approver, time), and the outcome. Audit logs are tamper-evident and access-controlled. | Logs that show "agent updated record" with no user, version, or approval. |
| SEC-09 | **Layered defenses against prompt injection and tool abuse** | No single mitigation is sufficient. Combine input isolation, privilege separation, output validation, egress control, and human approval (§4). Design assuming injection will sometimes succeed, and limit the blast radius. | Relying on one "prompt-injection classifier" as the only defense. |
| SEC-10 | **Separate policy decisions from model reasoning** | Authorization and business policy live in a policy decision point (PDP); tools and gateways act as policy enforcement points (PEP). The model's output is an input to the PDP, never its decision. | The agent decides whether a request is "allowed" and the tool trusts that judgment. |
| SEC-11 | **Human approval by risk** | Consequential actions require approval per the matrix in `agentic-ai-design-principles.md` §4. Approval is bound to exact parameters and recorded per SEC-08. | Blanket "auto-approve" enabled to speed up a pilot, then never removed. |
| SEC-12 | **Supply chain integrity** | Record model provenance (source, version, license, hash for self-hosted weights). Pin packages and produce an SBOM. Vet MCP servers and third-party tools before use (publisher, permissions requested, update policy, data flows). Sign and verify deployable artifacts. | Installing a community MCP server with filesystem and network access straight into production. |
| SEC-13 | **Network egress control** | Agents and tools reach only allowlisted destinations. Model calls go through a known gateway or endpoint. Data exfiltration channels (arbitrary URLs, image rendering, webhooks) are closed or monitored. | An agent with an unrestricted HTTP fetch tool and access to confidential data. |
| SEC-14 | **Tenant isolation** | Tenant boundaries are enforced in identity, data stores, indexes, caches, memories, and logs, not by a tenant ID in a prompt. Cross-tenant tests are part of release. | A shared vector index filtered only by a metadata field the model chooses. |

## 2. Identity-flow reference

| Flow | Caller identity | Credential type | Authorization point | Typical use | Key control |
|---|---|---|---|---|---|
| User → application | End user | Interactive sign-in via enterprise IdP (e.g. OIDC) | Application + API gateway | Any user-facing AI app | MFA and conditional access per tier |
| Application → model endpoint | Application workload | Workload identity / managed identity | Model gateway | All model calls | No user tokens sent to the model provider |
| Agent → tool (on behalf of user) | Agent identity + user identity | Downscoped OBO / exchanged token (e.g. OAuth 2.0 Token Exchange, RFC 8693) | Tool PEP + PDP | User-initiated reads/writes | Effective permission = user ∩ agent |
| Agent → tool (app-only) | Agent identity | Short-lived workload credential | Tool PEP + PDP | Background jobs with no user context | Narrow scopes; justified in an ADR |
| Tool → downstream system | Tool integration identity | Short-lived credential from a secrets manager or federation | Downstream system | System-of-record access | Model never sees the credential |
| Agent → agent | Calling agent identity (+ propagated user context) | Workload credential + signed context | Receiving agent's PEP | Rung 7 handoffs | No permission amplification across hops |
| Agent → MCP server | Agent or user identity per server's model | Per the MCP authorization model (verify current status) | MCP server + downstream PEP | Tool access via MCP | Server vetted (SEC-12); scopes declared |
| Human approver → approval service | Approver | Interactive sign-in | Approval service | Consequential actions | Approver ≠ requester for dual control |

## 3. Delegated access semantics (SEC-06)

- **Choose OBO by default for user-initiated actions.** The tool call carries the user's identity so the downstream system enforces the user's rights. Use app-only only where no user exists, and record why.
- **Downscope per tool.** Exchange the user's token for a token limited to the specific tool's audience and scopes. Never forward a broad session token.
- **Intersection rule.** For user-initiated work, the agent may do only what *both* the user and the agent are permitted to do. The agent's allowlist limits the user; the user's rights limit the agent.
- **Confused-deputy prevention.** A component with broad rights must never act on a request it can't attribute to an authorized principal. Check the requesting principal at the PEP, not the agent's own rights. Watch for: shared caches, shared indexes, background jobs triggered by user content, and agent-to-agent calls.
- **No amplification across hops.** In multi-agent or tool chains, propagate the original user context; each hop gets equal or fewer permissions.
- **Revocation.** Revoking a user's access, or suspending an agent version, takes effect on the next call (short token lifetimes, no long-lived cached grants).

## 4. Layered prompt-injection and tool-abuse defense (SEC-09)

| Layer | Control | Purpose |
|---|---|---|
| Input isolation | Mark untrusted content (spotlighting, delimiting, separate message roles), and strip or neutralize active content | Reduce the chance the model treats data as instructions |
| Privilege separation | Agents that read untrusted content get no consequential tools, or hand off structured, validated data to a privileged step | Limit blast radius when injection succeeds |
| Deterministic policy | PDP checks every tool call (SEC-10); tool schemas reject out-of-range parameters (AG-07) | Make manipulation insufficient to cause harm |
| Output validation | Validate model outputs and tool arguments against schemas and allowlists; scan for sensitive data before display or send | Catch manipulated or leaking outputs |
| Egress control | Destination allowlists; block markdown image/link exfiltration where not needed (SEC-13) | Close exfiltration channels |
| Human approval | Required for consequential actions per risk (SEC-11) | Final control on high-impact paths |
| Detection | Injection classifiers, anomaly alerts on tool-use patterns (OE-09) | Detect and respond; never the sole control |

Assume each layer can fail. A design passes G4 only if the consequential paths stay safe with the input-isolation and detection layers removed.

## 5. Minimum controls by tier

| Control | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Authentication | Enterprise SSO | SSO + conditional access | + MFA, workload identity everywhere | + phishing-resistant MFA for approvers and admins |
| Identity separation (SEC-03) | App vs user | + agent identity | + per-tool identities | + per-version agent identities |
| Delegated access (SEC-06) | Read-only, OBO | OBO, documented | OBO + downscoping + intersection | + continuous revocation tests |
| Authorization (SEC-10) | Application checks | PEP at tools | PDP + PEP for all tool calls | + per-call policy with dual control |
| Secrets (SEC-05) | Secrets manager | + no static keys where federation exists | + short-lived only, rotation audited | + hardware-backed keys where required |
| Injection defense (SEC-09) | Input isolation | + output validation | All layers in §4 | All layers + independent red team |
| Audit (SEC-08) | Access logs | Consequential-action log | Full SEC-08 record, tamper-evident | + independent review, retention per regulation |
| Supply chain (SEC-12) | Pinned dependencies | + SBOM, vetted tools/MCP servers | + signed artifacts, model provenance | + provenance verification at deploy |
| Egress (SEC-13) | Known endpoints | Allowlist for tools | Enforced allowlist, monitored | + deny-by-default, data-loss prevention |
| Tenant isolation (SEC-14) | N/A or logical | Logical, tested | Enforced in every store | + dedicated resources where required |

## 6. Security testing expectations

- **Threat model first.** Every T2+ engagement produces `05-validation/threat-model.md`; each threat maps to a mitigation and a `TST-` or `EVAL-` case. Reference frameworks such as the OWASP Top 10 for LLM Applications and MITRE ATLAS as checklists (verify current edition), not as complete coverage.
- **Authorization tests.** For each tool: allowed user, disallowed user, cross-tenant, expired token, revoked agent version, and parameter tampering after approval.
- **Injection tests.** Direct and indirect injection through every ingestion path (documents, web, email, tool output, memory), aiming at the consequential tools and the exfiltration channels.
- **Tool-abuse tests.** Out-of-range parameters, excessive call volume, recursive delegation, and attempts to call tools outside the allowlist.
- **Secret-leak tests.** Confirm no secret or credential appears in context, traces, or logs under error conditions.
- **Supply-chain checks.** SBOM review, vulnerability scan, and MCP/tool vetting record before each release.
- **Red team (T3/T4).** Independent adversarial testing per `architecture-quality-gates.md` G6, plus re-test after material changes.
- **Honest status.** Record which tests ran and their observed results; untested threats stay visible as residual risk with an owner.

## 7. G4 quick checklist

- [ ] Identity-flow table (§2) completed for every hop in the design
- [ ] OBO vs app-only stated per tool, with downscoped tokens
- [ ] PDP/PEP placement shown in the architecture diagram
- [ ] No secret reachable by model context, logs, or traces
- [ ] Every ingestion path has injection controls from at least three layers in §4
- [ ] Consequential actions: deterministic policy + approval per matrix + SEC-08 audit record
- [ ] Egress allowlist and tenant isolation defined and tested
- [ ] Residual risks accepted by a named owner

## 8. Anti-patterns

- **Guardrail-as-control:** treating a system prompt or a content filter as the authorization layer.
- **Token forwarding:** passing the user's full session token through the agent to every tool.
- **Shared superuser:** one service account for the app, the agent, and every tool.
- **Secrets in context:** credentials placed where the model, traces, or logs can see them.
- **Unvetted tool servers:** adding third-party MCP servers or plugins without reviewing permissions and data flows.
- **Open egress:** a generic fetch tool with no destination allowlist alongside access to sensitive data.
- **Metadata-only tenancy:** tenant separation enforced by a filter the model can influence.

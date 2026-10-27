# Enterprise AI Architecture Engineering Framework

A reusable architecture engineering capability for Claude Code. It does not prescribe one enterprise AI architecture. It discovers requirements, classifies constraints, researches current technology where that matters, designs the simplest defensible architecture, challenges it independently, validates it, and turns it into an engineering plan.

It works across business domains, clouds, on-premises and hybrid environments, and technology stacks.

## What it can do

| Engagement | Example request |
|---|---|
| **Mode A: Create** | "Create an enterprise architecture for this use case. Here are the requirements, NFRs, constraints and target platform." |
| **Mode B: Review/Redesign** | "Review the architecture in `../acme-bot/`. Challenge it, find the gaps, and produce a target architecture and a remediation plan." |
| **Mode C: Improve** | "Here is our partial design and proposed stack. Azure is mandatory. Complete it and challenge the weak choices." |
| **Technology decision** | "Evaluate agent frameworks for this use case and recommend one." |
| **Focused skill** | "Run threat-modeling on the tool-execution flow." / "Re-evaluate ADR-004." |

## How it is organized

```text
CLAUDE.md                  Coordinator (board chair) rules: loaded automatically by Claude Code
.claude/agents/            9 read-only specialist subagents (the expert bench)
.claude/skills/            10 composable procedures (discovery → design → review → debate → roadmap)
standards/                 Layer A: stable principles and quality gates
knowledge/                 Layer B: dated, evolving technology knowledge + reference patterns
templates/                 Deliverable templates (copied into use cases, never edited for a project)
use-cases/<id>/            Layer C: one isolated folder per engagement
tools/                     Non-destructive scaffolding and structural validators
docs/                      Getting started, operating model, conventions, extending
tests/                     Fictional fixtures + verification record (runs/ are evidence, not real use cases)
```

### Expert bench (`.claude/agents/`)

| Agent | Focus |
|---|---|
| `enterprise-architect` | Capability alignment, landscape, reuse vs build, ownership, cross-domain impact |
| `solution-architect` | End-to-end design, interfaces, workflows, deployment, feasibility, traceability |
| `agentic-systems-architect` | Whether agentic AI is justified; orchestration, tools, state, HITL, containment |
| `ai-platform-architect` | Model access/serving, gateways, registries, LLMOps, shared-vs-domain platform |
| `data-knowledge-memory-architect` | RAG/search, stores, memory, context, freshness, permission-aware retrieval |
| `security-identity-architect` | Threats, identity separation, delegated access, injection, audit, compliance |
| `integration-infrastructure-architect` | Cloud/on-prem/hybrid, network, IaC, integration, capacity, portability |
| `reliability-llmops-architect` | SLOs, latency budgets, retries/idempotency, DR, observability, readiness |
| `red-team-architect` | Independent adversarial challenge; never just endorses the others |

### Skills (`.claude/skills/`)

`use-case-discovery` · `architecture-design` · `architecture-review` · `architecture-debate` · `technology-evaluation` · `threat-modeling` · `nfr-validation` · `architecture-diagrams` · `adr-management` · `implementation-roadmap`

You can call them by name (e.g. `/architecture-review`), or just describe what you want and the coordinator picks the skills.

## Core rules (summary)

- **Requirements drive the architecture.** Every material decision traces to an ID.
- **Simplest sufficient design.** Agentic and multi-agent designs need a measurable justification ([solution ladder](standards/architecture-principles.md)).
- **Constraint-aware.** Mandated platforms are respected and never silently overridden. Weak choices are still challenged within that boundary.
- **Decisive.** One recommendation. Alternatives appear only when they carry a real trade-off.
- **Evidence-labelled.** Every claim is tagged as verified, vendor, independent, judgment, assumption, or unverified. Time-sensitive facts carry sources and dates.
- **Proportionate.** Depth scales with risk tier T1–T4 ([quality gates](standards/architecture-quality-gates.md)).

## Quick start

See [docs/getting-started.md](docs/getting-started.md). In short:

```bash
cd enterprise-ai-architecture-framework
claude
> Create an enterprise architecture for <your use case>. Requirements: ... Constraints: ...
```

Validate the framework itself at any time:

```bash
tools/validate-framework.sh
```

## Limitations

- Validators check **structure only**. Passing them does not mean an architecture is correct.
- Mermaid diagrams get full parsing only if `mmdc` (`@mermaid-js/mermaid-cli`) is installed. Otherwise lightweight structural checks run.
- Current-technology research depends on WebSearch/WebFetch being available in the session. Without them, claims are marked `[UNVERIFIED]`.
- Knowledge entries go stale. Re-verify anything older than six months before relying on it ([knowledge/README.md](knowledge/README.md)).

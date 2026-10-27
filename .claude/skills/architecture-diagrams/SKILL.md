---
name: architecture-diagrams
description: Produce consistent Mermaid architecture diagrams at C4-style levels: context, container, component, deployment, sequence, data flow, trust boundary, agent control flow (loop bounds, approval gates, failure exits), integration/event flow, network topology, and CI/CD. Cross-checks every diagram against the component catalogue and ADRs. Use for "draw the architecture", "diagram this", "sequence diagram", "trust boundary diagram", "agent flow", or the G7 consistency gate.
argument-hint: "<use-case-id> [diagram type(s)]"
---

# Architecture Diagrams

## Purpose

Create and maintain diagrams that **agree with the written design** and communicate it at the right abstraction level. Diagrams are views of the design, not a second source of truth. The component catalogue, ADRs, and requirements are authoritative, and a diagram that contradicts them is a defect. Conventions here implement `docs/conventions.md` §7.

## When to use / not use

| Use when | Don't use when |
|---|---|
| A design, threat model, NFR analysis, or roadmap needs a visual | The component catalogue doesn't exist yet. Draft it first with `architecture-design`; diagramming first invites invented components. |
| A Mode B baseline must be captured (as-is), or a target must be shown (to-be) | You want to prove an NFR. Diagrams don't prove performance or security. |
| An ADR is accepted or superseded and the affected diagrams must be updated | |
| G7 consistency check | |

## Inputs

| Input | Path |
|---|---|
| Component catalogue (`C-` IDs, names, technology, owner) | `02-design/solution-design.md` §Component Catalogue |
| ADRs (current status only) | `04-decisions/adr/`, `04-decisions/decision-log.md` |
| Data flows and trust boundaries | `05-validation/threat-model.md` (if it exists) |
| Agent design: loop bounds, tools, approvals | `02-design/solution-design.md`, `standards/agentic-ai-design-principles.md` |
| Patterns | [references/mermaid-patterns.md](references/mermaid-patterns.md) |

## Diagram set by risk tier

| Diagram type | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| System context | ● | ● | ● | ● |
| Container / application components | ◐ | ● | ● | ● |
| Component (inside a complex container) | ○ | ○ | ◐ | ● |
| Deployment | ○ | ◐ | ● | ● |
| Sequence (each critical journey and each side-effecting flow) | ◐ | ● | ● | ● |
| Data flow (classification on edges) | ○ | ◐ | ● | ● |
| Trust boundary / security | ◐ | ● | ● | ● |
| Agent execution and control flow (if rung ≥ 6) | ● | ● | ● | ● |
| Integration / event flow | ○ | ◐ | ● | ● |
| Environment / network topology | ○ | ○ | ● | ● |
| CI/CD and operational workflow | ○ | ○ | ◐ | ● |

● required · ◐ when the feature exists or the review asks · ○ optional. For Mode B, draw **both** baseline and target for each required type, labelled `(as-is)` and `(to-be)`.

## Workflow

### Step 1. Choose the abstraction level

Use C4-style levels: context (system and external actors), container (deployable units and data stores), component (inside one container), and deployment. Don't mix levels in one diagram. Supplement them with dynamic views: sequence, agent control flow, and event flow.

**Syntax choice.** Mermaid has C4 diagram syntax, but it is experimental in Mermaid and its layout is fragile. **Default to `flowchart` with `subgraph` for trust zones and levels.** Use `sequenceDiagram` for interactions and `stateDiagram-v2` for agent and approval state machines. Use C4 syntax only if the user asks, and accept the validator's warning.

### Step 2. Draft from the catalogue, not from memory

1. List the `C-` components in scope for this view.
2. Name nodes `C-xx Name`, exactly as in the catalogue. Node IDs are alphanumeric (`C05`), and labels are quoted when they contain special characters: `C05["C-05 Policy Engine"]`.
3. Copy the matching pattern from [references/mermaid-patterns.md](references/mermaid-patterns.md) and replace the generic names.

### Step 3. Apply the conventions

| Convention | Rule |
|---|---|
| Title | First line inside the block: `%% Title: <View> — <scope> (as-is/to-be if Mode B)` |
| Caption | One sentence in italics directly below the block, saying what the reader should take away: `*Caption: …*` |
| Node names | Match the component catalogue (`C-` ID plus exact name). External systems are prefixed `EXT`. |
| Edges | Labelled with interaction and, where relevant, **protocol · identity · data classification**, e.g. `-->|"HTTPS · OBO user token · Confidential"|` |
| Trust zones | `subgraph` per zone, labelled `TB-n <zone>` to match the threat model |
| Shapes (legend) | `[ ]` service or component · `[( )]` data store · `{ }` decision or policy gate · `([ ])` external actor or system · `[[ ]]` model endpoint · `{{ }}` queue, topic, or event bus |
| Legend | T2+: include the shape legend once per document, as in the patterns reference |
| Labels | Quote any label with spaces plus punctuation: `["..."]`. No parentheses, brackets, or braces inside unquoted labels. Use `<br/>` for line breaks. |
| Agent flows | Must show the **loop bound** (max steps, time, budget), each **approval gate**, each **policy check**, and every **failure exit** (bound exceeded, policy denied, tool error, approval rejected or timed out) |
| Size | Aim for about 15 nodes or fewer per diagram. Split by level or journey rather than shrink text. |

### Step 4. Place diagrams

- Design views: embed in `02-design/solution-design.md` §Architecture Overview, or put them in `02-design/diagrams/<view>.md` and link from the design.
- Trust boundary: `05-validation/threat-model.md` §Trust Boundaries (the `threat-modeling` skill calls this skill).
- Deployment, CI/CD, and rollout views: may also be linked from `06-delivery/implementation-roadmap.md`.

### Step 5. Consistency cross-check (G7)

Do this every time a diagram is created or changed. Record the result in the design or in `05-validation/quality-gates.md` evidence.

- [ ] Every node is in the component catalogue, and every in-scope catalogue entry appears in at least one diagram.
- [ ] The technology named on any node equals the technology in the ADR and the stack table. No superseded ADR choices appear.
- [ ] Every `DF-` flow in the threat model appears as an edge in the trust-boundary diagram, with the same classification.
- [ ] Every side-effecting FR (requirements, human-in-the-loop table) appears in a sequence or agent-flow diagram with its approval gate.
- [ ] Agent loop bounds and approval thresholds match the values in the design and NFRs.
- [ ] Deployment regions and zones match the residency CONs.
- [ ] Mode B: the as-is diagram reflects the observed implementation (code, IaC), not just the intended design. Note discrepancies as findings.

### Step 6. Validate

Run `tools/validate-diagrams.sh <path>` on each changed file, and report the actual output. Without `mmdc`, it does structural checks only. Say so. **A diagram that parses doesn't prove the design satisfies its NFRs or matches the deployed system.** Those claims need the evidence in `docs/operating-model.md` §7.

## Outputs

| Artifact | Path |
|---|---|
| Design diagrams | `use-cases/<id>/02-design/solution-design.md` (embedded) and/or `use-cases/<id>/02-design/diagrams/<view>.md` |
| Trust-boundary diagram | `use-cases/<id>/05-validation/threat-model.md` §Trust Boundaries |
| Delivery and ops diagrams | `use-cases/<id>/06-delivery/implementation-roadmap.md` (embedded or linked) |
| Consistency check result | Noted in the design, and as G7 evidence in `05-validation/quality-gates.md` |

## Quality gates touched

- **G7 Design consistency.** Primary.
- **G4 Security.** Trust boundaries drawn.
- **G3 / G9.** Deployment and operational views support technology and readiness evidence.

## Failure conditions

- A node isn't in the component catalogue, or a catalogue component is missing from every view.
- A diagram shows a superseded ADR choice as current.
- An agent flow lacks a loop bound, approval gate, or failure exit.
- Trust zones in the diagram don't match the threat model's `TB-` boundaries.
- A diagram has no `%% Title:` line or caption.
- The validator reports errors, or a pass is claimed without running it.
- A parse pass is cited as evidence of NFR or security compliance.

## References

- [references/mermaid-patterns.md](references/mermaid-patterns.md): copy-ready patterns for every type above
- `docs/conventions.md` §7 (diagram conventions), §2 (IDs)
- `standards/architecture-quality-gates.md` (G7 checklist), `standards/agentic-ai-design-principles.md` (loop bounds, approvals)
- `tools/validate-diagrams.sh`
- Related skills: `architecture-design`, `threat-modeling`, `adr-management`, `implementation-roadmap`

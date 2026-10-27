# Getting Started

## 1. Prerequisites

- Claude Code (this framework was built and checked with v2.1.308).
- Start Claude Code **from the repository root**, so that `CLAUDE.md`, `.claude/agents/`, `.claude/skills/` and `.claude/settings.json` load.
- Optional: install `mmdc` (`npm i -g @mermaid-js/mermaid-cli`) for full Mermaid parsing. The framework never installs it for you.
- Optional but recommended: WebSearch/WebFetch enabled, for current-technology research.

Check that everything loaded:

```text
/agents        → should list the 9 specialists
/skills        → should list the 10 framework skills (if your version has this command; otherwise type "/" and look for them)
```

Then run the framework self-check:

```bash
tools/validate-framework.sh
```

## 2. Start your first real engagement

Describe the work in plain language. You don't need to know any file paths. The coordinator will:

1. Classify the **mode** (A create, B review/redesign, C improve, or focused), the **risk tier** (T1–T4), and every input (constraint, preference, existing investment, open decision, assumption, prohibition).
2. Scaffold `use-cases/<id>/` using `tools/new-use-case.sh <id>`.
3. Ask up to about seven material questions, or proceed on recorded assumptions if you tell it to.
4. Run the skills and specialists that the tier requires, in parallel where possible.
5. Write deliverables into the use-case folder, run the validators, and report the outcome, decisions, gate results, residual risks, and what was *not* verified.

### Good first prompts

**New architecture**
> Create an enterprise architecture for this use case: <description>. Business goals: … Users: … NFRs: p95 < 3 s, 99.9 % availability … Constraints: Azure only, data must stay in-region, existing n8n must be reused where it fits. Prohibited: sending restricted data to external SaaS.

**Review an existing architecture**
> Review the architecture files in `/path/to/solution`. Independently challenge the design, identify anti-patterns and requirement gaps, and produce an improved target architecture with a prioritized remediation plan. Don't modify the source files.

**Constrained redesign**
> Redesign this solution for on-premises only, with GPU capacity of <N> × <accelerator>. Evaluate self-hosted model serving, security, connectivity and operations. Preserve the mandatory constraints and document the migration steps.

**Technology decision**
> Evaluate the available agent frameworks for this use case. Compare them against our FRs, NFRs, deployment constraints, security requirements, team skills, and current product maturity. Recommend one, and explain any meaningful alternative.

**Production-readiness review**
> Review the implementation and architecture against the requirements and production-readiness criteria. Separate verified defects, evidence-based risks, assumptions, and untested items.

**Focused**
> Run threat-modeling for the proposed tool-execution flow in use-cases/invoice-triage.
> Run nfr-validation against the supplied service targets.
> Re-evaluate ADR-004 in use-cases/invoice-triage. The model provider changed its residency terms.

### Steering the depth

- "Treat this as T1, quick review only." Gives a lightweight process.
- "This is customer-facing and executes payments." Raises the tier to T3/T4 and brings in the full bench and red team.
- "Proceed with assumptions; don't ask me questions now." Gaps are recorded as `ASM-` items to validate later.
- "Use only the security and reliability specialists." Gives you an explicit bench.

## 3. Where to find outputs

```text
use-cases/<id>/00-intake/use-case-brief.md      scope, classification, tier, open questions
use-cases/<id>/01-requirements/requirements.md  FR/NFR, constraints, traceability
use-cases/<id>/02-design/solution-design.md     the architecture (start here)
use-cases/<id>/03-review-board/                 specialist reports, debate record, review report
use-cases/<id>/04-decisions/adr/                ADRs + decision-log.md
use-cases/<id>/05-validation/                   threat model, NFR validation, test plan, gate results
use-cases/<id>/06-delivery/                     roadmap, backlog, runbooks
```

Validate a use case yourself:

```bash
tools/validate-deliverables.sh use-cases/<id>
tools/validate-diagrams.sh use-cases/<id>
```

## 4. Manual checks the validators can't do

A passing validator proves structure, not substance. Before approval, a human architect should confirm:

- [ ] The mandatory constraints in the brief are really mandatory (confirmed with their owners).
- [ ] The chosen solution-ladder rung is justified against simpler options.
- [ ] Each diagram matches the component catalogue and the ADRs.
- [ ] Time-sensitive claims (product features, licensing, regions, prices) have sources and dates, and are recent enough.
- [ ] Residual risks have named owners who have accepted them.
- [ ] Nothing marked "tested" or "verified" lacks evidence.
- [ ] No secrets or sensitive data appear in the deliverables.

See [operating-model.md](operating-model.md) for how the coordinator runs specialists and debate. See [conventions.md](conventions.md) for file layout and IDs.

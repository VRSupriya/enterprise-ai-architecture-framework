# Extending the Framework

The framework separates three layers. How you change each layer differs.

| Layer | Location | Change process | Who approves |
|---|---|---|---|
| A. Stable principles | `standards/`, `CLAUDE.md`, `docs/operating-model.md`, `docs/conventions.md` | Deliberate framework change, recorded in the change log below | Architecture board owner |
| B. Evolving technology knowledge | `knowledge/` | Update via the `technology-evaluation` skill. Every entry is dated and labelled. | Any architect, with peer review |
| C. Use-case decisions | `use-cases/<id>/` | ADRs within the engagement | The use case's decision owner |

`.claude/settings.json` asks before edits to `standards/`, `templates/` and `.claude/`, so those changes are deliberate.

**Never promote a Layer C decision to Layer A or B automatically.** If a decision from one use case looks generally useful (for example "pgvector was sufficient at our scale"), add it to `knowledge/` as dated evidence with its context. Don't add it as a rule.

## Updating technology knowledge

1. Run `technology-evaluation` for the topic (a use case isn't required: "Refresh the knowledge entry for agent frameworks").
2. Record the sources, access dates, versions and evidence labels.
3. Update the entry's `Last verified:` date and confidence.
4. If the change invalidates ADRs in active use cases, list those ADRs. Their revisit triggers decide whether they are re-opened. Don't edit them silently.

## Adding a specialist agent

1. Confirm there's a real gap. If an existing agent can absorb the mandate, prefer that.
2. Create `.claude/agents/<name>.md` with:
   - `name` (equal to the filename)
   - `description` (delegation triggers)
   - an explicit read-only `tools` list (no `Agent`, `Bash`, `Edit` or `Write`)
   - `model: inherit`
3. Follow the body structure the existing agents use:
   - mandate
   - out of scope / hand-off
   - inputs
   - method
   - standards
   - quality criteria
   - output in the [conventions.md §5](conventions.md) format
   - rules
4. Add a finding prefix to [conventions.md §2](conventions.md) and a row to the selection matrix in [operating-model.md §3](operating-model.md).
5. Add the name to `AGENTS` in `tools/validate-framework.sh`, then run it.

## Adding a skill

1. Create `.claude/skills/<name>/SKILL.md`. Frontmatter starts on line 1 and needs `name` (equal to the directory) and `description` (what the skill does and when to use it).
2. Include these sections: Purpose, When to use, Inputs, Workflow, Outputs, Quality gates, Failure conditions, References. Keep it under about 250 lines, and move detail into `references/`.
3. Reference the standards rather than restating them. Compose the skill with existing skills rather than duplicating them.
4. Add the name to `SKILLS` in `tools/validate-framework.sh`, then run it.

## Adding a reference architecture

Add `knowledge/reference-architectures/<pattern>.md` with the same sections as the existing patterns, and index it in that folder's README. A pattern is a decision aid, never a compulsory template.

## Adding or changing a template or a required section

1. Edit the template.
2. If a required `##` heading changes, update [conventions.md §3](conventions.md) and the matching `H_*` list in `tools/validate-deliverables.sh` in the same change.
3. Existing use cases keep their old structure. Re-validate them, and record any known exceptions in their brief.

## Framework change log

| Date | Change | Layer | Approved by |
|---|---|---|---|
| 2026-10-26 | Initial framework build | A/B | (pending owner approval) |

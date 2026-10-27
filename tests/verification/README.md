# Framework Verification Record

**Date:** 2026-10-27 · Claude Code v2.1.308 · Both runs use fictional fixtures. Nothing was deployed, and no system tests were executed.

This record shows how the framework behaved on representative inputs. It's evidence about the framework's procedures, not about any real architecture. The runs live in `runs/` (moved out of `use-cases/`, which is reserved for real engagements).

## Results by scenario (master prompt §20 Step 7)

| # | Scenario | How exercised | Result |
|---|---|---|---|
| 1 | New architecture from a use-case description | `runs/alarm-triage-onprem/`. A fresh agent acted as coordinator, starting only from `CLAUDE.md` and the skills. Mode A, T1. | Chose rungs 1–2: a deterministic rules job on the existing server. Treated "use AI agents" (CEO) as a PREF, ran the agentic justification test, and rejected agents with revisit triggers. Validator PASS. |
| 2 | Review and redesign of an existing architecture | `runs/fsa-review-fixture/`. Mode B, T3. Fixture in `tests/fixtures/field-service-assistant/`, with intended design and implemented config that deliberately diverge. | 7 independent specialist reports, consolidated into F-BRD findings with dispositions, a target design, a transition plan, and 6 ADRs. **All 15 planted issues** (`answer-key-field-service-assistant.md`) were found, most by 4 or more specialists. Every specialist flagged the gaps between intended and implemented. |
| 3 | Constrained platform | Run 2 (Azure mandated) and run 1 (on-prem mandated) | Run 2: no specialist proposed another cloud (0 mentions of AWS/GCP/etc. across all reports). Choices inside Azure were still challenged: AKS → Container Apps, custom gateway → APIM, Pinecone → AI Search. Run 1 introduced no cloud services. |
| 4 | Technology decision needing current research | Knowledge base build (~30 searches, dated and labelled), plus live research by the DK and IN specialists in run 2 | Sources cited with access dates. Vendor claims labelled `[VENDOR]`, and unverifiable claims labelled `[UNVERIFIED]`. The chair spot-checked two claims (MAF 1.0 GA on 2026-04-03; MCP spec 2026-07-28) and both were consistent. No standalone `technology-evaluation` run was performed. |
| 5 | Competing specialist recommendations | Run 2, DBT-03 (runtime: Container Apps vs AKS), plus severity disputes DBT-04/05 | A coordinator-mediated rebuttal round. Both sides refined their positions on evidence. The red team conceded the substance but added 4 conditions and caught an evidence mis-citation (DBT-07). Severity was decided by the rubric, not by vote. |

## Notable behaviors observed

- **The red team's independence worked.** It ran a blind first pass. On the second pass, the red team rated the target "Sound with conditions" and found five new weaknesses in the board's own design:
  - the confirmation token was trusted on C-02's word
  - n8n became the unassessed deputy
  - residency of reused components was unproven
  - the transition state left the residency breach live
  - audit ordering was not fail-closed

  It also caught the **board chair's overclaims**: G5 was marked PASS with Critical findings open, G6 was marked PASS before the second pass existed, and an existing APIM was asserted without evidence. These were corrected, and the lesson became a rule in `standards/architecture-quality-gates.md` §4 ("Assessment rules").
- **Proportionate challenge.** Specialists listed the areas where they found *no* material issue, and the red team declined to manufacture objections (for example, it rated lock-in low and called AKS "not a CON-001 breach").
- **Run 1 surfaced 8 framework gaps.** These were fixed:
  - the tier-table wording for internal policy
  - where T1 records gate results
  - defining test IDs without a test plan at T1
  - the T1 security checklist pointer
  - scaffolder guidance
  - the template defaulting to Mode A/T2, which could pass unset (now `?`)
  - checking that input IDs are defined
  - guidance when a lower ladder rung's viability is unknown

  Not fixed: diagram-node vs component-catalogue matching is still a manual check.

## Validator checks performed (observed output)

| Check | Result |
|---|---|
| `tools/validate-framework.sh` | PASS, 0 warnings |
| `tools/validate-diagrams.sh .` | PASS, structural only (`mmdc` not installed) |
| `tools/validate-deliverables.sh` on both runs | PASS, 0 warnings |
| Negative test (copy of run 2 with 8 injected defects) | All 8 detected: missing heading, TEMPLATE marker, missing red-team report, broken supersession, dangling ADR/NFR/TST refs, untraced FR, fake AWS key |
| Negative test (copy of run 1 with unset tier, undefined CON-/TST- refs) | All 3 detected |

## Limitations of this verification

- **Red-team agent registration.** In run 2, the red-team first pass ran as a general-purpose agent instructed to adopt `.claude/agents/red-team-architect.md` verbatim, read-only. The session had not yet registered the newly created agent file; it registered later in the same session. Rebuttal and second-pass rounds continued the same agent.
- **Run 1 had no specialists**, by design: a T1 engagement uses coordinator self-check per the operating model.
- **Not exercised end to end:**
  - `adr-management` revisit mode (supersession)
  - Mode C
  - a T4 full bench
  - `enterprise-architect` and `ai-platform-architect` in a live review
- **Mermaid diagrams** were never rendered by a real parser.
- **Specialist reports were persisted** by extracting each agent's final message from its session transcript (verbatim). In normal use, the coordinator writes the returned text to the file.

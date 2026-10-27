#!/usr/bin/env bash
# Structural validation of one use-case's deliverables against docs/conventions.md.
#
# Checks: brief metadata (Mode, Risk tier); minimum files for the tier; required
# `##` headings; unfilled templates; ADR naming/status/supersession links;
# cross-references (ADR-, FR-, NFR-, T-, TST- IDs) resolve; requirements appear
# in the traceability section; obvious secrets are absent.
#
# Read-only. Passing proves STRUCTURE only — not that the architecture is sound.
# Usage: tools/validate-deliverables.sh use-cases/<use-case-id>
set -u
. "$(dirname "$0")/lib.sh"

UC="${1:-}"
[ -n "$UC" ] && [ -d "$UC" ] || { echo "usage: $0 use-cases/<use-case-id>"; exit 2; }
UC="${UC%/}"

BRIEF="$UC/00-intake/use-case-brief.md"
REQ="$UC/01-requirements/requirements.md"
SD="$UC/02-design/solution-design.md"
RR="$UC/03-review-board/review-report.md"
DR="$UC/03-review-board/debate-record.md"
ADRDIR="$UC/04-decisions/adr"
TM="$UC/05-validation/threat-model.md"
TP="$UC/05-validation/test-and-evaluation-plan.md"
QG="$UC/05-validation/quality-gates.md"
RM="$UC/06-delivery/implementation-roadmap.md"

# heading lists use '|' as separator
H_BRIEF="Engagement Classification|Business Objectives|Scope|Stakeholders|Input Classification|Open Questions"
H_REQ="Functional Requirements|Non-Functional Requirements|Constraints and Assumptions|Traceability"
H_SD="Executive Summary|Solution Approach|Architecture Overview|Component Catalogue|Technology Selection|Security and Identity|Data and Knowledge|Operations and Reliability|Risks and Open Decisions"
H_RR="Scope and Baseline|Findings|Disposition|Target Architecture|Remediation Roadmap"
H_DR="Proposal|Objections|Resolutions|Residual Risks"
H_ADR="Status|Context|Decision|Alternatives Considered|Consequences|Revisit Triggers"
H_TM="Scope and Assets|Trust Boundaries|Threats|Residual Risk"
H_TP="Verification Matrix|AI Evaluation|Adversarial Testing|Release Criteria"
H_QG="Gate Results"
H_RM="Workstreams|Milestones|Dependencies|Operational Readiness|Rollout and Rollback|Risks"

check_doc() { # file headings required(1/0)
  local f="$1" hs="$2" req="$3"
  if [ ! -f "$f" ]; then
    [ "$req" = 1 ] && err "missing required deliverable for tier $TIER: ${f#$UC/}"
    return
  fi
  grep -q '<!-- TEMPLATE' "$f" && err "${f#$UC/}: still contains the TEMPLATE marker (unfilled)"
  local IFS='|'; local missing=""
  for h in $hs; do has_h2 "$f" "$h" || missing="$missing '$h'"; done
  [ -n "$missing" ] && err "${f#$UC/}: missing ## heading(s):$missing" || ok "${f#$UC/}"
}

info "== Brief"
[ -f "$BRIEF" ] || { err "missing $BRIEF"; summary; exit 1; }
MODE=$(grep -m1 -E '^\s*-\s*\*\*Mode:\*\*' "$BRIEF" | sed -E 's/.*\*\*Mode:\*\*[[:space:]]*([A-Za-z]+).*/\1/')
TIER=$(grep -m1 -E '^\s*-\s*\*\*Risk tier:\*\*' "$BRIEF" | sed -E 's/.*\*\*Risk tier:\*\*[[:space:]]*(T[1-4]).*/\1/')
case "$MODE" in A|B|C|Focused) ;; *) err "brief: '- **Mode:**' must be A, B, C or Focused (got '$MODE')"; MODE="?";; esac
case "$TIER" in T1|T2|T3|T4) ;; *) err "brief: '- **Risk tier:**' must be T1..T4 (got '$TIER')"; TIER="T1";; esac
info "mode=$MODE tier=$TIER"
check_doc "$BRIEF" "$H_BRIEF" 1

info "== Deliverables for tier $TIER (mode $MODE)"
t1=0; t2=0; t3=0
[ "$MODE" != "Focused" ] && t1=1
case "$TIER" in T2) t2=$t1;; T3|T4) t2=$t1; t3=$t1;; esac
need_sd=0; need_rr=0
[ "$t1" = 1 ] && { case "$MODE" in B) need_rr=1;; *) need_sd=1;; esac; }

check_doc "$REQ" "$H_REQ" "$t1"
check_doc "$SD"  "$H_SD"  "$need_sd"
check_doc "$RR"  "$H_RR"  "$need_rr"
check_doc "$TM"  "$H_TM"  "$t2"
check_doc "$QG"  "$H_QG"  "$t2"
check_doc "$RM"  "$H_RM"  "$t2"
check_doc "$TP"  "$H_TP"  "$t3"
check_doc "$DR"  "$H_DR"  "$t3"
if [ "$t3" = 1 ]; then
  ls "$UC"/03-review-board/round-*/red-team-architect.md >/dev/null 2>&1 \
    && ok "red-team report present" || err "tier $TIER requires 03-review-board/round-*/red-team-architect.md"
fi

info "== ADRs"
adr_count=0
if [ -d "$ADRDIR" ]; then
  for a in "$ADRDIR"/*.md; do
    [ -e "$a" ] || continue
    base=$(basename "$a")
    echo "$base" | grep -qE '^ADR-[0-9]{3}-[a-z0-9-]+\.md$' || { warn "ADR filename '$base' should match ADR-NNN-<slug>.md"; continue; }
    adr_count=$((adr_count + 1))
    check_doc "$a" "$H_ADR" 1
    st=$(awk '/^## +[Ss]tatus/{f=1; next} f && NF {print; exit}' "$a")
    echo "$st" | grep -qiE 'Proposed|Accepted|Rejected|Deprecated|Superseded' \
      || err "$base: Status must be Proposed|Accepted|Rejected|Deprecated|Superseded by ADR-NNN (got '$st')"
    sup=$(echo "$st" | grep -oE 'ADR-[0-9]{3}' | head -n1)
    if [ -n "$sup" ]; then ls "$ADRDIR/$sup"-*.md >/dev/null 2>&1 || err "$base: superseded by $sup, but that ADR does not exist"; fi
  done
fi
[ "$t2" = 1 ] && [ "$adr_count" -eq 0 ] && err "tier $TIER requires at least one ADR in 04-decisions/adr/"
[ -d "$ADRDIR" ] && [ "$adr_count" -gt 0 ] && [ ! -f "$UC/04-decisions/decision-log.md" ] && warn "04-decisions/decision-log.md (ADR index) is missing"

info "== Cross-references"
ALL=$(find "$UC" -name '*.md' -type f)
# ADR references must resolve to files.
for id in $(cat $ALL | grep -oE 'ADR-[0-9]{3}' | sort -u); do
  ls "$ADRDIR/$id"-*.md >/dev/null 2>&1 || err "reference to $id but no file $ADRDIR/$id-*.md"
done
# Requirement IDs referenced anywhere must be defined in requirements.md.
if [ -f "$REQ" ]; then
  for id in $(cat $ALL | grep -oE '\b(FR|NFR)-[0-9]{3}\b' | sort -u); do
    grep -qE "\b$id\b" "$REQ" || warn "$id is referenced but not defined in requirements.md"
  done
  # Each defined FR/NFR (first column of a table row) should appear in the Traceability section.
  defined=$(grep -oE '^\|[[:space:]]*(FR|NFR)-[0-9]{3}' "$REQ" | grep -oE '(FR|NFR)-[0-9]{3}' | sort -u)
  trace=$(awk 'BEGIN{IGNORECASE=1} /^## /{f=(tolower($0) ~ /^## +traceability/)} f' "$REQ")
  untraced=""
  for id in $defined; do echo "$trace" | grep -qE "\b$id\b" || untraced="$untraced $id"; done
  [ -n "$untraced" ] && warn "requirements not in Traceability section:$untraced"
fi
# Threat and test IDs must be defined in their home documents.
for id in $(cat $ALL | grep -oE '\bT-[0-9]{3}\b' | sort -u); do
  [ -f "$TM" ] && grep -qE "\b$id\b" "$TM" || warn "$id referenced but not defined in threat-model.md"
done
for id in $(cat $ALL | grep -oE '\b(TST|EVAL)-[A-Z]*[0-9]+\b' | sort -u); do
  if [ -f "$TP" ]; then
    grep -qE "\b$id\b" "$TP" || warn "$id referenced but not defined in test-and-evaluation-plan.md"
  else
    # No test plan (allowed below T3): the ID must be defined as the first cell of a table row somewhere.
    cat $ALL | grep -qE "^\|[[:space:]]*$id[[:space:]]*\|" || warn "$id referenced but not defined (no test plan, and no table row defines it)"
  fi
done
# Input-classification IDs must be defined (first table cell) in the brief or requirements.
DEFS="$BRIEF"; [ -f "$REQ" ] && DEFS="$DEFS $REQ"
for id in $(cat $ALL | grep -oE '\b(CON|PREF|INV|DEC|ASM|PRH)-[0-9]{3}\b' | sort -u); do
  cat $DEFS | grep -qE "^\|[[:space:]]*$id[[:space:]]*\|" || warn "$id referenced but not defined in the brief or requirements"
done

info "== Sensitive content scan (heuristic)"
leaks=$(grep -nE -- '-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|xox[baprs]-[0-9A-Za-z-]{10,}|sk-[A-Za-z0-9_-]{32,}|AccountKey=[A-Za-z0-9+/=]{20,}' $ALL 2>/dev/null)
[ -n "$leaks" ] && err "possible secret(s) in deliverables:
$leaks" || ok "no obvious secrets found"

info "== Diagrams"
if grep -lq '^```mermaid' $ALL 2>/dev/null; then
  "$(dirname "$0")/validate-diagrams.sh" "$UC" | sed 's/^/  /' | grep -E 'ERROR|WARN|Result' || true
  "$(dirname "$0")/validate-diagrams.sh" "$UC" >/dev/null 2>&1 || err "diagram validation failed (run tools/validate-diagrams.sh $UC)"
else
  [ "$t1" = 1 ] && warn "no mermaid diagrams found in deliverables"
fi

summary

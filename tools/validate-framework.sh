#!/usr/bin/env bash
# Structural validation of the framework itself (not of any use case).
# Checks: required files, agent + skill frontmatter, specialist least-privilege
# tool lists, relative markdown links, and backtick-quoted repo paths.
# Read-only. Usage: tools/validate-framework.sh
set -u
. "$(dirname "$0")/lib.sh"
cd "$REPO_ROOT" || exit 2

AGENTS="enterprise-architect solution-architect agentic-systems-architect ai-platform-architect data-knowledge-memory-architect security-identity-architect integration-infrastructure-architect reliability-llmops-architect red-team-architect"
SKILLS="use-case-discovery architecture-design architecture-review architecture-debate technology-evaluation threat-modeling nfr-validation architecture-diagrams adr-management implementation-roadmap"
REQUIRED_FILES="README.md CLAUDE.md .gitignore .claude/settings.json
standards/architecture-principles.md standards/agentic-ai-design-principles.md standards/security-and-identity.md
standards/data-governance.md standards/observability-and-evaluation.md standards/reliability-and-resilience.md
standards/architecture-quality-gates.md
knowledge/technology-catalog.md knowledge/framework-comparison.md knowledge/model-selection-guide.md
knowledge/deployment-patterns.md knowledge/reference-architectures/README.md
templates/use-case-intake.md templates/requirements.md templates/solution-design.md
templates/architecture-decision-record.md templates/threat-model.md templates/test-and-evaluation-plan.md
templates/implementation-roadmap.md templates/review-report.md templates/debate-record.md templates/quality-gates.md
.claude/skills/architecture-review/references/review-checklist.md
.claude/skills/architecture-review/references/severity-rubric.md
docs/getting-started.md docs/operating-model.md docs/extending-the-framework.md docs/conventions.md
tools/validate-diagrams.sh tools/validate-deliverables.sh tools/new-use-case.sh use-cases/.gitkeep"

info "== Required files"
for f in $REQUIRED_FILES; do [ -e "$f" ] || err "missing required file: $f"; done
[ "$ERRORS" -eq 0 ] && ok "all required files present"

info "== Settings JSON"
if command -v jq >/dev/null 2>&1; then
  jq empty .claude/settings.json 2>/dev/null && ok ".claude/settings.json is valid JSON" || err ".claude/settings.json is not valid JSON"
elif command -v python3 >/dev/null 2>&1; then
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' .claude/settings.json 2>/dev/null \
    && ok ".claude/settings.json is valid JSON" || err ".claude/settings.json is not valid JSON"
else
  warn "neither jq nor python3 available; JSON not validated"
fi

info "== Agents (.claude/agents)"
for a in $AGENTS; do
  f=".claude/agents/$a.md"
  [ -f "$f" ] || { err "agent missing: $f"; continue; }
  [ "$(head -n1 "$f")" = "---" ] || { err "$f: frontmatter must start on line 1"; continue; }
  name=$(fm_value "$f" name); desc=$(fm_value "$f" description); tools=$(fm_value "$f" tools)
  [ "$name" = "$a" ] || err "$f: name '$name' must equal filename '$a'"
  [ -n "$desc" ] || err "$f: description is required"
  if [ -z "$tools" ]; then
    err "$f: explicit 'tools' list required (specialists must not inherit all tools)"
  else
    for banned in Agent Bash Edit Write NotebookEdit; do
      echo ",$tools," | tr -d ' ' | grep -q ",$banned," && err "$f: specialist must not have '$banned' tool (read-only bench)"
    done
  fi
  [ "$(wc -l < "$f")" -ge 40 ] || warn "$f: body looks thin (<40 lines)"
done
for f in .claude/agents/*.md; do
  b=$(basename "$f" .md); echo " $AGENTS " | grep -q " $b " || warn "unexpected extra agent: $f (fine if intentional; update validate-framework.sh)"
done
[ "$ERRORS" -eq 0 ] && ok "agent frontmatter valid"

info "== Skills (.claude/skills)"
for s in $SKILLS; do
  f=".claude/skills/$s/SKILL.md"
  [ -f "$f" ] || { err "skill missing: $f"; continue; }
  [ "$(head -n1 "$f")" = "---" ] || { err "$f: frontmatter must start on line 1"; continue; }
  name=$(fm_value "$f" name); desc=$(fm_value "$f" description)
  [ "$name" = "$s" ] || err "$f: name '$name' must equal directory '$s'"
  [ -n "$desc" ] || err "$f: description is required"
  [ "${#desc}" -le 1536 ] || warn "$f: description >1536 chars will be truncated in the skill listing"
  lines=$(wc -l < "$f"); [ "$lines" -le 500 ] || warn "$f: $lines lines (docs recommend <500; move detail to references/)"
  for sec in "Purpose" "Workflow" "Outputs" "Failure"; do
    grep -qiE "^#+ .*$sec" "$f" || warn "$f: no heading containing '$sec'"
  done
done
[ "$ERRORS" -eq 0 ] && ok "skill frontmatter valid"

info "== Relative markdown links"
link_errs=0
TMP_LINKS=$(mktemp)
while IFS= read -r md; do
  dir=$(dirname "$md")
  # Extract (target) from [text](target), skipping fenced code blocks.
  awk '/^```/{f=!f; next} !f' "$md" | grep -oE '\]\([^)[:space:]]+\)' | sed -E 's/^\]\(//; s/\)$//' | while IFS= read -r t; do
    case "$t" in http*|mailto:*|\#*) continue;; esac
    p="${t%%#*}"; [ -z "$p" ] && continue
    case "$p" in *'<'*|*'*'*) continue;; esac
    [ -e "$dir/$p" ] || [ -e "$p" ] || echo "BROKEN $md -> $t"
  done
done < <(find . -name '*.md' -not -path './.git/*' -not -path './use-cases/*') > "$TMP_LINKS" 2>/dev/null
while IFS= read -r line; do err "${line#BROKEN }"; link_errs=$((link_errs+1)); done < "$TMP_LINKS"
rm -f "$TMP_LINKS"
[ "$link_errs" -eq 0 ] && ok "relative links resolve"

info "== Backtick-quoted framework paths"
path_errs=0
refs=$(find . -name '*.md' -not -path './.git/*' -not -path './use-cases/*' -print0 \
  | xargs -0 grep -ohE '`(\.claude|standards|knowledge|templates|docs|tools)/[A-Za-z0-9._/-]+`' 2>/dev/null \
  | tr -d '`' | sed -E 's/[.,;:]+$//' | sort -u)
for r in $refs; do
  # Only file-like references (extension or trailing slash); skips e.g. the MCP method `tools/list`.
  case "$r" in */) ;; *) case "${r##*/}" in *.*) ;; *) continue;; esac;; esac
  [ -e "$r" ] || { err "referenced path does not exist: $r"; path_errs=$((path_errs+1)); }
done
[ "$path_errs" -eq 0 ] && ok "backtick-quoted framework paths exist"

summary

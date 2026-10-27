#!/usr/bin/env bash
# Scaffold an isolated use-case workspace. Never overwrites existing files.
# Usage: tools/new-use-case.sh <use-case-id>     (lowercase-kebab, e.g. invoice-triage)
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ID="${1:-}"
if ! echo "$ID" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  echo "usage: $0 <use-case-id>  (lowercase-kebab, e.g. invoice-triage)" >&2; exit 2
fi
UC="$ROOT/use-cases/$ID"
if [ -e "$UC" ]; then
  echo "use-cases/$ID already exists — not modifying it. Continue the existing engagement or pick a new id." >&2; exit 1
fi

for d in 00-intake 01-requirements 02-design/diagrams 03-review-board/round-1 04-decisions/adr 05-validation 06-delivery/runbooks; do
  mkdir -p "$UC/$d"
done

# Only the intake brief and requirements are started; other templates are copied
# by the relevant skill when the engagement actually needs them.
cp "$ROOT/templates/use-case-intake.md" "$UC/00-intake/use-case-brief.md"
cp "$ROOT/templates/requirements.md"    "$UC/01-requirements/requirements.md"
sed -i.bak "s/<use-case-id>/$ID/g" "$UC/00-intake/use-case-brief.md" && rm -f "$UC/00-intake/use-case-brief.md.bak"

cat > "$UC/04-decisions/decision-log.md" <<EOF
# Decision Log — $ID

| ADR | Title | Status | Date | Decision owner | Supersedes / Superseded by |
|---|---|---|---|---|---|
EOF

echo "Created use-cases/$ID"
find "$UC" -type f | sed "s|$ROOT/||" | sort
echo
echo "Next: fill 00-intake/use-case-brief.md (use-case-discovery skill); set Mode and Risk tier (they start as '?')."
echo "Then copy the templates your mode and tier need (docs/conventions.md section 4), e.g.:"
echo "  Mode A/C: templates/solution-design.md -> 02-design/solution-design.md"
echo "  Mode B:   templates/review-report.md   -> 03-review-board/review-report.md"
echo "  T2+:      threat-model, quality-gates, implementation-roadmap, ADRs;  T3+: test-and-evaluation-plan, debate-record"
echo "Templates carry a TEMPLATE marker until filled; the validator reports them as unfilled."

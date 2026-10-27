#!/usr/bin/env bash
# Validate Mermaid diagrams embedded in Markdown files.
#
# Always runs lightweight structural checks:
#   - every ```mermaid fence is closed
#   - first non-comment line declares a known diagram type
#   - flowchart/graph: subgraph/end balance; balanced [] () {} per line
#   - sequenceDiagram: alt/opt/loop/par/critical/rect ... end balance
#   - %% Title: line present (framework convention, warning only)
# If the Mermaid CLI (`mmdc`) is already on PATH, each block is also rendered
# to a throwaway SVG to prove it parses. This script never installs anything.
#
# A diagram that parses is NOT proof that the design meets its requirements.
#
# Usage: tools/validate-diagrams.sh [path ...]   (default: whole repo)
set -u
. "$(dirname "$0")/lib.sh"

[ "$#" -eq 0 ] && set -- "$REPO_ROOT"
FILES=$(for p in "$@"; do
  if [ -d "$p" ]; then find "$p" -name '*.md' -not -path '*/.git/*'; elif [ -f "$p" ]; then echo "$p"; else err "no such path: $p"; fi
done | sort -u)

MMDC=""
command -v mmdc >/dev/null 2>&1 && MMDC=$(command -v mmdc)
if [ -n "$MMDC" ]; then info "mmdc found: full parse enabled"; else info "mmdc not found: structural checks only (install @mermaid-js/mermaid-cli yourself for full parsing)"; fi

TMPD=$(mktemp -d); trap 'rm -rf "$TMPD"' EXIT
total=0

for f in $FILES; do
  # Split each mermaid block into its own file: <tmp>/<n>.mmd, recording start line.
  rm -f "$TMPD"/blk_* 2>/dev/null
  awk -v d="$TMPD" '
    /^[ \t]*```mermaid[ \t]*$/ { if (inb) { print "NESTED " NR > (d "/blk_err") } inb=1; n++; start[n]=NR; out=sprintf("%s/blk_%03d_%d.mmd", d, n, NR); next }
    inb && /^[ \t]*```[ \t]*$/ { inb=0; close(out); next }
    inb { print > out }
    END { if (inb) print "UNCLOSED " start[n] > (d "/blk_err") }
  ' "$f"
  if [ -f "$TMPD/blk_err" ]; then
    while read -r kind ln; do err "$f:$ln: mermaid fence $kind"; done < "$TMPD/blk_err"
    rm -f "$TMPD/blk_err"
  fi
  for b in "$TMPD"/blk_*.mmd; do
    [ -e "$b" ] || continue
    total=$((total + 1))
    ln=$(basename "$b" .mmd); ln=${ln##*_}
    loc="$f:$ln"
    first=$(grep -vE '^[[:space:]]*(%%.*)?$' "$b" | grep -vE '^[[:space:]]*---' | head -n1 | awk '{print $1}')
    case "$first" in
      flowchart|graph) kind=flow ;;
      sequenceDiagram) kind=seq ;;
      stateDiagram|stateDiagram-v2|classDiagram|erDiagram|journey|gantt|pie|mindmap|timeline|quadrantChart|gitGraph|C4Context|C4Container|C4Component|C4Deployment|C4Dynamic|block-beta|architecture-beta|sankey-beta|xychart-beta|requirementDiagram) kind=other ;;
      "") err "$loc: empty mermaid block"; continue ;;
      *) err "$loc: unknown diagram type '$first'"; continue ;;
    esac
    grep -qE '^[[:space:]]*%%[[:space:]]*Title:' "$b" || warn "$loc: no '%% Title:' line (framework convention)"
    case "$first" in C4*) warn "$loc: Mermaid C4 syntax is experimental; prefer flowchart+subgraph for durability";; esac

    if [ "$kind" = flow ]; then
      bal=$(awk '/^[[:space:]]*%%/{next} /^[[:space:]]*subgraph([[:space:]]|$)/{s++} /^[[:space:]]*end[[:space:]]*$/{e++} END{print s-e}' "$b")
      [ "$bal" -eq 0 ] || err "$loc: subgraph/end imbalance ($bal)"
      # Bracket balance per line, ignoring quoted text and comments.
      awk -v loc="$loc" '
        /^[[:space:]]*%%/ {next}
        { l=$0; gsub(/"[^"]*"/, "", l);
          o=gsub(/\[/,"[",l); c=gsub(/\]/,"]",l); if (o!=c) printf "BR %s line %d: [ ] unbalanced\n", loc, NR;
          o=gsub(/\(/,"(",l); c=gsub(/\)/,")",l); if (o!=c) printf "BR %s line %d: ( ) unbalanced\n", loc, NR;
          o=gsub(/\{/,"{",l); c=gsub(/\}/,"}",l); if (o!=c) printf "BR %s line %d: { } unbalanced\n", loc, NR; }
      ' "$b" | while read -r _ msg; do echo "$msg"; done > "$TMPD/br"
      while IFS= read -r m; do err "$m"; done < "$TMPD/br"
    elif [ "$kind" = seq ]; then
      bal=$(awk '/^[[:space:]]*%%/{next} /^[[:space:]]*(alt|opt|loop|par|critical|break|rect|box)([[:space:]]|$)/{s++} /^[[:space:]]*end[[:space:]]*$/{e++} END{print s-e}' "$b")
      [ "$bal" -eq 0 ] || err "$loc: block/end imbalance in sequenceDiagram ($bal)"
    fi

    if [ -n "$MMDC" ]; then
      if ! "$MMDC" -q -i "$b" -o "$TMPD/out.svg" >"$TMPD/mmdc.log" 2>&1; then
        err "$loc: mmdc parse failed: $(head -n3 "$TMPD/mmdc.log" | tr '\n' ' ')"
      fi
    fi
  done
done

info "checked $total mermaid block(s)"
[ "$total" -eq 0 ] && warn "no mermaid blocks found"
summary

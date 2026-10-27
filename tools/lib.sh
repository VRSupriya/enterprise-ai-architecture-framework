#!/usr/bin/env bash
# Shared helpers for framework validators. Sourced, not executed.
# Portable to macOS bash 3.2 (no associative arrays, no mapfile).

ERRORS=0
WARNINGS=0

if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_YEL=$'\033[33m'; C_GRN=$'\033[32m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
  C_RED=""; C_YEL=""; C_GRN=""; C_DIM=""; C_OFF=""
fi

err()  { ERRORS=$((ERRORS + 1));   printf '%sERROR%s  %s\n' "$C_RED" "$C_OFF" "$*"; }
warn() { WARNINGS=$((WARNINGS + 1)); printf '%sWARN%s   %s\n' "$C_YEL" "$C_OFF" "$*"; }
ok()   { printf '%sOK%s     %s\n' "$C_GRN" "$C_OFF" "$*"; }
info() { printf '%s%s%s\n' "$C_DIM" "$*" "$C_OFF"; }

# Repo root = parent of the tools/ directory.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Print the YAML frontmatter block (without --- lines) of a file, or nothing.
frontmatter() {
  awk 'NR==1 && $0!="---" {exit} NR==1 {next} $0=="---" {exit} {print}' "$1"
}

# Value of a top-level scalar frontmatter key (strips surrounding quotes).
fm_value() {
  frontmatter "$1" | awk -v k="$2" '
    $0 ~ "^"k":" { sub("^"k":[ ]*", ""); gsub(/^["\x27]|["\x27]$/, ""); print; exit }'
}

# True if file has a level-2 heading matching $2 exactly (case-insensitive).
has_h2() {
  awk -v h="$2" 'BEGIN{h=tolower(h)} /^```/{f=!f} !f && /^## /{ t=tolower(substr($0,4)); sub(/[ \t]+$/,"",t); if (t==h) {found=1; exit} } END{exit !found}' "$1"
}

summary() {
  echo
  if [ "$ERRORS" -eq 0 ]; then
    printf '%sResult: PASS%s (%d warning(s)). Structural checks only — not proof of architectural correctness.\n' "$C_GRN" "$C_OFF" "$WARNINGS"
    return 0
  else
    printf '%sResult: FAIL%s — %d error(s), %d warning(s).\n' "$C_RED" "$C_OFF" "$ERRORS" "$WARNINGS"
    return 1
  fi
}

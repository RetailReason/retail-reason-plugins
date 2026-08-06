#!/usr/bin/env bash
# leak-check.sh — every byte in this repository ships publicly. This script fails when a
# string that must stay private shows up anywhere in the repo. Run it before every commit
# (see README for the pre-commit wiring). Exits 1 on any hit.
#
# This script is excluded from its own scan (it necessarily names the forbidden patterns),
# and the private-corpus skill names are never hardcoded here — they are read at runtime
# from the corpus repo when it is present on the machine.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

# Extended-regex scan; emits file:line:match (match text only, for precise filtering).
G() { grep -rnoE --exclude-dir=.git --exclude=leak-check.sh "$1" "$REPO_DIR" 2>/dev/null || true; }
# Fixed-string scan; emits file:line:whole-line.
GF() { grep -rnF --exclude-dir=.git --exclude=leak-check.sh "$1" "$REPO_DIR" 2>/dev/null || true; }

report() { # report <label> <hits>
  if [[ -n "$2" ]]; then
    echo "LEAK [$1]:"
    echo "$2"
    echo
    FAIL=1
  fi
}

# --- Static patterns -------------------------------------------------------------------

# Corpus reference-directory fragments must never appear in public files.
report "references/ path fragment" "$(GF 'references/')"

# Wiki-link syntax is corpus-internal cross-linking.
report "wiki-link syntax [[" "$(GF '[[')"

# Corpus-repo skill paths (walmart-<anything>/skills or .../SKILL.md). The distribution
# plugin's own paths (walmart-advisor/...) are the only allowed matches.
report "corpus skill path" \
  "$(G 'walmart-[a-z0-9-]+/(skills|SKILL\.md)' | grep -v ':walmart-advisor/' || true)"

# A real-looking seat key (the documented placeholder is 'wadv_live_...', which does not
# match: the char after the prefix must be alphanumeric to count as a leak).
report "live-looking seat key" "$(G 'wadv_live_[a-z0-9]')"

# Local absolute paths reveal private machine/repo layout.
report "local absolute path" "$(G '(/Users|/home)/[A-Za-z0-9._-]+/')"

# --- Dynamic denylist: internal skill directory names ----------------------------------
# The names themselves are private, so they are never written into this script. When the
# private corpus repo is available (env var, or auto-detected as a sibling directory with
# the expected layout), its skill directory names are read at runtime and grepped for.
CORPUS="${WADV_CORPUS_REPO:-}"
if [[ -z "$CORPUS" ]]; then
  for d in "$REPO_DIR"/../*/; do
    [[ "${d%/}" == "$REPO_DIR" ]] && continue
    if compgen -G "${d}walmart-*/skills" > /dev/null 2>&1; then
      CORPUS="${d%/}"
      break
    fi
  done
fi

if [[ -n "$CORPUS" && -d "$CORPUS" ]]; then
  count=0
  while IFS= read -r skdir; do
    name="$(basename "$skdir")"
    [[ "$name" == "walmart-advisor" ]] && continue
    count=$((count + 1))
    report "internal skill name: $name" "$(GF "$name")"
  done < <(find "$CORPUS" -mindepth 3 -maxdepth 3 -type d -path "*/skills/*" -not -path "*/codex/*" | sort -u)
  echo "internal-name denylist: checked $count names from corpus repo"
else
  echo "note: corpus repo not found — internal-name denylist skipped (set WADV_CORPUS_REPO to enable)"
fi

# --- Verdict ---------------------------------------------------------------------------
if [[ "$FAIL" -ne 0 ]]; then
  echo "leak-check FAILED — remove the flagged strings before committing."
  exit 1
fi
echo "leak-check passed"

#!/usr/bin/env bash
# leak-check.sh — every byte in this repository ships publicly. This script fails when a
# string that must stay private shows up anywhere in the repo. Run it before every commit
# (see README for the pre-commit wiring).
#
#   ./scripts/leak-check.sh            # default: warn + continue if the corpus repo is absent
#   ./scripts/leak-check.sh --strict   # release/CI mode: FAIL unless the internal-name
#                                      # denylist was actually built from the corpus repo
#
# Exit codes: 0 = clean; 1 = leak found; 2 = the check itself could not run correctly
# (bad arguments, wrong repo dir, grep error, --strict without a corpus repo). A pre-commit
# hook treats any non-zero exit as a block, so harness errors fail closed instead of
# silently passing.
#
# This script is excluded from its own scan (it necessarily names the forbidden patterns),
# and the private-corpus skill names are never hardcoded here — they are read at runtime
# from the corpus repo when it is present on the machine.
#
# SCOPE NOTE (maintainers): this guard matches literal strings only — path fragments,
# wiki-link syntax, key material, machine paths, and the corpus repo's skill directory
# names. It CANNOT detect structural leaks: prose that mirrors the private skill taxonomy
# one-to-one (ordered topic lists tracking internal module boundaries) passes this scan.
# Shim and tool trigger language must stay broad and outcome-shaped (PRD §5) — enforcing
# that is a human-review step, not this script.
set -euo pipefail

STRICT=0
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    *)
      echo "leak-check ERROR: unknown argument '$arg' (supported: --strict)" >&2
      exit 2
      ;;
  esac
done

# Resolve the script's REAL location even when invoked through a symlink. The README wires
# this script as .git/hooks/pre-commit via ln -s; $BASH_SOURCE is then the hook path, and
# naively resolving ".." from it lands in <repo>/.git — where --exclude-dir=.git makes the
# scan a silent no-op that passes on any tree. Portable readlink loop (no readlink -f).
resolve_source() {
  local src="${BASH_SOURCE[0]}" dir
  while [[ -L "$src" ]]; do
    dir="$(cd -P "$(dirname "$src")" && pwd)"
    src="$(readlink "$src")"
    [[ "$src" != /* ]] && src="$dir/$src"
  done
  printf '%s\n' "$src"
}
SCRIPT_PATH="$(resolve_source)"
REPO_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")/.." && pwd)"

# Fail closed if resolution went anywhere unexpected: a scan of the wrong directory must
# never report success.
if [[ ! -f "$REPO_DIR/scripts/leak-check.sh" || ! -f "$REPO_DIR/README.md" ]]; then
  echo "leak-check ERROR: resolved repo dir '$REPO_DIR' does not look like the distribution repo" >&2
  exit 2
fi
file_count="$(find "$REPO_DIR" -type f -not -path "*/.git/*" -not -name 'leak-check.sh' | wc -l | tr -d ' ')"
if (( file_count < 5 )); then
  echo "leak-check ERROR: only $file_count files visible under '$REPO_DIR' — refusing to certify an empty scan" >&2
  exit 2
fi

FAIL=0

# grep wrapper: exit 0 (match) and 1 (no match) are both fine outcomes; >=2 is a grep
# ERROR and must abort the run — under `set -euo pipefail` a bare `|| true` would swallow
# it and let a broken scan print "passed".
run_grep() {
  local out status=0
  out="$(grep "$@" 2>&1)" || status=$?
  if (( status > 1 )); then
    echo "leak-check ERROR: grep failed (status $status): $out" >&2
    exit 2
  fi
  printf '%s' "$out"
}
# Extended-regex scan; emits file:line:match (match text only, for precise filtering).
G() { run_grep -rnoE --exclude-dir=.git --exclude=leak-check.sh -e "$1" -- "$REPO_DIR"; }
# Fixed-string scan; emits file:line:whole-line.
GF() { run_grep -rnF --exclude-dir=.git --exclude=leak-check.sh -e "$1" -- "$REPO_DIR"; }

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
  "$(G 'walmart-[a-z0-9-]+/(skills|SKILL\.md)' | { grep -v ':walmart-advisor/' || true; })"

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
    [[ "$(cd -P "${d%/}" 2>/dev/null && pwd)" == "$REPO_DIR" ]] && continue
    if compgen -G "${d}walmart-*/skills" > /dev/null 2>&1; then
      CORPUS="${d%/}"
      break
    fi
  done
fi

DENYLIST_COUNT=0
if [[ -n "$CORPUS" && -d "$CORPUS" ]]; then
  while IFS= read -r skdir; do
    name="$(basename "$skdir")"
    [[ "$name" == "walmart-advisor" ]] && continue
    DENYLIST_COUNT=$((DENYLIST_COUNT + 1))
    report "internal skill name: $name" "$(GF "$name")"
  done < <(find "$CORPUS" -mindepth 3 -maxdepth 3 -type d -path "*/skills/*" -not -path "*/codex/*" | sort -u)
fi

if (( DENYLIST_COUNT > 0 )); then
  echo "internal-name denylist: checked $DENYLIST_COUNT names from corpus repo"
elif (( STRICT )); then
  echo "leak-check ERROR (--strict): internal-name denylist could not be built — corpus repo" >&2
  echo "not found or contains no skill directories. Set WADV_CORPUS_REPO to the corpus repo path." >&2
  exit 2
else
  echo "note: corpus repo not found — internal-name denylist skipped (set WADV_CORPUS_REPO to enable; pass --strict to make this fatal)"
fi

# --- Verdict ---------------------------------------------------------------------------
if [[ "$FAIL" -ne 0 ]]; then
  echo "leak-check FAILED — remove the flagged strings before committing."
  exit 1
fi
echo "leak-check passed"

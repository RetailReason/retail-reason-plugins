#!/usr/bin/env bash
# brand-check.sh — the buyer-facing identity guard.
#
# Every file in this repository is something a paying customer reads: the marketplace
# entry, the plugin manifests, the router skill, the install docs. The product is
# Retail Reason; Walmart is named only descriptively ("for Walmart suppliers"), never as
# part of the product's own name. A previous rename reached the server (MCP serverInfo,
# /healthz) but never reached this repo, so the install path advertised a different
# product than the one the customer had bought. This script makes that class of drift
# fail loudly instead of shipping.
#
#   ./scripts/brand-check.sh
#
# Exit codes: 0 = clean; 1 = a branding/instruction defect was found; 2 = the check itself
# could not run correctly (bad arguments, wrong repo dir, grep error).
#
# This script is excluded from its own scan — it necessarily names the retired strings.
# NOTE: it is NOT excluded from leak-check.sh's scan, so keep it free of the patterns that
# guard forbids (corpus path fragments, wiki-link syntax, machine-absolute paths).
#
# What it does NOT police: machine identifiers. The marketplace id, plugin id, skill
# directory names, the MCP server key, the wadv_live_ key prefix and WADV_LICENSE_KEY are
# wire/contract values pinned by the backend test suite, not product copy. Renaming them is
# a deliberate, coordinated two-repo change — see README "Contributing / maintainers".
set -euo pipefail

if [ "$#" -gt 0 ]; then
  echo "brand-check ERROR: unknown argument '$1' (this check takes no options)" >&2
  exit 2
fi

resolve_source() {
  src="${BASH_SOURCE[0]}"
  while [ -L "$src" ]; do
    dir="$(cd -P "$(dirname "$src")" && pwd)"
    src="$(readlink "$src")"
    case "$src" in
      /*) ;;
      *) src="$dir/$src" ;;
    esac
  done
  printf '%s\n' "$src"
}
SCRIPT_PATH="$(resolve_source)"
REPO_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")/.." && pwd)"

if [ ! -f "$REPO_DIR/scripts/brand-check.sh" ] || [ ! -f "$REPO_DIR/README.md" ]; then
  echo "brand-check ERROR: resolved repo dir '$REPO_DIR' does not look like the distribution repo" >&2
  exit 2
fi

PRODUCT="Retail Reason"
FAIL=0

run_grep() {
  out=""
  status=0
  out="$(grep "$@" 2>&1)" || status=$?
  if [ "$status" -gt 1 ]; then
    echo "brand-check ERROR: grep failed (status $status): $out" >&2
    exit 2
  fi
  printf '%s' "$out"
}

# Case-insensitive extended-regex scan of the whole repo; emits file:line:whole-line.
scan() { run_grep -rniE --exclude-dir=.git --exclude=brand-check.sh -e "$1" -- "$REPO_DIR"; }

report() { # report <label> <hits>
  if [ -n "$2" ]; then
    echo "BRAND [$1]:"
    echo "$2"
    echo
    FAIL=1
  fi
}

# --- 1. The retired product name must not appear anywhere -------------------------------
# "Walmart Advisory Service" / "Walmart advisory client" was the working title. It is also
# the shape of name the trademark posture rules out: Walmart may describe who the product
# serves, never lead the product's own name.
report "retired product name (Walmart-led)" "$(scan 'walmart +advisory')"

# A heading or a UI display name that presents the product as "Walmart Advisor" is the same
# problem in a different place. Descriptive prose about a human Walmart advisor is fine.
report "Walmart-led product name in a heading" "$(scan '^#+ .*walmart +advisor( |$)')"
report "Walmart-led product name in a manifest display field" \
  "$(scan '"(displayName|shortDescription|title)": *"[^"]*walmart +advisor')"

# --- 2. Every buyer-facing surface must name the product --------------------------------
SURFACES="
README.md
codex/README.md
codex/config-snippet.toml
.claude-plugin/marketplace.json
plugins/walmart-advisor/.claude-plugin/plugin.json
codex/plugins/walmart-advisor/.codex-plugin/plugin.json
plugins/walmart-advisor/skills/walmart-advisor/SKILL.md
codex/plugins/walmart-advisor/skills/walmart-advisor/SKILL.md
"
missing=""
for rel in $SURFACES; do
  f="$REPO_DIR/$rel"
  if [ ! -f "$f" ]; then
    echo "brand-check ERROR: expected buyer surface is missing: $rel" >&2
    exit 2
  fi
  if ! grep -qF "$PRODUCT" "$f"; then
    missing="$missing$rel: never names the product \"$PRODUCT\"
"
  fi
done
report "buyer surface does not name the product" "$missing"

# --- 3. Install instructions must match what actually ships -----------------------------
# The shipped Server URL / config-snippet url is the PRODUCTION endpoint. Any copy telling
# a paying seat that the shipped value is a local-development placeholder, or that a real
# endpoint arrives later with their subscription, is a guaranteed support ticket.
report "stale 'this default is for local dev' instruction" "$(scan 'for local development')"
report "stale 'endpoint arrives with your subscription' instruction" "$(scan 'provided with your subscription')"
report "stale 'swap in the production URL' instruction" "$(scan 'swap in the production url')"

# When localhost is mentioned it must be the complete, copy-pasteable override value —
# a bare "the localhost URL" refers to something this repo does not print anywhere.
bad_localhost="$(scan 'localhost' | { grep -vF 'http://localhost:8787/mcp' || true; })"
report "localhost mentioned without the full http://localhost:8787/mcp value" "$bad_localhost"

# --- 4. No unresolved placeholders on a paid product's docs -----------------------------
report "unresolved placeholder in customer-facing docs" "$(scan '_placeholder|<repo-url-or-path>|TBD')"

# --- 5. Verdict -------------------------------------------------------------------------
if [ "$FAIL" -ne 0 ]; then
  echo "brand-check FAILED — the buyer-facing identity or install copy has drifted."
  exit 1
fi
echo "brand-check passed"

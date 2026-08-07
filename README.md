# Walmart Advisory Service — client distribution

The Walmart Advisory Service is a hosted expert service for people who operate on Walmart's
supplier and seller platforms: 1P suppliers, 3P Marketplace sellers, and the consultants and
agencies who serve them. It answers operational questions with exact specifics — metric
definitions, screen paths, thresholds, dispute channels — pitfall-checks your draft
deliverables the way a seasoned Walmart advisor would, and keeps its knowledge continuously
verified (every answer carries an `as_of` verification date).

This repository contains only the **thin clients**: a Claude Code plugin, a Codex CLI
config, and the public capability map. All expertise is delivered by the hosted service
over an authenticated MCP connection; a licensed seat key (`wadv_live_...`) is required.
Keys are per-seat — don't share them.

## Install: Claude Code

1. Add the marketplace (use this repo's URL, or a local path while developing):

   ```
   /plugin marketplace add <repo-url-or-path>
   ```

2. Install the plugin:

   ```
   /plugin install walmart-advisor@walmart-advisory
   ```

3. When prompted, enter your **license key** (`wadv_live_...`). Leave **Server URL** at its
   default for local development; set it to the production URL when it is provided with
   your subscription.

4. Restart Claude Code and ask any Walmart supplier/seller question to confirm it works.

**If the key stops working after a restart:** the key is stored in your OS keychain and can
occasionally drop. Re-enter it in the plugin's settings (`/plugin` → walmart-advisor →
configure). If it keeps happening, use the env-var fallback: set
`export WADV_LICENSE_KEY="wadv_live_..."` in your shell profile and edit the installed
plugin's `.mcp.json` to read `"Authorization": "Bearer ${WADV_LICENSE_KEY}"` — Claude Code
expands environment variables in MCP headers.

## Install: Codex CLI

See [`codex/README.md`](./codex/README.md): export `WADV_LICENSE_KEY`, paste
[`codex/config-snippet.toml`](./codex/config-snippet.toml) into `~/.codex/config.toml`, and
optionally install the thin skill plugin under `codex/plugins/`.

## Other platforms

claude.ai / ChatGPT connectors are coming in a later phase.

## The capability map (`capabilities/capabilities.json`)

This file is the curated, public description of what the service covers. **No client reads it.**
It is ingested by the hosted service, and the `get_capabilities` tool renders it per seat — so
what a user sees differs from the file in two ways:

- **Filtered to the seat.** Only the areas that seat is licensed for are rendered; a buyer is
  never shown an area they cannot use. A Charter data seat implicitly covers the Basic scope.
- **Merged and retitled.** The file is keyed by entitlement (`supplier_academy`,
  `scintilla_basic`, `scintilla_charter`, `marketplace`, `supplier_one`); the answer is grouped
  under four presented areas — **Walmart supplier fundamentals**, **Scintilla / Walmart data**,
  **Walmart Marketplace**, **Supplier One**. The two Scintilla entitlements merge into the one
  Scintilla area (plan tier is an entitlement detail, not a browsing surface), with their topics
  and example questions concatenated and de-duplicated.

Editing this file changes what every seat sees, but only once the service re-ingests the corpus —
reinstalling the plugin changes nothing. Keep entries outcome-shaped: the leak-guard below cannot
catch a topic list that mirrors internal structure.

## Support

Support contact: _placeholder — support email/portal to be announced._ Include your org
name (never your license key) when writing in.

## Contributing / maintainers

Before committing, run the leak check — it must pass:

```bash
./scripts/leak-check.sh
```

It scans every file in this repo for strings that must never ship publicly. Wire it as a
pre-commit hook (the script resolves its real location through the symlink, so any
non-zero exit — leak found *or* the check failing to run — blocks the commit):

```bash
ln -s ../../scripts/leak-check.sh .git/hooks/pre-commit
```

Two modes:

- **Default** — if the private corpus repo is not on the machine, the internal-name
  denylist is skipped with a note and the static checks still run. This is the contributor
  mode: most machines legitimately lack the corpus repo.
- **`--strict`** — fails (exit 2) unless the denylist was actually built from the corpus
  repo. Use this wherever the corpus checkout exists (Matt's machine, release checks):
  `WADV_CORPUS_REPO=path/to/corpus-repo ./scripts/leak-check.sh --strict`. A sibling
  directory with the expected layout is auto-detected when the env var is unset.

The guard matches literal strings only. It cannot catch structural leaks — prose whose
shape mirrors the private skill taxonomy one-to-one. Trigger language in `SKILL.md` and
tool descriptions must stay broad and outcome-shaped; that part is human review.

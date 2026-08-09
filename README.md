# Retail Reason — client distribution

Retail Reason is a hosted expert service for people who operate on Walmart's
supplier and seller platforms: 1P suppliers, 3P Marketplace sellers, and the consultants and
agencies who serve them. It answers operational questions with exact specifics — metric
definitions, screen paths, thresholds, dispute channels — pitfall-checks your draft
deliverables the way a seasoned Walmart advisor would, and keeps its knowledge continuously
verified (every answer carries an `as_of` verification date).

This repository contains only the **thin clients**: a Claude Code plugin, a Codex CLI
config, and the public capability map. All expertise is delivered by the hosted service
over an authenticated MCP connection; a licensed seat key (`wadv_live_...`) is required.
Keys are per-seat — don't share them.

Retail Reason is an independent product. It is not affiliated with, endorsed by, or a
product of Walmart Inc.; "Walmart" and the platform names below are used only to describe
who the service is for and what it covers.

## Install: Claude Code

1. Add the marketplace:

   ```
   /plugin marketplace add https://github.com/RetailReason/retail-reason-plugins
   ```

2. Install the plugin:

   ```
   /plugin install walmart-advisor@walmart-advisory
   ```

   (`walmart-advisor` and `walmart-advisory` are the plugin and marketplace identifiers.
   The product is Retail Reason; those ids are frozen so existing installs keep working.)

3. When prompted, enter your **license key** (`wadv_live_...`). Leave **Server URL** at its
   default — it already points at the live Retail Reason service. Change it only if you are
   running the service yourself, to `http://localhost:8787/mcp`.

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

Support is by email: **matt@startupsuccesslab.com** — a monitored mailbox, answered by the
operator directly. (Startup Success Lab is the entity behind Retail Reason; a dedicated
support address moves here when it exists.) Include your org name and roughly when the
problem happened; never include your license key.

## Contributing / maintainers

Before committing, run both guards — they must pass:

```bash
./scripts/leak-check.sh
./scripts/brand-check.sh
```

### `leak-check.sh` — what must never ship

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

### `brand-check.sh` — what the buyer is told this product is

Every file here is something a buyer reads. The rename to Retail Reason reached the server
(`serverInfo.name`, `/healthz`) without ever reaching this repo, so for a while the install
path advertised a product name the customer had never been billed for. `brand-check.sh`
fails when the retired name reappears, when a buyer-facing surface stops naming Retail
Reason, when install copy describes the shipped production endpoint as a local-development
placeholder, or when a customer-facing placeholder is left unresolved.

It deliberately does **not** police machine identifiers. The marketplace id
(`walmart-advisory`), the plugin id and skill directory (`walmart-advisor`), the MCP server
key, the `wadv_live_` key prefix and `WADV_LICENSE_KEY` are wire values pinned by the
backend's `test/distribution.test.ts`; the MCP tool names (`ask_walmart`,
`check_walmart_pitfalls`, …) are the protocol contract. Changing any of them is a
coordinated two-repo change plus a breaking change for every existing install — never a
side effect of a copy edit.

Naming rule the check encodes: the product is **Retail Reason**, and Walmart is named only
to describe who the service is for ("for Walmart suppliers") — never as part of the
product's own name, in a heading, or in a manifest display field.

## Endpoint

The plugin ships pointing at the production service:

    https://mcp.retailreason.com/mcp

The MCP endpoint has its own host, separate from `api.retailreason.com` (reserved for the
account/billing REST API): the two have different authentication, rate limits and abuse
profiles, and separating them keeps those policies independent.

To run against a local backend instead, set the plugin's **Server URL** config value to
`http://localhost:8787/mcp` (Claude Code prompts for it at install; Codex reads it from
`config-snippet.toml`). The license key is unchanged either way.

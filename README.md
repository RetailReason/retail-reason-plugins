# Retail Reason — client distribution

Retail Reason is a hosted expert service for people who operate on Walmart's
supplier and seller platforms: 1P suppliers, 3P Marketplace sellers, and the consultants and
agencies who serve them. It answers operational questions with exact specifics — metric
definitions, screen paths, thresholds, dispute channels — pitfall-checks your draft
deliverables the way a seasoned Walmart advisor would, and keeps its knowledge continuously
verified (every answer carries an `as_of` verification date).

This repository contains only the **thin clients**: a Claude Code plugin, a Codex CLI
config, and the public capability map. All expertise is delivered by the hosted service
over an authenticated MCP connection; a user-bound access key (`wadv_live_...`) is required
for Claude Code and Codex.
Keys are bound to one named user and Retail Reason account — do not share them. Each named
user may keep at most two keys active so rotation can overlap; every key expires within 180 days
and can be revoked sooner by the user or an account owner/admin.

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

3. When prompted, enter a **Retail Reason access key** (`wadv_live_...`) from your account's
   key-management screen. This repository cannot issue a key and deliberately does not name
   an account URL before that surface passes launch acceptance. Leave **Server URL** at its
   shipped value. Change it only if you are running the service yourself, to
   `http://localhost:8787/mcp`.

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

## Hosted Claude and ChatGPT

Hosted Claude and ChatGPT are launch clients, but they do not use the CLI key above. They
connect through Retail Reason's WorkOS-backed OAuth flow from the account application after
each hosted path passes launch acceptance. Follow the in-account connection instructions;
do not paste a `wadv_live_...` key into either hosted client. This repository intentionally
does not invent a connector URL or claim that an unaccepted path is live.

## Key and workspace management

- Create a separate key for each named user; never reuse an owner, advisor, or client-guest
  key for another person.
- A user may have two active keys at once for overlap during rotation. Create the replacement,
  update Claude Code/Codex, verify it, then revoke the old key. Keys expire after at most 180
  days even if they are not rotated manually.
- Users can revoke their own keys. Account owners/admins can revoke any key in their account.
  Revocation is the first response to a copied, exposed, or lost key.
- Operator accounts normally have one workspace. Advisor users with more than one available
  client workspace select the workspace for each conversation; the client passes its
  `workspace_id` on every workspace-sensitive call, including `get_capabilities`, questions,
  and pitfall checks. A client guest is limited to the one workspace assigned by the Advisor
  Practice or Advisor Network account.

## The capability map (`capabilities/capabilities.json`)

This file is the curated, public description of what the service covers. **No client reads it.**
It is ingested by the hosted service, and the `get_capabilities` tool renders the same four
subject domains for every paid plan. A workspace's verified Scintilla tier changes which guidance
is applicable to that workspace; it does not remove a commercial subject domain. The response is:

- **Merged and retitled.** The file is keyed internally (`supplier_academy`,
  `scintilla_basic`, `scintilla_charter`, `marketplace`, `supplier_one`); the answer is grouped
  under four presented areas — **Walmart supplier fundamentals**, **Scintilla / Walmart data**,
  **Walmart Marketplace**, **Supplier One**. The two Scintilla source sets merge into the one
  Scintilla area, with topics and example questions concatenated and de-duplicated.

Editing this file changes what paid users see, but only once the service re-ingests the corpus —
reinstalling the plugin changes nothing. Keep entries outcome-shaped: the leak-guard below cannot
catch a topic list that mirrors internal structure.

## Support

Support is by email: **matt@startupsuccesslab.com** — a monitored mailbox, answered by the
operator directly. (Startup Success Lab is the entity behind Retail Reason; a dedicated
support address moves here when it exists.) Include your org name and roughly when the
problem happened; never include your access key.

## Contributing / maintainers

Before committing, run both guards — they must pass:

```bash
./scripts/leak-check.sh
./scripts/brand-check.sh
```

Clean-clone CI validates every shipped JSON file and runs the branding and static leak
guards on every pull request and `main` push. Because that public CI checkout cannot read
the private corpus repository, a release still requires a separately recorded successful
`leak-check.sh --strict` run against the exact corpus source checkout.

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

The plugin ships with this MCP endpoint configured:

    https://mcp.retailreason.com/mcp

The endpoint has its own host, separate from the account/billing API. Access still requires
an active account and user-bound key; the endpoint being reachable is not evidence that a
customer's launch provisioning path has passed acceptance.

To run against a local backend instead, set the plugin's **Server URL** config value to
`http://localhost:8787/mcp` (Claude Code prompts for it at install; Codex reads it from
`config-snippet.toml`). The access key is unchanged either way.

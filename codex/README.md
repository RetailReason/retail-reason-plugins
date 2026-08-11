# Retail Reason — Codex CLI setup

Retail Reason is a hosted expert service for people who operate on Walmart's supplier and
seller platforms. Two pieces to set up: the MCP server config (required) and an optional
thin skill plugin that teaches the model when and how to use the service.

## 1. MCP server (required)

1. Put your seat key in the environment (shell profile or session) **before** launching Codex:

   ```bash
   export WADV_LICENSE_KEY="wadv_live_..."
   ```

2. Append the contents of [`config-snippet.toml`](./config-snippet.toml) to
   `~/.codex/config.toml`:

   ```toml
   [mcp_servers.walmart_advisor]
   url = "https://mcp.retailreason.com/mcp"
   bearer_token_env_var = "WADV_LICENSE_KEY"
   tool_timeout_sec = 360
   ```

   Keep the 360-second tool timeout during the initial launch. A request can legitimately use a
   provider retry and one output-guard regeneration, which can outlast Codex's shorter default.
   This is a temporary compatibility bridge: revisit it after production latency data supports
   a lower end-to-end service deadline.

3. Paste the `url` exactly as shipped — it is the live Retail Reason production endpoint,
   and nothing further is issued with your subscription except the seat key you already
   have. Change it only if you are running the service yourself, to
   `http://localhost:8787/mcp`.

4. Restart Codex and confirm the server is listed (`codex mcp list` or the equivalent in
   your version).

Troubleshooting: a connection that never authenticates usually means `WADV_LICENSE_KEY`
was not set in the environment Codex launched from. An HTTP 401 or 403 means the server was
reached but rejected the key — check for typos, an expired/rotated key, or a key issued for
a different Retail Reason environment than the `url` above points at.

## 2. Thin skill plugin (optional, recommended)

The plugin under [`plugins/walmart-advisor/`](./plugins/walmart-advisor/) mirrors the Claude
Code plugin: a single routing skill that tells the model to check capabilities at session
start, route questions to the right tool, and pitfall-check drafts before finalizing.
Install it the way your Codex version installs local plugins (point it at the
`plugins/walmart-advisor` directory of your clone of
`https://github.com/RetailReason/retail-reason-plugins`).

The skill contains no knowledge content — everything substantive is served by the hosted
Retail Reason service against your seat's license.

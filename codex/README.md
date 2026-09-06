# Retail Reason — Codex CLI setup

Retail Reason is a hosted expert service for people who operate on Walmart's supplier and
seller platforms. Two pieces to set up: the MCP server config (required) and an optional
thin skill plugin that teaches the model when and how to use the service.

## 1. MCP server (required)

1. Create a user-bound access key in Retail Reason account key management, then put it in the
   environment (shell profile or session) **before** launching Codex:

   ```bash
   export WADV_LICENSE_KEY="wadv_live_..."
   ```

2. Append the contents of [`config-snippet.toml`](./config-snippet.toml) to
   `~/.codex/config.toml`:

   ```toml
   [mcp_servers.retail_reason]
   url = "https://mcp.retailreason.com/mcp"
   bearer_token_env_var = "WADV_LICENSE_KEY"
   tool_timeout_sec = 360
   ```

   Keep the 360-second tool timeout during the initial launch. A request can legitimately use a
   provider retry and one output-guard regeneration, which can outlast Codex's shorter default.
   This is a temporary compatibility bridge: revisit it after production latency data supports
   a lower end-to-end service deadline.

3. Paste the `url` exactly as shipped — it is the live Retail Reason production endpoint,
   and the repository cannot issue an access key. Change it only if you are running the service yourself, to
   `http://localhost:8787/mcp`.

4. Restart Codex and confirm the server is listed (`codex mcp list` or the equivalent in
   your version).

Troubleshooting: a connection that never authenticates usually means `WADV_LICENSE_KEY`
was not set in the environment Codex launched from. An HTTP 401 or 403 means the server was
reached but rejected the key — check for typos, an expired/rotated key, or a key issued for
a different Retail Reason environment than the `url` above points at.

Key rules: one user per key, no more than two active keys per named user, and a maximum
180-day lifetime. Rotate by creating the replacement, updating this environment variable,
restarting and verifying Codex, then revoking the old key. Revoke an exposed or lost key
immediately; an account owner/admin can revoke any key in the account.

For an advisor account, choose the client workspace at the start of the conversation. The
Retail Reason routing skill calls `list_workspaces`; when more than one is available it asks
for the intended workspace and passes that `workspace_id` on every workspace-sensitive call,
including `get_capabilities`, questions, and pitfall checks. A client guest sees only the
workspace assigned by an Advisor Practice or Advisor Network account.

## 2. Thin skill plugin (optional, recommended)

The plugin under [`plugins/retail-reason/`](./plugins/retail-reason/) mirrors the Claude
Code plugin: a single routing skill that tells the model to check capabilities at session
start, route questions to the right tool, and pitfall-check drafts before finalizing.
Install it the way your Codex version installs local plugins (point it at the
`plugins/retail-reason` directory of your clone of
`https://github.com/RetailReason/retail-reason-plugins`).

The skill contains no knowledge content — everything substantive is served by the hosted
Retail Reason service under the caller's account, user, workspace, and plan entitlements.

# Walmart Advisory Service — Codex CLI setup

Two pieces: the MCP server config (required) and an optional thin skill plugin that teaches
the model when and how to use the service.

## 1. MCP server (required)

1. Put your seat key in the environment (shell profile or session) **before** launching Codex:

   ```bash
   export WADV_LICENSE_KEY="wadv_live_..."
   ```

2. Append the contents of [`config-snippet.toml`](./config-snippet.toml) to
   `~/.codex/config.toml`:

   ```toml
   [mcp_servers.walmart_advisor]
   url = "http://localhost:8787/mcp"
   bearer_token_env_var = "WADV_LICENSE_KEY"
   ```

3. Leave the `localhost` URL for local development; replace it with the production URL when
   it is provided with your subscription.

4. Restart Codex and confirm the server is listed (`codex mcp list` or the equivalent in
   your version).

Troubleshooting: a connection that never authenticates usually means `WADV_LICENSE_KEY`
was not set in the environment Codex launched from. An HTTP 401 means the server was
reached but rejected the key — check for typos or an expired/rotated key.

## 2. Thin skill plugin (optional, recommended)

The plugin under [`plugins/walmart-advisor/`](./plugins/walmart-advisor/) mirrors the Claude
Code plugin: a single routing skill that tells the model to check capabilities at session
start, route questions to the right tool, and pitfall-check drafts before finalizing.
Install it the way your Codex version installs local plugins (point it at the
`plugins/walmart-advisor` directory).

The skill contains no knowledge content — everything substantive is served by the hosted
service against your seat's license.

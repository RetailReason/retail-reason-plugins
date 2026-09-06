# MCP Registry entry

`server.json` is the entry for the official MCP Registry (registry.modelcontextprotocol.io),
the upstream that Glama, PulseMCP, and other directories mirror. It describes the remote
server only; it ships no code and grants no access. A paid plan is still required to use it.

## Publish (founder-run; needs the namespace proof and the CLI)

1. Install the publisher CLI (`mcp-publisher`, from the registry project's releases).
2. Prove the `com.retailreason` namespace with a DNS TXT record on retailreason.com. Generate an
   Ed25519 key pair on your own machine and keep the private key in the credential store:

   ```bash
   openssl genpkey -algorithm Ed25519 -out mcp-registry.pem
   PUBLIC_KEY="$(openssl pkey -in mcp-registry.pem -pubout -outform DER | tail -c 32 | base64)"
   echo "v=MCPv1; k=ed25519; p=${PUBLIC_KEY}"   # add this as a TXT record on the apex
   ```

   Then `mcp-publisher login dns --domain retailreason.com --private-key mcp-registry.pem`.
   (The HTTP alternative serves the same line at `/.well-known/mcp-registry-auth` on
   retailreason.com; that file would need to be registered in the site's release allowlist.)
3. From this directory: `mcp-publisher publish`.
4. Verify: `curl "https://registry.modelcontextprotocol.io/v0.1/servers?search=com.retailreason"`.

## Keep it current

Registry versions are immutable. Bump `version` here whenever the server's `serverInfo.version`
or the description changes, republish, and record the listing in the service RUNBOOK's public
listing versions section. Today `serverInfo.version` is 0.1.0.

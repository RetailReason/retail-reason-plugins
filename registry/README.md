# MCP Registry entry

`server.json` describes the remote Retail Reason Intelligence server for the official
[MCP Registry](https://registry.modelcontextprotocol.io/). Downstream directories can
consume the registry; publication does not guarantee that every directory lists it.
The linked public repository contains the thin clients, not the hosted server's source.
This entry ships no code and grants no access.

An active paid Retail Reason plan is required. Hosted Claude uses OAuth sign-in.
Claude Code and Codex CLI send a personal access key. Retail Reason answers questions
and checks drafts; it never connects to retailer accounts and is independent of Walmart Inc.
See the [connection instructions](https://retailreason.com/docs/connect/) for current setup.

## Validate before publication

The description is limited to 100 characters by the pinned upstream schema. CI validates
the complete entry against `server.schema.json`, a retained copy of the
[2025-12-11 MCP schema](https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json).
When adopting a newer schema, review and replace that copy and the `$schema` value together.

```bash
npm exec --yes --package ajv-cli@5.0.0 --package ajv-formats@3.0.1 -- ajv validate --spec=draft7 --strict=false --all-errors -c ajv-formats -s registry/server.schema.json -d registry/server.json
```

## Publish (owner action)

1. Install `mcp-publisher` from the official registry project's releases and inspect its
   help for the installed version. Use the [publication quickstart](https://modelcontextprotocol.io/registry/quickstart).
2. Authenticate ownership of `com.retailreason` with the owner's existing namespace proof
   and private key, following the [official authentication instructions](https://modelcontextprotocol.io/registry/authentication).
   The documented DNS command's `--private-key` argument takes the extracted private-key
   value, **not a PEM filename**. Handle this privately with shell tracing disabled. Never
   put private-key bytes in chat, shell history, logs, source files, or this repository.
   Generating a new key, changing DNS, or adding the HTTP proof file is a separate owner
   action. The HTTP proof file would also require the site's release allowlist entry.
3. Confirm the intended name and version are not already published. Registry search is
   read-only: `curl --max-time 30 "https://registry.modelcontextprotocol.io/v0.1/servers?search=com.retailreason"`.
4. From `registry/`, the owner runs `mcp-publisher publish` and retains the successful
   result. Verify the listing through the same search endpoint.

No repository check logs in, generates a key, changes DNS, or publishes the entry.

## Keep it current

The prepared entry is version `0.1.0`, matching the reviewed service's `serverInfo.version`.
The September 7, 2026 registry search returned no `com.retailreason` entry, so this remains
the first-publication candidate. Recheck before publishing: registry versions are immutable.
After publication, any changed entry needs a new version. Coordinate that version with the
service release, then record the published listing and version in the service runbook.

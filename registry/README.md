# MCP Registry entry

`server.json` describes the remote Retail Reason Intelligence server for the official
[MCP Registry](https://registry.modelcontextprotocol.io/). Downstream directories can
consume the registry; publication does not guarantee that every directory lists it.
The linked public repository contains the thin clients, not the hosted server's source.
This entry ships no code and grants no access.

An eligible Retail Reason account with active paid or trial access is required.
Hosted Claude, including Claude Cowork, uses OAuth sign-in.
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
2. Authenticate ownership of `com.retailreason` with matching domain proof and a private
   key, following the [official authentication instructions](https://modelcontextprotocol.io/registry/authentication).
   Check whether that proof and its key exist before treating publication as ready.
   If either is missing, prepare the ownership setup for the owner's approval first.
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

## Published entry and future updates

`com.retailreason/intelligence` version `0.1.0` was published on September 11, 2026
at 23:16:17 UTC. The official registry returned it as active, with the approved
name, title, description, repository, endpoint, and authentication guidance.
[Read the published entry](https://registry.modelcontextprotocol.io/v0.1/servers/com.retailreason%2Fintelligence/versions/0.1.0).

The public domain-ownership TXT proof is configured. The matching signing key is
held by the owner in Mac Keychain. Publication used the official registry API,
with its authentication token kept in memory. The standard publisher CLI stores
its token in a local file; choose the API workflow when credential policy does
not allow that storage.

The registry omits `isRequired: false` from its response because false is the
schema default. The retained entry sets it explicitly; both representations
leave the personal-key header optional so hosted OAuth remains supported.

Do not publish version `0.1.0` again. Registry versions are immutable. Review any
future metadata change, select a new version, verify the current ownership proof,
and record the resulting publication. The published entry's version matches the
reviewed service's `serverInfo.version`.

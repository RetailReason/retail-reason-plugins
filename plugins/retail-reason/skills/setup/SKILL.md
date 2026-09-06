---
name: setup
description: "Set up or repair the Retail Reason connection for this plugin: where to create the user-bound access key, how to enter it, how to confirm the connection works, and what an authorization error means. Use when the walmart-advisor plugin was just installed, when a Retail Reason tool call fails with an authorization or key error, or when the user asks how to connect Retail Reason."
---

# Retail Reason setup

This plugin is a thin client. Every answer comes from the hosted Retail Reason service over an
authenticated MCP connection, so the only setup is the key that identifies the user.

## Before you start

- An active paid Retail Reason plan is required. There is no trial; the first purchase carries a
  seven-day refund under the published terms. Plans and purchase: https://retailreason.com/pricing/
- Keys are bound to one named user and one Retail Reason account. Never share a key between
  people, and never paste one into a chat, a file, or a repository.

## Steps

1. **Create a personal access key.** Sign in at https://app.retailreason.com/app/access and create a
   key. It is shown once and starts with `wadv_live_`. Copy it to the clipboard.
2. **Enter the key in the plugin.** When Claude Code prompts for the plugin's **Access key**, paste
   it. Leave **Server URL** at its shipped value, `https://mcp.retailreason.com/mcp`. Change the URL
   only if the user is running the service locally.
3. **Restart Claude Code**, then ask a Walmart supplier or seller question. A working connection
   returns an answer with an `as_of` verification date.
4. **Advisor accounts** with more than one client workspace are asked which workspace the
   conversation concerns; the routing skill handles that on every workspace-sensitive call.

## If it does not work

- **Authorization or key error.** The key was rejected: check for a typo, an expired or revoked key,
  or a key issued for a different Retail Reason environment. Rotate at
  https://app.retailreason.com/app/access (two keys may be active per user during rotation; every
  key expires within 180 days).
- **Key disappears after a restart.** The key lives in the OS keychain and can occasionally drop.
  Re-enter it under the plugin's settings, or use the environment-variable fallback described in
  the repository README.
- **Still stuck.** Email matt@retailreason.com with the account name, the client in use, and roughly
  when it happened. Never include the key.

Current, maintained setup instructions for every supported client: https://retailreason.com/docs/connect/

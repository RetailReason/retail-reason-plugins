---
name: setup
description: "Set up or repair Retail Reason in Claude Code or Cowork. Use when the plugin was installed, a connection or authorization error occurs, or the user asks how to connect. Claude Code uses a personal access key; Cowork uses Retail Reason account sign-in."
---

# Retail Reason setup

This plugin connects to the hosted Retail Reason service. An eligible account with active access
is required. First identify whether the user is in Claude Code or Cowork, then follow that client's
setup. The service address is https://mcp.retailreason.com/mcp.

## Claude Code

1. Sign in at https://app.retailreason.com/app/access and create a personal access key for Claude
   Code. It is shown once and starts with `wadv_live_`.
2. Enter it in the plugin's protected **Access key** setting. The service address is already
   included in the plugin.
3. Restart Claude Code and ask a supplier or seller question using Retail Reason. Confirm an
   actual service response with an `as_of` verification date.

Keys belong to one named user and account. Never share them or paste them into chat, a file, or a
repository. Each user may keep two active keys during rotation; every key expires within 180 days.
If a key is rejected, check expiration, revocation and the environment, then rotate it through the
account app if needed. If a saved key disappears, re-enter it in the protected plugin settings.

## Claude Cowork

1. Open **Customize → Plugins → Retail Reason → Connectors** and choose **Connect** for
   `retail-reason`. The address should be https://mcp.retailreason.com/mcp.
2. Keep **Sign in now** and **Use Claude's published identity** selected, then add the connector.
   Choose **Connect** if sign-in has not opened.
3. Sign in with the identity that holds the user's active Retail Reason membership. Cowork does
   not use the Claude Code access key. Do not add that key as a request header.
4. Start a new Cowork task and ask a supplier or seller question using Retail Reason. Confirm an
   actual service response with an `as_of` verification date.

If the address contains an unresolved placeholder or the Skills tab is missing `walmart-advisor`,
update the marketplace and plugin. An installed plugin alone does not prove the service connection
works. For an authorization failure, retain the displayed support reference and explain that the
connection has not succeeded. Do not switch authentication methods to bypass an access failure.

## Workspace and support

Call `list_workspaces` before choosing a workspace. If several are available, ask which one this
conversation concerns. Follow the advisory skill's workspace rules on every relevant tool call.

Email matt@retailreason.com with the client, account name, approximate time and any support reference
if setup remains blocked. Never include keys, tokens or passwords.

Maintained setup guide: https://retailreason.com/docs/connect/

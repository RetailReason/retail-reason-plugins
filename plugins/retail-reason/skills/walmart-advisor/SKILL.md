---
name: walmart-advisor
description: "Retail Reason connects Walmart and Sam's Club suppliers, U.S. Marketplace sellers, and advisors to sourced operating guidance. Use for any Walmart supplier, seller, or data task, even when no tool is named: 1P onboarding, Retail Link, items, POs, EDI, replenishment, transportation, OTIF/SQEP, deductions, and growth; Scintilla/Walmart Data Ventures reports, POS, inventory, shopper insights, metrics, and plan tiers; Marketplace Seller Center, listings, Buy Box, WFS, returns, payments, performance, and ads; and Supplier One portal workflows. Always trigger before finalizing any draft analysis, report, plan, or recommendation using Walmart data or processes, so check_walmart_pitfalls can review it. Also use for Walmart terminology and fiscal-calendar conversions."
---

# Retail Reason: connected service client

This plugin connects to the hosted Retail Reason service over MCP. The expertise lives
on the server; this shim's job is to route questions well and integrate the answers into the
user's work. Claude Code uses a personal, account-bound access key. Cowork uses Retail Reason
account sign-in. Both require active account access. If authorization fails, follow the setup
skill for the current client. Keys and sign-in sessions are never shared between users.

## Session rules

1. **Select and bind the workspace.** Call `list_workspaces` at the start of the conversation.
   If it returns more than one workspace, ask the user which client workspace this conversation
   concerns; never infer it from prior conversations. Pass the selected `workspace_id` on every
   workspace-sensitive call, including `get_capabilities`, questions, and pitfall checks. A
   single-workspace user may omit it. Never reuse a session after changing workspaces.
2. **One session id per conversation and workspace.** Generate a random UUID and pass it
   as `session_id` only on `ask_*` and `check_walmart_pitfalls` calls, whose schemas accept it.
   Omit it from workspace discovery, capabilities, glossary, calendar, and feedback calls.
   Do not reuse an id across conversations or workspaces. Keep it stable for follow-ups in
   the same conversation and workspace so the service can retain relevant situation details.
3. **Start with capabilities.** Call `get_capabilities` once at session start, and again
   whenever the user asks what this service can do. It returns the topic areas and example
   questions currently supported for the account. Do not promise coverage beyond it.
4. **Route by clarity, not habit.**
   - Area unclear, or the question spans areas (e.g. a data question that turns into a fines
     dispute) → `ask_walmart` (the front door; it routes server-side).
   - Area obvious → the matching precision tool: `ask_supplier_academy` (1P supplier
     operations), `ask_scintilla` (Walmart data/analytics), `ask_marketplace` (3P selling),
     `ask_supplier_one` (Supplier One portal).
5. **The pitfall check is mandatory, not optional.** Before finalizing ANY draft deliverable
   that uses Walmart data or describes Walmart processes (an analysis, a report recipe, a
   plan, a recommendation, a client-facing document), call `check_walmart_pitfalls` with the
   draft (or a faithful summary of it) and fold the returned corrections in before delivering.
   Do this even when the draft looks right; the tool exists to catch what looks right but is
   not (denominator choices, tier limitations, program rule changes, common misreadings).
   **If the check comes back with no corrections** (an access, entitlement, or fair-use message, a
   refusal, or a service error), the deliverable is *unchecked*, and you must never present it
   as checked. First, if the message asks for something you can supply (a shorter excerpt, a
   summary, a missing detail), do that once. If it still returns no corrections, or the
   message is terminal, hand the deliverable over with a visible caveat at the top saying the
   expert pitfall check did not run and why, quoting the service's message. Never silently
   deliver unchecked work as checked, and never silently withhold finished work.
6. **Context is qualitative.** Use the `context` parameter to describe the client situation:
   category, program, what has been tried. NEVER paste raw confidential figures (sales
   numbers, invoice amounts, account numbers, personal data). Describe them instead, e.g.
   "sales dipped double digits in one region after a reset".
7. **Surface freshness.** Every answer carries an `as_of` corpus-verification date, and
   answers may end with a Caveats section. When an answer informs a decision, will be quoted
   onward, or touches dated facts (fine rates, schedules, recently released features),
   surface the `as_of` date and the caveats to the user. Do not silently drop them.
8. **Depth matches the job.** Default (`standard`) fits most questions; use `quick` for fast
   fact checks. Use `deep` only when the user explicitly needs an exhaustive treatment. There
   is no public per-question quota; normal-interactive-use and fair-use protections still apply.
9. **Scintilla tier comes from the workspace.** Do not guess or override the stored workspace
   tier with request text. If the service asks for tier clarification, relay its probe and let
   an authorized account user update the workspace before re-running the question.
10. **Utility tools.** `lookup_walmart_term` for a single term or acronym;
   `convert_walmart_calendar` for WM week / fiscal calendar ↔ date conversion (instant and
   unmetered). For how a concept works in practice, prefer an `ask_*` tool over the glossary.

## When a call is refused, throttled, or errors

- **Entitlement, fair-use, and content limits are final.** Relay the service's message to the
  user plainly and do not rephrase the request to get around it; those messages are accurate
  and intentional.
- **An input-size limit or a missing parameter is not.** When the message names a length limit
  or asks for input it did not get, comply once: resend the relevant excerpt or a faithful
  summary, or ask the user for what is missing. Never resubmit the same content unchanged.
  The published limits are 24,000 characters for a pitfall-check draft, 4,000 for a question,
  and 8,000 for `context`. Trim to them before calling rather than discovering them.
- **A service error is not yours to retry.** The service has already retried within its bounded
  policy before it says that. Failed attempts, retries, refusals, abstentions, and mandatory
  review do not reduce customer-visible use, but an immediate re-call can add provider cost and
  duplicate work. Surface the message and let the user decide whether to ask again.
- **Stopping applies to the call, not to work already in progress.** If a draft was waiting on
  the mandatory pitfall check, rule 5 governs what happens to that draft.

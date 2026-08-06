---
name: walmart-advisor
description: "Connected Walmart advisory service — use for ANY Walmart supplier, seller, or Walmart-data task, even when the user does not name a tool. Covers: operating as a Walmart 1P supplier (becoming a supplier, onboarding, Retail Link and supplier systems, item setup, EDI, replenishment and forecasting, transportation, supply-chain compliance — OTIF, chargebacks, fines, disputes — invoices, deductions, getting paid, merchandising and growth programs, Sam's Club, Direct Import); interpreting or extracting Walmart's supplier-facing data (Scintilla / Walmart Data Ventures — POS and inventory analytics, report building, dashboards, shopper behavior, customer research, metric definitions, instock/OOS diagnosis, data integrations and APIs); selling on Walmart Marketplace as a 3P seller (Seller Center, onboarding, listings and listing quality, pricing and Buy Box, WFS fulfillment, orders and returns, payments and fees, performance standards, advertising, Marketplace APIs); and working in the Supplier One portal (navigation, items, orders, payments, performance, step-by-step actions). Also trigger when: reviewing or finalizing any draft analysis, report, plan, or client deliverable that uses Walmart data or describes Walmart processes (mandatory pitfall check); converting Walmart fiscal-calendar dates (WM week, WMYYWW, fiscal quarters); or looking up a Walmart term or acronym."
---

# Walmart Advisor — connected service client

This skill pairs with the `walmart_advisor` MCP server (configured in `config.toml` — see
this repo's `codex/README.md`). The expertise lives on the hosted service; this skill's job
is to route questions well and integrate the answers into the user's work. A licensed seat
key is required — if calls fail with an authorization error, check that `WADV_LICENSE_KEY`
was set in the environment Codex launched from.

## Session rules

1. **One session id per conversation.** Generate a single random UUID at the start of the
   conversation and pass it as `session_id` on every tool call. Do not reuse an id across
   conversations, and do not generate a new one mid-conversation — the service uses it to
   keep context (resolved plan tier, situation details) across follow-ups.
2. **Start with capabilities.** Call `get_capabilities` once at session start, and again
   whenever the user asks what this service can do. It returns the topic areas and example
   questions for the areas this seat is licensed for — do not promise coverage beyond it.
3. **Route by clarity, not habit.**
   - Area unclear, or the question spans areas (e.g. a data question that turns into a fines
     dispute) → `ask_walmart` (the front door; it routes server-side).
   - Area obvious → the matching precision tool: `ask_supplier_academy` (1P supplier
     operations), `ask_scintilla` (Walmart data/analytics), `ask_marketplace` (3P selling),
     `ask_supplier_one` (Supplier One portal).
4. **The pitfall check is mandatory, not optional.** Before finalizing ANY draft deliverable
   that uses Walmart data or describes Walmart processes — an analysis, a report recipe, a
   plan, a recommendation, a client-facing document — call `check_walmart_pitfalls` with the
   draft (or a faithful summary of it) and fold the returned corrections in before delivering.
   Do this even when the draft looks right; the tool exists to catch what looks right but is
   not (denominator choices, tier limitations, program rule changes, common misreadings).
5. **Context is qualitative.** Use the `context` parameter to describe the client situation —
   category, program, what has been tried. NEVER paste raw confidential figures (sales
   numbers, invoice amounts, account numbers, personal data). Describe them instead, e.g.
   "sales dipped double digits in one region after a reset".
6. **Surface freshness.** Every answer carries an `as_of` corpus-verification date, and
   answers may end with a Caveats section. When an answer informs a decision, will be quoted
   onward, or touches dated facts (fine rates, schedules, recently released features),
   surface the `as_of` date and the caveats to the user — do not silently drop them.
7. **Depth is a budget.** Default (`standard`) fits most questions; use `quick` for fast
   fact checks. Use `deep` only when the user explicitly needs an exhaustive treatment —
   deep queries draw on a limited daily allowance.
8. **Scintilla tier.** When a data question concerns a specific client, pass `client_tier`
   if known. If the response returns a `tier_probe`, ask the user the probe questions, then
   re-ask with the resolved tier — do not guess the tier.
9. **Utility tools.** `lookup_walmart_term` for a single term or acronym;
   `convert_walmart_calendar` for WM week / fiscal calendar ↔ date conversion (instant and
   unmetered). For how a concept works in practice, prefer an `ask_*` tool over the glossary.

## When a call is refused or throttled

Relay the service's message to the user plainly and stop. Do not try to rephrase around a
licensing, allowance, or content limit — those messages are accurate and intentional.

---
name: research-ticket
description: Research a Jira ticket using Atlassian MCP tools and produce a structured implementation spec saved to specs/[TICKET-KEY].md. Use when the user provides a Jira ticket number (e.g. SH-164) or a Jira URL and asks to research, spec, document, or analyze it. Requires Atlassian MCP to be configured.
disable-model-invocation: true
---

# Research Ticket

Research a Jira ticket and produce a clear implementation spec, then save it to a file.

## Prerequisites

Atlassian MCP must be configured in Cursor. See `setup/cursor-mcp.md`.

## Steps

### 1. Extract ticket key

From the user's message, extract just the ticket key (e.g. `SH-164`). Strip any URL prefix if the user provided a full URL (e.g. `https://smartdevllc.atlassian.net/browse/SH-164` → `SH-164`).

### 2. Fetch Jira ticket

Use the available Atlassian MCP tool to fetch the Jira issue with:
- `cloudId`: `070e123d-8736-4c70-adcc-b56fd6c9ac3f`
- `issueIdOrKey`: the extracted ticket key

Collect:
- **Summary** (title)
- **Description** — full content, do not truncate
- **Acceptance Criteria** — often in description or a dedicated field
- **Story Type** — Bug / Story / Task / Sub-task
- **Status**, **Priority**, **Assignee**, **Reporter**
- **Labels**, **Fix Version**, **Sprint**
- **Linked issues** — blocks / is blocked by / relates to
- **Attachments** — list filenames
- **Comments** — especially from PO/BA clarifying requirements
- **Confluence links** — any URLs in description or "Web links" field pointing to Confluence

### 3. Fetch Confluence pages (if any)

For each Confluence page URL found in step 2, extract the page ID from the URL (the numeric segment, e.g. `4555407513` from `.../pages/4555407513/...`) then use the Atlassian MCP tool to fetch the Confluence page with:
- `cloudId`: `070e123d-8736-4c70-adcc-b56fd6c9ac3f`
- `pageId`: the extracted page ID

Extract relevant sections: overview, business rules, UI specs, data flow, edge cases.
Note the page title and URL for reference.

### 4. Synthesize and save spec

Compose the full spec in markdown using the structure below, then save it to `specs/[TICKET-KEY].md` (e.g. `specs/SH-164.md`). Create the directory if it doesn't exist.

---

# Spec: [TICKET-KEY] — [Summary]

## Overview
One paragraph: what is this feature/bug/task about, why it exists, business context.

## Ticket Info
| Field | Value |
|-------|-------|
| Type | |
| Status | |
| Priority | |
| Assignee | |
| Sprint | |

## Requirements & Acceptance Criteria
List every AC item as a checkbox. If AC is missing from the ticket, derive it from the description and Confluence content. Mark derived items with `(inferred)`.

- [ ] AC 1
- [ ] AC 2
- [ ] ...

## Functional Details
Describe the expected behavior in detail:
- User flows / interactions
- Business rules and validation logic
- Edge cases and error handling
- API or data changes implied

## UI / UX Notes
If the ticket mentions screens, components, or links to designs:
- Describe the UI changes
- List affected screens/components

## Technical Context
Based on the description and Confluence:
- Affected services / modules
- Data models involved
- Integration points (APIs, external systems)
- Constraints or non-functional requirements (performance, security, etc.)

## Out of Scope
What is explicitly NOT included in this ticket.

## Open Questions
List anything ambiguous or missing that needs clarification before coding.

## References
- Jira: [TICKET-KEY](url)
- Confluence: [Page Title](url) — for each page fetched

---

After saving the file, confirm to the user: `Spec saved to specs/[TICKET-KEY].md`

## Usage

In Cursor Agent chat:
```
/research-ticket SH-164
```
or:
```
/research-ticket https://smartdevllc.atlassian.net/browse/SH-164
```

## Comparing to Claude Code Version

| Aspect | This Cursor Skill | Claude Code `/research-ticket` |
|--------|-------------------|-------------------------------|
| Invocation | `/research-ticket SH-164` (explicit only) | `/research-ticket SH-164` |
| MCP tool | Atlassian MCP via `.cursor/mcp.json` | Atlassian MCP via `~/.claude.json` |
| Output path | `specs/[KEY].md` | `specs/[KEY].md` |
| Auto-invoke | Disabled (`disable-model-invocation: true`) | N/A — always explicit |

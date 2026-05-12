Research a Jira ticket and produce a clear implementation spec, then save it to a file.

## Input
$ARGUMENTS — Jira ticket number (e.g. PROJ-123) or full URL (e.g. https://your-org.atlassian.net/browse/PROJ-123)

## Steps

### 1. Extract ticket key
From the input, extract just the ticket key (e.g. `PROJ-123`). Strip any URL prefix if provided.

### 2. Fetch Jira ticket
Use the MCP tool `mcp__atlassian__getJiraIssue` with:
- `cloudId`: `<your-cloud-id>`
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
For each Confluence page URL found in step 2, extract the page ID from the URL (the numeric segment, e.g. `4555407513` from `.../pages/4555407513/...`) then use the MCP tool `mcp__atlassian__getConfluencePage` with:
- `cloudId`: `<your-cloud-id>`
- `pageId`: the extracted page ID

Extract relevant sections: overview, business rules, UI specs, data flow, edge cases.
Note the page title and URL for reference.

### 4. Synthesize and save spec

Compose the full spec in markdown using the structure below, then use the Write tool to save it as `specs/[TICKET-KEY].md` in the project root (e.g. `specs/PROJ-123.md`). Create the `specs/` folder if it doesn't exist.

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

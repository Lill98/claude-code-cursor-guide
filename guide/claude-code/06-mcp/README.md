# MCP (Model Context Protocol)

MCP is the protocol that connects Claude to external tools and services. Instead of copy-pasting data into a prompt, Claude calls MCP tools directly — querying databases, reading GitHub PRs, fetching tickets, accessing APIs.

---

## How It Works

```
Without MCP:
  You ──copy-paste data──▶ Claude prompt ──▶ Response

With MCP:
  You ──"Review PR #42"──▶ Claude ──mcp__github__getPullRequest──▶ GitHub API
                                                                         │
                             Claude ◀──────────── PR data ───────────────┘
                               │
                               └──▶ Response (with real, current data)
```

Claude decides when to call MCP tools on its own — you do not need to specify tool names in the prompt.

---

## Configuration

MCP config lives in `~/.claude.json` — a **global file, never commit to git**:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "package-name", "optional-args"]
    }
  }
}
```

### Remote MCP (OAuth)

For hosted services that expose an MCP endpoint and use OAuth:

```json
{
  "mcpServers": {
    "your-service": {
      "command": "npx",
      "args": ["-y", "mcp-remote@latest", "https://your-service.com/mcp"]
    }
  }
}
```

`mcp-remote` is a local proxy that handles the OAuth redirect — it is not an MCP server itself. Replace the URL with the MCP endpoint of the service you're connecting to.

### Local MCP (stdio)

For local tools and databases:

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://localhost/mydb"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/dir"]
    }
  }
}
```

---

## Common MCP Servers

| Service | Package / Endpoint | Available Tools |
|---------|--------------------|-----------------|
| **Atlassian** (Jira + Confluence) | `mcp-remote@latest` → `https://mcp.atlassian.com/v1/mcp` | getJiraIssue, searchJira, getConfluencePage, createJiraIssue, ... |
| **GitHub** | `@modelcontextprotocol/server-github` | getPR, createIssue, listRepos, ... |
| **PostgreSQL** | `@modelcontextprotocol/server-postgres` | query, listTables, describe, ... |
| **Filesystem** | `@modelcontextprotocol/server-filesystem` | read, write, list (cross-project access) |
| **Slack** | `@modelcontextprotocol/server-slack` | sendMessage, listChannels, ... |
| **Notion** | via MCP registry | getPage, createPage, ... |
| **Figma** | via MCP registry | getFile, getComponent, ... |

---

## Managing MCP Servers

```bash
# List connected servers and their status
claude mcp list
# Output: atlassian: npx -y mcp-remote@latest ... - Connected

# Add a new server interactively
claude mcp add

# Remove a server
claude mcp remove server-name
```

---

## Permissions

MCP tools must be allowed in `.claude/settings.json` (project) or `~/.claude/settings.json` (global):

```json
{
  "permissions": {
    "allow": [
      "mcp__github__getPullRequest",
      "mcp__github__listIssues",
      "mcp__postgres__query",
      "mcp__postgres__listTables"
    ]
  }
}
```

Allow all tools from a single server with a wildcard:

```json
{
  "permissions": {
    "allow": ["mcp__github__*"]
  }
}
```

---

## Using MCP in Prompts

After setup, use plain natural language:

```
Review the open PRs assigned to me in the frontend repo
```

```
List all users who signed up in the last 7 days
```

```
Find all issues labeled "bug" in the backend repo, sorted by creation date
```

Claude knows when to call which MCP tool — you do not need to name the tool in the prompt.

---

## Using MCP in Skills / Commands

Combine MCP with Skills to build automated workflows:

```markdown
---
name: review-pr
description: Fetch a GitHub PR and review for security issues, missing tests, and breaking changes
disable-model-invocation: true
---

# review-pr

## Steps
1. Use mcp__github__getPullRequest to fetch the PR diff and metadata
2. Analyze for security issues, missing input validation, and breaking changes
3. Check if new code paths have corresponding tests
4. Return a structured review report with severity levels
```

→ See working example: [.claude/commands/research-ticket.md](../../.claude/commands/research-ticket.md)

---

## Non-interactive CLI Mode

Use MCP in automation, CI/CD, and scripts with the `-p` flag:

```bash
# Fetch a GitHub PR and summarize breaking changes as JSON
claude -p "Review PR #42 in owner/repo and list breaking changes as JSON array" \
  --output-format json \
  --allowedTools mcp__github__getPullRequest

# Run a security scan and save to file
claude -p "Check all TypeScript files in src/ for common security issues" \
  --output-format text \
  --allowedTools Read,Bash,Grep \
  > security-report.txt

# Use in a CI pipeline
claude -p "Review the diff in this PR for breaking changes" \
  --output-format json \
  --allowedTools Bash
```

**Useful flags:**

| Flag | Description |
|------|-------------|
| `-p "prompt"` | Non-interactive mode (single prompt, then exit) |
| `--output-format text\|json\|stream-json` | Output format |
| `--allowedTools Tool1,Tool2` | Restrict to specific tools |
| `--model claude-sonnet-4-6` | Specify model |
| `--max-turns 5` | Limit the number of agentic turns |

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `Failed to connect` | Wrong package name | Use exactly `mcp-remote@latest` |
| `File is not defined` | Node.js version too old | Upgrade Node to v20+ |
| Tools not appearing | Config not reloaded | Open a new terminal and restart `claude` |
| Browser does not open | First-time auth flow | Run `claude mcp list` in a fresh terminal |

---

## See a Real-World Example

→ [example-atlassian.md](./example-atlassian.md) — Atlassian (Jira + Confluence) full setup with OAuth

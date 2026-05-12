# Setting Up Atlassian MCP for Claude Code

Integrate Jira/Confluence into Claude Code via Atlassian's official MCP server.

---

## Prerequisites

- Claude Code installed ([installation guide](https://docs.anthropic.com/en/docs/claude-code))
- Node.js **v20+** (see Step 1)
- Atlassian Cloud account (with Jira/Confluence access)

---

## Step 1 — Install Node.js v20+

Check your current version:
```bash
node --version
```

If below v20, install via nvm:

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Reload shell
source ~/.bashrc

# Install Node 20
nvm install 20
nvm alias default 20

# Verify
node --version   # should output v20.x.x
```

> **Windows/WSL note:** Run these commands in the WSL terminal, not PowerShell.

---

## Step 2 — Add MCP Server to Claude Code Config

Open the config file:
```bash
# macOS / Linux / WSL
nano ~/.claude.json
```

Find the `"mcpServers"` section (if it doesn't exist, add it before the closing `}`) and add:

```json
"mcpServers": {
  "atlassian": {
    "command": "npx",
    "args": [
      "-y",
      "mcp-remote@latest",
      "https://mcp.atlassian.com/v1/mcp"
    ]
  }
}
```

Example of a complete `~/.claude.json` (end section):

```json
{
  "...other config...",
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote@latest",
        "https://mcp.atlassian.com/v1/mcp"
      ]
    }
  }
}
```

---

## Step 3 — Log In to Atlassian (OAuth)

Open a new terminal and run:
```bash
claude mcp list
```

Expected result:
```
atlassian: npx -y mcp-remote@latest https://mcp.atlassian.com/v1/mcp - ✓ Connected
```

**On first use** in Claude Code, the browser will automatically open for Atlassian OAuth login. After logging in and granting permissions, the token is saved automatically — no need to log in again on subsequent uses.

---

## Step 4 — Test It

Open Claude Code (`claude`) and try:

```
Fetch ticket PROJ-123 from Jira and summarize it for me
```

```
Get all Open tickets in project PROJ assigned to me
```

```
Find the Confluence page about the onboarding process
```

---

## Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| `Failed to connect` | Package doesn't exist or wrong name | Use exactly `mcp-remote@latest` + the official URL |
| `File is not defined` | Node.js < v20 | Upgrade Node to v20 (Step 1) |
| No MCP tools available | Config not reloaded | Open a new terminal and run `claude` again |
| Browser doesn't open | First-time auth not completed | Run `claude mcp list` in a new terminal |

---

## Important Notes

- **Do not use** unofficial packages like `@anthropic/mcp-server-atlassian`, `@teolin/mcp-atlassian`, etc. — these are third-party, not official Atlassian.
- **The official Atlassian MCP server** is a remote server at `https://mcp.atlassian.com/v1/mcp`, using OAuth 2.1.
- `mcp-remote` is only a local proxy to handle the OAuth redirect — it is **not** the actual MCP server.
- The OAuth token after login is stored at `~/.mcp-auth/` (automatic, no additional configuration needed).

---

## Also Using Cursor?

The OAuth token at `~/.mcp-auth/` is shared — no re-authentication needed. Just add the same `mcpServers` config to `~/.cursor/mcp.json`.

→ [Setting Up MCP for Cursor](./cursor-mcp.md)

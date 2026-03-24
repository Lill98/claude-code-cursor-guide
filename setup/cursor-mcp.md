# Setting Up MCP for Cursor

Add MCP servers to Cursor. If you already set up MCP for Claude Code, **no reinstallation or re-authentication is required** — you just point Cursor at the same servers.

---

## How Cursor Reads MCP Config

Cursor reads MCP server definitions from two locations:

| Location | Scope |
|----------|-------|
| `~/.cursor/mcp.json` | Global — applies to all projects |
| `.cursor/mcp.json` in project root | Project-level — shared with team via git |

The format is identical to Claude Code's `~/.claude.json` — same `mcpServers` key, same fields.

---

## Already Have MCP Set Up for Claude Code?

If you followed `setup/atlassian-mcp.md`, the Atlassian MCP server is already running and authenticated. You only need to add the same config to Cursor's file.

**Step 1: Open (or create) `~/.cursor/mcp.json`**

```bash
nano ~/.cursor/mcp.json
```

**Step 2: Add the same `mcpServers` block**

```json
{
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

That's it. The OAuth token stored at `~/.mcp-auth/` by `mcp-remote` is reused automatically — Cursor will connect without prompting for login again.

---

## Fresh Setup (No Claude Code MCP)

Follow these steps if you haven't set up Atlassian MCP before.

**Step 1: Ensure Node.js v20+**

```bash
node --version   # must be v20+
```

If not, see Step 1 of `setup/atlassian-mcp.md`.

**Step 2: Create `~/.cursor/mcp.json`**

```json
{
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

**Step 3: Authenticate**

Open Cursor and start the Agent. When it tries to use an Atlassian MCP tool for the first time, `mcp-remote` will open the browser for Atlassian OAuth login. After logging in and granting permissions, the token is saved at `~/.mcp-auth/` automatically.

---

## Verify the Connection

1. Open Cursor Settings (`Cmd/Ctrl + ,`)
2. Navigate to **MCP** tab
3. You should see `atlassian` listed with a green connected status

---

## Use MCP in Cursor

Once connected, use the `research-ticket` skill to fetch Jira tickets:

```
/research-ticket SH-164
```

Or ask naturally:

```
Fetch Jira ticket SH-164 and summarize the acceptance criteria
```

---

## Adding Other MCP Servers

The same pattern works for any MCP server. Add more entries under `mcpServers`:

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "mcp-remote@latest", "https://mcp.atlassian.com/v1/mcp"]
    },
    "another-server": {
      "command": "node",
      "args": ["/path/to/server.js"],
      "env": {
        "API_KEY": "${env:MY_API_KEY}"
      }
    }
  }
}
```

Supported transports: `stdio` (local) and remote servers via HTTP/SSE.

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Server not listed in MCP tab | `mcp.json` not saved or invalid JSON | Run `cat ~/.cursor/mcp.json \| python3 -m json.tool` to validate |
| `Failed to connect` | Node.js < v20 | Upgrade Node (see `setup/atlassian-mcp.md` Step 1) |
| Auth prompt on every use | Token expired | Run `npx mcp-remote@latest https://mcp.atlassian.com/v1/mcp` in terminal to re-auth |
| Tool requires approval every time | Default Cursor setting | Enable auto-run in Cursor Settings → Features → Agent |

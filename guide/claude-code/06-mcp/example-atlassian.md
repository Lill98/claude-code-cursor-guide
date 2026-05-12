# Example: Atlassian MCP Setup (Jira + Confluence)

This guide walks through connecting Claude Code to Atlassian so you can query Jira tickets and Confluence pages directly from your prompts.

---

## Prerequisites

- **Claude Code installed** — `claude --version` should work in your terminal.
- **Node.js v20 or later** — required by `mcp-remote`. Earlier versions will fail with `File is not defined`.
- **Atlassian Cloud account** — works with Jira Cloud and Confluence Cloud. Not supported on Atlassian Server/Data Center.

---

## Step 1: Install / Verify Node.js v20+

Check your current version:

```bash
node --version
# Should output: v20.x.x or higher
```

If you are on an older version, upgrade with nvm (works on macOS, Linux, and WSL):

```bash
# Install nvm (if not already installed)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Reload shell
source ~/.bashrc   # or ~/.zshrc on macOS

# Install and use Node 20
nvm install 20
nvm use 20
nvm alias default 20

# Verify
node --version    # v20.x.x
npx --version     # 10.x.x
```

---

## Step 2: Add Atlassian to `~/.claude.json`

`~/.claude.json` is your global Claude Code config. It is never committed to git.

Open or create the file and add the `mcpServers` block:

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "mcp-remote@latest", "https://mcp.atlassian.com/v1/mcp"]
    }
  }
}
```

**Important notes:**
- Use exactly `mcp-remote@latest` — this is the official OAuth proxy package from Cloudflare.
- Do not use unofficial packages like `@teolin/mcp-atlassian` or `@anthropic/mcp-server-atlassian`. The official hosted endpoint `https://mcp.atlassian.com/v1/mcp` only works with `mcp-remote`.
- If you have other MCP servers already configured, add `"atlassian": { ... }` inside the existing `"mcpServers"` object — do not create a second `"mcpServers"` key.

**Full example with multiple servers:**

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "mcp-remote@latest", "https://mcp.atlassian.com/v1/mcp"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/yourname/projects"]
    }
  }
}
```

---

## Step 3: First-Time OAuth Login

The first time Claude Code connects to Atlassian, it opens your browser for OAuth authorization.

**Trigger the login:**

```bash
claude mcp list
```

Expected output:
```
atlassian: npx -y mcp-remote@latest https://mcp.atlassian.com/v1/mcp - Connecting...
```

Your browser opens automatically with an Atlassian OAuth page. Log in with your Atlassian account and click **Allow**. The browser redirects back and shows a success page.

Back in the terminal, the status changes to:
```
atlassian: npx -y mcp-remote@latest https://mcp.atlassian.com/v1/mcp - Connected
```

**Token storage:** The OAuth token is stored at `~/.mcp-auth/` — Claude Code and Cursor both read from this directory. You will not need to log in again unless the token expires.

```
~/.mcp-auth/
  └── mcp-remote/
        └── [hashed-url]/
              ├── token.json      ← OAuth access + refresh tokens
              └── metadata.json   ← Server metadata cache
```

Do not delete this directory unless you want to force re-authorization. The tokens auto-refresh before expiry.

---

## Step 4: Allow Tools in `settings.json`

If Claude Code prompts you to allow MCP tool calls on first use, you can pre-approve them. Use `.claude/settings.local.json` for personal project settings (this file is gitignored):

**Full access (read + write):**

```json
{
  "permissions": {
    "allow": [
      "mcp__atlassian__getJiraIssue",
      "mcp__atlassian__searchJiraIssuesUsingJql",
      "mcp__atlassian__getVisibleJiraProjects",
      "mcp__atlassian__getConfluencePage",
      "mcp__atlassian__getConfluenceSpaces",
      "mcp__atlassian__getPagesInConfluenceSpace",
      "mcp__atlassian__createJiraIssue",
      "mcp__atlassian__editJiraIssue",
      "mcp__atlassian__addCommentToJiraIssue",
      "mcp__atlassian__transitionJiraIssue"
    ]
  }
}
```

**Wildcard — allow all Atlassian tools (convenient, less restrictive):**

```json
{
  "permissions": {
    "allow": ["mcp__atlassian__*"]
  }
}
```

**Read-only (recommended for shared or CI environments):**

```json
{
  "permissions": {
    "allow": [
      "mcp__atlassian__getJiraIssue",
      "mcp__atlassian__searchJiraIssuesUsingJql",
      "mcp__atlassian__getVisibleJiraProjects",
      "mcp__atlassian__getConfluencePage"
    ]
  }
}
```

---

## Step 5: Test It

Open a new Claude Code session and try these prompts:

```
What Jira projects do I have access to?
```

```
Fetch ticket PROJ-123 from Jira and summarize the acceptance criteria
```

```
Find all open tickets in project PROJ assigned to me, ordered by creation date
```

```
Get the Confluence page about our API authentication standards
```

Claude calls the Atlassian MCP tools automatically — you do not need to name the tools in the prompt.

---

## Step 6: Use with the `/research-ticket` Command

Once MCP is connected, you can use it inside Claude Code slash commands to automate ticket research.

The `/research-ticket` command in this repo fetches a Jira ticket plus any linked Confluence pages, then writes a structured spec file to `specs/[TICKET-KEY].md`.

**Run it:**

```
/research-ticket PROJ-42
```

**Or with a full URL:**

```
/research-ticket https://yourworkspace.atlassian.net/browse/PROJ-42
```

The command calls two MCP tools automatically:
1. `mcp__atlassian__getJiraIssue` — fetches the ticket (summary, description, ACs, linked issues)
2. `mcp__atlassian__getConfluencePage` — fetches each Confluence page linked in the ticket

**Finding your `cloudId`:**

The `cloudId` is a UUID that identifies your Atlassian workspace. Commands that call MCP tools directly (like `/research-ticket`) need it hardcoded.

To find it:

```bash
# Open this URL in your browser (while logged into Atlassian)
https://api.atlassian.com/oauth/token/accessible-resources
```

Or ask Claude:

```
What is my Atlassian cloudId?
```

Claude will call `mcp__atlassian__getAccessibleAtlassianResources` and return the UUID.

Once you have it, add it to your command file (`.claude/commands/research-ticket.md`):

```markdown
Use the MCP tool `mcp__atlassian__getJiraIssue` with:
- `cloudId`: `your-cloud-id-here`
- `issueIdOrKey`: the extracted ticket key
```

**Example output** — after running `/research-ticket BLOG-14`:

```
specs/BLOG-14.md saved.

# Spec: BLOG-14 — Publish Post

## Overview
Authors can promote a draft post to published state...

## Acceptance Criteria
- [ ] AC01: Only the post author or Admin can publish
- [ ] AC02: Only posts with status "draft" can be published
...
```

---

## Sharing with Cursor

If you also use Cursor, add the same config to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "mcp-remote@latest", "https://mcp.atlassian.com/v1/mcp"]
    }
  }
}
```

The OAuth token at `~/.mcp-auth/` is shared — Cursor reuses the same login session. No need to authorize again.

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `File is not defined` or `ReferenceError: File is not defined` | Node.js version < 20 | Upgrade to Node.js v20+ using nvm. Run `node --version` to confirm. |
| `Failed to connect` or `Connection refused` | Wrong package name or URL | Verify `~/.claude.json` uses exactly `mcp-remote@latest` and URL `https://mcp.atlassian.com/v1/mcp`. |
| MCP tools not appearing in Claude | Config not reloaded | Close all Claude Code terminals and open a fresh one. Re-run `claude mcp list`. |
| Browser does not open for OAuth | First-time auth needs a fresh terminal | Open a brand new terminal (not an existing Claude session), run `claude mcp list` from there. |
| `cloudId not found` in a command | cloudId not set in the command file | Find your cloudId via `https://api.atlassian.com/oauth/token/accessible-resources` and hardcode it. |
| `Permission denied` for an MCP tool | Tool not in the allow list | Add the tool name to `"allow"` in `.claude/settings.local.json`. |

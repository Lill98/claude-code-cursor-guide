# MCP (Model Context Protocol)

MCP là giao thức kết nối Claude với external tools và services. Thay vì copy-paste data vào prompt, Claude gọi MCP tools trực tiếp — query database, đọc GitHub PR, fetch ticket, access APIs.

---

## Cơ Chế Hoạt Động

```
Không có MCP:
  Bạn ──copy-paste data──▶ Claude prompt ──▶ Response

Có MCP:
  Bạn ──"Review PR #42"──▶ Claude ──mcp__github__getPullRequest──▶ GitHub API
                                                                         │
                             Claude ◀──────────── PR data ───────────────┘
                               │
                               └──▶ Response (với real, current data)
```

Claude tự biết khi nào gọi MCP tool — không cần specify tên tool trong prompt.

---

## Configuration

MCP config nằm trong `~/.claude.json` — file **global, không commit lên git**:

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

Dành cho hosted services có MCP endpoint và dùng OAuth:

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

`mcp-remote` là local proxy xử lý OAuth redirect — không phải MCP server thực sự. Thay URL bằng MCP endpoint của service bạn muốn kết nối.

### Local MCP (stdio)

Dành cho local tools và databases:

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

## MCP Servers Phổ Biến

| Service | Package / Endpoint | Tools |
|---------|--------------------|-------|
| **Atlassian** (Jira + Confluence) | `mcp-remote@latest` → `https://mcp.atlassian.com/v1/mcp` | getJiraIssue, searchJira, getConfluencePage, createJiraIssue, ... |
| **GitHub** | `@modelcontextprotocol/server-github` | getPR, createIssue, listRepos, ... |
| **PostgreSQL** | `@modelcontextprotocol/server-postgres` | query, listTables, describe, ... |
| **Filesystem** | `@modelcontextprotocol/server-filesystem` | read, write, list (cross-project) |
| **Slack** | `@modelcontextprotocol/server-slack` | sendMessage, listChannels, ... |
| **Notion** | via MCP registry | getPage, createPage, ... |
| **Figma** | via MCP registry | getFile, getComponent, ... |

---

## Quản Lý MCP Servers

```bash
# Xem servers đang connect và trạng thái
claude mcp list
# Output: atlassian: npx -y mcp-remote@latest ... - Connected

# Thêm server mới (interactive)
claude mcp add

# Xóa server
claude mcp remove server-name
```

---

## Permissions

MCP tools cần được allow trong `.claude/settings.json` (project) hoặc `~/.claude/settings.json` (global):

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

Allow tất cả tools của một server bằng wildcard:

```json
{
  "permissions": {
    "allow": ["mcp__github__*"]
  }
}
```

---

## Dùng MCP Trong Prompts

Sau khi setup, dùng bình thường bằng ngôn ngữ tự nhiên:

```
Review the open PRs assigned to me in the frontend repo
```

```
List all users who signed up in the last 7 days
```

```
Find all issues labeled "bug" in the backend repo, sorted by creation date
```

Claude tự biết khi nào gọi MCP tool nào — không cần specify tên tool trong prompt.

---

## Dùng MCP Trong Skills / Commands

Kết hợp MCP với Skills để tạo workflows tự động:

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

→ Xem working example: [.claude/commands/research-ticket.md](../../.claude/commands/research-ticket.md)

---

## Non-interactive CLI Mode

Dùng MCP trong automation, CI/CD, scripts bằng flag `-p`:

```bash
# Fetch GitHub PR và tóm tắt breaking changes dưới dạng JSON
claude -p "Review PR #42 in owner/repo and list breaking changes as JSON array" \
  --output-format json \
  --allowedTools mcp__github__getPullRequest

# Chạy security scan và lưu vào file
claude -p "Check all TypeScript files in src/ for common security issues" \
  --output-format text \
  --allowedTools Read,Bash,Grep \
  > security-report.txt

# Dùng trong CI pipeline
claude -p "Review the diff in this PR for breaking changes" \
  --output-format json \
  --allowedTools Bash
```

**Các flag hữu ích:**

| Flag | Mô tả |
|------|-------|
| `-p "prompt"` | Non-interactive mode (một prompt rồi exit) |
| `--output-format text\|json\|stream-json` | Định dạng output |
| `--allowedTools Tool1,Tool2` | Giới hạn tools được phép dùng |
| `--model claude-sonnet-4-6` | Chỉ định model |
| `--max-turns 5` | Giới hạn số agentic turns |

---

## Troubleshooting

| Lỗi | Nguyên nhân | Fix |
|-----|-------------|-----|
| `Failed to connect` | Sai package name | Dùng đúng `mcp-remote@latest` |
| `File is not defined` | Node.js version quá cũ | Upgrade Node lên v20+ |
| Tools không xuất hiện | Config chưa reload | Mở terminal mới, chạy `claude` lại |
| Browser không mở | First-time auth flow | Chạy `claude mcp list` trong terminal mới |

---

## Xem Ví Dụ Thực Tế

→ [example-atlassian.md](./example-atlassian.md) — Atlassian (Jira + Confluence) setup đầy đủ với OAuth

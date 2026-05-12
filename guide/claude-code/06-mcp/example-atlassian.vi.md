# Ví dụ: Thiết lập Atlassian MCP (Jira + Confluence)

Hướng dẫn này giúp bạn kết nối Claude Code với Atlassian để có thể truy vấn Jira ticket và Confluence page trực tiếp từ prompt.

---

## Yêu cầu

- **Claude Code đã cài** — `claude --version` phải hoạt động trong terminal.
- **Node.js v20 trở lên** — `mcp-remote` bắt buộc phải có. Phiên bản cũ hơn sẽ báo lỗi `File is not defined`.
- **Tài khoản Atlassian Cloud** — hỗ trợ Jira Cloud và Confluence Cloud. Không hỗ trợ Atlassian Server/Data Center.

---

## Bước 1: Cài đặt / Kiểm tra Node.js v20+

Kiểm tra phiên bản hiện tại:

```bash
node --version
# Kết quả mong muốn: v20.x.x trở lên
```

Nếu đang dùng phiên bản cũ, nâng cấp bằng nvm (hoạt động trên macOS, Linux và WSL):

```bash
# Cài nvm (nếu chưa có)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Reload shell
source ~/.bashrc   # hoặc ~/.zshrc trên macOS

# Cài và dùng Node 20
nvm install 20
nvm use 20
nvm alias default 20

# Xác nhận
node --version    # v20.x.x
npx --version     # 10.x.x
```

---

## Bước 2: Thêm Atlassian vào `~/.claude.json`

`~/.claude.json` là file config toàn cục của Claude Code. File này không bao giờ được commit vào git.

Mở hoặc tạo file và thêm block `mcpServers`:

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

**Lưu ý quan trọng:**
- Dùng chính xác `mcp-remote@latest` — đây là package OAuth proxy chính thức từ Cloudflare.
- Không dùng các package không chính thức như `@teolin/mcp-atlassian` hay `@anthropic/mcp-server-atlassian`. Endpoint chính thức `https://mcp.atlassian.com/v1/mcp` chỉ hoạt động với `mcp-remote`.
- Nếu đã có MCP server khác, thêm `"atlassian": { ... }` vào trong object `"mcpServers"` hiện có — không tạo key `"mcpServers"` thứ hai.

**Ví dụ đầy đủ với nhiều server:**

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

## Bước 3: Đăng nhập OAuth lần đầu

Lần đầu Claude Code kết nối với Atlassian, trình duyệt sẽ mở tự động để xác thực OAuth.

**Kích hoạt đăng nhập:**

```bash
claude mcp list
```

Kết quả mong đợi:
```
atlassian: npx -y mcp-remote@latest https://mcp.atlassian.com/v1/mcp - Connecting...
```

Trình duyệt tự động mở trang OAuth của Atlassian. Đăng nhập bằng tài khoản Atlassian và nhấn **Allow**. Trình duyệt redirect về và hiển thị trang thành công.

Trong terminal, trạng thái chuyển thành:
```
atlassian: npx -y mcp-remote@latest https://mcp.atlassian.com/v1/mcp - Connected
```

**Lưu trữ token:** Token OAuth được lưu tại `~/.mcp-auth/` — cả Claude Code và Cursor đều đọc từ thư mục này. Bạn không cần đăng nhập lại trừ khi token hết hạn.

```
~/.mcp-auth/
  └── mcp-remote/
        └── [url-đã-hash]/
              ├── token.json      ← OAuth access + refresh token
              └── metadata.json   ← Cache metadata server
```

Không xóa thư mục này trừ khi muốn buộc xác thực lại. Token tự làm mới trước khi hết hạn.

---

## Bước 4: Cho phép Tool trong `settings.json`

Nếu Claude Code hỏi xác nhận cho phép gọi MCP tool lần đầu, bạn có thể pre-approve trong `.claude/settings.local.json` (file này bị gitignore — đây là config cá nhân cho project):

**Quyền đầy đủ (đọc + ghi):**

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

**Wildcard — cho phép tất cả Atlassian tool (tiện lợi, ít hạn chế hơn):**

```json
{
  "permissions": {
    "allow": ["mcp__atlassian__*"]
  }
}
```

**Chỉ đọc (khuyến nghị cho môi trường chia sẻ hoặc CI):**

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

## Bước 5: Kiểm thử

Mở phiên Claude Code mới và thử các prompt sau:

```
Tôi có quyền truy cập những Jira project nào?
```

```
Lấy ticket PROJ-123 từ Jira và tóm tắt acceptance criteria
```

```
Tìm tất cả ticket đang mở trong project PROJ được giao cho tôi, sắp xếp theo ngày tạo
```

```
Lấy trang Confluence về tiêu chuẩn xác thực API của chúng tôi
```

Claude sẽ tự động gọi các MCP tool Atlassian — bạn không cần đặt tên tool trong prompt.

---

## Bước 6: Dùng với lệnh `/research-ticket`

Sau khi MCP đã kết nối, bạn có thể dùng nó bên trong slash command của Claude Code để tự động hóa việc nghiên cứu ticket.

Lệnh `/research-ticket` trong repo này lấy một Jira ticket cùng các Confluence page được liên kết, sau đó ghi một file spec có cấu trúc vào `specs/[TICKET-KEY].md`.

**Chạy lệnh:**

```
/research-ticket PROJ-42
```

**Hoặc với URL đầy đủ:**

```
/research-ticket https://yourworkspace.atlassian.net/browse/PROJ-42
```

Lệnh này tự động gọi hai MCP tool:
1. `mcp__atlassian__getJiraIssue` — lấy ticket (summary, description, AC, linked issue)
2. `mcp__atlassian__getConfluencePage` — lấy từng Confluence page được liên kết trong ticket

**Tìm `cloudId` của bạn:**

`cloudId` là UUID xác định workspace Atlassian của bạn. Các command gọi MCP tool trực tiếp (như `/research-ticket`) cần hardcode giá trị này.

Cách tìm:

```bash
# Mở URL này trong trình duyệt (khi đã đăng nhập Atlassian)
https://api.atlassian.com/oauth/token/accessible-resources
```

Hoặc hỏi Claude:

```
cloudId Atlassian của tôi là gì?
```

Claude sẽ gọi `mcp__atlassian__getAccessibleAtlassianResources` và trả về UUID.

Sau khi có cloudId, thêm vào file command (`.claude/commands/research-ticket.md`):

```markdown
Dùng MCP tool `mcp__atlassian__getJiraIssue` với:
- `cloudId`: `your-cloud-id-here`
- `issueIdOrKey`: ticket key đã trích xuất
```

**Ví dụ kết quả** — sau khi chạy `/research-ticket BLOG-14`:

```
specs/BLOG-14.md đã được lưu.

# Spec: BLOG-14 — Publish Post

## Tổng quan
Author có thể chuyển draft post sang trạng thái published...

## Acceptance Criteria
- [ ] AC01: Chỉ author hoặc Admin mới có thể publish
- [ ] AC02: Chỉ post có status "draft" mới được publish
...
```

---

## Dùng chung với Cursor

Nếu bạn cũng dùng Cursor, thêm cùng config vào `~/.cursor/mcp.json`:

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

Token OAuth tại `~/.mcp-auth/` được dùng chung — Cursor tái sử dụng phiên đăng nhập. Không cần xác thực lại.

---

## Xử lý Sự cố

| Lỗi | Nguyên nhân | Cách sửa |
|-----|-------------|----------|
| `File is not defined` hoặc `ReferenceError: File is not defined` | Node.js phiên bản < 20 | Nâng cấp lên Node.js v20+ bằng nvm. Chạy `node --version` để xác nhận. |
| `Failed to connect` hoặc `Connection refused` | Tên package hoặc URL sai | Kiểm tra `~/.claude.json` dùng chính xác `mcp-remote@latest` và URL `https://mcp.atlassian.com/v1/mcp`. |
| MCP tool không xuất hiện trong Claude | Config chưa được reload | Đóng tất cả terminal Claude Code và mở terminal mới. Chạy lại `claude mcp list`. |
| Trình duyệt không mở để OAuth | Luồng xác thực lần đầu cần terminal mới | Mở terminal hoàn toàn mới (không phải phiên Claude đang chạy), chạy `claude mcp list` từ đó. |
| `cloudId not found` trong command | cloudId chưa được set trong file command | Tìm cloudId qua `https://api.atlassian.com/oauth/token/accessible-resources` và hardcode vào. |
| `Permission denied` cho MCP tool | Tool chưa có trong danh sách allow | Thêm tên tool vào `"allow"` trong `.claude/settings.local.json`. |

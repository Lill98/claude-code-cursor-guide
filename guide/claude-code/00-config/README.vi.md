# Phân Cấp Cấu Hình

Đọc phần này trước. Hiểu rõ các tầng config giúp bạn đặt file đúng chỗ và tránh nhầm lẫn khi làm việc nhóm.

---

## Tổng Quan: 4 Tầng Config

```
┌─────────────────────────────────────────────────────────────┐
│  TẦNG 0 — MANAGED / ORG-WIDE                                │
│  /etc/claude-code/CLAUDE.md  (Linux)                        │
│  /Library/Application Support/ClaudeCode/CLAUDE.md (macOS)  │
│  IT/DevOps thiết lập — ghi đè tất cả, áp dụng cho mọi người│
└──────────────────────────┬──────────────────────────────────┘
                           │ ghi đè
┌──────────────────────────▼──────────────────────────────────┐
│  TẦNG 1 — GLOBAL / PERSONAL                                  │
│  ~/.claude/                                                  │
│  ~/.claude.json                                              │
│  Cá nhân — áp dụng mọi project, không push lên git         │
└──────────────────────────┬──────────────────────────────────┘
                           │ ghi đè
┌──────────────────────────▼──────────────────────────────────┐
│  TẦNG 2 — PROJECT / TEAM                                     │
│  [project-root]/CLAUDE.md                                   │
│  [project-root]/.claude/                                    │
│  Cả team dùng chung — commit lên git                        │
└──────────────────────────┬──────────────────────────────────┘
                           │ mở rộng
┌──────────────────────────▼──────────────────────────────────┐
│  TẦNG 3 — DIRECTORY-LEVEL                                   │
│  src/auth/CLAUDE.md                                         │
│  src/payments/CLAUDE.md                                     │
│  Load theo yêu cầu khi làm việc trong folder đó             │
└─────────────────────────────────────────────────────────────┘
```

---

## Chi Tiết Từng Tầng

### Tầng 0 — Managed / Org-wide

| Hệ điều hành | Path |
|---|------|
| macOS | `/Library/Application Support/ClaudeCode/CLAUDE.md` |
| Linux | `/etc/claude-code/CLAUDE.md` |
| Windows | `C:\Program Files\ClaudeCode\CLAUDE.md` |

Dành cho IT, DevOps, hoặc Tech Lead muốn enforce rules cho toàn bộ tổ chức mà không ai có thể ghi đè.

Ví dụ nội dung:
```markdown
## Company Rules (enforced)
- Never commit secrets or API keys
- All PRs must have test coverage
- Use company Jira for ticket references
```

---

### Tầng 1 — Global / Personal

```
~/.claude/
├── CLAUDE.md              # Rules áp dụng mọi project của bạn
├── settings.json          # Personal hooks, preferences
├── skills/<name>/         # Personal skills (thắng project nếu trùng tên)
│   └── SKILL.md
└── commands/<name>.md     # Personal commands (legacy format)

~/.claude.json             # MCP server config (file riêng)
```

Dành cho preferences cá nhân — coding style, workflow riêng, tools bạn dùng trên mọi project.

Ví dụ `~/.claude/CLAUDE.md`:
```markdown
## My Personal Rules
- Always write tests before implementation
- Prefer functional patterns over class-based
- Use conventional commits format
```

---

### Tầng 2 — Project / Team

```
[project-root]/
├── CLAUDE.md                    # Project rules (commit lên git)
├── CLAUDE.local.md              # Local override của bạn (gitignore)
└── .claude/
    ├── settings.json            # Team hooks, permissions (commit)
    ├── settings.local.json      # Local override (gitignore)
    ├── skills/<name>/SKILL.md   # Team skills (commit)
    ├── commands/<name>.md       # Team commands, legacy format (commit)
    ├── hooks/                   # Hook scripts (commit)
    │   ├── lint-fix.sh
    │   └── run-tests.sh
    └── rules/                   # Path-scoped rules (commit) — xem bên dưới
        ├── api.md
        └── testing.md
```

Dành cho rules và workflows mà cả team phải tuân theo — project convention, code standard, quality gate.

---

### Tầng 3 — Directory-level

```
[project-root]/
└── src/
    ├── CLAUDE.md          # Load khi làm việc trong src/ và các thư mục con
    ├── auth/
    │   └── CLAUDE.md      # Load khi làm việc trong src/auth/
    └── payments/
        └── CLAUDE.md      # Load khi làm việc trong src/payments/
```

Dành cho rules đặc thù của từng module — chi tiết domain logic và pattern chỉ relevant khi đang làm trong folder đó.

Lợi ích: CLAUDE.md ở root giữ ngắn gọn. Chi tiết nằm đúng chỗ, chỉ tốn token khi cần.

---

## Git Ownership

| File / Folder | Push lên git? | Owner | Ghi chú |
|---------------|:---:|-------|---------|
| `~/.claude/CLAUDE.md` | Không | Cá nhân | Personal rules |
| `~/.claude/settings.json` | Không | Cá nhân | Personal hooks |
| `~/.claude/skills/` | Không | Cá nhân | Personal skills |
| `~/.claude.json` | Không | Cá nhân | MCP config |
| `CLAUDE.md` (project root) | Có | Team | Rules cả team follow |
| `CLAUDE.local.md` | Gitignore | Cá nhân | Local rule override |
| `src/*/CLAUDE.md` | Có | Team | Module-level rules |
| `.claude/settings.json` | Có | Team | Team hooks |
| `.claude/settings.local.json` | Gitignore | Cá nhân | Local permission override |
| `.claude/skills/` | Có | Team | Team skills |
| `.claude/commands/` | Có | Team | Team commands |
| `.claude/hooks/` | Có | Team | Hook scripts |
| `.claude/rules/` | Có | Team | Path-scoped rules |
| `/etc/claude-code/CLAUDE.md` | N/A | Công ty | Managed policy |

---

## Quy Tắc Override và Precedence

### CLAUDE.md — Cộng dồn (không ghi đè, stack lên nhau)

Tất cả CLAUDE.md files đều được load và **stack** theo thứ tự từ global đến local:

```
~/.claude/CLAUDE.md          (1 — global personal)
  +
/etc/claude-code/CLAUDE.md   (2 — managed org)
  +
[project]/CLAUDE.md          (3 — project team)
  +
[project]/CLAUDE.local.md    (4 — local personal)
  +
[project]/src/auth/CLAUDE.md (5 — load on demand)
```

Nếu có conflict (rule A bảo dùng Zod, rule B bảo dùng class-validator), rule load sau sẽ được ưu tiên. Tránh conflict bằng cách thiết kế từng tầng tập trung vào phạm vi của nó.

### Skills — Personal thắng

Nếu `~/.claude/skills/write-test/` và `.claude/skills/write-test/` cùng tồn tại, personal version thắng.

### settings.json — Merge

`settings.local.json` merge với `settings.json`. Local thắng nếu trùng key.

### MCP — Chỉ ở global

`~/.claude.json` là file duy nhất cho MCP config. Không có project-level MCP config.

---

## CLAUDE.local.md vs settings.local.json

Hai file này dễ nhầm:

| | `CLAUDE.local.md` | `.claude/settings.local.json` |
|--|---|---|
| **Override gì** | Rules và instructions cho Claude | Permissions và hooks config |
| **Ví dụ** | "Luôn dùng tab, không dùng spaces" | Allow `Bash(npm run deploy)` |
| **Gitignore** | Có — luôn gitignore | Có — luôn gitignore |
| **Dùng khi** | Cần rule cá nhân không muốn team thấy | Cần permission local (API keys, local tools) |

---

## .claude/rules/ — Path-scoped Rules

Rules chỉ load khi Claude đang làm việc với files khớp glob pattern.

```
.claude/rules/
├── api.md           # Chỉ load khi edit src/api/**
├── testing.md       # Chỉ load khi edit **/*.spec.ts
└── database.md      # Chỉ load khi edit **/*.prisma
```

Format:
```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Rules
- All endpoints must have input validation
- Use standard error response format: { error, code, message }
- Never expose internal error details to client
```

Lợi ích: CLAUDE.md root giữ ngắn gọn (khoảng 50 dòng). Chi tiết kỹ thuật nằm trong rules files và chỉ load khi liên quan — tiết kiệm token đáng kể về lâu dài.

---

## @import Syntax — Giữ CLAUDE.md Ngắn Gọn

Từ CLAUDE.md có thể import file khác thay vì copy nội dung vào inline:

```markdown
# CLAUDE.md
See @README.md for project overview and @package.json for available scripts.

## Workflows
- Git conventions: @docs/git-workflow.md
- API standards: @docs/api-standards.md
- Personal preferences: @~/.claude/my-project-notes.md
```

Claude đọc file được import trước khi respond. Dùng cho docs có sẵn trong repo — không cần duplicate.

---

## Auto Memory — Hệ Thống Bộ Nhớ Thứ Hai

Ngoài CLAUDE.md (bạn viết tay), Claude Code còn có **auto memory** — Claude tự ghi chú cho chính nó:

```
~/.claude/projects/<project-hash>/memory/
├── MEMORY.md              # Index — load đầu mỗi session (tối đa 200 dòng)
├── debugging.md           # Claude tự ghi khi tìm ra bug pattern
├── api-conventions.md     # Claude tự ghi conventions nó học được
└── user-preferences.md    # Claude tự ghi preferences của bạn
```

Cơ chế hoạt động:
- `MEMORY.md` load tự động khi bắt đầu session
- Topic files load theo yêu cầu khi liên quan
- Claude tự quyết định ghi gì (corrections, insights, patterns đã học)
- Lưu local trên máy — không sync lên cloud

Xem memory đang load: gõ `/memory` trong Claude Code.

Tắt auto memory: đặt `autoMemoryEnabled: false` trong settings.json.

---

## Template .gitignore

Thêm vào `.gitignore` của project:

```gitignore
# Claude Code — local overrides (không commit)
.claude/settings.local.json
CLAUDE.local.md

# Personal session notes
claude-session-notes.md
```

---

## Pattern: Company Template Repo

Repo này chính là ví dụ của pattern này. Cách một công ty có thể tổ chức:

```
[company]/ai-tools-handbook/    <- Repo này
├── guide/                      # Documentation
├── .claude/                    # Working demo config
│   ├── settings.json           # Team hooks template
│   ├── skills/                 # Team skill templates
│   └── hooks/                  # Hook script templates
└── CLAUDE.md                   # Repo rules template

# Từng project team copy về và customize:
[project]/.claude/    <- copy từ template, điều chỉnh cho project
[project]/CLAUDE.md   <- copy từ template, điều chỉnh cho domain
```

---

## Xem Thêm

- [01-rules/](../01-rules/README.md) — Nội dung CLAUDE.md và path-scoped rules trong .claude/rules/
- [06-mcp/](../06-mcp/README.md) — Cấu hình `~/.claude.json`

# Hướng Dẫn Tùy Chỉnh Claude Code

Hướng dẫn đầy đủ để mở rộng và tự động hóa Claude Code với Rules, Commands, Hooks, Skills, Subagents, MCP, TDD và các tips nâng cao. Tất cả ví dụ dùng project **blog-api** (FastAPI + SQLAlchemy + PostgreSQL + pytest).

---

## Tổng Quan

| # | Loại | Vị trí | Kích hoạt khi | Dùng để |
|---|------|---------|---------------|---------|
| 00 | **Config** | `CLAUDE.md`, `~/.claude/`, `.claude/` | Khi khởi động / bắt đầu session | Thiết lập các tầng config, đặt file đúng chỗ, phân quyền git |
| 01 | **Rules** | `CLAUDE.md` tại project root | Mỗi lần Claude bắt đầu task | Định nghĩa convention, stack, context cố định |
| 02 | **Commands** | `.claude/commands/*.md` | Người dùng gõ `/command-name` | Workflow lặp lại nhiều lần, có thể tham số hóa |
| 03 | **Hooks** | `.claude/settings.json` → `hooks` | Tự động trước/sau tool calls | Tự động kiểm tra chất lượng không cần nhắc |
| 04 | **Skills** | `.claude/skills/<name>/SKILL.md` | Người dùng gõ `/skill-name` hoặc Claude tự gọi | Workflow chuyên sâu; Claude tự load khi phù hợp |
| 05 | **Subagents** | Claude gọi nội bộ | Claude quyết định ủy thác subtask | Chạy song song, task dài, cô lập |
| 06 | **MCP** | `~/.claude.json` → `mcpServers` | Claude cần gọi external tool | Kết nối Jira, Confluence, databases, APIs |
| 07 | **TDD** | `.claude/skills/spec-to-tests/SKILL.md` + Stop hook | `/spec-to-tests` + Stop event | Tạo test stubs từ spec, chạy tests tự động |
| 08 | **Tips** | N/A (patterns và mental models) | Tham khảo khi debug hoặc tối ưu | Tiết kiệm token, context window, prompt discipline |

---

## Lộ Trình Học

### Level 1 — Basic (bắt đầu từ đây)

Học ba section này trước. Áp dụng được ngay cho mọi project và mang lại giá trị rõ ràng ngay lập tức.

| Section | Học gì | Kết quả |
|---------|--------|---------|
| **01-rules** | Cách viết CLAUDE.md hiệu quả | Claude luôn biết stack và convention của bạn mà không cần nhắc lại |
| **02-commands** | Cách biến workflow lặp lại thành slash command | `/create-module auth` tạo ra module NestJS hoàn chỉnh theo chuẩn của bạn |
| **03-hooks** | Cách trigger script tự động theo tool event | ESLint và Prettier chạy sau mỗi lần sửa file — không cần nhắc |

Sau Level 1, Claude hành xử như một developer đã hiểu project của bạn. Nó tự tuân theo convention và tự kiểm tra chất lượng.

### Level 2 — Intermediate

Nâng cao sau khi đã vững phần cơ bản.

| Section | Học gì | Kết quả |
|---------|--------|---------|
| **04-skills** | Built-in skills + viết expert workflow tùy chỉnh | `/review-pr` kiểm tra theo checklist RBAC + Zod + coverage; Claude tự gọi khi phù hợp |
| **05-subagents** | Cách Claude ủy thác subtask sang agent song song | Research dài hoặc generate nhiều file chạy nhanh hơn, không block |
| **06-mcp** | Kết nối external tools qua Model Context Protocol | Claude đọc Jira ticket và Confluence trực tiếp trong lúc làm task |

Sau Level 2, Claude có thể lấy context trực tiếp từ tools của bạn và chạy workflow phức tạp mà không cần can thiệp thủ công.

### Level 3 — Advanced

Dành cho team muốn tự động hóa hoàn toàn.

| Section | Học gì | Kết quả |
|---------|--------|---------|
| **07-tdd** | Workflow spec-to-tests, Stop hook chạy tests | Tests được generate từ acceptance criteria và chạy tự động sau mỗi task |
| **08-tips** | Cách Claude đọc context, token budget, prompt pattern | Viết prompt gọn hơn, tránh lãng phí context window, debug behavior của Claude |

Sau Level 3, toàn bộ vòng phát triển — spec, tests, implementation, lint, quality gates — được tự động hóa và tái sử dụng được.

---

## Khi Nào Dùng Cái Gì

### Rules (CLAUDE.md)
Dùng khi muốn Claude **luôn biết** context của project mà không cần nhắc. Phù hợp cho convention stack, naming pattern, anti-pattern, và team standard.

Ví dụ: "Luôn dùng Zod cho validation, không dùng class-validator. Service file ở `src/modules/<name>/<name>.service.ts`."

### Commands
Dùng khi có **workflow lặp lại với input thay đổi**. Command là prompt template có thể nhận tham số.

Ví dụ: `/create-module auth` — Claude tạo controller, service, DTO, và spec file theo cấu trúc project của bạn.

### Hooks
Dùng khi muốn **kiểm tra chất lượng tự động ở tầng tool call** — không phụ thuộc vào việc Claude có nhớ hay không, được enforce bởi harness.

Ví dụ: Sau mỗi lần ghi file → ESLint chạy. Sau mỗi session Claude kết thúc → unit tests chạy.

### Skills
Dùng khi workflow đủ phức tạp để cần **prompt engineering riêng** — roles, few-shot examples, structured output. Cũng dùng cho built-in skills có sẵn của Claude Code.

Built-in skills dùng được ngay: `/simplify`, `/debug`, `/batch`, `/loop`, `/claude-api`, `/init`, `/review`, `/security-review`

Ví dụ: `/review-pr` — Claude review diff theo checklist RBAC + Zod + test coverage của project.

### Subagents
Dùng khi Claude cần **chạy nhiều task độc lập song song** hoặc ủy thác việc dài mà không block conversation chính.

Ví dụ: Claude spawn một subagent đọc tất cả spec file trong khi agent khác đọc implementation hiện tại — sau đó tổng hợp kết quả.

### MCP
Dùng khi Claude cần **dữ liệu trực tiếp từ external system** — Jira ticket, Confluence docs, database schema, third-party API.

Ví dụ: `/research-ticket SH-164` — Claude fetch ticket, linked Confluence pages, và viết spec implementation có cấu trúc.

### TDD Workflow
Dùng khi có spec và muốn tests được **viết trước hoặc song song với implementation** — test đỏ trước, implementation mới làm chúng xanh.

Ví dụ: `/spec-to-tests specs/SH-164.md src/modules/invitation/invitation.service.spec.ts` — tạo `it.todo()` stubs từ acceptance criteria.

### Tips
Đọc khi muốn hiểu **tại sao Claude hành xử theo một cách nhất định** — context window hoạt động ra sao, khi nào nên compact, cách viết prompt sống sót qua session dài.

---

## Cấu Trúc Thư Mục

```
.claude/
├── settings.json              # Hooks config, permissions (commit lên git)
├── settings.local.json        # Local overrides — gitignore
├── hooks/
│   ├── lint-fix.sh            # Pre-tool hoặc post-tool hook script
│   └── run-tests.sh           # Stop hook: chạy tests sau mỗi session
├── commands/                  # Legacy command format — vẫn hoạt động
│   └── create-module.md
├── skills/                    # Format được khuyến nghị
│   ├── write-test/
│   │   └── SKILL.md
│   ├── review-pr/
│   │   └── SKILL.md
│   └── spec-to-tests/
│       └── SKILL.md           # TDD workflow skill
└── rules/                     # Path-scoped rules (chỉ load khi liên quan)
    ├── api.md                 # Load khi edit src/api/**
    └── testing.md             # Load khi edit *.spec.ts

~/.claude/skills/              # Personal skills — áp dụng mọi project
~/.claude.json                 # MCP server config

CLAUDE.md                      # Project rules — commit lên git
CLAUDE.local.md                # Local rule override — gitignore
```

---

## Quick Start

```bash
# 1. Copy template project rules
cp guide/claude-code/01-rules/example-blog.md CLAUDE.md

# 2. Tạo các thư mục config
mkdir -p .claude/commands .claude/hooks .claude/skills .claude/rules

# 3. Copy command (legacy format)
cp guide/claude-code/02-commands/example-create-module.md .claude/commands/create-module.md

# 4. Thiết lập skill (format mới)
mkdir -p .claude/skills/write-test
# Copy nội dung từ guide/claude-code/04-skills/example-write-test.md
# vào .claude/skills/write-test/SKILL.md

# 5. Thiết lập TDD skill
mkdir -p .claude/skills/spec-to-tests
# Copy skill template từ guide/claude-code/07-tdd/README.md
# vào .claude/skills/spec-to-tests/SKILL.md

# 6. Thiết lập hooks
# Xem guide/claude-code/03-hooks/example-blog.md cho ruff/black/isort/pytest hooks
# Xem guide/claude-code/07-tdd/README.md cho run-tests.sh và Stop hook config

# 7. Gitignore local overrides
echo '.claude/settings.local.json' >> .gitignore
echo 'CLAUDE.local.md' >> .gitignore
```

---

## Các Section

| Section | README | Nội dung |
|---------|--------|----------|
| 00-config | [README](./00-config/README.md) | Các tầng config, git ownership, override rules, path-scoped rules, auto memory |
| 01-rules | [README](./01-rules/README.md) | Cấu trúc CLAUDE.md, những gì cần đưa vào, ví dụ cho FastAPI project |
| 02-commands | [README](./02-commands/README.md) | Format command, tham số, ví dụ create-module |
| 03-hooks | [README](./03-hooks/README.md) | Hook events (10+), stdin JSON format, env vars, lint + test examples |
| 04-skills | [README](./04-skills/README.md) | Built-in skills, format SKILL.md, frontmatter fields, auto-invoke |
| 05-subagents | [README](./05-subagents/README.md) | Cách subagents hoạt động, khi nào dùng, giới hạn |
| 06-mcp | [README](./06-mcp/README.md) | Thiết lập MCP, Atlassian integration, research-ticket workflow |
| 07-tdd | [README](./07-tdd/README.md) | Skill spec-to-tests, Stop hook, vòng red-green-refactor |
| 08-tips | [README](./08-tips/README.md) | Context window, tối ưu token, prompt pattern, debug Claude |

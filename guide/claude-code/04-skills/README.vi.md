# Claude Code Skills

Skills mở rộng khả năng của Claude. Lưu file `SKILL.md` trong `.claude/skills/<name>/` (project-scoped) hoặc `~/.claude/skills/<name>/` (personal), và Claude tự động thêm nó vào toolkit. Invoke trực tiếp bằng `/skill-name` hoặc để Claude tự invoke khi phát hiện description phù hợp.

> **Lưu ý:** Format `.claude/commands/*.md` cũ vẫn hoạt động bình thường (backward compatible). Skills là format khuyến nghị hiện tại vì hỗ trợ thêm: frontmatter, supporting files, và auto-invocation theo description.

---

## Bundled Skills (có sẵn trong mọi session, không cần thiết lập)

Claude Code đi kèm các built-in skills bạn có thể invoke ngay lập tức:

| Skill | Cách dùng | Mục đích |
|-------|-----------|---------|
| `/simplify` | `/simplify` | Review code đã thay đổi về khả năng tái sử dụng, chất lượng, và hiệu quả — fix issues tìm được |
| `/debug` | `/debug [error]` | Systematic debugging workflow |
| `/batch` | `/batch [task]` | Chạy một task trên nhiều files song song |
| `/loop` | `/loop [interval] [task]` | Lặp lại một task theo lịch định kỳ |
| `/claude-api` | `/claude-api` | Build, debug, và optimize tích hợp Anthropic SDK |

Các built-in commands sau cũng truy cập được qua Skill tool:

| Command | Mục đích |
|---------|---------|
| `/init` | Tạo `CLAUDE.md` từ codebase hiện tại |
| `/review` | Review một pull request |
| `/security-review` | Security review các changes trên current branch |

---

## Skills vs Commands

| | Command (`.claude/commands/`) | Skill (`.claude/skills/<name>/`) |
|--|-------------------------------|----------------------------------|
| Format | File `.md` đơn lẻ | Directory với `SKILL.md` + optional supporting files |
| Frontmatter | Hỗ trợ | Hỗ trợ (khuyến nghị) |
| Auto-invocation bởi Claude | Không | Có — Claude đọc `description` và invoke khi phù hợp |
| Supporting files | Không | Có — templates, examples, scripts |
| Trạng thái | Vẫn hoạt động | Khuyến nghị cho work mới |

Nếu cả command và skill có cùng tên, skill sẽ thắng.

---

## Cấu trúc Directory

```
.claude/skills/
└── write-test/
    ├── SKILL.md           # Instructions chính (bắt buộc)
    ├── examples/
    │   └── sample.spec.ts # Ví dụ output
    └── scripts/
        └── validate.sh    # Helper script tùy chọn

~/.claude/skills/          # Personal skills (áp dụng cho tất cả projects)
```

### Vị trí và Priority

| Vị trí | Path | Phạm vi |
|--------|------|---------|
| Personal | `~/.claude/skills/<name>/SKILL.md` | Tất cả projects của bạn |
| Project | `.claude/skills/<name>/SKILL.md` | Chỉ project này |

Priority: personal > project. Nếu cùng tên tồn tại ở cả hai, personal thắng.

---

## Format SKILL.md

Mỗi skill cần một `SKILL.md` với YAML frontmatter theo sau là markdown instructions:

```markdown
---
name: skill-name
description: Skill làm gì và khi nào dùng. Claude dùng field này để quyết định khi nào tự invoke.
disable-model-invocation: false
allowed-tools: Read Grep
---

# Skill instructions ở đây

$ARGUMENTS là input được truyền vào khi invoke.
```

### Frontmatter Fields

| Field | Bắt buộc | Mô tả |
|-------|----------|-------|
| `name` | Không | Slash-command name (mặc định là tên directory) |
| `description` | Khuyến nghị | Claude dùng để quyết định khi nào auto-invoke. Front-load key use case. Bị truncate ở 1,536 chars. |
| `when_to_use` | Không | Các trigger phrases bổ sung, được append vào `description` |
| `argument-hint` | Không | Hiển thị trong autocomplete, ví dụ: `[file-path]` hoặc `[module-name] [type]` |
| `disable-model-invocation` | Không | `true` = chỉ bạn có thể invoke (Claude sẽ không auto-trigger). Dùng cho deploy, commit, hoặc side-effect workflows. |
| `user-invocable` | Không | `false` = ẩn khỏi `/` menu; chỉ Claude auto-invoke. Dùng cho background reference knowledge. |
| `allowed-tools` | Không | Tools Claude có thể dùng không cần hỏi permission khi skill đang active. Ví dụ: `Bash(git *) Read Grep` |
| `model` | Không | Override model cho skill này |
| `effort` | Không | Override effort level: `low`, `medium`, `high`, `max` |
| `context` | Không | `fork` = chạy trong isolated subagent |
| `agent` | Không | Subagent type khi `context: fork`: `Explore`, `Plan`, `general-purpose`, hoặc custom subagent name |
| `paths` | Không | Glob patterns — skill chỉ kích hoạt khi làm việc với files matching, ví dụ: `**/*.spec.ts` |

### Argument Substitutions

| Variable | Mô tả |
|----------|-------|
| `$ARGUMENTS` | Toàn bộ argument string sau tên skill |
| `$ARGUMENTS[0]` hoặc `$0` | Argument đầu tiên (0-based index) |
| `$ARGUMENTS[1]` hoặc `$1` | Argument thứ hai |
| `${CLAUDE_SESSION_ID}` | Session ID hiện tại |
| `${CLAUDE_SKILL_DIR}` | Directory chứa `SKILL.md` này |

Ví dụ: `/migrate-component SearchBar React Vue` → `$0=SearchBar`, `$1=React`, `$2=Vue`

---

## Invocation Control

| Frontmatter | User có thể invoke | Claude tự invoke |
|-------------|-------------------|------------------|
| (mặc định) | Có | Có — khi description phù hợp |
| `disable-model-invocation: true` | Có | Không |
| `user-invocable: false` | Không | Có — khi description phù hợp |

**Khi nào dùng `disable-model-invocation: true`:** `/deploy`, `/commit`, `/send-email`, `/spec-to-tests` — các workflows có side effects hoặc khi bạn muốn kiểm soát thời điểm chạy.

**Khi nào dùng `user-invocable: false`:** Background knowledge như `legacy-system-context` — Claude nên biết khi relevant nhưng không phải action để user invoke trực tiếp.

---

## Template

```markdown
---
name: [skill-name]
description: [Skill làm gì. Hãy cụ thể — Claude dùng text này để quyết định khi nào invoke. Ví dụ: "Use when writing pytest unit tests for FastAPI services in blog-api"]
disable-model-invocation: false
---

# [Skill Name]

## Role
You are a [specific expert role]. You have expertise in [domain] and deep understanding of [context].

## Context
[Context cụ thể của project mà Claude cần — tech stack, conventions, patterns]

## Input
$ARGUMENTS là [mô tả input — ví dụ: "the path to the service file that needs tests"]

## Task
[Mô tả tổng quan task — 1-2 câu]

## Steps

1. **[Bước 1]**
   [Mô tả chi tiết Claude cần làm gì]

2. **[Bước 2]**
   [Mô tả chi tiết]

3. **[Bước 3]**
   [Mô tả chi tiết]

## Output Format
[Mô tả chính xác format output — include examples (few-shot) khi có thể]

## Quality Checklist
Trước khi hoàn thành, kiểm tra:
- [ ] [Tiêu chí 1]
- [ ] [Tiêu chí 2]
- [ ] [Tiêu chí 3]

## Example

Input: `/[skill-name] example-arg`

Expected output:
\`\`\`
[Ví dụ output]
\`\`\`
```

---

## Tips

- **Description là chìa khóa** — Viết để Claude biết khi nào auto-invoke. "Use when writing Vitest tests for NestJS services" tốt hơn chỉ "write-test".
- **Strong persona** — "Senior NestJS engineer with 5 years RBAC experience" tạo ra output tốt hơn "engineer".
- **`disable-model-invocation: true`** cho mọi thứ có side effects bạn muốn kiểm soát.
- **Giữ SKILL.md dưới 500 lines** — Chuyển tài liệu tham khảo chi tiết vào supporting files trong cùng directory.
- **`$0`, `$1` cho positional args** — `/migrate-component SearchBar React Vue` cho `$0=SearchBar`, `$1=React`, `$2=Vue`.
- **Supporting files** — Đặt templates, examples, và scripts trong cùng directory và tham chiếu từ SKILL.md.

---

## Xem Ví dụ Thực Tế

→ [example-write-test.md](./example-write-test.md)

# Claude Code Skills

## Skills vs Commands — Phân biệt mới (2025)

Skills là first-class feature của Claude Code, **không chỉ là commands phức tạp hơn**:

| | Commands | Skills |
|---|---|---|
| **Lưu ở đâu** | `.claude/commands/*.md` | Built-in hoặc `.claude/commands/*.md` |
| **Trigger** | User gõ `/command-name` | User gõ `/skill-name` **hoặc auto-trigger** theo context |
| **Cơ chế** | Claude đọc file MD | Claude dùng `Skill` tool để invoke |
| **Built-in** | Không | Có — nhiều skills pre-installed sẵn |
| **Persona/Role** | Thường không cần | Thường có role/expertise rõ ràng |

---

## Built-in Skills (có sẵn, không cần cài)

Claude Code hiện ship kèm các skills sau:

| Skill | Trigger | Mô tả |
|-------|---------|-------|
| `update-config` | `/update-config` | Cấu hình Claude Code qua `settings.json` (hooks, behaviors) |
| `keybindings-help` | `/keybindings-help` | Customize keyboard shortcuts trong `~/.claude/keybindings.json` |
| `simplify` | `/simplify` | Review code vừa thay đổi, refactor cho gọn, chất lượng |
| `loop` | `/loop 5m /foo` | Chạy lặp lại một command theo interval (mặc định 10m) |
| `schedule` | `/schedule` | Tạo scheduled remote agents chạy theo cron schedule |
| `claude-api` | Auto khi import `anthropic` | Hỗ trợ build apps với Claude API / Anthropic SDK |
| `research-ticket` | `/research-ticket SH-164` | Research Jira ticket → tạo implementation spec |

### Ví dụ dùng built-in skills

```bash
# Chạy /run-tests mỗi 5 phút
/loop 5m /run-tests

# Schedule một agent chạy mỗi sáng
/schedule

# Review và simplify code vừa edit
/simplify

# Config hooks tự động
/update-config
```

---

## Khi nào viết Custom Skill?

Viết custom skill khi:
- Workflow phức tạp cần **prompt engineering chi tiết** với role/persona
- Muốn Claude đóng vai "chuyên gia" trong domain cụ thể (RBAC, test writing...)
- Cần **few-shot examples** để định hướng output quality
- Built-in skills không đủ

---

## Structure of an Effective Skill

### 1. Role/Persona
Define what role Claude plays → influences how Claude thinks and what it outputs.

### 2. Context
Provide specific context that Claude needs to operate correctly.

### 3. Input Format
Clearly describe what Claude will receive.

### 4. Analysis Steps
Structured analysis steps — especially important for complex skills.

### 5. Output Format
Define the exact output format — can include examples (few-shot).

### 6. Few-shot Example (optional)
Sample input/output — helps Claude understand the expected quality.

---

## TEMPLATE

```markdown
# [Skill Name]

## Role
You are a [specific expert role]. You have expertise in [domain] and a deep understanding of [context].

## Context
[Describe the project context this skill operates in — tech stack, conventions, patterns]

## Input
$ARGUMENTS is [describe input — e.g., "the path to the service file that needs tests"]

## Task
[Describe the overall task — 1-2 sentences]

## Analysis Steps

Before creating output, analyze in this order:

1. **[Analysis step 1]**
   - [Details to consider]
   - [Questions to answer]

2. **[Analysis step 2]**
   - [Details to consider]

3. **[Analysis step 3]**
   - [Details to consider]

## Output Format

### [Section 1]
[Describe section 1 format]

### [Section 2]
[Describe section 2 format]

## Quality Checklist
Before finishing, verify:
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Example

Input: `[example input]`

Expected output:
```
[Example output]
```
```

---

## Tips for Writing Skills

- **Strong persona** — "Senior NestJS engineer with 5 years of RBAC experience" → better output than just "engineer"
- **Few-shot examples** — Provide 1-2 sample outputs, Claude will match the quality
- **Explicit checklist** — List specific quality criteria, Claude will self-verify
- **Don't make it too long** — If the skill prompt exceeds 100 lines, consider splitting into 2 skills
- **Test with edge cases** — Try the skill with "difficult" inputs to check behavior
- **Prefer built-in skills first** — Trước khi viết custom skill, check xem built-in skills có đủ chưa

---

## Loop & Schedule — Automation Skills

Hai skills đặc biệt để tự động hóa:

### `/loop` — Chạy lặp theo interval
```
/loop [interval] [command]
```
```bash
# Chạy /run-tests mỗi 5 phút
/loop 5m /run-tests

# Chạy /check-build mỗi 10 phút (mặc định)
/loop /check-build
```

### `/schedule` — Cron jobs cho Claude agents
Tạo scheduled remote agents chạy tự động theo cron schedule.
```bash
/schedule
# Claude hỏi: command nào? schedule khi nào? → tạo cron trigger
```

---

## See a Real-World Example

→ [example-write-test.md](./example-write-test.md)

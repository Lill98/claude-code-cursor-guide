# Claude Code: Subagents

Subagent chạy trong **context window riêng biệt** — không kế thừa conversation history của main session. Main agent delegate task, subagent làm xong và trả về **summary**. Main session nhận summary, không phải toàn bộ output.

---

## Tại Sao Dùng Subagents?

| Vấn đề | Giải pháp |
|--------|-----------|
| Grep 50 files → làm đầy main context | Explore subagent đọc hết, main chỉ nhận summary |
| Cần review code vừa viết nhưng bị bias | Reviewer subagent với fresh context |
| Nhiều task độc lập có thể chạy song song | Spawn nhiều subagents cùng lúc |
| Debug session dài làm bẩn main conversation | Subagent isolate debugging |

---

## Cách Subagents Hoạt Động

```
Main Session (context A)
  │
  ├─── delegate task ───▶ Subagent (context B — fresh, isolated)
  │                              │
  │                              │  explore 30 files
  │                              │  chạy tests
  │                              │  phân tích patterns
  │                              │
  ◀─── returns summary ──────────┘
  │     (~200 tokens, không phải 5000)
  │
  └─── tiếp tục với summary trong context
```

Subagent không biết gì về main conversation. Nó chỉ biết những gì có trong delegation prompt.

---

## Các Loại Subagent

| Type | Dùng khi | Read-only? |
|------|----------|:----------:|
| `Explore` | Tìm kiếm codebase, trả lời "file X ở đâu", "symbol Y được define chỗ nào" | Có |
| `Plan` | Architecture decisions, tạo implementation plan | Có |
| `general-purpose` | Full capability — đọc và viết file, chạy commands | Không |

---

## Cách Kích Hoạt Subagents

### 1. Chỉ Định Rõ Trong Prompt

```
Use an Explore subagent to find all files that import UserService
```

```
Use a general-purpose subagent to implement the auth middleware,
then report back what was changed
```

### 2. Trong Skill Qua `context: fork`

Thêm `context: fork` vào frontmatter của `SKILL.md` để skill chạy trong isolated subagent:

```markdown
---
name: review-pr
description: Review code changes for security and quality issues
context: fork
agent: Explore
---

# Review PR

Review all staged changes and check for:
1. Security issues (missing auth, data exposure)
2. Missing input validation
3. Test coverage gaps

Report findings with severity: CRITICAL / WARNING / SUGGESTION
```

Khi user gõ `/review-pr`:
- Tạo subagent mới với type `Explore`
- Skill chạy trong subagent đó
- Main context nhận report, không phải toàn bộ file contents

### 3. Worktree Isolation

Git worktree cho phép checkout cùng một repo ra **nhiều thư mục khác nhau cùng lúc**, mỗi thư mục ở một branch riêng. Hiểu đơn giản: như có 2 bản sao độc lập của codebase trên máy — Claude A làm việc trên bản sao 1, Claude B trên bản sao 2, không ai đụng file của nhau, không conflict.

```bash
# Mỗi lệnh tạo một thư mục riêng + branch riêng
claude --worktree bugfix-payment    # Terminal 1 → thư mục riêng, branch bugfix-payment
claude --worktree feature-dashboard # Terminal 2 → thư mục riêng, branch feature-dashboard
```

Mỗi worktree có:
- Branch git riêng — commit không đụng nhau
- Working directory riêng — file không conflict
- Context window riêng — 2 Claude session độc lập hoàn toàn

Dùng khi: cần 2 feature làm song song, hoặc muốn agent implement trên branch riêng để review trước khi merge vào main.

---

## Frontmatter Fields Cho Subagents

```markdown
---
name: skill-name
context: fork                        # Bắt buộc để chạy trong subagent
agent: Explore                       # Subagent type: Explore, Plan, general-purpose
disable-model-invocation: true       # Tùy chọn: chỉ invoke thủ công
---
```

| Field | Values | Ghi chú |
|-------|--------|---------|
| `context` | `fork` | Chạy trong isolated subagent |
| `agent` | `Explore`, `Plan`, `general-purpose` | Default: `general-purpose` |

---

## Patterns

"Patterns" ở đây là các **công thức có sẵn** — mỗi khi gặp một tình huống cụ thể, có một cách dùng subagent đã được kiểm chứng cho tình huống đó. Thay vì tự nghĩ "mình nên spawn subagent kiểu gì", bạn chỉ cần nhận ra mình đang ở tình huống nào và áp công thức tương ứng.

| Tình huống | Pattern |
|---|---|
| Cần đọc nhiều file để hiểu codebase | Investigation |
| Cần review code vừa viết khách quan | Writer / Reviewer |
| Nhiều task độc lập cần làm cùng lúc | Fan-out |
| Implement xong cần verify kết quả | Implement → Verify |

---

### Pattern 1: Investigation (Explore)

**Vấn đề:** Bạn cần hiểu flow của một feature — phải đọc 15-30 file. Nếu Claude tự đọc trực tiếp, toàn bộ nội dung các file đó lấp đầy conversation window đang làm việc, không còn chỗ để tiếp tục.

**Cách dùng:** Gõ vào chat Claude Code:

```
Use an Explore subagent to investigate how the payment flow works.
Find all relevant files, trace the data flow from API endpoint to database.
Return a summary: which files, which functions, what data model.
```

**Điều gì xảy ra:** Claude tự spawn một agent con (Explore — chỉ đọc, không sửa file), agent đó đọc hết các file liên quan, rồi báo cáo tóm tắt lại cho conversation của bạn. Conversation của bạn chỉ nhận bản tóm tắt ngắn — không phải toàn bộ nội dung từng file.

**Kết quả:** Bạn biết được file nào liên quan, flow hoạt động ra sao — mà conversation vẫn còn chỗ trống để làm việc tiếp.

---

### Pattern 2: Writer / Reviewer

**Vấn đề:** Bạn vừa implement xong một feature — Claude trong session đó đã "sống" cùng code từ đầu nên khó nhìn ra lỗi. Giống như tự proof-read bài mình vừa viết.

**Cách dùng:** Mở terminal thứ hai, chạy một session Claude Code hoàn toàn mới — session này không biết gì về lần implement trước:

```bash
# Terminal 1 — session implement
claude "Implement the UserInvitation feature per specs/PROJ-123.md"

# Terminal 2 — session review (mở riêng, không liên quan)
claude "Review the changes in src/modules/invitation/ for security issues,
        missing validation, and test coverage."
```

**Điều gì xảy ra:** Session 2 đọc code từ disk (những gì Session 1 đã commit/lưu) mà không có bất kỳ ký ức nào về quá trình viết ra nó — giống như một người khác review.

**Kết quả:** Bắt được lỗi mà session implement bỏ sót vì quá quen với code của mình.

---

### Pattern 3: Fan-out (Parallel)

**Vấn đề:** Bạn cần kiểm tra 3 loại lỗi khác nhau trong codebase. Làm lần lượt mất 3 lần thời gian, và kết quả của lần trước lấp đầy conversation làm ảnh hưởng lần sau.

**Cách dùng:** Gõ vào chat Claude Code một lần, mô tả cả 3 task:

```
Use 3 parallel subagents to analyze the codebase:
1. Subagent 1: Find all Prisma queries missing a firmId filter
2. Subagent 2: Find all endpoints missing the @RequirePermission decorator
3. Subagent 3: Find all DTOs not using Zod validation

Each should return a list of file:line references.
Merge the findings into a single security audit report.
```

**Điều gì xảy ra:** Claude spawn 3 agent con chạy song song — mỗi cái làm một việc độc lập, không biết về nhau. Khi cả 3 xong, Claude tổng hợp kết quả và trả về cho bạn.

**Kết quả:** Hoàn thành trong thời gian của 1 task thay vì 3, conversation chỉ nhận bản tổng hợp cuối.

---

### Pattern 4: Implement → Verify

**Vấn đề:** Claude implement xong một feature nhưng bạn không chắc kết quả đúng. Nếu để Claude tự chạy test ngay trong cùng conversation, nó đang "tự chấm bài mình" — dễ bỏ sót lỗi vì biết mình vừa làm gì.

**Cách dùng:** Gõ vào chat Claude Code, yêu cầu nó implement xong rồi tự spawn subagent verify:

```
1. Implement the feature
2. Then use a general-purpose subagent to:
   - Run the test suite
   - Check that all acceptance criteria are covered
   - Report what passes, what fails, what is missing
```

**Điều gì xảy ra:** Claude implement xong, sau đó spawn một agent con riêng để chạy test. Agent con này không biết implementation đã làm gì — nó chỉ chạy test và báo cáo kết quả thực tế.

**Kết quả:** Bạn nhận được báo cáo "pass/fail/missing" từ một agent không có lý do gì để bao che cho code vừa viết.

---

## SubagentStart / SubagentStop Hooks

**Hook** là shell command mà Claude Code tự động chạy khi một sự kiện nhất định xảy ra — không cần bạn làm gì. Bạn cấu hình một lần trong `.claude/settings.json`, sau đó nó tự chạy mỗi khi đúng sự kiện.

`SubagentStart` và `SubagentStop` là 2 sự kiện liên quan đến subagent:
- **SubagentStart** — kích hoạt ngay khi Claude spawn một subagent mới
- **SubagentStop** — kích hoạt khi subagent đó làm xong (dù thành công hay thất bại)

**Dùng để làm gì:** Ghi log để biết bao nhiêu subagent đã chạy, đo thời gian mỗi subagent mất bao lâu, hoặc gửi notification khi subagent hoàn thành.

**Cấu hình trong `.claude/settings.json`:**

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "",
        "hooks": [{
          "type": "command",
          "command": "echo \"Subagent started\" >> ~/.claude-activity.log"
        }]
      }
    ],
    "SubagentStop": [
      {
        "matcher": "",
        "hooks": [{
          "type": "command",
          "command": "bash .claude/hooks/on-subagent-stop.sh"
        }]
      }
    ]
  }
}
```

Ví dụ trên: mỗi khi có subagent bắt đầu, tự động ghi một dòng vào file `~/.claude-activity.log`. Khi subagent kết thúc, tự động chạy script `on-subagent-stop.sh`.

> Hooks là một topic lớn hơn — xem chi tiết tại [03-hooks](../03-hooks/README.vi.md).

---

## Khi Nào Dùng Subagents vs Skills Thường

| Tình huống | Dùng |
|------------|------|
| Task một bước, output rõ ràng | Skill thường |
| Cần explore nhiều files (>5) | Subagent với `Explore` |
| Cần feedback loop (implement → test → fix) | Subagent với `general-purpose` |
| Review code vừa viết, cần fresh perspective | Worktree hoặc new session |
| Nhiều task độc lập có thể parallel | Multiple subagents |
| Debug session dài | Subagent để isolate |

---

## TEMPLATE: Skill Với Subagent

```markdown
---
name: [skill-name]
description: [Khi nào dùng skill này — Claude dùng field này để auto-invocation]
context: fork
agent: Explore
disable-model-invocation: true
---

# [Skill Name]

## Role
[Expert persona — ví dụ: "Senior security auditor"]

## Task
[Subagent này cần làm gì — càng cụ thể càng tốt]

## Steps

1. **[Bước 1]**
   [Hướng dẫn chi tiết]

2. **[Bước 2]**
   [Hướng dẫn chi tiết]

3. **[Bước 3]**
   [Hướng dẫn chi tiết]

## Output Format

Return a structured report to the main agent:

### FINDINGS
[Kết quả tổ chức theo severity hoặc category]

### SUMMARY
[Tóm tắt 2-3 câu về các phát hiện chính]

### RECOMMENDED NEXT STEPS
[Main agent nên làm gì với thông tin này]
```

---

## Xem Ví Dụ Thực Tế

→ [example-subagents.md](./example-subagents.md)

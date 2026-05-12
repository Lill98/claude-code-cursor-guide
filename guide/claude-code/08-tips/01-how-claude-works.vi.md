# Cách Claude Code Xử Lý Prompt Của Bạn

Hiểu cơ chế này giúp bạn prompt đúng cách và tránh lãng phí token.

---

## Khi Bạn Gõ Một Prompt

Claude **không đọc toàn bộ codebase**. Nó dùng search tools để tìm file liên quan trước, rồi mới đọc. Đây là flow thực tế:

```
Bạn gõ: "Fix the login bug"
                │
                ▼
┌───────────────────────────────────────┐
│  BƯỚC 1: Load CLAUDE.md              │
│  Tất cả CLAUDE.md files tích lũy     │
│  Token cố định mỗi session            │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│  BƯỚC 2: Parse Prompt                │
│  Trích keywords: "login", "bug"       │
│  Tìm file paths nếu có               │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│  BƯỚC 3: Search Codebase             │
│  grep -r "login" src/                 │
│  find . -name "*login*"               │
│  ls src/auth/                         │
│  → Ra danh sách file ứng viên        │
│    (tốn ít token)                    │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│  BƯỚC 4: Đọc File Liên Quan          │
│  Read src/auth/login.service.ts       │
│  Read src/auth/login.controller.ts    │
│  → Bước tốn token nhiều nhất         │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│  BƯỚC 5: Cascade Imports (NGUY HIỂM) │
│  Login service import UserService     │
│  UserService import PrismaService     │
│  PrismaService import...              │
│  → Có thể kéo theo 5–10 file nữa     │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│  BƯỚC 6: Plan + Implement            │
│  Với context đã tích lũy             │
└───────────────────────────────────────┘
```

---

## Bản Đồ Token Consumption

| Bước | Token tiêu thụ | Có thể tối ưu? |
|------|:--------------:|:--------------:|
| Load CLAUDE.md | Cố định, mỗi session | Giữ CLAUDE.md ngắn |
| Search (grep/find) | Ít — chỉ file names + matches | Ít |
| Đọc 2–3 file liên quan | Nhiều | Chỉ đường file path |
| Cascade imports | Rất nhiều | Dùng .claudeignore |
| Conversation history | Tích lũy theo thời gian | Dùng /compact, /clear |

---

## Hệ Quả Thực Tế

### Prompt mơ hồ → Claude tự tìm → tốn token

```
Bạn:   "Fix the login bug"
Claude: grep "login" → tìm 15 files → đọc 5–6 → cascade thêm 3–4 file nữa
Kết quả: ~8,000 tokens chỉ để hiểu context
```

### Prompt có file path → Claude đọc đúng ngay

```
Bạn:   "Fix login bug in src/auth/login.service.ts ~line 80"
Claude: Đọc đúng 1 file → ~800 tokens
Kết quả: Tiết kiệm 90% token cho bước load context
```

---

## Cơ Chế Context Window

### Context không reset giữa các message

Toàn bộ conversation tích lũy. Message thứ 40 "trả phí" cho 39 message trước:

```
Message  1:   800 tokens → tổng     800
Message  2:   600 tokens → tổng   1,400
...
Message 40:   200 tokens → tổng  45,000 tokens!
```

### Chất lượng giảm khi context đầy

```
0–30%   đầy  →  Chất lượng tốt nhất
30–60%  đầy  →  Bắt đầu "mất tập trung"
60–80%  đầy  →  Chất lượng giảm rõ
80%+    đầy  →  Auto-compact hoặc error
```

### Cache tokens tiết kiệm 90% khi đọc lại

Nếu CLAUDE.md ít thay đổi, Anthropic cache nó lại. Lần đọc sau chỉ tốn 10% giá token gốc. Không thay đổi format CLAUDE.md giữa các session — điều đó phá vỡ cache.

---

## Những Thứ Claude "Thấy" Trong Một Session

```
Session context bao gồm:
├── System prompt (ẩn — tools, permissions)
├── CLAUDE.md files (tất cả levels: global, project, folder)
├── Auto memory từ sessions trước
├── Conversation history (tất cả messages trong session này)
└── File contents đã đọc
```

Lệnh `/context` cho thấy phân tích chi tiết:

```
/context
→ System:       12,000 tokens
→ Tools:         8,000 tokens
→ Memory:        2,000 tokens
→ Conversation: 15,000 tokens
→ Total:        37,000 / 200,000 tokens (18%)
```

---

## File Được Đọc Vào Thì Ở Lại

Một khi file được đọc vào context, **nó ở đó cho đến khi bạn /clear**. Kể cả khi conversation đã chuyển sang topic khác, file content vẫn tiếp tục chiếm token.

**Hệ quả:** Session debug dài (đọc nhiều file để trace bug) làm bẩn context cho các task tiếp theo. Chất lượng giảm cho mọi thứ sau đó.

**Fix:** Chạy `/clear` hoặc dùng subagent cho các task investigation — subagent có context riêng biệt.

---

## Plan Mode — Khám Phá Trước Khi Thực Thi

Plan Mode (Shift+Tab) cho phép Claude đọc files, đặt câu hỏi, và hiểu vấn đề **mà không thực thi code**:

```
[Plan Mode]
Bạn:   "Add user invitation feature"
Claude: Đọc 5 files, đặt 2 câu hỏi làm rõ, tạo implementation plan
Bạn:   Review plan, điều chỉnh scope nếu cần
Bạn:   Shift+Tab → chuyển lại Normal Mode
Claude: Implement theo plan đã thống nhất
```

**Lợi ích:** Tránh 20 phút implement sai hướng rồi phải undo.

---

## .claudeignore — Chặn Claude Đọc File Không Cần

```gitignore
# .claudeignore (tạo ở project root)
node_modules/
dist/
build/
.next/
coverage/
*.generated.ts
prisma/migrations/
*.lock
*.log
public/assets/
```

Tác dụng: khi Claude search hay find files, những file này bị bỏ qua hoàn toàn — không bao giờ đọc dù có import.

---

## Checklist Trước Khi Prompt

- [ ] Đã chỉ rõ file path cụ thể chưa?
- [ ] Đã paste error message/log thực tế chưa (không phải tóm tắt)?
- [ ] Đã nói cách verify kết quả chưa (test command, expected output)?
- [ ] Session có đang "bẩn" từ debug trước không? (cân nhắc /clear)
- [ ] Task có đủ nhỏ và rõ ràng không?

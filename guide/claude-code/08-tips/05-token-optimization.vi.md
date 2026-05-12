# Token Optimization

Các kỹ thuật thực tế để giảm token consumption mà không hy sinh chất lượng. Sắp xếp từ impact cao nhất đến thấp nhất.

---

## 1. Giữ CLAUDE.md Ngắn và Tập Trung Vào Behavior

CLAUDE.md được load khi bắt đầu mỗi session và đọc lại mỗi message. Mỗi dòng tốn token lặp đi lặp lại.

**Quy tắc:**
- Chỉ thêm rule thực sự thay đổi hành vi của Claude
- Bỏ text giải thích — Claude không cần biết lý do tại sao
- Dùng câu ngắn, mệnh lệnh: "Filter all queries by firmId." không phải "Remember to always make sure that..."
- Tách theo folder: đặt rule riêng của module trong `src/modules/auth/CLAUDE.md` thay vì root

**Trước:**
```markdown
# Project Rules

This project is a NestJS backend. When you are working on this project, 
please remember that we use Prisma as our ORM and all database queries 
need to be multi-tenant aware, which means you should always filter by 
firmId when querying data. Also, we use Vitest for testing, not Jest.
```

**Sau:**
```markdown
- ORM: Prisma. All queries filter by firmId and deletedAt: null.
- Testing: Vitest (not Jest).
```

Kết quả: cùng instruction, giảm ~85% token mỗi session.

---

## 2. Dùng .claudeignore Để Chặn Thư Mục Lớn

Không có `.claudeignore`, Claude có thể đọc `node_modules/`, generated files, hoặc build output khi khám phá codebase. Những thứ này gần như không bao giờ hữu ích và đốt hàng nghìn token.

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
.git/
```

Tác dụng: grep và find bỏ qua hoàn toàn các thư mục này. Claude không bao giờ vô tình đọc một Prisma client được generate dài 50,000 dòng.

---

## 3. Dùng Subagents Cho File Exploration

Khi cần khám phá phần lớn codebase (hiểu kiến trúc, tìm tất cả usage của một pattern), dùng subagent. Subagent chạy trong context riêng biệt — các file read ở đó, không vào session chính.

```
Use a subagent to:
1. Read all files in src/modules/auth/
2. Find all places where the JWT token is validated
3. Return a summary of the validation flow (max 20 lines)

Do not read these files directly — delegate to the subagent.
```

File reads của subagent (có thể 10,000+ token) không xuất hiện trong context chính. Chỉ bản tóm tắt 20 dòng mới vào.

---

## 4. Parallel Sessions Với Git Worktrees

Chạy hai feature đồng thời trong một session trộn context và tăng token usage. Dùng git worktrees để mỗi feature có session sạch riêng.

```bash
# Session chính: invitation feature
# (đang mở)

# Tạo session song song cho feature thứ hai
git worktree add ../project-auth-refactor feature/auth-refactor
claude --worktree ../project-auth-refactor
```

Mỗi session chỉ trả phí cho context của nó. Không cross-contamination.

---

## 5. /compact và /clear Đúng Thời Điểm

Đừng chờ đến khi context đạt 80%+. Compact hoặc clear chủ động.

**Quy tắc ngón tay cái:**
- Sau khi hoàn thành task và trước khi bắt đầu task tiếp theo: `/clear`
- Ở 40–60% context trong task đang làm dở: `/compact "keep [info quan trọng]"`
- Sau session debug dài: luôn `/clear` trước khi bắt đầu task mới

Xem [03-session-management.md](./03-session-management.md) để biết bảng quyết định đầy đủ.

---

## 6. Giới Hạn Thinking Tokens

Extended thinking rất tốn kém. Giới hạn cho task thông thường.

**Trong `.claude/settings.json`:**
```json
{
  "env": {
    "MAX_THINKING_TOKENS": "8000"
  }
}
```

Mặc định là 32,000 cho extended thinking mode. 8,000 đủ cho hầu hết task implementation. Dùng `/effort max` một cách có chủ đích chỉ khi thực sự cần (quyết định kiến trúc phức tạp, debug vấn đề khó).

---

## 7. Chọn Model Theo Độ Phức Tạp

Đừng dùng Opus cho mọi thứ. Sonnet xử lý được 90% task phát triển hàng ngày với chi phí bằng 1/5.

| Loại Task | Model Khuyến Nghị |
|-----------|------------------|
| Code implementation | Sonnet (mặc định) |
| Bug fixing | Sonnet |
| Viết test | Sonnet |
| Q&A và lookup đơn giản | Haiku |
| Quyết định kiến trúc phức tạp | Opus |
| Debug lỗi không nhất quán | Opus |
| Refactor lớn trên nhiều file | Opus |

Chuyển bằng `/model sonnet` hoặc `/model opus` giữa session.

---

## 8. Chỉ Đường File Cụ Thể Thay Vì Mô Tả Mơ Hồ

Prompt mơ hồ kích hoạt tìm kiếm rộng. File path cụ thể bỏ qua hoàn toàn giai đoạn tìm kiếm.

| Kiểu Prompt | Token Cost |
|------------|------------|
| "Fix the auth bug" | ~8,000 tokens (search + cascade reads) |
| "Fix bug in @src/auth/login.service.ts line 80" | ~800 tokens (đọc một file) |

Khi bạn biết code liên quan ở đâu, luôn thêm path vào.

---

## 9. Chia Thành Focused Sessions Thay Vì Một Mega-Session

Một mega-session dài tích lũy context từ tất cả task. Nhiều session ngắn focused mỗi cái bắt đầu sạch.

**Anti-pattern:**
```
Session: design + implementation + debugging + refactor + tests + code review
→ Context đầy, các task cuối chạy trong context ô nhiễm ở mức 70%+
```

**Tốt hơn:**
```
Session 1: Design và plan (Plan Mode)    → /clear
Session 2: Implement core logic          → /clear
Session 3: Debug failing tests           → /clear
Session 4: Refactor và review cuối       → /clear
```

Mỗi session chạy ở chất lượng tối đa. Tổng chi phí token thường thấp hơn dù bắt đầu lại — không có noise tích lũy.

---

## 10. Session Notes Pattern Cho Liên Tục Giữa Sessions

Khi bắt đầu session mới, đừng đọc lại file để rebuild context. Dùng handoff note gọn.

**Cuối session:**
```
/btw Write a 15-line summary of: what was built, which files were modified,
the current state, and the next 3 steps. I'll use this to start the next session.
```

**Đầu session tiếp theo — paste note rồi đưa task ngay:**
```
[paste summary vào đây]

Next task: implement validateInviteInput() in invitation.service.ts.
Run npx vitest --run after.
```

Claude lấy context từ note (200 token) thay vì đọc lại file (3,000+ token).

---

## 11. Prompt Caching — Giữ CLAUDE.md Ổn Định

Anthropic cache nội dung CLAUDE.md giữa các API call. Token được cache chỉ tốn 10% so với uncached. Cache TTL là 5 phút; reset nếu nội dung file thay đổi.

**Maximize cache hit rate:**
- Không thêm note tạm thời vào CLAUDE.md trong session
- Không reformat hoặc sắp xếp lại CLAUDE.md giữa các session
- Kiểm tra cache hit rate với `/cost` — tìm "cache_read_input_tokens" trong output

Cache hit rate cao nghĩa là tiết kiệm 90% cho việc đọc CLAUDE.md trong cả ngày làm việc.

---

## 12. Theo Dõi Usage Với /cost, /stats, /context

Không thể tối ưu thứ bạn không đo.

```bash
/cost     # Tổng token session này + cache hit rate
/stats    # Số lần gọi tool, thời gian đã dùng, tổng chi phí
/context  # Phân tích: system / tools / memory / conversation
```

Chạy `/cost` đầu và cuối mỗi session để hiểu token đi đâu. So sánh trước/sau khi áp dụng kỹ thuật để verify hiệu quả thực sự.

---

## Bảng Ưu Tiên

| Kỹ Thuật | Impact | Effort Setup |
|----------|:------:|:------------:|
| CLAUDE.md ngắn, chỉ behavior | Cao | Thấp |
| .claudeignore | Cao | Rất thấp |
| Chỉ đường file path cụ thể | Cao | Không cần |
| Focused sessions (không mega-session) | Cao | Không cần |
| /compact và /clear đúng lúc | Cao | Không cần |
| Subagents cho exploration | Trung bình | Thấp |
| Session Notes cho liên tục | Trung bình | Thấp |
| Giới hạn thinking tokens | Trung bình | Thấp |
| Chọn model theo độ phức tạp | Trung bình | Không cần |
| Parallel sessions với worktrees | Trung bình | Trung bình |
| Prompt caching (CLAUDE.md ổn định) | Trung bình | Không cần |
| Theo dõi với /cost | Thấp (enabling) | Không cần |

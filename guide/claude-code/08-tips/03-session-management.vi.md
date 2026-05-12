# Session Management

Khi nào nên clear, compact, bắt đầu session mới, hoặc chạy song song — và tại sao điều này ảnh hưởng đến chất lượng output.

---

## Tại Sao Session Bị Xuống Cấp

Mỗi message, mỗi file Claude đọc, và mỗi lần gọi tool đều tích lũy trong context window. Claude không có "working memory" tự reset — nó luôn xử lý toàn bộ lịch sử. Khi context đầy, model phân bổ ngày càng nhiều attention cho nội dung cũ hơn, làm giảm hiệu suất cho task hiện tại.

Đây không phải lỗi của Claude; đây là cách transformer model hoạt động. Giải pháp là session hygiene.

---

## Ngưỡng Xuống Cấp Của Context

```
0–30%   Context dùng  →  Chất lượng đầy đủ. Làm việc thoải mái.
30–40%  Context dùng  →  Vùng cảnh báo. Cân nhắc wrap up hoặc compact.
40–70%  Context dùng  →  Chất lượng giảm rõ. Chạy /compact.
70–80%  Context dùng  →  Compact ngay hoặc bắt đầu session mới.
80%+    Context dùng  →  Auto-compact kích hoạt. Có thể gây lỗi hoặc cắt bớt.
```

Kiểm tra mức sử dụng hiện tại với `/context` hoặc theo dõi status line (bật/tắt bằng `/statusline`).

---

## Bảng Quyết Định

| Tình huống | Hành động khuyến nghị |
|-----------|-----------------------|
| Bắt đầu task hoàn toàn khác | `/clear` — xóa sạch để bắt đầu |
| Session dài, vẫn đang làm cùng task | `/compact` — nén lại, tiếp tục |
| Session bị ô nhiễm bởi debug noise | `/clear` — không kéo noise sang task mới |
| Claude đi sai hướng 10+ message | Esc+Esc checkpoint menu → rewind |
| Cần làm song song hai feature | `claude --worktree` — parallel sessions |
| Task khám phá file lớn (đọc nhiều file) | Subagent — context riêng biệt |
| Context ở 70%+ và task chưa xong | `/compact "keep [context chính]"` rồi tiếp tục |
| Context ở 80%+ | Session mới + Session Notes pattern |

---

## /clear vs /compact vs Session Mới

### `/clear`
- Xóa sạch mọi thứ: conversation history, tất cả file đã đọc, toàn bộ context
- Dùng khi: bắt đầu task mới không liên quan, sau khi đi sai hướng không thể rewind, sau debug session dài đã kết thúc
- Nhược điểm: mất tất cả — paste context quan trọng thủ công nếu task mới cần

### `/compact`
- Nén conversation thành bản tóm tắt trong khi vẫn giữ session Claude đang chạy
- Dùng khi: context cao nhưng vẫn đang làm dở task và muốn tiếp tục
- Có thể hướng dẫn: `/compact "keep the invitation service implementation and the failing test list"`
- Nhược điểm: một số chi tiết mất khi nén; những điểm tinh tế quan trọng có thể biến mất

### Session Mới
- Mở terminal mới / Claude Code instance mới
- Dùng khi: chuyển sang workstream song song, hoặc sau khi `/clear` xóa thứ bạn vẫn cần
- Kết hợp tốt nhất với Session Notes pattern để chuyển context có chủ đích

---

## Anti-Pattern Thường Gặp

### Kitchen Sink Sessions
```
Tệ: Một session làm design + implementation + debugging + code review + tests
    → Context đầy, các task cuối chất lượng thấp

Tốt: Một session cho một task focused. /clear giữa các task.
```

### Debug Pollution
```
Tệ: Fix bug A → debug session đọc 15 file → rồi nhờ Claude viết feature B
    → Claude có 15 file không liên quan trong context khi viết feature B

Tốt: Fix bug A → /clear → viết feature B trong session sạch
```

### Correction Loops
```
Tệ: 10 message cố gắng sửa hướng Claude đã đi sai
    → Mỗi lần sửa thêm context, không thực sự reset hiểu biết của model

Tốt: Esc+Esc → rewind về trước chỗ sai → hướng dẫn rõ ràng hơn
```

---

## Session Notes Pattern

Dùng cách này để chuyển context thiết yếu giữa các session mà không tốn token.

**Cuối session — tạo handoff note:**

```
/btw Summarize what we did, what files were changed, and what the next steps are. 
Keep it under 20 lines. I'll paste this at the start of the next session.
```

**Đầu session tiếp theo — paste vào:**

```
Context từ session trước:
- Đang implement InvitationService trong src/modules/invitation/
- Đã xong: inviteUser() với email validation và user creation
- Tiếp theo: implement validateInviteInput() và thêm email dispatch
- Ràng buộc quan trọng: mọi query phải filter theo firmId và deletedAt: null
```

Cách này cho Claude chính xác những gì nó cần — mà không cần đọc lại tất cả file từ đầu.

---

## Parallel Sessions với Worktrees

Git worktrees cho phép bạn có nhiều working directory từ cùng một repository, mỗi cái trên branch khác nhau. Mỗi Claude session trong worktree có context sạch riêng.

```bash
# Tạo worktree cho task song song
git worktree add ../project-feature-auth feature/auth-refactor
claude --worktree ../project-feature-auth

# Bây giờ bạn có hai Claude sessions:
# - Project chính: đang làm invitation feature
# - Worktree: refactor auth module
# Mỗi session có context riêng — không ảnh hưởng nhau
```

Tốt nhất cho: làm song song hai feature, hoặc giữ task chạy nền dài biệt lập.

---

## Subagents Để Cô Lập Context

Khi task yêu cầu đọc nhiều file (refactor quy mô lớn, phân tích codebase), giao cho subagent. Subagent có context riêng, làm việc, và trả kết quả — session chính của bạn vẫn sạch.

```
Prompt cho main session:
"Use a subagent to read all files in src/modules/auth/ and summarize 
the authentication flow. Return a 1-page summary."
```

File subagent đọc không tích lũy trong context chính. Chỉ bản tóm tắt cuối cùng mới vào.

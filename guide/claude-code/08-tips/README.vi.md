# Tips & Best Practices

> **Level 3 — Nâng cao.** Đọc phần này sau khi đã quen với Rules, Hooks, và Skills cơ bản.

Phần này giải thích cách Claude Code thực sự hoạt động khi bạn gõ prompt — để bạn hiểu điều gì đang xảy ra, tránh lãng phí token, và viết prompt hiệu quả hơn.

---

## Nội Dung

| File | Nội dung |
|------|---------|
| [01-how-claude-works.md](./01-how-claude-works.md) | Claude làm gì với prompt của bạn — từng bước |
| [02-built-in-commands.md](./02-built-in-commands.md) | Toàn bộ built-in commands và keyboard shortcuts |
| [03-session-management.md](./03-session-management.md) | Khi nào dùng /clear, /compact, hay tạo session mới |
| [04-prompting.md](./04-prompting.md) | Cách viết prompt hiệu quả — ví dụ trước/sau |
| [05-token-optimization.md](./05-token-optimization.md) | Kỹ thuật tiết kiệm token với bảng ưu tiên |

---

## 3 Nguyên Tắc Cốt Lõi

### 1. Context Window Là Tài Nguyên Quý Nhất

Mỗi file Claude đọc, mỗi message bạn gửi, mỗi output Claude tạo ra đều tốn token và tích lũy trong context window. Khi context đầy (~30–40%), chất lượng output bắt đầu giảm — Claude "mất tập trung".

**Hệ quả thực tế:** Một session làm nhiều task khác nhau sẽ cho kết quả tệ hơn nhiều session ngắn, mỗi cái một task.

### 2. Verification Loop Quan Trọng Hơn Prompt Dài

Cung cấp cách để Claude tự verify kết quả của mình:

```
Implement X. Then run `npm test` to verify. Fix any failures.
```

Cách này cho kết quả tốt hơn 2–3 lần so với chỉ nói "implement X."

### 3. Chỉ Đường Thay Vì Để Claude Tự Tìm

```
Tệ:  "Fix the login bug"
     → Claude grep khắp nơi, đọc nhiều file, tốn token

Tốt: "Fix login bug in src/auth/login.service.ts ~line 80"
     → Claude đọc đúng file ngay lập tức
```

---

## Quick Reference

```bash
/clear          # Bắt đầu session mới hoàn toàn
/compact        # Nén conversation, giữ lại thông tin chính
/memory         # Xem các CLAUDE.md file đang được load
/cost           # Token usage + cache hit rate
/context        # Phân tích token theo từng loại
Shift+Tab       # Chuyển chế độ: Normal → Auto-accept → Plan Mode
Esc+Esc         # Checkpoint menu (rewind về trạng thái trước)
/btw            # Câu hỏi phụ — không vào conversation history
```

# Built-in Commands & Keyboard Shortcuts

Tài liệu tham khảo đầy đủ về các built-in commands và shortcuts của Claude Code. Những lệnh này có sẵn trong mọi session — không cần setup.

---

## Session Control

| Command | Tác dụng |
|---------|---------|
| `/clear` | Xóa toàn bộ conversation và bắt đầu session mới. Toàn bộ context bị xóa sạch. Dùng khi session bị "bẩn" hoặc bạn bắt đầu task hoàn toàn mới. |
| `/compact` | Nén conversation thành bản tóm tắt. Giải phóng không gian context window trong khi giữ lại các quyết định và code quan trọng. |
| `/compact "focus"` | Compact với gợi ý focus: cho Claude biết phần nào cần giữ. Ví dụ: `/compact "keep the auth module changes"` |
| `/rewind` | Giống Esc+Esc — mở checkpoint menu để quay lại điểm trước trong conversation. |
| `/btw` | Đặt câu hỏi phụ mà không thêm vào conversation history. Tốt cho các lookup nhanh không muốn làm bẩn context. |
| `/cost` | Hiển thị token usage của session hiện tại và cache hit rate. Dùng để theo dõi hiệu quả sử dụng context. |
| `/context` | Phân tích token theo từng loại: system prompt, tools, memory, conversation. |
| `/stats` | Thống kê session gồm tổng token, số lần gọi tool, và thời gian đã dùng. |

---

## Chuyển Đổi Chế Độ

| Command / Shortcut | Tác dụng |
|--------------------|---------|
| `Shift+Tab` | Chuyển giữa các chế độ: **Normal** → **Auto-accept edits** → **Plan Mode** → quay lại Normal. |
| `/effort low` | Dùng ít thinking tokens. Tốt cho câu hỏi đơn giản và lookup. |
| `/effort medium` | Mức effort mặc định. |
| `/effort high` | Dùng extended thinking. Tốt hơn cho các quyết định kiến trúc phức tạp. |
| `/effort max` | Maximum thinking tokens. Dùng tiết kiệm — rất tốn kém. |

**Mô tả các chế độ:**
- **Normal** — Claude hỏi trước mỗi lần sửa file (mặc định)
- **Auto-accept** — Claude áp dụng tất cả edit mà không hỏi. Dùng khi chạy không cần giám sát.
- **Plan Mode** — Claude đọc file và lên kế hoạch nhưng không viết gì. Chuyển sang Normal Mode để thực thi.

---

## Chọn Model

| Command | Tác dụng |
|---------|---------|
| `/model sonnet` | Chuyển sang Claude Sonnet. Khuyến nghị mặc định — nhanh và tiết kiệm chi phí. |
| `/model opus` | Chuyển sang Claude Opus. Mạnh hơn cho lý luận phức tạp; đắt hơn. |
| `/model haiku` | Chuyển sang Claude Haiku. Nhanh và rẻ cho task đơn giản. |

Dùng `/cost` sau khi đổi model để so sánh chi phí token.

---

## Tùy Chỉnh

| Command | Tác dụng |
|---------|---------|
| `/init` | Quét project hiện tại và tạo file CLAUDE.md với các pattern và stack được phát hiện. |
| `/memory` | Xem tất cả CLAUDE.md files đang được load (global, project, folder levels). |
| `/rename "name"` | Đặt tên cho session này trong lịch sử session. |
| `/color` | Bật/tắt syntax highlighting. |
| `/statusline` | Bật/tắt status line (thanh token usage ở trên cùng). |
| `/voice` | Bật chế độ voice input (nơi được hỗ trợ). |

---

## Background Tasks

| Command | Tác dụng |
|---------|---------|
| `Ctrl+B` | Chạy session hiện tại ở background. Claude tiếp tục làm việc; bạn lấy lại terminal. Trả kết quả khi xong. |

Hữu ích cho các task dài (chạy test suite, tạo nhiều file) khi bạn muốn làm việc khác trong lúc Claude đang chạy.

---

## Keyboard Shortcuts

| Shortcut | Tác dụng |
|----------|---------|
| `Esc` | Dừng output hoặc action hiện tại của Claude ngay lập tức. |
| `Esc + Esc` | Mở checkpoint menu. Chọn trạng thái trước trong conversation để quay lại. |
| `Ctrl+S` | Stash draft prompt hiện tại mà không gửi. Lấy lại sau. |
| `Shift+Tab` | Chuyển giữa Normal / Auto-accept / Plan modes. |
| `Ctrl+B` | Gửi về background. |

---

## Shell Command Prefix

Thêm `!` vào đầu bất kỳ dòng nào để chạy như shell command trực tiếp trong prompt:

```
! cat src/auth/login.service.ts
Explain what this login service does and suggest improvements.
```

Cách này pipe output của shell vào thẳng prompt — không cần mở terminal riêng.

---

## Worktrees

```bash
claude --worktree feature-name
```

Mở Claude Code trong một git worktree riêng biệt. Mỗi worktree có working directory và Claude session riêng — hữu ích cho phát triển song song mà không cần switch branch trong workspace chính.

Xem [03-session-management.md](./03-session-management.md) để biết workflow parallel sessions đầy đủ.

# Tối Ưu Token Cho Vibe Coder

Dành cho những ai dùng Claude Code mà không hiểu sâu về cấu trúc codebase. Mục tiêu: nói "fix bug feature X" và Claude đi thẳng vào đúng file — không tốn token để tự tìm kiếm.

---

## Vấn Đề

Khi bạn gõ prompt mơ hồ, Claude phải tự tìm code ở đâu:

```
Bạn:   "Fix checkout bị bug"
Claude: grep -r "checkout" src/  → 47 files
        đọc 6-7 files để đoán file nào đúng
        cascade thêm 4-5 imports
        → ~12,000 tokens chỉ để hiểu code ở đâu
```

Khi Claude đã biết cấu trúc trước:

```
Bạn:   "Fix checkout bị bug"
Claude: đọc CLAUDE.md → thấy "Checkout: src/modules/checkout/"
        đọc spec/checkout.md → biết file nào quan trọng
        đọc checkout.service.ts → fix bug
        → ~1,200 tokens
```

**Setup 1 lần → tiết kiệm 90% mỗi session về sau.**

---

## Giải Pháp 1: Feature Map trong CLAUDE.md (bắt buộc, làm trước)

Tạo `CLAUDE.md` ở root project. Quan trọng nhất là bảng map tên feature → folder code.

```markdown
## Feature Map
Đọc spec tương ứng trước khi làm việc với feature nào.

| Feature         | Spec                    | Code                        |
|-----------------|-------------------------|-----------------------------|
| Checkout        | @spec/checkout.md       | src/modules/checkout/       |
| Giỏ hàng        | @spec/cart.md           | src/modules/cart/           |
| Auth / Login    | @spec/auth.md           | src/modules/auth/           |
| Đơn hàng        | @spec/orders.md         | src/modules/orders/         |
| Thông báo       | @spec/notifications.md  | src/modules/notifications/  |

## Tech Stack
- Framework: NestJS + TypeScript
- Database: PostgreSQL + Prisma
- Test: Jest — chạy: npm test -- --testPathPattern=[module]

## Rules
- Không sửa *.repository.ts trực tiếp — đi qua service layer
- Sau khi fix bug, luôn chạy test của module liên quan
```

**Giữ CLAUDE.md ngắn.** File này load mỗi session. Mỗi dòng thừa = token tốn mỗi ngày.  
Cú pháp `@spec/feature.md` có nghĩa là Claude chỉ đọc spec khi cần — không load hết ngay từ đầu.

---

## Giải Pháp 2: Folder spec/ — Một File Cho Mỗi Feature

Tạo folder `spec/` ở root project. Viết bằng ngôn ngữ tự nhiên — không cần biết code.

```
spec/
├── checkout.md
├── cart.md
├── auth.md
├── orders.md
└── notifications.md
```

### Template: spec/checkout.md

```markdown
## Feature Checkout

### Làm gì
Xử lý luồng mua hàng: validate giỏ hàng → tính giá → apply discount → tạo đơn → charge thanh toán.

### Files chính
- checkout.controller.ts  — API endpoints (/checkout, /checkout/confirm)
- checkout.service.ts      — logic chính, gọi cart + payment module
- checkout.repository.ts   — database queries (không sửa trực tiếp)
- dto/create-checkout.dto  — schema validate input

### Rules quan trọng
- Luôn lock cart trước khi tạo order (tránh race condition)
- Payment thất bại phải rollback order trong cùng transaction
- Discount code validate trong checkout.service.ts, không phải controller

### Hay bị bug ở đây
- Tính giá sai → checkout.service.ts → calculateTotal()
- Discount không apply → checkout.service.ts → applyDiscount()
- Order không lưu → checkout.repository.ts → createOrder()
```

### Cách Claude dùng

```
Bạn:   "Checkout bị lỗi khi apply discount code"
         ↓
Claude đọc CLAUDE.md → thấy "Checkout: @spec/checkout.md"
         ↓
Claude đọc spec/checkout.md → thấy "Discount → applyDiscount()"
         ↓
Claude đọc checkout.service.ts → fix function
```

Không tìm kiếm. Không cascade. Đi thẳng vào đúng chỗ.

---

## Giải Pháp 3: .claudeignore — Chặn Folder Claude Không Cần Đọc

Không có file này, Claude có thể vô tình đọc `node_modules/`, build output, file generated — lãng phí hàng nghìn token.

Tạo `.claudeignore` ở root project:

```gitignore
node_modules/
dist/
build/
.next/
coverage/
*.lock
*.log
*.generated.ts
prisma/migrations/
public/assets/
.git/
```

Impact cao nhất, effort thấp nhất. Làm này trước mọi thứ khác.

---

## Giải Pháp 4: .claude/rules/ — Tự Động Load Rule Theo File Path (nâng cao)

Nếu muốn rule tự load khi Claude edit file trong một module cụ thể — không cần bạn nhắc:

```
.claude/rules/
├── checkout.md
├── cart.md
└── auth.md
```

Format cho `.claude/rules/checkout.md`:

```markdown
---
paths:
  - "src/modules/checkout/**"
---

## Checkout rules
- checkout.service.ts: logic chính — giá, discount, tạo order
- checkout.repository.ts: DB queries — không sửa trực tiếp
- Luôn lock cart trước khi tạo order
- Payment thất bại → rollback order trong cùng transaction
```

Khi Claude edit bất kỳ file nào trong `src/modules/checkout/**`, rule này tự load. Bạn không cần làm gì.

**Khi nào dùng spec/ vs .claude/rules/:**

| | spec/ folder | .claude/rules/ |
|--|--|--|
| Trigger khi | Bạn đề cập tên feature | Claude edit file trong folder |
| Viết bằng | Ngôn ngữ tự nhiên, thoải mái | Ngắn, tập trung vào behavior |
| Tốt cho | Bug report, feature mới | Enforce code pattern tự động |

Hai cái có thể dùng song song. spec/ cho context, rules/ cho constraint.

---

## Giải Pháp 5: RTK — Nén Output Bash Tự Động

Nếu bạn đã cài [RTK](https://github.com/rtk-ai/rtk), đây là lớp tối ưu ở tầng thấp nhất — hoạt động trong suốt, không cần làm gì thêm.

### RTK làm gì

Trước mỗi lệnh Bash Claude gọi (grep, git log, docker logs...), RTK hook intercept và nén output trước khi kết quả đó nạp vào context:

```
Claude gọi: git log --all -p src/checkout/
RTK filter: giữ lại chỉ phần liên quan, bỏ noise
Claude nhận: output đã nén (98% nhỏ hơn với git log lớn)
```

### Cài đặt

```bash
# Cài RTK
brew install rtk-ai/tap/rtk   # hoặc xem docs tại github.com/rtk-ai/rtk

# Thêm vào ~/.claude/settings.json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{ "type": "command", "command": "rtk hook claude" }]
    }]
  }
}
```

### Kết quả thực tế

```bash
rtk gain   # xem token đã tiết kiệm

# Output ví dụ:
# Tokens saved: 3.1M / 4.9M → tiết kiệm 64.3%
# grep:    50% savings  (lệnh Claude dùng nhiều nhất khi tìm code)
# git log: 98% savings  (output raw rất lớn)
# ps aux:  98% savings
```

### Thứ tự ưu tiên kết hợp

```
RTK           → nén output bash (tự động, transparent)
.claudeignore → block folder không cần đọc (1 lần setup)
CLAUDE.md     → feature map (Claude biết đi đâu ngay)
spec/         → chi tiết từng feature (đọc khi cần, không load hết)
Session discipline → /clear sau mỗi task
```

---

## Session Discipline — Tiết Kiệm Token Không Cần Setup

### /clear sau mỗi task

```
Task 1: Fix checkout bug     → xong
/clear
Task 2: Thêm feature cart    → bắt đầu với context sạch
```

Không `/clear` → mọi file Claude đọc cho task 1 vẫn còn trong context, làm nặng task 2.

### /compact khi context 40–60%

```
/compact "giữ lại: bug discount checkout, đang fix applyDiscount(), chưa chạy test"
```

Claude tóm tắt conversation, chỉ giữ phần bạn chỉ định.

### Bắt đầu session với feature cụ thể

```
"Fix bug discount trong checkout. Đọc spec/checkout.md trước."
```

1 câu thêm = 200 token. Tiết kiệm Claude khỏi phải tự tìm.

---

## Bootstrap — Setup Một Lần Duy Nhất

Nếu bạn không biết cấu trúc repo, để Claude tự map:

```
"Explore repo này bằng subagent. Tìm tất cả feature chính và folder tương ứng.
Sau đó viết:
1. CLAUDE.md ở root với feature map
2. File spec/[feature].md cho từng feature với files chính và mô tả ngắn.
Mỗi spec file tối đa 30 dòng."
```

Claude tốn 1 session explore → viết hết context files → mọi session sau đều rẻ.

---

## Checklist Theo Thứ Tự

| Bước | Impact | Effort | Làm khi |
|------|:------:|:------:|---------|
| Thêm `.claudeignore` | Cao | 2 phút | Đầu tiên |
| Viết `CLAUDE.md` với feature map | Cao | 10 phút | Thứ hai |
| Viết `spec/` files mỗi feature | Cao | 20 phút | Thứ ba |
| Cài RTK + hook | Cao | 5 phút | Nếu chưa có |
| `/clear` sau mỗi task | Cao | 0 | Luôn luôn |
| Thêm `.claude/rules/` mỗi module | Trung bình | 15 phút | Khi cần |
| `/compact` khi context 40–60% | Trung bình | 0 | Khi session dài |

---

## Prompt Mẫu Cho Vibe Coder

```
# Fix bug
"[Tên feature] bị lỗi khi [mô tả triệu chứng].
Đọc spec/[feature].md trước, sau đó fix."

# Feature mới
"Thêm [mô tả] vào [tên feature].
Đọc spec/[feature].md trước để hiểu cấu trúc hiện tại."

# Không biết feature nào bị lỗi
"[Mô tả triệu chứng]. Tôi không biết feature nào liên quan.
Đọc CLAUDE.md để tìm đúng module, sau đó điều tra."
```

Thêm "Đọc spec/[feature].md trước" = 10 token. Tiết kiệm Claude khỏi tự tìm = hàng nghìn token.

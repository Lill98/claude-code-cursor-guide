# Ví dụ: Subagent trong Thực tế cho blog-api

Ba pattern thực tế áp dụng cho dự án blog-api (FastAPI + SQLAlchemy + PostgreSQL + Pydantic v2 + pytest).

---

## Ví dụ 1: Security Audit — Fan-out Pattern

Ba kiểm tra độc lập chạy đồng thời. Claude spawn cả ba subagent cùng lúc và chờ tất cả hoàn thành trước khi gộp kết quả.

**Prompt của người dùng:**
```
Dùng 3 Explore subagent song song để audit blog-api:

Subagent 1 — Thiếu Dependency require_role:
  Kiểm tra mọi router file trong app/routers/*.py.
  Với mỗi endpoint function (@router.get, @router.post, @router.patch, @router.delete),
  xác nhận có Depends(require_role(...)) trong tham số không.
  Trả về danh sách endpoint thiếu require_role.

Subagent 2 — Query Không Kiểm Tra Ownership:
  Tìm tất cả lời gọi update() và delete() trong app/services/*.py
  mà không có author_id filter trong mệnh đề where.
  Trả về đường dẫn file, số dòng và model đang được update.

Subagent 3 — Thiếu Soft Delete Filter:
  Tìm tất cả lời gọi db.query(...).filter(...) và db.query(...).all() trong app/
  mà không có deleted_at.is_(None) trong filter.
  Trả về đường dẫn file, số dòng và tên model.

Sau khi cả 3 hoàn thành, gộp kết quả thành một security report có tham chiếu file:dòng.
```

**Điều xảy ra:**

```
Phiên chính
  │
  ├─── spawn đồng thời ───▶ Subagent 1: Kiểm tra require_role
  │                             đọc tất cả router file
  │                             kiểm tra Depends(require_role) trên từng endpoint
  │                             trả về danh sách thiếu require_role
  │
  ├─── spawn đồng thời ───▶ Subagent 2: Ownership Query
  │                             grep các lời gọi update/delete trong service
  │                             kiểm tra author_id trong mệnh đề where
  │                             trả về danh sách query không an toàn
  │
  ├─── spawn đồng thời ───▶ Subagent 3: Soft Delete Filter
  │                             grep các lời gọi query/filter
  │                             kiểm tra deleted_at.is_(None)
  │                             trả về danh sách thiếu filter
  │
  ◀─── chờ cả 3 ──────────────────────────────────────────────────
  │
  └─── gộp thành security report
```

**Định dạng output mong đợi:**

```markdown
## Security Audit blog-api

### Thiếu Dependency require_role() (từ Subagent 1)
- app/routers/comments.py:34 — DELETE /comments/{id} không có Depends(require_role)
- app/routers/tags.py:18 — POST /tags không có Depends(require_role) (thao tác admin-only bị lộ)

### Query Không Kiểm Tra Ownership (từ Subagent 2)
- app/services/post_service.py:67 — db.query(Post).filter(Post.id == post_id).update(...)
  không có author_id trong filter
  Rủi ro: bất kỳ user đã xác thực nào cũng có thể ghi đè nội dung bài của author khác

### Thiếu Filter deleted_at.is_(None) (từ Subagent 3)
- app/services/comment_service.py:42 — db.query(Comment).filter(...).all()
  thiếu deleted_at.is_(None)
  Rủi ro: comment đã soft-deleted vẫn được trả về cho API consumer

### Tóm Tắt
- 2 endpoint thiếu require_role (nguy cơ bypass authentication)
- 1 service method thiếu ownership check (nguy cơ toàn vẹn dữ liệu)
- 1 query trả về bản ghi đã soft-deleted (nguy cơ nhất quán dữ liệu)

Hành động ưu tiên: thêm ownership check vào post_service.py:67 trước lần deploy tiếp theo.
```

Tổng thời gian thực thi là max(subagent 1, 2, 3) — không phải tổng cộng. Cả ba chạy đồng thời.

---

## Ví dụ 2: Writer / Reviewer Pattern

Session A implement tính năng mới trong cô lập. Session B mở một context hoàn toàn mới để review — không có lịch sử chung, không bị ảnh hưởng bởi bias từ Session A.

### Session A: Implement tính năng "publish post"

**Prompt trong Session A:**
```
Implement tính năng publish post cho blog-api.

Yêu cầu:
- Endpoint: PATCH /posts/{post_id}/publish
- Chỉ author của bài hoặc admin mới có thể publish
- Bài phải đang có status 'draft' — không thể publish bài đã published
- Khi thành công: đặt status thành 'published', đặt published_at=datetime.utcnow(), trả về bài đã cập nhật
- Khi thất bại:
    404 HTTPException nếu không tìm thấy bài hoặc đã soft-deleted (deleted_at không phải None)
    403 HTTPException nếu người gọi không phải owner (trừ khi role là 'admin')
    409 HTTPException nếu bài đã published

File cần tạo hoặc sửa:
- app/services/post_service.py — thêm method publish_post()
- app/routers/posts.py — thêm endpoint PATCH /posts/{post_id}/publish với Depends(require_role("admin", "author"))
- tests/test_post_service.py — thêm pytest test cho publish_post()
```

Session A tạo ra phần implementation. Developer commit hoặc lưu diff lại.

### Session B: Review trong Context Mới

Mở một Claude Code session mới (hoặc dùng `/clear` để reset context). Session B không có ký ức về quá trình suy nghĩ của Session A — review với con mắt trong sáng.

**Prompt trong Session B:**
```
Review implementation của tính năng "publish post" trong blog-api.
Kiểm tra diff hoặc đọc các file sau:
- app/services/post_service.py
- app/routers/posts.py
- tests/test_post_service.py

Tập trung vào:
1. Ownership check — publish_post() có kiểm tra post.author_id == current_user.id trước không?
2. Status transition validation — service có từ chối khi status đã là 'published' không?
3. Role enforcement — endpoint có Depends(require_role("admin", "author")) không? Reader có bị chặn không?
4. Soft delete — query có deleted_at.is_(None) để bài đã xóa không thể publish không?
5. HTTP code — 403 có dùng đúng cho lỗi authorization, 401 cho unauthenticated không? Có bị nhầm không?
6. Alembic — có migration được thêm nếu schema thay đổi (ví dụ: thêm cột published_at) không?
7. Test coverage — các trường hợp negative có được test không: sai author, đã published, không tồn tại?

Trả về feedback có cấu trúc: CRITICAL / WARNING / SUGGESTION / LGTM.
```

**Tại sao cần một session mới:**

Context của Session A chứa lý luận đằng sau implementation — nó có xu hướng biện hộ cho những quyết định đã đưa ra. Session B chỉ nhìn thấy output và áp dụng cùng góc nhìn phê phán như một human PR reviewer. Sự kết hợp này phát hiện các vấn đề mà self-review bỏ sót.

**Ví dụ output review từ Session B:**

```markdown
### CRITICAL
- app/services/post_service.py:89 — publish_post() query Post không có deleted_at.is_(None).
  Một bài đã soft-deleted có thể được publish qua endpoint này.
  Sửa: thêm .filter(Post.deleted_at.is_(None)) vào query.

### WARNING
- tests/test_post_service.py — không có test cho trường hợp status đã là 'published'.
  Path 409 HTTPException chưa được test.
  Thêm: def test_raises_conflict_when_already_published(...)

### SUGGESTION
- Xem xét trích xuất ownership check (post.author_id == current_user.id or current_user.role == "admin")
  thành một helper dùng chung (ví dụ: assert_owner_or_admin) để tránh duplicate logic
  giữa publish_post(), update_post() và delete_post().

### LGTM
- Depends(require_role("admin", "author")) được đặt đúng trên endpoint của router.
- 403 HTTPException được raise trước khi có bất kỳ DB write nào khi caller không phải owner.
- Response trả về post schema đầy đủ — nhất quán với các endpoint khác.
- Alembic migration đã được thêm cho cột published_at.
```

---

## Ví dụ 3: Security Audit Skill với `context: fork`

SKILL.md này chạy như một Explore subagent tự động khi được gọi. Trường `context: fork` khiến Claude Code tạo một context cô lập mới — skill không thể thấy cuộc hội thoại hiện tại hay làm ô nhiễm context chính với nội dung file.

`.claude/skills/security-audit/SKILL.md`:

```markdown
---
name: security-audit
description: Audit blog-api Python codebase for security issues — missing require_role dependencies, ownership checks, and soft-delete filters. Use when reviewing new endpoints or services.
context: fork
agent: Explore
disable-model-invocation: true
---

# security-audit

## Role
Bạn là Senior Security Engineer chuyên về bảo mật FastAPI REST API.
Bạn đang chạy như một Explore subagent cô lập, không có lịch sử hội thoại.
Nhiệm vụ của bạn là audit codebase blog-api và trả về report có cấu trúc cho main agent.

## Security Checks

### 1. Role Enforcement
- Chạy `find app/routers -name "*.py"` để liệt kê tất cả router file
- Với mỗi router file, đọc file và kiểm tra mọi route function
  (@router.get, @router.post, @router.patch, @router.delete) xem có
  Depends(require_role(...)) trong tham số không
- Flag bất kỳ route function nào thiếu require_role

### 2. Ownership Checks
- Chạy `grep -rn "\.update\|\.delete" app/services --include="*.py"`
- Với mỗi kết quả, đọc context xung quanh (±10 dòng)
- Flag bất kỳ lời gọi update hoặc delete nào có filter không chứa `author_id`
- Lưu ý: Admin bypass là chấp nhận được — chỉ flag nếu hoàn toàn không có role check

### 3. Soft Delete Filter
- Chạy `grep -rn "db\.query\|\.filter\|\.all()" app/services --include="*.py"`
- Với mỗi query, kiểm tra chuỗi filter có `deleted_at.is_(None)` không
- Flag bất kỳ query nào thiếu filter này

### 4. Hard Delete Detection
- Chạy `grep -rn "db\.delete\b" app/services --include="*.py"`
- Flag bất kỳ lời gọi db.delete() trực tiếp nào — tất cả xóa phải đặt deleted_at, không xóa hàng

## Steps

1. Chạy `find app/routers -name "*.py"` — thu thập danh sách router
2. Đọc từng router file, kiểm tra require_role trên mọi endpoint
3. Chạy grep ownership, đọc context xung quanh từng kết quả
4. Chạy grep query, kiểm tra deleted_at.is_(None) trên từng kết quả
5. Chạy grep delete, flag bất kỳ hard delete nào

## Output Format

Trả về cấu trúc này cho main agent:

### CRITICAL
[Vấn đề có thể dẫn đến truy cập trái phép hoặc hỏng dữ liệu — sửa trước khi deploy]

### WARNING
[Vấn đề làm yếu bảo mật — sửa trong sprint này]

### INFO
[Khoảng trống nhỏ — ưu tiên thấp]

### SUMMARY
Tổng: X critical, Y warning, Z info.
Khu vực rủi ro cao nhất: [tên module]
Hành động ưu tiên ngay: [một câu]
```

**Cách dùng:**
```
/security-audit
```

Claude spawn một Explore subagent trong forked context, nó chạy tất cả bốn kiểm tra trên toàn bộ codebase và trả về report có cấu trúc cho phiên chính của bạn. Lịch sử hội thoại của bạn vẫn sạch — không có nội dung file nào tích lũy vào working context của bạn.

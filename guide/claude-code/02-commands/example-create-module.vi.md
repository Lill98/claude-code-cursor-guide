# Ví dụ: Command `/create-module` cho blog-api

Đây là file `.claude/commands/create-module.md` thực tế dùng trong dự án `blog-api`.
Sao chép toàn bộ nội dung bên dưới vào `.claude/commands/create-module.md`.

---

```markdown
# create-module

## Purpose
Tạo một FastAPI module mới theo chuẩn blog-api, bao gồm tất cả boilerplate file và đăng ký vào app. Module được tạo ra sẽ có role-based access control, Pydantic v2 schema, soft delete, và pytest unit test.

## Usage
```
/create-module [module-name]
```

## Arguments
- `$ARGUMENTS`: Tên module ở dạng singular snake_case (ví dụ: `tag`, `comment`, `post`)

## Steps

1. **Đọc pattern từ module có sẵn**
   Đọc `app/routers/posts.py` và `app/services/post_service.py` để học chính xác:
   - Cách định nghĩa FastAPI router và đăng ký endpoint
   - Cách dùng `Depends(get_current_user)` và `Depends(require_role(...))` trong route signature
   - Cách service class được cấu trúc và inject vào router qua `Depends()`
   - Cách định nghĩa Pydantic v2 schema (model_config, field type, validator)
   - Pattern service method: `get_all`, `get_one`, `create`, `update`, `delete`
   - Cách implement soft delete (set `deleted_at`, không bao giờ xóa vật lý)

2. **Tạo các file cho module mới**
   Tạo các file sau. Thay `$ARGUMENTS` bằng tên module thực tế. Dùng PascalCase cho tên class (ví dụ: `comment` → `CommentService`, `CommentOut`).

   - `app/models/$ARGUMENTS.py` — SQLAlchemy model với `id`, `created_at`, `updated_at`, `deleted_at`
   - `app/schemas/$ARGUMENTS.py` — Pydantic v2 schema: `$NAMECreate`, `$NAMEUpdate`, `$NAMEOut`
   - `app/services/${ARGUMENTS}_service.py` — Service class với `get_all`, `get_one`, `create`, `update`, `delete` (soft)
   - `app/routers/${ARGUMENTS}s.py` — FastAPI router với CRUD endpoint dùng `Depends()`
   - `tests/test_${ARGUMENTS}_service.py` — pytest test dùng `MagicMock(spec=Session)`

3. **Implement SQLAlchemy model**
   Trong `app/models/$ARGUMENTS.py`:
   - Kế thừa từ `Base`
   - Thêm column: `id` (Integer primary key), `created_at`, `updated_at` (DateTime với server_default), `deleted_at` (DateTime nullable)
   - Thêm các column nghiệp vụ phù hợp với module

4. **Implement CRUD endpoint chuẩn**
   Router phải có các route sau:
   - `GET /` — `get_all` — admin và author có thể truy cập (author chỉ thấy record của mình)
   - `GET /{id}` — `get_one` — admin, author và reader có thể truy cập
   - `POST /` — `create` — admin và author có thể truy cập
   - `PUT /{id}` — `update` — admin có toàn quyền; author chỉ update record của mình
   - `DELETE /{id}` — soft delete — set `deleted_at = datetime.utcnow()`, không xóa khỏi DB; chỉ admin

   Dùng `Depends(require_role("admin", "author"))` để khai báo role yêu cầu cho từng endpoint.
   Dùng `Depends(get_current_user)` để lấy thông tin user đang đăng nhập từ JWT payload.

5. **Implement soft delete trong service**
   Mọi query `get_all` và `get_one` phải filter `Model.deleted_at == None`.
   Method `delete` phải set `record.deleted_at = datetime.utcnow()` rồi commit.
   Không bao giờ gọi `db.delete(record)`.

6. **Viết pytest unit test**
   Trong `tests/test_${ARGUMENTS}_service.py`:
   - Import `MagicMock` từ `unittest.mock` và `Session` từ `sqlalchemy.orm`
   - Tạo `mock_db = MagicMock(spec=Session)` cho mỗi test
   - Test tối thiểu: `get_all` chỉ trả về record chưa bị xóa, `delete` set `deleted_at` và không xóa record vật lý
   - Dùng pytest fixture và câu lệnh `assert` chuẩn

7. **Đăng ký router vào `app/main.py`**
   Mở `app/main.py` và thêm:
   ```python
   from app.routers import ${ARGUMENTS}s
   app.include_router(${ARGUMENTS}s.router, prefix="/${ARGUMENTS}s", tags=["${NAME}s"])
   ```
   Thêm import ở đầu file cùng với các import router khác.

   Sau đó kiểm tra từng file đã tạo:
   - Mọi SQLAlchemy query đều filter `Model.deleted_at == None`
   - Không có business logic trong router — chỉ gọi sang service
   - Schema dùng Pydantic v2 style (`model_config = ConfigDict(from_attributes=True)`)
   - `require_role()` được áp dụng cho mọi endpoint có giới hạn quyền truy cập
   - Router đã có mặt trong `app/main.py`

## Output

Các file sẽ được tạo:
```
app/models/$ARGUMENTS.py
app/schemas/$ARGUMENTS.py
app/services/${ARGUMENTS}_service.py
app/routers/${ARGUMENTS}s.py
tests/test_${ARGUMENTS}_service.py
```

File sẽ được chỉnh sửa:
- `app/main.py` (thêm import và lệnh `include_router`)

## Example
```
/create-module tag
```

Kết quả mong đợi:
- `app/models/tag.py`
- `app/schemas/tag.py`
- `app/services/tag_service.py`
- `app/routers/tags.py`
- `tests/test_tag_service.py`
- `app/main.py` (đã cập nhật — `app.include_router(tags.router, prefix="/tags", tags=["Tags"])`)
```

---

## Cách dùng

```bash
# Trong Claude Code CLI:
/create-module tag
/create-module comment
/create-module post
```

## Lưu ý

Command này hoạt động tốt nhất khi:
- Dự án đã có `CLAUDE.md` ghi rõ các convention (soft delete, tên role, pattern Pydantic v2)
- Có ít nhất một module mẫu (ví dụ: `post`) để Claude học pattern chính xác
- Migration Alembic cho model mới đã có sẵn hoặc yêu cầu Claude tạo trước
- `get_current_user`, `require_role()`, và JWT middleware đã được cài đặt trong `app/dependencies/`

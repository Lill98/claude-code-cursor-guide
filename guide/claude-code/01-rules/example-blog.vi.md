# Ví dụ: CLAUDE.md cho blog-api

Đây là file `CLAUDE.md` thực tế của dự án **blog-api**.
Sao chép toàn bộ nội dung bên dưới vào `CLAUDE.md` ở thư mục gốc của dự án.

---

````markdown
# blog-api

## Project Overview
- **Purpose:** REST API cho nền tảng blog đa vai trò với bài viết, bình luận và tag
- **Stack:** FastAPI, SQLAlchemy, PostgreSQL, Pydantic v2, pytest, Alembic
- **Type:** REST API
- **Domain:** Quản lý nội dung — author đăng bài, reader duyệt đọc, admin kiểm duyệt

## Architecture

Ứng dụng FastAPI với layout theo feature. Mỗi domain có router, service, schema, model và tests riêng:

```
blog-api/
├── app/
│   ├── main.py
│   ├── database.py          # engine, SessionLocal, Base
│   ├── models/
│   │   ├── user.py          # User model
│   │   ├── post.py          # Post model
│   │   ├── comment.py
│   │   └── tag.py
│   ├── schemas/
│   │   ├── user.py          # UserCreate, UserOut
│   │   ├── post.py          # PostCreate, PostUpdate, PostOut
│   │   └── comment.py
│   ├── routers/
│   │   ├── posts.py
│   │   ├── comments.py
│   │   └── users.py
│   ├── services/
│   │   ├── post_service.py
│   │   ├── comment_service.py
│   │   └── user_service.py
│   ├── dependencies/
│   │   ├── auth.py          # get_current_user, require_role
│   │   └── db.py            # get_db
│   └── core/
│       ├── security.py      # JWT utils
│       └── config.py        # Settings (pydantic-settings)
├── tests/
│   ├── conftest.py          # fixtures: mock_db, mock_author, mock_admin, mock_reader
│   ├── test_post_service.py
│   └── test_comment_service.py
├── alembic/
├── alembic.ini
└── pyproject.toml
```

## Quy ước cấu trúc Module/Router

Mỗi feature phải tuân theo layout chính xác sau:

```
app/
├── models/[name].py           # SQLAlchemy model
├── schemas/[name].py          # Pydantic schema input/output
├── routers/[name]s.py         # Chỉ xử lý HTTP, không có business logic
├── services/[name]_service.py # Toàn bộ business logic, nhận db: Session
└── tests/test_[name]_service.py
```

## Code Conventions

### Naming
- Files: `snake_case` (ví dụ: `post_service.py`, `comment_router.py`)
- Classes: `PascalCase` (ví dụ: `PostService`, `PostCreate`, `PostOut`)
- Functions/variables: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Database columns: `snake_case` (SQLAlchemy)

### FastAPI Patterns
- Router chỉ xử lý HTTP — không gọi DB trực tiếp, không có business logic
- Service chứa toàn bộ business logic và nhận `db: Session` như một parameter
- Dùng `Depends()` để inject auth và DB vào router
- Không import service trực tiếp từ router mà không qua `Depends(get_db)`

## Validation & Schema

**Luôn dùng Pydantic v2 schema cho toàn bộ input và output. Không bao giờ dùng raw dict.**

```python
# schemas/post.py
from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional

class PostCreate(BaseModel):
    title: str
    content: str
    tag_ids: list[int] = []

class PostOut(BaseModel):
    id: int
    title: str
    status: str
    author_id: int
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
```

- Dùng `model_config = ConfigDict(from_attributes=True)` cho tất cả output schema
- Dùng `PostOut` làm `response_model` cho mọi endpoint của router
- Không bao giờ để lộ `deleted_at` trong bất kỳ output schema nào

## Database (SQLAlchemy)

- Integer primary key với `autoincrement=True`
- Soft delete: `deleted_at: Optional[datetime] = None` trên User, Post và Comment — không bao giờ xóa cứng bản ghi
- Timestamps: `created_at` và `updated_at` trên mọi model
- Luôn lọc bản ghi đã xóa — không bao giờ bỏ sót điều kiện `.deleted_at.is_(None)`

```python
# Luôn lọc bản ghi đã soft delete
post = db.query(Post).filter(Post.id == id, Post.deleted_at.is_(None)).first()
if not post:
    raise HTTPException(status_code=404)
# Luôn kiểm tra quyền sở hữu
if post.author_id != current_user.id and current_user.role != "admin":
    raise HTTPException(status_code=403)
```

## Auth & Authorization

- JWT auth qua `OAuth2PasswordBearer`, inject bằng `Depends(get_current_user)`
- Kiểm soát truy cập theo role qua `Depends(require_role([...]))` — roles: `admin`, `author`, `reader`
- `current_user` chứa: `id`, `email`, `role`
- Admin có thể truy cập tất cả bản ghi. Author chỉ được chỉnh sửa bài của mình.
- Kiểm tra quyền sở hữu thuộc về service, không phải router.

```python
@router.delete("/{post_id}")
def delete_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["admin", "author"]))
):
    return post_service.delete(db, post_id, current_user)
```

## API Response Format

FastAPI tự động serialize qua `response_model=PostOut`. Không cần bọc response thủ công.

- Single object: trả về model instance trực tiếp
- List: trả về plain list — FastAPI serialize qua `response_model=list[PostOut]`
- Phân trang: trả về dict `{"items": [...], "total": n}` chỉ khi thực sự cần
- Service trả về model instance hoặc raise `HTTPException` — không trả raw dict

## Testing

**Dùng pytest với MagicMock. Không dùng unittest trực tiếp.**

```python
# tests/test_post_service.py
from unittest.mock import MagicMock
import pytest
from fastapi import HTTPException
from app.services.post_service import PostService

post_service = PostService()

def test_get_post_raises_404_when_not_found(mock_db):
    mock_db.query.return_value.filter.return_value.first.return_value = None
    with pytest.raises(HTTPException) as exc:
        post_service.get_post(mock_db, post_id=999)
    assert exc.value.status_code == 404
```

- Mock `db: Session` bằng `MagicMock()` — fixture định nghĩa trong `tests/conftest.py`
- File test đặt trong thư mục `tests/`: `test_post_service.py` test `services/post_service.py`
- Không test router — logic nằm trong service
- Fixture: `mock_db`, `mock_author`, `mock_admin`, `mock_reader` trong `conftest.py`

## DO
- Dùng Pydantic v2 schema cho tất cả kiểu request và response
- Luôn thêm `.filter(Model.deleted_at.is_(None))` trong mọi SQLAlchemy query
- Xác minh quyền sở hữu bài viết (`post.author_id == current_user.id`) trong service trước mọi thao tác ghi
- Áp dụng `Depends(require_role([...]))` cho mọi endpoint không public
- Raise `HTTPException` với status code rõ ràng (404, 403, 400, v.v.)
- Giữ trạng thái `Post.status` rõ ràng: `draft` → `published` chỉ qua một service method chuyên biệt

## DON'T
- Không gọi database trực tiếp từ router
- Không xóa cứng bản ghi — set `deleted_at` thay thế
- Không đặt business logic trong router
- Không cho phép author chỉnh sửa hoặc xóa bài của author khác
- Không để lộ `deleted_at` trong API response schema
- Không dùng raw dict làm input hoặc output — luôn định nghĩa Pydantic schema
````

---

## Path-Scoped Rules

Các file rule này nằm trong `.claude/rules/` và chỉ được load khi Claude đang làm việc với file khớp glob pattern. Chúng giữ cho `CLAUDE.md` ngắn gọn trong khi vẫn cung cấp context đúng nơi cần thiết.

### `.claude/rules/auth.md`

```markdown
---
paths:
  - "app/dependencies/**"
  - "app/routers/**"
---

# Auth & Authorization Rules

- Luôn inject auth qua `Depends(get_current_user)` — không bao giờ đọc JWT thủ công trong router.
- Dùng `Depends(require_role(["admin", "author"]))` cho mọi endpoint không public.
- Kiểm tra quyền sở hữu (`post.author_id == current_user.id`) thuộc về service, không phải router.
- Admin bỏ qua ownership — luôn kiểm tra `current_user.role != "admin"` trước khi raise 403.
- Shape của `current_user`: `id: int`, `email: str`, `role: str` (một trong `admin`, `author`, `reader`).
```

### `.claude/rules/testing.md`

```markdown
---
paths:
  - "tests/**"
---

# Testing Rules

- Dùng pytest với `MagicMock` — không dùng `unittest.TestCase` trực tiếp.
- Mock `db: Session` bằng `MagicMock()` — không bao giờ dùng database thật trong unit test.
- Tất cả fixture (`mock_db`, `mock_author`, `mock_admin`, `mock_reader`) định nghĩa trong `tests/conftest.py`.
- Chỉ test service — không viết test cho router (logic nằm trong service).
- Mỗi service method cần tối thiểu: một happy path test và một error case test.
- Luôn assert rằng `deleted_at.is_(None)` có mặt trong các DB query call.
```

---

## @import

Nếu `CLAUDE.md` vượt quá 200 dòng, tách ra bằng `@import`:

```markdown
# blog-api

@.claude/context/architecture.md
@.claude/context/conventions.md
@.claude/context/testing.md
```

Mỗi file được import sẽ load inline như thể nội dung nằm trực tiếp trong file gốc. Path tính tương đối so với `CLAUDE.md`. Dùng khi một section đủ dài để có file riêng, hoặc khi muốn version-control từng phần độc lập.

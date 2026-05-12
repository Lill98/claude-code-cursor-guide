# Ví dụ: Skill `/write-test` và `/review-pr` cho blog-api

Hai skill cho dự án blog-api (FastAPI + SQLAlchemy + PostgreSQL + Pydantic v2 + pytest).

Tạo `.claude/skills/write-test/SKILL.md` và `.claude/skills/review-pr/SKILL.md` với nội dung bên dưới.

> Nếu vẫn đang dùng `.claude/commands/`, copy vào `.claude/commands/write-test.md` cũng hoạt động.

---

## Skill 1: `/write-test`

`.claude/skills/write-test/SKILL.md`:

```markdown
---
name: write-test
description: Write comprehensive pytest unit tests for a FastAPI service in blog-api. Use when asked to write tests, add test coverage, or test a service file. Covers SQLAlchemy session mocking, ownership checks, and role-based access.
disable-model-invocation: false
---

# write-test

## Role
Bạn là Senior Python/FastAPI engineer với chuyên môn về unit testing, pytest và SQLAlchemy. Bạn hiểu sâu kiến trúc blog-api: JWT auth, role-based access control (admin / author / reader), Pydantic v2 schema và soft delete pattern.

## Context
Dự án blog-api sử dụng:
- **pytest** cho unit testing
- **unittest.mock.MagicMock(spec=Session)** để mock SQLAlchemy session (fixture `mock_db`)
- Service nhận tham số `db: Session` (không dùng DI container — gọi function hoặc method thông thường)
- Mọi query phải filter `deleted_at.is_(None)` theo soft delete pattern
- Author sở hữu bài viết của mình: kiểm tra qua `post.author_id == current_user.id`
- Lọc theo role: reader chỉ thấy bài published; author chỉ thấy bài của mình; admin thấy tất cả
- Exception: `HTTPException` với status code `404`, `403`, `409`
- Pydantic v2 schema được dùng cho toàn bộ validation request/response

## Input
$ARGUMENTS là đường dẫn đến file service cần viết test.
Ví dụ: `app/services/post_service.py`

## Task
Đọc file service, phân tích tất cả public function/method, sau đó viết pytest test toàn diện theo fixture strategy chuẩn của dự án.

## Analysis Steps

1. **Đọc file service**
   Đọc `$ARGUMENTS` và xác định:
   - Tất cả public function hoặc method
   - Tham số: `db: Session`, `current_user`, DTO
   - SQLAlchemy model đang query (Post, Comment, Tag, User)
   - HTTPException status code được raise

2. **Phân tích từng function**
   Với mỗi function, xác định:
   - Happy path (input hợp lệ, bản ghi tồn tại, đúng role)
   - Not found case (bản ghi không tồn tại, hoặc có `deleted_at`)
   - Forbidden case (author truy cập bài của author khác → 403)
   - Role-based filtering (reader chỉ nhận `status == "published"`)
   - Ownership check (update/delete kiểm tra `post.author_id == current_user.id`)
   - Soft delete behavior (delete đặt `deleted_at`, không gọi `db.delete()`)

3. **Thiết kế fixture**
   Dùng pytest fixture cho mock object tái sử dụng:
   - `mock_db` — `MagicMock(spec=Session)`
   - `mock_author`, `mock_admin`, `mock_reader` — User mock với role tương ứng
   - `mock_post` — Post mock với đầy đủ trường, `author_id` khớp với `mock_author.id`

4. **Viết test**
   Tổ chức theo tên function. Dùng cách đặt tên `def test_<function>_<scenario>` hoặc gom vào class.

## Output Format

Tạo file test tại `tests/services/test_post_service.py`:

```python
# tests/conftest.py
import pytest
from unittest.mock import MagicMock
from sqlalchemy.orm import Session


@pytest.fixture
def mock_db():
    return MagicMock(spec=Session)


@pytest.fixture
def mock_author():
    user = MagicMock()
    user.id = 1
    user.role = "author"
    return user


@pytest.fixture
def mock_admin():
    user = MagicMock()
    user.id = 99
    user.role = "admin"
    return user


@pytest.fixture
def mock_reader():
    user = MagicMock()
    user.id = 2
    user.role = "reader"
    return user


@pytest.fixture
def mock_post(mock_author):
    post = MagicMock()
    post.id = 1
    post.title = "Test Post"
    post.slug = "test-post"
    post.content = "Post content here."
    post.status = "draft"
    post.author_id = mock_author.id
    post.deleted_at = None
    return post


# tests/services/test_post_service.py
import pytest
from unittest.mock import MagicMock, patch
from fastapi import HTTPException

from app.services.post_service import (
    get_posts,
    get_post,
    create_post,
    update_post,
    publish_post,
    delete_post,
)


# ── get_posts ──────────────────────────────────────────────────────────────────

def test_get_posts_reader_sees_published_only(mock_db, mock_reader, mock_post):
    mock_post.status = "published"
    mock_db.query.return_value.filter.return_value.all.return_value = [mock_post]

    result = get_posts(db=mock_db, current_user=mock_reader)

    assert result == [mock_post]


def test_get_posts_author_sees_own_posts_only(mock_db, mock_author, mock_post):
    mock_db.query.return_value.filter.return_value.all.return_value = [mock_post]

    result = get_posts(db=mock_db, current_user=mock_author)

    assert result == [mock_post]


def test_get_posts_admin_sees_all(mock_db, mock_admin, mock_post):
    draft_post = MagicMock()
    draft_post.status = "draft"
    draft_post.deleted_at = None
    mock_db.query.return_value.filter.return_value.all.return_value = [mock_post, draft_post]

    result = get_posts(db=mock_db, current_user=mock_admin)

    assert len(result) == 2


def test_get_posts_returns_empty_list(mock_db, mock_reader):
    mock_db.query.return_value.filter.return_value.all.return_value = []

    result = get_posts(db=mock_db, current_user=mock_reader)

    assert result == []


# ── get_post ───────────────────────────────────────────────────────────────────

def test_get_post_returns_post_when_found(mock_db, mock_author, mock_post):
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post

    result = get_post(post_id=1, db=mock_db, current_user=mock_author)

    assert result == mock_post


def test_get_post_raises_404_when_not_found(mock_db, mock_author):
    mock_db.query.return_value.filter.return_value.first.return_value = None

    with pytest.raises(HTTPException) as exc_info:
        get_post(post_id=999, db=mock_db, current_user=mock_author)

    assert exc_info.value.status_code == 404


def test_get_post_raises_404_for_soft_deleted_post(mock_db, mock_author):
    # Bản ghi soft-deleted không được trả về (filter deleted_at)
    mock_db.query.return_value.filter.return_value.first.return_value = None

    with pytest.raises(HTTPException) as exc_info:
        get_post(post_id=1, db=mock_db, current_user=mock_author)

    assert exc_info.value.status_code == 404


# ── create_post ────────────────────────────────────────────────────────────────

def test_create_post_sets_author_id_and_draft_status(mock_db, mock_author):
    post_data = MagicMock()
    post_data.title = "New Post"
    post_data.slug = "new-post"
    post_data.content = "Content."

    def fake_refresh(obj):
        obj.id = 10
        obj.author_id = mock_author.id
        obj.status = "draft"

    mock_db.refresh.side_effect = fake_refresh

    result = create_post(post_in=post_data, db=mock_db, current_user=mock_author)

    mock_db.add.assert_called_once()
    mock_db.commit.assert_called_once()


def test_create_post_raises_409_for_duplicate_slug(mock_db, mock_author, mock_post):
    post_data = MagicMock()
    post_data.slug = "test-post"

    # Slug đã tồn tại
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post

    with pytest.raises(HTTPException) as exc_info:
        create_post(post_in=post_data, db=mock_db, current_user=mock_author)

    assert exc_info.value.status_code == 409


# ── update_post ────────────────────────────────────────────────────────────────

def test_update_post_succeeds_when_author_owns_it(mock_db, mock_author, mock_post):
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post
    update_data = MagicMock()
    update_data.title = "Updated Title"

    result = update_post(post_id=1, post_in=update_data, db=mock_db, current_user=mock_author)

    mock_db.commit.assert_called_once()


def test_update_post_raises_403_when_author_does_not_own_it(mock_db, mock_author, mock_post):
    mock_post.author_id = 50  # chủ sở hữu khác
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post
    update_data = MagicMock()

    with pytest.raises(HTTPException) as exc_info:
        update_post(post_id=1, post_in=update_data, db=mock_db, current_user=mock_author)

    assert exc_info.value.status_code == 403


def test_update_post_admin_can_update_any_post(mock_db, mock_admin, mock_post):
    mock_post.author_id = 999  # chủ sở hữu khác, nhưng admin bỏ qua kiểm tra
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post
    update_data = MagicMock()
    update_data.title = "Admin Edit"

    result = update_post(post_id=1, post_in=update_data, db=mock_db, current_user=mock_admin)

    mock_db.commit.assert_called_once()


def test_update_post_raises_404_when_post_not_found(mock_db, mock_author):
    mock_db.query.return_value.filter.return_value.first.return_value = None

    with pytest.raises(HTTPException) as exc_info:
        update_post(post_id=999, post_in=MagicMock(), db=mock_db, current_user=mock_author)

    assert exc_info.value.status_code == 404


# ── publish_post ───────────────────────────────────────────────────────────────

def test_publish_post_transitions_draft_to_published(mock_db, mock_author, mock_post):
    mock_post.status = "draft"
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post

    result = publish_post(post_id=1, db=mock_db, current_user=mock_author)

    assert mock_post.status == "published"
    mock_db.commit.assert_called_once()


def test_publish_post_raises_403_when_author_does_not_own_it(mock_db, mock_author, mock_post):
    mock_post.author_id = 50  # chủ sở hữu khác
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post

    with pytest.raises(HTTPException) as exc_info:
        publish_post(post_id=1, db=mock_db, current_user=mock_author)

    assert exc_info.value.status_code == 403


def test_publish_post_raises_404_when_post_not_found(mock_db, mock_author):
    mock_db.query.return_value.filter.return_value.first.return_value = None

    with pytest.raises(HTTPException) as exc_info:
        publish_post(post_id=999, db=mock_db, current_user=mock_author)

    assert exc_info.value.status_code == 404


# ── delete_post ────────────────────────────────────────────────────────────────

def test_delete_post_soft_deletes_by_setting_deleted_at(mock_db, mock_author, mock_post):
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post

    delete_post(post_id=1, db=mock_db, current_user=mock_author)

    assert mock_post.deleted_at is not None
    mock_db.commit.assert_called_once()
    mock_db.delete.assert_not_called()


def test_delete_post_raises_403_when_author_does_not_own_it(mock_db, mock_author, mock_post):
    mock_post.author_id = 50  # chủ sở hữu khác
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post

    with pytest.raises(HTTPException) as exc_info:
        delete_post(post_id=1, db=mock_db, current_user=mock_author)

    assert exc_info.value.status_code == 403


def test_delete_post_admin_can_delete_any_post(mock_db, mock_admin, mock_post):
    mock_post.author_id = 999  # chủ sở hữu khác
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post

    delete_post(post_id=1, db=mock_db, current_user=mock_admin)

    assert mock_post.deleted_at is not None
    mock_db.commit.assert_called_once()


def test_delete_post_raises_404_when_post_not_found(mock_db, mock_author):
    mock_db.query.return_value.filter.return_value.first.return_value = None

    with pytest.raises(HTTPException) as exc_info:
        delete_post(post_id=999, db=mock_db, current_user=mock_author)

    assert exc_info.value.status_code == 404
```

## Quality Checklist
Trước khi hoàn thành, kiểm tra:
- [ ] Mỗi public function có ít nhất 2 test case (happy path + error)
- [ ] Query được xác nhận có filter `deleted_at.is_(None)`
- [ ] Ownership check được test: author trên bài của mình (pass), author trên bài người khác (403)
- [ ] Role-based filtering được test: reader chỉ nhận published, admin nhận tất cả
- [ ] `publish_post` chỉ cho phép chuyển từ draft → published
- [ ] `delete_post` dùng soft delete (`post.deleted_at = datetime.utcnow()`) — không bao giờ gọi `db.delete()`
- [ ] Tất cả fixture được định nghĩa trong `conftest.py` và dùng chung giữa các module test
- [ ] HTTPException status code đúng: 404 not found, 403 forbidden, 409 conflict

## Example

Input: `/write-test app/services/post_service.py`

Claude sẽ:
1. Đọc `app/services/post_service.py`
2. Xác định các function: `get_posts`, `get_post`, `create_post`, `update_post`, `publish_post`, `delete_post`
3. Tạo `tests/services/test_post_service.py` với khoảng 130-160 dòng test bao gồm role filtering, ownership check, soft delete và status transition
```

---

## Skill 2: `/review-pr`

`.claude/skills/review-pr/SKILL.md`:

```markdown
---
name: review-pr
description: Review code changes in blog-api against security (ownership checks, require_role dependencies), Pydantic v2 validation, soft delete pattern, and test coverage standards. Use when reviewing PRs or staged changes.
disable-model-invocation: true
---

# review-pr

## Role
Bạn là Senior Python Engineer và Security Reviewer của blog-api. Bạn review code với tiêu chuẩn cao về bảo mật (ownership isolation, role enforcement), chất lượng code và khả năng bảo trì.

## Context
blog-api là một REST API đa role (admin / author / reader) xây dựng trên FastAPI và SQLAlchemy. Các bug nghiêm trọng nhất là:
1. Thiếu dependency `require_role()` trên endpoint — bất kỳ user đã xác thực nào cũng có thể gọi
2. Thiếu kiểm tra ownership `post.author_id == current_user.id` — author có thể sửa bài của author khác
3. Hard delete — tất cả xóa phải đặt `deleted_at`, không bao giờ gọi `db.delete(obj)`
4. Thiếu filter `deleted_at.is_(None)` — bản ghi đã soft-deleted rò rỉ vào response

Stack: FastAPI + SQLAlchemy + PostgreSQL + Pydantic v2 + pytest.

## Task
Review tất cả staged changes (`git diff --staged`) hoặc file được chỉ định trong $ARGUMENTS. Cung cấp feedback có cấu trúc theo mức độ nghiêm trọng.

## Analysis Steps

1. **Security scan** — Ưu tiên cao nhất
   - Mọi endpoint router có khai báo dependency `require_role(...)` không (hoặc tương đương)?
   - Mọi thao tác update/delete có kiểm tra `post.author_id == current_user.id` không (trừ admin)?
   - Có bất kỳ lời gọi `db.delete(obj)` nào không? (hard delete — phải là soft delete)
   - Slug có được kiểm tra uniqueness trước khi create/update không?
   - Toàn bộ input có được validate qua Pydantic schema không? (không dùng `dict` thô hay `request.json()` chưa validate)

2. **Data integrity**
   - Mọi query có filter `deleted_at.is_(None)` không?
   - `get_posts` có áp dụng role-based filtering không (reader: chỉ published; author: bài của mình; admin: tất cả)?
   - `publish_post` có validate status hiện tại là `"draft"` trước khi chuyển trạng thái không?
   - Slug uniqueness có được enforce ở service layer trước khi ghi không?

3. **Code quality**
   - Có business logic trong router/controller không? (không được phép — chỉ service)
   - Request/response model có dùng Pydantic v2 schema không?
   - Service có trả về SQLAlchemy model instance hoặc dữ liệu đã validate qua Pydantic không? (không dùng dict thô)
   - Exception type có đúng không: `HTTPException(status_code=404)`, `403`, `409`?

4. **Test coverage**
   - Các service function mới có pytest test tương ứng không?
   - Ownership check có ít nhất một negative test (403) không?
   - Soft delete behavior có được kiểm tra (`deleted_at` được đặt, `db.delete` không được gọi) không?
   - `conftest.py` có cung cấp fixture `mock_db`, `mock_author`, `mock_admin`, `mock_reader` không?

## Output Format

### CRITICAL (phải sửa trước khi merge)
[Vấn đề liên quan đến bảo mật, toàn vẹn dữ liệu, hoặc thiếu auth]

### WARNING (nên sửa)
[Vấn đề liên quan đến convention, thiếu test, hoặc validation chưa đầy đủ]

### SUGGESTION (cải tiến tùy chọn)
[Cải tiến nên có]

### LGTM
[Những phần được triển khai tốt]
```

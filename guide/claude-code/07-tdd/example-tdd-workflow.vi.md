# Ví dụ: TDD Workflow — Publish Post (blog-api)

Hướng dẫn end-to-end về TDD workflow sử dụng một tính năng thực tế từ `blog-api`. Minh họa cách đi từ spec file đến test bị skip rồi test pass, với feedback test tự động sau mỗi Claude task.

**Stack:** FastAPI + SQLAlchemy + PostgreSQL + Pydantic v2 + pytest + Alembic

---

## Spec

Spec bên dưới thường được tạo bởi `/research-ticket BLOG-14`. Ở đây hiển thị inline để bạn thấy chính xác workflow bắt đầu từ đâu.

```markdown
# Spec: BLOG-14 — Publish Post

## Tổng quan
Author có thể chuyển draft post của họ sang trạng thái published.
Sau khi published, bài viết trở nên công khai và không thể publish lại.

## Acceptance Criteria
- [ ] AC01: Chỉ author của post (hoặc admin) mới có thể publish
- [ ] AC02: Chỉ post có status "draft" mới được publish — re-publish bị từ chối
- [ ] AC03: Publish đặt status thành "published" và ghi lại timestamp published_at
- [ ] AC04: Trả về 404 nếu post không tồn tại hoặc đã bị soft-delete
- [ ] AC05: Trả về 403 nếu user yêu cầu không phải author hoặc admin
```

---

## Bước 1: Chạy `/spec-to-tests`

```
/spec-to-tests specs/publish-post.md tests/test_post_service.py
```

Claude đọc spec, trích xuất một behavior cho mỗi AC item, và tạo hai file.

---

## Bước 2: File Test Được Tạo

**`tests/test_post_service.py`** — toàn bộ là stub, chưa có gì được implement:

```python
import pytest
from unittest.mock import MagicMock
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.services.post_service import PostService


class TestPublishPost:
    @pytest.mark.skip(reason="not implemented — AC01: author can publish own post")
    def test_author_can_publish_own_draft(self, mock_db, mock_author, mock_post):
        pass

    @pytest.mark.skip(reason="not implemented — AC01: admin can publish any post")
    def test_admin_can_publish_any_post(self, mock_db, mock_admin, mock_post):
        pass

    @pytest.mark.skip(reason="not implemented — AC02: cannot publish already published post")
    def test_raises_conflict_when_already_published(self, mock_db, mock_author, mock_post):
        pass

    @pytest.mark.skip(reason="not implemented — AC03: sets published_at timestamp")
    def test_sets_published_at_on_publish(self, mock_db, mock_author, mock_post):
        pass

    @pytest.mark.skip(reason="not implemented — AC04: raises 404 when post not found")
    def test_raises_404_when_post_not_found(self, mock_db, mock_author):
        pass

    @pytest.mark.skip(reason="not implemented — AC05: raises 403 for non-author non-admin")
    def test_raises_403_for_reader(self, mock_db, mock_reader, mock_post):
        pass
```

---

## Bước 3: Scaffold Service Được Tạo

**`app/services/post_service.py`** — được tạo cùng với file test:

```python
from sqlalchemy.orm import Session

from app.models import Post, User


class PostService:
    def publish_post(self, db: Session, post_id: int, current_user: User) -> Post:
        return None
```

Cả hai file đều tồn tại. Dự án chạy được. Tất cả test ở trạng thái skipped.

---

## Bước 4: Xác nhận Test ở Trạng thái Skip

Chạy pytest để xác nhận trạng thái khởi đầu:

```bash
pytest tests/test_post_service.py -v
```

Kết quả:

```
============================= test session starts ==============================
collected 6 items

tests/test_post_service.py::TestPublishPost::test_author_can_publish_own_draft SKIPPED (not implemented — AC01: author can publish own post)
tests/test_post_service.py::TestPublishPost::test_admin_can_publish_any_post SKIPPED (not implemented — AC01: admin can publish any post)
tests/test_post_service.py::TestPublishPost::test_raises_conflict_when_already_published SKIPPED (not implemented — AC02: cannot publish already published post)
tests/test_post_service.py::TestPublishPost::test_sets_published_at_on_publish SKIPPED (not implemented — AC03: sets published_at timestamp)
tests/test_post_service.py::TestPublishPost::test_raises_404_when_post_not_found SKIPPED (not implemented — AC04: raises 404 when post not found)
tests/test_post_service.py::TestPublishPost::test_raises_403_for_reader SKIPPED (not implemented — AC05: raises 403 for non-author non-admin)

========================= 6 skipped in 0.18s ==========================
```

Đây là trạng thái "red". Chưa có logic nào — tất cả test là pending stub. Số lượng skip sẽ giảm về không khi từng behavior được implement.

---

## Bước 5: Implement Method

Yêu cầu Claude implement `publish_post` từng behavior một:

```
Implement publish_post trong app/services/post_service.py để các skipped test pass.
Query post với deleted_at.is_(None), kiểm tra quyền sở hữu, enforce draft-only rule,
sau đó đặt status="published" và published_at=datetime.utcnow().
```

**`app/services/post_service.py` hoàn chỉnh:**

```python
from datetime import datetime

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import Post, User


class PostService:
    def publish_post(self, db: Session, post_id: int, current_user: User) -> Post:
        post = db.query(Post).filter(Post.id == post_id, Post.deleted_at.is_(None)).first()
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        if post.author_id != current_user.id and current_user.role != "admin":
            raise HTTPException(status_code=403, detail="Not authorized")
        if post.status == "published":
            raise HTTPException(status_code=409, detail="Post is already published")
        post.status = "published"
        post.published_at = datetime.utcnow()
        db.commit()
        db.refresh(post)
        return post
```

---

## Bước 6: Implement Từng Test Một

Xóa `@pytest.mark.skip` khỏi từng test và điền assertion vào. Ba ví dụ hoàn chỉnh:

```python
import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import Post, User
from app.services.post_service import PostService


@pytest.fixture
def service():
    return PostService()


@pytest.fixture
def mock_db():
    return MagicMock(spec=Session)


@pytest.fixture
def mock_author():
    user = MagicMock(spec=User)
    user.id = 1
    user.role = "author"
    return user


@pytest.fixture
def mock_admin():
    user = MagicMock(spec=User)
    user.id = 2
    user.role = "admin"
    return user


@pytest.fixture
def mock_reader():
    user = MagicMock(spec=User)
    user.id = 3
    user.role = "reader"
    return user


@pytest.fixture
def mock_post():
    post = MagicMock(spec=Post)
    post.id = 10
    post.author_id = 1
    post.status = "draft"
    post.deleted_at = None
    return post


class TestPublishPost:
    def test_author_can_publish_own_draft(self, service, mock_db, mock_author, mock_post):
        mock_db.query.return_value.filter.return_value.first.return_value = mock_post

        result = service.publish_post(mock_db, post_id=10, current_user=mock_author)

        assert mock_post.status == "published"
        assert isinstance(mock_post.published_at, datetime)
        mock_db.commit.assert_called_once()
        mock_db.refresh.assert_called_once_with(mock_post)
        assert result is mock_post

    def test_admin_can_publish_any_post(self, service, mock_db, mock_admin, mock_post):
        # post.author_id=1, admin.id=2 — user khác nhau nhưng admin bypass ownership
        mock_db.query.return_value.filter.return_value.first.return_value = mock_post

        result = service.publish_post(mock_db, post_id=10, current_user=mock_admin)

        assert mock_post.status == "published"
        assert result is mock_post

    def test_raises_403_for_reader(self, service, mock_db, mock_reader, mock_post):
        # post.author_id=1, reader.id=3 — không phải owner và không phải admin
        mock_db.query.return_value.filter.return_value.first.return_value = mock_post

        with pytest.raises(HTTPException) as exc_info:
            service.publish_post(mock_db, post_id=10, current_user=mock_reader)

        assert exc_info.value.status_code == 403
```

---

## Bước 7: pytest Output — Tất Cả Pass

```bash
pytest tests/test_post_service.py -v
```

Kết quả:

```
============================= test session starts ==============================
collected 6 items

tests/test_post_service.py::TestPublishPost::test_author_can_publish_own_draft PASSED
tests/test_post_service.py::TestPublishPost::test_admin_can_publish_any_post PASSED
tests/test_post_service.py::TestPublishPost::test_raises_conflict_when_already_published PASSED
tests/test_post_service.py::TestPublishPost::test_sets_published_at_on_publish PASSED
tests/test_post_service.py::TestPublishPost::test_raises_404_when_post_not_found PASSED
tests/test_post_service.py::TestPublishPost::test_raises_403_for_reader PASSED

========================= 6 passed in 0.34s ==========================
```

Tất cả 6 test đều pass. Số lượng skip bây giờ bằng không.

---

## Bước 8: Kết quả Stop Hook

Stop hook trong `.claude/hooks/run-tests.sh` tự động chạy sau mỗi Claude task. Sau khi implement `publish_post`, console hiển thị:

```
Running unit tests...
============================= test session starts ==============================
collected 6 items

tests/test_post_service.py::TestPublishPost::test_author_can_publish_own_draft PASSED
tests/test_post_service.py::TestPublishPost::test_admin_can_publish_any_post PASSED
tests/test_post_service.py::TestPublishPost::test_raises_conflict_when_already_published PASSED
tests/test_post_service.py::TestPublishPost::test_sets_published_at_on_publish PASSED
tests/test_post_service.py::TestPublishPost::test_raises_404_when_post_not_found PASSED
tests/test_post_service.py::TestPublishPost::test_raises_403_for_reader PASSED

========================= 6 passed in 0.34s ==========================
All tests passed.

==============================
  Claude has finished the task
==============================
```

Bạn thấy kết quả trước khi chạy `git add`. Không cần lệnh bổ sung nào.

**Cấu hình hook** (`.claude/settings.json`):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/lint-fix.sh" }]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/run-tests.sh" }
        ]
      }
    ]
  }
}
```

---

## Bước 9: Pre-commit Hook với pre-commit Library

Cài `pre-commit` để bắt buộc test gate khi commit — áp dụng cho tất cả thành viên trong team, không chỉ người dùng Claude Code:

```bash
pip install pre-commit
```

**`.pre-commit-config.yaml`** (thêm vào thư mục gốc của repo):

```yaml
repos:
  - repo: local
    hooks:
      - id: pytest
        name: pytest
        entry: pytest --tb=short -q
        language: system
        pass_filenames: false
```

Kích hoạt hook:

```bash
pre-commit install
git add .pre-commit-config.yaml && git commit -m "chore: add pre-commit pytest gate"
```

**Khi tất cả test pass**, `git commit` hoạt động bình thường:

```
$ git commit -m "feat(post): implement publish_post"
[pytest] ........................................
pytest...................................................................Passed
[main a3f9c12] feat(post): implement publish_post
```

**Khi test thất bại**, commit bị từ chối:

```
$ git commit -m "feat(post): implement publish_post"
[pytest] ........................................
FAILED tests/test_post_service.py::TestPublishPost::test_raises_conflict_when_already_published
- AssertionError: assert 409 == 409 ... HTTPException not raised

pytest...................................................................Failed
- hook id: pytest
- exit code: 1
```

Sửa test thất bại, chạy lại `git commit`. Gate này đảm bảo code lỗi không bao giờ vào nhánh main.

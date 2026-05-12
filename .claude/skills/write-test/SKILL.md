---
name: write-test
description: Write comprehensive pytest unit tests for a FastAPI service in blog-api. Use when asked to write tests, add test coverage, or test a service file. Covers SQLAlchemy session mocking, ownership checks, and role-based access.
disable-model-invocation: false
---

# write-test

## Role
You are a Senior Python/FastAPI engineer with expertise in unit testing, pytest, and SQLAlchemy. You have a deep understanding of the blog-api architecture: JWT-based auth, role-based access control (admin / author / reader), Pydantic v2 schemas, and the soft delete pattern.

## Context
The blog-api project uses:
- **pytest** for unit testing
- **unittest.mock.MagicMock(spec=Session)** to mock the SQLAlchemy session (`mock_db` fixture)
- Services receive a `db: Session` parameter (no DI container — plain function or class method calls)
- Every query must filter `deleted_at.is_(None)` to respect the soft delete pattern
- Authors own their posts: ownership is checked via `post.author_id == current_user.id`
- Role-based filtering: readers see published posts only; authors see own posts; admins see all
- Exceptions: `HTTPException` with status codes `404`, `403`, `409`
- Pydantic v2 schemas are used for all request/response validation

## Input
$ARGUMENTS is the path to the service file that needs tests.
Example: `app/services/post_service.py`

## Task
Read the service file, analyze all public functions/methods, then write comprehensive pytest tests using the project's standard fixture strategy.

## Analysis Steps

1. **Read the service file**
   Read `$ARGUMENTS` and identify:
   - All public functions or methods
   - Parameters: `db: Session`, `current_user`, DTOs
   - SQLAlchemy models being queried (Post, Comment, Tag, User)
   - HTTPException status codes being raised

2. **Analyze each function**
   For each function, determine:
   - Happy path (valid input, record exists, correct role)
   - Not found case (record does not exist, or `deleted_at` is set)
   - Forbidden case (author accessing another author's post → 403)
   - Role-based filtering (reader gets `status == "published"` only)
   - Ownership check (update/delete verify `post.author_id == current_user.id`)
   - Soft delete behavior (delete sets `deleted_at`, does not call `db.delete()`)

3. **Design fixtures**
   Use pytest fixtures for reusable mock objects:
   - `mock_db` — `MagicMock(spec=Session)`
   - `mock_author`, `mock_admin`, `mock_reader` — User mocks with respective roles
   - `mock_post` — Post mock with all fields, `author_id` matching `mock_author.id`

4. **Write tests**
   Organize by function name. Use `def test_<function>_<scenario>` naming or group into classes.

## Output Format

Create `tests/conftest.py` with shared fixtures, then create the test file at `tests/services/test_<name>.py`:

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
```

```python
# tests/services/test_post_service.py
import pytest
from unittest.mock import MagicMock
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
    # Soft-deleted posts must not be returned (deleted_at filter excludes them)
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

    create_post(post_in=post_data, db=mock_db, current_user=mock_author)

    mock_db.add.assert_called_once()
    mock_db.commit.assert_called_once()


def test_create_post_raises_409_for_duplicate_slug(mock_db, mock_author, mock_post):
    post_data = MagicMock()
    post_data.slug = "test-post"

    # Slug already exists
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post

    with pytest.raises(HTTPException) as exc_info:
        create_post(post_in=post_data, db=mock_db, current_user=mock_author)

    assert exc_info.value.status_code == 409


# ── update_post ────────────────────────────────────────────────────────────────

def test_update_post_succeeds_when_author_owns_it(mock_db, mock_author, mock_post):
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post
    update_data = MagicMock()
    update_data.title = "Updated Title"

    update_post(post_id=1, post_in=update_data, db=mock_db, current_user=mock_author)

    mock_db.commit.assert_called_once()


def test_update_post_raises_403_when_author_does_not_own_it(mock_db, mock_author, mock_post):
    mock_post.author_id = 50  # different owner
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post

    with pytest.raises(HTTPException) as exc_info:
        update_post(post_id=1, post_in=MagicMock(), db=mock_db, current_user=mock_author)

    assert exc_info.value.status_code == 403


def test_update_post_admin_can_update_any_post(mock_db, mock_admin, mock_post):
    mock_post.author_id = 999  # different owner, admin bypasses check
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post

    update_post(post_id=1, post_in=MagicMock(), db=mock_db, current_user=mock_admin)

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

    publish_post(post_id=1, db=mock_db, current_user=mock_author)

    assert mock_post.status == "published"
    mock_db.commit.assert_called_once()


def test_publish_post_raises_403_when_author_does_not_own_it(mock_db, mock_author, mock_post):
    mock_post.author_id = 50  # different owner
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
    mock_post.author_id = 50  # different owner
    mock_db.query.return_value.filter.return_value.first.return_value = mock_post

    with pytest.raises(HTTPException) as exc_info:
        delete_post(post_id=1, db=mock_db, current_user=mock_author)

    assert exc_info.value.status_code == 403


def test_delete_post_admin_can_delete_any_post(mock_db, mock_admin, mock_post):
    mock_post.author_id = 999  # different owner
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

Before finishing, verify:
- [ ] Every public function has at least 2 test cases (happy path + at least one error case)
- [ ] Queries are verified to filter `deleted_at.is_(None)`
- [ ] Ownership checks are tested: author on own post (pass), author on other's post (403)
- [ ] Role-based filtering is tested: reader gets published only, admin gets all
- [ ] `publish_post` only allows draft → published transition
- [ ] `delete_post` uses soft delete (`post.deleted_at = datetime.utcnow()`) — `db.delete()` is never called
- [ ] All fixtures are defined in `conftest.py` and shared across test modules
- [ ] HTTPException status codes match: 404 not found, 403 forbidden, 409 conflict
- [ ] Test file path follows convention: `app/services/post_service.py` → `tests/services/test_post_service.py`

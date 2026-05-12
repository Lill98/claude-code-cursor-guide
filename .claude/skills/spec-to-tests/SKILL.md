---
name: spec-to-tests
description: Read a spec file and generate pytest.mark.skip test stubs and a service scaffold for TDD in blog-api (FastAPI/pytest). Use at the start of a new feature to create the test skeleton before writing implementation.
disable-model-invocation: true
---

# spec-to-tests

## Role
You are an experienced TDD practitioner working in a FastAPI/pytest codebase. Your job is to translate a written spec into a pytest test file with `@pytest.mark.skip(reason="not implemented")` stubs — one stub per distinct behavior described in the spec. You also create a minimal service scaffold with empty function bodies.

The developer will fill in the implementations after you create the structure. You do not write implementation code.

## Context

- **Test framework:** pytest — use `def test_*` functions, `@pytest.mark.skip`, `pytest.raises`
- **Mocking:** `MagicMock(spec=Session)` from `unittest.mock`; fixture defined as `mock_db` in `conftest.py`
- **Framework:** FastAPI — services are plain Python functions or classes; no DI container
- **Pattern:** Tests live under `tests/` (`tests/services/test_post_service.py` for `app/services/post_service.py`)
- **Soft delete:** Every fetch function must eventually filter `deleted_at.is_(None)`; add a skip stub for it
- **Ownership:** Every mutating function must eventually check `post.author_id == current_user.id`; add a stub for it
- **Roles:** Every endpoint must eventually enforce `require_role()`; add a stub for it

## Input

`$ARGUMENTS` contains two paths separated by a space:
1. Path to the spec file (e.g., `specs/PROJ-123.md`)
2. Path to the target test file to create (e.g., `tests/services/test_invitation_service.py`)

Example:
```
/spec-to-tests specs/PROJ-123.md tests/services/test_invitation_service.py
```

## Task

1. Read the spec file at the first path.
2. Extract every distinct **behavior** described — each "should", "must", "when X then Y", acceptance criterion, or edge case becomes one `@pytest.mark.skip` stub.
3. Group behaviors by the service function they belong to using a class or comment block.
4. Infer the service module name and function names from the spec and the target file path.
5. Write the test file to the second path.
6. Write a minimal service scaffold at the corresponding `app/services/<name>.py` path. The scaffold has empty function bodies that raise `NotImplementedError`.

## Output Format

### Test file (`tests/services/test_<name>.py`)

```python
import pytest
from unittest.mock import MagicMock
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.services.<service_name> import (
    <function_name>,
    # ... other functions inferred from the spec
)


# ── <function_name> ────────────────────────────────────────────────────────────

@pytest.mark.skip(reason="not implemented")
def test_<function_name>_<happy_path_behavior>(mock_db, mock_author):
    pass


@pytest.mark.skip(reason="not implemented")
def test_<function_name>_raises_404_when_not_found(mock_db, mock_author):
    pass


@pytest.mark.skip(reason="not implemented")
def test_<function_name>_raises_403_when_not_owner(mock_db, mock_author):
    pass


@pytest.mark.skip(reason="not implemented")
def test_<function_name>_excludes_soft_deleted_records(mock_db, mock_author):
    pass


@pytest.mark.skip(reason="not implemented")
def test_<function_name>_enforces_require_role(mock_db):
    pass


# Repeat for each function inferred from the spec ...
```

### Service scaffold (`app/services/<name>.py`)

```python
from sqlalchemy.orm import Session
from fastapi import HTTPException

from app.models import <Model>
from app.schemas import <CreateSchema>, <UpdateSchema>, <ResponseSchema>


def <function_name>(
    # args inferred from spec: db: Session, current_user, dto, ids, etc.
) -> <ReturnType>:
    raise NotImplementedError


# Repeat for each function ...
```

## Concrete example

Given spec `specs/SH-200.md` describing a comment system, output `tests/services/test_comment_service.py`:

```python
import pytest
from unittest.mock import MagicMock
from fastapi import HTTPException

from app.services.comment_service import (
    get_comments,
    create_comment,
    delete_comment,
)


# ── get_comments ───────────────────────────────────────────────────────────────

@pytest.mark.skip(reason="not implemented")
def test_get_comments_returns_list_for_post(mock_db, mock_reader):
    pass


@pytest.mark.skip(reason="not implemented")
def test_get_comments_excludes_soft_deleted(mock_db, mock_reader):
    pass


@pytest.mark.skip(reason="not implemented")
def test_get_comments_raises_404_when_post_not_found(mock_db, mock_reader):
    pass


# ── create_comment ─────────────────────────────────────────────────────────────

@pytest.mark.skip(reason="not implemented")
def test_create_comment_sets_author_id_from_current_user(mock_db, mock_author):
    pass


@pytest.mark.skip(reason="not implemented")
def test_create_comment_raises_404_when_post_not_found(mock_db, mock_author):
    pass


@pytest.mark.skip(reason="not implemented")
def test_create_comment_raises_403_for_reader_role(mock_db, mock_reader):
    pass


# ── delete_comment ─────────────────────────────────────────────────────────────

@pytest.mark.skip(reason="not implemented")
def test_delete_comment_soft_deletes_by_setting_deleted_at(mock_db, mock_author):
    pass


@pytest.mark.skip(reason="not implemented")
def test_delete_comment_raises_403_when_not_owner(mock_db, mock_author):
    pass


@pytest.mark.skip(reason="not implemented")
def test_delete_comment_admin_can_delete_any_comment(mock_db, mock_admin):
    pass


@pytest.mark.skip(reason="not implemented")
def test_delete_comment_raises_404_when_not_found(mock_db, mock_author):
    pass
```

And scaffold `app/services/comment_service.py`:

```python
from sqlalchemy.orm import Session
from fastapi import HTTPException

from app.models import Comment, Post
from app.schemas.comment import CommentCreate, CommentResponse


def get_comments(post_id: int, db: Session, current_user) -> list:
    raise NotImplementedError


def create_comment(post_id: int, comment_in: CommentCreate, db: Session, current_user) -> Comment:
    raise NotImplementedError


def delete_comment(comment_id: int, db: Session, current_user) -> None:
    raise NotImplementedError
```

## Quality Checklist

Before finishing, verify:
- [ ] Every acceptance criterion and "should" statement from the spec maps to at least one `@pytest.mark.skip` stub
- [ ] Every function that fetches data has a stub for `deleted_at.is_(None)` filtering
- [ ] Every mutating function has a stub for ownership check (403)
- [ ] Every endpoint-level behavior has a stub for `require_role()` enforcement
- [ ] Test function names follow `test_<function>_<scenario>` convention
- [ ] The service scaffold has correct Python syntax and raises `NotImplementedError`
- [ ] No implementation logic in the scaffold — only `raise NotImplementedError`
- [ ] `conftest.py` fixtures (`mock_db`, `mock_author`, `mock_admin`, `mock_reader`, `mock_post`) are assumed available — do not redefine them in the test file

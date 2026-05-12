# Example: CLAUDE.md for blog-api

This is the actual `CLAUDE.md` for the **blog-api** project.
Copy the entire content below into `CLAUDE.md` at your project root.

---

````markdown
# blog-api

## Project Overview
- **Purpose:** REST API for a multi-role blogging platform with posts, comments, and tags
- **Stack:** FastAPI, SQLAlchemy, PostgreSQL, Pydantic v2, pytest, Alembic
- **Type:** REST API
- **Domain:** Content management — authors publish posts, readers browse, admins moderate

## Architecture

FastAPI application with feature-based layout. Each domain has its own router, service, schema, model, and tests:

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

## Module/Router Structure Convention

Every feature follows this exact layout:

```
app/
├── models/[name].py          # SQLAlchemy model
├── schemas/[name].py         # Pydantic input/output schemas
├── routers/[name]s.py        # HTTP routing only, no business logic
├── services/[name]_service.py # All business logic, receives db: Session
└── tests/test_[name]_service.py
```

## Code Conventions

### Naming
- Files: `snake_case` (e.g., `post_service.py`, `comment_router.py`)
- Classes: `PascalCase` (e.g., `PostService`, `PostCreate`, `PostOut`)
- Functions/variables: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Database columns: `snake_case` (SQLAlchemy)

### FastAPI Patterns
- Routers handle HTTP only — no direct DB calls, no business logic
- Services contain all business logic and receive `db: Session` as a parameter
- Use `Depends()` for auth and DB injection into routers
- Never import the service directly from a router without going through `Depends(get_db)`

## Validation & Schemas

**Always use Pydantic v2 schemas for all input and output. Never use raw dicts.**

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

- Use `model_config = ConfigDict(from_attributes=True)` on all output schemas
- Use `PostOut` as `response_model` on every router endpoint
- Never expose `deleted_at` in any output schema

## Database (SQLAlchemy)

- Integer primary keys with `autoincrement=True`
- Soft delete: `deleted_at: Optional[datetime] = None` on User, Post, and Comment — never hard delete records
- Timestamps: `created_at` and `updated_at` on every model
- Always filter soft-deleted records — never omit the `.deleted_at.is_(None)` check

```python
# Always filter soft-deleted records
post = db.query(Post).filter(Post.id == id, Post.deleted_at.is_(None)).first()
if not post:
    raise HTTPException(status_code=404)
# Always check ownership
if post.author_id != current_user.id and current_user.role != "admin":
    raise HTTPException(status_code=403)
```

## Auth & Authorization

- JWT auth via `OAuth2PasswordBearer`, injected with `Depends(get_current_user)`
- Role-based access via `Depends(require_role([...]))` — roles: `admin`, `author`, `reader`
- `current_user` contains: `id`, `email`, `role`
- Admin can access all records. Authors can only modify their own posts.
- Ownership check belongs in the service, not the router.

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

FastAPI auto-serializes via `response_model=PostOut`. No manual response wrapping needed.

- Single object: return the model instance directly
- List: return a plain list — FastAPI serializes via `response_model=list[PostOut]`
- Pagination: return a dict `{"items": [...], "total": n}` only when explicitly needed
- Services return model instances or raise `HTTPException` — never return raw dicts

## Testing

**Use pytest with MagicMock. Do not use unittest directly.**

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

- Mock `db: Session` with `MagicMock()` — fixture defined in `tests/conftest.py`
- Test files go in `tests/` folder: `test_post_service.py` tests `services/post_service.py`
- Do not test routers — logic lives in services
- Fixtures: `mock_db`, `mock_author`, `mock_admin`, `mock_reader` in `conftest.py`

## DO
- Use Pydantic v2 schemas for all request and response types
- Always include `.filter(Model.deleted_at.is_(None))` in every SQLAlchemy query
- Verify post ownership (`post.author_id == current_user.id`) in the service before any write
- Apply `Depends(require_role([...]))` to every endpoint that is not public
- Raise `HTTPException` with explicit status codes (404, 403, 400, etc.)
- Keep `Post.status` transitions explicit: `draft` → `published` only via a dedicated service method

## DON'T
- Do not call the database directly from routers
- Do not hard delete records — set `deleted_at` instead
- Do not put business logic in routers
- Do not allow authors to modify or delete other authors' posts
- Do not expose `deleted_at` in API response schemas
- Do not use raw dicts as input or output — always define a Pydantic schema
````

---

## Path-Scoped Rules

These rule files live in `.claude/rules/` and only load when Claude is working on matching files. They keep `CLAUDE.md` focused while delivering targeted context where it matters.

### `.claude/rules/auth.md`

```markdown
---
paths:
  - "app/dependencies/**"
  - "app/routers/**"
---

# Auth & Authorization Rules

- Always inject auth via `Depends(get_current_user)` — never read the JWT manually in a router.
- Use `Depends(require_role(["admin", "author"]))` on every non-public endpoint.
- Ownership checks (`post.author_id == current_user.id`) belong in the service, not the router.
- Admin bypasses ownership — always check `current_user.role != "admin"` before raising 403.
- `current_user` shape: `id: int`, `email: str`, `role: str` (one of `admin`, `author`, `reader`).
```

### `.claude/rules/testing.md`

```markdown
---
paths:
  - "tests/**"
---

# Testing Rules

- Use pytest with `MagicMock` — do not use `unittest.TestCase` directly.
- Mock `db: Session` using `MagicMock()` — never use a real database in unit tests.
- All fixtures (`mock_db`, `mock_author`, `mock_admin`, `mock_reader`) are defined in `tests/conftest.py`.
- Test services only — do not write tests for routers (logic lives in services).
- Every service method needs at minimum: a happy path test and an error case test.
- Always assert that `deleted_at.is_(None)` is present in DB query calls.
```

---

## @import

If `CLAUDE.md` grows past 200 lines, split it using `@import`:

```markdown
# blog-api

@.claude/context/architecture.md
@.claude/context/conventions.md
@.claude/context/testing.md
```

Each imported file is loaded inline. Paths are relative to `CLAUDE.md`. Use this when a section is long enough to deserve its own file, or when you want to version-control sections independently.

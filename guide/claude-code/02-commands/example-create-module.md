# Example: Command `/create-module` for blog-api

This is the actual `.claude/commands/create-module.md` file used in the `blog-api` project.
Copy the entire content below into `.claude/commands/create-module.md`.

---

```markdown
# create-module

## Purpose
Create a new FastAPI module that follows blog-api standards, including all boilerplate files and registration in the app. The generated module will include role-based access control, Pydantic v2 schemas, soft delete, and pytest unit tests.

## Usage
```
/create-module [module-name]
```

## Arguments
- `$ARGUMENTS`: Module name in singular snake_case (e.g., `tag`, `comment`, `post`)

## Steps

1. **Read patterns from an existing module**
   Read `app/routers/posts.py` and `app/services/post_service.py` to learn exactly:
   - How the FastAPI router is defined and how endpoints are registered
   - How `Depends(get_current_user)` and `Depends(require_role(...))` are used in route signatures
   - How the service class is structured and injected into the router via `Depends()`
   - How Pydantic v2 schemas are defined (model_config, field types, validators)
   - Service method patterns: `get_all`, `get_one`, `create`, `update`, `delete`
   - How soft delete is implemented (set `deleted_at`, never physically delete)

2. **Create the files for the new module**
   Create the following files. Replace `$ARGUMENTS` with the actual module name. Use PascalCase for class names (e.g., `comment` → `CommentService`, `CommentOut`).

   - `app/models/$ARGUMENTS.py` — SQLAlchemy model with `id`, `created_at`, `updated_at`, `deleted_at`
   - `app/schemas/$ARGUMENTS.py` — Pydantic v2 schemas: `$NAMECreate`, `$NAMEUpdate`, `$NAMEOut`
   - `app/services/${ARGUMENTS}_service.py` — Service class with `get_all`, `get_one`, `create`, `update`, `delete` (soft)
   - `app/routers/${ARGUMENTS}s.py` — FastAPI router with CRUD endpoints using `Depends()`
   - `tests/test_${ARGUMENTS}_service.py` — pytest tests using `MagicMock(spec=Session)`

3. **Implement the SQLAlchemy model**
   In `app/models/$ARGUMENTS.py`:
   - Inherit from `Base`
   - Include columns: `id` (Integer primary key), `created_at`, `updated_at` (DateTime with server_default), `deleted_at` (DateTime nullable)
   - Add any domain-specific columns appropriate to the module

4. **Implement standard CRUD endpoints**
   The router must have these routes:
   - `GET /` — `get_all` — accessible by admin and author (authors see only their own records)
   - `GET /{id}` — `get_one` — accessible by admin, author, and reader
   - `POST /` — `create` — accessible by admin and author
   - `PUT /{id}` — `update` — admin has full access; author can only update own records
   - `DELETE /{id}` — soft delete — sets `deleted_at = datetime.utcnow()`, never removes from DB; admin only

   Use `Depends(require_role("admin", "author"))` to declare required roles on each endpoint.
   Use `Depends(get_current_user)` to get the logged-in user from the JWT payload.

5. **Implement soft delete in the service**
   Every `get_all` and `get_one` query must filter `Model.deleted_at == None`.
   The `delete` method must set `record.deleted_at = datetime.utcnow()` and commit.
   Never call `db.delete(record)`.

6. **Write pytest unit tests**
   In `tests/test_${ARGUMENTS}_service.py`:
   - Import `MagicMock` from `unittest.mock` and `Session` from `sqlalchemy.orm`
   - Create a `mock_db = MagicMock(spec=Session)` for each test
   - Test at minimum: `get_all` returns only non-deleted records, `delete` sets `deleted_at` and does not physically remove the record
   - Use `pytest` fixtures and standard `assert` statements

7. **Register the router in `app/main.py`**
   Open `app/main.py` and add:
   ```python
   from app.routers import ${ARGUMENTS}s
   app.include_router(${ARGUMENTS}s.router, prefix="/${ARGUMENTS}s", tags=["${NAME}s"])
   ```
   Add the import at the top of the file alongside other router imports.

   Then verify each created file:
   - Every SQLAlchemy query filters `Model.deleted_at == None`
   - No business logic exists in the router — only calls to the service
   - Schemas use Pydantic v2 style (`model_config = ConfigDict(from_attributes=True)`)
   - `require_role()` is applied to every endpoint that restricts access
   - The router is present in `app/main.py`

## Output

Files to be created:
```
app/models/$ARGUMENTS.py
app/schemas/$ARGUMENTS.py
app/services/${ARGUMENTS}_service.py
app/routers/${ARGUMENTS}s.py
tests/test_${ARGUMENTS}_service.py
```

File to be modified:
- `app/main.py` (add import and `include_router` call)

## Example
```
/create-module tag
```

Expected output:
- `app/models/tag.py`
- `app/schemas/tag.py`
- `app/services/tag_service.py`
- `app/routers/tags.py`
- `tests/test_tag_service.py`
- `app/main.py` (updated — `app.include_router(tags.router, prefix="/tags", tags=["Tags"])`)
```

---

## Usage

```bash
# In Claude Code CLI:
/create-module tag
/create-module comment
/create-module post
```

## Notes

This command works best when:
- The project already has a `CLAUDE.md` that documents conventions (soft delete, role names, Pydantic v2 pattern)
- At least one example module exists (e.g., `post`) for Claude to learn the exact patterns from
- The Alembic migration for the new model is either already present or Claude is asked to generate it
- `get_current_user`, `require_role()`, and JWT middleware are already set up in `app/dependencies/`

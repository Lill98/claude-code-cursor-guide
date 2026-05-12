# Example: Config Hierarchy for blog-api

This example shows all config layers working together for the **blog-api** project. The scenario: a developer opens `app/services/post_service.py`.

---

## Full Project Structure

```
blog-api/
├── CLAUDE.md                          # Team rules: stack, patterns, DO/DON'T (committed)
├── CLAUDE.local.md                    # Gitignored: personal DB URL, formatter prefs
├── app/
│   ├── CLAUDE.md                      # App-level rules (committed)
│   ├── main.py
│   ├── database.py
│   ├── models/
│   ├── schemas/
│   ├── routers/
│   ├── services/
│   │   └── CLAUDE.md                  # Service-layer rules (committed)
│   ├── dependencies/
│   └── core/
├── tests/
│   ├── conftest.py
│   ├── test_post_service.py
│   └── test_comment_service.py
├── alembic/
├── alembic.ini
├── pyproject.toml
└── .claude/
    ├── settings.json                  # Team hooks config (committed)
    ├── settings.local.json            # Gitignored: personal permissions
    ├── skills/
    │   ├── write-test/SKILL.md
    │   └── review-pr/SKILL.md
    ├── hooks/
    │   ├── lint-fix.sh                # runs ruff check --fix
    │   ├── prettier-fix.sh            # runs black + isort
    │   └── run-tests.sh               # runs pytest
    └── rules/
        ├── testing.md                 # paths: ["tests/**/*.py", "test_*.py"]
        └── schemas.md                 # paths: ["app/schemas/**/*.py"]
```

---

## Key File Contents

### `CLAUDE.md` (project root — committed to git)

```markdown
# blog-api

## Stack
FastAPI + SQLAlchemy + PostgreSQL + Pydantic v2 + pytest + Alembic

## Feature Structure
app/
├── models/[name].py           — SQLAlchemy model with soft delete (deleted_at)
├── schemas/[name].py          — Pydantic v2 input/output schemas only
├── routers/[name]s.py         — HTTP only, no business logic, uses Depends()
├── services/[name]_service.py — Business logic, receives db: Session as parameter
└── tests/test_[name]_service.py

## Rules
- Soft delete everywhere: always query with .filter(Model.deleted_at.is_(None))
- Authors can only edit their own posts: verify post.author_id == current_user.id in service
- Routers use response_model=PostOut — never return raw dicts
- Roles: admin (full access), author (own posts only), reader (read-only)
- Raise HTTPException with explicit status codes — 404, 403, 400, etc.

## Commands
/write-test  — Generate pytest unit tests for a service file
/review-pr   — Security and quality review of staged changes
```

---

### `app/services/CLAUDE.md` (service-layer rules)

```markdown
# Service Layer Rules

- Every service method receives `db: Session` as the first parameter — never import SessionLocal directly
- Always filter soft-deleted records: .filter(Model.deleted_at.is_(None)) on every query
- Check ownership before any write: if post.author_id != current_user.id and current_user.role != "admin": raise HTTPException(status_code=403)
- Services raise HTTPException directly — do not return error dicts
- Never return raw SQLAlchemy model instances from a service used by a router that expects a schema
- Set deleted_at = datetime.utcnow() for delete operations — never call db.delete()
```

---

### `.claude/settings.json` (team hooks — committed to git)

```json
{
  "_comment": "Team config — committed to git. Personal overrides go in settings.local.json (gitignored). PostToolUse hooks auto-format files after every Write/Edit. Stop hook runs the test suite after each Claude response.",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/prettier-fix.sh"
          }
        ]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/lint-fix.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/run-tests.sh"
          }
        ]
      }
    ]
  }
}
```

The hook scripts reference Python tooling:

- `lint-fix.sh` — runs `ruff check --fix app/ tests/`
- `prettier-fix.sh` — runs `black app/ tests/ && isort app/ tests/`
- `run-tests.sh` — runs `pytest tests/ -q --tb=short`

---

### `.claude/rules/testing.md` (activated for test files)

```markdown
---
paths:
  - "tests/**/*.py"
  - "test_*.py"
---

# Testing Rules

- Use pytest — do not use unittest.TestCase directly
- Mock db: Session with MagicMock() — never use a real database in unit tests
- Chain mock returns to match SQLAlchemy query style: mock_db.query().filter().first()
- Reset all mocks in each test — never share state between test cases
- Test file names must match source: post_service.py → test_post_service.py
- Do not test routers — all logic lives in services
- Use fixtures from conftest.py: mock_db, mock_author, mock_admin, mock_reader
```

---

### `.claude/settings.local.json` (personal — gitignored)

```json
{
  "permissions": {
    "allow": [
      "Bash(pytest tests/ *)",
      "Bash(alembic upgrade *)",
      "Bash(psql postgresql://localhost:5432/blog_dev *)"
    ]
  }
}
```

---

## `.gitignore` Entries for Claude Code

```gitignore
# Claude Code — personal local config (never commit)
CLAUDE.local.md
.claude/settings.local.json

# Claude Code — session data
.claude/cache/
```

---

## What to Commit vs What Not to Commit

| File | Commit? | Reason |
|---|---|---|
| `CLAUDE.md` | Yes | Team-wide rules every developer should follow |
| `app/CLAUDE.md` | Yes | App-level rules are part of the codebase |
| `app/services/CLAUDE.md` | Yes | Service-layer rules that the whole team benefits from |
| `.claude/settings.json` | Yes | Shared hooks (lint, format, test) apply to all |
| `.claude/rules/testing.md` | Yes | Path-scoped rules activated automatically for test files |
| `.claude/skills/` | Yes | Shared workflows available to the whole team |
| `.claude/hooks/` | Yes | Hook scripts that settings.json references |
| `CLAUDE.local.md` | No | Personal overrides — local DB URL, personal shortcuts |
| `.claude/settings.local.json` | No | Personal permissions — varies per developer |

---

## What Claude Sees When Opening `app/services/post_service.py`

When you open `app/services/post_service.py`, Claude merges all active layers:

```
Active config:
  [global]  ~/.claude/CLAUDE.md              → company-wide Python + git standards
  [global]  ~/.claude/CLAUDE.local.md        → your personal output preferences
  [project] CLAUDE.md                        → stack, feature structure, role rules
  [project] CLAUDE.local.md                  → your local DB URL, preferred runner
  [project] app/CLAUDE.md                    ← ACTIVATED: file is inside app/
  [project] app/services/CLAUDE.md           ← ACTIVATED: file is inside app/services/
  [rule]    .claude/rules/schemas.md         ← NOT activated: not in app/schemas/
  [rule]    .claude/rules/testing.md         ← NOT activated: not a test file
```

Claude now knows:
- Use pytest not unittest
- Always filter `.deleted_at.is_(None)` in every SQLAlchemy query
- Check `post.author_id == current_user.id` before any write operation
- Receive `db: Session` as a parameter — never import SessionLocal directly
- Raise `HTTPException` — never return error dicts from services
- Use soft delete: set `deleted_at = datetime.utcnow()`, never call `db.delete()`

All without repeating any of this in the prompt.

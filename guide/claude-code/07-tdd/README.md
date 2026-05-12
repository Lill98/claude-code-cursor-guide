# Claude Code: TDD Workflow

Write tests from a spec in parallel with implementation — not after the code is done. This section covers two tools: a skill that generates failing test stubs from a spec, and hooks that run tests automatically after every Claude task and before every commit.

---

## Why Parallel Matters

The default AI workflow is: write code → ask AI to write tests. This produces **confirmatory tests** — tests that describe what the code does, not what it should do.

The TDD approach flips this: generate test stubs from the spec first, then implement. Tests are red from the start. Implementation fills them green, method by method. This catches mismatches between the spec and the code early — before code review, not after.

"Parallel" means both files — the spec file and the test file — exist from the beginning of a task. You do not wait for the code to be done before creating tests.

---

## The Two-Part Workflow

| Part | Tool | What It Does |
|------|------|--------------|
| **1. Generate test stubs** | `/spec-to-tests` skill | Reads a spec file, extracts acceptance criteria, creates `@pytest.mark.skip` stubs + an empty service scaffold |
| **2. Gate on test results** | Stop hook + pre-commit | Shows test output after every Claude task; blocks `git commit` if tests fail |

---

## Part 1: Skill Template `/spec-to-tests`

Create `.claude/skills/spec-to-tests/SKILL.md` and copy the content below into it.

> Legacy format: copy into `.claude/commands/spec-to-tests.md` — also works.

```markdown
---
name: spec-to-tests
description: Read a spec file and generate pytest.mark.skip test stubs and a service scaffold for TDD. Use at the start of a new feature to create the test skeleton before writing implementation.
disable-model-invocation: true
---

# spec-to-tests

## Role
You are an experienced TDD practitioner working in a FastAPI/pytest codebase. Your job is to translate a written spec into a pytest test file with `@pytest.mark.skip(reason="not implemented")` stubs — one stub per distinct behavior. You also create a minimal service scaffold with empty function bodies that raise `NotImplementedError`.

## Context
- **Test framework:** pytest — use `def test_*` functions, `@pytest.mark.skip`, `pytest.raises`
- **Mocking:** `MagicMock(spec=Session)` from `unittest.mock`; fixtures in `conftest.py`
- **Framework:** FastAPI — services are plain Python functions or classes; no DI container
- **Pattern:** Tests in `tests/services/test_<name>.py` for `app/services/<name>.py`
- **Soft delete:** Every fetch must filter `deleted_at.is_(None)`
- **Ownership:** Mutating functions check `record.author_id == current_user.id`

## Input
`$ARGUMENTS` contains two paths separated by a space:
1. Path to the spec file (e.g. `specs/PROJ-123.md`)
2. Path to the target test file (e.g. `tests/services/test_post_service.py`)

## Task
Read the spec, extract every distinct behavior (each "should", "must", "when X then Y", acceptance criterion), and create two files: a test file with `@pytest.mark.skip` stubs and a service scaffold.

## Output Format

Test file:
```python
import pytest
from unittest.mock import MagicMock
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.services.[service_name] import [function_name]


# ── [function_name] ───────────────────────────────────────────────────────────

@pytest.mark.skip(reason="not implemented")
def test_[function_name]_[happy_path](mock_db, mock_author):
    pass


@pytest.mark.skip(reason="not implemented")
def test_[function_name]_raises_404_when_not_found(mock_db, mock_author):
    pass


@pytest.mark.skip(reason="not implemented")
def test_[function_name]_raises_403_when_not_owner(mock_db, mock_author):
    pass
```

Service scaffold:
```python
from sqlalchemy.orm import Session
from fastapi import HTTPException

from app.models import [Model]
from app.schemas import [CreateSchema], [ResponseSchema]


def [function_name](db: Session, current_user, dto) -> [ReturnType]:
    raise NotImplementedError
```

## Quality Checklist
- [ ] Every acceptance criterion maps to at least one `@pytest.mark.skip` stub
- [ ] Every fetch function has a stub for `deleted_at.is_(None)` filtering
- [ ] Every mutating function has a stub for ownership check (403)
- [ ] Test function names follow `test_<function>_<scenario>` convention
- [ ] Service scaffold raises `NotImplementedError` — no implementation
- [ ] `conftest.py` fixtures (`mock_db`, `mock_author`, `mock_admin`) are assumed available
```

---

## How to Use `/spec-to-tests` (Step-by-Step)

```
1. Have a spec file ready — either from /research-ticket or written manually
   Example: specs/PROJ-123.md

2. In Claude Code, run:
   /spec-to-tests specs/PROJ-123.md tests/services/test_post_service.py

3. Claude generates two files:
   - tests/services/test_post_service.py  ← @pytest.mark.skip stubs, all skipped
   - app/services/post_service.py         ← empty scaffold, raises NotImplementedError

4. Verify the test suite is in skip state:
   pytest --tb=short -v
   → Each stub shows as "s" (skipped) in the output

5. Start implementing — remove @pytest.mark.skip one by one and watch tests go green
```

---

## Part 2a: Stop Hook — Automatic Test Feedback

The `Stop` hook runs after every Claude task. It cannot block Claude (Stop hooks are non-blocking), but it surfaces test results in the console immediately — before you run `git add` or `git commit`.

### Setup

**Step 1: Create the hook script**

**`.claude/hooks/run-tests.sh`**

```bash
#!/bin/bash
# Run unit tests after every Claude task

echo ""
echo "Running unit tests..."
pytest --tb=short -q 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "All tests passed."
else
  echo "Tests failed — fix before committing."
fi

exit 0
```

**Step 2: Grant execute permission**

```bash
chmod +x .claude/hooks/run-tests.sh
```

**Step 3: Add to `.claude/settings.json`**

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/run-tests.sh"
          }
        ]
      }
    ]
  }
}
```

### How to Use: Stop Hook (Step-by-Step)

```
1. Create .claude/hooks/run-tests.sh with the script above
2. Run: chmod +x .claude/hooks/run-tests.sh
3. Add the Stop event to .claude/settings.json
4. From now on: every time Claude finishes a task, unit tests run automatically
5. Review the test output before running git commit
```

> **Note:** `exit 0` is intentional. Stop hooks cannot block Claude — they display output only. Use the Husky pre-commit hook (below) to enforce a hard gate at commit time.

---

## Part 2b: pre-commit Hook — Hard Enforcement

The `pre-commit` tool runs `pytest` before every `git commit`. If any test fails, the commit is rejected. This is the enforcement layer — it applies to the whole team regardless of which AI tool they use.

### Setup

**Step 1: Install pre-commit (one-time per project)**

```bash
pip install pre-commit
```

**Step 2: Create `.pre-commit-config.yaml`**

```yaml
repos:
  - repo: local
    hooks:
      - id: pytest
        name: pytest
        entry: pytest --tb=short -q
        language: system
        pass_filenames: false
        always_run: true
```

**Step 3: Install the git hook and commit the config**

```bash
pre-commit install
git add .pre-commit-config.yaml && git commit -m "chore: add pre-commit test gate"
```

### How to Use: pre-commit (Step-by-Step)

```
1. Run the 3 setup steps above (one-time per project)
2. Verify: pre-commit run --all-files  → should run pytest
3. From now on: git commit is blocked if any test fails
4. When blocked, fix failing tests, then re-run git commit
5. To bypass in an emergency (not recommended): git commit --no-verify
```

> **Note:** The pre-commit hook applies to everyone on the team — not just Claude Code users. It enforces the gate at the git level.

---

## How the Two Hooks Work Together

| | Stop Hook | pre-commit |
|---|---|---|
| **When it runs** | After every Claude task | On every `git commit` |
| **Blocks?** | No — shows output only | Yes — commit rejected if tests fail |
| **Purpose** | Immediate feedback during AI-assisted development | Hard enforcement at commit time |
| **Applies to** | Claude Code users only | All team members |

The Stop hook catches problems early while you are still in a Claude session. pre-commit makes sure nothing broken reaches the git history, regardless of how the code was written.

---

## Tips

- Use `@pytest.mark.skip(reason="not implemented")`, not just `@pytest.mark.skip` — the `reason` makes intent visible in test output
- The hook uses `pytest --tb=short -q` — it exits after one run, fitting inside Claude Code's 60-second hook timeout
- For large test suites, scope the hook: replace `pytest` with `pytest tests/services/`
- If the Stop hook slows your workflow, remove it from `settings.json` and rely on pre-commit alone

---

## See a Real-World Example

[Example: Parallel TDD for PROJ-123 — New Feature](./example-tdd-workflow.md)

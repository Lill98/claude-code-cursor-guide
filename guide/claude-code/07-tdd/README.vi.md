# Claude Code: TDD Workflow

Viết test từ spec song song với implementation — không phải sau khi code xong. Phần này gồm hai công cụ: một skill tạo test stub từ spec, và các hook tự động chạy test sau mỗi task của Claude và trước mỗi commit.

---

## Tại Sao Cần Song Song?

Workflow AI mặc định là: viết code → nhờ AI viết test. Kết quả là **confirmatory tests** — test mô tả những gì code đang làm, không phải những gì code nên làm.

TDD lật ngược điều này: tạo test stub từ spec trước, rồi mới implement. Test đỏ ngay từ đầu. Implementation lần lượt làm chúng xanh, từng method một. Cách này phát hiện mismatch giữa spec và code sớm — trước code review, không phải sau.

"Song song" nghĩa là cả hai file — spec file và test file — tồn tại ngay từ đầu task. Bạn không chờ code xong mới tạo test.

---

## Workflow Hai Phần

| Phần | Công cụ | Tác dụng |
|------|---------|---------|
| **1. Tạo test stub** | `/spec-to-tests` skill | Đọc spec file, trích acceptance criteria, tạo `@pytest.mark.skip` stubs + service scaffold rỗng |
| **2. Gate bằng test** | Stop hook + pre-commit | Hiển thị kết quả test sau mỗi task Claude; chặn `git commit` nếu test fail |

---

## Phần 1: Skill Template `/spec-to-tests`

Tạo `.claude/skills/spec-to-tests/SKILL.md` và copy nội dung bên dưới vào.

> Format cũ: copy vào `.claude/commands/spec-to-tests.md` cũng hoạt động.

```markdown
---
name: spec-to-tests
description: Đọc spec file và tạo pytest.mark.skip test stubs cùng service scaffold cho TDD. Dùng khi bắt đầu feature mới để tạo test skeleton trước khi viết implementation.
disable-model-invocation: true
---

# spec-to-tests

## Role
Bạn là TDD practitioner làm việc trong codebase FastAPI/pytest. Nhiệm vụ: dịch spec thành pytest test file với `@pytest.mark.skip(reason="not implemented")` stubs — một stub cho mỗi behavior. Bạn cũng tạo service scaffold rỗng với empty function bodies.

## Context
- **Test framework:** pytest — dùng `def test_*`, `@pytest.mark.skip`, `pytest.raises`
- **Mocking:** `MagicMock(spec=Session)` từ `unittest.mock`; fixture trong `conftest.py`
- **Framework:** FastAPI — services là plain Python functions hoặc classes; không có DI container
- **Pattern:** Tests trong `tests/services/test_<name>.py` cho `app/services/<name>.py`
- **Soft delete:** Mỗi fetch phải filter `deleted_at.is_(None)`
- **Ownership:** Hàm mutating kiểm tra `record.author_id == current_user.id`

## Input
`$ARGUMENTS` chứa hai path cách nhau bởi dấu cách:
1. Path đến spec file (vd: `specs/SH-164.md`)
2. Path đến test file cần tạo (vd: `tests/services/test_post_service.py`)

## Task
Đọc spec, trích mọi behavior (mỗi "should", "must", "when X then Y", acceptance criterion), và tạo hai file: test file với `@pytest.mark.skip` stubs và service scaffold.

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
- [ ] Mọi acceptance criterion map sang ít nhất một `@pytest.mark.skip` stub
- [ ] Mọi fetch function có stub cho `deleted_at.is_(None)` filtering
- [ ] Mọi mutating function có stub cho ownership check (403)
- [ ] Tên test function theo convention `test_<function>_<scenario>`
- [ ] Service scaffold raise `NotImplementedError` — không có implementation
- [ ] Fixtures `conftest.py` (`mock_db`, `mock_author`, `mock_admin`) được assume có sẵn
```

---

## Cách Dùng `/spec-to-tests` (Từng Bước)

```
1. Chuẩn bị spec file — từ /research-ticket hoặc viết tay
   Ví dụ: specs/SH-164.md

2. Trong Claude Code, chạy:
   /spec-to-tests specs/SH-164.md tests/services/test_post_service.py

3. Claude tạo hai file:
   - tests/services/test_post_service.py  ← @pytest.mark.skip stubs, tất cả bị skip
   - app/services/post_service.py         ← scaffold rỗng, raise NotImplementedError

4. Kiểm tra test suite ở trạng thái skip:
   pytest --tb=short -v
   → Mỗi stub hiển thị là "s" (skipped) trong output

5. Bắt đầu implement — xóa @pytest.mark.skip từng cái và xem test chuyển sang xanh
```

---

## Phần 2a: Stop Hook — Feedback Test Tự Động

`Stop` hook chạy sau mỗi task của Claude. Nó không thể chặn Claude (Stop hook không blocking), nhưng nó hiển thị kết quả test ngay trên console — trước khi bạn chạy `git add` hay `git commit`.

### Setup

**Bước 1: Tạo hook script**

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

**Bước 2: Cấp quyền thực thi**

```bash
chmod +x .claude/hooks/run-tests.sh
```

**Bước 3: Thêm vào `.claude/settings.json`**

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

### Cách Dùng: Stop Hook (Từng Bước)

```
1. Tạo .claude/hooks/run-tests.sh với script bên trên
2. Chạy: chmod +x .claude/hooks/run-tests.sh
3. Thêm Stop event vào .claude/settings.json
4. Từ đây: mỗi khi Claude hoàn thành task, unit test tự động chạy
5. Xem kết quả test trước khi chạy git commit
```

> **Lưu ý:** `exit 0` là cố ý. Stop hook không thể chặn Claude — chỉ hiển thị output. Dùng pre-commit hook (bên dưới) để enforce hard gate lúc commit.

---

## Phần 2b: pre-commit Hook — Enforcement Cứng

pre-commit tool chạy `pytest` trước mỗi `git commit`. Nếu test nào fail, commit bị từ chối. Đây là lớp enforcement — áp dụng cho cả team, bất kể ai viết code.

### Setup

**Bước 1: Cài pre-commit (một lần duy nhất mỗi project)**

```bash
pip install pre-commit
```

**Bước 2: Tạo `.pre-commit-config.yaml`**

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

**Bước 3: Cài git hook và commit config**

```bash
pre-commit install
git add .pre-commit-config.yaml && git commit -m "chore: add pre-commit test gate"
```

### Cách Dùng: pre-commit (Từng Bước)

```
1. Chạy 3 bước setup bên trên (một lần mỗi project)
2. Verify: pre-commit run --all-files  → phải chạy pytest
3. Từ đây: git commit bị chặn nếu test nào fail
4. Khi bị chặn, fix test fail, rồi chạy git commit lại
5. Bypass khẩn cấp (không khuyến khích): git commit --no-verify
```

> **Lưu ý:** pre-commit hook áp dụng cho cả team — không chỉ người dùng Claude Code. Nó enforce ở git level.

---

## Hai Hook Phối Hợp Thế Nào

| | Stop Hook | pre-commit |
|---|---|---|
| **Khi nào chạy** | Sau mỗi task Claude | Mỗi lần `git commit` |
| **Có chặn không?** | Không — chỉ hiển thị output | Có — commit bị từ chối nếu test fail |
| **Mục đích** | Feedback ngay trong lúc phát triển với AI | Enforcement cứng tại thời điểm commit |
| **Áp dụng cho** | Chỉ người dùng Claude Code | Toàn bộ team |

Stop hook phát hiện vấn đề sớm khi bạn còn đang trong Claude session. pre-commit đảm bảo không có gì bị lỗi đi vào git history, bất kể code được viết bởi ai hay công cụ nào.

---

## Tips

- Dùng `@pytest.mark.skip(reason="not implemented")`, không chỉ `@pytest.mark.skip` — `reason` hiển thị trong test output
- Hook dùng `pytest --tb=short -q` — thoát sau một lần chạy, vừa với timeout 60 giây của Claude Code hook
- Với test suite lớn, scope lại hook: thay `pytest` bằng `pytest tests/services/`
- Nếu Stop hook làm chậm workflow, xóa khỏi `settings.json` và chỉ dùng pre-commit

---

## Xem Ví Dụ Thực Tế

[Example: Parallel TDD for SH-164 — Invite User via Email](./example-tdd-workflow.md)

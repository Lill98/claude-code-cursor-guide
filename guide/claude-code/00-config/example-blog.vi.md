# Ví dụ: Cấu hình theo thứ bậc cho blog-api

Ví dụ này mô tả tất cả các lớp cấu hình hoạt động cùng nhau cho dự án **blog-api**. Kịch bản: một developer mở file `app/services/post_service.py`.

---

## Cấu trúc đầy đủ của dự án

```
blog-api/
├── CLAUDE.md                          # Quy tắc team: stack, patterns, DO/DON'T (được commit)
├── CLAUDE.local.md                    # Gitignored: DB URL cá nhân, tuỳ chỉnh formatter
├── app/
│   ├── CLAUDE.md                      # Quy tắc cấp app (được commit)
│   ├── main.py
│   ├── database.py
│   ├── models/
│   ├── schemas/
│   ├── routers/
│   ├── services/
│   │   └── CLAUDE.md                  # Quy tắc tầng service (được commit)
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
    ├── settings.json                  # Cấu hình hook của team (được commit)
    ├── settings.local.json            # Gitignored: permission cá nhân
    ├── skills/
    │   ├── write-test/SKILL.md
    │   └── review-pr/SKILL.md
    ├── hooks/
    │   ├── lint-fix.sh                # chạy ruff check --fix
    │   ├── prettier-fix.sh            # chạy black + isort
    │   └── run-tests.sh               # chạy pytest
    └── rules/
        ├── testing.md                 # paths: ["tests/**/*.py", "test_*.py"]
        └── schemas.md                 # paths: ["app/schemas/**/*.py"]
```

---

## Nội dung các file quan trọng

### `CLAUDE.md` (thư mục gốc — được commit vào git)

```markdown
# blog-api

## Stack
FastAPI + SQLAlchemy + PostgreSQL + Pydantic v2 + pytest + Alembic

## Cấu trúc Feature
app/
├── models/[name].py           — SQLAlchemy model với soft delete (deleted_at)
├── schemas/[name].py          — Chỉ dùng Pydantic v2 schema input/output
├── routers/[name]s.py         — Chỉ xử lý HTTP, không có business logic, dùng Depends()
├── services/[name]_service.py — Business logic, nhận db: Session như parameter
└── tests/test_[name]_service.py

## Quy tắc
- Soft delete ở mọi nơi: luôn query với .filter(Model.deleted_at.is_(None))
- Author chỉ được chỉnh sửa bài của mình: kiểm tra post.author_id == current_user.id trong service
- Router dùng response_model=PostOut — không bao giờ trả raw dict
- Roles: admin (toàn quyền), author (chỉ bài của mình), reader (chỉ đọc)
- Raise HTTPException với status code rõ ràng — 404, 403, 400, v.v.

## Commands
/write-test  — Tạo pytest unit test cho file service
/review-pr   — Review bảo mật và chất lượng cho staged changes
```

---

### `app/services/CLAUDE.md` (quy tắc tầng service)

```markdown
# Quy tắc Tầng Service

- Mọi service method nhận `db: Session` làm parameter đầu tiên — không bao giờ import SessionLocal trực tiếp
- Luôn lọc bản ghi đã soft delete: .filter(Model.deleted_at.is_(None)) trong mọi query
- Kiểm tra quyền sở hữu trước mọi thao tác ghi: if post.author_id != current_user.id and current_user.role != "admin": raise HTTPException(status_code=403)
- Service raise HTTPException trực tiếp — không trả error dict
- Không trả raw SQLAlchemy model instance từ service được dùng bởi router yêu cầu schema
- Set deleted_at = datetime.utcnow() cho thao tác xóa — không bao giờ gọi db.delete()
```

---

### `.claude/settings.json` (hook của team — được commit vào git)

```json
{
  "_comment": "Cấu hình team — được commit vào git. Ghi đè cá nhân đặt trong settings.local.json (gitignored). Hook PostToolUse tự động format file sau mỗi lần Write/Edit. Hook Stop chạy test suite sau mỗi phản hồi của Claude.",
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

Các hook script tham chiếu đến Python tooling:

- `lint-fix.sh` — chạy `ruff check --fix app/ tests/`
- `prettier-fix.sh` — chạy `black app/ tests/ && isort app/ tests/`
- `run-tests.sh` — chạy `pytest tests/ -q --tb=short`

---

### `.claude/rules/testing.md` (kích hoạt cho file test)

```markdown
---
paths:
  - "tests/**/*.py"
  - "test_*.py"
---

# Quy tắc Testing

- Dùng pytest — không dùng unittest.TestCase trực tiếp
- Mock db: Session bằng MagicMock() — không bao giờ dùng database thật trong unit test
- Chain mock return để khớp với SQLAlchemy query style: mock_db.query().filter().first()
- Reset tất cả mock trong mỗi test — không chia sẻ state giữa các test case
- Tên file test phải khớp với source: post_service.py → test_post_service.py
- Không test router — toàn bộ logic nằm trong service
- Dùng fixture từ conftest.py: mock_db, mock_author, mock_admin, mock_reader
```

---

### `.claude/settings.local.json` (cá nhân — gitignored)

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

## Mục `.gitignore` cho Claude Code

```gitignore
# Claude Code — config cá nhân cục bộ (không commit)
CLAUDE.local.md
.claude/settings.local.json

# Claude Code — dữ liệu phiên làm việc
.claude/cache/
```

---

## Nên và không nên commit file nào

| File | Commit? | Lý do |
|---|---|---|
| `CLAUDE.md` | Có | Quy tắc toàn team mà mọi developer cần tuân theo |
| `app/CLAUDE.md` | Có | Quy tắc cấp app là một phần của codebase |
| `app/services/CLAUDE.md` | Có | Quy tắc tầng service mà cả team được hưởng lợi |
| `.claude/settings.json` | Có | Hook dùng chung (lint, format, test) áp dụng cho tất cả |
| `.claude/rules/testing.md` | Có | Quy tắc theo đường dẫn tự động kích hoạt cho file test |
| `.claude/skills/` | Có | Workflow dùng chung cho cả team |
| `.claude/hooks/` | Có | Script hook được settings.json tham chiếu |
| `CLAUDE.local.md` | Không | Ghi đè cá nhân — DB URL cục bộ, phím tắt riêng |
| `.claude/settings.local.json` | Không | Permission cá nhân — khác nhau tuỳ theo developer |

---

## Claude Thấy Gì Khi Mở `app/services/post_service.py`

Khi bạn mở `app/services/post_service.py`, Claude hợp nhất tất cả các lớp đang hoạt động:

```
Config đang hoạt động:
  [global]  ~/.claude/CLAUDE.md              → tiêu chuẩn Python + git toàn công ty
  [global]  ~/.claude/CLAUDE.local.md        → tùy chọn đầu ra cá nhân
  [project] CLAUDE.md                        → stack, cấu trúc feature, quy tắc role
  [project] CLAUDE.local.md                  → URL DB cục bộ, runner ưa thích
  [project] app/CLAUDE.md                    ← KÍCH HOẠT: file nằm trong app/
  [project] app/services/CLAUDE.md           ← KÍCH HOẠT: file nằm trong app/services/
  [rule]    .claude/rules/schemas.md         ← KHÔNG kích hoạt: không nằm trong app/schemas/
  [rule]    .claude/rules/testing.md         ← KHÔNG kích hoạt: không phải file test
```

Claude giờ biết:
- Dùng pytest không phải unittest
- Luôn lọc `.deleted_at.is_(None)` trong mọi SQLAlchemy query
- Kiểm tra `post.author_id == current_user.id` trước mọi thao tác ghi
- Nhận `db: Session` như parameter — không import SessionLocal trực tiếp
- Raise `HTTPException` — không trả error dict từ service
- Dùng soft delete: set `deleted_at = datetime.utcnow()`, không gọi `db.delete()`

Tất cả mà không cần developer nhắc lại trong prompt.

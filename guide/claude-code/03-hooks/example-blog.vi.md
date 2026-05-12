# Ví dụ: Hooks cho blog-api

Hooks thực tế cho dự án `blog-api` (FastAPI + SQLAlchemy + pytest). Các hook này tự động format và lint sau mỗi lần chỉnh sửa file, chạy bộ test khi Claude hoàn thành task, và chặn các lệnh shell nguy hiểm trước khi chúng được thực thi.

---

## Cài đặt

### 1. Tạo hook scripts

**`.claude/hooks/lint-fix.sh`**

```bash
#!/bin/bash
# Chạy ruff --fix trên file Python Claude vừa chỉnh sửa.
# Được kích hoạt bởi PostToolUse trên Write|Edit.

INPUT=$(cat)

FILE_PATH=$(python3 -c "
import sys, json
try:
    data = json.loads('''$INPUT''')
    tool_input = data.get('tool_input', {})
    print(tool_input.get('file_path', ''))
except:
    print('')
" 2>/dev/null)

if [[ "$FILE_PATH" == *.py ]]; then
  echo "ruff: $FILE_PATH"
  ruff check --fix "$FILE_PATH" 2>&1
  if [ $? -eq 0 ]; then
    echo "ruff: $FILE_PATH — no issues"
  else
    echo "ruff: $FILE_PATH — issues found (auto-fixed where possible)"
  fi
fi
```

**`.claude/hooks/prettier-fix.sh`**

```bash
#!/bin/bash
# Chạy black và isort trên file Python Claude vừa chỉnh sửa.
# Được kích hoạt bởi PostToolUse trên Write|Edit.

INPUT=$(cat)

FILE_PATH=$(python3 -c "
import sys, json
try:
    data = json.loads('''$INPUT''')
    tool_input = data.get('tool_input', {})
    print(tool_input.get('file_path', ''))
except:
    print('')
" 2>/dev/null)

if [[ "$FILE_PATH" == *.py ]]; then
  echo "black: $FILE_PATH"
  black "$FILE_PATH" 2>&1
  echo "isort: $FILE_PATH"
  isort "$FILE_PATH" 2>&1
fi
```

**`.claude/hooks/run-tests.sh`**

```bash
#!/bin/bash
# Chạy toàn bộ pytest suite sau khi Claude hoàn thành task.
# Được kích hoạt bởi event Stop (mang tính thông báo — luôn exit 0).

echo ""
echo "=============================="
echo "  Running tests..."
echo "=============================="

echo "pytest --tb=short -q"
pytest --tb=short -q 2>&1

if [ $? -eq 0 ]; then
  echo ""
  echo "  All tests passed."
  echo "=============================="
else
  echo ""
  echo "  Some tests failed — review output above"
  echo "=============================="
fi

# Stop hook phải exit 0 — giá trị khác 0 sẽ chặn response của Claude.
exit 0
```

**`.claude/hooks/check-dangerous.sh`**

```bash
#!/bin/bash
# Chặn các lệnh shell nguy hiểm trước khi Claude chạy chúng.
# Được kích hoạt bởi PreToolUse trên Bash. Exit 2 để chặn, exit 0 để cho phép.

INPUT=$(cat)

COMMAND=$(python3 -c "
import sys, json
try:
    data = json.loads('''$INPUT''')
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Chặn câu lệnh SQL DROP TABLE hoặc DROP DATABASE
if echo "$COMMAND" | grep -qiE "(DROP TABLE|DROP DATABASE)"; then
  echo "BLOCKED: Destructive SQL statement is not allowed: $COMMAND" >&2
  exit 2
fi

# Chặn lệnh Alembic downgrade về base (xóa toàn bộ migration)
if echo "$COMMAND" | grep -qE "alembic downgrade base"; then
  echo "BLOCKED: 'alembic downgrade base' is not allowed. Specify a target revision instead." >&2
  exit 2
fi

# Chặn thao tác xóa thư mục app/
if echo "$COMMAND" | grep -qE "rm -rf app/"; then
  echo "BLOCKED: Destructive rm on app/ is not allowed: $COMMAND" >&2
  exit 2
fi

exit 0
```

Cấp quyền thực thi cho tất cả script:

```bash
chmod +x .claude/hooks/lint-fix.sh
chmod +x .claude/hooks/prettier-fix.sh
chmod +x .claude/hooks/run-tests.sh
chmod +x .claude/hooks/check-dangerous.sh
```

---

### 2. Cấu hình `.claude/settings.json`

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/prettier-fix.sh"
          }
        ]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/lint-fix.sh"
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
            "command": "bash .claude/hooks/run-tests.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/check-dangerous.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Kết quả khi chạy

Khi Claude chỉnh sửa một file Python (ví dụ: `app/services/post_service.py`), bạn sẽ thấy:

```
black: app/services/post_service.py
isort: app/services/post_service.py
ruff: app/services/post_service.py — no issues
```

Khi Claude hoàn thành task và Stop hook được kích hoạt:

```
==============================
  Running tests...
==============================
pytest --tb=short -q
...........
11 passed in 0.43s
All tests passed.
```

Khi Claude cố chạy một lệnh bị chặn:

```
BLOCKED: 'alembic downgrade base' is not allowed. Specify a target revision instead.
```

Claude nhận thông báo lỗi từ stderr và sẽ tự động tìm phương án an toàn hơn.

---

## Xử lý sự cố

**Hook không chạy:**
- Kiểm tra `settings.json` có đúng cú pháp JSON không: `cat .claude/settings.json | python3 -m json.tool`
- Kiểm tra script có quyền thực thi không: `ls -la .claude/hooks/`
- Chạy thủ công để kiểm tra script hoạt động độc lập:
  ```bash
  echo '{"tool_input":{"file_path":"app/services/post_service.py"}}' | bash .claude/hooks/lint-fix.sh
  ```

**`ruff` không tìm thấy:**
- Cài ruff vào virtualenv của dự án: `pip install ruff`
- Xác nhận virtualenv đang active khi Claude Code chạy: `which ruff`
- Nếu không được, dùng đường dẫn đầy đủ: thay `ruff` bằng `python3 -m ruff` trong script

**`black` hoặc `isort` chưa được cài:**
- Cài cả hai công cụ: `pip install black isort`
- Kiểm tra chúng có sẵn trong virtualenv mà Claude Code sử dụng: `which black && which isort`
- Nếu dùng `pyproject.toml`, xác nhận có section `[tool.black]` và `[tool.isort]` để cả hai công cụ nhận đúng config

**`pytest` không tìm thấy test — lỗi đường dẫn:**
- Chạy thủ công `pytest --tb=short -q` từ root repo để xác nhận test discovery hoạt động
- Thêm `pytest.ini` hoặc section `[tool.pytest.ini_options]` trong `pyproject.toml` với `testpaths = ["tests"]`
- Nếu pytest không có trên PATH, thay `pytest` bằng `python3 -m pytest` trong `run-tests.sh`

**Hook script không thực thi (permission denied):**
- Chạy lại `chmod +x` cho tất cả script: `chmod +x .claude/hooks/*.sh`
- Trên một số hệ thống, kiểm tra thêm dòng shebang `#!/bin/bash` phải là dòng đầu tiên, không có khoảng trắng phía trước

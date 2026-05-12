# Example: Hooks for blog-api

Real-world hooks for the `blog-api` project (FastAPI + SQLAlchemy + pytest). These hooks automatically format and lint after every file edit, run the test suite when Claude finishes, and block dangerous shell commands before they execute.

---

## Setup

### 1. Create hook scripts

**`.claude/hooks/lint-fix.sh`**

```bash
#!/bin/bash
# Run ruff --fix on the Python file Claude just edited.
# Triggered by PostToolUse on Write|Edit.

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
# Run black and isort on the Python file Claude just edited.
# Triggered by PostToolUse on Write|Edit.

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
# Run the full pytest suite after Claude finishes a task.
# Triggered by Stop event (informational — exit 0 always).

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

# Stop hooks must exit 0 — non-zero would block Claude's response.
exit 0
```

**`.claude/hooks/check-dangerous.sh`**

```bash
#!/bin/bash
# Block dangerous shell commands before Claude runs them.
# Triggered by PreToolUse on Bash. Exit 2 to block, exit 0 to allow.

INPUT=$(cat)

COMMAND=$(python3 -c "
import sys, json
try:
    data = json.loads('''$INPUT''')
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Block raw SQL DROP or DROP DATABASE statements
if echo "$COMMAND" | grep -qiE "(DROP TABLE|DROP DATABASE)"; then
  echo "BLOCKED: Destructive SQL statement is not allowed: $COMMAND" >&2
  exit 2
fi

# Block destructive Alembic downgrade to base (wipes all migrations)
if echo "$COMMAND" | grep -qE "alembic downgrade base"; then
  echo "BLOCKED: 'alembic downgrade base' is not allowed. Specify a target revision instead." >&2
  exit 2
fi

# Block destructive filesystem operations on the app directory
if echo "$COMMAND" | grep -qE "rm -rf app/"; then
  echo "BLOCKED: Destructive rm on app/ is not allowed: $COMMAND" >&2
  exit 2
fi

exit 0
```

Grant execute permissions to all scripts:

```bash
chmod +x .claude/hooks/lint-fix.sh
chmod +x .claude/hooks/prettier-fix.sh
chmod +x .claude/hooks/run-tests.sh
chmod +x .claude/hooks/check-dangerous.sh
```

---

### 2. Configure `.claude/settings.json`

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

## Result When Running

When Claude edits a Python file (e.g., `app/services/post_service.py`), you'll see:

```
black: app/services/post_service.py
isort: app/services/post_service.py
ruff: app/services/post_service.py — no issues
```

When Claude finishes a task and the Stop hook fires:

```
==============================
  Running tests...
==============================
pytest --tb=short -q
...........
11 passed in 0.43s
All tests passed.
```

When Claude attempts a blocked command:

```
BLOCKED: 'alembic downgrade base' is not allowed. Specify a target revision instead.
```

Claude sees the error message from stderr and will attempt a safer alternative automatically.

---

## Troubleshooting

**Hook isn't running at all:**
- Verify `settings.json` is valid JSON: `cat .claude/settings.json | python3 -m json.tool`
- Verify scripts have execute permissions: `ls -la .claude/hooks/`
- Test the script manually to confirm it works in isolation:
  ```bash
  echo '{"tool_input":{"file_path":"app/services/post_service.py"}}' | bash .claude/hooks/lint-fix.sh
  ```

**`ruff` is not found:**
- Install ruff in the project virtualenv: `pip install ruff`
- Verify the virtualenv is active when Claude Code runs: `which ruff`
- Alternatively use the full path: replace `ruff` with `python3 -m ruff` in the script

**`black` or `isort` is not installed:**
- Install both tools: `pip install black isort`
- Check that they are available in the same virtualenv Claude Code uses: `which black && which isort`
- If using `pyproject.toml`, confirm the `[tool.black]` and `[tool.isort]` sections are present so both tools pick up the correct config

**`pytest` path issues — tests are not found:**
- Run `pytest --tb=short -q` manually from the repo root to confirm discovery works
- Add a `pytest.ini` or `pyproject.toml` `[tool.pytest.ini_options]` section with `testpaths = ["tests"]`
- If pytest is not on PATH, replace `pytest` with `python3 -m pytest` in `run-tests.sh`

**Hook script is not executing (permission denied):**
- Re-run `chmod +x` on all scripts: `chmod +x .claude/hooks/*.sh`
- On some systems, also verify the shebang line `#!/bin/bash` is exactly the first line with no leading whitespace

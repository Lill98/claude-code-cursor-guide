# Example: Hooks for saafehouse-be (Cursor)

Real-world hooks for the saafehouse-be project: auto-format after file edits, run unit tests when the agent finishes, and block dangerous shell commands.

---

## Setup

### 1. Create hook scripts

**`.cursor/hooks/prettier-fix.sh`**

```bash
#!/bin/bash
# Run Prettier on the file Cursor just edited

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('file_path', ''))
except:
    print('')
" 2>/dev/null)

if [[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx || "$FILE_PATH" == *.json || "$FILE_PATH" == *.prisma ]]; then
  echo "Prettier: $FILE_PATH"
  npx prettier --write "$FILE_PATH" 2>&1
fi

exit 0
```

**`.cursor/hooks/lint-fix.sh`**

```bash
#!/bin/bash
# Run ESLint --fix on the TypeScript file Cursor just edited

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('file_path', ''))
except:
    print('')
" 2>/dev/null)

if [[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx ]]; then
  echo "ESLint: $FILE_PATH"
  npx eslint --fix "$FILE_PATH" 2>&1
  if [ $? -eq 0 ]; then
    echo "ESLint passed"
  else
    echo "ESLint found issues (auto-fixed where possible)"
  fi
fi

exit 0
```

**`.cursor/hooks/run-tests.sh`**

```bash
#!/bin/bash
# Run unit tests when Cursor agent finishes

echo ""
echo "Running unit tests..."
npx vitest --run 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "All tests passed."
else
  echo "Tests failed — fix before committing."
fi

exit 0
```

**`.cursor/hooks/check-dangerous-commands.sh`**

```bash
#!/bin/bash
# Block dangerous shell commands

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('command', ''))
except:
    print('')
")

if echo "$COMMAND" | grep -qE "rm -rf.*(src|dist|node_modules|\.env)"; then
  echo "BLOCKED: Dangerous command prevented: $COMMAND" >&2
  exit 2
fi

exit 0
```

```bash
# Grant execute permissions
chmod +x .cursor/hooks/prettier-fix.sh
chmod +x .cursor/hooks/lint-fix.sh
chmod +x .cursor/hooks/run-tests.sh
chmod +x .cursor/hooks/check-dangerous-commands.sh
```

---

### 2. Configure `.cursor/hooks.json`

```json
{
  "version": 1,
  "hooks": {
    "afterFileEdit": [
      {
        "command": ".cursor/hooks/prettier-fix.sh",
        "type": "command",
        "timeout": 30
      },
      {
        "command": ".cursor/hooks/lint-fix.sh",
        "type": "command",
        "timeout": 30
      }
    ],
    "stop": [
      {
        "command": ".cursor/hooks/run-tests.sh",
        "type": "command",
        "timeout": 60
      }
    ],
    "beforeShellExecution": [
      {
        "command": ".cursor/hooks/check-dangerous-commands.sh",
        "type": "command",
        "matcher": "rm -rf",
        "failClosed": true
      }
    ]
  }
}
```

---

## Result When Running

When Cursor edits a TypeScript file, you'll see in the console:

```
Prettier: src/modules/firm/firm.service.ts
ESLint: src/modules/firm/firm.service.ts
ESLint passed
```

When the agent finishes a task:

```
Running unit tests...
 PASS  src/modules/firm/firm.service.spec.ts
All tests passed.
```

When Cursor tries to run a dangerous command:

```
BLOCKED: Dangerous command prevented: rm -rf src/
```

---

## Troubleshooting

**Hook isn't running:**
- Check `hooks.json` is valid JSON: `cat .cursor/hooks.json | python3 -m json.tool`
- Check scripts have execute permissions: `ls -la .cursor/hooks/`
- Check the Hooks output channel in Cursor Settings → Hooks tab
- Save `hooks.json` to trigger auto-reload (no restart needed)

**Hook runs but has no effect:**
- ESLint/Prettier must be installed: `npm ls eslint prettier`
- Scripts run from the project root — verify relative paths
- Test the script manually: `echo '{"file_path":"src/test.ts"}' | bash .cursor/hooks/prettier-fix.sh`

# Example: Hooks for saafehouse-be

Real-world hooks for the saafehouse-be project: automatically lint and format after every time Claude edits a TypeScript file.

---

## Setup

### 1. Create hook scripts

**`.claude/hooks/lint-fix.sh`**

```bash
#!/bin/bash
# Run ESLint --fix on the TypeScript file Claude just edited

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tool_input = data.get('tool_input', {})
    print(tool_input.get('file_path', ''))
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
```

**`.claude/hooks/prettier-fix.sh`**

```bash
#!/bin/bash
# Run Prettier on the file Claude just edited

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tool_input = data.get('tool_input', {})
    print(tool_input.get('file_path', ''))
except:
    print('')
" 2>/dev/null)

if [[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx || "$FILE_PATH" == *.json || "$FILE_PATH" == *.prisma ]]; then
  echo "Prettier: $FILE_PATH"
  npx prettier --write "$FILE_PATH" 2>&1
fi
```

**`.claude/hooks/notify-done.sh`**

```bash
#!/bin/bash
# Notify when Claude finishes a task

echo ""
echo "=============================="
echo "  Claude has finished the task"
echo "=============================="

# Optional: play a notification sound (macOS)
# afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true

# Optional: write to log
echo "$(date): Claude task completed" >> ~/.claude-activity.log
```

```bash
# Grant execute permissions to scripts
chmod +x .claude/hooks/lint-fix.sh
chmod +x .claude/hooks/prettier-fix.sh
chmod +x .claude/hooks/notify-done.sh
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
            "command": "bash .claude/hooks/notify-done.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Result When Running

When Claude edits a TypeScript file, you'll see in the console:

```
Prettier: src/modules/firm/firm.service.ts
ESLint: src/modules/firm/firm.service.ts
ESLint passed
```

When Claude finishes a task:

```
==============================
  Claude has finished the task
==============================
```

---

## Advanced Hook: PreToolUse to Block Dangerous Commands

Example: block Claude from deleting production config files:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/check-dangerous-commands.sh"
          }
        ]
      }
    ]
  }
}
```

**`.claude/hooks/check-dangerous-commands.sh`**

```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
")

if echo "$COMMAND" | grep -qE "rm -rf.*(src|dist|node_modules|\.env)"; then
  echo "BLOCKED: Dangerous command prevented: $COMMAND" >&2
  exit 1
fi

exit 0
```

---

## Troubleshooting

**Hook isn't running:**
- Check if `settings.json` is valid JSON: `cat .claude/settings.json | python3 -m json.tool`
- Check if scripts have execute permissions: `ls -la .claude/hooks/`
- Run the script manually to test: `echo '{"tool_input":{"file_path":"test.ts"}}' | bash .claude/hooks/lint-fix.sh`

**Hook runs but has no effect:**
- ESLint/Prettier must be installed in the project: `npm ls eslint prettier`
- Check the working directory (hooks run from the project root)

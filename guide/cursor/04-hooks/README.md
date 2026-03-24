# Cursor: Hooks

Hooks are scripts that run at defined stages of the Cursor agent loop. They can observe, block, or modify agent actions — running formatters after edits, gating risky operations, injecting context at session start, and more.

---

## Configuration

Hooks are defined in `hooks.json`. Two locations:

| Location | Scope |
|----------|-------|
| `.cursor/hooks.json` | Project-level — shared with team via git |
| `~/.cursor/hooks.json` | User-level — applies to all projects |

```json
{
  "version": 1,
  "hooks": {
    "hookName": [
      {
        "command": "./path/to/script.sh",
        "type": "command",
        "timeout": 30,
        "matcher": "optional-pattern",
        "failClosed": false
      }
    ]
  }
}
```

Cursor auto-reloads `hooks.json` when saved — no restart needed.

---

## Hook Events

| Event | When It Fires | Can Block? |
|-------|---------------|-----------|
| `sessionStart` | Agent session begins | No |
| `stop` | Agent loop ends (task complete) | No — but can inject follow-up |
| `preToolUse` | Before any tool runs | Yes (exit 2) |
| `postToolUse` | After any tool succeeds | No |
| `afterFileEdit` | After agent edits a file | No |
| `beforeShellExecution` | Before shell command runs | Yes (exit 2) |
| `afterShellExecution` | After shell command runs | No |
| `beforeSubmitPrompt` | Before user prompt is sent | Yes (exit 2) |

---

## Hook Types

### Command Hook (default)

Runs a shell script. Receives JSON on stdin, returns JSON on stdout.

```json
{
  "command": ".cursor/hooks/run-tests.sh",
  "type": "command",
  "timeout": 60
}
```

Exit code behavior:
- `0` — success; stdout is parsed as JSON response
- `2` — **blocks** the action (for hooks that support blocking)
- other — fail-open (action proceeds, hook error is logged)

### Prompt Hook

LLM-evaluated policy — no scripting required. Useful for natural language rules.

```json
{
  "type": "prompt",
  "prompt": "Is this a read-only operation? Only allow safe, non-destructive commands.",
  "timeout": 10
}
```

---

## Input Format

Every hook script receives a JSON object on stdin:

```json
{
  "conversation_id": "string",
  "hook_event_name": "stop",
  "workspace_roots": ["/path/to/project"],
  "user_email": "user@example.com"
}
```

`afterFileEdit` also includes `file_path`. `beforeShellExecution` includes the command string.

---

## Matchers

Filter hooks to run only for specific tools or commands:

```json
{
  "command": ".cursor/hooks/check-command.sh",
  "matcher": "curl|wget|rm -rf"
}
```

Matcher patterns for `preToolUse`/`postToolUse`:
- By tool name: `Shell`, `Read`, `Write`
- By MCP tool: `MCP:toolname`

---

## TEMPLATE

**`.cursor/hooks.json`**

```json
{
  "version": 1,
  "hooks": {
    "afterFileEdit": [
      {
        "command": ".cursor/hooks/format.sh",
        "type": "command",
        "timeout": 30
      }
    ],
    "stop": [
      {
        "command": ".cursor/hooks/on-stop.sh",
        "type": "command",
        "timeout": 60
      }
    ],
    "beforeShellExecution": [
      {
        "command": ".cursor/hooks/check-dangerous.sh",
        "type": "command",
        "matcher": "rm -rf|DROP TABLE|kubectl delete",
        "failClosed": true
      }
    ]
  }
}
```

**`.cursor/hooks/format.sh`**

```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('file_path', ''))
except:
    print('')
")

if [[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx ]]; then
  npx prettier --write "$FILE_PATH" 2>&1
  npx eslint --fix "$FILE_PATH" 2>&1
fi

exit 0
```

---

## Tips

- Use `failClosed: true` for security-critical hooks — if the hook script fails, the action is blocked rather than allowed
- Use `type: "prompt"` for policy enforcement when you don't want to write a script
- Project hooks (`.cursor/hooks.json`) are committed to git and shared with the team; user hooks (`~/.cursor/hooks.json`) are personal
- The `stop` hook can return a `followup_message` to automatically continue the conversation (up to `loop_limit` times)

---

## See a Real-World Example

→ [Example: Hooks for saafehouse-be](./example-saafehouse.md)

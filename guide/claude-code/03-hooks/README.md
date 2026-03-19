# Template: Claude Code Hooks

Hooks are shell commands that run automatically when Claude performs actions. Configure them in `.claude/settings.json` (project-level) or `~/.claude/settings.json` (global).

---

## Hook Event Types

| Event | When It Runs | Can It Block? |
|-------|-------------|---------------|
| `PreToolUse` | Before Claude uses a tool | Yes (exit code != 0) |
| `PostToolUse` | After Claude uses a tool | No |
| `Stop` | When Claude finishes a response | No |
| `Notification` | When a notification occurs | No |

---

## settings.json Structure

```json
{
  "hooks": {
    "[EventName]": [
      {
        "matcher": "[tool-name-pattern]",
        "hooks": [
          {
            "type": "command",
            "command": "[shell command]"
          }
        ]
      }
    ]
  }
}
```

---

## Matchers

| Matcher | Matches |
|---------|---------|
| `""` (empty) | All tools |
| `"Write"` | Write tool only |
| `"Edit\|Write"` | Edit or Write tool |
| `"Bash"` | Bash tool only |

---

## Environment Variables in Hooks

Claude Code passes context via stdin (JSON) and environment variables:

| Variable | Content |
|----------|---------|
| `$CLAUDE_TOOL_NAME` | Name of the tool that was called |
| `$CLAUDE_TOOL_INPUT` | Tool input (JSON string) |
| `$CLAUDE_TOOL_OUTPUT` | Tool output (PostToolUse only) |

The JSON input for Write/Edit tools contains a `file_path` field — use it to know which file was modified.

---

## TEMPLATE

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "YOUR_COMMAND_HERE"
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
            "command": "YOUR_STOP_COMMAND_HERE"
          }
        ]
      }
    ]
  }
}
```

---

## Pattern: Extract File Path from stdin

Hooks receive tool input via stdin as JSON. To extract `file_path`:

```bash
#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

if [ -n "$FILE_PATH" ]; then
  echo "Processing: $FILE_PATH"
fi
```

---

## Tips

- **Test the hook first** — Run the command manually before adding it to hooks
- **Exit codes** — A `PreToolUse` hook with exit code != 0 will block the tool call
- **Timeout** — Hooks have a default 60s timeout, avoid heavy operations
- **Log output** — Hook stdout/stderr is displayed in the Claude Code console
- **Separate scripts** — For complex logic, create a script at `.claude/hooks/my-hook.sh`

---

## See a Real-World Example

→ [example-saafehouse.md](./example-saafehouse.md)

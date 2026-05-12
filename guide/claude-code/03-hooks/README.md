# Claude Code Hooks

Hooks are shell commands that run automatically when Claude performs actions. Configure them in `.claude/settings.json` (project-level) or `~/.claude/settings.json` (global). Use hooks to enforce rules, automate side effects, and log activity — without relying on Claude's memory.

---

## Hook Events

### Session-level (once per session)

| Event | When It Runs | Can Block? |
|-------|-------------|------------|
| `SessionStart` | When a session starts or resumes | No |
| `SessionEnd` | When a session ends | No |

### Turn-level (each time the user sends input)

| Event | When It Runs | Can Block? |
|-------|-------------|------------|
| `UserPromptSubmit` | Before Claude processes a prompt | Yes (exit 2) |
| `Stop` | When Claude finishes a response | Yes (exit 2) |
| `StopFailure` | When a turn ends due to an API error | No |

### Tool execution loop (each tool call)

| Event | When It Runs | Can Block? |
|-------|-------------|------------|
| `PreToolUse` | Before a tool call executes | Yes (exit 2) |
| `PostToolUse` | After a tool call succeeds | No (stderr forwarded to Claude) |
| `PostToolUseFailure` | After a tool call fails | No |
| `PermissionRequest` | When a permission dialog appears | Yes (exit 2) |
| `PermissionDenied` | When auto mode rejects a tool call | No |

### Async events (for monitoring and logging)

`Notification`, `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `PreCompact`, `PostCompact`, `FileChanged`, `CwdChanged`, and others. These run asynchronously and cannot block Claude.

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
            "command": "[shell command or script path]"
          }
        ]
      }
    ]
  }
}
```

Multiple hooks can be registered for the same event. Each entry in the outer array is a matcher group; each group can have multiple commands.

---

## Matchers

Matchers filter which tool calls trigger a hook. Only relevant for tool-level events (`PreToolUse`, `PostToolUse`, etc.).

| Matcher | Matches |
|---------|---------|
| `""` (empty string) | All tools |
| `"Write"` | Write tool only |
| `"Edit\|Write"` | Edit or Write tool |
| `"Bash"` | Bash tool only |
| `"Read\|Grep\|Glob"` | Any read-style tool |

Use regex alternation (`|`) to match multiple tools in one hook.

---

## Stdin Input (JSON)

Hooks receive data via **stdin as JSON** — not environment variables. All hook events include these common fields:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/directory",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse"
}
```

**Tool events** (`PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`) add:

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.ts",
    "content": "..."
  },
  "tool_use_id": "toolu_01ABC..."
}
```

**`PostToolUse`** additionally includes:

```json
{
  "tool_response": {
    "result": "tool output here"
  }
}
```

---

## Environment Variables

| Variable | Available In | Description |
|----------|-------------|-------------|
| `CLAUDE_PROJECT_DIR` | All hooks | Absolute path to the project root |
| `CLAUDE_ENV_FILE` | `SessionStart`, `CwdChanged`, `FileChanged` | File path for persisting env vars to Bash commands |
| `CLAUDE_CODE_REMOTE` | All hooks | `"true"` when running in a remote or web environment |

> **Important:** There is no `$CLAUDE_TOOL_NAME`, `$CLAUDE_TOOL_INPUT`, or `$CLAUDE_TOOL_OUTPUT`. All tool data comes through stdin JSON.

---

## Exit Codes

| Exit Code | Effect |
|-----------|--------|
| `0` | Success. Stdout is parsed as JSON if possible. |
| `2` | Block the action (only works for: `PreToolUse`, `Stop`, `SubagentStop`, `PreCompact`, `UserPromptSubmit`, `PermissionRequest`) |
| Any other | Non-blocking error — stderr is shown, execution continues |

### JSON Output (exit 0)

When a hook exits with `0` and stdout is valid JSON, Claude reads these fields:

```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Optional message shown to Claude as a system prompt addition",
  "followup": "Optional user-facing message appended to the transcript"
}
```

All fields are optional. Use `systemMessage` to inject context or warnings into Claude's reasoning.

---

## Template

Copy this into `.claude/settings.json` and fill in your commands:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/on-file-write.sh"
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
            "command": ".claude/hooks/guard-bash.sh"
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
            "command": ".claude/hooks/on-stop.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Pattern: Extract File Path from Stdin

Use this bash snippet at the top of any hook script that needs to read the file path from a tool call:

```bash
#!/bin/bash
INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

if [ -n "$FILE_PATH" ]; then
  echo "Processing: $FILE_PATH"
  # your logic here
fi
```

For other fields, replace `file_path` with the field name from the stdin JSON schema above (e.g., `tool_name`, `content`, `result`).

---

## Tips

- **Test hooks manually first** — Run the command directly in your shell before adding it to settings. Hooks that crash will still run on every matching event.
- **Exit 2 to block** — `PreToolUse` with exit 2 cancels the tool call; `Stop` with exit 2 keeps Claude running (useful for forcing follow-up actions).
- **Timeout is 60 seconds** — Hooks that exceed 60s are killed. Keep scripts fast; offload heavy work to background processes.
- **Separate scripts** — For complex logic, create a dedicated file at `.claude/hooks/my-hook.sh`. Keep settings.json entries short.
- **Stderr goes to the Claude console** — Use it for debug output you want to see but not inject into Claude's context.
- **No tool data in env vars** — Always parse stdin JSON. Never rely on environment variables for tool input/output.

---

## See a Real-World Example

→ [example-blog.md](./example-blog.md)

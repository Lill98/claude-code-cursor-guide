# Claude Code Hooks

Hooks là các shell command chạy tự động khi Claude thực hiện actions. Cấu hình trong `.claude/settings.json` (project-level) hoặc `~/.claude/settings.json` (global). Dùng hooks để enforce rules, tự động hóa side effects, và ghi log — mà không phụ thuộc vào memory của Claude.

---

## Hook Events

### Session-level (một lần mỗi session)

| Event | Khi nào chạy | Có thể block? |
|-------|-------------|---------------|
| `SessionStart` | Khi session bắt đầu hoặc resume | Không |
| `SessionEnd` | Khi session kết thúc | Không |

### Turn-level (mỗi lần user gửi input)

| Event | Khi nào chạy | Có thể block? |
|-------|-------------|---------------|
| `UserPromptSubmit` | Trước khi Claude xử lý prompt | Có (exit 2) |
| `Stop` | Khi Claude hoàn thành response | Có (exit 2) |
| `StopFailure` | Khi turn kết thúc do API error | Không |

### Tool execution loop (mỗi tool call)

| Event | Khi nào chạy | Có thể block? |
|-------|-------------|---------------|
| `PreToolUse` | Trước khi tool call thực thi | Có (exit 2) |
| `PostToolUse` | Sau khi tool call thành công | Không (stderr chuyển tiếp đến Claude) |
| `PostToolUseFailure` | Sau khi tool call thất bại | Không |
| `PermissionRequest` | Khi permission dialog xuất hiện | Có (exit 2) |
| `PermissionDenied` | Khi auto mode từ chối tool call | Không |

### Async events (dùng cho monitoring và logging)

`Notification`, `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `PreCompact`, `PostCompact`, `FileChanged`, `CwdChanged`, và nhiều events khác. Các events này chạy bất đồng bộ và không thể block Claude.

---

## Cấu trúc settings.json

```json
{
  "hooks": {
    "[EventName]": [
      {
        "matcher": "[tool-name-pattern]",
        "hooks": [
          {
            "type": "command",
            "command": "[shell command hoặc đường dẫn script]"
          }
        ]
      }
    ]
  }
}
```

Nhiều hooks có thể được đăng ký cho cùng một event. Mỗi entry trong mảng ngoài là một matcher group; mỗi group có thể có nhiều command.

---

## Matchers

Matchers lọc xem tool call nào kích hoạt hook. Chỉ có tác dụng với tool-level events (`PreToolUse`, `PostToolUse`, v.v.).

| Matcher | Khớp với |
|---------|---------|
| `""` (chuỗi rỗng) | Tất cả tools |
| `"Write"` | Chỉ Write tool |
| `"Edit\|Write"` | Edit hoặc Write tool |
| `"Bash"` | Chỉ Bash tool |
| `"Read\|Grep\|Glob"` | Bất kỳ read-style tool nào |

Dùng regex alternation (`|`) để match nhiều tools trong một hook.

---

## Stdin Input (JSON)

Hooks nhận dữ liệu qua **stdin dưới dạng JSON** — không phải qua environment variables. Tất cả hook events đều có các common fields sau:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/directory",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse"
}
```

**Tool events** (`PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`) bổ sung thêm:

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

**`PostToolUse`** bổ sung thêm:

```json
{
  "tool_response": {
    "result": "tool output here"
  }
}
```

---

## Environment Variables

| Variable | Available In | Mô tả |
|----------|-------------|-------|
| `CLAUDE_PROJECT_DIR` | Tất cả hooks | Đường dẫn tuyệt đối đến project root |
| `CLAUDE_ENV_FILE` | `SessionStart`, `CwdChanged`, `FileChanged` | File path để persist env vars cho Bash commands |
| `CLAUDE_CODE_REMOTE` | Tất cả hooks | `"true"` khi chạy trong remote hoặc web environment |

> **Lưu ý quan trọng:** Không có `$CLAUDE_TOOL_NAME`, `$CLAUDE_TOOL_INPUT`, hay `$CLAUDE_TOOL_OUTPUT`. Tất cả dữ liệu của tool đều đến qua stdin JSON.

---

## Exit Codes

| Exit Code | Tác động |
|-----------|---------|
| `0` | Thành công. Stdout được parse dưới dạng JSON nếu có thể. |
| `2` | Block action (chỉ hoạt động với: `PreToolUse`, `Stop`, `SubagentStop`, `PreCompact`, `UserPromptSubmit`, `PermissionRequest`) |
| Mã khác | Non-blocking error — stderr hiển thị, execution tiếp tục |

### JSON Output (exit 0)

Khi hook exit với `0` và stdout là JSON hợp lệ, Claude đọc các fields sau:

```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Message tùy chọn hiển thị cho Claude như một system prompt bổ sung",
  "followup": "Message tùy chọn hiển thị cho user, được append vào transcript"
}
```

Tất cả fields đều tùy chọn. Dùng `systemMessage` để inject context hoặc cảnh báo vào quá trình reasoning của Claude.

---

## Template

Copy vào `.claude/settings.json` và điền commands của bạn:

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

## Pattern: Lấy File Path từ Stdin

Dùng bash snippet này ở đầu bất kỳ hook script nào cần đọc file path từ tool call:

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
  # logic của bạn ở đây
fi
```

Với các fields khác, thay `file_path` bằng tên field trong stdin JSON schema ở trên (ví dụ: `tool_name`, `content`, `result`).

---

## Tips

- **Test hook trước** — Chạy command trực tiếp trong shell trước khi thêm vào settings. Hook bị crash vẫn chạy mỗi khi có matching event.
- **Exit 2 để block** — `PreToolUse` với exit 2 hủy tool call; `Stop` với exit 2 giữ Claude chạy tiếp (hữu ích để buộc follow-up actions).
- **Timeout là 60 giây** — Hook vượt quá 60s sẽ bị kill. Giữ script nhanh; offload heavy work vào background processes.
- **Tách thành scripts riêng** — Với logic phức tạp, tạo file riêng tại `.claude/hooks/my-hook.sh`. Giữ entries trong settings.json ngắn gọn.
- **Stderr hiển thị trong Claude console** — Dùng cho debug output bạn muốn xem nhưng không muốn inject vào context của Claude.
- **Không có tool data trong env vars** — Luôn parse stdin JSON. Không bao giờ dựa vào environment variables cho tool input/output.

---

## Xem Ví dụ Thực Tế

→ [example-blog.md](./example-blog.md)

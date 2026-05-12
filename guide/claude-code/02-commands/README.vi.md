# Commands: Slash Commands trong Claude Code

Commands là các slash command (`/command-name`) bạn gõ trực tiếp trong Claude Code. Khi được gọi, Claude đọc file `.md` tương ứng và thực thi workflow được định nghĩa bên trong.

---

## Commands hoạt động như thế nào

1. Tạo file tại `.claude/commands/command-name.md`
2. Viết workflow dưới dạng Markdown — văn xuôi, bullet steps, hoặc kết hợp
3. Gọi bằng cách gõ `/command-name [arguments]` trong Claude Code

Claude thay thế các placeholder đặc biệt trong file bằng input thực tế bạn cung cấp, sau đó thực hiện theo hướng dẫn.

---

## Cú pháp đặc biệt

| Placeholder | Ý nghĩa |
|---|---|
| `$ARGUMENTS` | Toàn bộ text gõ sau tên command |
| `$ARGUMENTS[0]` | Argument đầu tiên (phân cách bằng dấu cách) |
| `$ARGUMENTS[1]` | Argument thứ hai |

Ví dụ: `/create-module auth` → `$ARGUMENTS = "auth"`, `$ARGUMENTS[0] = "auth"`

### Namespace Support

Commands trong subdirectory trở thành slash command có namespace:

```
.claude/commands/create-module.md    → /create-module
.claude/commands/db/migrate.md       → /db:migrate
.claude/commands/db/seed.md          → /db:seed
.claude/commands/git/pr.md           → /git:pr
```

Dùng namespace để nhóm các command liên quan và tránh đặt tên trùng.

---

## Template Command

```markdown
# [Tên Command]

## Purpose
[Command này làm gì — 1-2 câu]

## Usage
/[command-name] [mô tả argument]

## Arguments
- `$ARGUMENTS`: [Mô tả argument — ví dụ "tên module cần tạo"]

## Steps

1. **[Tiêu đề bước 1]**
   [Mô tả chi tiết Claude cần làm trong bước này]

2. **[Tiêu đề bước 2]**
   [Mô tả chi tiết]

3. **[Tiêu đề bước 3]**
   [Mô tả chi tiết]

## Output
[Mô tả kết quả — liệt kê các file được tạo hoặc chỉnh sửa]

## Example
/[command-name] example-arg

Expected output:
- [File 1 tạo tại đường dẫn]
- [File 2 tạo tại đường dẫn]
```

---

## Commands vs Skills — Khi nào dùng cái nào

Cả commands và skills đều định nghĩa các workflow có thể tái sử dụng. Sự khác biệt là ở độ phức tạp và tính năng hỗ trợ.

| | Commands | Skills |
|---|---|---|
| **Vị trí** | `.claude/commands/*.md` | `.claude/skills/<name>/SKILL.md` |
| **Frontmatter** | Không | Có (role, tools, triggers) |
| **Supporting files** | Không | Có (template, schema đi kèm) |
| **Auto-invocation** | Không | Có (qua field `triggers`) |
| **Phù hợp cho** | Workflow đơn giản, một lần | Workflow phức tạp cần persona hoặc tooling |

**Dùng command khi:**
- Workflow có 5-15 bước và vừa trong một file
- Không cần vai trò hoặc persona cụ thể cho Claude
- Không có supporting asset nào (template, schema) cần đi kèm

**Dùng skill khi:**
- Workflow cần field `role` để gán persona cụ thể cho Claude
- Cần auto-invoke dựa trên pattern (ví dụ khi file khớp glob bị sửa)
- Có các file hỗ trợ mà workflow cần tham chiếu
- File command sẽ vượt quá khoảng 50 dòng

---

## Tips viết command hiệu quả

- **Tham chiếu file cụ thể.** "Đọc `src/modules/auth/auth.module.ts` để học pattern module" hữu ích hơn "xem các module hiện có".
- **Liệt kê output rõ ràng.** Nêu tên các file Claude sẽ tạo hoặc sửa để người dùng biết kết quả mong đợi.
- **Giữ các bước theo thứ tự.** Đánh số từng bước và mỗi bước chỉ thực hiện một hành động cụ thể.
- **Giữ file ngắn gọn.** Nếu command vượt quá 50 dòng, chuyển sang `.claude/skills/` để có thể đi kèm supporting files.
- **Test với ví dụ thực tế.** Chạy command một lần với input thực để xác nhận output khớp kỳ vọng trước khi chia sẻ với team.

---

## Xem ví dụ thực tế

[example-create-module.md](./example-create-module.md)

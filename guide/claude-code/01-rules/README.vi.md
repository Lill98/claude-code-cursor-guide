# Rules: CLAUDE.md và Path-Scoped Rules

Claude đọc rules từ hai nơi: file `CLAUDE.md` ở root của project, và các file rule theo đường dẫn nằm trong `.claude/rules/`. Hai nguồn này kết hợp để cho Claude biết cấu trúc codebase và cách xử lý công việc.

---

## CLAUDE.md là gì

`CLAUDE.md` là file Markdown đặt ở **root của project**. Claude đọc file này tự động trước khi bắt đầu bất kỳ task nào — trước cả khi xem code. Dùng file này để ghi lại những quyết định không hiện ra rõ ràng trong source code: naming conventions, patterns bắt buộc, lựa chọn thư viện, và các điểm dễ nhầm.

Hãy xem đây như một tài liệu onboarding ngắn do team viết, gửi đến Claude.

---

## Template CLAUDE.md

Copy nội dung này vào root project và điền vào từng phần. Xóa những phần không áp dụng.

```markdown
# [Tên Project]

## Project Overview
- **Purpose:** [Project làm gì — một câu]
- **Stack:** [Công nghệ chính, ví dụ NestJS, Prisma, PostgreSQL]
- **Type:** [API / Web App / Library / CLI / ...]
- **Domain:** [B2B SaaS / E-commerce / Internal tool / ...]

## Architecture
[Mô tả các module, layer, và pattern chính — 3-8 bullet points]

## Code Conventions

### File Structure
[Quy tắc đặt tên file, tổ chức thư mục]

### Naming
- Variables: camelCase
- Classes: PascalCase
- Files: kebab-case
- Constants: UPPER_SNAKE_CASE

### Key Patterns
[Các pattern bắt buộc — ví dụ "dùng repository pattern", "luôn wrap DB call trong service"]

## Validation & DTOs
[Thư viện validation nào được dùng và DTO đặt ở đâu]

## Database
[ORM / query builder, chiến lược migration, quy ước đặc biệt]

## Testing
[Framework test, cách tổ chức test, chiến lược mock]

## API Response Format
[Cấu trúc response chuẩn nếu có]

## DO
- [Practice tốt cụ thể 1]
- [Practice tốt cụ thể 2]

## DON'T
- [Điều cần tránh 1]
- [Điều cần tránh 2]

## Important Context
[Bất kỳ điều gì sẽ khiến engineer mới bất ngờ — gotchas, quyết định không rõ ràng]
```

---

## Path-Scoped Rules (.claude/rules/)

Path-scoped rules là các file rule chỉ được load khi Claude đang làm việc với file khớp với glob pattern. Tính năng này giữ cho CLAUDE.md ngắn gọn bằng cách tách context chỉ liên quan đến một phần cụ thể của codebase ra file riêng.

### Format

Mỗi file rule là một file Markdown với YAML frontmatter:

```markdown
---
paths:
  - "src/modules/payments/**"
  - "src/webhooks/**"
---

# Payment Module Rules

- Không bao giờ log dữ liệu thẻ raw, kể cả trong debug mode.
- Tất cả Stripe webhook handler phải verify signature trước khi xử lý.
- Dùng `PaymentResult<T>` làm return type cho mọi payment operation.
```

Đặt file ở bất kỳ đâu trong `.claude/rules/`, ví dụ:

```
.claude/rules/payments.md
.claude/rules/auth.md
.claude/rules/database.md
```

### Khi nào dùng Path-Scoped Rules vs CLAUDE.md

| Dùng CLAUDE.md khi... | Dùng .claude/rules/ khi... |
|---|---|
| Rule áp dụng cho toàn bộ codebase | Rule chỉ liên quan đến một module hoặc layer |
| Là convention đặt tên hoặc cấu trúc toàn cục | Chứa ràng buộc theo domain (bảo mật, compliance) |
| Ngắn gọn, không làm phình file | Sẽ đẩy CLAUDE.md vượt quá 200 dòng |

### Glob Pattern thường dùng

```
src/modules/auth/**        # Mọi file trong auth module
src/**/*.spec.ts           # Tất cả test file
prisma/**                  # Schema và migration Prisma
src/common/**              # Shared utilities và decorator
**/*.dto.ts                # Tất cả DTO file bất kể vị trí
src/modules/payments/**    # Một domain module cụ thể
```

---

## Cú pháp @import

Bạn có thể tách một CLAUDE.md lớn thành nhiều file và import chúng:

```markdown
# My Project

@architecture.md
@conventions/naming.md
@conventions/testing.md
```

Claude sẽ load các file được tham chiếu như thể nội dung của chúng nằm trực tiếp trong file gốc. Path là tương đối so với file chứa lệnh `@import`. Dùng cú pháp này khi:

- Một phần (như API conventions) đủ dài để có file riêng
- Nhiều project chia sẻ một bộ rule chung lưu trong file dùng chung
- Bạn muốn version control từng phần độc lập

---

## Tips

- **Giữ CLAUDE.md dưới 200 dòng.** Claude đọc file này trong mỗi task. File dài làm loãng sự chú ý và tăng chi phí token.
- **Cụ thể.** "Dùng Zod cho tất cả request validation" hữu ích hơn "validate inputs".
- **Thêm code example ngắn cho pattern không rõ ràng.** Một đoạn 4 dòng đáng giá hơn một đoạn văn dài.
- **Cập nhật khi convention thay đổi.** Rule lỗi thời còn tệ hơn không có rule — chúng khiến Claude hiểu sai.
- **Không ghi lại những gì Claude có thể đọc từ code.** Nếu một pattern nhất quán và thấy rõ trong các file hiện có, Claude sẽ học từ ví dụ. CLAUDE.md dành cho những quyết định không thấy trong code.

### Không nên đặt gì trong CLAUDE.md

- Cách framework hoạt động cơ bản (Claude đã biết NestJS, Prisma, v.v.)
- Thông tin đã có trong package.json hoặc tsconfig
- Hướng dẫn chỉ áp dụng cho một file — đặt trong file đó dưới dạng comment
- Bất kỳ thứ gì bí mật (API key, password) — dùng environment variables

---

## Xem ví dụ thực tế

[example-blog.md](./example-blog.md)

# Cách Viết Prompt Hiệu Quả

Prompt tốt là cụ thể, có giới hạn, và kiểm chứng được. Tài liệu này gồm các kỹ thuật thực tế và ví dụ trước/sau.

---

## Workflow 4 Giai Đoạn

Trước khi viết prompt, xác định bạn đang ở giai đoạn nào:

```
Giai đoạn 1: EXPLORE (Plan Mode)
  → Hiểu không gian vấn đề
  → Nhờ Claude đọc file liên quan và tóm tắt
  → CHƯA viết code

Giai đoạn 2: PLAN
  → Xác định chính xác cần xây dựng gì
  → Thống nhất hướng tiếp cận trước khi implement
  → Chỉ rõ constraints, file paths, interfaces

Giai đoạn 3: IMPLEMENT
  → Một task focused mỗi message
  → Thêm verification criteria vào prompt
  → Cung cấp error logs, file paths, line numbers

Giai đoạn 4: COMMIT
  → Verify tất cả test pass
  → Review diff
  → Commit với message rõ ràng
```

Bỏ qua giai đoạn 1 và 2 là nguyên nhân phổ biến nhất của token lãng phí và implement sai hướng.

---

## Ví Dụ Trước / Sau

### Ví dụ 1: Bug Fix

```
Tệ:  "Fix the login bug"

Tốt: "Fix the login bug in src/auth/login.service.ts.
      Error: 'Cannot read property userId of undefined' at line 83.
      Full stack trace:
        TypeError: Cannot read property 'userId' of undefined
          at LoginService.validateToken (login.service.ts:83:21)
          at AuthGuard.canActivate (auth.guard.ts:34:18)
      After fixing, run `npm test src/auth` to verify."
```

### Ví dụ 2: Feature Mới

```
Tệ:  "Add user invitation feature"

Tốt: "Add an inviteUser() method to InvitationService 
      in src/modules/invitation/invitation.service.ts.
      
      Requirements (từ spec specs/SH-164.md):
      - Tạo User với status: 'pending'
      - Gửi invitation email qua EmailService
      - Từ chối nếu email đã tồn tại trong cùng firm (throw ConflictException)
      - Filter tất cả query theo firmId và deletedAt: null
      
      After implementing, run: npx vitest --run src/modules/invitation"
```

### Ví dụ 3: Refactor

```
Tệ:  "Refactor the auth module"

Tốt: "Refactor src/auth/auth.service.ts để extract token validation 
      vào một private method validateToken() riêng.
      Code hiện tại: lines 45–82 trong method login() làm inline token checking.
      Không thay đổi public method signature.
      After refactoring, run: npm test src/auth"
```

---

## Cung Cấp Context Hiệu Quả

### Dùng @filename để tham chiếu file

```
Fix the bug in @src/auth/login.service.ts — the error is on line 83.
```

Claude đọc file trực tiếp từ reference, không cần lệnh bổ sung.

### Pipe shell output vào prompt bằng `!`

```
! cat src/auth/login.service.ts
Explain what the validateToken method does and where it could throw.
```

### Paste full error logs — đừng tóm tắt

```
Tệ:  "There's a Prisma error when creating a user"

Tốt: "Getting this error when running the invitation test:
      PrismaClientKnownRequestError: 
        Unique constraint failed on the fields: (`email`,`firmId`)
        at Object.request (node_modules/@prisma/client/runtime/index.js:45891:15)
        at InvitationService.inviteUser (invitation.service.ts:28:27)
      Fix this in src/modules/invitation/invitation.service.ts"
```

Full error log cho Claude call stack chính xác. Tóm tắt thì không.

---

## Thêm Verification Criteria Ngay Từ Đầu

Luôn cho Claude biết cách verify kết quả của nó. Điều này cải thiện kết quả hơn hầu hết mọi thứ khác.

```
Implement validateInviteInput() in invitation.service.ts.
When done, run: npx vitest --run src/modules/invitation/invitation.service.spec.ts
Fix any failing tests before responding.
```

Không có verification criteria, Claude dừng sau khi viết code. Có chúng, Claude chạy test, phát hiện lỗi, và fix trong cùng một lượt.

---

## Chỉ Định Constraints

Cho Claude constraints cụ thể để tránh vượt phạm vi:

| Loại Constraint | Ví dụ |
|----------------|-------|
| Phạm vi file | "Only modify src/modules/invitation/invitation.service.ts" |
| Line numbers | "The issue is around line 80–95" |
| Giữ nguyên interface | "Do not change the public API" |
| Test command | "Run npx vitest --run after each change" |
| Dependencies | "Do not add new npm packages" |

---

## Anti-Patterns

### Kitchen Sink Prompt
```
Tệ: "Add user invitation, fix the login bug, refactor auth, 
     update tests, and write docs for the API"

Tốt: Một task mỗi message. Nối tiếp nhau sau khi mỗi cái thành công.
```

### Yêu Cầu Mơ Hồ
```
Tệ: "Make the code better"
    → Claude không biết tối ưu theo chiều nào

Tốt: "Reduce the cyclomatic complexity of inviteUser() — 
     it currently has 4 nested if blocks"
```

### Over-Specified Implementation Details
```
Tệ: "Use a for loop to iterate over the array, 
     then push each item into a new array, 
     then return the new array"
    → Bạn đang viết code thay cho Claude

Tốt: "Filter the invitation list to only include pending invitations 
     older than 7 days. Write a test for this."
```

### Không Có Verification
```
Tệ: "Add the email validation check"
Tốt: "Add the email validation check. Run the test suite. Fix failures."
```

---

## Interview Approach Cho Feature Phức Tạp

Với feature phức tạp hoặc mơ hồ, để Claude hỏi câu hỏi trước khi implement. Cách này phát lộ hiểu lầm trước khi tốn token.

```
I need to add multi-tenant invitation with role-based scoping.
Before you start implementing, ask me the clarifying questions 
you need to get this right. I will answer them, then you implement.
```

Claude thường hỏi về: edge cases, chiến lược xử lý lỗi, dùng pattern hiện có hay tạo mới, test nào cần viết. Trả lời trước tránh được hai vòng revision.

---

## Writer / Reviewer Pattern

Với code quan trọng về chất lượng, chạy Claude hai lượt:

**Lượt 1 — Writer:**
```
Implement the inviteUser() method in invitation.service.ts.
Write the most straightforward, readable implementation.
```

**Lượt 2 — Reviewer (message mới hoặc /btw):**
```
Review the inviteUser() method you just wrote.
Check for: missing error handling, Prisma N+1 queries, 
missing firmId filters, and TypeScript type safety.
Fix any issues you find.
```

Cách hai lượt phát hiện nhiều vấn đề hơn so với prompt "viết và review" gộp một.

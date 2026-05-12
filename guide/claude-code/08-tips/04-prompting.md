# How to Write Effective Prompts

Good prompts are specific, bounded, and verifiable. This document covers practical techniques and real before/after examples.

---

## The 4-Phase Workflow

Before writing any prompt, decide which phase you are in:

```
Phase 1: EXPLORE (Plan Mode)
  → Understand the problem space
  → Ask Claude to read relevant files and summarize
  → Do NOT write code yet
  
Phase 2: PLAN
  → Define exactly what needs to be built
  → Agree on the approach before implementation
  → Specify constraints, file paths, interfaces

Phase 3: IMPLEMENT
  → One focused task per message
  → Include verification criteria in the prompt
  → Provide error logs, file paths, line numbers

Phase 4: COMMIT
  → Verify all tests pass
  → Review the diff
  → Commit with a clear message
```

Skipping Phase 1 and 2 is the most common cause of wasted tokens and wrong implementations.

---

## Before / After Examples

### Example 1: Bug Fix

```
Bad:  "Fix the login bug"

Good: "Fix the login bug in src/auth/login.service.ts.
      Error: 'Cannot read property userId of undefined' at line 83.
      Full stack trace:
        TypeError: Cannot read property 'userId' of undefined
          at LoginService.validateToken (login.service.ts:83:21)
          at AuthGuard.canActivate (auth.guard.ts:34:18)
      After fixing, run `npm test src/auth` to verify."
```

### Example 2: New Feature

```
Bad:  "Add user invitation feature"

Good: "Add an inviteUser() method to InvitationService 
      in src/modules/invitation/invitation.service.ts.
      
      Requirements (from spec specs/SH-164.md):
      - Create a User with status: 'pending'
      - Send invitation email via EmailService
      - Reject if email already exists in the same firm (throw ConflictException)
      - Filter all queries by firmId and deletedAt: null
      
      After implementing, run: npx vitest --run src/modules/invitation"
```

### Example 3: Refactor

```
Bad:  "Refactor the auth module"

Good: "Refactor src/auth/auth.service.ts to extract token validation 
      into a separate validateToken() private method.
      Current code: lines 45–82 in the login() method do token checking inline.
      Do not change the public method signature.
      After refactoring, run: npm test src/auth"
```

---

## Providing Context Efficiently

### Use @filename to reference files

```
Fix the bug in @src/auth/login.service.ts — the error is on line 83.
```

Claude reads the file directly from the reference, no extra command needed.

### Pipe shell output into prompts with `!`

```
! cat src/auth/login.service.ts
Explain what the validateToken method does and where it could throw.
```

### Paste full error logs — do not summarize

```
Bad:  "There's a Prisma error when creating a user"

Good: "Getting this error when running the invitation test:
      PrismaClientKnownRequestError: 
        Unique constraint failed on the fields: (`email`,`firmId`)
        at Object.request (node_modules/@prisma/client/runtime/index.js:45891:15)
        at InvitationService.inviteUser (invitation.service.ts:28:27)
      Fix this in src/modules/invitation/invitation.service.ts"
```

Full error logs give Claude the exact call stack. Summaries do not.

---

## Include Verification Criteria Upfront

Always tell Claude how to verify its own work. This improves outcomes more than almost anything else.

```
Implement validateInviteInput() in invitation.service.ts.
When done, run: npx vitest --run src/modules/invitation/invitation.service.spec.ts
Fix any failing tests before responding.
```

Without verification criteria, Claude stops after writing the code. With them, Claude runs the tests, discovers failures, and fixes them in the same turn.

---

## Constraint Specification

Give Claude specific constraints to prevent overreach:

| Constraint Type | Example |
|----------------|---------|
| File scope | "Only modify src/modules/invitation/invitation.service.ts" |
| Line numbers | "The issue is around line 80–95" |
| Interface preservation | "Do not change the public API" |
| Test command | "Run npx vitest --run after each change" |
| Dependencies | "Do not add new npm packages" |

---

## Anti-Patterns

### Kitchen Sink Prompt
```
Bad: "Add user invitation, fix the login bug, refactor auth, 
     update tests, and write docs for the API"

Good: One task per message. Chain them after each succeeds.
```

### Vague Request
```
Bad: "Make the code better"
     → Claude does not know what dimension to optimize

Good: "Reduce the cyclomatic complexity of inviteUser() — 
     it currently has 4 nested if blocks"
```

### Over-Specified Implementation Details
```
Bad: "Use a for loop to iterate over the array, 
     then push each item into a new array, 
     then return the new array"
     → You are writing the code, not Claude

Good: "Filter the invitation list to only include pending invitations 
     older than 7 days. Write a test for this."
```

### No Verification
```
Bad: "Add the email validation check"
Good: "Add the email validation check. Run the test suite. Fix failures."
```

---

## Interview Approach for Complex Features

For complex or ambiguous features, let Claude ask questions before implementing. This surfaces misunderstandings before they cost tokens.

```
I need to add multi-tenant invitation with role-based scoping.
Before you start implementing, ask me the clarifying questions 
you need to get this right. I will answer them, then you implement.
```

Claude will typically ask about: edge cases, error handling strategy, whether to use existing patterns or create new ones, which tests to write. Answering these upfront avoids two rounds of revision.

---

## Writer / Reviewer Pattern

For quality-critical code, run Claude in two passes:

**Pass 1 — Writer:**
```
Implement the inviteUser() method in invitation.service.ts.
Write the most straightforward, readable implementation.
```

**Pass 2 — Reviewer (new message or /btw):**
```
Review the inviteUser() method you just wrote.
Check for: missing error handling, Prisma N+1 queries, 
missing firmId filters, and TypeScript type safety.
Fix any issues you find.
```

The two-pass approach catches more issues than a single "write and review" prompt.

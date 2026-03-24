# Example: Parallel TDD for SH-164 — Invite User via Email

End-to-end walkthrough of the TDD workflow using the SH-164 spec. Shows how to go from a spec file to red tests to green tests, with automatic test feedback after each Claude task.

---

## Step 0: Get the Spec

Use `/research-ticket SH-164` to generate the spec, or use the one already in this repo:

```
examples/specs/SH-164.md
```

The spec describes inviting a user via email. Key acceptance criteria:
- **AC02** — Reject duplicate or invalid email without creating a user
- **AC03** — On success: create user with `pending` status, send invitation email
- **AC03** — On failure: throw error, do not create user
- **AC04** — Send invitation email with correct content
- **AC05** — Assign role and scope (sub-firm/product) to the new user

---

## Step 1: Generate Test Stubs from the Spec

Run in Claude Code:

```
/spec-to-tests examples/specs/SH-164.md src/modules/invitation/invitation.service.spec.ts
```

Claude reads the spec, extracts behaviors from AC01–AC05, and creates two files.

**`src/modules/invitation/invitation.service.spec.ts`** (generated):

```typescript
import { describe, it, beforeEach } from 'vitest';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { PrismaClient } from '@prisma/client';

import { InvitationService } from './invitation.service';

describe('InvitationService', () => {
  let service: InvitationService;
  let prisma: DeepMockProxy<PrismaClient>;

  beforeEach(() => {
    prisma = mockDeep<PrismaClient>();
    service = new InvitationService(prisma as any);
  });

  describe('inviteUser', () => {
    it.todo('creates user with pending status on success');              // AC03
    it.todo('dispatches invitation email on success');                  // AC04
    it.todo('rejects duplicate email without creating user');           // AC02
    it.todo('rejects invalid email format without creating user');      // AC02
    it.todo('assigns role and scope to new user');                      // AC05
    it.todo('throws when email service fails without creating user');   // AC03 error case
  });

  describe('validateInviteInput', () => {
    it.todo('passes when all required fields are present');             // AC01
    it.todo('fails when email is missing');                             // AC01
    it.todo('fails when role is missing');                              // AC01
    it.todo('requires sub-firm scope when role is Manager');            // AC01
  });
});
```

**`src/modules/invitation/invitation.service.ts`** (scaffold, generated alongside):

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class InvitationService {
  constructor(private readonly prisma: PrismaService) {}

  async inviteUser(dto: any, firmId: string): Promise<any> {
    return undefined;
  }

  validateInviteInput(dto: any): void {
    return undefined;
  }
}
```

Both files exist. The project compiles. All tests are `todo`.

---

## Step 2: Implement Alongside

Open a second terminal and run:

```bash
npx vitest --run --reporter=verbose
```

Initial output — all stubs visible, nothing hidden:

```
 PASS  src/modules/invitation/invitation.service.spec.ts
  InvitationService
    inviteUser
      - creates user with pending status on success
      - dispatches invitation email on success
      - rejects duplicate email without creating user
      - rejects invalid email format without creating user
      - assigns role and scope to new user
      - throws when email service fails without creating user
    validateInviteInput
      - passes when all required fields are present
      - fails when email is missing
      - fails when role is missing
      - requires sub-firm scope when role is Manager

Test Files  1 passed (1)
Tests       10 todo (10)
```

This is the "parallel" part — tests exist and describe the expected behavior before any logic is written. As you (or Claude) implement each method, convert `it.todo()` to a full test with assertions. Watch the count shift from `todo` to `passed`.

Example: after implementing `inviteUser`:

```bash
npx vitest --run --reporter=verbose
```

```
 PASS  src/modules/invitation/invitation.service.spec.ts
  InvitationService
    inviteUser
      ✓ creates user with pending status on success (14ms)
      ✓ dispatches invitation email on success (9ms)
      ✓ rejects duplicate email without creating user (6ms)
      ...
```

---

## Step 3: Stop Hook — Automatic Feedback After Each Claude Task

Set up the Stop hook so test results appear automatically every time Claude finishes.

**`.claude/hooks/run-tests.sh`**:

```bash
#!/bin/bash
# Run unit tests after every Claude task

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

```bash
chmod +x .claude/hooks/run-tests.sh
```

**Add to `.claude/settings.json`** (alongside the existing hooks):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/prettier-fix.sh" }]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/lint-fix.sh" }]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/run-tests.sh" },
          { "type": "command", "command": "bash .claude/hooks/notify-done.sh" }
        ]
      }
    ]
  }
}
```

After Claude implements `inviteUser`, the console shows:

```
Running unit tests...
 PASS  src/modules/invitation/invitation.service.spec.ts
  ✓ InvitationService > inviteUser > creates user with pending status (14ms)
  ✓ InvitationService > inviteUser > dispatches invitation email (9ms)
  ✓ InvitationService > inviteUser > rejects duplicate email (6ms)
  ✓ InvitationService > inviteUser > assigns role and scope to new user (8ms)
  ✓ InvitationService > inviteUser > throws when email service fails (5ms)

Test Files  1 passed (1)
Tests  5 passed, 5 todo (10)
All tests passed.

==============================
  Claude has finished the task
==============================
```

You see the results before you run `git add`. No extra commands needed.

---

## Step 4: Husky Pre-commit Hook — Block Commits on Failure

Install Husky to enforce the test gate at commit time. This applies to all team members, not just Claude Code users.

```bash
npm install --save-dev husky
npx husky init
echo "npx vitest --run" > .husky/pre-commit
git add .husky/pre-commit && git commit -m "chore: add pre-commit test gate"
```

When all tests pass, `git commit` works normally:

```
$ git commit -m "feat: implement InvitationService"
 PASS  src/modules/invitation/invitation.service.spec.ts (10 tests)
[main 3a9b1c2] feat: implement InvitationService
```

When a test fails, the commit is rejected:

```
$ git commit -m "feat: implement InvitationService"
 FAIL  src/modules/invitation/invitation.service.spec.ts
  × InvitationService > inviteUser > rejects duplicate email without creating user

husky - pre-commit hook exited with code 1 (error)
```

Fix the failing test, then re-run `git commit`.

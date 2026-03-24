# Example: Parallel TDD for SH-164 — Invite User via Email (Cursor)

End-to-end walkthrough of the TDD workflow in Cursor using the SH-164 spec.

---

## Step 0: Set Up the Skill

Create `.cursor/skills/spec-to-tests/SKILL.md` from the template in [README.md](./README.md).

```bash
mkdir -p .cursor/skills/spec-to-tests
# Paste SKILL.md content from guide/cursor/03-tdd/README.md
```

No restart needed — Cursor discovers the skill automatically.

---

## Step 1: Generate Test Stubs

Have the spec file ready: `examples/specs/SH-164.md`

In Cursor chat:

```
Generate test stubs from examples/specs/SH-164.md for the InvitationService.
Output to src/modules/invitation/invitation.service.spec.ts
```

Cursor reads the spec, extracts behaviors from AC01–AC05, and creates two files.

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

Open a terminal and run:

```bash
npx vitest --run --reporter=verbose
```

Initial output — all stubs visible:

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

This is the "parallel" part — tests exist and describe the expected behavior before any logic is written.

In Cursor, ask the agent to implement one method at a time:

```
Implement InvitationService.inviteUser based on the spec in examples/specs/SH-164.md
```

After each method is implemented, convert the corresponding `it.todo()` stubs to full assertions. Re-run vitest to confirm they turn green.

After implementing `inviteUser`:

```
 PASS  src/modules/invitation/invitation.service.spec.ts
  InvitationService
    inviteUser
      ✓ creates user with pending status on success (14ms)
      ✓ dispatches invitation email on success (9ms)
      ✓ rejects duplicate email without creating user (6ms)
      ✓ rejects invalid email format without creating user (4ms)
      ✓ assigns role and scope to new user (8ms)
      ✓ throws when email service fails without creating user (5ms)
    validateInviteInput
      - passes when all required fields are present
      - fails when email is missing
      - fails when role is missing
      - requires sub-firm scope when role is Manager

Test Files  1 passed (1)
Tests  6 passed, 4 todo (10)
```

---

## Step 3: Stop Hook — Automatic Feedback After Each Task

Set up the `stop` hook so test results appear automatically every time Cursor finishes.

**`.cursor/hooks/run-tests.sh`**:

```bash
#!/bin/bash
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
chmod +x .cursor/hooks/run-tests.sh
```

**`.cursor/hooks.json`**:

```json
{
  "version": 1,
  "hooks": {
    "stop": [
      {
        "command": ".cursor/hooks/run-tests.sh",
        "type": "command",
        "timeout": 60
      }
    ]
  }
}
```

After Cursor implements `inviteUser`, the console shows:

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
```

---

## Step 4: Husky Pre-commit Hook

Set up Husky to block commits if tests fail:

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

---

## Comparing to Claude Code Version

| Step | Cursor | Claude Code |
|------|--------|-------------|
| Generate stubs | "Generate test stubs from SH-164..." | `/spec-to-tests examples/specs/SH-164.md src/...` |
| Auto-run tests after task | `stop` hook in `.cursor/hooks.json` | `Stop` hook in `.claude/settings.json` |
| Block commit | Husky (same) | Husky (same) |
| Output files | Same test file + scaffold | Same test file + scaffold |

The generated `invitation.service.spec.ts` and the Husky setup are identical regardless of tool. The only difference is the hook config format and skill invocation style.

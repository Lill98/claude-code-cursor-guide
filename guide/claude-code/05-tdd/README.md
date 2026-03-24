# Claude Code: TDD Workflow

Write tests from a spec in parallel with implementation — not after the code is done. This section covers two tools: a skill that generates failing test stubs from a spec, and hooks that run tests automatically after every Claude task and before every commit.

---

## Why Parallel Matters

The default AI workflow is: write code → ask AI to write tests. This produces **confirmatory tests** — tests that describe what the code does, not what it should do.

The TDD approach flips this: generate test stubs from the spec first, then implement. Tests are red from the start. Implementation fills them green, method by method. This catches mismatches between the spec and the code early, not after a code review.

"Parallel" means both files — the spec file and the implementation file — exist from the beginning of a task. You don't wait for the code to be done before creating tests.

---

## The Two-Part Workflow

| Part | Tool | What It Does |
|------|------|--------------|
| **1. Generate test stubs** | `/spec-to-tests` skill | Reads a spec file, extracts acceptance criteria, creates `it.todo()` stubs + an empty service scaffold |
| **2. Gate on test results** | Stop hook + Husky pre-commit | Shows test output after every Claude task; blocks `git commit` if tests fail |

---

## Part 1: Skill Template `/spec-to-tests`

Copy the content below into `.claude/commands/spec-to-tests.md`:

```markdown
# spec-to-tests

## Role
You are a Senior NestJS/TypeScript engineer practicing test-driven development. You know how to read a product spec and translate acceptance criteria into testable behaviors before any implementation exists.

## Context
The saafehouse-be project uses:
- **Vitest** (not Jest) for unit testing
- **jest-mock-extended** `mockDeep<PrismaClient>()` to mock Prisma
- Services receive PrismaService injected via constructor
- Every query must filter by `firmId` and `deletedAt: null`
- Exceptions: `NotFoundException`, `ForbiddenException`, `ConflictException`

## Input
$ARGUMENTS contains two paths separated by a space:
- Path 1: the spec file (e.g. `examples/specs/SH-164.md`)
- Path 2: the target test file to create (e.g. `src/modules/invitation/invitation.service.spec.ts`)

## Task
Read the spec file, extract all acceptance criteria as testable behaviors, then create two files: a test file with `it.todo()` stubs and a service scaffold so the project compiles.

## Steps

1. **Read the spec**
   Open Path 1 and identify:
   - The feature being built
   - All acceptance criteria (AC01, AC02, etc.)
   - The affected services/modules from the Technical Context section
   - The data models involved

2. **Extract behaviors**
   For each acceptance criterion, identify the testable behavior — not the UI interaction, but the business logic outcome:
   - AC: "system creates user with pending status" → behavior: `inviteUser creates a User record with status: 'pending'`
   - AC: "email service fails → show error toast, keep modal open" → behavior: `inviteUser throws when email service fails`
   - AC: "email uniqueness check fails → no user created" → behavior: `inviteUser does not create user when email already exists`

3. **Write the test file**
   Group behaviors by service method. Use `it.todo()` for each stub:
   ```typescript
   describe('ServiceName', () => {
     describe('methodName', () => {
       it.todo('behavior description from spec');
       it.todo('another behavior');
     });
   });
   ```
   Use descriptive test names that a non-engineer can read and verify against the spec.

4. **Write the service scaffold**
   Create the corresponding service file (if it does not exist) with:
   - The class definition
   - Empty method signatures matching what the test file imports
   - Methods return `undefined` (to be implemented)
   - Constructor accepting PrismaService

5. **Output both files**
   - Test file at Path 2
   - Service scaffold at the corresponding `.ts` path (replace `.spec.ts` with `.ts`)

## Output Format

Test file:
```typescript
import { describe, it, beforeEach } from 'vitest';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { PrismaClient } from '@prisma/client';

import { [ServiceName] } from './[service-file]';

describe('[ServiceName]', () => {
  let service: [ServiceName];
  let prisma: DeepMockProxy<PrismaClient>;

  beforeEach(() => {
    prisma = mockDeep<PrismaClient>();
    service = new [ServiceName](prisma as any);
  });

  describe('[methodName]', () => {
    it.todo('[behavior from AC01]');
    it.todo('[behavior from AC02]');
    it.todo('[error case from AC03]');
  });
});
```

## Quality Checklist
Before finishing, verify:
- [ ] Every acceptance criterion maps to at least one `it.todo()` stub
- [ ] Test names describe business behavior, not implementation steps
- [ ] Service scaffold compiles — no missing imports or type errors
- [ ] `it.todo()` is used, not `it.skip()` (todo is visible in Vitest output)
- [ ] Both files are created

## Example
Input: `/spec-to-tests examples/specs/SH-164.md src/modules/invitation/invitation.service.spec.ts`

Claude will:
1. Read `examples/specs/SH-164.md`
2. Extract behaviors from AC01–AC05
3. Create `src/modules/invitation/invitation.service.spec.ts` with `it.todo()` stubs
4. Create `src/modules/invitation/invitation.service.ts` scaffold
```

---

## How to Use `/spec-to-tests` (Step-by-Step)

```
1. Have a spec file ready — either from /research-ticket or written manually
   Example: examples/specs/SH-164.md

2. In Claude Code, run:
   /spec-to-tests examples/specs/SH-164.md src/modules/invitation/invitation.service.spec.ts

3. Claude generates two files:
   - invitation.service.spec.ts  ← it.todo() stubs, all red
   - invitation.service.ts       ← empty scaffold, compiles cleanly

4. Verify the test suite is red:
   npx vitest --run --reporter=verbose
   → Each stub shows as "todo" in the output

5. Start implementing methods — run vitest after each one to watch tests go green
```

---

## Part 2a: Stop Hook — Automatic Test Feedback

The `Stop` hook runs after every Claude task. It cannot block Claude (Stop hooks are non-blocking), but it surfaces test results in the console immediately — before you run `git add` or `git commit`.

### Setup

**Step 1: Create the hook script**

**`.claude/hooks/run-tests.sh`**

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

**Step 2: Grant execute permission**

```bash
chmod +x .claude/hooks/run-tests.sh
```

**Step 3: Add to `.claude/settings.json`**

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/run-tests.sh"
          }
        ]
      }
    ]
  }
}
```

### How to Use: Stop Hook (Step-by-Step)

```
1. Create .claude/hooks/run-tests.sh with the script above
2. Run: chmod +x .claude/hooks/run-tests.sh
3. Add the Stop event to .claude/settings.json
4. From now on: every time Claude finishes a task, unit tests run automatically
5. Review the test output before running git commit
```

> **Note:** `exit 0` is intentional. Stop hooks cannot block Claude — they display output only. Use the Husky pre-commit hook (below) to enforce a hard gate at commit time.

---

## Part 2b: Husky Pre-commit Hook — Hard Enforcement

The Husky pre-commit hook runs `vitest` before every `git commit`. If any test fails, the commit is rejected. This is the enforcement layer — it applies to the whole team regardless of which AI tool they use.

### Setup

**Step 1: Install Husky (one-time per project)**

```bash
npm install --save-dev husky
npx husky init
```

**Step 2: Set the pre-commit hook**

```bash
echo "npx vitest --run" > .husky/pre-commit
```

**Step 3: Commit the hook file**

```bash
git add .husky/pre-commit && git commit -m "chore: add pre-commit test gate"
```

### How to Use: Husky Pre-commit (Step-by-Step)

```
1. Run the 3 setup commands above (one-time per project)
2. Verify: cat .husky/pre-commit  → should show "npx vitest --run"
3. From now on: git commit is blocked if any test fails
4. When blocked, fix failing tests, then re-run git commit
5. To bypass in an emergency (not recommended): git commit --no-verify
```

> **Note:** The Husky hook applies to everyone on the team — not just Claude Code users. It enforces the gate at the git level.

---

## How the Two Hooks Work Together

| | Stop Hook | Husky Pre-commit |
|---|---|---|
| **When it runs** | After every Claude task | On every `git commit` |
| **Blocks?** | No — shows output only | Yes — commit rejected if tests fail |
| **Purpose** | Immediate feedback during AI-assisted development | Hard enforcement at commit time |
| **Applies to** | Claude Code users only | All team members |

The Stop hook catches problems early, while you're still in a Claude session. Husky makes sure nothing broken reaches the git history, regardless of how the code was written.

---

## Tips

- Use `it.todo()`, not `it.skip()` — `todo` tests are visible in Vitest output; `skip` hides intent
- The hook uses `vitest --run` not `--watch` — it exits after one run, fitting inside Claude Code's 60-second hook timeout
- For large test suites, scope the hook: replace `npx vitest --run` with `npx vitest --run src/modules/invitation`
- If the Stop hook slows your workflow, remove it from `settings.json` and rely on Husky alone

---

## See a Real-World Example

→ [Example: Parallel TDD for SH-164 — Invite User via Email](./example-tdd-workflow.md)

# Cursor: TDD Workflow

Write tests from a spec in parallel with implementation — not after the code is done. This section covers a Cursor Skill that generates failing test stubs from a spec, a `stop` hook that runs tests automatically after every agent task, and a Husky pre-commit hook that blocks commits when tests fail.

---

## Why Parallel Matters

The default AI workflow is: write code → ask AI to write tests. This produces **confirmatory tests** — tests that describe what the code does, not what it should do.

The TDD approach flips this: generate test stubs from the spec first, then implement. Tests are red from the start. Implementation fills them green, method by method. This catches mismatches between the spec and the code early, not after a code review.

---

## The Three-Part Workflow

| Part | Tool | What It Does |
|------|------|--------------|
| **1. Generate test stubs** | `spec-to-tests` Skill | Reads a spec file, extracts acceptance criteria, creates `it.todo()` stubs + an empty service scaffold |
| **2. Auto-run tests after task** | `stop` hook in `.cursor/hooks.json` | Runs `vitest` automatically when the agent finishes — shows results before you commit |
| **3. Block commits on failure** | Husky pre-commit | Blocks `git commit` if any test fails |

---

## Part 1: Skill — `spec-to-tests`

Create `.cursor/skills/spec-to-tests/SKILL.md` with the content below.

```markdown
---
name: spec-to-tests
description: Generate failing Vitest unit test stubs from a product spec or requirements document, following TDD principles. Use when starting a new feature from a spec, when the user wants to write tests before implementation, when they mention "spec-to-tests", "TDD", or "write tests from the spec". Creates it.todo() stubs for each acceptance criterion plus an empty service scaffold.
---

# Spec to Tests

## Context

The saafehouse-be project uses:
- **Vitest** (not Jest) for unit testing
- **jest-mock-extended** `mockDeep<PrismaClient>()` to mock Prisma
- Services receive PrismaService injected via constructor
- Every query must filter by `firmId` and `deletedAt: null`
- Exceptions: `NotFoundException`, `ForbiddenException`, `ConflictException`

## Task

Read the spec file the user provides, extract all acceptance criteria as testable behaviors, then create two files: a test file with `it.todo()` stubs and a service scaffold so the project compiles immediately.

## Steps

1. **Read the spec**
   Open the spec file and identify:
   - The feature being built
   - All acceptance criteria (AC01, AC02, etc.)
   - The affected services/modules from the Technical Context section
   - The data models involved

2. **Extract behaviors**
   For each acceptance criterion, identify the testable behavior — not the UI interaction, but the business logic outcome:
   - AC: "system creates user with pending status" → behavior: `inviteUser creates a User record with status: 'pending'`
   - AC: "email uniqueness check fails → no user created" → behavior: `inviteUser does not create user when email already exists`
   - AC: "email service fails → show error toast" → behavior: `inviteUser throws when email service fails`

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
   Create the corresponding service file with:
   - The class definition with `@Injectable()` decorator
   - Empty method signatures matching what the test file imports
   - Methods return `undefined` (to be implemented)
   - Constructor accepting PrismaService

5. **Output both files**
   Create the test file at the path the user specified (or derive from the spec), and the scaffold at the corresponding `.ts` path.

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
- [ ] Every acceptance criterion maps to at least one `it.todo()` stub
- [ ] Test names describe business behavior, not implementation steps
- [ ] Service scaffold compiles — no missing imports or type errors
- [ ] `it.todo()` is used, not `it.skip()` (todo is visible in Vitest output)
- [ ] Both files are created

## Example

User says: "Generate test stubs for SH-164 — the invitation feature"

Agent will:
1. Read the spec file (e.g. `examples/specs/SH-164.md`)
2. Extract behaviors from AC01–AC05
3. Create `src/modules/invitation/invitation.service.spec.ts` with `it.todo()` stubs
4. Create `src/modules/invitation/invitation.service.ts` scaffold
```

---

## How to Use: `spec-to-tests` in Cursor (Step-by-Step)

```
1. Create the skill directory and SKILL.md:
   mkdir -p .cursor/skills/spec-to-tests
   # Paste the SKILL.md content above into .cursor/skills/spec-to-tests/SKILL.md

2. Have a spec file ready — either from /research-ticket or written manually
   Example: examples/specs/SH-164.md

3. In Cursor chat, say:
   "Generate test stubs from examples/specs/SH-164.md for the InvitationService"
   or:
   "Use spec-to-tests on SH-164 and output to src/modules/invitation/"

4. Cursor generates two files:
   - invitation.service.spec.ts  ← it.todo() stubs, all red
   - invitation.service.ts       ← empty scaffold, compiles cleanly

5. Verify the test suite is red:
   npx vitest --run --reporter=verbose
   → Each stub shows as "todo" in the output

6. Start implementing methods in Cursor — watch tests go green one by one
```

---

## Part 2: Stop Hook — Automatic Test Feedback

Cursor's `stop` hook fires when the agent loop ends. Use it to run `vitest` automatically after every task — test results appear before you run `git add` or `git commit`.

> See [Hooks Guide](../04-hooks/README.md) for full hook documentation.

### Setup

**Step 1: Create the hook script**

**`.cursor/hooks/run-tests.sh`**

```bash
#!/bin/bash
# Run unit tests after every Cursor agent task

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
chmod +x .cursor/hooks/run-tests.sh
```

**Step 3: Add to `.cursor/hooks.json`**

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

### How to Use: Stop Hook (Step-by-Step)

```
1. Create .cursor/hooks/run-tests.sh with the script above
2. Run: chmod +x .cursor/hooks/run-tests.sh
3. Create or update .cursor/hooks.json with the stop event
4. Save hooks.json — Cursor reloads it automatically, no restart needed
5. From now on: every time the agent finishes a task, unit tests run automatically
6. Review the test output before running git commit
```

> **Note:** `exit 0` is intentional. The `stop` hook cannot block the agent — it displays output only. Use Husky (below) to enforce a hard gate at commit time.

---

## Part 3: Husky Pre-commit Hook — Hard Enforcement

The Husky pre-commit hook runs `vitest` before every `git commit`. If any test fails, the commit is rejected. This applies to all team members regardless of which AI tool they use.

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

> **Note:** Husky applies to everyone on the team — not just Cursor users. It enforces the gate at the git level.

---

## Cursor vs Claude Code: TDD Workflow Comparison

| | Cursor | Claude Code |
|---|---|---|
| **Test stub generation** | `spec-to-tests` Skill (auto-detected by description) | `/spec-to-tests` command (explicit slash command) |
| **Auto-run tests after task** | `stop` hook in `.cursor/hooks.json` | `Stop` hook in `.claude/settings.json` |
| **Hook config file** | `.cursor/hooks.json` | `.claude/settings.json` |
| **Block commits** | Husky pre-commit (same) | Husky pre-commit (same) |
| **Invocation** | "generate test stubs from SH-164" | `/spec-to-tests examples/specs/SH-164.md src/...` |

Both tools support automatic test feedback after every agent task. The hook config format is different but the behavior is equivalent.

---

## Tips

- Use `it.todo()`, not `it.skip()` — `todo` tests are visible in Vitest output; `skip` hides intent
- Run `vitest --run` not `--watch` for one-shot checks
- If the test suite is large, scope the run: `npx vitest --run src/modules/invitation`

---

## See a Real-World Example

→ [Example: Parallel TDD for SH-164 — Invite User via Email](./example-tdd-workflow.md)

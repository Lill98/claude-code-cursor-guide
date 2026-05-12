---
name: spec-to-tests
description: Generate failing Vitest unit test stubs from a product spec or requirements document, following TDD principles. Use when starting a new feature from a spec, when the user wants to write tests before implementation, when they mention "spec-to-tests", "TDD", or "write tests from the spec". Creates it.todo() stubs for each acceptance criterion plus an empty service scaffold.
---

# Spec to Tests

## Context

This example assumes:
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

User says: "Generate test stubs for PROJ-123 — the invitation feature"

Agent will:
1. Read the spec file (e.g. `specs/PROJ-123.md`)
2. Extract behaviors from AC01–AC05
3. Create `src/modules/invitation/invitation.service.spec.ts` with `it.todo()` stubs
4. Create `src/modules/invitation/invitation.service.ts` scaffold

# Example: Skill `/write-test` for saafehouse-be

This is the actual `.claude/commands/write-test.md` file.
Copy the entire content below into `.claude/commands/write-test.md`.

---

```markdown
# write-test

## Role
You are a Senior NestJS engineer with expertise in unit testing, Vitest, and Prisma. You have a deep understanding of saafehouse-be architecture: multi-tenant RBAC, Zod validation, and the soft delete pattern.

## Context
The saafehouse-be project uses:
- **Vitest** (not Jest) for unit testing
- **jest-mock-extended** `mockDeep<PrismaClient>()` to mock Prisma
- Services receive PrismaService injected via constructor
- Every query must filter by `firmId` and `deletedAt: null`
- Responses are raw data (no wrapping — the interceptor handles wrapping)
- Exceptions: `NotFoundException`, `ForbiddenException`, `ConflictException`

## Input
$ARGUMENTS is the path to the service file that needs tests.
Example: `src/modules/firm/firm.service.ts`

## Task
Read the service file, analyze all methods, then write comprehensive Vitest unit tests with the project's standard mock strategy.

## Analysis Steps

1. **Read the service file**
   Read `$ARGUMENTS` and identify:
   - All public methods
   - Injected dependencies (usually PrismaService)
   - Prisma models being used
   - Exception types being thrown

2. **Analyze each method**
   For each method, determine:
   - Happy path (valid input, record exists)
   - Not found case (record doesn't exist or wrong firmId)
   - Conflict case (if there's a unique constraint)
   - Permission/ownership case (if applicable)
   - Soft delete behavior (findOne must skip records where deletedAt != null)

3. **Design test data**
   Create mock data factories:
   - `mockFirm`, `mockUser`, `mock[EntityName]` — objects with all fields
   - Consistent UUIDs for easy tracking

4. **Write tests**
   Organize by method, each method has multiple test cases.

## Output Format

Create a test file at the corresponding path (replace `.ts` with `.spec.ts`):

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { PrismaClient } from '@prisma/client';
import { NotFoundException, ConflictException } from '@nestjs/common';

import { [ServiceName] } from './[service-file]';

// ─── Mock Data ─────────────────────────────────────────────────────────────
const FIRM_ID = 'firm-uuid-001';
const USER_ID = 'user-uuid-001';

const mock[Entity] = {
  id: '[entity]-uuid-001',
  firmId: FIRM_ID,
  // ... all required fields
  createdAt: new Date('2024-01-01'),
  updatedAt: new Date('2024-01-01'),
  deletedAt: null,
};

// ─── Tests ─────────────────────────────────────────────────────────────────
describe('[ServiceName]', () => {
  let service: [ServiceName];
  let prisma: DeepMockProxy<PrismaClient>;

  beforeEach(() => {
    prisma = mockDeep<PrismaClient>();
    service = new [ServiceName](prisma);
  });

  describe('findAll', () => {
    it('should return array of [entity] for the firm', async () => {
      prisma.[model].findMany.mockResolvedValue([mock[Entity]]);

      const result = await service.findAll(FIRM_ID);

      expect(prisma.[model].findMany).toHaveBeenCalledWith({
        where: { firmId: FIRM_ID, deletedAt: null },
      });
      expect(result).toEqual([mock[Entity]]);
    });

    it('should return empty array when no [entity] exist', async () => {
      prisma.[model].findMany.mockResolvedValue([]);
      const result = await service.findAll(FIRM_ID);
      expect(result).toEqual([]);
    });
  });

  describe('findOne', () => {
    it('should return [entity] when found', async () => {
      prisma.[model].findFirst.mockResolvedValue(mock[Entity]);

      const result = await service.findOne(mock[Entity].id, FIRM_ID);

      expect(result).toEqual(mock[Entity]);
    });

    it('should throw NotFoundException when [entity] not found', async () => {
      prisma.[model].findFirst.mockResolvedValue(null);

      await expect(service.findOne('non-existent', FIRM_ID))
        .rejects.toThrow(NotFoundException);
    });

    it('should not return soft-deleted [entity]', async () => {
      prisma.[model].findFirst.mockResolvedValue(null);

      await service.findOne(mock[Entity].id, FIRM_ID).catch(() => {});

      expect(prisma.[model].findFirst).toHaveBeenCalledWith({
        where: expect.objectContaining({ deletedAt: null }),
      });
    });
  });

  describe('create', () => {
    const createDto = {
      // ... required fields
    };

    it('should create and return new [entity]', async () => {
      prisma.[model].create.mockResolvedValue(mock[Entity]);

      const result = await service.create(createDto, FIRM_ID);

      expect(prisma.[model].create).toHaveBeenCalledWith({
        data: { ...createDto, firmId: FIRM_ID },
      });
      expect(result).toEqual(mock[Entity]);
    });
  });

  describe('update', () => {
    it('should update and return [entity]', async () => {
      prisma.[model].findFirst.mockResolvedValue(mock[Entity]);
      prisma.[model].update.mockResolvedValue({ ...mock[Entity], name: 'Updated' });

      const result = await service.update(mock[Entity].id, { name: 'Updated' }, FIRM_ID);

      expect(result.name).toBe('Updated');
    });

    it('should throw NotFoundException when [entity] not found', async () => {
      prisma.[model].findFirst.mockResolvedValue(null);

      await expect(service.update('non-existent', {}, FIRM_ID))
        .rejects.toThrow(NotFoundException);
    });
  });

  describe('remove', () => {
    it('should soft delete [entity] by setting deletedAt', async () => {
      prisma.[model].findFirst.mockResolvedValue(mock[Entity]);
      prisma.[model].update.mockResolvedValue({ ...mock[Entity], deletedAt: new Date() });

      await service.remove(mock[Entity].id, FIRM_ID);

      expect(prisma.[model].update).toHaveBeenCalledWith({
        where: { id: mock[Entity].id },
        data: { deletedAt: expect.any(Date) },
      });
    });

    it('should throw NotFoundException when [entity] not found', async () => {
      prisma.[model].findFirst.mockResolvedValue(null);

      await expect(service.remove('non-existent', FIRM_ID))
        .rejects.toThrow(NotFoundException);
    });
  });
});
```

## Quality Checklist
Before finishing, verify:
- [ ] Every public method has at least 2 test cases (happy path + error)
- [ ] `findFirst`/`findMany` tests verify `deletedAt: null` in the where clause
- [ ] `firmId` is verified in Prisma calls
- [ ] Mock data has all required fields (no TypeScript errors)
- [ ] Imports are from `vitest`, not from `jest`
- [ ] `mockDeep<PrismaClient>()` is reset in `beforeEach`

## Example

Input: `/write-test src/modules/firm/firm.service.ts`

Claude will:
1. Read `src/modules/firm/firm.service.ts`
2. Identify methods: `findAll`, `findOne`, `create`, `update`, `remove`
3. Create `src/modules/firm/firm.service.spec.ts` with ~80-120 lines of tests
```

---

## Bonus Skill: `/review-pr`

Add to `.claude/commands/review-pr.md`:

```markdown
# review-pr

## Role
You are a Senior Engineer and Security Reviewer at saafehouse. You review code with high standards for security (multi-tenant isolation), code quality, and maintainability.

## Context
saafehouse-be is a multi-tenant SaaS. The most critical bug is data leakage between firms (missing firmId filter). Stack: NestJS + Prisma + Zod + Vitest + RBAC.

## Task
Review all staged changes (`git diff --staged`) or the file specified in $ARGUMENTS. Provide structured feedback.

## Analysis Steps

1. **Security scan** — Highest priority
   - Does every Prisma query have a `firmId` filter?
   - Is there any hard delete (must be soft delete)?
   - Does the endpoint have `@RequirePermission`?
   - Is input validated via Zod?

2. **Business logic**
   - Does the service method match the requirements?
   - Are edge cases (null, empty, concurrent) handled?
   - Are the exception types correct?

3. **Code quality**
   - Is there business logic in the controller? (not allowed)
   - Do DTOs use Zod? (class-validator is not allowed)
   - Test coverage: do new methods have tests?

4. **Conventions**
   - Are file/class names in correct kebab/PascalCase?
   - Is the response format correct? (services return raw data, no wrapping)

## Output Format

### CRITICAL (must fix before merge)
[Issues related to security, data integrity]

### WARNING (should fix)
[Issues related to conventions, missing tests]

### SUGGESTIONS (optional improvement)
[Nice-to-have improvements]

### LGTM
[Parts that are well implemented]
```

# Example: Skill `write-test` for saafehouse-be

This is the `SKILL.md` for a test-generation skill adapted for Cursor.
Create the directory `.cursor/skills/write-test/` and place this content in `SKILL.md`.

---

## File: `.cursor/skills/write-test/SKILL.md`

```markdown
---
name: write-test
description: Generate comprehensive Vitest unit tests for NestJS services with mockDeep PrismaClient, multi-tenant firmId verification, and soft delete testing. Use when writing tests, creating spec files, or when the user mentions unit testing, test coverage, or service tests.
---

# Write Test

## Context

The saafehouse-be project uses:
- **Vitest** (not Jest) for unit testing
- **jest-mock-extended** `mockDeep<PrismaClient>()` to mock Prisma
- Services receive PrismaService injected via constructor
- Every query must filter by `firmId` and `deletedAt: null`
- Responses are raw data (no wrapping — the interceptor handles wrapping)
- Exceptions: `NotFoundException`, `ForbiddenException`, `ConflictException`

## Task

Read the target service file, analyze all public methods, then generate comprehensive Vitest unit tests following the project's standard mock strategy.

## Steps

1. **Read the service file** and identify:
   - All public methods
   - Injected dependencies (usually PrismaService)
   - Prisma models being used
   - Exception types being thrown

2. **Analyze each method** to determine test cases:
   - Happy path (valid input, record exists)
   - Not found case (record doesn't exist or wrong firmId)
   - Conflict case (if there's a unique constraint)
   - Soft delete behavior (findOne must skip records where deletedAt != null)

3. **Design test data** with mock factories:
   - `mockFirm`, `mockUser`, `mock[EntityName]` — objects with all fields
   - Consistent UUIDs for easy tracking

4. **Write tests** organized by method, each with multiple test cases

## Output Format

Create a test file at the corresponding path (replace `.ts` with `.spec.ts`):

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { PrismaClient } from '@prisma/client';
import { NotFoundException, ConflictException } from '@nestjs/common';

import { [ServiceName] } from './[service-file]';

// ─── Mock Data ──────────────────────────────────────────────────────
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

// ─── Tests ──────────────────────────────────────────────────────────
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

    it('should throw NotFoundException when not found', async () => {
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
    const createDto = { /* required fields */ };

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

    it('should throw NotFoundException when not found', async () => {
      prisma.[model].findFirst.mockResolvedValue(null);
      await expect(service.update('non-existent', {}, FIRM_ID))
        .rejects.toThrow(NotFoundException);
    });
  });

  describe('remove', () => {
    it('should soft delete by setting deletedAt', async () => {
      prisma.[model].findFirst.mockResolvedValue(mock[Entity]);
      prisma.[model].update.mockResolvedValue({ ...mock[Entity], deletedAt: new Date() });
      await service.remove(mock[Entity].id, FIRM_ID);
      expect(prisma.[model].update).toHaveBeenCalledWith({
        where: { id: mock[Entity].id },
        data: { deletedAt: expect.any(Date) },
      });
    });

    it('should throw NotFoundException when not found', async () => {
      prisma.[model].findFirst.mockResolvedValue(null);
      await expect(service.remove('non-existent', FIRM_ID))
        .rejects.toThrow(NotFoundException);
    });
  });
});
```

## Quality Checklist
- [ ] Every public method has at least 2 test cases (happy path + error)
- [ ] `findFirst`/`findMany` tests verify `deletedAt: null` in the where clause
- [ ] `firmId` is verified in Prisma calls
- [ ] Mock data has all required fields (no TypeScript errors)
- [ ] Imports are from `vitest`, not from `jest`
- [ ] `mockDeep<PrismaClient>()` is reset in `beforeEach`
```

---

## Bonus Skill: `review-pr`

Create `.cursor/skills/review-pr/SKILL.md`:

```markdown
---
name: review-pr
description: Review code for multi-tenant security, NestJS conventions, Zod validation, and test coverage. Use when reviewing pull requests, code changes, diffs, or when the user asks for a code review.
---

# Code Review — saafehouse-be

## Context
saafehouse-be is a multi-tenant SaaS. The most critical bug is data leakage between firms (missing firmId filter). Stack: NestJS + Prisma + Zod + Vitest + RBAC.

## Review Checklist

### 1. Security (highest priority)
- Does every Prisma query have a `firmId` filter?
- Is there any hard delete (must be soft delete)?
- Does the endpoint have `@RequirePermission`?
- Is input validated via Zod?

### 2. Business Logic
- Does the service method match the requirements?
- Are edge cases (null, empty, concurrent) handled?
- Are the exception types correct?

### 3. Code Quality
- Is there business logic in the controller? (not allowed)
- Do DTOs use Zod? (class-validator is not allowed)
- Do new methods have tests?

### 4. Conventions
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

---

## Setup

```bash
# Create skill directories
mkdir -p .cursor/skills/write-test
mkdir -p .cursor/skills/review-pr

# Copy SKILL.md content into each directory
```

## Comparing to the Claude Code Version

The content of this skill is equivalent to the Claude Code `/write-test` command. The differences are:

| Aspect | This Cursor Skill | Claude Code `/write-test` |
|--------|-------------------|--------------------------|
| Location | `.cursor/skills/write-test/SKILL.md` | `.claude/commands/write-test.md` |
| Invocation | Auto-detected or user mentions testing | User types `/write-test path/to/service.ts` |
| Metadata | YAML frontmatter with `name` + `description` | None — uses `$ARGUMENTS` placeholder |
| Input | Agent infers from context or user request | Explicit `$ARGUMENTS` = file path |

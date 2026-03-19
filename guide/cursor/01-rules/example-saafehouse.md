# Example: Cursor Rules for saafehouse-be

These are the `.cursor/rules/*.mdc` files for the **saafehouse-be** project.
Create each file in `.cursor/rules/` in your project.

---

## File 1: `.cursor/rules/project-context.mdc`

```markdown
---
description: Core project context for saafehouse-be — stack, architecture, and overview
alwaysApply: true
---

# saafehouse-be

## Project Overview
- **Purpose:** Multi-tenant SaaS backend for real estate firm management
- **Stack:** NestJS, Prisma ORM, PostgreSQL, Zod, Vitest
- **Type:** REST API
- **Domain:** B2B SaaS — firm, agent, listing, and transaction management

## Architecture

Monolith NestJS with feature modules. Each domain is an independent module:

```
src/
├── modules/
│   ├── firm/          # Firm (tenant) management
│   ├── user/          # User management
│   ├── listing/       # Property listings
│   └── auth/          # Authentication
├── common/
│   ├── guards/        # AuthGuard, PermissionGuard
│   ├── decorators/    # @CurrentUser, @RequirePermission
│   ├── filters/       # Global exception filters
│   └── interceptors/  # Response transform interceptor
└── prisma/            # PrismaService
```

## Module Structure

Every module must follow this structure:

```
modules/[name]/
├── [name].module.ts
├── [name].controller.ts
├── [name].service.ts
├── [name].service.spec.ts
└── dto/
    ├── create-[name].dto.ts
    └── update-[name].dto.ts
```
```

---

## File 2: `.cursor/rules/nestjs-patterns.mdc`

```markdown
---
description: NestJS conventions — controller/service patterns, Zod DTOs, naming, RBAC
globs: "**/*.ts"
alwaysApply: false
---

# NestJS Patterns

## Naming
- Files: `kebab-case` (e.g., `firm-member.service.ts`)
- Classes: `PascalCase` (e.g., `FirmMemberService`)
- Variables/methods: `camelCase`
- Constants: `UPPER_SNAKE_CASE`

## Controller / Service Split
- Controllers only handle HTTP — no business logic
- Services contain all business logic
- Inject PrismaService directly into Services (do not use Repository pattern)

## Validation — Always Zod, Never class-validator

```typescript
import { z } from 'zod';
import { createZodDto } from 'nestjs-zod';

export const CreateFirmSchema = z.object({
  name: z.string().min(2).max(100),
  slug: z.string().regex(/^[a-z0-9-]+$/),
  ownerId: z.string().uuid(),
});

export class CreateFirmDto extends createZodDto(CreateFirmSchema) {}
```

## Authentication & Authorization
- JWT auth via `AuthGuard` (global guard)
- Permission-based RBAC via `@RequirePermission` decorator
- `RequestUser` contains: `id`, `firmId`, `role`, `permissions[]`
- Do not manually check permissions in services — use the decorator on controllers

```typescript
@Get(':id')
@RequirePermission('listing:read')
async findOne(
  @Param('id') id: string,
  @CurrentUser() user: RequestUser,
) {
  return this.listingService.findOne(id, user.firmId);
}
```

## API Response Format
Services return raw data — `ResponseInterceptor` wraps automatically. Do not manually wrap in controllers.

## DO
- Add `@RequirePermission` before every endpoint
- Use Zod schemas for all DTOs

## DON'T
- Do not use `class-validator` or `class-transformer`
- Do not put business logic in controllers
```

---

## File 3: `.cursor/rules/prisma-conventions.mdc`

```markdown
---
description: Prisma ORM conventions — multi-tenant firmId filter, soft delete, UUID keys
globs: "**/*.ts"
alwaysApply: false
---

# Prisma Conventions

## Primary Keys
UUID for all primary keys: `@id @default(uuid())`

## Soft Delete
- Every model has `deletedAt DateTime?`
- Never hard delete records
- Always include `deletedAt: null` in queries

## Timestamps
Every model must have `createdAt` and `updatedAt`.

## Multi-Tenant Isolation
Every query must filter by `firmId`. This is a security requirement — missing firmId means data leaks between tenants.

```typescript
const listing = await this.prisma.listing.findFirst({
  where: { id, firmId, deletedAt: null },
});
if (!listing) throw new NotFoundException('Listing not found');
```

## Error Handling
Use NestJS built-in exceptions:
- `NotFoundException` — resource does not exist
- `ForbiddenException` — no permission
- `BadRequestException` — invalid input
- `ConflictException` — duplicate resource

## DO
- Always filter by `firmId` in every Prisma query
- Use `deletedAt: null` when querying (soft delete)

## DON'T
- Do not hard delete records
- Do not skip `firmId` filter (multi-tenant security)
```

---

## File 4: `.cursor/rules/testing.mdc`

```markdown
---
description: Testing conventions — Vitest, mockDeep PrismaClient, test patterns
globs: "**/*.spec.ts"
alwaysApply: false
---

# Testing Conventions

**Use Vitest. Do not use Jest.**

## Standard Test Setup

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { PrismaClient } from '@prisma/client';

describe('FirmService', () => {
  let service: FirmService;
  let prisma: DeepMockProxy<PrismaClient>;

  beforeEach(() => {
    prisma = mockDeep<PrismaClient>();
    service = new FirmService(prisma);
  });

  it('should find firm by id', async () => {
    prisma.firm.findFirst.mockResolvedValue(mockFirm);
    const result = await service.findOne('uuid', 'firmId');
    expect(result).toEqual(mockFirm);
  });
});
```

## Rules
- Mock PrismaClient with `jest-mock-extended` (compatible with Vitest)
- Test files go next to the file being tested: `firm.service.spec.ts`
- Do not test controllers (logic lives in services)
- Every service method needs at least: happy path + error case
- Verify `firmId` and `deletedAt: null` are present in Prisma calls

## DO
- Import from `vitest`, not from `jest`
- Reset mocks in `beforeEach`
- Test soft delete behavior (deletedAt filter)

## DON'T
- Do not use Jest
- Do not skip firmId verification in tests
```

---

## Setup

```bash
# Create the rules directory
mkdir -p .cursor/rules

# Create each file above in .cursor/rules/
# project-context.mdc
# nestjs-patterns.mdc
# prisma-conventions.mdc
# testing.mdc
```

## Result

When you open a `.ts` file in Cursor, the agent automatically knows:
- Project architecture and stack (from `project-context.mdc`)
- NestJS patterns and Zod DTOs (from `nestjs-patterns.mdc`)
- Prisma multi-tenant rules (from `prisma-conventions.mdc`)

When you open a `.spec.ts` file, the agent additionally knows:
- Vitest setup, mock patterns, and test standards (from `testing.mdc`)

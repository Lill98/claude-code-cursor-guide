# Example: CLAUDE.md for saafehouse-be

This is the actual `CLAUDE.md` for the **saafehouse-be** project.
Copy the entire content below into `CLAUDE.md` at your project root.

---

```markdown
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

Every module must follow this exact structure:

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

## Code Conventions

### Naming
- Files: `kebab-case` (e.g., `firm-member.service.ts`)
- Classes: `PascalCase` (e.g., `FirmMemberService`)
- Variables/methods: `camelCase`
- Constants: `UPPER_SNAKE_CASE`
- Database fields: `snake_case` (Prisma schema)

### NestJS Patterns
- Controllers only handle HTTP — no business logic
- Services contain all business logic
- Inject PrismaService directly into Services (do not use the Repository pattern)

## Validation & DTOs

**Always use Zod. Never use class-validator.**

Standard pattern:

```typescript
// dto/create-firm.dto.ts
import { z } from 'zod';
import { createZodDto } from 'nestjs-zod';

export const CreateFirmSchema = z.object({
  name: z.string().min(2).max(100),
  slug: z.string().regex(/^[a-z0-9-]+$/),
  ownerId: z.string().uuid(),
});

export class CreateFirmDto extends createZodDto(CreateFirmSchema) {}
```

```typescript
// In module.ts — enable ZodValidationPipe globally
providers: [{ provide: APP_PIPE, useClass: ZodValidationPipe }]
```

## Database (Prisma)

- UUID for all primary keys: `@id @default(uuid())`
- Soft delete: `deletedAt DateTime?` field — never hard delete records
- Timestamps: `createdAt` and `updatedAt` on every model
- Multi-tenant: every query must filter by `firmId`

```typescript
// Always check firmId in queries
const listing = await this.prisma.listing.findFirst({
  where: { id, firmId, deletedAt: null },
});
if (!listing) throw new NotFoundException('Listing not found');
```

## Authentication & Authorization

- JWT auth via `AuthGuard` (global guard)
- Permission-based RBAC via `@RequirePermission` decorator

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

- `RequestUser` contains: `id`, `firmId`, `role`, `permissions[]`
- Do not manually check permissions in services — use the decorator on controllers

## API Response Format

All responses are wrapped by `ResponseInterceptor`:

```typescript
// Success response
{
  "data": { ... },        // single object
  "meta": { ... }         // optional pagination
}

// List response
{
  "data": [ ... ],
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 20
  }
}
```

Services only return raw data — the interceptor wraps automatically. Do not manually wrap in controllers.

## Testing

**Use Vitest. Do not use Jest.**

```typescript
// [name].service.spec.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

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

- Mock PrismaClient with `jest-mock-extended` (compatible with Vitest)
- Test files go next to the file being tested: `firm.service.spec.ts`
- Do not test controllers (logic lives in services)

## Error Handling

Use NestJS built-in exceptions:
- `NotFoundException` — resource does not exist
- `ForbiddenException` — no permission
- `BadRequestException` — invalid input
- `ConflictException` — duplicate resource

## DO
- Always filter by `firmId` in every Prisma query
- Use Zod schemas for all DTOs
- Add `@RequirePermission` before every endpoint
- Write tests for service methods
- Use `deletedAt: null` when querying (soft delete)

## DON'T
- Do not use `class-validator` or `class-transformer`
- Do not hard delete records in the database
- Do not put business logic in controllers
- Do not skip `firmId` filter (multi-tenant security)
- Do not use Jest (use Vitest)
```

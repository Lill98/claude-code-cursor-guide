# Example: Command `/create-module` for saafehouse-be

This is the actual `.claude/commands/create-module.md` file.
Copy the entire content below into `.claude/commands/create-module.md`.

---

```markdown
# create-module

## Purpose
Create a new NestJS feature module that follows saafehouse-be standards, including all boilerplate files and registration in the app.

## Usage
```
/create-module [module-name]
```

## Arguments
- `$ARGUMENTS`: Module name in kebab-case (e.g., `property-type`, `agent-profile`)

## Steps

1. **Read patterns from an existing module**
   Read all files in `src/modules/firm/` to learn exactly:
   - Module file structure
   - How to inject PrismaService
   - How to use the @RequirePermission decorator
   - Zod DTO pattern
   - Service method patterns (findAll, findOne, create, update, remove)

2. **Create directory and files**
   Create `src/modules/$ARGUMENTS/` with the following files (replace `$ARGUMENTS` with the module name, use PascalCase for class names):

   - `$ARGUMENTS.module.ts` — NestJS module, imports PrismaModule
   - `$ARGUMENTS.controller.ts` — REST controller with CRUD endpoints, uses @RequirePermission
   - `$ARGUMENTS.service.ts` — Business logic, injects PrismaService, always filters by firmId
   - `$ARGUMENTS.service.spec.ts` — Vitest unit tests with mockDeep PrismaClient
   - `dto/create-$ARGUMENTS.dto.ts` — Zod schema + createZodDto
   - `dto/update-$ARGUMENTS.dto.ts` — Partial of the Create schema

3. **Create standard CRUD endpoints**
   Controller must have:
   - `GET /` — findAll (filter by firmId from @CurrentUser)
   - `GET /:id` — findOne
   - `POST /` — create
   - `PATCH /:id` — update
   - `DELETE /:id` — softDelete (set deletedAt, do not delete from DB)

   Permission format: `[module-name]:read`, `[module-name]:write`, `[module-name]:delete`

4. **Register in AppModule**
   Open `src/app.module.ts` and add the new module to the `imports` array.

5. **Verify**
   Re-read the created files and check:
   - firmId filter is present in every Prisma query
   - deletedAt: null is included in every findFirst/findMany
   - No business logic in the controller
   - DTOs use Zod (not class-validator)

## Output
Files to be created:
```
src/modules/$ARGUMENTS/
├── $ARGUMENTS.module.ts
├── $ARGUMENTS.controller.ts
├── $ARGUMENTS.service.ts
├── $ARGUMENTS.service.spec.ts
└── dto/
    ├── create-$ARGUMENTS.dto.ts
    └── update-$ARGUMENTS.dto.ts
```

File to be modified:
- `src/app.module.ts` (add import)

## Example
```
/create-module property-type
```

Expected output:
- `src/modules/property-type/property-type.module.ts`
- `src/modules/property-type/property-type.controller.ts`
- `src/modules/property-type/property-type.service.ts`
- `src/modules/property-type/property-type.service.spec.ts`
- `src/modules/property-type/dto/create-property-type.dto.ts`
- `src/modules/property-type/dto/update-property-type.dto.ts`
- `src/app.module.ts` (updated)
```

---

## Usage

```bash
# In Claude Code CLI:
/create-module property-type
/create-module agent-profile
/create-module transaction-history
```

## Notes

This command works best when:
- The project already has a `CLAUDE.md` with conventions
- At least one example module exists (e.g., `firm`) for Claude to learn patterns from
- The Prisma schema already has a corresponding model (or Claude will create the migration)

# Rules: CLAUDE.md and Path-Scoped Rules

Claude reads rules from two places: a project-level `CLAUDE.md` at the repo root, and path-scoped rule files under `.claude/rules/`. Together they tell Claude how your codebase is structured and how to behave.

---

## What CLAUDE.md Is

`CLAUDE.md` is a Markdown file placed at the **root of your project**. Claude reads it automatically at the start of every task — before looking at any code. Use it to capture decisions that are not obvious from reading the source: naming conventions, required patterns, library choices, and known pitfalls.

Think of it as a short onboarding note written by the team, addressed to Claude.

---

## CLAUDE.md Template

Copy this into your project root and fill in each section. Remove sections that do not apply.

```markdown
# [Project Name]

## Project Overview
- **Purpose:** [What the project does — one sentence]
- **Stack:** [Main technologies, e.g. NestJS, Prisma, PostgreSQL]
- **Type:** [API / Web App / Library / CLI / ...]
- **Domain:** [B2B SaaS / E-commerce / Internal tool / ...]

## Architecture
[Describe modules, layers, and key patterns — 3-8 bullet points]

## Code Conventions

### File Structure
[File naming rules, directory layout]

### Naming
- Variables: camelCase
- Classes: PascalCase
- Files: kebab-case
- Constants: UPPER_SNAKE_CASE

### Key Patterns
[Required patterns — e.g., "use repository pattern", "always wrap DB calls in a service"]

## Validation & DTOs
[Which validation library is used and where DTOs live]

## Database
[ORM / query builder, migration strategy, special conventions]

## Testing
[Test framework, how tests are co-located, mock strategy]

## API Response Format
[Standard response envelope if one exists]

## DO
- [Explicit good practice 1]
- [Explicit good practice 2]

## DON'T
- [Thing to avoid 1]
- [Thing to avoid 2]

## Important Context
[Anything that would surprise a new engineer — gotchas, non-obvious decisions]
```

---

## Path-Scoped Rules (.claude/rules/)

Path-scoped rules are rule files that only load when Claude is working on files that match a glob pattern. They keep CLAUDE.md short by moving context that only matters for a specific area of the codebase into its own file.

### Format

Each rule file is a Markdown file with YAML frontmatter:

```markdown
---
paths:
  - "src/modules/payments/**"
  - "src/webhooks/**"
---

# Payment Module Rules

- Never log raw card data, even in debug mode.
- All Stripe webhook handlers must verify the signature before processing.
- Use `PaymentResult<T>` as the return type for all payment operations.
```

Place the file anywhere under `.claude/rules/`, for example:

```
.claude/rules/payments.md
.claude/rules/auth.md
.claude/rules/database.md
```

### When to Use Path-Scoped Rules vs CLAUDE.md

| Use CLAUDE.md when... | Use .claude/rules/ when... |
|---|---|
| The rule applies to the whole codebase | The rule only matters for one module or layer |
| It is a global naming or structure convention | It contains domain-specific constraints (security, compliance) |
| It is short enough to not clutter the file | It would push CLAUDE.md past 200 lines |

### Common Glob Patterns

```
src/modules/auth/**        # Everything under the auth module
src/**/*.spec.ts           # All test files
prisma/**                  # All Prisma schema and migration files
src/common/**              # Shared utilities and decorators
**/*.dto.ts                # All DTO files regardless of location
src/modules/payments/**    # A single domain module
```

---

## @import Syntax

You can split a large CLAUDE.md into multiple files and import them:

```markdown
# My Project

@architecture.md
@conventions/naming.md
@conventions/testing.md
```

Claude will load the referenced files as if their content were inline. Paths are relative to the file containing the `@import`. Use this when:

- A section (like API conventions) is long enough to deserve its own file
- Multiple projects share a base set of rules stored in a common file
- You want to version-control sections independently

---

## Tips

- **Keep CLAUDE.md under 200 lines.** Claude reads it on every task. Long files dilute attention and increase token cost.
- **Be specific.** "Use Zod for all request validation" is more useful than "validate inputs".
- **Add short code examples for non-obvious patterns.** A 4-line snippet is worth a paragraph of prose.
- **Update it when conventions change.** Stale rules are worse than no rules — they actively mislead.
- **Do not duplicate what Claude can read from code.** If a pattern is consistent and visible in existing files, Claude will learn it from examples. CLAUDE.md is for decisions that are not visible in the code.

### What NOT to put in CLAUDE.md

- How basic frameworks work (Claude already knows NestJS, Prisma, etc.)
- Information that is already in package.json or tsconfig
- Instructions that apply to only one file — put those in the file as comments
- Anything secret (API keys, passwords) — use environment variables

---

## See a Real-World Example

[example-blog.md](./example-blog.md)

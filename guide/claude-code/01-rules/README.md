# Template: CLAUDE.md

Place this file at the **root of your project** named `CLAUDE.md`. Claude will automatically read this file every time it starts a new task.

---

## How to Use This Template

1. Copy the **TEMPLATE** section below
2. Create a `CLAUDE.md` file at your project root
3. Fill in the actual information for your project in each section
4. Remove any sections that don't apply

---

## TEMPLATE

```markdown
# [Project Name]

## Project Overview
- **Purpose:** [Brief description of what the project does]
- **Stack:** [Main technologies]
- **Type:** [API / Web App / Library / CLI / ...]
- **Domain:** [B2B SaaS / E-commerce / Internal tool / ...]

## Architecture
[Describe the overall architecture — modules, layers, patterns]

## Code Conventions

### File Structure
[File naming rules, directory organization]

### Naming
- Variables: [camelCase / snake_case / ...]
- Classes: [PascalCase / ...]
- Files: [kebab-case / ...]
- Constants: [UPPER_SNAKE / ...]

### Key Patterns
[Required patterns — e.g., "use repository pattern", "use Result type"]

## Validation & DTOs
[Which validation framework is used and how]

## Database
[ORM/Query builder in use, special conventions]

## Testing
[Test framework, how to write tests, mock strategy]

## API Response Format
[Standard response structure for the project]

## DO
- [Thing to do 1]
- [Thing to do 2]

## DON'T
- [Thing to avoid 1]
- [Thing to avoid 2]

## Important Context
[Any special context Claude needs to know]
```

---

## Tips

- **Keep it concise** — Claude reads the entire file every time, keep it under 200 lines
- **Be specific** — "Use Zod" is better than "Use a validation library"
- **Short code examples** — Add 3-5 line snippets for complex patterns
- **Keep it updated** — When conventions change, update CLAUDE.md immediately

---

## See a Real-World Example

→ [example-saafehouse.md](./example-saafehouse.md)

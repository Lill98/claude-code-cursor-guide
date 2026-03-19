# Template: Cursor Rules (.mdc files)

Rules are `.mdc` files in `.cursor/rules/` that give Cursor persistent context about your project. Each rule has YAML frontmatter controlling when it applies, followed by markdown content.

---

## How to Create a Rule

1. Create a file at `.cursor/rules/your-rule-name.mdc`
2. Add YAML frontmatter with scope configuration
3. Write the rule content in markdown
4. Cursor automatically picks it up — no restart needed

---

## File Format

```markdown
---
description: Brief description of what this rule does
globs: **/*.ts
alwaysApply: false
---

# Rule Title

Your rule content here — conventions, patterns, examples...
```

### Frontmatter Fields

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | What the rule does (shown in the rule picker UI) |
| `globs` | string | Glob pattern — rule activates when matching files are open |
| `alwaysApply` | boolean | If `true`, applies to every conversation regardless of files |

---

## Three Scoping Modes

### 1. Always Apply

For universal project context that should be active in every conversation:

```yaml
---
description: Core project context and stack information
alwaysApply: true
---
```

Use for: project overview, architecture, team conventions that apply everywhere.

### 2. File-Scoped

For rules that only matter when working with specific file types:

```yaml
---
description: TypeScript conventions for this project
globs: **/*.ts
alwaysApply: false
---
```

Use for: language-specific patterns, framework conventions, test standards.

Common glob patterns:
- `**/*.ts` — all TypeScript files
- `**/*.spec.ts` — test files only
- `src/modules/**/*.ts` — module files only
- `**/*.prisma` — Prisma schema files
- `**/*.{ts,tsx}` — TypeScript and TSX files

### 3. Manual

For rules you only want when explicitly referenced:

```yaml
---
description: Migration guide for upgrading from v1 to v2
alwaysApply: false
---
```

No `globs` field — the rule only activates when the user mentions it or selects it from the rule picker.

---

## TEMPLATE

```markdown
---
description: [What this rule enforces or teaches — shown in the UI]
globs: [file pattern, e.g. **/*.ts]
alwaysApply: [true or false]
---

# [Rule Title]

## [Section 1 — e.g., Conventions]
[Concrete rules with examples]

## [Section 2 — e.g., Patterns]
[Code patterns to follow]

## DO
- [Thing to do]

## DON'T
- [Thing to avoid]
```

---

## Organizing Rules

### One Concern Per File

Split your project context into focused rules instead of one giant file:

| File | Scope | Content |
|------|-------|---------|
| `project-context.mdc` | Always | Stack, architecture, overview |
| `typescript-patterns.mdc` | `**/*.ts` | Language conventions |
| `testing.mdc` | `**/*.spec.ts` | Test framework, mock patterns |
| `api-conventions.mdc` | `**/controllers/**` | REST API patterns |

### Keep Rules Concise

- **Under 50 lines per rule** — focused rules are more effective than long ones
- **Concrete examples** — show 3-5 line code snippets for complex patterns
- **Actionable** — write like clear internal documentation, not tutorials

---

## Tips

- **Split, don't merge** — Multiple focused `.mdc` files > one massive file
- **Use globs** — Only load rules when they're relevant to the current file
- **Be specific** — "Use Zod for validation" beats "Use a validation library"
- **Include DO/DON'T** — Clear lists of what to do and what to avoid
- **Test by editing a file** — Open a matching file and check if Cursor applies the rule

---

## Cursor Rules vs Claude Code Rules

| Aspect | Cursor (`.mdc`) | Claude Code (`CLAUDE.md`) |
|--------|-----------------|--------------------------|
| File count | Multiple files, one per concern | Single file |
| Scoping | Glob patterns per file | Always active |
| Format | YAML frontmatter + markdown | Plain markdown |
| Location | `.cursor/rules/` | Project root |
| Line limit | ~50 lines per file recommended | ~200 lines total recommended |

If you use both tools, you can maintain separate rules for each — the content is similar, but the format and organization differ.

---

## See a Real-World Example

→ [example-saafehouse.md](./example-saafehouse.md)

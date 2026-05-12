# Template: Cursor Rules

Rules give Cursor persistent context about your project. They live in `.cursor/rules/` as `.md` or `.mdc` files with YAML frontmatter.

> **Scope note:** Rules apply to **Agent (Chat) only**. They do not apply to Cursor Tab (inline completions) or Inline Edit (Cmd+K).

---

## How to Create a Rule

Three ways:
1. **Chat:** Type `/create-rule` and describe what you need — Cursor creates the file for you
2. **Settings UI:** `Cursor Settings > Rules, Commands` → `+ Add Rule`
3. **Manual:** Create `.cursor/rules/your-rule-name.md` directly

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

## Four Scoping Modes

### 1. Always Apply

Active in every Agent conversation, regardless of which files are open:

```yaml
---
description: Core project context and stack information
alwaysApply: true
---
```

Use for: project overview, architecture, team conventions that apply everywhere.

### 2. Apply Intelligently

Agent reads the `description` and decides whether to apply the rule based on relevance to the current task:

```yaml
---
description: Prisma multi-tenant query patterns — filter by firmId and deletedAt
alwaysApply: false
---
```

No `globs` field, `alwaysApply: false`. The `description` field is what drives the decision — write it to clearly describe when this rule is relevant.

Use for: rules that are only useful for certain tasks but hard to scope to specific file patterns.

### 3. Apply to Specific Files

Activates when files matching the glob pattern are open or being edited:

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

### 4. Apply Manually

Only activates when explicitly referenced using `@rule-name` in the chat:

```yaml
---
description: Migration guide for upgrading from v1 to v2
alwaysApply: false
---
```

No `globs`, `alwaysApply: false`. User types `@migration-guide` to include this rule in the conversation.

Use for: reference guides, one-off procedures, or rules you want full control over.

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

## Alternative: `AGENTS.md`

For simpler cases, Cursor also supports plain `AGENTS.md` files in the project root or subdirectories — no frontmatter required. These are always active and apply to the directory they're placed in (and subdirectories).

Use `.cursor/rules/*.md` when you need scoping (globs, always, intelligent). Use `AGENTS.md` when you want a simple, flat rules file with no configuration.

---

## Cursor Rules vs Claude Code Rules

| Aspect | Cursor (`.md`/`.mdc`) | Claude Code (`CLAUDE.md`) |
|--------|-----------------|--------------------------|
| File count | Multiple files, one per concern | Single file |
| Scoping | 4 modes: always, intelligent, glob, manual | Always active |
| Manual invocation | `@rule-name` in chat | N/A |
| Format | YAML frontmatter + markdown | Plain markdown |
| Location | `.cursor/rules/` | Project root |
| Applies to | Agent (Chat) only | All Claude Code tasks |
| Line limit | ~50 lines per file recommended | ~200 lines total recommended |

If you use both tools, you can maintain separate rules for each — the content is similar, but the format and organization differ.

---

## See a Real-World Example

→ Copy the template above into `.cursor/rules/project-context.md` and adapt to your project.

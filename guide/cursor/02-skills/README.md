# Template: Cursor Skills (SKILL.md)

Skills are directories in `.cursor/skills/` (project-level) or `~/.cursor/skills/` (personal, cross-project) that teach Cursor's agent how to perform specific tasks. Each skill contains a `SKILL.md` file with YAML frontmatter and markdown instructions.

---

## How to Create a Skill

1. Create a directory: `.cursor/skills/your-skill-name/`
2. Create `SKILL.md` inside with YAML frontmatter
3. Optionally add reference files (`reference.md`, `examples.md`, scripts)
4. Cursor automatically discovers it — no restart needed

---

## Directory Structure

```
.cursor/skills/
└── your-skill-name/
    ├── SKILL.md              # Required — main instructions
    ├── reference.md          # Optional — detailed documentation
    ├── examples.md           # Optional — usage examples
    └── scripts/              # Optional — utility scripts
        └── helper.sh
```

### Storage Locations

| Type | Path | Scope |
|------|------|-------|
| **Project** | `.cursor/skills/skill-name/` | Shared with the team via the repo |
| **Personal** | `~/.cursor/skills/skill-name/` | Available across all your projects |

---

## File Format

```markdown
---
name: your-skill-name
description: Brief description of what this skill does and when to use it.
---

# Your Skill Name

## Instructions
Clear, step-by-step guidance for the agent.

## Examples
Concrete examples of using this skill.
```

### Frontmatter Fields

| Field | Requirements | Purpose |
|-------|-------------|---------|
| `name` | Max 64 chars, lowercase letters/numbers/hyphens only | Unique identifier |
| `description` | Max 1024 chars, non-empty | Helps the agent decide when to apply this skill |

---

## TEMPLATE

```markdown
---
name: [skill-name]
description: [What this skill does]. Use when [trigger scenarios].
---

# [Skill Name]

## Context
[Project context the agent needs — tech stack, conventions, patterns]

## Task
[What the agent should do — 1-2 sentences]

## Steps

1. **[Step 1]**
   [Detailed instructions]

2. **[Step 2]**
   [Detailed instructions]

3. **[Step 3]**
   [Detailed instructions]

## Output Format
[Describe the expected output structure]

## Quality Checklist
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Examples

**Input:** [example input]

**Expected output:**
```
[example output]
```
```

---

## Writing Effective Descriptions

The `description` field is critical — Cursor uses it to decide when to automatically apply the skill.

### Include Both WHAT and WHEN

```yaml
# Good — specific, includes trigger terms
description: Generate comprehensive Vitest unit tests for NestJS services with mockDeep PrismaClient. Use when writing tests, creating spec files, or when the user mentions unit testing.

# Bad — too vague
description: Helps with testing.
```

### Write in Third Person

```yaml
# Good
description: Reviews code for multi-tenant security, checking firmId filters in Prisma queries.

# Bad
description: I can help you review code for security issues.
```

---

## Best Practices

### Keep SKILL.md Under 500 Lines

For longer content, use progressive disclosure:

```markdown
# My Skill

## Quick Start
[Essential instructions — this is what the agent reads first]

## Additional Resources
- For complete API details, see [reference.md](reference.md)
- For usage examples, see [examples.md](examples.md)
```

### Be Concise

The agent is already smart. Only add context it doesn't already have:
- Domain-specific patterns it can't infer
- Project conventions that differ from defaults
- Concrete code examples for complex patterns

### One Concern Per Skill

Each skill should do one thing well. If a skill does multiple unrelated tasks, split it.

### Use Concrete Examples

Show input/output examples so the agent understands the expected quality level.

---

## Cursor Skills vs Claude Code Skills

| Aspect | Cursor (`SKILL.md`) | Claude Code (`.claude/commands/*.md`) |
|--------|---------------------|--------------------------------------|
| Location | `.cursor/skills/skill-name/SKILL.md` | `.claude/commands/skill-name.md` |
| Metadata | YAML frontmatter (`name`, `description`) | None (file name is the command name) |
| Discovery | Auto-detected by description matching | User types `/skill-name` explicitly |
| Invocation | Automatic or manual | Always manual (slash command) |
| Supporting files | Can include reference docs, scripts | Single markdown file only |
| Personal scope | `~/.cursor/skills/` | `~/.claude/commands/` |

The key difference: Claude Code skills are always invoked explicitly via slash commands, while Cursor skills can be automatically applied when the agent detects a matching task.

---

## See a Real-World Example

→ [example-write-test.md](./example-write-test.md)

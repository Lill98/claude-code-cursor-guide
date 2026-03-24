# Template: Cursor Skills (SKILL.md)

Skills are directories containing a `SKILL.md` file that teach Cursor's agent how to perform specific tasks. Cursor automatically discovers them at startup from known skill directories.

---

## How to Create a Skill

1. Create a directory: `.agents/skills/your-skill-name/`
2. Create `SKILL.md` inside with YAML frontmatter
3. Optionally add `scripts/`, `references/`, or `assets/` subdirectories
4. Cursor automatically discovers it — no restart needed
5. Invoke manually via `/skill-name` in Agent chat, or let the agent apply it automatically

---

## Directory Structure

```
.agents/skills/
└── your-skill-name/          # Folder name must match the `name` field in SKILL.md
    ├── SKILL.md              # Required — main instructions
    ├── scripts/              # Optional — executable scripts the agent can run
    │   └── helper.sh
    ├── references/           # Optional — additional docs loaded on demand
    │   └── api-reference.md
    └── assets/               # Optional — templates, images, data files
        └── template.ts
```

### Storage Locations

| Type | Path | Scope |
|------|------|-------|
| **Project** (preferred) | `.agents/skills/skill-name/` | Shared with the team via the repo |
| **Project** (also works) | `.cursor/skills/skill-name/` | Shared with the team via the repo |
| **Personal** | `~/.cursor/skills/skill-name/` | Available across all your projects |

> Legacy paths `.claude/skills/` and `.codex/skills/` are also recognized for compatibility.

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

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | Lowercase letters, numbers, hyphens only. **Must match the parent folder name.** |
| `description` | Yes | Helps the agent decide when to apply this skill. Be specific about trigger scenarios. |
| `disable-model-invocation` | No | Set to `true` to disable automatic invocation — skill only activates when user types `/skill-name` explicitly |
| `license` | No | License name or file reference |
| `compatibility` | No | Environment requirements |
| `metadata` | No | Arbitrary key-value pairs |

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
| Preferred location | `.agents/skills/skill-name/SKILL.md` | `.claude/commands/skill-name.md` |
| Metadata | YAML frontmatter (`name`, `description`, optional fields) | None (file name is the command name) |
| Discovery | Auto-detected by description matching | User types `/skill-name` explicitly |
| Invocation | Automatic or `/skill-name` | Always manual (slash command) |
| Disable auto-invoke | `disable-model-invocation: true` | N/A — always manual |
| Supporting files | `scripts/`, `references/`, `assets/` dirs | Single markdown file only |
| Personal scope | `~/.cursor/skills/` | `~/.claude/commands/` |
| Folder name | Must match `name` field | N/A |

The key difference: Claude Code skills are always invoked explicitly via slash commands, while Cursor skills are automatically applied when the agent detects a matching task (unless `disable-model-invocation: true`).

---

## See a Real-World Example

→ [example-write-test.md](./example-write-test.md)

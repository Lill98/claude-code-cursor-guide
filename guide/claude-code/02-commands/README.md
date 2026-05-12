# Commands: Slash Commands in Claude Code

Commands are slash commands (`/command-name`) you type directly in Claude Code. When invoked, Claude reads the corresponding `.md` file and executes the workflow defined inside it.

---

## How Commands Work

1. Create a file at `.claude/commands/command-name.md`
2. Write the workflow as Markdown — plain prose, bullet steps, or a mix
3. Invoke it by typing `/command-name [arguments]` in Claude Code

Claude replaces special placeholders in the file with the actual input you provide, then follows the instructions.

---

## Special Syntax

| Placeholder | Meaning |
|---|---|
| `$ARGUMENTS` | All text typed after the command name |
| `$ARGUMENTS[0]` | First space-separated argument |
| `$ARGUMENTS[1]` | Second space-separated argument |

Example: `/create-module auth` → `$ARGUMENTS = "auth"`, `$ARGUMENTS[0] = "auth"`

### Namespace Support

Commands in a subdirectory become namespaced slash commands:

```
.claude/commands/create-module.md    → /create-module
.claude/commands/db/migrate.md       → /db:migrate
.claude/commands/db/seed.md          → /db:seed
.claude/commands/git/pr.md           → /git:pr
```

Use namespaces to group related commands and avoid name collisions.

---

## Command Template

```markdown
# [Command Name]

## Purpose
[What this command does — 1-2 sentences]

## Usage
/[command-name] [argument-description]

## Arguments
- `$ARGUMENTS`: [Describe the argument — e.g., "name of the module to create"]

## Steps

1. **[Step 1 title]**
   [Detailed description of what Claude should do in this step]

2. **[Step 2 title]**
   [Detailed description]

3. **[Step 3 title]**
   [Detailed description]

## Output
[Describe the result — list files created or modified]

## Example
/[command-name] example-arg

Expected output:
- [File 1 created at path]
- [File 2 created at path]
```

---

## Commands vs Skills — When to Use Which

Both commands and skills define reusable workflows. The difference is complexity and features.

| | Commands | Skills |
|---|---|---|
| **Location** | `.claude/commands/*.md` | `.claude/skills/<name>/SKILL.md` |
| **Frontmatter** | No | Yes (role, tools, triggers) |
| **Supporting files** | No | Yes (can include templates, schemas) |
| **Auto-invocation** | No | Yes (via `triggers` field) |
| **Best for** | Simple, one-off workflows | Complex workflows with persona or tooling |

**Use a command when:**
- The workflow is 5-15 steps and fits in a single file
- You do not need a specific role or persona for Claude
- There are no supporting assets (templates, schemas) to bundle

**Use a skill when:**
- The workflow needs a `role` field to give Claude a specific persona
- You need to auto-invoke it based on a pattern (e.g., when a file matching a glob is modified)
- There are supporting files that the workflow references
- The command file would exceed ~50 lines

---

## Tips for Writing Effective Commands

- **Reference specific files.** "Read `src/modules/auth/auth.module.ts` to learn the module pattern" is more useful than "look at the existing modules".
- **List exact output.** Name the files Claude will create or modify so the user knows what to expect.
- **Keep steps ordered.** Number each step and keep each step to a single concrete action.
- **Keep files short.** If a command exceeds 50 lines, move it to `.claude/skills/` where it can have supporting files.
- **Test with a real example.** Run the command once on a real input to verify the output matches expectations before sharing with the team.

---

## See a Real-World Example

[example-create-module.md](./example-create-module.md)

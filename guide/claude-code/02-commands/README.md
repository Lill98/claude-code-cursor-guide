# Template: Claude Code Command

Commands are slash commands (`/command-name`) in Claude Code. When the user types a command, Claude executes the workflow defined in the `.md` file.

---

## How to Create a Command

1. Create a file at `.claude/commands/command-name.md`
2. Write the content using the template below
3. Use it by typing `/command-name [arguments]` in Claude Code

---

## Special Syntax

| Placeholder | Meaning |
|-------------|---------|
| `$ARGUMENTS` | All text after the command name |
| `$ARGUMENTS` in action | Example: `/create-module auth` → `$ARGUMENTS = "auth"` |

---

## TEMPLATE

```markdown
# [Command Name]

## Purpose
[Brief description of what this command does — 1-2 sentences]

## Usage
```
/[command-name] [argument-description]
```

## Arguments
- `$ARGUMENTS`: [Describe the argument — e.g., "name of the module to create"]

## Steps

1. **[Step 1 title]**
   [Detailed description of what Claude should do]

2. **[Step 2 title]**
   [Detailed description]

3. **[Step 3 title]**
   [Detailed description]

## Output
[Describe the result Claude will produce]

## Example
```
/[command-name] example-arg
```
Expected output:
- [File 1 created]
- [File 2 created]
```

---

## Tips for Writing Commands

- **Be specific about steps** — "Read file X to learn the pattern" is better than "learn the codebase"
- **Reference real files** — Tell Claude exactly which files to read to learn patterns
- **Clear output** — List the exact files that will be created/modified
- **Don't make it too long** — If a command exceeds 50 lines, consider making it a skill instead
- **Test it** — Try the command with a real example and verify the output

---

## See a Real-World Example

→ [example-create-module.md](./example-create-module.md)

# Claude Code Skills

Skills extend what Claude can do. Store a `SKILL.md` file in `.claude/skills/<name>/` (project-scoped) or `~/.claude/skills/<name>/` (personal), and Claude automatically adds it to its toolkit. Invoke directly with `/skill-name` or let Claude auto-invoke when it detects a match against the skill description.

> **Note:** The legacy `.claude/commands/*.md` format still works (backward compatible). Skills are the recommended format because they support frontmatter, supporting files, and auto-invocation by description.

---

## Bundled Skills (available in every session, no setup needed)

Claude Code ships with built-in skills you can invoke immediately:

| Skill | Usage | Purpose |
|-------|-------|---------|
| `/simplify` | `/simplify` | Review changed code for reuse, quality, and efficiency — fix issues found |
| `/debug` | `/debug [error]` | Systematic debugging workflow |
| `/batch` | `/batch [task]` | Run a task across multiple files in parallel |
| `/loop` | `/loop [interval] [task]` | Repeat a task on a recurring schedule |
| `/claude-api` | `/claude-api` | Build, debug, and optimize Anthropic SDK integrations |

These built-in commands are also accessible via the Skill tool:

| Command | Purpose |
|---------|---------|
| `/init` | Generate a `CLAUDE.md` from the current codebase |
| `/review` | Review a pull request |
| `/security-review` | Security review of changes on the current branch |

---

## Skills vs Commands

| | Command (`.claude/commands/`) | Skill (`.claude/skills/<name>/`) |
|--|-------------------------------|----------------------------------|
| Format | Single `.md` file | Directory with `SKILL.md` + optional supporting files |
| Frontmatter | Supported | Supported (recommended) |
| Auto-invocation by Claude | No | Yes — Claude reads `description` and invokes when relevant |
| Supporting files | No | Yes — templates, examples, scripts |
| Status | Still works | Recommended for new work |

If both a command and a skill share the same name, the skill takes priority.

---

## Directory Structure

```
.claude/skills/
└── write-test/
    ├── SKILL.md           # Main instructions (required)
    ├── examples/
    │   └── sample.spec.ts # Example output
    └── scripts/
        └── validate.sh    # Optional helper script

~/.claude/skills/          # Personal skills (apply to all projects)
```

### Locations and Priority

| Location | Path | Scope |
|----------|------|-------|
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project only |

Priority: personal > project. If the same name exists in both, personal wins.

---

## SKILL.md Format

Each skill needs a `SKILL.md` with YAML frontmatter followed by markdown instructions:

```markdown
---
name: skill-name
description: What this skill does and when to use it. Claude uses this field to decide when to invoke automatically.
disable-model-invocation: false
allowed-tools: Read Grep
---

# Skill instructions here

$ARGUMENTS is the input passed when invoked.
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Slash-command name (defaults to directory name) |
| `description` | Recommended | Claude uses this to decide when to auto-invoke. Front-load the key use case. Truncated at 1,536 chars. |
| `when_to_use` | No | Additional trigger phrases, appended to `description` |
| `argument-hint` | No | Shown in autocomplete, e.g. `[file-path]` or `[module-name] [type]` |
| `disable-model-invocation` | No | `true` = only you can invoke (Claude will not auto-trigger). Use for deploy, commit, or side-effect workflows. |
| `user-invocable` | No | `false` = hidden from `/` menu; Claude auto-invokes only. Use for background reference knowledge. |
| `allowed-tools` | No | Tools Claude can use without asking permission while this skill is active. E.g. `Bash(git *) Read Grep` |
| `model` | No | Override the model for this skill |
| `effort` | No | Override effort level: `low`, `medium`, `high`, `max` |
| `context` | No | `fork` = run in an isolated subagent |
| `agent` | No | Subagent type when `context: fork`: `Explore`, `Plan`, `general-purpose`, or a custom subagent name |
| `paths` | No | Glob patterns — skill only activates when working with matching files, e.g. `**/*.spec.ts` |

### Argument Substitutions

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | Full argument string after the skill name |
| `$ARGUMENTS[0]` or `$0` | First argument (0-based index) |
| `$ARGUMENTS[1]` or `$1` | Second argument |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Directory containing this `SKILL.md` |

Example: `/migrate-component SearchBar React Vue` → `$0=SearchBar`, `$1=React`, `$2=Vue`

---

## Invocation Control

| Frontmatter | User can invoke | Claude auto-invokes |
|-------------|-----------------|---------------------|
| (default) | Yes | Yes — when description matches |
| `disable-model-invocation: true` | Yes | No |
| `user-invocable: false` | No | Yes — when description matches |

**When to use `disable-model-invocation: true`:** `/deploy`, `/commit`, `/send-email`, `/spec-to-tests` — workflows with side effects or where you want to control timing.

**When to use `user-invocable: false`:** Background knowledge like `legacy-system-context` — Claude should know when relevant but it is not an action the user invokes directly.

---

## Template

```markdown
---
name: [skill-name]
description: [What this skill does. Be specific — Claude uses this text to decide when to invoke. Example: "Use when writing pytest unit tests for FastAPI services in blog-api"]
disable-model-invocation: false
---

# [Skill Name]

## Role
You are a [specific expert role]. You have expertise in [domain] and deep understanding of [context].

## Context
[Project-specific context Claude needs — tech stack, conventions, patterns]

## Input
$ARGUMENTS is [describe input — e.g., "the path to the service file that needs tests"]

## Task
[Describe the overall task — 1-2 sentences]

## Steps

1. **[Step 1]**
   [Detailed description of what Claude should do]

2. **[Step 2]**
   [Detailed description]

3. **[Step 3]**
   [Detailed description]

## Output Format
[Describe the exact output format — include examples (few-shot) where possible]

## Quality Checklist
Before finishing, verify:
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Example

Input: `/[skill-name] example-arg`

Expected output:
\`\`\`
[Example output]
\`\`\`
```

---

## Tips

- **Description is the key** — Write it so Claude knows when to auto-invoke. "Use when writing Vitest tests for NestJS services" is better than just "write-test".
- **Strong persona** — "Senior NestJS engineer with 5 years RBAC experience" produces better output than "engineer".
- **`disable-model-invocation: true`** for anything with side effects you want to control.
- **Keep SKILL.md under 500 lines** — Move detailed reference material into supporting files in the same directory.
- **`$0`, `$1` for positional args** — `/migrate-component SearchBar React Vue` gives `$0=SearchBar`, `$1=React`, `$2=Vue`.
- **Supporting files** — Place templates, examples, and scripts in the same directory and reference them from SKILL.md.

---

## See a Real-World Example

→ [example-write-test.md](./example-write-test.md)

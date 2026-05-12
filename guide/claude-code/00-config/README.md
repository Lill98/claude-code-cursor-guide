# Configuration Hierarchy

Read this section first. Understanding the config layers helps you place files in the right location and avoid confusion when working in a team.

---

## Overview: 4 Config Layers

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 0 — MANAGED / ORG-WIDE                               │
│  /etc/claude-code/CLAUDE.md  (Linux)                        │
│  /Library/Application Support/ClaudeCode/CLAUDE.md (macOS)  │
│  Set by IT/DevOps — overrides everything, applies to all    │
└──────────────────────────┬──────────────────────────────────┘
                           │ overrides
┌──────────────────────────▼──────────────────────────────────┐
│  LAYER 1 — GLOBAL / PERSONAL                                 │
│  ~/.claude/                                                  │
│  ~/.claude.json                                              │
│  Personal — applies to all your projects, never push to git │
└──────────────────────────┬──────────────────────────────────┘
                           │ overrides
┌──────────────────────────▼──────────────────────────────────┐
│  LAYER 2 — PROJECT / TEAM                                    │
│  [project-root]/CLAUDE.md                                   │
│  [project-root]/.claude/                                    │
│  Shared by the whole team — commit to git                   │
└──────────────────────────┬──────────────────────────────────┘
                           │ extends
┌──────────────────────────▼──────────────────────────────────┐
│  LAYER 3 — DIRECTORY-LEVEL                                   │
│  src/auth/CLAUDE.md                                         │
│  src/payments/CLAUDE.md                                     │
│  Loaded on-demand when working inside that folder           │
└─────────────────────────────────────────────────────────────┘
```

---

## Layer Details

### Layer 0 — Managed / Org-wide

| OS | Path |
|----|------|
| macOS | `/Library/Application Support/ClaudeCode/CLAUDE.md` |
| Linux | `/etc/claude-code/CLAUDE.md` |
| Windows | `C:\Program Files\ClaudeCode\CLAUDE.md` |

For IT, DevOps, or Tech Leads who need to enforce rules across the entire organization that no individual can override.

Example content:
```markdown
## Company Rules (enforced)
- Never commit secrets or API keys
- All PRs must have test coverage
- Use company Jira for ticket references
```

---

### Layer 1 — Global / Personal

```
~/.claude/
├── CLAUDE.md              # Rules that apply to all your projects
├── settings.json          # Personal hooks, preferences
├── skills/<name>/         # Personal skills (win over project skills if name conflicts)
│   └── SKILL.md
└── commands/<name>.md     # Personal commands (legacy format)

~/.claude.json             # MCP server config (separate file)
```

For personal preferences — your coding style, personal workflows, tools you use across every project.

Example `~/.claude/CLAUDE.md`:
```markdown
## My Personal Rules
- Always write tests before implementation
- Prefer functional patterns over class-based
- Use conventional commits format
```

---

### Layer 2 — Project / Team

```
[project-root]/
├── CLAUDE.md                    # Project rules (commit to git)
├── CLAUDE.local.md              # Your local override (gitignore)
└── .claude/
    ├── settings.json            # Team hooks, permissions (commit)
    ├── settings.local.json      # Local override (gitignore)
    ├── skills/<name>/SKILL.md   # Team skills (commit)
    ├── commands/<name>.md       # Team commands, legacy format (commit)
    ├── hooks/                   # Hook scripts (commit)
    │   ├── lint-fix.sh
    │   └── run-tests.sh
    └── rules/                   # Path-scoped rules (commit) — see below
        ├── api.md
        └── testing.md
```

For rules and workflows the whole team must follow — project conventions, code standards, quality gates.

---

### Layer 3 — Directory-level

```
[project-root]/
└── src/
    ├── CLAUDE.md          # Loaded when working in src/ and subdirectories
    ├── auth/
    │   └── CLAUDE.md      # Loaded when working in src/auth/
    └── payments/
        └── CLAUDE.md      # Loaded when working in src/payments/
```

For module-specific rules — domain logic details and patterns that are only relevant when working inside that folder.

Benefit: the root CLAUDE.md stays short. Details live exactly where they are relevant and only consume tokens when needed.

---

## Git Ownership

| File / Folder | Push to git? | Owner | Notes |
|---------------|:---:|-------|-------|
| `~/.claude/CLAUDE.md` | Never | Personal | Personal rules |
| `~/.claude/settings.json` | Never | Personal | Personal hooks |
| `~/.claude/skills/` | Never | Personal | Personal skills |
| `~/.claude.json` | Never | Personal | MCP config |
| `CLAUDE.md` (project root) | Yes | Team | Rules everyone follows |
| `CLAUDE.local.md` | Gitignore | Personal | Local rule override |
| `src/*/CLAUDE.md` | Yes | Team | Module-level rules |
| `.claude/settings.json` | Yes | Team | Team hooks |
| `.claude/settings.local.json` | Gitignore | Personal | Local permission override |
| `.claude/skills/` | Yes | Team | Team skills |
| `.claude/commands/` | Yes | Team | Team commands |
| `.claude/hooks/` | Yes | Team | Hook scripts |
| `.claude/rules/` | Yes | Team | Path-scoped rules |
| `/etc/claude-code/CLAUDE.md` | N/A | Company | Managed policy |

---

## Override and Precedence Rules

### CLAUDE.md — Stacking (additive, not overwriting)

All CLAUDE.md files are loaded and **stacked** in order from global to local:

```
~/.claude/CLAUDE.md          (1st — global personal)
  +
/etc/claude-code/CLAUDE.md   (2nd — managed org)
  +
[project]/CLAUDE.md          (3rd — project team)
  +
[project]/CLAUDE.local.md    (4th — local personal)
  +
[project]/src/auth/CLAUDE.md (5th — loaded on demand)
```

If there is a conflict (rule A says use Zod, rule B says use class-validator), the rule loaded later takes priority. Avoid conflicts by design — keep each layer focused on its own scope.

### Skills — Personal wins

If `~/.claude/skills/write-test/` and `.claude/skills/write-test/` both exist, the personal version wins.

### settings.json — Merge

`settings.local.json` merges with `settings.json`. Local wins on any conflicting key.

### MCP — Global only

`~/.claude.json` is the only location for MCP config. There is no project-level MCP config file.

---

## CLAUDE.local.md vs settings.local.json

These two files are easy to mix up:

| | `CLAUDE.local.md` | `.claude/settings.local.json` |
|--|---|---|
| **Overrides** | Rules and instructions for Claude | Permissions and hooks config |
| **Example** | "Always use tabs, not spaces" | Allow `Bash(npm run deploy)` |
| **Gitignore** | Yes — always gitignore | Yes — always gitignore |
| **Use when** | You need a personal rule you don't want the team to see | You need local permissions (API keys, local tools) |

---

## .claude/rules/ — Path-scoped Rules

Rules that only load when Claude is working with files matching a glob pattern.

```
.claude/rules/
├── api.md           # Only loads when editing src/api/**
├── testing.md       # Only loads when editing **/*.spec.ts
└── database.md      # Only loads when editing **/*.prisma
```

Format:
```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Rules
- All endpoints must have input validation
- Use standard error response format: { error, code, message }
- Never expose internal error details to client
```

Benefit: the root CLAUDE.md stays short (around 50 lines). Technical details live in rules files and only load when relevant — significant token savings over time.

---

## @import Syntax — Keep CLAUDE.md Short

From CLAUDE.md you can import other files instead of copying their content inline:

```markdown
# CLAUDE.md
See @README.md for project overview and @package.json for available scripts.

## Workflows
- Git conventions: @docs/git-workflow.md
- API standards: @docs/api-standards.md
- Personal preferences: @~/.claude/my-project-notes.md
```

Claude reads the imported file before responding. Use this for existing docs in the repo — no duplication needed.

---

## Auto Memory — A Second Memory System

In addition to CLAUDE.md (which you write), Claude Code has **auto memory** — Claude writes notes to itself:

```
~/.claude/projects/<project-hash>/memory/
├── MEMORY.md              # Index — loaded at the start of every session (max 200 lines)
├── debugging.md           # Claude writes here when it finds a bug pattern
├── api-conventions.md     # Claude writes here when it learns a convention
└── user-preferences.md    # Claude writes here when it learns your preferences
```

How it works:
- `MEMORY.md` loads automatically at session start
- Topic files load on-demand when relevant
- Claude decides what to write (corrections, insights, patterns it has learned)
- Machine-local — does not sync to the cloud

View what memory is currently loaded: type `/memory` in Claude Code.

Disable auto memory: set `autoMemoryEnabled: false` in settings.json.

---

## .gitignore Template

Add to your project `.gitignore`:

```gitignore
# Claude Code — local overrides (never commit)
.claude/settings.local.json
CLAUDE.local.md

# Personal session notes
claude-session-notes.md
```

---

## Pattern: Company Template Repo

This repo is an example of this pattern. How a company can organize it:

```
[company]/ai-tools-handbook/    <- This repo
├── guide/                      # Documentation
├── .claude/                    # Working demo config
│   ├── settings.json           # Team hooks template
│   ├── skills/                 # Team skill templates
│   └── hooks/                  # Hook script templates
└── CLAUDE.md                   # Repo rules template

# Each project team copies and customizes:
[project]/.claude/    <- copy from template, adjust for the project
[project]/CLAUDE.md   <- copy from template, adjust for the domain
```

---

## See Also

- [01-rules/](../01-rules/README.md) — CLAUDE.md content and .claude/rules/ path-scoped rules
- [06-mcp/](../06-mcp/README.md) — Configuring `~/.claude.json`

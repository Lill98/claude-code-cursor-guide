# Cursor: Rules & Skills

This document explains how to customize Cursor's AI agent with persistent project context and expert workflows, with practical examples from the **saafehouse-be** project (NestJS + Prisma + RBAC + multi-tenant).

---

## Overview

Cursor has 2 core customization mechanisms:

| Type | File/Location | Triggered When | Used For |
|------|--------------|----------------|----------|
| **Rules** | `.cursor/rules/*.mdc` | Automatically when matching files are open (or always) | Defining project conventions, patterns, constraints |
| **Skills** | `.cursor/skills/*/SKILL.md` | Automatically when the agent detects a relevant task | Expert workflows with detailed instructions |

### What About Commands and Hooks?

Cursor does not have equivalents to Claude Code's **Commands** (slash commands) or **Hooks** (auto-run shell scripts). However:

- **Commands** can be approximated by writing a Skill with step-by-step workflow instructions
- **Hooks** can be partially replaced by IDE-level settings (e.g., format on save, ESLint integration)

---

## How Rules Work in Cursor

Rules are `.mdc` (Markdown with Config) files in `.cursor/rules/`. Each file has YAML frontmatter that controls when it applies:

```
.cursor/rules/
├── project-context.mdc       # Always applies — stack, architecture
├── nestjs-patterns.mdc       # Applies to *.ts files
├── prisma-conventions.mdc    # Applies to *.ts files
└── testing.mdc               # Applies to *.spec.ts files
```

### Three Rule Scoping Modes

| Mode | Frontmatter | When It Applies |
|------|-------------|-----------------|
| **Always** | `alwaysApply: true` | Every conversation, regardless of files open |
| **File-scoped** | `globs: **/*.ts` | Only when matching files are open or being edited |
| **Manual** | `alwaysApply: false`, no globs | Only when explicitly referenced by the user |

This is more granular than Claude Code's single `CLAUDE.md` file — you can split your project conventions into focused, file-type-specific rules.

---

## How Skills Work in Cursor

Skills are directories containing a `SKILL.md` file in `.cursor/skills/` (project-level) or `~/.cursor/skills/` (personal, cross-project):

```
.cursor/skills/
└── write-test/
    ├── SKILL.md              # Required — main instructions
    ├── reference.md          # Optional — detailed docs
    └── examples.md           # Optional — usage examples
```

Skills have YAML frontmatter with `name` and `description` fields. The description is critical — Cursor uses it to decide when to automatically apply the skill.

---

## Recommended Reading Order

1. [Rules](./01-rules/README.md) — Start here, every project benefits from rules
2. [Skills](./02-skills/README.md) — When you need expert-level workflows

---

## Quick Start for saafehouse-be

```bash
# 1. Create the rules directory
mkdir -p .cursor/rules

# 2. Copy the example rules (split into focused .mdc files)
# See: guide/cursor/01-rules/example-saafehouse.md for all rule files

# 3. Create the skills directory
mkdir -p .cursor/skills/write-test

# 4. Copy the write-test skill
# See: guide/cursor/02-skills/example-write-test.md for the SKILL.md content
```

---

## Directory Structure in Your Project

```
your-project/
├── .cursor/
│   ├── rules/                    # Project rules
│   │   ├── project-context.mdc   # Stack, architecture (always active)
│   │   ├── nestjs-patterns.mdc   # NestJS conventions (*.ts files)
│   │   ├── prisma-conventions.mdc# Prisma patterns (*.ts files)
│   │   └── testing.mdc           # Test patterns (*.spec.ts files)
│   └── skills/                   # Project skills
│       └── write-test/
│           └── SKILL.md          # Test generation skill
└── ...
```

# Cursor: Rules, Skills, TDD Workflow

This document explains how to customize Cursor's AI agent with persistent project context and expert workflows, with practical examples for a NestJS + Prisma project.

---

## Overview

Cursor has 5 core customization mechanisms:

| Type | File/Location | Triggered When | Used For |
|------|--------------|----------------|----------|
| **Rules** | `.cursor/rules/*.md` | Automatically (always, glob, intelligently) or `@rule-name` | Defining project conventions, patterns, constraints |
| **Skills** | `.agents/skills/*/SKILL.md` | Auto-detected or `/skill-name` | Single-purpose expert workflows |
| **Subagents** | `.cursor/agents/*.md` | Auto-delegated or `/name` | Multi-step specialized tasks with own context window |
| **Hooks** | `.cursor/hooks.json` | Automatically before/after agent actions | Enforcing quality gates automatically |
| **TDD Workflow** | `spec-to-tests` skill + `stop` hook + Husky | Auto-detected + `stop` event + every `git commit` | Generate test stubs from spec; run tests before commit |

### What About Commands?

Cursor does not have custom slash commands equivalent to Claude Code's `/command-name` system. Both **Skills** (`/skill-name`) and **Subagents** (`/name`) support explicit slash-style invocation, but they are primarily driven by the agent's automatic delegation based on `description`.

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
2. [Skills](./02-skills/README.md) — When you need single-purpose expert workflows
3. [Subagents](./05-subagents/README.md) — When you need multi-step specialized agents
4. [Hooks](./04-hooks/README.md) — When you want automation after agent actions
5. [TDD Workflow](./03-tdd/README.md) — When you want to write tests in parallel with code

---

## Quick Start

```bash
# 1. Create the rules directory
mkdir -p .cursor/rules

# 2. Copy the example rules (split into focused .mdc files)
# See: guide/cursor/01-rules/README.md for all rule templates

# 3. Create the skills directory
mkdir -p .agents/skills/write-test
mkdir -p .agents/skills/spec-to-tests
mkdir -p .agents/skills/research-ticket

# 4. Copy skills (SKILL.md content from each guide section)
# write-test:      guide/cursor/02-skills/example-write-test.md
# spec-to-tests:   guide/cursor/03-tdd/README.md
# research-ticket: .agents/skills/research-ticket/SKILL.md (live example in this repo)

# 5. Set up Husky pre-commit hook (blocks commits on test failure)
npm install --save-dev husky
npx husky init
echo "npx vitest --run" > .husky/pre-commit

# 6. Set up MCP (optional — needed for /research-ticket skill)
# If already set up for Claude Code: copy the same config to ~/.cursor/mcp.json
# Fresh setup: see setup/cursor-mcp.md
```

---

## Directory Structure in Your Project

```
your-project/
├── .agents/
│   └── skills/                   # Project skills (preferred location)
│       ├── write-test/
│       │   └── SKILL.md          # Test generation skill
│       └── spec-to-tests/
│           └── SKILL.md          # TDD workflow: spec → test stubs
├── .cursor/
│   ├── rules/                    # Project rules
│   │   ├── project-context.md    # Stack, architecture (always active)
│   │   ├── nestjs-patterns.md    # NestJS conventions (*.ts files)
│   │   ├── prisma-conventions.md # Prisma patterns (*.ts files)
│   │   └── testing.md            # Test patterns (*.spec.ts files)
│   ├── agents/                   # Custom subagents
│   │   ├── verifier.md           # Validates implementations
│   │   └── test-runner.md        # Runs tests until green
│   └── hooks/                    # Hook scripts
│       ├── hooks.json            # Hook configuration
│       ├── prettier-fix.sh       # Format on file edit
│       ├── lint-fix.sh           # Lint on file edit
│       └── run-tests.sh          # Run tests on agent stop
├── .husky/
│   └── pre-commit                # Blocks commit if tests fail
└── ...
```

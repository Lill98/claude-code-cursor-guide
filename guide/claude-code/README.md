# Claude Code Customization Guide

A complete guide to extending and automating Claude Code with Rules, Commands, Hooks, Skills, Subagents, MCP, TDD, and advanced tips. All examples use a **blog-api** project (FastAPI + SQLAlchemy + PostgreSQL + pytest).

---

## Overview

| # | Type | Location | Triggered When | Used For |
|---|------|----------|----------------|----------|
| 00 | **Config** | `CLAUDE.md`, `~/.claude/`, `.claude/` | At startup / session init | Setting up layers, file placement, git ownership |
| 01 | **Rules** | `CLAUDE.md` at project root | Every time Claude starts a task | Defining project conventions, stack, and fixed context |
| 02 | **Commands** | `.claude/commands/*.md` | User types `/command-name` | Repeatable, parameterized workflows |
| 03 | **Hooks** | `.claude/settings.json` → `hooks` | Automatically before/after tool calls | Enforcing quality gates without reminders |
| 04 | **Skills** | `.claude/skills/<name>/SKILL.md` | User types `/skill-name` or Claude auto-invokes | Expert workflows; Claude loads automatically when relevant |
| 05 | **Subagents** | Invoked by Claude internally | Claude decides to delegate a subtask | Parallel execution, long-running tasks, isolation |
| 06 | **MCP** | `~/.claude.json` → `mcpServers` | Claude calls an external tool | Connecting Jira, Confluence, databases, APIs |
| 07 | **TDD** | `.claude/skills/spec-to-tests/SKILL.md` + Stop hook | `/spec-to-tests` + Stop event | Generate test stubs from spec, run tests automatically |
| 08 | **Tips** | N/A (patterns and mental models) | Reference when debugging or optimizing | Token savings, context window, prompt discipline |

---

## Learning Path

### Level 1 — Basic (start here)

Cover these three sections first. They apply to every project and give you immediate, tangible value.

| Section | What you learn | Outcome |
|---------|---------------|---------|
| **01-rules** | How to write an effective CLAUDE.md | Claude always knows your stack and conventions without being told |
| **02-commands** | How to turn a repeated workflow into a slash command | `/create-module auth` generates a complete NestJS module in your style |
| **03-hooks** | How to trigger scripts automatically on tool events | ESLint and Prettier run after every file edit — no reminders needed |

At the end of Level 1, Claude behaves like a developer who already knows your project. It follows your conventions and enforces quality gates by itself.

### Level 2 — Intermediate

Add power once the basics are solid.

| Section | What you learn | Outcome |
|---------|---------------|---------|
| **04-skills** | Built-in skills + writing custom expert workflows | `/review-pr` checks against your RBAC + Zod + coverage checklist; Claude auto-invokes when relevant |
| **05-subagents** | How Claude delegates subtasks to parallel agents | Long research or multi-file generation runs faster without blocking |
| **06-mcp** | Connecting external tools via Model Context Protocol | Claude reads your Jira ticket and Confluence page directly during a task |

At the end of Level 2, Claude can pull live context from your tools and run complex multi-step workflows without manual coordination.

### Level 3 — Advanced

For teams who want full automation and discipline.

| Section | What you learn | Outcome |
|---------|---------------|---------|
| **07-tdd** | Spec-to-tests workflow, Stop hook for test runs | Tests are generated from acceptance criteria and run automatically after every task |
| **08-tips** | How Claude reads context, token budgets, prompt patterns | You write leaner prompts, avoid context window waste, and debug Claude behavior reliably |

At the end of Level 3, the entire development loop — spec, tests, implementation, lint, quality gates — is automated and reproducible.

---

## When to Use Each

### Rules (CLAUDE.md)
Use when you want Claude to **always know** your project context without being reminded. Good for stack conventions, naming patterns, anti-patterns, and team-wide standards.

Example: "Always use Zod for validation, never class-validator. Service files are in `src/modules/<name>/<name>.service.ts`."

### Commands
Use when you have a **repeatable, multi-step workflow with variable input**. Commands are prompt templates that accept arguments.

Example: `/create-module auth` — Claude generates controller, service, DTO, and spec file following your project structure.

### Hooks
Use when you want **automated quality checks at the tool-call level** — not dependent on Claude remembering, but enforced by the harness itself.

Example: After every file write → ESLint runs. After every Claude session ends → unit tests run.

### Skills
Use when a workflow is complex enough to need **dedicated prompt engineering** — roles, few-shot examples, structured output. Also use for built-in skills shipped with Claude Code.

Built-in skills available immediately: `/simplify`, `/debug`, `/batch`, `/loop`, `/claude-api`, `/init`, `/review`, `/security-review`

Example: `/review-pr` — Claude reviews diffs against an RBAC + Zod + test coverage checklist specific to your project.

### Subagents
Use when Claude needs to **run multiple independent tasks in parallel** or delegate long-running work without blocking the main conversation.

Example: Claude spawns one subagent to read all spec files while another reads the existing service implementation — then combines results.

### MCP
Use when Claude needs **live data from external systems** — Jira tickets, Confluence docs, database schemas, third-party APIs.

Example: `/research-ticket SH-164` — Claude fetches the ticket, linked Confluence pages, and writes a structured implementation spec.

### TDD Workflow
Use when you have a spec and want tests **written before or alongside implementation** — red tests first, then implementation makes them green.

Example: `/spec-to-tests specs/SH-164.md src/modules/invitation/invitation.service.spec.ts` — generates `it.todo()` stubs from acceptance criteria.

### Tips
Read when you want to understand **why Claude behaves a certain way** — how context windows work, when to compact, how to write prompts that survive long sessions.

---

## Directory Structure

```
.claude/
├── settings.json              # Hooks config, permissions (commit to git)
├── settings.local.json        # Local overrides — gitignore this
├── hooks/
│   ├── lint-fix.sh            # Pre-tool or post-tool hook script
│   └── run-tests.sh           # Stop hook: runs tests after every session
├── commands/                  # Legacy command format — still works
│   └── create-module.md
├── skills/                    # Recommended format
│   ├── write-test/
│   │   └── SKILL.md
│   ├── review-pr/
│   │   └── SKILL.md
│   └── spec-to-tests/
│       └── SKILL.md           # TDD workflow skill
└── rules/                     # Path-scoped rules (load only when relevant)
    ├── api.md                 # Loaded when editing src/api/**
    └── testing.md             # Loaded when editing *.spec.ts

~/.claude/skills/              # Personal skills — apply to all projects
~/.claude.json                 # MCP server config

CLAUDE.md                      # Project rules — commit to git
CLAUDE.local.md                # Local rule override — gitignore this
```

---

## Quick Start

```bash
# 1. Copy project rules template
cp guide/claude-code/01-rules/example-blog.md CLAUDE.md

# 2. Create config directories
mkdir -p .claude/commands .claude/hooks .claude/skills .claude/rules

# 3. Copy a command (legacy format)
cp guide/claude-code/02-commands/example-create-module.md .claude/commands/create-module.md

# 4. Set up a skill (new format)
mkdir -p .claude/skills/write-test
# Copy content from guide/claude-code/04-skills/example-write-test.md
# into .claude/skills/write-test/SKILL.md

# 5. Set up the TDD skill
mkdir -p .claude/skills/spec-to-tests
# Copy the spec-to-tests skill template from guide/claude-code/07-tdd/README.md
# into .claude/skills/spec-to-tests/SKILL.md

# 6. Set up hooks
# See guide/claude-code/03-hooks/example-blog.md for ruff/black/isort/pytest hooks
# See guide/claude-code/07-tdd/README.md for run-tests.sh and Stop hook config

# 7. Gitignore local overrides
echo '.claude/settings.local.json' >> .gitignore
echo 'CLAUDE.local.md' >> .gitignore
```

---

## Guide Sections

| Section | README | What it covers |
|---------|--------|----------------|
| 00-config | [README](./00-config/README.md) | Config layers, git ownership, override rules, path-scoped rules, auto memory |
| 01-rules | [README](./01-rules/README.md) | CLAUDE.md structure, what to include, example for FastAPI project |
| 02-commands | [README](./02-commands/README.md) | Command format, parameters, create-module example |
| 03-hooks | [README](./03-hooks/README.md) | Hook events (10+), stdin JSON format, env vars, lint + test examples |
| 04-skills | [README](./04-skills/README.md) | Built-in skills, SKILL.md format, frontmatter fields, auto-invoke |
| 05-subagents | [README](./05-subagents/README.md) | How subagents work, when to use, limitations |
| 06-mcp | [README](./06-mcp/README.md) | MCP setup, Atlassian integration, research-ticket workflow |
| 07-tdd | [README](./07-tdd/README.md) | Spec-to-tests skill, Stop hook, red-green-refactor loop |
| 08-tips | [README](./08-tips/README.md) | Context window, token optimization, prompt patterns, debugging Claude |

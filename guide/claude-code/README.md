# Claude Code: Rules, Commands, Hooks, Skills, TDD Workflow

This document explains the 5 core mechanisms for customizing and extending Claude Code, with practical examples from the **saafehouse-be** project (NestJS + Prisma + RBAC + multi-tenant).

---

## Overview of the 5 Types

| Type | File/Location | Triggered When | Used For |
|------|--------------|----------------|----------|
| **Rules** | `CLAUDE.md` at root | Every time Claude starts a task | Defining project conventions and fixed context |
| **Commands** | `.claude/commands/*.md` | User types `/command-name` | Repeatable workflows, can be parameterized |
| **Hooks** | `.claude/settings.json` → `hooks` | Automatically before/after tool calls | Enforcing quality gates automatically |
| **Skills** | `.claude/commands/*.md` (complex prompt) | User types `/skill-name` | Specific expertise with detailed prompt engineering |
| **TDD Workflow** | `.claude/commands/spec-to-tests.md` + `.claude/hooks/run-tests.sh` | `/spec-to-tests` + Stop event | Generate test stubs from spec in parallel with implementation |

---

## When to Use Each

### Rules (CLAUDE.md) — Use when:
- You want Claude to **always know** your project context (stack, conventions) without reminding it
- You have patterns or anti-patterns that need consistent enforcement
- Example: "Always use Zod validation, never use class-validator"

### Commands — Use when:
- You have a repeatable, multi-step workflow with **variable input**
- You want to standardize how modules are created, tests are written, etc.
- Example: `/create-module auth` → Claude creates a complete controller/service/dto following your standards

### Hooks — Use when:
- You want to **automate** quality checks without reminding Claude
- You want to enforce rules at the tool execution level (not dependent on Claude remembering)
- Example: After every file edit by Claude → ESLint runs automatically

### Skills — Use when:
- The workflow is complex and needs **detailed prompt engineering** with roles and few-shot examples
- You want Claude to act as an "expert" in a specific domain
- Example: `/review-pr` → Claude reviews code against an RBAC + Zod + test coverage checklist

### TDD Workflow — Use when:
- You have a spec and want to write tests **before or alongside** the implementation
- You want tests to be red from the start and guide implementation, not confirm it after the fact
- You want test results surfaced automatically after every Claude task and enforced at commit time
- Example: `/spec-to-tests examples/specs/SH-164.md src/modules/invitation/invitation.service.spec.ts` → generates `it.todo()` stubs from acceptance criteria

---

## Directory Structure

```
.claude/
├── settings.json          # Hooks configuration
├── hooks/
│   └── run-tests.sh       # Unit test runner (Stop hook)
└── commands/
    ├── create-module.md   # /create-module command
    ├── write-test.md      # /write-test skill
    ├── review-pr.md       # /review-pr skill
    └── spec-to-tests.md   # /spec-to-tests skill (TDD workflow)

CLAUDE.md                  # Rules (placed at project root)
```

---

## Recommended Reading Order

1. [Rules](./01-rules/README.md) — Start here, every project needs this
2. [Commands](./02-commands/README.md) — When you have workflows to reuse
3. [Hooks](./03-hooks/README.md) — When you want automation
4. [Skills](./04-skills/README.md) — When you need advanced prompt engineering
5. [TDD Workflow](./05-tdd/README.md) — When you want to write tests in parallel with code

---

## Quick Start for saafehouse-be

```bash
# 1. Copy CLAUDE.md to the project root
cp guide/claude-code/01-rules/example-saafehouse.md CLAUDE.md

# 2. Create the commands and hooks directories
mkdir -p .claude/commands .claude/hooks

# 3. Copy commands
cp guide/claude-code/02-commands/example-create-module.md .claude/commands/create-module.md
cp guide/claude-code/04-skills/example-write-test.md .claude/commands/write-test.md

# 4. Set up the TDD workflow skill
# Copy the spec-to-tests skill template from guide/claude-code/05-tdd/README.md
# into .claude/commands/spec-to-tests.md

# 5. Set up hooks (ESLint, Prettier, test runner)
# See: guide/claude-code/03-hooks/example-saafehouse.md
# See: guide/claude-code/05-tdd/README.md (run-tests.sh + Stop hook config)
```

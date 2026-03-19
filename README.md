# AI Tools Handbook — Claude Code & Cursor

A practical guide to customizing and extending **Claude Code** and **Cursor** — two AI-powered coding tools. Learn how to use Rules, Commands, Hooks, and Skills to make AI assistants work effectively in your projects.

## What Are These Tools?

- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** is an agentic coding tool from Anthropic that runs in your terminal and IDE. It reads your codebase, edits files, runs commands, and helps you build software.
- **[Cursor](https://www.cursor.com/)** is an AI-powered IDE built on VS Code. Its Agent mode can read, write, and refactor code with awareness of your project context.

Both tools can be customized to understand your project's stack, conventions, and workflows. This repo teaches you how.

## Repository Structure

```
├── guide/                           # Core guide
│   ├── README.md                    # Overview — comparison of both tools
│   ├── claude-code/                 # Claude Code specific
│   │   ├── README.md               # Overview of 4 concepts
│   │   ├── 01-rules/               # CLAUDE.md — project context
│   │   ├── 02-commands/            # Slash commands
│   │   ├── 03-hooks/               # Automated quality gates
│   │   └── 04-skills/              # Advanced prompt engineering
│   └── cursor/                      # Cursor specific
│       ├── README.md               # Overview of 2 concepts
│       ├── 01-rules/               # .cursor/rules/*.mdc files
│       └── 02-skills/              # .cursor/skills/*/SKILL.md
├── setup/
│   └── atlassian-mcp.md            # Connect Jira/Confluence via MCP
├── examples/
│   └── specs/                       # Sample output from AI workflows
│       └── SH-164.md
└── .claude/                         # Working Claude Code config (live example)
    ├── commands/
    │   └── research-ticket.md
    └── settings.local.json
```

## Quick Start

### 1. Read the Guide

Start with the [Guide Overview](guide/README.md) to understand the concepts and choose your tool:

| Tool | Concepts | Start Here |
|------|----------|------------|
| **Claude Code** | Rules, Commands, Hooks, Skills | [guide/claude-code/](guide/claude-code/README.md) |
| **Cursor** | Rules, Skills | [guide/cursor/](guide/cursor/README.md) |

### 2. Concept Comparison

| Concept | Claude Code | Cursor |
|---------|------------|--------|
| **Rules** | Single `CLAUDE.md` at project root | Multiple `.cursor/rules/*.mdc` with glob scoping |
| **Commands** | `.claude/commands/*.md` slash commands | -- |
| **Hooks** | `.claude/settings.json` auto-run scripts | -- |
| **Skills** | Advanced commands in `.claude/commands/` | `.cursor/skills/*/SKILL.md` with auto-discovery |
| **MCP** | Supported | Supported |

### 3. Set Up Your Project

**For Claude Code:**

```bash
cp guide/claude-code/01-rules/example-saafehouse.md your-project/CLAUDE.md
mkdir -p your-project/.claude/commands
cp guide/claude-code/02-commands/example-create-module.md your-project/.claude/commands/create-module.md
```

**For Cursor:**

```bash
mkdir -p your-project/.cursor/rules
# Create .mdc files from guide/cursor/01-rules/example-saafehouse.md

mkdir -p your-project/.cursor/skills/write-test
# Create SKILL.md from guide/cursor/02-skills/example-write-test.md
```

### 4. Connect External Tools (Optional)

- [Atlassian MCP Setup](setup/atlassian-mcp.md) — Connect Jira & Confluence

## What's Inside

### Guide: Claude Code

| Section | What It Covers |
|---------|---------------|
| [Rules](guide/claude-code/01-rules/README.md) | `CLAUDE.md` — project context Claude always knows |
| [Commands](guide/claude-code/02-commands/README.md) | Slash commands for repeatable workflows |
| [Hooks](guide/claude-code/03-hooks/README.md) | Auto-run ESLint, Prettier, etc. after AI edits |
| [Skills](guide/claude-code/04-skills/README.md) | Expert personas with prompt engineering |

### Guide: Cursor

| Section | What It Covers |
|---------|---------------|
| [Rules](guide/cursor/01-rules/README.md) | `.mdc` files — glob-scoped project conventions |
| [Skills](guide/cursor/02-skills/README.md) | `SKILL.md` — auto-discovered expert workflows |

### Examples

- **[SH-164.md](examples/specs/SH-164.md)** — Spec generated from a Jira ticket via the `/research-ticket` command
- **[.claude/commands/research-ticket.md](.claude/commands/research-ticket.md)** — Live command that fetches Jira tickets via MCP

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and/or [Cursor](https://www.cursor.com/) installed
- A project you want to configure
- (Optional) Node.js v20+ for MCP integrations

## Contributing

1. Follow the templates in each guide section
2. Include both a template and a real-world example for each concept
3. Write in English
4. Keep documents concise — AI assistants read them on every task

## License

This guide is open for internal and educational use.

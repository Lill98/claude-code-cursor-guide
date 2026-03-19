# AI Coding Assistant Guide: Claude Code & Cursor

This guide teaches you how to customize and extend two AI coding assistants — **Claude Code** (Anthropic's terminal-based agent) and **Cursor** (AI-powered IDE) — with practical examples from the **saafehouse-be** project.

---

## Concept Comparison

Both tools let you give the AI persistent context about your project, but they use different mechanisms:

| Concept | Claude Code | Cursor | Purpose |
|---------|------------|--------|---------|
| **Rules** | `CLAUDE.md` (single file, always active) | `.cursor/rules/*.mdc` (multiple files, can be glob-scoped) | Tell the AI about your project conventions |
| **Commands** | `.claude/commands/*.md` (slash commands) | -- | Reusable multi-step workflows |
| **Hooks** | `.claude/settings.json` hooks | -- | Auto-run shell commands before/after AI actions |
| **Skills** | `.claude/commands/*.md` (advanced prompts) | `.cursor/skills/*/SKILL.md` | Expert-level prompt engineering |
| **MCP** | Supported (`.claude.json`) | Supported (Cursor Settings) | Connect external tools (Jira, Confluence, etc.) |

### Key Differences

- **Claude Code** runs in your terminal. It has **Commands** (slash-command workflows) and **Hooks** (automated quality gates) that Cursor does not.
- **Cursor** is a full IDE. Its rules system is more granular — you can scope rules to specific file patterns using globs, and split concerns across multiple `.mdc` files. Its **Skills** system uses a formal `SKILL.md` format with YAML metadata for automatic discovery.
- **Both** support MCP (Model Context Protocol) for connecting external tools like Jira and Confluence.

---

## Choose Your Guide

### [Claude Code Guide](./claude-code/README.md)

Covers 4 concepts:
1. **Rules** — `CLAUDE.md` at the project root
2. **Commands** — Slash commands in `.claude/commands/`
3. **Hooks** — Automated quality gates in `.claude/settings.json`
4. **Skills** — Advanced prompt engineering as commands

### [Cursor Guide](./cursor/README.md)

Covers 2 concepts:
1. **Rules** — `.cursor/rules/*.mdc` with glob-scoped targeting
2. **Skills** — `.cursor/skills/*/SKILL.md` with formal metadata

---

## Which Tool Should I Start With?

| Situation | Recommendation |
|-----------|---------------|
| You use Cursor as your IDE | Start with the [Cursor Guide](./cursor/README.md) |
| You prefer terminal workflows | Start with the [Claude Code Guide](./claude-code/README.md) |
| You use both | Start with Rules in both — they solve the same problem differently |
| You want automated quality gates | Claude Code has [Hooks](./claude-code/03-hooks/README.md); Cursor does not |
| You want file-scoped AI behavior | Cursor [Rules](./cursor/01-rules/README.md) support glob patterns natively |

---

## Quick Start

### For Claude Code

```bash
# Copy rules to your project root
cp guide/claude-code/01-rules/example-saafehouse.md your-project/CLAUDE.md

# Set up commands
mkdir -p your-project/.claude/commands
cp guide/claude-code/02-commands/example-create-module.md your-project/.claude/commands/create-module.md
```

### For Cursor

```bash
# Copy rules to your project
mkdir -p your-project/.cursor/rules
cp guide/cursor/01-rules/example-saafehouse.md your-project/.cursor/rules/

# Set up skills
mkdir -p your-project/.cursor/skills
cp -r guide/cursor/02-skills/example-write-test.md your-project/.cursor/skills/
```

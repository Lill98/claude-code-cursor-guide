# AI Coding Assistant Guide: Claude Code & Cursor

This guide teaches you how to customize and extend two AI coding assistants — **Claude Code** (Anthropic's terminal-based agent) and **Cursor** (AI-powered IDE) — with practical examples from the **saafehouse-be** project.

---

## Concept Comparison

Both tools let you give the AI persistent context about your project, but they use different mechanisms:

| Concept | Claude Code | Cursor | Purpose |
|---------|------------|--------|---------|
| **Rules** | `CLAUDE.md` (single file, always active) | `.cursor/rules/*.md` (multiple files, 4 scoping modes) | Tell the AI about your project conventions |
| **Commands** | `.claude/commands/*.md` (slash commands) | -- | Reusable multi-step workflows |
| **Hooks** | `.claude/settings.json` hooks | `.cursor/hooks.json` hooks | Auto-run shell commands before/after AI actions |
| **Skills** | `.claude/commands/*.md` (advanced prompts) | `.agents/skills/*/SKILL.md` | Single-purpose expert workflows |
| **Subagents** | -- | `.cursor/agents/*.md` | Multi-step specialized agents with own context window |
| **TDD Workflow** | `/spec-to-tests` skill + Stop hook + Husky | `spec-to-tests` Skill + `stop` hook + Husky | Generate test stubs from spec; run tests before commit |
| **MCP** | Supported (`~/.claude.json`) | Supported (`~/.cursor/mcp.json`) | Connect external tools (Jira, Confluence, etc.) |

### Key Differences

- **Claude Code** runs in your terminal. It has **Commands** (explicit slash commands) that Cursor does not. Both have **Hooks**, but with different config formats and event names.
- **Cursor** is a full IDE. Its rules system supports 4 scoping modes. It has **Subagents** (multi-step agents with their own context window, in `.cursor/agents/`) which Claude Code does not have. Skills are stored in `.agents/skills/` and auto-discovered by description.
- **Both** support MCP (Model Context Protocol) for connecting external tools like Jira and Confluence.

---

## Choose Your Guide

### [Claude Code Guide](./claude-code/README.md)

Covers 5 concepts:
1. **Rules** — `CLAUDE.md` at the project root
2. **Commands** — Slash commands in `.claude/commands/`
3. **Hooks** — Automated quality gates in `.claude/settings.json`
4. **Skills** — Advanced prompt engineering as commands
5. **TDD Workflow** — Generate test stubs from spec; run tests before commit

### [Cursor Guide](./cursor/README.md)

Covers 5 concepts:
1. **Rules** — `.cursor/rules/*.md` with 4 scoping modes
2. **Skills** — `.agents/skills/*/SKILL.md` with auto-discovery
3. **Subagents** — `.cursor/agents/*.md` for multi-step specialized tasks
4. **Hooks** — `.cursor/hooks.json` automated quality gates
5. **TDD Workflow** — `spec-to-tests` Skill + `stop` hook + Husky

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

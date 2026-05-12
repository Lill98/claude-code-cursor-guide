# AI Coding Assistant Guide: Claude Code & Cursor

A practical guide to customizing and extending **Claude Code** (Anthropic's terminal-based agent) and **Cursor** (AI-powered IDE) with rules, commands, hooks, skills, subagents, MCP, and more.

---

## Concept Comparison

Both tools let you give the AI persistent context about your project, but they use different mechanisms:

| Concept | Claude Code | Cursor | Purpose |
|---------|------------|--------|---------|
| **Config** | 4-layer hierarchy (Managed → Global → Project → Directory) | — | Understand what loads, what to commit, what to gitignore |
| **Rules** | `CLAUDE.md` (stacking layers) + `.claude/rules/` (path-scoped) | `.cursor/rules/*.md` — 4 scoping modes | Tell the AI about your project conventions |
| **Commands** | `.claude/commands/*.md` — slash commands | — | Reusable multi-step workflows |
| **Hooks** | `.claude/settings.json` — 10+ events (PreToolUse, Stop, SubagentStart/Stop, PreCompact, ...) | `.cursor/hooks.json` | Auto-run shell commands before/after AI actions |
| **Skills** | `.claude/skills/*/SKILL.md` or `~/.claude/skills/` (personal). Bundled: `/simplify`, `/debug`, `/review` | `.agents/skills/*/SKILL.md` | Single-purpose expert workflows; auto-invoked by description |
| **Subagents** | `context: fork` in skills + `claude --worktree`; SubagentStart/Stop hooks | `.cursor/agents/*.md` | Isolated context window for exploration, parallel work, review |
| **MCP** | `~/.claude.json` | `~/.cursor/mcp.json` | Connect external tools (Jira, GitHub, DB...) |
| **TDD Workflow** | `/spec-to-tests` skill + Stop hook | `spec-to-tests` skill + stop hook | Generate test stubs from spec; run tests automatically |

### Key Differences

- **Claude Code** runs in your terminal. It has **Commands** (explicit slash commands) that Cursor does not. It has a rich hook system with 10+ events including `SubagentStop`, `PreCompact`, and `UserPromptSubmit`. Subagents run in fully isolated context windows via `context: fork`.
- **Cursor** is a full IDE built on VS Code. Its rules system supports 4 scoping modes (always, auto, agent-requested, manual). Subagents live in `.cursor/agents/` as specialized multi-step agents.
- **Both** support MCP (Model Context Protocol) for connecting to Jira, Confluence, GitHub, databases, and other external tools.

---

## Choose Your Guide

### [Claude Code Guide](./claude-code/README.md)

8 sections, 3 learning levels:

| Level | Sections | What You Get |
|-------|----------|--------------|
| **Basic** | 00-config → 01-rules → 02-commands → 03-hooks | Config hierarchy, project context, slash commands, auto formatting |
| **Intermediate** | 04-skills → 05-subagents → 06-mcp | Expert workflows, parallel agents, Jira/GitHub integration |
| **Advanced** | 07-tdd → 08-tips | TDD automation, token optimization, session management |

### [Cursor Guide](./cursor/README.md)

Covers 5 concepts:
1. **Rules** — `.cursor/rules/*.md` with 4 scoping modes
2. **Skills** — `.agents/skills/*/SKILL.md` with auto-discovery
3. **TDD Workflow** — `spec-to-tests` skill + stop hook
4. **Hooks** — `.cursor/hooks.json` automated quality gates
5. **Subagents** — `.cursor/agents/*.md` for multi-step specialized tasks

---

## Which Tool Should I Start With?

| Situation | Recommendation |
|-----------|---------------|
| You use Cursor as your IDE | Start with the [Cursor Guide](./cursor/README.md) |
| You prefer terminal workflows | Start with the [Claude Code Guide](./claude-code/README.md) |
| You use both | Start with Rules in both — concepts transfer |
| You want automated quality gates | Both have Hooks; Claude Code has more events (SubagentStop, PreCompact, UserPromptSubmit) |
| You want file-scoped AI behavior | Cursor Rules support glob patterns natively |
| You want external tool integration | Both support MCP; see [06-mcp](./claude-code/06-mcp/README.md) |

---

## Quick Start

### For Claude Code

```bash
# Copy the working demo config to your project
cp -r .claude/ your-project/.claude/

# Use the example CLAUDE.md as a starting point
cp guide/claude-code/01-rules/example-blog.md your-project/CLAUDE.md

# Add personal overrides to .gitignore
echo ".claude/settings.local.json" >> your-project/.gitignore
echo "CLAUDE.local.md" >> your-project/.gitignore
```

### For Cursor

```bash
# Copy rules to your project
mkdir -p your-project/.cursor/rules
cp guide/cursor/01-rules/example-*.md your-project/.cursor/rules/

# Copy skills
mkdir -p your-project/.agents/skills
cp -r guide/cursor/02-skills/example-write-test.md your-project/.agents/skills/
```

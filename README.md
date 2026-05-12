# AI Tools Handbook — Claude Code & Cursor

I've compiled a handbook on Claude Code and Cursor — drawing from Anthropic's official courses and my own hands-on experience.

It covers: config hierarchy and CLAUDE.md setup, advanced features like Hooks, Skills, Commands, MCP, Subagents, TDD workflows, and some token optimization techniques that aren't well documented elsewhere.

The structure is organized as a learning path — numbered sections from basics to advanced — so it's easy to follow whether you're just getting started or looking to go deeper. Each section includes a reusable template plus a real-world example you can copy directly into your project.

> **Note:** The Claude Code guide is up to date. The Cursor guide is still a work in progress and will be updated over time.

## What Are These Tools?

- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** — Anthropic's agentic coding tool. Runs in your terminal and IDE. Reads your codebase, edits files, runs commands, and builds software autonomously.
- **[Cursor](https://www.cursor.com/)** — AI-powered IDE built on VS Code. Agent mode reads, writes, and refactors code with full project context.

Both tools can be customized to understand your stack, conventions, and workflows. This repo is a reference handbook and working demo — copy the templates, adapt to your project.

---

## Repository Structure

```
├── guide/
│   ├── README.md                        # Claude Code vs Cursor comparison
│   ├── claude-code/                     # Claude Code guide (8 sections)
│   │   ├── README.md / README.vi.md     # Overview + 3-level learning path
│   │   ├── 00-config/                   # Config hierarchy — read this first
│   │   ├── 01-rules/                    # CLAUDE.md, .claude/rules/, @import
│   │   ├── 02-commands/                 # Slash commands
│   │   ├── 03-hooks/                    # Auto quality gates (10+ events)
│   │   ├── 04-skills/                   # Expert workflows (bundled + custom)
│   │   ├── 05-subagents/                # Multi-agent, worktrees, context isolation
│   │   ├── 06-mcp/                      # External tools (Jira, GitHub, DB...)
│   │   ├── 07-tdd/                      # TDD workflow: spec → tests → code
│   │   └── 08-tips/                     # How Claude works, prompting, token optimization
│   └── cursor/                          # Cursor guide
│       ├── README.md
│       ├── 01-rules/                    # .cursor/rules/*.md — 4 scoping modes
│       ├── 02-skills/                   # .agents/skills/*/SKILL.md
│       ├── 03-tdd/                      # TDD workflow
│       ├── 04-hooks/                    # hooks.json
│       └── 05-subagents/               # .cursor/agents/
├── specs/                               # Generated specs from /research-ticket (outputs)
│   ├── SH-164.md
│   └── SH-171.md
├── setup/
│   └── cursor-mcp.md                    # MCP setup for Cursor
└── .claude/                             # Working demo config (copy to your project)
    ├── settings.json                    # Hooks: prettier, lint, tests
    ├── commands/
    │   └── research-ticket.md           # Live command — fetch Jira → spec
    ├── skills/
    │   ├── write-test/SKILL.md
    │   ├── review-pr/SKILL.md
    │   └── spec-to-tests/SKILL.md
    └── hooks/
        ├── lint-fix.sh
        ├── prettier-fix.sh
        └── run-tests.sh
```

---

## How to Read This Repo

**Step 1 — Pick your tool:**

| I use... | Start here |
|----------|------------|
| Claude Code | [guide/claude-code/README.md](guide/claude-code/README.md) |
| Cursor | [guide/cursor/README.md](guide/cursor/README.md) |
| Both | Read Claude Code first — concepts transfer |

**Step 2 — Follow the numbered sections in order.** Each section builds on the previous one.

**Step 3 — Copy the working demo** from `.claude/` into your project and adjust.

---

### Claude Code — 3-Level Learning Path

| Level | Sections | What You Get |
|-------|----------|--------------|
| **Basic** | 00-config → 01-rules → 02-commands → 03-hooks | Project context, slash commands, auto formatting |
| **Intermediate** | 04-skills → 05-subagents → 06-mcp | Expert workflows, parallel agents, external tools |
| **Advanced** | 07-tdd → 08-tips | TDD automation, token optimization, session management |

> Each section has `README.md` (English) + `README.vi.md` (Vietnamese) + `example-*.md` (real-world example).

### Cursor

**Start here:** [guide/cursor/README.md](guide/cursor/README.md)

---

## Concept Comparison

| Concept | Claude Code | Cursor |
|---------|------------|--------|
| **Rules** | `CLAUDE.md` (stacking layers) + `.claude/rules/` (path-scoped) | `.cursor/rules/*.md` — 4 scoping modes |
| **Commands** | `.claude/commands/*.md` — slash commands | — |
| **Hooks** | `.claude/settings.json` — 10+ events | `.cursor/hooks.json` |
| **Skills** | `.claude/skills/<name>/SKILL.md` + bundled skills | `.agents/skills/<name>/SKILL.md` |
| **Subagents** | `context: fork` in skills + `claude --worktree` | `.cursor/agents/*.md` |
| **MCP** | `~/.claude.json` | `~/.cursor/mcp.json` |
| **TDD Workflow** | `/spec-to-tests` + Stop hook + Husky | `spec-to-tests` skill + stop hook + Husky |

---

## Use the Working Demo

The `.claude/` folder in this repo is a functional config — not just documentation. Copy it to your project:

```bash
# Copy working config to your project
cp -r .claude/ your-project/.claude/

# Copy CLAUDE.md template
cp guide/claude-code/01-rules/example-blog.md your-project/CLAUDE.md

# Add to .gitignore
echo ".claude/settings.local.json" >> your-project/.gitignore
echo "CLAUDE.local.md" >> your-project/.gitignore
```

---

## Connect External Tools

- **Jira + Confluence:** [guide/claude-code/06-mcp/example-atlassian.md](guide/claude-code/06-mcp/example-atlassian.md)
- **MCP for Cursor:** [setup/cursor-mcp.md](setup/cursor-mcp.md)

---

## Each guide section has

- `README.md` — concept explanation + template (English)
- `README.vi.md` — same content in Vietnamese
- `example-*.md` — real-world example implementing the template
- `example-*.vi.md` — Vietnamese version of the example

---

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and/or [Cursor](https://www.cursor.com/) installed
- Node.js v20+ (for MCP integrations)
- A project you want to configure

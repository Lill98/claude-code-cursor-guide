# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## What This Repo Is

A general-purpose handbook teaching how to customize Claude Code and Cursor with Rules, Commands, Hooks, Skills, Subagents, and MCP. No build/test pipeline — pure markdown documentation repo.

## Guide Structure Convention

Every guide section follows this pattern — maintain it when adding or updating:

```
guide/<tool>/<section>/
├── README.md          # Concept explanation + template (English)
├── README.vi.md       # Same content in Vietnamese
├── example-*.md       # Real-world example implementing the template (English)
└── example-*.vi.md    # Vietnamese version of the example
```

Sections are numbered (`00-config`, `01-rules`, etc.) to enforce reading order.

**Language rule:** `README.md` and `example-*.md` = pure English. `README.vi.md` and `example-*.vi.md` = pure Vietnamese. No mixing within a file. Technical terms (hook, skill, MCP, subagent, context window, etc.) stay in English even in VI files.

## Claude Code Guide Sections

```
guide/claude-code/
├── 00-config/     # Config hierarchy — read first
├── 01-rules/      # CLAUDE.md, .claude/rules/, @import
├── 02-commands/   # Slash commands
├── 03-hooks/      # Auto quality gates (10+ events)
├── 04-skills/     # Expert workflows (bundled + custom)
├── 05-subagents/  # Multi-agent, worktrees, context isolation
├── 06-mcp/        # External tools (Jira, GitHub, DB...)
├── 07-tdd/        # TDD workflow: spec → tests → code
└── 08-tips/       # How Claude works, prompting, token optimization
```

## Active Claude Code Config (live demo in this repo)

`.claude/commands/research-ticket.md` — fetches a Jira ticket + linked Confluence pages via MCP, writes a structured spec to `specs/[TICKET-KEY].md`.

`.claude/skills/` — working skill demos: `write-test`, `review-pr`, `spec-to-tests`.

`.claude/hooks/` — working hook scripts: `lint-fix.sh`, `prettier-fix.sh`, `run-tests.sh`.

`.claude/settings.json` — team hooks config (PostToolUse + Stop).

`.claude/settings.local.json` — local permissions (gitignored). Do not commit.

## /research-ticket Command

Requires Atlassian MCP. See `guide/claude-code/06-mcp/example-atlassian.md` for setup.

Output path: `specs/[TICKET-KEY].md`

`.env` in repo root may hold API tokens — do not commit changes to this file.

## Do Not

- Mix languages within a single `.md` file
- Add saafehouse-specific content — keep examples generic
- Commit `.claude/settings.local.json` or `.env`
- Create new floating docs at repo root — content belongs inside `guide/`

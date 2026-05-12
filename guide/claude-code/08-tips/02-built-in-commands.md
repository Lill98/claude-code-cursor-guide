# Built-in Commands & Keyboard Shortcuts

Complete reference for Claude Code's built-in commands and shortcuts. These are available in every session — no setup required.

---

## Session Control

| Command | What It Does |
|---------|-------------|
| `/clear` | Discard the entire conversation and start a fresh session. All context is wiped. Use when the session is polluted or you are starting a new, unrelated task. |
| `/compact` | Compress the conversation into a summary. Frees up context window space while keeping key decisions and code. |
| `/compact "focus"` | Compact with a focus hint: tell Claude which parts to keep. Example: `/compact "keep the auth module changes"` |
| `/rewind` | Same as Esc+Esc — opens the checkpoint menu to jump back to a previous point in the conversation. |
| `/btw` | Ask a side question without it being added to conversation history. Good for quick lookups that should not pollute the context. |
| `/cost` | Show token usage for this session and the cache hit rate. Use this to track how efficiently you are using context. |
| `/context` | Show a token breakdown by category: system prompt, tools, memory, conversation. |
| `/stats` | Session statistics including total tokens, tool calls, and time elapsed. |

---

## Mode Switching

| Command / Shortcut | What It Does |
|--------------------|-------------|
| `Shift+Tab` | Cycle through modes: **Normal** → **Auto-accept edits** → **Plan Mode** → back to Normal. |
| `/effort low` | Use minimal thinking tokens. Good for simple questions and lookups. |
| `/effort medium` | Default effort level. |
| `/effort high` | Use extended thinking. Better for complex architecture decisions. |
| `/effort max` | Maximum thinking tokens. Use sparingly — very expensive. |

**Mode descriptions:**
- **Normal** — Claude asks for permission before each file edit (default)
- **Auto-accept** — Claude applies all edits without asking. Use for unattended runs.
- **Plan Mode** — Claude reads files and plans but does not write anything. Switch to Normal Mode to execute.

---

## Model Selection

| Command | What It Does |
|---------|-------------|
| `/model sonnet` | Switch to Claude Sonnet. Recommended default — fast and cost-effective. |
| `/model opus` | Switch to Claude Opus. More capable for complex reasoning; more expensive. |
| `/model haiku` | Switch to Claude Haiku. Fast and cheap for simple tasks. |

Use `/cost` after switching models to compare token spend.

---

## Customization

| Command | What It Does |
|---------|-------------|
| `/init` | Scan the current project and generate a CLAUDE.md file with detected patterns and stack. |
| `/memory` | View all CLAUDE.md files currently loaded (global, project, folder levels). |
| `/rename "name"` | Give this session a name for the session history. |
| `/color` | Toggle syntax highlighting. |
| `/statusline` | Toggle the status line (token usage bar at the top). |
| `/voice` | Enable voice input mode (where supported). |

---

## Background Tasks

| Command | What It Does |
|---------|-------------|
| `Ctrl+B` | Run the current session in the background. Claude continues working; you get your terminal back. Returns output when done. |

Useful for long-running tasks (running test suites, generating many files) where you want to do other work while Claude is running.

---

## Keyboard Shortcuts

| Shortcut | What It Does |
|----------|-------------|
| `Esc` | Stop Claude's current output or action immediately. |
| `Esc + Esc` | Open the checkpoint menu. Choose a previous state in the conversation to rewind to. |
| `Ctrl+S` | Stash the current draft prompt without sending it. Retrieve it later. |
| `Shift+Tab` | Cycle between Normal / Auto-accept / Plan modes. |
| `Ctrl+B` | Send to background. |

---

## Shell Command Prefix

Prefix any line with `!` to run it as a shell command directly in your prompt:

```
! cat src/auth/login.service.ts
Explain what this login service does and suggest improvements.
```

This pipes the shell output directly into the prompt — no need for a separate terminal command.

---

## Worktrees

```bash
claude --worktree feature-name
```

Open Claude Code in a separate git worktree. Each worktree has its own working directory and Claude session — useful for parallel development without branch-switching in your main workspace.

See [03-session-management.md](./03-session-management.md) for the full parallel sessions workflow.

# Tips & Best Practices

> **Level 3 — Advanced.** Read this section after you are comfortable with Rules, Hooks, and Skills.

This section explains how Claude Code actually works when you type a prompt — so you understand what is happening, avoid wasting tokens, and write more effective prompts.

---

## Contents

| File | What It Covers |
|------|---------------|
| [01-how-claude-works.md](./01-how-claude-works.md) | What Claude does with your prompt — step by step |
| [02-built-in-commands.md](./02-built-in-commands.md) | All built-in commands and keyboard shortcuts |
| [03-session-management.md](./03-session-management.md) | When to use /clear, /compact, or start a new session |
| [04-prompting.md](./04-prompting.md) | How to write effective prompts — before/after examples |
| [05-token-optimization.md](./05-token-optimization.md) | Token-saving techniques with a priority table |

---

## 3 Core Principles

### 1. The Context Window Is Your Most Valuable Resource

Every file Claude reads, every message you send, every output Claude produces consumes tokens and accumulates in the context window. When the context fills up (~30–40%), output quality begins to degrade — Claude loses focus.

**Practical consequence:** One session that handles many different tasks will perform worse than multiple short sessions each with a single task.

### 2. Verification Loops Matter More Than Long Prompts

Give Claude a way to verify its own results:

```
Implement X. Then run `npm test` to verify. Fix any failures.
```

This produces 2–3x better outcomes compared to just saying "implement X."

### 3. Point to the Right Place Instead of Letting Claude Search

```
Bad:  "Fix the login bug"
      → Claude greps everywhere, reads many files, burns tokens

Good: "Fix login bug in src/auth/login.service.ts ~line 80"
      → Claude reads the right file immediately
```

---

## Quick Reference

```bash
/clear          # Start a fresh session
/compact        # Compress conversation, keep key information
/memory         # View which CLAUDE.md files are loaded
/cost           # Token usage + cache hit rate
/context        # Token breakdown by category
Shift+Tab       # Cycle: Normal → Auto-accept → Plan Mode
Esc+Esc         # Checkpoint menu (rewind to a previous state)
/btw            # Side question — not added to conversation history
```

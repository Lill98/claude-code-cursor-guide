# How Claude Code Processes Your Prompts

Understanding this mechanism helps you prompt correctly and avoid wasting tokens.

---

## When You Type a Prompt

Claude does **not read your entire codebase**. It uses search tools to find relevant files first, then reads them. This is the actual flow:

```
You type: "Fix the login bug"
                │
                ▼
┌───────────────────────────────────────┐
│  STEP 1: Load CLAUDE.md              │
│  All CLAUDE.md files accumulate      │
│  Fixed token cost per session        │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│  STEP 2: Parse Prompt                │
│  Extract keywords: "login", "bug"    │
│  Find file paths if provided         │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│  STEP 3: Search Codebase             │
│  grep -r "login" src/                │
│  find . -name "*login*"              │
│  ls src/auth/                        │
│  → Produces a list of candidate      │
│    files (low token cost)            │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│  STEP 4: Read Relevant Files         │
│  Read src/auth/login.service.ts      │
│  Read src/auth/login.controller.ts   │
│  → Highest token cost step           │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│  STEP 5: Cascade Imports (DANGER)    │
│  Login service imports UserService   │
│  UserService imports PrismaService   │
│  PrismaService imports...            │
│  → Can cascade into 5–10 more files  │
└───────────────────┬───────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│  STEP 6: Plan + Implement            │
│  With accumulated context            │
└───────────────────────────────────────┘
```

---

## Token Consumption Map

| Step | Token Cost | Optimizable? |
|------|:----------:|:------------:|
| Load CLAUDE.md | Fixed, per session | Keep CLAUDE.md short |
| Search (grep/find) | Low — file names + matches only | Minimal |
| Read 2–3 relevant files | High | Point to file paths directly |
| Cascade imports | Very high | Use .claudeignore |
| Conversation history | Accumulates over time | Use /compact, /clear |

---

## Practical Consequences

### Vague prompt → Claude searches → burns tokens

```
You:   "Fix the login bug"
Claude: grep "login" → finds 15 files → reads 5–6 → cascades into 3–4 more
Result: ~8,000 tokens just to understand context
```

### Prompt with file path → Claude reads the right file immediately

```
You:   "Fix login bug in src/auth/login.service.ts ~line 80"
Claude: Reads exactly 1 file → ~800 tokens
Result: 90% token savings on the context-loading step
```

---

## Context Window Mechanics

### Context does not reset between messages

The entire conversation accumulates. Message 40 "pays" for all 39 previous messages:

```
Message  1:   800 tokens → total     800
Message  2:   600 tokens → total   1,400
...
Message 40:   200 tokens → total  45,000 tokens!
```

### Quality degrades as context fills

```
0–30%   full  →  Best quality
30–60%  full  →  Starting to lose focus
60–80%  full  →  Noticeable quality drop
80%+    full  →  Auto-compact triggers or error
```

### Cache tokens save 90% on repeated reads

If CLAUDE.md rarely changes, Anthropic caches it. Subsequent reads cost only 10% of the original token price. Do not reformat CLAUDE.md between sessions — it breaks the cache.

---

## What Is in Claude's Context at Any Point

```
Session context contains:
├── System prompt (hidden — tools, permissions)
├── CLAUDE.md files (all levels: global, project, folder)
├── Auto memory from previous sessions
├── Conversation history (all messages in this session)
└── File contents that were read
```

The `/context` command shows a breakdown:

```
/context
→ System:       12,000 tokens
→ Tools:         8,000 tokens
→ Memory:        2,000 tokens
→ Conversation: 15,000 tokens
→ Total:        37,000 / 200,000 tokens (18%)
```

---

## Once a File Is Read, It Stays

Once a file is read into context, **it stays there until you /clear**. Even when the conversation moves on to a different topic, the file content continues consuming tokens.

**Consequence:** A long debug session (reading many files to trace a bug) contaminates the context for subsequent tasks. Quality drops for everything after.

**Fix:** Run `/clear` or use a subagent for investigation tasks — subagents get their own isolated context.

---

## Plan Mode — Explore Before Committing

Plan Mode (Shift+Tab) lets Claude read files, ask questions, and understand a problem **without executing any code**:

```
[Plan Mode]
You:   "Add user invitation feature"
Claude: Reads 5 files, asks 2 clarifying questions, creates implementation plan
You:   Review plan, adjust scope if needed
You:   Shift+Tab → switch back to Normal Mode
Claude: Implements based on the agreed plan
```

**Benefit:** Avoids 20 minutes of implementing in the wrong direction and having to undo.

---

## .claudeignore — Prevent Reading Unnecessary Files

```gitignore
# .claudeignore (create at project root)
node_modules/
dist/
build/
.next/
coverage/
*.generated.ts
prisma/migrations/
*.lock
*.log
public/assets/
```

Effect: when Claude searches or finds files, these are completely skipped — never read even if imported.

---

## Checklist Before Prompting

- [ ] Did you include the specific file path?
- [ ] Did you paste the actual error message/log (not a summary)?
- [ ] Did you describe how to verify (test command, expected output)?
- [ ] Is the session "dirty" from a previous debug? (consider /clear)
- [ ] Is the task small and clearly defined?

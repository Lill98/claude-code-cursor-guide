# Token Optimization

Practical techniques for reducing token consumption without sacrificing quality. Ordered from highest to lowest impact.

---

## 1. Keep CLAUDE.md Short and Behavior-Focused

CLAUDE.md is loaded at the start of every session and re-read on every message. Every line costs tokens repeatedly.

**Rules:**
- Only include rules that change Claude's behavior
- Remove explanatory text — Claude does not need context about why
- Use short, imperative sentences: "Filter all queries by firmId." not "Remember to always make sure that..."
- Split into folder-level files: put module-specific rules in `src/modules/auth/CLAUDE.md` instead of the root

**Before:**
```markdown
# Project Rules

This project is a NestJS backend. When you are working on this project, 
please remember that we use Prisma as our ORM and all database queries 
need to be multi-tenant aware, which means you should always filter by 
firmId when querying data. Also, we use Vitest for testing, not Jest.
```

**After:**
```markdown
- ORM: Prisma. All queries filter by firmId and deletedAt: null.
- Testing: Vitest (not Jest).
```

Result: same instructions, ~85% fewer tokens per session.

---

## 2. Use .claudeignore to Block Large Directories

Without `.claudeignore`, Claude may read `node_modules/`, generated files, or build output when exploring the codebase. These are almost never useful and burn thousands of tokens.

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
.git/
```

Effect: grep and find operations skip these entirely. Claude never accidentally reads a 50,000-line generated Prisma client.

---

## 3. Use Subagents for File Exploration

When you need to explore a large part of the codebase (understanding architecture, finding all usages of a pattern), use a subagent. Subagents run in their own isolated context — the file reads stay there, not in your main session.

```
Use a subagent to:
1. Read all files in src/modules/auth/
2. Find all places where the JWT token is validated
3. Return a summary of the validation flow (max 20 lines)

Do not read these files directly — delegate to the subagent.
```

The subagent's file reads (potentially 10,000+ tokens) do not appear in your main context. Only the 20-line summary does.

---

## 4. Parallel Sessions with Git Worktrees

Running two features simultaneously in one session mixes context and inflates token usage. Use git worktrees to give each feature its own clean session.

```bash
# Main session: invitation feature
# (already open)

# Create a parallel session for a second feature
git worktree add ../project-auth-refactor feature/auth-refactor
claude --worktree ../project-auth-refactor
```

Each session pays only for its own context. No cross-contamination.

---

## 5. /compact and /clear at the Right Time

Do not wait until context is at 80%+. Compact or clear proactively.

**Rule of thumb:**
- After completing a task and before starting the next: `/clear`
- At 40–60% context during an ongoing task: `/compact "keep [key info]"`
- After a long debug session: always `/clear` before starting a new task

See [03-session-management.md](./03-session-management.md) for the full decision table.

---

## 6. Limit Thinking Tokens

Extended thinking is expensive. Limit it for routine tasks.

**In `.claude/settings.json`:**
```json
{
  "env": {
    "MAX_THINKING_TOKENS": "8000"
  }
}
```

Default is 32,000 for extended thinking mode. 8,000 is sufficient for most implementation tasks. Use `/effort max` explicitly only when needed (complex architecture decisions, debugging hard problems).

---

## 7. Model Selection by Task Complexity

Do not use Opus for everything. Sonnet handles 90% of everyday development tasks at 1/5 the cost.

| Task Type | Recommended Model |
|-----------|-------------------|
| Code implementation | Sonnet (default) |
| Bug fixing | Sonnet |
| Test writing | Sonnet |
| Simple Q&A and lookups | Haiku |
| Complex architecture decisions | Opus |
| Debugging intermittent failures | Opus |
| Large refactors across many files | Opus |

Switch with `/model sonnet` or `/model opus` mid-session.

---

## 8. Point to Specific Files Instead of Vague Descriptions

Vague prompts trigger broad searches. Specific file paths skip the search phase entirely.

| Prompt Style | Token Cost |
|-------------|------------|
| "Fix the auth bug" | ~8,000 tokens (search + cascade reads) |
| "Fix bug in @src/auth/login.service.ts line 80" | ~800 tokens (single file read) |

When you know where the relevant code is, always include the path.

---

## 9. Break Work into Focused Sessions

One long mega-session accumulates context from all tasks. Multiple short focused sessions each start clean.

**Anti-pattern:**
```
Session: design + implementation + debugging + refactor + tests + code review
→ Context fills, last tasks run in polluted context at 70%+ usage
```

**Better:**
```
Session 1: Design and plan (Plan Mode)    → /clear
Session 2: Implement core logic           → /clear
Session 3: Debug failing tests            → /clear
Session 4: Refactor and final review      → /clear
```

Each session runs at peak quality. Total token cost is often lower despite starting fresh — no accumulated noise.

---

## 10. Session Notes Pattern for Cross-Session Continuity

When you start a new session, do not re-read files to rebuild context. Use a compact handoff note.

**End of session:**
```
/btw Write a 15-line summary of: what was built, which files were modified,
the current state, and the next 3 steps. I'll use this to start the next session.
```

**Start of next session — paste the note, then immediately give the task:**
```
[paste summary here]

Next task: implement validateInviteInput() in invitation.service.ts.
Run npx vitest --run after.
```

Claude gets context from the note (200 tokens) instead of re-reading files (3,000+ tokens).

---

## 11. Prompt Caching — Keep CLAUDE.md Static

Anthropic caches CLAUDE.md content between API calls. Cached tokens cost 10% of uncached. The cache TTL is 5 minutes; it resets if the file content changes.

**Maximize cache hit rate:**
- Do not add temporary notes to CLAUDE.md during a session
- Do not reformat or reorder CLAUDE.md between sessions
- Check cache hit rate with `/cost` — look for "cache_read_input_tokens" in the output

High cache hit rate means 90% savings on CLAUDE.md reads across an entire day.

---

## 12. Track Usage with /cost, /stats, /context

You cannot optimize what you do not measure.

```bash
/cost     # Total tokens this session + cache hit rate
/stats    # Tool calls, elapsed time, total spend
/context  # Breakdown: system / tools / memory / conversation
```

Run `/cost` at the start and end of each session to understand where tokens go. Compare before/after adding a technique to verify it actually helps.

---

## Priority Table

| Technique | Impact | Setup Effort |
|-----------|:------:|:------------:|
| Short, behavior-only CLAUDE.md | High | Low |
| .claudeignore | High | Very Low |
| Point to specific file paths | High | None |
| Focused sessions (not mega-sessions) | High | None |
| /compact and /clear at right time | High | None |
| Subagents for exploration | Medium | Low |
| Session Notes for continuity | Medium | Low |
| Limit thinking tokens | Medium | Low |
| Model selection by complexity | Medium | None |
| Parallel sessions with worktrees | Medium | Medium |
| Prompt caching (static CLAUDE.md) | Medium | None |
| Track usage with /cost | Low (enabling) | None |

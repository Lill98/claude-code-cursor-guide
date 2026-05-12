# Session Management

When to clear, compact, start fresh, or run sessions in parallel — and why it matters for output quality.

---

## Why Sessions Degrade

Every message, every file Claude reads, and every tool call accumulates in the context window. Claude does not have a "working memory" that refreshes — it always processes the full history. As the context fills, the model increasingly allocates attention to earlier content, which degrades performance on the current task.

This is not a Claude bug; it is how transformer models work. The fix is session hygiene.

---

## Context Degradation Thresholds

```
0–30%   Context usage  →  Full quality. Work freely.
30–40%  Context usage  →  Warning zone. Consider wrapping up or compacting.
40–70%  Context usage  →  Quality noticeably drops. Run /compact.
70–80%  Context usage  →  Compact immediately or start new session.
80%+    Context usage  →  Auto-compact triggers. May cause errors or truncation.
```

Check your current usage with `/context` or watch the status line (toggle with `/statusline`).

---

## Decision Table

| Situation | Recommended Action |
|-----------|--------------------|
| Starting a completely different task | `/clear` — wipe the slate |
| Long session, same task still ongoing | `/compact` — compress, keep going |
| Session is polluted with debug noise | `/clear` — don't drag the noise forward |
| You made Claude go in the wrong direction for 10+ messages | `Esc+Esc` checkpoint menu → rewind |
| Need to work on two features simultaneously | `claude --worktree` — parallel sessions |
| Large file exploration task (reading many files) | Subagent — isolated context |
| Context at 70%+ and task not finished | `/compact "keep [key context]"` then continue |
| Context at 80%+ | New session + Session Notes pattern |

---

## /clear vs /compact vs New Session

### `/clear`
- Wipes everything: conversation history, all read files, all context
- Use when: starting a new unrelated task, after a bad direction that cannot be rewound, after a long debug session that is now over
- Drawback: you lose everything — paste key context manually if the new task needs it

### `/compact`
- Compresses the conversation into a summary while keeping your Claude session running
- Use when: context is high but you are still mid-task and want to continue
- You can guide it: `/compact "keep the invitation service implementation and the failing test list"`
- Drawback: some detail is lost in compression; important nuances may disappear

### New Session
- Open a fresh terminal / new Claude Code instance
- Use when: shifting to a parallel workstream, or after `/clear` wipes something you still need
- Best combined with Session Notes pattern to transfer context deliberately

---

## Common Anti-Patterns

### Kitchen Sink Sessions
```
Bad: One session that does design + implementation + debugging + code review + tests
     → Context fills, last tasks are low quality

Good: One session per focused task. /clear between tasks.
```

### Debug Pollution
```
Bad: Fix bug A → debug session reads 15 files → then ask Claude to write feature B
     → Claude has 15 irrelevant files in context while writing feature B

Good: Fix bug A → /clear → write feature B in a clean session
```

### Correction Loops
```
Bad: 10 messages trying to correct a direction Claude got wrong
     → Each correction adds more context, doesn't actually reset the model's understanding

Good: Esc+Esc → rewind to before the wrong turn → give clearer instructions
```

---

## Session Notes Pattern

Use this to transfer essential context between sessions without wasting tokens.

**End of session — create a handoff note:**

```
/btw Summarize what we did, what files were changed, and what the next steps are. 
Keep it under 20 lines. I'll paste this at the start of the next session.
```

**Start of next session — paste it:**

```
Context from previous session:
- We were implementing InvitationService in src/modules/invitation/
- Completed: inviteUser() with email validation and user creation
- Next: implement validateInviteInput() and add the email dispatch
- Key constraint: every query must filter by firmId and deletedAt: null
```

This gives Claude exactly what it needs — without re-reading all the files from scratch.

---

## Parallel Sessions with Worktrees

Git worktrees let you have multiple working directories from the same repository, each on a different branch. Each Claude session in a worktree has its own clean context.

```bash
# Create a worktree for a parallel task
git worktree add ../project-feature-auth feature/auth-refactor
claude --worktree ../project-feature-auth

# Now you have two Claude sessions:
# - Main project: working on invitation feature
# - Worktree: refactoring auth module
# Each session has its own context — they don't interfere
```

Best for: working on two features in parallel, or keeping a long-running background task isolated.

---

## Subagents for Context Isolation

When a task requires reading many files (large-scale refactoring, codebase analysis), offload it to a subagent. The subagent gets its own context, does the work, and returns results — your main session stays clean.

```
Main session prompt:
"Use a subagent to read all files in src/modules/auth/ and summarize 
the authentication flow. Return a 1-page summary."
```

The subagent's file reads do not accumulate in your main context. Only the final summary does.

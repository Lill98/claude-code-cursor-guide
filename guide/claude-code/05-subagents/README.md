# Claude Code: Subagents

Subagents run in a **separate context window** — they do not inherit the conversation history of the main session. The main agent delegates a task, the subagent completes it, and returns a **summary**. The main session receives the summary, not the full output.

---

## Why Use Subagents?

| Problem | Solution |
|---------|----------|
| Grep 50 files → fills main context | Explore subagent reads everything; main receives only the summary |
| Need to review code you just wrote but are biased | Reviewer subagent with a fresh context |
| Multiple independent tasks that can run in parallel | Spawn multiple subagents simultaneously |
| Long debug session pollutes the main conversation | Subagent isolates the debugging work |

---

## How Subagents Work

```
Main Session (context A)
  │
  ├─── delegate task ───▶ Subagent (context B — fresh, isolated)
  │                              │
  │                              │  explores 30 files
  │                              │  runs tests
  │                              │  analyzes patterns
  │                              │
  ◀─── returns summary ──────────┘
  │     (~200 tokens, not 5000)
  │
  └─── continues with summary in context
```

The subagent has no knowledge of the main conversation. It only knows what was in the delegation prompt.

---

## Built-in Subagent Types

| Type | Use when | Read-only? |
|------|----------|:----------:|
| `Explore` | Searching the codebase, answering "where is file X", "where is symbol Y defined" | Yes |
| `Plan` | Architecture decisions, creating an implementation plan | Yes |
| `general-purpose` | Full capability — read and write files, run commands | No |

---

## How to Trigger Subagents

### 1. Explicit in Prompt

```
Use an Explore subagent to find all files that import UserService
```

```
Use a general-purpose subagent to implement the auth middleware,
then report back what was changed
```

### 2. In a Skill via `context: fork`

Add `context: fork` to the frontmatter of `SKILL.md` to run the skill inside an isolated subagent:

```markdown
---
name: review-pr
description: Review code changes for security and quality issues
context: fork
agent: Explore
---

# Review PR

Review all staged changes and check for:
1. Security issues (missing auth, data exposure)
2. Missing input validation
3. Test coverage gaps

Report findings with severity: CRITICAL / WARNING / SUGGESTION
```

When the user types `/review-pr`:
- A new subagent of type `Explore` is created
- The skill runs inside that subagent
- The main context receives the report, not the full file contents

### 3. Worktree Isolation

```bash
# Create an isolated working directory with its own branch
claude --worktree feature-auth

# Multiple agents in parallel, no conflicts
claude --worktree bugfix-payment    # Terminal 1
claude --worktree feature-dashboard # Terminal 2
```

Each worktree has:
- Its own git branch
- Its own working directory
- Its own context window

---

## Frontmatter Fields for Subagents

```markdown
---
name: skill-name
context: fork                        # Required to run inside a subagent
agent: Explore                       # Subagent type: Explore, Plan, general-purpose
disable-model-invocation: true       # Optional: manual invocation only
---
```

| Field | Values | Notes |
|-------|--------|-------|
| `context` | `fork` | Run in isolated subagent |
| `agent` | `Explore`, `Plan`, `general-purpose` | Default: `general-purpose` |

---

## Patterns

### Pattern 1: Investigation (Explore)

Use when you need to explore the codebase without filling the main context:

```
Use an Explore subagent to investigate how the payment flow works.
Find all relevant files, trace the data flow from API endpoint to database.
Return a summary: which files, which functions, what data model.
```

Main context receives a ~300-token summary instead of the output of 15 file reads.

---

### Pattern 2: Writer / Reviewer

Session A writes the code. Session B reviews it from a fresh context — no bias from having just written it:

```bash
# Session A: implement
claude "Implement the UserInvitation feature per specs/SH-164.md"

# Session B (fresh): review
claude "Review the changes in src/modules/invitation/ for security issues,
        missing validation, and test coverage. Fresh eyes, no context from implementation."
```

---

### Pattern 3: Fan-out (Parallel)

Spawn multiple subagents for independent tasks:

```
Use 3 parallel subagents to analyze the codebase:
1. Subagent 1: Find all Prisma queries missing a firmId filter
2. Subagent 2: Find all endpoints missing the @RequirePermission decorator
3. Subagent 3: Find all DTOs not using Zod validation

Each should return a list of file:line references.
Merge the findings into a single security audit report.
```

---

### Pattern 4: Implement → Verify

One subagent implements, then a verification subagent checks the result:

```
1. Implement the feature
2. Then use a general-purpose subagent to:
   - Run the test suite
   - Check that all acceptance criteria are covered
   - Report what passes, what fails, what is missing
```

---

## SubagentStart / SubagentStop Hooks

Monitor subagent lifecycle in `settings.json`:

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "",
        "hooks": [{
          "type": "command",
          "command": "echo \"Subagent started\" >> ~/.claude-activity.log"
        }]
      }
    ],
    "SubagentStop": [
      {
        "matcher": "",
        "hooks": [{
          "type": "command",
          "command": "bash .claude/hooks/on-subagent-stop.sh"
        }]
      }
    ]
  }
}
```

`SubagentStart` fires when a subagent is created. `SubagentStop` fires when it finishes (successfully or not). Use these for logging, timing, or triggering follow-up actions.

---

## When to Use Subagents vs Regular Skills

| Situation | Use |
|-----------|-----|
| Single-step task with clear output | Regular skill |
| Need to explore many files (>5) | Subagent with `Explore` |
| Need a feedback loop (implement → test → fix) | Subagent with `general-purpose` |
| Reviewing code you just wrote, need fresh perspective | Worktree or new session |
| Multiple independent tasks that can run in parallel | Multiple subagents |
| Long debug session | Subagent to isolate |

---

## TEMPLATE: Skill with Subagent

```markdown
---
name: [skill-name]
description: [When to use this skill — Claude uses this for auto-invocation]
context: fork
agent: Explore
disable-model-invocation: true
---

# [Skill Name]

## Role
[Expert persona — e.g., "Senior security auditor"]

## Task
[What this subagent should do — be specific]

## Steps

1. **[Step 1]**
   [Detailed instructions]

2. **[Step 2]**
   [Detailed instructions]

3. **[Step 3]**
   [Detailed instructions]

## Output Format

Return a structured report to the main agent:

### FINDINGS
[Findings organized by severity or category]

### SUMMARY
[2-3 sentence summary of key findings]

### RECOMMENDED NEXT STEPS
[What the main agent should do with this information]
```

---

## See a Real-World Example

→ [example-subagents.md](./example-subagents.md)

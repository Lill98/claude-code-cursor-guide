# Cursor: Subagents

Subagents are specialized AI assistants that the main Cursor agent can delegate tasks to. Each subagent runs in its own context window and returns results to the parent agent. Use them to break down complex tasks, run work in parallel, or apply specialized expertise.

---

## Built-in Subagents

Cursor includes three built-in subagents that activate automatically:

| Subagent | What It Does |
|----------|-------------|
| **Explore** | Searches and analyzes codebases using a faster model — runs in parallel for large code searches |
| **Bash** | Runs shell command sequences and isolates verbose output from the main context |
| **Browser** | Controls browsers via MCP tools, filtering noisy DOM snapshots |

No configuration needed — these activate when the agent encounters work suited to them.

---

## Custom Subagents

You can define your own subagents for specialized, repeatable tasks.

### Configuration

```
.cursor/agents/          # Project-level — shared with team via git
└── verifier.md

~/.cursor/agents/        # User-level — personal, across all projects
└── debugger.md
```

### File Format

```markdown
---
name: verifier
description: Independently validates completed work — runs tests, checks for incomplete implementations, verifies edge cases. Use after implementing a feature.
model: inherit
readonly: false
is_background: false
---

# Verifier

Review the completed implementation and:
1. Run the test suite
2. Check that all acceptance criteria from the spec are covered
3. Identify any missing edge cases
4. Report what passes, what fails, and what's missing
```

### Frontmatter Fields

| Field | Type | Purpose |
|-------|------|---------|
| `name` | string | Identifier — used for `/name` invocation. Lowercase, hyphens only. |
| `description` | string | Tells the agent when to delegate to this subagent. Be specific. |
| `model` | string | `inherit` (use parent model), `fast` (cheaper/faster), or a specific model ID |
| `readonly` | boolean | If `true`, restricts the subagent from writing files |
| `is_background` | boolean | If `true`, runs without blocking the parent agent |

---

## How to Use Subagents (Step-by-Step)

### Automatic Delegation

The agent decides when to use a subagent based on its `description`. No action needed — just describe the task naturally.

### Manual Invocation

```
/verifier confirm the InvitationService implementation is complete
```

Or in natural language:
```
Have the debugger investigate why this test is failing
```

### Parallel Execution

```
Run the verifier and the test-runner in parallel on the invitation module
```

---

## Subagents vs Skills

| | Subagents | Skills |
|---|---|---|
| **Use for** | Multi-step tasks, parallel work, context isolation | Single-purpose tasks that complete in one shot |
| **Context** | Own context window — starts fresh | Runs in the current agent context |
| **Config location** | `.cursor/agents/` | `.agents/skills/` |
| **Invocation** | `/name` or auto-delegated | `/name` or auto-detected from description |
| **Examples** | Test runner that loops until green, code verifier | Generate changelog, write test from spec |

**Rule of thumb:** If the task requires multiple steps with feedback loops (implement → test → fix → test again), use a subagent. If it's a one-shot generation task, use a skill.

---

## TEMPLATE

```markdown
---
name: [subagent-name]
description: [What this subagent specializes in and when the parent agent should delegate to it. Be specific about the task type and trigger conditions.]
model: inherit
readonly: false
is_background: false
---

# [Subagent Name]

## Role
[1-2 sentences describing the subagent's expertise and perspective]

## Steps
1. [First action]
2. [Second action]
3. [Third action]

## Output Format
[How the subagent should report results back to the parent agent]
```

---

## Example Subagents

### `verifier` — Validates completed implementations

```markdown
---
name: verifier
description: Validates completed feature implementations. Runs Vitest tests, checks required filters in Prisma queries, verifies input validation, and confirms auth decorators are present. Use after implementing a new service or endpoint.
model: inherit
readonly: true
is_background: false
---

# Verifier

## Steps
1. Run `npx vitest --run --reporter=verbose` and report results
2. Check all new Prisma queries include `firmId` and `deletedAt: null` filters
3. Verify all controller inputs are validated with Zod DTOs
4. Confirm endpoints have `@RequirePermission` decorators
5. Report: what passes, what fails, what is missing

## Output Format
### PASS
[Tests and checks that succeeded]

### FAIL
[Tests that failed — include the error message]

### MISSING
[Required checks not present — firmId filter missing, no Zod validation, etc.]
```

### `test-runner` — Runs tests in a loop until green

```markdown
---
name: test-runner
description: Runs Vitest tests and fixes failures iteratively until all tests pass. Use when implementing a feature from test stubs — it runs tests, identifies failures, fixes them, and repeats until green.
model: inherit
readonly: false
is_background: false
---

# Test Runner

## Steps
1. Run `npx vitest --run --reporter=verbose`
2. If all tests pass, report success and stop
3. If tests fail, identify the root cause and implement the fix
4. Re-run tests and repeat until all pass (up to 5 iterations)
5. If still failing after 5 iterations, report the remaining failures with context

## Output Format
Report final test results and a summary of what was fixed.
```

---

## Tips

- Write focused subagents with a single responsibility — avoid "helper" or "assistant" names
- The `description` is what drives auto-delegation — be specific about trigger conditions
- Use `readonly: true` for verifier/auditor subagents that should never modify files
- Use `is_background: true` for long-running tasks that don't need to block the parent agent
- Version control subagent definitions — they are project knowledge

---

## See a Real-World Example

→ Adapt the examples above to your project's specific tech stack and conventions.

# Template: Claude Code Skill

Skills are commands with more detailed prompt engineering. Technically, skills and commands are both `.md` files in `.claude/commands/`. The difference is in **design**:

- **Command**: Clear step-by-step workflow, specific input/output
- **Skill**: Claude takes on an "expert" role, with a persona, few-shot examples, and deeper analysis

---

## Structure of an Effective Skill

### 1. Role/Persona
Define what role Claude plays → influences how Claude thinks and what it outputs.

### 2. Context
Provide specific context that Claude needs to operate correctly.

### 3. Input Format
Clearly describe what Claude will receive.

### 4. Analysis Steps
Structured analysis steps — especially important for complex skills.

### 5. Output Format
Define the exact output format — can include examples (few-shot).

### 6. Few-shot Example (optional)
Sample input/output — helps Claude understand the expected quality.

---

## TEMPLATE

```markdown
# [Skill Name]

## Role
You are a [specific expert role]. You have expertise in [domain] and a deep understanding of [context].

## Context
[Describe the project context this skill operates in — tech stack, conventions, patterns]

## Input
$ARGUMENTS is [describe input — e.g., "the path to the service file that needs tests"]

## Task
[Describe the overall task — 1-2 sentences]

## Analysis Steps

Before creating output, analyze in this order:

1. **[Analysis step 1]**
   - [Details to consider]
   - [Questions to answer]

2. **[Analysis step 2]**
   - [Details to consider]

3. **[Analysis step 3]**
   - [Details to consider]

## Output Format

### [Section 1]
[Describe section 1 format]

### [Section 2]
[Describe section 2 format]

## Quality Checklist
Before finishing, verify:
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Example

Input: `[example input]`

Expected output:
```
[Example output]
```
```

---

## Tips for Writing Skills

- **Strong persona** — "Senior NestJS engineer with 5 years of RBAC experience" → better output than just "engineer"
- **Few-shot examples** — Provide 1-2 sample outputs, Claude will match the quality
- **Explicit checklist** — List specific quality criteria, Claude will self-verify
- **Don't make it too long** — If the skill prompt exceeds 100 lines, consider splitting into 2 skills
- **Test with edge cases** — Try the skill with "difficult" inputs to check behavior

---

## See a Real-World Example

→ [example-write-test.md](./example-write-test.md)

# Token Optimization for Vibe Coders

For developers who use Claude Code without deep knowledge of the codebase structure. The goal: tell Claude "fix bug in feature X" and have it go straight to the right files — no expensive codebase exploration.

---

## The Problem

When you type a vague prompt, Claude has to figure out where the code lives:

```
You:   "Fix the checkout bug"
Claude: grep -r "checkout" src/  → 47 files
        read 6-7 files to find the right one
        cascade into 4-5 more imports
        → ~12,000 tokens just to understand where to look
```

When Claude already knows the structure:

```
You:   "Fix the checkout bug"
Claude: reads CLAUDE.md → sees "Checkout: src/modules/checkout/"
        reads spec/checkout.md → knows which files matter
        reads checkout.service.ts → fixes bug
        → ~1,200 tokens
```

**One-time setup cost → 90% savings on every future session.**

---

## Solution 1: Feature Map in CLAUDE.md (required, do this first)

Create a `CLAUDE.md` at your project root. The only thing that matters is the feature-to-folder mapping.

```markdown
## Feature Map
Read the corresponding spec file before working on any feature.

| Feature         | Spec                    | Code location               |
|-----------------|-------------------------|-----------------------------|
| Checkout        | @spec/checkout.md       | src/modules/checkout/       |
| Cart            | @spec/cart.md           | src/modules/cart/           |
| Auth / Login    | @spec/auth.md           | src/modules/auth/           |
| Orders          | @spec/orders.md         | src/modules/orders/         |
| Notifications   | @spec/notifications.md  | src/modules/notifications/  |

## Stack
- Framework: NestJS + TypeScript
- Database: PostgreSQL + Prisma
- Tests: Jest — run with: npm test -- --testPathPattern=[module]

## Rules
- Never edit *.repository.ts directly — go through the service layer
- After fixing a bug, always run the relevant test suite
```

**Keep CLAUDE.md short.** It loads on every session. Every line costs tokens repeatedly.  
The `@spec/feature.md` syntax means Claude reads the spec file only when needed — not upfront.

---

## Solution 2: spec/ Folder — One File Per Feature

Create a `spec/` folder at project root. Write one file per feature in plain language — no technical knowledge required.

```
spec/
├── checkout.md
├── cart.md
├── auth.md
├── orders.md
└── notifications.md
```

### Template: spec/checkout.md

```markdown
## Checkout Feature

### What it does
Handles the full purchase flow: validate cart → calculate price → apply discount → create order → charge payment.

### Main files
- checkout.controller.ts  — API endpoints (/checkout, /checkout/confirm)
- checkout.service.ts      — core logic, calls cart + payment modules
- checkout.repository.ts   — database queries (do not edit directly)
- dto/create-checkout.dto  — input validation schema

### Key rules
- Always lock the cart before creating an order (prevents race conditions)
- Payment failure must rollback the order in the same transaction
- Discount codes are validated in checkout.service.ts, not in the controller

### Common bug locations
- Wrong price calculation → checkout.service.ts → calculateTotal()
- Discount not applying → checkout.service.ts → applyDiscount()
- Order not saved → checkout.repository.ts → createOrder()
```

### How Claude uses it

```
You:   "Checkout is broken when applying a discount code"
         ↓
Claude reads CLAUDE.md → sees "Checkout: @spec/checkout.md"
         ↓
Claude reads spec/checkout.md → sees "Discount not applying → applyDiscount()"
         ↓
Claude reads checkout.service.ts → fixes the function
```

No exploration. No cascade reads. Straight to the right place.

---

## Solution 3: .claudeignore — Block Directories Claude Should Never Read

Without this, Claude may accidentally read `node_modules/`, build output, or generated files — thousands of tokens wasted.

Create `.claudeignore` at project root:

```gitignore
node_modules/
dist/
build/
.next/
coverage/
*.lock
*.log
*.generated.ts
prisma/migrations/
public/assets/
.git/
```

This is the highest-impact, lowest-effort setup step. Do it before anything else.

---

## Solution 4: .claude/rules/ — Auto-load Rules by File Path (optional, advanced)

If you want rules to load automatically when Claude edits a specific module — without having to mention the spec file:

```
.claude/rules/
├── checkout.md
├── cart.md
└── auth.md
```

Format for `.claude/rules/checkout.md`:

```markdown
---
paths:
  - "src/modules/checkout/**"
---

## Checkout rules
- checkout.service.ts: core logic — price, discount, order creation
- checkout.repository.ts: DB queries — do not edit directly
- Always lock cart before creating order
- Payment failure → rollback order in same transaction
```

When Claude edits any file matching `src/modules/checkout/**`, this rule file loads automatically. No prompt required from you.

**When to use spec/ vs .claude/rules/:**

| | spec/ folder | .claude/rules/ |
|--|--|--|
| Triggered by | You mention the feature | Claude edits a file in the folder |
| Written in | Plain language, any detail level | Short, behavior-focused rules |
| Best for | Bug reports, new features | Enforcing code patterns automatically |

Both can coexist. Use spec/ for context, rules/ for constraints.

---

## Session Discipline — Free Token Savings

These cost nothing to set up and matter as much as the file structure.

### /clear between tasks

```
Task 1: Fix checkout bug     → done
/clear
Task 2: Add cart feature     → starts with clean context
```

Without `/clear`, every file Claude read for task 1 stays in context and inflates the cost of task 2.

### /compact during long tasks

When context is at 40–60% full, run:

```
/compact "keep: checkout discount bug, fix in applyDiscount(), tests pending"
```

Claude summarizes the conversation, keeping only what you specify.

### Start each session with the feature

```
"Fix the discount bug in checkout. Read spec/checkout.md first."
```

One sentence adds 200 tokens. Saves Claude from searching.

---

## How to Bootstrap (one-time setup)

If you don't know the codebase structure at all, let Claude map it for you in one session:

```
"Explore this repo using a subagent. Find all major features and their 
folder locations. Then write:
1. CLAUDE.md at the root with a feature map
2. A spec/[feature].md file for each feature with its main files and purpose.
Keep each spec file under 30 lines."
```

Claude does one expensive exploration session → writes all the context files → every future session is cheap.

---

## Priority Checklist

| Step | Impact | Effort | Do this |
|------|:------:|:------:|---------|
| Add `.claudeignore` | High | 2 min | First |
| Write `CLAUDE.md` with feature map | High | 10 min | Second |
| Write `spec/` files per feature | High | 20 min | Third |
| Use `/clear` between tasks | High | None | Always |
| Add `.claude/rules/` per module | Medium | 15 min | When needed |
| Include file paths in prompts | High | None | Always |
| Use `/compact` at 40–60% context | Medium | None | During long tasks |

---

## Prompt Patterns for Vibe Coders

```
# Bug fix
"[Feature name] is broken when [describe what happens]. 
Read spec/[feature].md first, then fix it."

# New feature
"Add [description] to [feature name]. 
Read spec/[feature].md first to understand the existing structure."

# Unknown bug
"[Describe the symptom]. I don't know which feature is responsible. 
Read CLAUDE.md to find the right module, then investigate."
```

The explicit "Read spec/[feature].md first" costs 10 tokens and saves Claude from searching.

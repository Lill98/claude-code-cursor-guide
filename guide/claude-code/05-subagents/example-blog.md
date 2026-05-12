# Example: Subagents in Practice for blog-api

Three practical patterns applied to the blog-api project (FastAPI + SQLAlchemy + PostgreSQL + Pydantic v2 + pytest).

---

## Example 1: Security Audit — Fan-out Pattern

Three independent checks run simultaneously. Claude spawns all three subagents at once and waits for all to complete before merging the findings.

**User prompt:**
```
Use 3 parallel Explore subagents to audit blog-api:

Subagent 1 — Missing require_role Dependencies:
  Check every FastAPI router file in app/routers/*.py.
  For each endpoint function (@router.get, @router.post, @router.patch, @router.delete),
  confirm it has Depends(require_role(...)) in its parameters.
  Return the list of endpoints missing require_role.

Subagent 2 — Unsafe Ownership Queries:
  Find all SQLAlchemy update() and delete() calls in app/services/*.py
  that do not include an author_id filter in the where clause.
  Return file path, line number, and the model being updated.

Subagent 3 — Missing Soft Delete Filter:
  Find all db.query(...).filter(...) and db.query(...).all() calls in app/
  that do not include a deleted_at.is_(None) filter.
  Return file path, line number, and model name.

After all 3 complete, merge findings into a security report with file:line references.
```

**What happens:**

```
Main session
  │
  ├─── spawn simultaneously ───▶ Subagent 1: require_role Check
  │                                  reads all router files
  │                                  checks Depends(require_role) on each endpoint
  │                                  returns missing-role list
  │
  ├─── spawn simultaneously ───▶ Subagent 2: Ownership Queries
  │                                  greps update/delete calls in services
  │                                  checks for author_id in where clause
  │                                  returns unsafe-query list
  │
  ├─── spawn simultaneously ───▶ Subagent 3: Soft Delete Filter
  │                                  greps query/filter calls
  │                                  checks for deleted_at.is_(None)
  │                                  returns missing-filter list
  │
  ◀─── waits for all 3 ──────────────────────────────────────────
  │
  └─── merges into security report
```

**Expected output format:**

```markdown
## blog-api Security Audit

### Missing require_role() Dependency (from Subagent 1)
- app/routers/comments.py:34 — DELETE /comments/{id} has no Depends(require_role)
- app/routers/tags.py:18 — POST /tags has no Depends(require_role) (admin-only action exposed)

### Unsafe Ownership Queries (from Subagent 2)
- app/services/post_service.py:67 — db.query(Post).filter(Post.id == post_id).update(...)
  has no author_id check in the filter
  Risk: any authenticated user can overwrite another author's post content

### Missing deleted_at.is_(None) Filter (from Subagent 3)
- app/services/comment_service.py:42 — db.query(Comment).filter(...).all()
  missing deleted_at.is_(None)
  Risk: soft-deleted comments are returned to API consumers

### Summary
- 2 endpoints missing require_role (authentication bypass risk)
- 1 service method missing ownership check (data integrity risk)
- 1 query returning soft-deleted records (data consistency risk)

Recommended immediate action: add author_id ownership check to post_service.py:67 before next deploy.
```

The total wall time is max(subagent 1, 2, 3) — not the sum. All three run concurrently.

---

## Example 2: Writer / Reviewer Pattern

Session A implements a new feature in isolation. Session B opens a completely fresh context to review it — no shared history, no anchoring bias.

### Session A: Implement the "publish post" feature

**User prompt in Session A:**
```
Implement the publish post feature for blog-api.

Requirements:
- Endpoint: PATCH /posts/{post_id}/publish
- Only the post's author or an admin can publish
- The post must currently have status 'draft' — cannot publish an already-published post
- On success: set status to 'published', set published_at=datetime.utcnow(), return the updated post
- On failure:
    404 HTTPException if post not found or soft-deleted (deleted_at is not None)
    403 HTTPException if caller is not the owner (unless role is 'admin')
    409 HTTPException if post is already published

Files to create or modify:
- app/services/post_service.py — add publish_post() method
- app/routers/posts.py — add PATCH /posts/{post_id}/publish endpoint with Depends(require_role("admin", "author"))
- tests/test_post_service.py — add pytest tests for publish_post()
```

Session A produces the implementation. The developer commits or saves the diff.

### Session B: Fresh-context Review

Open a new Claude Code session (or use `/clear` to reset context). Session B has no memory of Session A's thought process — it reviews with clean eyes.

**User prompt in Session B:**
```
Review the implementation of the "publish post" feature in blog-api.
Check the diff or read these files:
- app/services/post_service.py
- app/routers/posts.py
- tests/test_post_service.py

Focus on:
1. Ownership check — does publish_post() verify post.author_id == current_user.id before proceeding?
2. Status transition validation — does the service reject calls when status is already 'published'?
3. Role enforcement — does the router endpoint have Depends(require_role("admin", "author"))? Is reader blocked?
4. Soft delete — does the query include deleted_at.is_(None) so deleted posts cannot be published?
5. HTTP codes — is 403 used for authorization failure and 401 for unauthenticated? Are they confused?
6. Alembic — was a migration added if the schema changed (e.g., published_at column added)?
7. Test coverage — are negative cases tested: wrong author, already-published, non-existent post?

Return structured feedback: CRITICAL / WARNING / SUGGESTION / LGTM.
```

**Why a fresh session matters:**

Session A's context contains the implementation reasoning — it will tend to justify decisions it already made. Session B sees only the output and applies the same critical lens as a human PR reviewer. This combination catches issues that self-review misses.

**Example review output from Session B:**

```markdown
### CRITICAL
- app/services/post_service.py:89 — publish_post() queries Post without deleted_at.is_(None).
  A soft-deleted post can be published via this endpoint.
  Fix: add .filter(Post.deleted_at.is_(None)) to the query.

### WARNING
- tests/test_post_service.py — no test for the case where status is already 'published'.
  The 409 HTTPException path is untested.
  Add: def test_raises_conflict_when_already_published(...)

### SUGGESTION
- Consider extracting the ownership check (post.author_id == current_user.id or current_user.role == "admin")
  into a shared helper (e.g., assert_owner_or_admin) to avoid duplicating this logic
  across publish_post(), update_post(), and delete_post().

### LGTM
- Depends(require_role("admin", "author")) is correctly placed on the router endpoint.
- 403 HTTPException is raised before any DB write when the caller is not the owner.
- The response returns the full updated post schema — consistent with other endpoints.
- Alembic migration added for published_at column.
```

---

## Example 3: Security Audit Skill with `context: fork`

This SKILL.md runs as an Explore subagent automatically when invoked. The `context: fork` field causes Claude Code to create a fresh isolated context — the skill cannot see your current conversation or pollute your main context with file contents.

`.claude/skills/security-audit/SKILL.md`:

```markdown
---
name: security-audit
description: Audit blog-api Python codebase for security issues — missing require_role dependencies, ownership checks, and soft-delete filters. Use when reviewing new endpoints or services.
context: fork
agent: Explore
disable-model-invocation: true
---

# security-audit

## Role
You are a Senior Security Engineer specializing in FastAPI REST API security.
You are running as an isolated Explore subagent with no conversation history.
Your job is to audit the blog-api codebase and return a structured report to the main agent.

## Security Checks

### 1. Role Enforcement
- Run `find app/routers -name "*.py"` to list all router files
- For each router file, read the file and check every route function
  (@router.get, @router.post, @router.patch, @router.delete) for a
  Depends(require_role(...)) parameter
- Flag any route function that is missing require_role

### 2. Ownership Checks
- Run `grep -rn "\.update\|\.delete" app/services --include="*.py"`
- For each match, read the surrounding context (±10 lines)
- Flag any update or delete call whose filter does not include `author_id`
- Note: admin bypass is acceptable — flag only if there is no role check at all

### 3. Soft Delete Filter
- Run `grep -rn "db\.query\|\.filter\|\.all()" app/services --include="*.py"`
- For each query, check whether the filter chain includes `deleted_at.is_(None)`
- Flag any query missing this filter

### 4. Hard Delete Detection
- Run `grep -rn "db\.delete\b" app/services --include="*.py"`
- Flag any direct db.delete() call — all deletes must set deleted_at, not remove the row

## Steps

1. Run `find app/routers -name "*.py"` — collect router list
2. Read each router file, check require_role on every endpoint
3. Run ownership grep, read context around each match
4. Run query grep, check deleted_at.is_(None) on each
5. Run delete grep, flag any hard deletes

## Output Format

Return this structure to the main agent:

### CRITICAL
[Issues that can lead to unauthorized access or data corruption — fix before deploy]

### WARNING
[Issues that weaken security posture — fix this sprint]

### INFO
[Minor gaps — low priority]

### SUMMARY
Total: X critical, Y warnings, Z info items.
Highest risk area: [module name]
Recommended immediate action: [one sentence]
```

**Usage:**
```
/security-audit
```

Claude spawns an Explore subagent in a forked context, it runs all four checks across the codebase, and returns the structured report to your main session. Your conversation history stays clean — none of the file reads accumulate in your working context.

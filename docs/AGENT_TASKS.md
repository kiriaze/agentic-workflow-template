# AGENT_TASKS.md

Live implementation spec. The Orchestrator writes tasks here; Implementers (Codex, Claude Sonnet subagents) execute against them.

**Not** the same as `HANDOFF.md` — that tracks session continuity for Claude Code (where did I leave off).  
This file tracks **active implementation work** that has been scoped, planned, and is ready to hand to an implementer agent.

---

## How to use this file

**Orchestrator:** When a plan is approved, add a task block below using the template. Include exact files, acceptance criteria, and skill rules. Delete the block when the task is merged.

**Implementer:** Read your assigned task block. Follow the spec exactly. Report back with files touched and any open questions. Never modify other agents' task blocks.

**Reviewer:** Read the original task block + the diff. Verify acceptance criteria are met. Flag any spec deviations.

---

## Active Tasks

_No active tasks. See next steps in HANDOFF.md._

<!-- retired active tasks below -->

---

## Task Template

````markdown
### TASK-[N]: [Short title]

**Status:** `ready` | `in-progress` | `review` | `done`  
**Assigned to:** Codex | claude-sonnet-4-6 | unassigned  
**Branch:** `feat/short-description`

#### Spec

[What to build and why — 2-4 sentences. Link to the relevant planning-template.md section if applicable.]

#### Files to touch

- `src/path/to/file.ts` — [what changes]
- `src/path/to/other.ts` — [what changes]

#### Do NOT touch

- `src/lib/providers/` — prompt caching must be preserved
- [other protected files/dirs]

#### Implementation guidelines

> Codex cannot invoke Claude Code skills. Inline equivalents are listed here.
> Items marked **[CC review]** are run by Claude Code during diff review — Codex does not need to handle them.

- [ ] **Simplify** — after implementation, remove unnecessary abstractions, dead code, and overly clever patterns. Prefer the simplest code that satisfies the spec.
- [ ] **TDD** (if applicable) — write the failing test first, then implement until it passes.
- [ ] **Supabase** (if applicable) — use RLS, parameterised queries, `ON CONFLICT DO NOTHING` for idempotent inserts. No raw SQL in app code.
- [ ] **security-review** [CC review] — Claude Code runs this during diff review for any auth, API key, or route changes.
- [ ] **impeccable:audit** [CC review] — Claude Code runs this for any significant UI changes.

#### Acceptance criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] `npx tsc --noEmit` passes
- [ ] `npm run lint` passes

#### Notes / open questions

[Any constraints, edge cases, or questions the implementer should be aware of.]

#### Setup steps

Run before touching any files.

```bash
git fetch origin
git checkout main && git pull origin main
git checkout -b [branch-name]
```
````

> Untracked files are not branch-specific — stage and commit as you work, not only at the end.

#### Completion steps

Run after all acceptance criteria pass.

```bash
git add [only the files listed above]
git commit -m "[type]: [description under 72 chars]"
git push origin [branch-name]
```

Then output:

```
TASK COMPLETE
Branch: [branch-name]
Commits: [SHA] [subject]
Files changed: [list]
Manual steps remaining: [e.g. run migration in Supabase SQL editor]
Open questions: [any spec deviations or edge cases]
```

```

---

## Completed Tasks (last 5)

```

# AGENT_TASKS.md

Live task registry. Orchestrator adds rows here when a task is scoped and ready; Implementers read the spec file linked in the Spec column.

**Not** the same as `HANDOFF.md` — that tracks session continuity for Claude Code.
This file tracks **active implementation work** ready to hand to an implementer agent.

---

## How to use this file

**Orchestrator:** When a plan is approved, add one row to Active Tasks and create a spec file in `docs/tasks/TASK-NNN.md` using the template at the bottom of this file.

**Implementer:** Read the spec file linked in your row. Follow it exactly. Report back with files touched and any open questions.

**Reviewer:** Read the original spec file + the diff. Verify acceptance criteria are met.

**On task completion (merged):**

1. Delete the row from Active Tasks.
2. Add one row to Completed Tasks (include the PR number).
3. Delete the spec file from `docs/tasks/`. The PR and commit history are the permanent record.

**Changing only a Status field is not completion. The row must be gone from Active Tasks.**

---

## Active Tasks

| Task | Title | Status | Assigned to | Branch | Task type | Spec |
|------|-------|--------|-------------|--------|-----------|------|

_No active tasks. See next steps in HANDOFF.md._

---

## Completed Tasks

| Task | Title | PR | Merged |
|------|-------|----|--------|

---

## Task template

Create `docs/tasks/TASK-NNN.md` with this structure, then add one row to Active Tasks above.

```markdown
# TASK-NNN: [Short title]

**Status:** `ready` | `in-progress` | `review`
**Assigned to:** `claude-sonnet-4-6` | `codex` | `unassigned`
**Branch:** `feat/short-description`
**Task type:** `architecture` | `security_review` | `ui_visual` | `docs_config` | `implementation` | `research`

## Spec

[What to build and why — 2–4 sentences.]

## Files to touch

- `src/path/to/file.ts` — [what changes]

## Do NOT touch

- [protected files/dirs]

## Implementation guidelines

- [ ] Invoke relevant skills before starting (see AGENTS.md § Agent Skill Rules)
- [ ] ...

## Acceptance criteria

- [ ] [Criterion]
- [ ] Type-check passes
- [ ] Lint passes
- [ ] All tests pass

## Setup steps

\`\`\`bash
git fetch origin
git checkout main && git pull origin main
git checkout -b [branch-name]
\`\`\`

## Completion steps

\`\`\`bash
git add [only the files listed above]
git commit -m "[type]: [description under 72 chars]"   # no AI attribution
git push origin [branch-name]
\`\`\`

Then post:
\`\`\`
TASK COMPLETE
Branch: [branch-name]
Commits: [SHA] [subject]
Files changed: [list]
Open questions: [any spec deviations or edge cases]
\`\`\`
```

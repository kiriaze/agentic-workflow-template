# Planning Template

Use this format for every implementation plan before handing off to an Implementer agent.
The Orchestrator writes this. The Implementer receives it as their complete context.

For a filled-in example, see `docs/plans/example-plan.md`.

---

## Plan: [Short title]

**Type:** `feat` | `fix` | `refactor` | `chore`
**Branch:** `feat/short-description` | `fix/short-description`
**Task type:** `architecture` | `security_review` | `ui_visual` | `docs_config` | `implementation` | `research`
**Touches:** [number] files
**Estimated complexity:** Low | Medium | High

---

### Context

> Why does this work need to happen? What problem does it solve or what capability does it add?
> 2–4 sentences max. The implementer needs the "why", not a full history.

---

### Scope

**Files to touch** (absolute paths):
```
src/path/to/file-a.ts       — [what changes here]
src/path/to/file-b.tsx      — [what changes here]
```

**Do NOT touch:**
- `src/path/to/sensitive-file.ts` — [reason]
- Any file not listed above without confirming first

---

### Implementation Notes

> Specific technical guidance the implementer needs. Not a full spec — just the things that
> aren't obvious from reading the files. Include: relevant types, patterns to follow,
> patterns to avoid, known edge cases, and which existing code to model after.

- [Note 1]
- [Note 2]

---

### Implementation Guidelines

Check off each skill that applies to this task. Full trigger conditions: `AGENTS.md` § Agent Skill Rules.

- [ ] `test-driven-development` — write failing test before fix/feature
- [ ] `vercel-react-best-practices` — new page, layout, route, or data-fetching hook
- [ ] `vercel-composition-patterns` — new reusable component (2+ uses) or 3+ boolean props
- [ ] `frontend-design-system` — building or significantly modifying a UI component
- [ ] `security-review` [CC review] — auth, API key, rate limiting, or API routes
- [ ] `impeccable:audit` [CC review] — significant UI component (new page, major layout)
- [ ] `simplify` [CC reviewer runs post-diff; implementer does not invoke]

---

### Acceptance Criteria

The task is done when ALL of the following are true:

- [ ] [Specific functional criterion — what the code must do]
- [ ] [Specific functional criterion]
- [ ] `npx tsc --noEmit` — no type errors
- [ ] `npm run lint` — no lint errors
- [ ] `npm test` — all tests pass
- [ ] No regressions in [specific related areas to manually verify]

---

### Out of Scope

> Explicitly list related things that are tempting to fix but should NOT be done in this task.
> Prevents scope creep and keeps the diff reviewable.

- [Thing 1 — address separately in TASK-N]
- [Thing 2]

---

### Open Questions

> Things the Implementer should flag before proceeding if unclear, rather than guessing.

- [Question 1]

---

### Setup steps

```bash
git fetch origin
git checkout main && git pull origin main
git checkout -b [branch-name]
```

> **Important:** Untracked files are not branch-specific in git — they appear on every branch
> until committed. Stage and commit to the task branch as you work, not only at the end.

### Completion steps

```bash
git add [only the files listed in "Files to touch"]
git commit -m "[type]: [description under 72 chars]"   # no AI attribution
git push origin [branch-name]
```

Then output a summary so Claude Code can review:

```
TASK COMPLETE
Branch: [branch-name]
Commits: [short SHA] [subject]
Files changed: [list]
Open questions: [any spec deviations or edge cases found]
```

# Planning Template

Use this format for every implementation plan before handing off to an Implementer agent.
The Orchestrator writes this. The Implementer receives it as their complete context.

---

## Plan: [Short title]

**Type:** `feat` | `fix` | `refactor` | `chore`
**Branch:** `feat/short-description` | `fix/short-description`
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
src/path/to/file-c.ts       — [what changes here]
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
- [Note 3]

---

### Implementation Guidelines

> **If assigned to Codex:** Codex cannot invoke Claude Code skills. Use the inline equivalents
> below. Items marked **[CC review]** are run by Claude Code during diff review.
>
> **If assigned to Claude Code:** invoke the skill directly via the Skill tool.

| Guideline | Codex (inline) | CC (skill) |
|---|---|---|
| Simplify | Remove dead code, unnecessary abstractions, prefer simple over clever | `simplify` |
| TDD | Write failing test first, implement until green | `test-driven-development` |
| Supabase | RLS, parameterised queries, idempotent inserts | `supabase` + `supabase-postgres-best-practices` |
| Claude API | Preserve prompt caching; check adapters pattern | `claude-api` |
| New page/route | Follow App Router data-fetching patterns | `vercel-react-best-practices` |
| New component (2+ uses) | Avoid boolean prop proliferation, use composition | `vercel-composition-patterns` |
| UI markup | Check `.impeccable.md` tokens before writing | `frontend-design-system` |
| Design brief | Read `.impeccable.md`; describe intent in spec | `impeccable:shape` |
| Security [CC review] | — | `security-review` |
| UI audit [CC review] | — | `impeccable:audit` |
| Harden [CC review] | — | `impeccable:harden` |

**Checked boxes for this task:**

- [ ] Simplify
- [ ] TDD
- [ ] Supabase
- [ ] Claude API
- [ ] New page/route
- [ ] New component
- [ ] UI markup / design brief
- [ ] Security [CC review]
- [ ] UI audit [CC review]

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
> This prevents scope creep and keeps the diff reviewable.

- [Thing 1 — address separately in issue/task X]
- [Thing 2]

---

### Open Questions

> Things the Implementer should flag before proceeding if unclear, rather than guessing.

- [Question 1]
- [Question 2]

---

### Setup steps

Run these before touching any files. Do not skip.

```bash
git fetch origin
git checkout main && git pull origin main   # start from a clean, up-to-date main
git checkout -b [branch-name]               # create and switch to the task branch immediately
```

> **Important:** Untracked files are not branch-specific in git — they appear on every branch
> until committed. Stage and commit to the task branch as you work, not only at the end.

### Completion steps

Run these after all acceptance criteria pass.

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
Manual steps remaining: [e.g. run migration in Supabase SQL editor]
Open questions: [any spec deviations or edge cases found]
```

---

## Example (filled in)

**Plan: Add cursor-based pagination to /api/reviews**

**Type:** `feat`
**Branch:** `feat/reviews-pagination`
**Touches:** 3 files
**Estimated complexity:** Medium

### Context

`/api/reviews` is currently hardcoded to `LIMIT 100`. Large accounts will hit this ceiling
as saved reviews accumulate. This adds cursor-based pagination so the dashboard can load
reviews incrementally rather than all at once.

### Scope

**Files to touch:**
```
src/app/api/reviews/route.ts          — add cursor param, update query, return nextCursor
src/hooks/useResumeReview.ts          — update fetch logic to support nextCursor
src/components/dashboard/DashboardView.tsx — add "load more" trigger
```

**Do NOT touch:**
- `src/lib/supabase/server.ts` — shared utility, changes need separate review
- Review card components — layout is not in scope

### Implementation Notes

- Use `created_at` + `id` as the cursor (stable sort, handles ties). Return as
  `nextCursor: string` (base64-encoded JSON `{ created_at, id }`).
- The Supabase query should use `.lt('created_at', cursor.created_at)` or
  `.lt('id', cursor.id)` when created_at ties. Page size: 20.
- Model the hook change after `useUserSettings` — same pattern for async state.
- `DashboardView` should use an intersection observer for the "load more" trigger,
  not a button, to match the existing scroll behavior.

### Skill Rules for This Task

- [x] `test-driven-development` — cursor encoding/decoding logic needs unit tests
- [x] `supabase` + `supabase-postgres-best-practices` — query change
- [x] `simplify` — run after done

### Acceptance Criteria

- [ ] Reviews load in pages of 20; scrolling to the bottom triggers the next page
- [ ] First page loads with no cursor; subsequent pages pass the cursor correctly
- [ ] Empty state shows correctly when all reviews are loaded
- [ ] `npx tsc --noEmit` — clean
- [ ] `npm run lint` — clean
- [ ] `npm test` — all pass; cursor encode/decode has coverage

### Out of Scope

- Search or filtering on the reviews list (separate task)
- Changing the review card layout

### Open Questions

- Should the initial page size be 20 or configurable? (default 20, flag later if needed)

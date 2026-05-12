# Example Plan (filled in)

> This is a filled-in example of `docs/plans/planning-template.md`.

---

## Plan: Add cursor-based pagination to /api/reviews

**Type:** `feat`
**Branch:** `feat/reviews-pagination`
**Task type:** `implementation`
**Touches:** 3 files
**Estimated complexity:** Medium

---

### Context

`/api/reviews` is currently hardcoded to `LIMIT 100`. Large accounts will hit this ceiling
as saved reviews accumulate. This adds cursor-based pagination so the dashboard can load
reviews incrementally rather than all at once.

---

### Scope

**Files to touch:**
```
src/app/api/reviews/route.ts              — add cursor param, update query, return nextCursor
src/hooks/useResumeReview.ts              — update fetch logic to support nextCursor
src/components/dashboard/DashboardView.tsx — add "load more" trigger
```

**Do NOT touch:**
- `src/lib/supabase/server.ts` — shared utility, changes need separate review
- Review card components — layout is not in scope

---

### Implementation Notes

- Use `created_at` + `id` as the cursor (stable sort, handles ties). Return as
  `nextCursor: string` (base64-encoded JSON `{ created_at, id }`).
- The query should use `.lt('created_at', cursor.created_at)` or `.lt('id', cursor.id)`
  when `created_at` ties. Page size: 20.
- Model the hook change after `useUserSettings` — same pattern for async state.
- `DashboardView` should use an intersection observer for the "load more" trigger,
  not a button, to match the existing scroll behavior.

---

### Implementation Guidelines

- [x] `test-driven-development` — cursor encoding/decoding logic needs unit tests
- [x] `simplify` [CC reviewer runs post-diff]

---

### Acceptance Criteria

- [ ] Reviews load in pages of 20; scrolling to the bottom triggers the next page
- [ ] First page loads with no cursor; subsequent pages pass the cursor correctly
- [ ] Empty state shows correctly when all reviews are loaded
- [ ] `npx tsc --noEmit` — clean
- [ ] `npm run lint` — clean
- [ ] `npm test` — all pass; cursor encode/decode has coverage

---

### Out of Scope

- Search or filtering on the reviews list (separate task)
- Changing the review card layout

---

### Open Questions

- Should the initial page size be 20 or configurable? (default 20, flag later if needed)

---

### Setup steps

```bash
git fetch origin
git checkout main && git pull origin main
git checkout -b feat/reviews-pagination
```

### Completion steps

```bash
git add src/app/api/reviews/route.ts src/hooks/useResumeReview.ts src/components/dashboard/DashboardView.tsx
git commit -m "feat(reviews): add cursor-based pagination"
git push origin feat/reviews-pagination
```

Then post:
```
TASK COMPLETE
Branch: feat/reviews-pagination
Commits: abc1234 feat(reviews): add cursor-based pagination
Files changed: src/app/api/reviews/route.ts, src/hooks/useResumeReview.ts, src/components/dashboard/DashboardView.tsx
Open questions: none
```

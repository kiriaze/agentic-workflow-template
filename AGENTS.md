# AGENTS.md

Single source of truth for all agents and AI tools working in this repository.
Claude Code reads this via `CLAUDE.md`. OpenAI Codex and other agents read it directly.

> **Non-Claude Code agents:** where this file references `@docs/filename.md`, read that
> file directly for the full content.

---

## Commands

```bash
npm run dev      # Next.js dev server with Turbopack
npm run build    # Production build
npm run lint     # ESLint
npm test         # Vitest unit tests
npx tsc --noEmit # Type-check without emitting
```

---

## Architecture

**Stack:** ...

Key files: ...

@docs/architecture.md

---

## Environment Variables

Required: ``.

@docs/environment.md

---

## Conventions

- **No `any`**, named exports only, extract repeated logic to hooks/utils, no new state libraries.
- **shadcn/ui first**, Tailwind only, 4pt spacing scale, `@/*` path alias.
- Design context lives in `.impeccable.md` — read it before any significant UI work.

@docs/conventions.md

---

## Workflow

- **Plan before implementing** — for any change touching more than ~3 files, map all touch points before writing code.
- **Type-check before committing** — run `npx tsc --noEmit`. Fix all errors; never suppress with `@ts-ignore` without a comment explaining why.
- **Lint before committing** — run `npm run lint`.
- **Tests before committing** — run `npm test`. All tests must pass.
- **Commit per logical unit** — don't batch unrelated changes. One feature or fix per commit.
- **Conventional commits** — prefix with `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`. Subject line ≤ 72 characters.
- **Never add AI attribution** — no `Co-Authored-By`, AI signatures, or any AI attribution in commits or PRs.
- **Update HANDOFF.md** at ~50-60% context window before `/clear`. Refresh current task, next steps, known issues, recent decisions. Compress oldest session log entry if more than 3 exist.

### Bug fix validation rule

**"Fixed" means tests prove it.** Never mark a bug as resolved without a test that would catch a regression.

1. Write the failing test _first_ — before touching production code. If you can't write a failing test, explain why in the PR and describe the alternative validation performed.
2. The test name must make the failure case obvious (e.g. `preserves jdFit from meta block in assembled review`, not `test1`).
3. Run the full test suite after fixing to confirm the fix doesn't break anything else.
4. In the PR description, name the test(s) added and what scenario they guard.

This rule exists because bugs marked "fixed" without tests have repeatedly re-emerged. A fix without a test is a hypothesis, not a proof.

### Validation evidence & PR requirements

Every PR must include evidence appropriate to the change type. There is no `.github/PULL_REQUEST_TEMPLATE.md` — these requirements are enforced here and in `docs/workflow.md`.

| Change type                 | Required evidence in PR body                                         |
| --------------------------- | -------------------------------------------------------------------- |
| **Bug fix**                 | Name of the test(s) added; one-line description of what each catches |
| **UI/visual change**        | Before screenshot + after screenshot (CC: use `preview_screenshot`)  |
| **New feature (UI)**        | Screenshot or screen recording of the golden path; edge cases noted  |
| **New feature (API/logic)** | Test names + example request/response or log output                  |
| **Refactor**                | "Behaviour unchanged" — tests pass count before and after            |
| **Docs/config**             | No media required; describe what changed and why                     |

**For UI changes, CC must:**

1. Start a preview server before and after the change.
2. Capture `preview_screenshot` for both states.
3. Paste both screenshots into the PR body with `Before:` / `After:` labels.
4. If the change requires interaction (click flow, form, animation), describe the steps to reproduce or record a Loom and link it.

**Codex cannot capture screenshots.** CC performs screenshot capture during the review phase for all Codex-implemented UI tasks before opening or approving a PR.

## Effort Level Discipline

Default effort: **`high`** — applies to all implementation, debugging, and review tasks.

Escalate to **`xhigh`** only for:

- Architectural decisions affecting ≥5 files or introducing new abstractions
- Cross-cutting bugs where the root cause is unknown and requires deep reasoning
- Security-critical analysis (auth flows, key handling, RLS policies)

Do **not** use `xhigh` for: single-file edits, routine refactors, UI changes, documentation, or any task with a clear and narrow scope. Extended thinking on routine work burns tokens without improving output quality.

---

## Project Init (First Pass)

Run when setting up a fresh environment, onboarding, or when project state is unknown.

1. **Pull fresh:** `git fetch origin && git pull origin main`
2. **Check `.impeccable.md`** — if missing, invoke `impeccable teach` before any UI work. All impeccable skills require this file; without it their output is generic and project-unaware.
3. **Check `DESIGN.md`** — if missing, run `impeccable document` to generate from existing tokens (recommended before significant UI work).
4. **Read `HANDOFF.md`** — current task, next steps, known issues.
5. **Invoke `using-superpowers`** — establish skill awareness for the session.

---

## Agent Skill Rules

These rules are **prescriptive**. Apply them based on context automatically — do not wait to be asked.

### Session start

**On your FIRST response of any session, do all of the following automatically — without waiting to be asked:**

1. Invoke `using-superpowers` via the Skill tool.
2. The `UserPromptSubmit` hook has already injected HANDOFF.md and AGENT_TASKS.md into context. Acknowledge the current task and next steps from HANDOFF.md.
3. Report any `ready` or `in-progress` tasks from AGENT_TASKS.md.
4. State what you propose to do next and wait for confirmation before acting.

Before any UI/design work: confirm `.impeccable.md` exists. If not, invoke `impeccable teach` first.

### Planning & design

- New feature or component identified → invoke `impeccable:shape` before writing code (task-scoped design brief). `using-superpowers` loads the session; `impeccable:shape` designs the specific thing.
- Open-ended brainstorm → stay in conversation until something concrete emerges, then invoke `impeccable:shape`.
- Task touches more than ~3 files → map all touch points and confirm the plan before writing code.

### Implementation

**Invoke `test-driven-development` when:**

- Implementing a new API route or hook
- Fixing a bug — write the failing test _before_ the fix
- Building complex logic: scoring, parsing, state machines, data transforms
- Working in an unfamiliar area before modifying it

**Skip TDD for:** UI/visual changes, simple refactors with no logic change, trivial single-file edits, rapid prototyping.

**Other triggers:**

- `src/lib/providers/` or `@anthropic-ai/sdk` imports → invoke `claude-api` (prompt caching must be preserved)
- New Next.js page, layout, route, or data-fetching hook → invoke `vercel-react-best-practices`
- New reusable component (2+ uses) or component with 3+ boolean props → invoke `vercel-composition-patterns`
- Building or significantly modifying a UI component → invoke `frontend-design-system`
- Any Supabase work (schema, queries, RLS, auth, migrations) → invoke `supabase` + `supabase-postgres-best-practices`

### Post-implementation

- After any non-trivial code change → invoke `simplify`
- After a significant UI component (new page, complex widget, major layout) → invoke `impeccable:audit`
- Before shipping any user-facing feature → invoke `impeccable:harden`
- Auth, API key handling, rate limiting, or API route changes → invoke `security-review`

### Deployment

This project is hosted on Vercel — invoke `deploy-to-vercel`.

---

## Multi-Agent Rules

| Role             | Claude Code                 | Codex          | Does                                                                       |
| ---------------- | --------------------------- | -------------- | -------------------------------------------------------------------------- |
| **Orchestrator** | `claude-opus-4-7`           | `gpt-5.5`      | Plans, decomposes, delegates, reviews diffs. Never writes production code. |
| **Implementer**  | `claude-sonnet-4-6`         | `gpt-5.4`      | Executes a focused spec. Runs in a worktree.                               |
| **Reviewer**     | `claude-sonnet-4-6`         | `gpt-5.4`      | Checks diff vs spec, runs quality gates.                                   |
| **Researcher**   | `claude-haiku-4-5-20251001` | `gpt-5.4-mini` | Read-only exploration. Never modifies files.                               |

**Key rules:**

- Every agent that modifies files uses `isolation: "worktree"`. No exceptions.
- Orchestrator has approved plan with independent tasks → invoke `subagent-driven-development`.
- Implementation complete + quality gates pass → invoke `finishing-a-development-branch`.
- Agents do not merge into main. Human reviews, approves, and merges.
- Every session starts with `git fetch origin && git pull origin main`.

Full detail — roles, worktrees, handoff protocol, git workflow, parallel work:
@docs/multi-agent.md

---

## Docs

| File                        | Contents                                                                     |
| --------------------------- | ---------------------------------------------------------------------------- |
| `docs/workflow.md`          | **Start here** — how human, CC, and Codex work together end-to-end           |
| `docs/architecture.md`      | Full architecture: providers, API routes, hooks, prompts, auth, flags        |
| `docs/conventions.md`       | Coding + UI/design conventions in full, design context pointer               |
| `docs/environment.md`       | All environment variables with descriptions                                  |
| `docs/multi-agent.md`       | Worktrees, handoff protocol, git workflow, parallel work, Codex token limits |
| `docs/planning-template.md` | Canonical plan format for Orchestrator → Implementer handoff                 |
| `docs/AGENT_TASKS.md`       | Live implementation spec — Orchestrator writes, Codex/Implementers execute   |

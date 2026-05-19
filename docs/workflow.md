# Workflow Guide

How the human engineer, Claude Code (CC), and Codex work together in this codebase — from idea to shipped feature.

---

## The Three-Actor Model

| Actor | Tool | Strengths | Does NOT |
|---|---|---|---|
| **Human** | You | Context, taste, final decisions | Write boilerplate |
| **Claude Code** | Interactive CLI session | Planning, design, review, orchestration, debugging, UX judgment | Run unattended jobs |
| **Codex** | OpenAI Codex (background agent) | Isolated implementation of scoped specs | Plan, design, merge to main |

CC is your primary collaborator. Codex is a specialized implementer — it receives a precise spec and executes it in isolation.

> **Role flexibility:** Either CC or Codex can fill any role — `docs/agent-roster.json` defines model assignments for all roles on both platforms. The table above reflects the *recommended* defaults. CC makes the better orchestrator in practice: it has hooks, browser access, and interactive back-and-forth. Codex excels as an unattended implementer. Adjust `agent-roster.json` when your setup differs.

---

## End-to-End Workflow

```mermaid
flowchart TD
    A([💡 Idea / Bug / Request]) --> B{Scope?}

    B -->|Single file or trivial| C[CC: implement directly]
    B -->|>3 files or new feature| D[CC: shape + plan]

    D --> E[impeccable:shape — design brief]
    E --> F[CC: map all touch points, confirm plan]
    F --> G{Parallel tasks?}

    G -->|Yes| H[CC: write AGENT_TASKS.md spec]
    G -->|No, CC handles| C

    H --> I[subagent-driven-development]
    I --> J[Codex: implement in worktree branch]
    J --> K[Codex: tsc + lint + tests pass]
    K --> L[CC: review diff vs spec]
    L --> M{Passes review?}

    M -->|No — fix needed| J
    M -->|Yes| N[finishing-a-development-branch]

    C --> O[CC: tsc + lint + tests]
    O --> N

    N --> P[Human: review PR on GitHub]
    P --> Q[Human: merge + delete branch]
    Q --> R([✅ Shipped])
```

---

## Workflow Phases

### 1. Ideation
- Discuss freely with CC — no tooling needed.
- For open-ended brainstorming, CC stays conversational until something concrete emerges.
- For feature requests from users, log to [features page](/features) or the chosen feedback tool.

### 2. Design (UI/UX work)
- CC invokes `impeccable:shape` (or an equivalent design brief) to produce a task-scoped brief before writing any code.
- Design constraints live in `PRODUCT.md` and `DESIGN.md` — run `impeccable teach` (or equivalent) once per project to generate them. If `impeccable` is unavailable, write a short design brief manually before starting UI code.
- Do not write UI code before a design brief is produced; output is generic without it.

### 3. Planning
- For any change touching >3 files, CC maps all touch points and confirms with you before acting.
- The canonical plan format is `docs/plans/planning-template.md`.
- Once a plan is approved, CC writes the spec into `docs/AGENT_TASKS.md` and creates `docs/tasks/TASK-NNN.md`.

### 4. Implementation

**CC handles directly when:**
- Single-file or simple multi-file edits
- Bug fixes, refactors, configuration
- UI/visual changes
- Anything requiring real-time judgment or back-and-forth

**Codex handles when:**
- Task is fully specced in AGENT_TASKS.md (exact files, acceptance criteria)
- Work is independent (no active CC context required)
- Multiple parallel tasks exist

CC invokes `subagent-driven-development` to dispatch Codex tasks. Each Codex session runs in an isolated git worktree (separate branch), so parallel work can't conflict.

### 5. Review & Validation Evidence

Quality gates (mandatory for all PRs):
- `npx tsc --noEmit` — clean
- `npm run lint` — clean
- `npm test` — all pass

**Automated enforcement:** Once your stack is chosen, create `.scripts/quality-gates.sh` with your project's lint/typecheck/test commands. The pre-commit hook runs it automatically on every commit — quality gates become enforced, not just instructed. Example:

```sh
#!/bin/sh
npm run lint && npx tsc --noEmit && npm test
```

Make it executable: `chmod +x .scripts/quality-gates.sh`. AI will create this file during scaffold adaptation (TASK-000) or when you ask it to once your stack is known.

Skill invocations (as applicable):
- CC runs `simplify`, `security-review`, and `impeccable:audit` where appropriate.
- Codex output: CC reviews the diff against the spec before a PR is opened.

**Validation evidence in the PR body is required — not optional.** The goal: anyone can open the PR and know in under 30 seconds what changed, that it works, and what would break if it regressed.

| Change type | Evidence required |
|---|---|
| Bug fix | Test name(s) added; one-line description of what each catches |
| UI/visual change | Before + after `preview_screenshot` with `Before:` / `After:` labels |
| New feature (UI) | Screenshot or Loom of the golden path; edge cases noted |
| New feature (API/logic) | Test names + example request/response or log output |
| Refactor | "Behaviour unchanged" — test pass count before and after |
| Docs/config | What changed and why; no media required |

**Bug fix rule — "fixed" means tests prove it:**
1. Write the failing test *before* the fix. If you can't, explain why in the PR.
2. Run the full suite after fixing to confirm no regressions.
3. Name the added test(s) in the PR body.

**UI screenshot workflow (CC):**
1. `preview_start` → capture `preview_screenshot` of the *current* state (before).
2. Make the change, reload, capture `preview_screenshot` of the *after* state.
3. Paste both into the PR body with `Before:` / `After:` labels.
4. For interaction flows (click, form, animation): describe reproduction steps or link a Loom.

**Codex note:** Codex has no browser access. CC performs all screenshot capture during the review phase for Codex-implemented UI tasks. This is a non-negotiable step before opening a PR for any Codex task that touches the UI.

### 6. Ship
- CC (or Codex) opens a PR via `gh pr create`.
- **Human reviews, approves, and merges on GitHub.** Neither CC nor Codex merges to main.
- Branch is deleted on merge.

---

## Automatic vs Manual

### Automatic (CC does without being asked)
| Trigger | CC action |
|---|---|
| Session start | Invoke `using-superpowers`, read HANDOFF.md, report AGENT_TASKS.md status |
| UI/design work | Check `PRODUCT.md` + `DESIGN.md`, invoke `impeccable:shape` before coding |
| New feature >3 files | Map touch points, confirm plan |
| `src/lib/providers/` touched | Invoke `claude-api` (preserves prompt caching) |
| New Next.js page/route | Invoke `vercel-react-best-practices` |
| New reusable component | Invoke `vercel-composition-patterns` |
| Supabase work | Invoke `supabase` + `supabase-postgres-best-practices` |
| After non-trivial code change | Invoke `simplify` |
| After significant UI component | Invoke `impeccable:audit` |
| Auth/API route changes | Invoke `security-review` |
| ~50-60% context window | Update HANDOFF.md, then you run `/clear` |

### Manual (requires your action)
| Task | Why manual |
|---|---|
| Merge PRs | Human judgment; agents never touch main |
| Supabase migrations | Run in Supabase dashboard SQL editor |
| Deploy to production | `vercel deploy` or Vercel CI on merge |
| Feature tooling decisions (Canny, Frill, etc.) | Product judgment |
| `.env.local` changes | Security boundary |
| Approve architectural changes | Human owns the roadmap |

---

## Session Lifecycle

```mermaid
sequenceDiagram
    participant H as Human
    participant CC as Claude Code
    participant GH as GitHub

    H->>CC: Start session ("What's next?" or task)
    CC->>CC: Read HANDOFF.md + AGENT_TASKS.md
    CC->>H: Report current state, propose next action
    H->>CC: Confirm / redirect
    CC->>CC: Implement + quality gates
    CC->>GH: Push branch + open PR (if needed)
    H->>GH: Review + merge PR

    Note over H,CC: ~50-60% context window
    CC->>CC: Update HANDOFF.md (current task, next steps, decisions)
    H->>CC: /clear
    H->>CC: Start next session ("Read HANDOFF.md and continue")
```

**Key rule:** CC updates HANDOFF.md before context runs out. This is the only state that persists across `/clear`. If HANDOFF.md is stale, the next session starts blind.

---

## File Ownership Map

| File | Updated by | When | How to regenerate |
|---|---|---|---|
| `HANDOFF.md` | CC (auto) | Before every `/clear`; after milestones | N/A — CC always maintains it |
| `docs/AGENT_TASKS.md` | CC (auto) | On task state changes | N/A |
| `docs/environment.md` | CC (auto) | In same commit as new env vars | Ask Claude: "update environment.md from the codebase" |
| `docs/architecture.md` | Human or AI | After structural changes | Ask Claude: "read the codebase and fill in architecture.md" |
| `docs/conventions.md` | Human or AI | After stack is chosen or changes | Ask Claude: "update conventions.md for [stack]" |
| `AGENTS.md` | Human | After setup.sh; when workflow changes | Review `[fill in]` placeholders; AI can suggest updates |
| `PRODUCT.md` / `DESIGN.md` | Skill | Once per project; re-run if brand changes | `impeccable teach` (or equivalent design brief tool) |
| `docs/agent-roster.json` | Human | When new model versions ship | Edit directly |
| `.scripts/quality-gates.sh` | Human or AI | Created once stack is chosen | Ask Claude: "create quality-gates.sh for [stack]" |
| `docs/tasks/TASK-NNN.md` | CC (auto) | Created per approved plan; deleted on merge | N/A |
| `docs/workflow.md` | Human | When workflow changes | Update manually; AI can propose edits |
| `docs/multi-agent.md` | Human | When multi-agent rules change | Update manually |
| `CLAUDE.md` | Human | Rarely — CC entry point only | N/A — loads AGENTS.md via @reference |

---

## When to Use Codex vs CC

```mermaid
flowchart TD
    A{Is the task fully specced?} -->|No| B[Stay in CC — discuss and plan first]
    A -->|Yes| C{Does it need real-time judgment?}
    C -->|Yes — design, debugging, review| B
    C -->|No — pure implementation| D{Is the scope narrow?}
    D -->|Yes, 1-3 files, clear acceptance criteria| E[Either works — CC is faster for small tasks]
    D -->|Yes, multiple independent parallel tasks| F[Codex — use subagent-driven-development]
    D -->|No, too large| G[Break it into smaller task blocks first]
```

**Rule of thumb:** If you can write the spec in 10 minutes and it has clear acceptance criteria, it's ready for Codex. If it requires taste, iteration, or context from this conversation, keep it in CC.

---

## Keeping This System in Sync

**When anything in the workflow changes** (new skill added, file renamed, convention updated, tool deprecated):

1. Update the relevant `docs/` file.
2. Update `AGENTS.md` if the change affects agent behavior.
3. Update this file if the change affects how humans and agents interface.
4. Update `HANDOFF.md` to note the change in the current session's decisions.

CC is responsible for flagging when docs are stale and proposing updates as part of normal work. Never let a session end with undocumented architectural or workflow decisions.

**AI-updatable docs:** `docs/architecture.md`, `docs/conventions.md`, and `docs/environment.md` are stubs at scaffold time. They can be regenerated on demand — ask Claude to read the codebase and update them. Do this after choosing a stack, adding a major library, or onboarding to an existing project. See the File Ownership Map above for regeneration commands.

---

## Quick Reference: Key Commands

```bash
# Dev
# [fill in] dev server
# [fill in] build
# [fill in] lint
# [fill in] test
# [fill in] type-check

# Git
git fetch origin && git pull origin main   # Always pull fresh before starting
gh pr create --title "..." --body "..."    # Open a PR (CC does this; human merges)

# Context management
/clear               # Start fresh session (update HANDOFF.md first)
```

# Multi-Agent Rules

## Roles and model assignments

> Model assignments, effort overrides, and task-type routing are defined in **`docs/agent-roster.json`** — the single source of truth. Never hardcode model names elsewhere.

| Role | Responsibilities |
|---|---|
| **Orchestrator** | Plans, decomposes tasks, writes implementer specs, delegates work, reviews final diffs. Does not write production code directly. |
| **Implementer** | Writes code per spec. Receives a focused prompt: exact files to touch, what to change, what to preserve, which skill rules apply. |
| **Reviewer** | Checks diff against spec. Runs type-check + lint + tests. Invokes `simplify` and `security-review` where applicable. |
| **Researcher** | Read-only — codebase exploration, file lookups, web research. Returns findings to orchestrator. Never modifies files. |

### Model selection at runtime

At session start, read `docs/agent-roster.json`.

When spawning any subagent, resolve the model in this order:
1. Does the task have an explicit `task_type`? → use `routing.task_type_overrides[task_type]`
2. Does the task spec declare an effort level? → apply `routing.effort_overrides[role][effort]`
3. Fall back to `roles[role]` default.

If provider is CC: use the `cc` field. If Codex: use the `codex` field.

**Task type labels** (set in `AGENT_TASKS.md` per task row):
`architecture` | `security_review` | `ui_visual` | `docs_config` | `implementation` (default) | `research`

When a new model version ships, update **`docs/agent-roster.json`** only — all other files reference it.

---

## Worktree guidelines

- Use `isolation: "worktree"` for **every agent that modifies files**. No exceptions.
- Do **not** use worktrees for read-only agents (Researcher, Explore). They run in the main tree.
- The Orchestrator stays in the main tree and coordinates.
- Each Implementer runs in its own worktree (isolated branch), preventing conflicts on parallel work.
- Worktrees are auto-cleaned if the agent makes no changes.
- After an Implementer completes, the Orchestrator reviews the diff before any PR is opened.

---

## Handoff protocol

**Orchestrator → Implementer prompt must include:**
- Exact files to touch (absolute paths)
- What to change and why
- What **not** to change
- Which skill rules apply (TDD? security-review? supabase?)
- Acceptance criteria — how to know the task is done correctly

Use `docs/plans/planning-template.md` as the canonical format for writing plans before handing off to implementers. Once a plan is approved, add one row to `docs/AGENT_TASKS.md` and create `docs/tasks/TASK-NNN.md` — that is the live spec Codex and subagent Implementers execute against.

**Implementer → completion handoff must include:**
- Summary of changes made
- Files touched
- Any open questions or edge cases discovered

The **Reviewer** receives: original spec + diff — not the full conversation history.

---

## Skill invocations during execution

- When the Orchestrator has an approved plan with independent tasks → invoke `subagent-driven-development`. This dispatches each task to a fresh implementer subagent with two-stage review (spec compliance first, then code quality). Do not attempt to manually orchestrate what this skill handles.
- When implementation is complete and all quality gates pass → invoke `finishing-a-development-branch`. This runs final verification, presents merge/PR options, and handles branch cleanup. Do not manually replicate this flow.

---

## Git workflow

Agents follow this workflow on every task automatically.

**1. Before starting any work — pull fresh:**
```bash
git fetch origin
git pull origin main
```

**2. Work in an isolated branch (via worktree):**
```
feat/short-description   # new features
fix/short-description    # bug fixes
chore/short-description  # non-code changes
```

**3. Commit when the task is complete and validated:**
- `npx tsc --noEmit` — clean
- `npm run lint` — clean
- `npm test` — all pass
- Conventional commit, subject ≤ 72 characters
- No AI attribution

**4. Push branch and open a PR:**
```bash
git push origin <branch-name>
gh pr create --title "<conventional title>" --body "<summary + test plan>"
```

**5. Agents do not merge into main. A human reviews, approves, and merges.**

**6. Exception — trivial changes** (typo, config value, single-line non-logic edit, docs):
Commit directly to main and push immediately. No branch or PR needed.

**7. After human merges:** next agent session starts by pulling fresh from main (step 1).

---

## Parallel agent work

When the Orchestrator spawns multiple Implementers in parallel:
- Each gets its own worktree and uniquely named branch to avoid collision
- The Orchestrator opens a separate PR per branch
- PRs are merged in dependency order if there are dependencies; independent PRs can merge in any order

---

## Codex session limits and task scoping

**Token ceiling:** Codex sessions double in cost above 272K input tokens. Keep sessions under this boundary.

**Practical ceiling:** Target ≤220K tokens per Codex session (`.codex/config.toml` warns at this threshold). This leaves headroom for the model's own output and any tool call payloads.

**How to scope tasks for Codex:**
- One task block in `docs/AGENT_TASKS.md` = one Codex session. If a task block would pull in more than 3-4 large files of context, split it.
- Do **not** give Codex open-ended exploration prompts. The Orchestrator does exploration (Researcher role); Codex receives a precise spec with exact file paths.
- Avoid loading the full `docs/` folder into context unless all of it is genuinely needed. Point Codex to the specific files in its task block.
- If a task requires reading many files before writing, have the Researcher agent pre-summarize and include the summary in the task spec rather than making Codex re-read everything.

**`AGENT_TASKS.md` is the Codex entry point.** Each task block is self-contained: files to touch, what to change, what not to touch, acceptance criteria. Codex should need nothing outside the task block + the files listed in it.

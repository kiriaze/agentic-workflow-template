# Multi-Agent Rules

## Roles and model assignments

| Role | Claude Code model | Codex model | Responsibilities |
|---|---|---|---|
| **Orchestrator** | `claude-opus-4-7` | `gpt-5.5` | Plans, decomposes tasks, writes implementer specs, delegates work, reviews final diffs. Does not write production code directly. |
| **Implementer** | `claude-sonnet-4-6` | `gpt-5.4` | Writes code per spec. Receives a focused prompt: exact files to touch, what to change, what to preserve, which skill rules apply. |
| **Reviewer** | `claude-sonnet-4-6` | `gpt-5.4` | Checks diff against spec. Runs type-check + lint + tests. Invokes `simplify` and `security-review` where applicable. |
| **Researcher** | `claude-haiku-4-5-20251001` | `gpt-5.4-mini` | Read-only — codebase exploration, file lookups, web research. Returns findings to orchestrator. Never modifies files. |

### Model alias vs. pinned — what you need to know

**Claude Code:**
- `claude-opus-4-7` — pinned to Opus 4.7. Prefer this over the bare `claude-opus-4` alias so orchestration behavior doesn't drift when Anthropic releases Opus 4.8+. Update deliberately.
- `claude-sonnet-4-6` — pinned. Stable for implementation and review.
- `claude-haiku-4-5-20251001` — pinned. Prefer this over `claude-haiku-4`; the alias resolves to the latest stable Haiku 4.x which may change.

**Codex (OpenAI):**
- `gpt-5.5` — most capable; use for orchestration and architectural reasoning.
- `gpt-5.4` — strong code generation; use for implementation and review.
- `gpt-5.4-mini` — fast and lightweight; use for read-only research and exploration.

When a new model version ships, update the pinned IDs here and in `.codex/config.toml` together so the two files stay in sync.

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

Use `docs/planning-template.md` as the canonical format for writing plans before handing off to implementers. Once a plan is approved, write the task into `docs/AGENT_TASKS.md` — that is the live spec Codex and subagent Implementers execute against.

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

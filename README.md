# Agentic Workflow Template

A universal scaffold for AI-agent-driven development. Sets up the full multi-agent workflow — Claude Code, Codex, and any agent that reads `AGENTS.md` — in under a minute.

## What it sets up

| File / Dir | Purpose |
|---|---|
| `AGENTS.md` | Behavioral contract for all agents: rules, skill triggers, workflow, multi-agent roles |
| `CLAUDE.md` | Claude Code entry point — loads `AGENTS.md` via `@` reference |
| `PRODUCT.md` | Design context stub: product purpose, visual direction, tone, accessibility baseline |
| `HANDOFF.md` | Session continuity: current task, next steps, known issues, environment state, session log |
| `.scripts/` | Shared hook scripts used by both `.claude/` and `.codex/`: session-start, branch protection, auto-lint |
| `.claude/` | Permissions and hook wiring (hooks call `.scripts/`); worktrees |
| `.git-hooks/` | Conventional commit enforcement + blocks `src/` commits directly on `main` |
| `.github/` | PR template: Summary, Evidence table, quality gate checklist |
| `.codex/` | Codex config: model assignment, approval mode, context includes, token budget; hooks mirroring `.claude/settings.json` |
| `docs/` | Architecture, conventions, environment, multi-agent rules, planning templates, workflow guide, task specs |
| `docs/agent-roster.json` | Single source of truth for model assignments by role, effort level, and task type |
| `docs/plans/` | `planning-template.md` + filled-in `example-plan.md` for Orchestrator → Implementer handoffs |
| `docs/tasks/` | One spec file per active task (`TASK-NNN.md`); deleted on merge — PR history is the record |
| `.gitignore` | Sane defaults — created only if missing, never overwritten |

## Usage

```bash
# New project under ~/Localhost/
./setup.sh my-app

# Explicit path
./setup.sh ~/Code/my-app
./setup.sh ./my-app

# Current directory (existing project)
./setup.sh .
```

Existing scaffold-managed files are backed up as `*.bak.TIMESTAMP` before being overwritten — nothing is silently lost.

## After setup

**Upgrading an existing project?** `setup.sh` automatically creates `docs/tasks/TASK-000-adapt-scaffold.md` when it detects backed-up files. On your first Claude Code session the session-start hook injects it — Claude reads the backups, fills in all `[fill in]` placeholders, and reports what was migrated vs what still needs manual input. No copy/paste required.

**Fresh project:**

1. `cd <project-dir>` and open Claude Code
2. The session-start hook automatically injects `HANDOFF.md` + active tasks on your first prompt
3. Run `git config core.hooksPath .git-hooks` if you didn't use `setup.sh` (the script does this automatically)
4. Fill in the `[fill in]` placeholders in `AGENTS.md` (commands, stack-specific skill triggers, deployment) — or ask Claude to do it based on your stack
5. Once your stack is scaffolded, ask Claude to update `docs/architecture.md`, `docs/conventions.md`, and `docs/environment.md` from the codebase — these are AI-updatable on demand at any time, not just at setup
6. For UI/design work: run `impeccable teach` (or equivalent) to generate full `PRODUCT.md` and `DESIGN.md`
7. Commit: `git add -A && git commit -m 'chore: initial scaffold'`

**Upgrading (step 0 ran):** steps 4–5 above are handled by Claude automatically. Review the migration report, fill any gaps, then run `impeccable teach` (or equivalent) if `PRODUCT.md` needs a full refresh.

## Stack-agnostic by design

`AGENTS.md` ships with typed placeholders for commands, conventions, skill triggers, and deployment target. No stack decisions are forced at scaffold time — populate them once you know what you're building.

## What's not included

- **Skills** — live globally in `~/.claude/skills/`. Shared across all projects; not copied per-project.
- **Global Claude settings** — `~/.claude/settings.json` governs global permissions. Never touched by this script.
- **`settings.local.json`** — project-specific command allowlists accumulate here as you work; not scaffolded.

## Optional skill integrations

This template references several Claude Code skills. None are required — the system degrades gracefully without them. Install what fits your workflow.

| Skill | What it provides | If unavailable |
|---|---|---|
| `impeccable` | Design brief (`impeccable:shape`), UI audit, harden; generates `PRODUCT.md` + `DESIGN.md` | Write a short design brief manually before UI code; stub or skip `PRODUCT.md`/`DESIGN.md` |
| `using-superpowers` | Establishes skill awareness at session start | Skip — CC proceeds without it |
| `subagent-driven-development` | Dispatches parallel implementation tasks to Implementer agents | Manually spawn each implementer agent per task |
| `finishing-a-development-branch` | Final verification + PR options after implementation | Run quality gates manually; open PR with `gh pr create` |
| `simplify` | Post-implementation code quality pass | Ask inline: "review this diff for unnecessary complexity" |

Skills live in `~/.claude/skills/` and are shared across all your projects. To add one, copy the skill file there.

## Repo structure

```
setup.sh                          ← Scaffold script
AGENTS.md                         ← Master agent rulebook (behavioral contract)
CLAUDE.md                         ← CC entry point (@AGENTS.md)
PRODUCT.md                        ← Design context stub (fill in or run impeccable teach)
HANDOFF.md                        ← Session continuity template
.claude/
  settings.json                   ← Permissions + hook wiring (calls .scripts/)
.git-hooks/
  pre-commit                      ← Blocks src/ commits on main/master
  commit-msg                      ← Enforces conventional commit format
.github/
  PULL_REQUEST_TEMPLATE.md        ← Evidence table + quality gate checklist
.scripts/
  session-start.sh              ← Injects HANDOFF.md + active tasks (shared by CC and Codex)
  check-branch.sh               ← Blocks src/ writes on main (shared by CC and Codex)
  auto-lint.sh                  ← Auto-lint on .ts/.tsx edits (shared by CC and Codex)
.codex/
  config.toml                     ← Codex model, approval mode, context includes, token limit
  hooks.json                      ← Codex hook wiring (calls .scripts/)
docs/
  workflow.md                     ← How human, CC, and Codex work together end-to-end
  architecture.md                 ← Stack, routes, hooks (fill in per project)
  conventions.md                  ← Coding and UI conventions (fill in per project)
  environment.md                  ← Environment variables (fill in per project)
  multi-agent.md                  ← Worktrees, model selection, handoff protocol, git workflow
  agent-roster.json               ← Model assignments by role, effort, and task type
  AGENT_TASKS.md                  ← Live task registry with active/completed rows
  plans/
    planning-template.md          ← Orchestrator → Implementer handoff format
    example-plan.md               ← Filled-in example plan
  tasks/                          ← Individual task spec files (TASK-NNN.md); empty at scaffold time
```

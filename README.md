# Agentic Workflow Template

A universal scaffold for AI-agent-driven development. Sets up the full multi-agent workflow — Claude Code, Codex, and any agent that reads `AGENTS.md` — in under a minute.

## What it sets up

| File / Dir | Purpose |
|---|---|
| `AGENTS.md` | Behavioral contract for all agents: rules, skill triggers, workflow, multi-agent roles |
| `CLAUDE.md` | Claude Code entry point — loads `AGENTS.md` via `@` reference |
| `PRODUCT.md` | Design context stub: product purpose, visual direction, tone, accessibility baseline |
| `HANDOFF.md` | Session continuity: current task, next steps, known issues, environment state, session log |
| `.claude/` | Session-start hook (auto-injects `HANDOFF.md` + active tasks on first prompt), branch-protection hook, permissions |
| `.git-hooks/` | Conventional commit enforcement + blocks `src/` commits directly on `main` |
| `.github/` | PR template: Summary, Evidence table, quality gate checklist |
| `.codex/` | Codex config: model assignment, approval mode, context includes, token budget |
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
4. Fill in the `[fill in]` placeholders in `AGENTS.md` (commands, stack-specific skill triggers, deployment)
5. Fill in `docs/architecture.md` and `docs/environment.md`
6. For UI/design work: run `/impeccable teach` to generate full `PRODUCT.md` and `DESIGN.md`
7. Commit: `git add -A && git commit -m 'chore: initial scaffold'`

**Upgrading (step 0 ran):** steps 4–5 above are handled by Claude automatically. Review the migration report, fill any gaps, then run `/impeccable teach` if `PRODUCT.md` needs a full refresh.

## Stack-agnostic by design

`AGENTS.md` ships with typed placeholders for commands, conventions, skill triggers, and deployment target. No stack decisions are forced at scaffold time — populate them once you know what you're building.

## What's not included

- **Skills** — live globally in `~/.claude/skills/`. Shared across all projects; not copied per-project.
- **Global Claude settings** — `~/.claude/settings.json` governs global permissions. Never touched by this script.
- **`settings.local.json`** — project-specific command allowlists accumulate here as you work; not scaffolded.

## Repo structure

```
setup.sh                          ← Scaffold script
AGENTS.md                         ← Master agent rulebook (behavioral contract)
CLAUDE.md                         ← CC entry point (@AGENTS.md)
PRODUCT.md                        ← Design context stub (fill in or run impeccable teach)
HANDOFF.md                        ← Session continuity template
.claude/
  settings.json                   ← Permissions + hooks (PreToolUse, UserPromptSubmit, PostToolUse)
  scripts/
    session-start.sh              ← Injects HANDOFF.md + active tasks on first prompt per hour
    check-branch.sh               ← Blocks src/ writes on main before git hooks fire
.git-hooks/
  pre-commit                      ← Blocks src/ commits on main/master
  commit-msg                      ← Enforces conventional commit format
.github/
  PULL_REQUEST_TEMPLATE.md        ← Evidence table + quality gate checklist
.codex/
  config.toml                     ← Codex model, approval mode, context includes, token limit
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

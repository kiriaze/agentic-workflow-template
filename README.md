# Agentic Workflow Template

A universal scaffold for AI-agent-driven development. Sets up the full multi-agent workflow — Claude Code, Codex, and any agent that reads `AGENTS.md` — in under a minute.

## What it sets up

| File / Dir | Purpose |
|---|---|
| `AGENTS.md` | Behavioral contract for all agents: rules, skill triggers, workflow, multi-agent roles |
| `CLAUDE.md` | Claude Code entry point — loads `AGENTS.md` via `@` reference |
| `.claude/` | Session-start hook (auto-injects `HANDOFF.md` + active tasks on every prompt), permissions, settings |
| `.codex/` | Codex config: model assignment, approval mode, context includes, token budget |
| `HANDOFF.md` | Session continuity: current task, next steps, known issues, session log |
| `docs/` | Architecture, conventions, environment, multi-agent rules, planning template, workflow, task specs |
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

If existing scaffold-managed files are detected, you'll get a 5-second warning before anything is touched. All overwritten files are backed up to `.scaffold-backups/TIMESTAMP/` — nothing is silently lost.

## After setup

1. `cd <project-dir>` and open Claude Code
2. The session-start hook automatically injects context on your first prompt
3. Describe what you're building — the AI fills in the `[fill in]` placeholders in `AGENTS.md` and `docs/` once your stack is known
4. For UI/design work: run `/impeccable teach` to generate `PRODUCT.md` and `DESIGN.md`
5. Commit the scaffold: `git add -A && git commit -m 'chore: initial scaffold'`

## Stack-agnostic by design

`AGENTS.md` ships with typed placeholders for commands, conventions, skill triggers, and deployment target. No stack decisions are forced at scaffold time — the AI populates these once you know what you're building.

## What's not included

- **Skills** — live globally in `~/.claude/skills/` (symlinked from `~/.agents/skills/`). Shared across all projects; not copied per-project.
- **Global Claude settings** — `~/.claude/settings.json` governs effort level, token limits, and global permissions. Never touched by this script.

## Repo structure

```
setup.sh                ← Scaffold script
AGENTS.md               ← Master agent rulebook (the system)
CLAUDE.md               ← CC entry point (@AGENTS.md)
HANDOFF.md              ← Session continuity template
docs/
  workflow.md           ← How human, CC, and Codex work together
  architecture.md       ← Stack, routes, hooks, auth (fill in per project)
  conventions.md        ← Coding and UI conventions (fill in per project)
  environment.md        ← Environment variables (fill in per project)
  multi-agent.md        ← Worktrees, handoff protocol, git workflow
  planning-template.md  ← Orchestrator → Implementer handoff format
  AGENT_TASKS.md        ← Live task specs for Codex/Implementers
.claude/
  settings.json         ← Permissions + hooks
  scripts/
    session-start.sh    ← Injects HANDOFF.md + active tasks on prompt
.codex/
  config.toml           ← Codex model, approval, context, token limit
```

## Future

**`--update` mode** — sync an existing project's system rules to the latest template version without overwriting project-specific files (`HANDOFF.md`, `docs/architecture.md`, `docs/environment.md`, `docs/AGENT_TASKS.md`). The backup mechanism from option A applies here too — back up everything, replace system rules, let the user cherry-pick from backups. Not yet implemented.

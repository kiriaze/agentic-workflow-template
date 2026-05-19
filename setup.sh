#!/usr/bin/env bash
# setup.sh — scaffold a project with the full Agentic Workflow Template
#
# Usage:
#   ./setup.sh <project-name-or-path>
#
# Examples:
#   ./setup.sh my-new-app
#   ./setup.sh ~/Localhost/my-new-app
#   ./setup.sh ~/Code/my-new-app
#   ./setup.sh ./my-new-app
#   ./setup.sh .
#
# Behavior:
#   - Bare names like "my-new-app" create projects under:
#       ${AI_PROJECTS_DIR:-$HOME/Localhost}
#   - Explicit paths like "~/Code/my-new-app", "./my-new-app", or "." are used directly.
#   - Template/source files are read from the directory containing this setup.sh.
#   - Existing scaffold-managed files are backed up before being overwritten.

set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
PROJECT_ARG="${1:-}"
DEFAULT_PROJECT_ROOT="${AI_PROJECTS_DIR:-$HOME/Localhost}"

if [[ -z "$PROJECT_ARG" ]]; then
  echo "Usage: $0 <project-name-or-path>"
  echo ""
  echo "Examples:"
  echo "  $0 my-new-app"
  echo "  $0 ~/Localhost/my-new-app"
  echo "  $0 ~/Code/my-new-app"
  echo "  $0 ./my-new-app"
  echo "  $0 ."
  echo ""
  echo "Default root for bare project names: $DEFAULT_PROJECT_ROOT"
  echo "Override with:"
  echo "  AI_PROJECTS_DIR=~/Code $0 my-new-app"
  exit 1
fi

# Expand leading ~ manually because quoted shell args do not expand it.
case "$PROJECT_ARG" in
  "~")
    PROJECT_ARG="$HOME"
    ;;
  "~/"*)
    PROJECT_ARG="$HOME/${PROJECT_ARG#~/}"
    ;;
esac

# Treat explicit paths as paths.
# Treat plain names like "my-app" as projects under DEFAULT_PROJECT_ROOT.
if [[ "$PROJECT_ARG" == "." || \
      "$PROJECT_ARG" == ".." || \
      "$PROJECT_ARG" == ./* || \
      "$PROJECT_ARG" == ../* || \
      "$PROJECT_ARG" == /* || \
      "$PROJECT_ARG" == */* ]]; then
  PROJECT_PATH="$PROJECT_ARG"
else
  PROJECT_PATH="$DEFAULT_PROJECT_ROOT/$PROJECT_ARG"
fi

# Resolve project directory.
# If it exists, resolve the actual path.
# If it does not exist, resolve/create its parent and append basename.
if [[ -d "$PROJECT_PATH" ]]; then
  PROJECT_DIR="$(cd -- "$PROJECT_PATH" && pwd -P)"
  PROJECT_NAME="$(basename -- "$PROJECT_DIR")"
else
  PROJECT_PARENT="$(mkdir -p -- "$(dirname -- "$PROJECT_PATH")" && cd -- "$(dirname -- "$PROJECT_PATH")" && pwd -P)"
  PROJECT_NAME="$(basename -- "$PROJECT_PATH")"
  PROJECT_DIR="$PROJECT_PARENT/$PROJECT_NAME"
fi

# Template files live beside this setup.sh script.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TEMPLATE_DIR="$SCRIPT_DIR"

# Prevent accidentally scaffolding the template directory itself.
if [[ "$PROJECT_DIR" == "$TEMPLATE_DIR" ]]; then
  echo "Error: refusing to scaffold the template directory itself:"
  echo "  $PROJECT_DIR"
  echo ""
  echo "Run this from a target project directory with:"
  echo "  $0 ."
  echo ""
  echo "Or create a new project with:"
  echo "  $0 my-new-app"
  exit 1
fi

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${BLUE}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}!${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*"; }

# ── Backup helpers ────────────────────────────────────────────────────────────
BACKUP_STAMP="$(date +%Y%m%d%H%M%S)"
BACKUP_DIR=".scaffold-backups/${BACKUP_STAMP}"

backup_existing() {
  local path="$1"

  if [[ -e "$path" || -L "$path" ]]; then
    local dest="${BACKUP_DIR}/${path}"
    mkdir -p -- "$(dirname -- "$dest")"
    cp -a "$path" "$dest"
    warn "Backed up: $path → $dest"
  fi
}

detect_existing_scaffold_files() {
  local existing=()
  local check=(
    AGENTS.md CLAUDE.md HANDOFF.md
    .scripts .claude .codex
    docs/architecture.md docs/conventions.md docs/environment.md
    docs/multi-agent.md docs/planning-template.md docs/workflow.md docs/AGENT_TASKS.md
  )

  for p in "${check[@]}"; do
    [[ -e "$p" ]] && existing+=("$p")
  done

  if [[ ${#existing[@]} -gt 0 ]]; then
    warn "Existing scaffold-managed files detected:"
    for p in "${existing[@]}"; do
      echo "    $p"
    done
    echo ""
    info "All will be backed up to ${BACKUP_DIR}/ before overwrite."
    info "Press Ctrl-C to abort, or wait 5 seconds to continue..."
    sleep 5
    echo ""
  fi
}

copy_with_backup() {
  local src="$1"
  local dest="$2"

  mkdir -p -- "$(dirname -- "$dest")"
  backup_existing "$dest"
  rm -rf -- "$dest"
  cp -a "$src" "$dest"
}

copy_with_project_name_replacement() {
  local src="$1"
  local dest="$2"

  mkdir -p -- "$(dirname -- "$dest")"
  backup_existing "$dest"

  local replacement="$PROJECT_NAME"
  replacement="${replacement//\\/\\\\}"
  replacement="${replacement//&/\\&}"
  replacement="${replacement//|/\\|}"

  sed "s|PROJECT_NAME|$replacement|g" "$src" > "$dest"
}

# ── Create project dir ────────────────────────────────────────────────────────
if [[ -e "$PROJECT_DIR" && ! -d "$PROJECT_DIR" ]]; then
  error "Target exists but is not a directory: $PROJECT_DIR"
  exit 1
fi

info "Scaffolding project: $PROJECT_DIR"
mkdir -p -- "$PROJECT_DIR"
cd "$PROJECT_DIR"

detect_existing_scaffold_files

# ── Git init ──────────────────────────────────────────────────────────────────
if [[ ! -d .git ]]; then
  git init
  success "Initialized git repository"
else
  warn "Git already initialized, skipping"
fi

# ── .claude/ static assets ────────────────────────────────────────────────────
mkdir -p .claude

copy_claude_static_assets() {
  local src_dir="$TEMPLATE_DIR/.claude"

  if [[ ! -d "$src_dir" ]]; then
    warn "Template .claude/ directory not found at $src_dir, continuing with generated Claude config"
    return 0
  fi

  shopt -s dotglob nullglob

  for src in "$src_dir"/*; do
    local name
    name="$(basename -- "$src")"

    case "$name" in
      .DS_Store)
        continue
        ;;

      .session-*)
        continue
        ;;

      skills)
        # Skills are global; do not copy or symlink them into each project.
        continue
        ;;

      *)
        copy_with_backup "$src" ".claude/$name"
        success "Copied .claude/$name"
        ;;
    esac
  done

  shopt -u dotglob nullglob
}

copy_claude_static_assets

# ── CLAUDE.md ────────────────────────────────────────────────────────────────
if [[ -f "$TEMPLATE_DIR/CLAUDE.md" ]]; then
  copy_with_backup "$TEMPLATE_DIR/CLAUDE.md" "CLAUDE.md"
  success "Copied CLAUDE.md from setup template"
else
  backup_existing "CLAUDE.md"
  echo '@AGENTS.md' > CLAUDE.md
  success "Created CLAUDE.md"
fi

# ── AGENTS.md ────────────────────────────────────────────────────────────────
if [[ -f "$TEMPLATE_DIR/AGENTS.md" ]]; then
  copy_with_backup "$TEMPLATE_DIR/AGENTS.md" "AGENTS.md"
  success "Copied AGENTS.md from setup template"
else
  warn "Template AGENTS.md not found at $TEMPLATE_DIR/AGENTS.md — creating stub"
  backup_existing "AGENTS.md"

  cat > AGENTS.md <<'MD'
# AGENTS.md

Single source of truth for all agents and AI tools working in this repository.
Claude Code reads this via `CLAUDE.md`. OpenAI Codex and other agents read it directly.

> **Non-Claude Code agents:** where this file references `@docs/filename.md`, read that
> file directly for the full content.

---

## Commands

```bash
npm run dev      # Dev server
npm run build    # Production build
npm run lint     # ESLint
npm test         # Tests
npx tsc --noEmit # Type-check
````

## Architecture

@docs/architecture.md

## Conventions

@docs/conventions.md

## Workflow

* Plan before implementing (>3 files → map touch points first)
* Type-check + lint before committing
* Conventional commits (`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`)
* Never add AI attribution

## Effort Level Discipline

Default: **`high`**. Escalate to `xhigh` only for architectural decisions, unknown-root cross-cutting bugs, or security-critical analysis.

@docs/multi-agent.md
MD

success "Created AGENTS.md stub"
fi

# ── docs/ ────────────────────────────────────────────────────────────────────

mkdir -p docs

DOC_FILES=(
architecture.md
conventions.md
environment.md
multi-agent.md
workflow.md
AGENT_TASKS.md
agent-roster.json
)

for f in "${DOC_FILES[@]}"; do
if [[ -f "$TEMPLATE_DIR/docs/$f" ]]; then
copy_with_backup "$TEMPLATE_DIR/docs/$f" "docs/$f"
success "Copied docs/$f"
else
warn "Template docs/$f not found, skipping"
fi
done

# ── docs/plans/ ───────────────────────────────────────────────────────────────

mkdir -p docs/plans

for f in planning-template.md example-plan.md; do
if [[ -f "$TEMPLATE_DIR/docs/plans/$f" ]]; then
copy_with_backup "$TEMPLATE_DIR/docs/plans/$f" "docs/plans/$f"
success "Copied docs/plans/$f"
else
warn "Template docs/plans/$f not found, skipping"
fi
done

# ── docs/tasks/ ───────────────────────────────────────────────────────────────

mkdir -p docs/tasks
if [[ ! -f docs/tasks/.gitkeep ]]; then
touch docs/tasks/.gitkeep
success "Created docs/tasks/.gitkeep"
fi

# ── .git-hooks/ ──────────────────────────────────────────────────────────────

if [[ -d "$TEMPLATE_DIR/.git-hooks" ]]; then
  mkdir -p .git-hooks
  for hook_src in "$TEMPLATE_DIR/.git-hooks"/*; do
    hook_name="$(basename -- "$hook_src")"
    copy_with_backup "$hook_src" ".git-hooks/$hook_name"
    chmod +x ".git-hooks/$hook_name"
    success "Copied .git-hooks/$hook_name"
  done
  git config core.hooksPath .git-hooks
  success "Set core.hooksPath to .git-hooks"
else
  warn "Template .git-hooks/ not found, skipping"
fi

# ── .github/ ──────────────────────────────────────────────────────────────────

if [[ -d "$TEMPLATE_DIR/.github" ]]; then
  mkdir -p .github
  for gh_src in "$TEMPLATE_DIR/.github"/*; do
    gh_name="$(basename -- "$gh_src")"
    copy_with_backup "$gh_src" ".github/$gh_name"
    success "Copied .github/$gh_name"
  done
else
  warn "Template .github/ not found, skipping"
fi

# ── .codex/ config ────────────────────────────────────────────────────────────

mkdir -p .codex

if [[ -f "$TEMPLATE_DIR/.codex/config.toml" ]]; then
  copy_with_project_name_replacement "$TEMPLATE_DIR/.codex/config.toml" ".codex/config.toml"
  success "Copied .codex/config.toml"
else
  warn "Template .codex/config.toml not found, skipping"
fi

if [[ -f "$TEMPLATE_DIR/.codex/hooks.json" ]]; then
  copy_with_backup "$TEMPLATE_DIR/.codex/hooks.json" ".codex/hooks.json"
  success "Copied .codex/hooks.json"
else
  warn "Template .codex/hooks.json not found, skipping"
fi

# ── .scripts/ shared hooks ────────────────────────────────────────────────────
# Shared by both .claude/settings.json and .codex/hooks.json

if [[ -d "$TEMPLATE_DIR/.scripts" ]]; then
  mkdir -p .scripts
  for script_src in "$TEMPLATE_DIR/.scripts"/*; do
    [[ "$(basename -- "$script_src")" == .session-* ]] && continue
    script_name="$(basename -- "$script_src")"
    copy_with_backup "$script_src" ".scripts/$script_name"
    [[ "$script_src" == *.sh ]] && chmod +x ".scripts/$script_name"
    success "Copied .scripts/$script_name"
  done
else
  warn "Template .scripts/ not found, skipping"
fi

# ── HANDOFF.md ────────────────────────────────────────────────────────────────

if [[ -f "$TEMPLATE_DIR/HANDOFF.md" ]]; then
copy_with_project_name_replacement "$TEMPLATE_DIR/HANDOFF.md" "HANDOFF.md"
success "Copied HANDOFF.md from setup template"
else
backup_existing "HANDOFF.md"

cat > HANDOFF.md <<MD
# HANDOFF.md

## Current task

*Project just initialized. No active task.*

## Next steps (priority order)

1. Run \`impeccable teach\` to generate \`PRODUCT.md\` and \`DESIGN.md\` design context
2. Fill in \`docs/architecture.md\` with the tech stack and project structure
3. Fill in \`docs/environment.md\` with environment variables
4. Fill in the Commands section of \`AGENTS.md\`

## Known issues

None.

## Environment state

*[Fill in: deployed services, external accounts, credentials that agents need context on — e.g. "Cloudflare Worker deployed at https://...", "Supabase project: <name>"]*

## Recent decisions

- Project scaffolded with setup.sh

## Session log

### $(date '+%Y-%m-%d') — Init

- Initialized project with AI agent workflow scaffold

*Keep the 3 most recent sessions; compress older entries into a single summary line.*
MD

success "Created HANDOFF.md"
fi

# ── PRODUCT.md ────────────────────────────────────────────────────────────────

if [[ -f "$TEMPLATE_DIR/PRODUCT.md" ]]; then
  copy_with_backup "$TEMPLATE_DIR/PRODUCT.md" "PRODUCT.md"
  success "Copied PRODUCT.md stub (fill in or run 'impeccable teach' to generate)"
else
  warn "Template PRODUCT.md not found, skipping"
fi

# ── .gitignore ────────────────────────────────────────────────────────────────

if [[ ! -f .gitignore ]]; then
cat > .gitignore <<'GITIGNORE'
node_modules/
.next/
dist/
coverage/
.env
.env.local
*.tsbuildinfo
.DS_Store
.scaffold-backups/
GITIGNORE

success "Created .gitignore"
else
warn ".gitignore already exists, leaving it unchanged"
if ! grep -qF ".scaffold-backups/" .gitignore; then
  echo ".scaffold-backups/" >> .gitignore
  success "Added .scaffold-backups/ to existing .gitignore"
fi
fi

# ── TASK-000: scaffold adapt (upgrade only) ───────────────────────────────────

if [[ -d "$BACKUP_DIR" ]]; then
  cat > docs/tasks/TASK-000-adapt-scaffold.md <<MD
# TASK-000: Adapt scaffold content from backups

**Status:** \`ready\`
**Assigned to:** \`claude-sonnet-4-6\`
**Branch:** main
**Task type:** \`docs_config\`

## Spec

\`setup.sh\` was run over an existing project. Previous scaffold files were backed up to
\`${BACKUP_DIR}/\`. Extract project-specific content from those backups and apply it to the
current template files — filling in all \`[fill in]\` placeholders so the new scaffold
reflects the actual project. Preserve template structure throughout.

## Files to read (from backup)

Backup location: \`${BACKUP_DIR}/\`

For each file that exists in the backup, extract the content described:

- \`AGENTS.md\` — commands block, language/convention rules, UI stack, skill triggers, deployment target
- \`docs/architecture.md\` — tech stack, routes, hooks, auth, feature flags
- \`docs/conventions.md\` — language rules, state management, UI rules
- \`docs/environment.md\` — env var definitions and defaults
- \`HANDOFF.md\` — current task, recent decisions, known issues
- \`PRODUCT.md\` — product purpose, tone, visual direction, accessibility baseline

## Files to write

- \`AGENTS.md\` — fill in Commands, Conventions, Skill triggers, Deployment sections
- \`docs/architecture.md\` — fill in stack, routes, hooks, auth
- \`docs/conventions.md\` — fill in language, state, UI rules
- \`docs/environment.md\` — fill in env vars
- \`HANDOFF.md\` — merge relevant context (current task, decisions, known issues)
- \`PRODUCT.md\` — fill in product context if backup had content beyond the stub

## Do NOT touch

- Template structure — only populate \`[fill in]\` placeholders; do not restructure
- \`.claude/\`, \`.git-hooks/\`, \`.github/\`, \`.codex/\` — not part of this task

## Acceptance criteria

- [ ] All \`[fill in]\` placeholders are either populated or flagged as "not found in backup"
- [ ] Template structure in each file is preserved
- [ ] Migration report delivered: what was adapted vs what still needs manual input
- [ ] This file (\`docs/tasks/TASK-000-adapt-scaffold.md\`) deleted on completion
- [ ] The TASK-000 row removed from \`docs/AGENT_TASKS.md\` on completion
MD

  success "Created docs/tasks/TASK-000-adapt-scaffold.md"

  # Add TASK-000 row to AGENT_TASKS.md active table
  python3 -c "
path = 'docs/AGENT_TASKS.md'
old = '_No active tasks. See next steps in HANDOFF.md._'
new = '| TASK-000 | Adapt scaffold content from backups | \`ready\` | \`claude-sonnet-4-6\` | main | \`docs_config\` | [spec](docs/tasks/TASK-000-adapt-scaffold.md) |'
content = open(path).read().replace(old, new, 1)
open(path, 'w').write(content)
"
  success "Added TASK-000 to docs/AGENT_TASKS.md"

  # Set TASK-000 as the current task in HANDOFF.md
  python3 -c "
path = 'HANDOFF.md'
old = '_No current task. Needs planning._'
new = 'Adapt scaffold content from backups — see [TASK-000](docs/tasks/TASK-000-adapt-scaffold.md).'
content = open(path).read().replace(old, new, 1)
open(path, 'w').write(content)
"
  success "Set TASK-000 as current task in HANDOFF.md"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  $PROJECT_NAME scaffolded at $PROJECT_DIR${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Template source:"
echo "  $TEMPLATE_DIR"
echo ""
echo "Next steps:"
echo "  1.  cd \"$PROJECT_DIR\""
echo "  2.  Initialize your framework if needed, e.g.:"
echo "      npx create-next-app@latest ."
if [[ -d "$BACKUP_DIR" ]]; then
  echo "  3.  Open Claude Code — TASK-000 runs automatically on first session,"
  echo "      adapting backup content into AGENTS.md, docs/, HANDOFF.md, and PRODUCT.md."
  echo "      Review the migration report and fill in any remaining gaps."
  echo "  4.  Run /impeccable teach if PRODUCT.md needs a full refresh."
  echo "  5.  Commit:"
  echo "      git add -A && git commit -m 'chore: upgrade scaffold'"
else
  echo "  3.  Fill in AGENTS.md (Commands section) and docs/architecture.md"
  echo "  4.  Fill in docs/environment.md with your env vars"
  echo "  5.  Open Claude Code and run /impeccable teach (generates PRODUCT.md + DESIGN.md)"
  echo "  6.  Commit:"
  echo "      git add -A && git commit -m 'chore: initial scaffold'"
fi
echo ""
warn "Overwritten files were backed up to .scaffold-backups/${BACKUP_STAMP}/ before overwrite."
warn "Git hooks installed in .git-hooks/ and wired via core.hooksPath."
warn "Remember: run 'impeccable teach' before any UI work."
warn "Global Claude settings, if any, still live in ~/.claude/settings.json"
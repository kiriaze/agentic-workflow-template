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

backup_existing() {
  local path="$1"

  if [[ -e "$path" || -L "$path" ]]; then
    local backup="${path}.bak.${BACKUP_STAMP}"
    local n=1

    while [[ -e "$backup" || -L "$backup" ]]; do
      backup="${path}.bak.${BACKUP_STAMP}.${n}"
      n=$((n + 1))
    done

    cp -a "$path" "$backup"
    warn "Backed up existing $path → $backup"
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

      scripts)
        mkdir -p .claude/scripts

        for script_src in "$src"/*; do
          local script_name
          script_name="$(basename -- "$script_src")"
          copy_with_backup "$script_src" ".claude/scripts/$script_name"
          chmod +x ".claude/scripts/$script_name"
          success "Copied .claude/scripts/$script_name"
        done
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
planning-template.md
workflow.md
AGENT_TASKS.md
)

for f in "${DOC_FILES[@]}"; do
if [[ -f "$TEMPLATE_DIR/docs/$f" ]]; then
copy_with_backup "$TEMPLATE_DIR/docs/$f" "docs/$f"
success "Copied docs/$f"
else
warn "Template docs/$f not found, skipping"
fi
done

# ── .codex/ config ────────────────────────────────────────────────────────────

mkdir -p .codex

if [[ -f "$TEMPLATE_DIR/.codex/config.toml" ]]; then
copy_with_project_name_replacement "$TEMPLATE_DIR/.codex/config.toml" ".codex/config.toml"
success "Copied .codex/config.toml"
else
warn "Template .codex/config.toml not found, skipping"
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

## Next steps

1. Run `impeccable teach` to generate `.impeccable.md` design context
2. Set up environment variables
3. Add architecture details to `docs/architecture.md`

## Known issues

None.

## Recent decisions

* Project scaffolded with setup.sh

## Session log

### $(date '+%Y-%m-%d') — Init

* Initialized project with AI agent workflow scaffold
MD

success "Created HANDOFF.md"
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
GITIGNORE

success "Created .gitignore"
else
warn ".gitignore already exists, leaving it unchanged"
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
echo "  1.  cd "$PROJECT_DIR""
echo "  2.  Initialize your framework if needed, e.g.:"
echo "      npx create-next-app@latest ."
echo "  3.  Open Claude Code and run:"
echo "      /impeccable teach"
echo "  4.  Fill in docs/architecture.md and docs/environment.md"
echo "  5.  Commit:"
echo "      git add -A && git commit -m 'chore: initial scaffold'"
echo ""
warn "Existing scaffold-managed files were backed up as *.bak.${BACKUP_STAMP} before overwrite."
warn "Remember: run 'impeccable teach' before any UI work."
warn "Global Claude settings, if any, still live in ~/.claude/settings.json"
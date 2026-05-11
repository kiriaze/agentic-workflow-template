#!/usr/bin/env bash
# new-ai-project.sh — scaffold a new project with the full AI agent workflow
#
# Usage: ./new-ai-project.sh <project-name> [destination-dir]
#
# What it does:
#   1. Creates the project directory (or uses existing)
#   2. Initializes git
#   3. Copies AGENTS.md, docs/, .codex/, .claude/ config stubs
#   4. Creates HANDOFF.md stub
#   5. Leaves skills global; project only receives repo-specific agent config
#   6. Reminds you to run `impeccable teach` for design context
#
# Prerequisites:
#   - Node.js + npm
#   - git
#   - gh (GitHub CLI, optional — for auto-creating the repo)
#   - ~/.agents/skills/ populated (subagent-driven-development, finishing-a-development-branch, etc.)

set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
PROJECT_NAME="${1:-}"
DEST_DIR="${2:-$HOME/Localhost}"

if [[ -z "$PROJECT_NAME" ]]; then
  echo "Usage: $0 <project-name> [destination-dir]"
  exit 1
fi

PROJECT_DIR="$DEST_DIR/$PROJECT_NAME"
TEMPLATE_DIR="$HOME/Localhost/Career Copilot Claude"   # reference project

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}!${NC} $*"; }

# ── Create project dir ────────────────────────────────────────────────────────
info "Creating project: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ── Git init ──────────────────────────────────────────────────────────────────
if [[ ! -d .git ]]; then
  git init
  success "Initialized git repository"
else
  warn "Git already initialized, skipping"
fi

# ── .claude/ setup ────────────────────────────────────────────────────────────
mkdir -p .claude

# Session-start script
mkdir -p .claude/scripts
cat > .claude/scripts/session-start.sh <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SESSION_KEY=$(date +%Y%m%d%H)
FLAG_DIR="$PROJECT_ROOT/.claude"
FLAG="$FLAG_DIR/.session-${SESSION_KEY}"
if [[ -f "$FLAG" ]]; then exit 0; fi
touch "$FLAG"
find "$FLAG_DIR" -maxdepth 1 -name '.session-*' ! -name ".session-${SESSION_KEY}" -delete 2>/dev/null || true
echo "<session-start-brief>"
echo ""
echo "## HANDOFF.md"
if [[ -f "$PROJECT_ROOT/HANDOFF.md" ]]; then cat "$PROJECT_ROOT/HANDOFF.md"; else echo "(HANDOFF.md not found)"; fi
echo ""
echo "## Active AGENT_TASKS"
if [[ -f "$PROJECT_ROOT/docs/AGENT_TASKS.md" ]]; then
  ACTIVE=$(grep -B2 -A12 'Status.*`ready`\|Status.*`in-progress`' "$PROJECT_ROOT/docs/AGENT_TASKS.md" 2>/dev/null || true)
  if [[ -n "$ACTIVE" ]]; then echo "$ACTIVE"; else echo "(no active tasks)"; fi
else
  echo "(docs/AGENT_TASKS.md not found)"
fi
echo ""
echo "</session-start-brief>"
SCRIPT
chmod +x .claude/scripts/session-start.sh
success "Created .claude/scripts/session-start.sh"

# Derive absolute path for the hook command
ABS_SCRIPT="$(pwd)/.claude/scripts/session-start.sh"

cat > .claude/settings.json <<JSON
{
  "permissions": {
    "deny": [
      "Read(.next/**)",
      "Write(.next/**)",
      "Write(*.tsbuildinfo)"
    ]
  },
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${ABS_SCRIPT}\""
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "cd \"\$PWD\" && file=\"\$CLAUDE_TOOL_RESULT_FILE_PATH\"; if [[ \"\$file\" == *.ts || \"\$file\" == *.tsx ]]; then npx eslint --fix \"\$file\" 2>/dev/null || true; fi"
          }
        ]
      }
    ]
  }
}
JSON
success "Created .claude/settings.json"

# ── CLAUDE.md (single-line redirect) ──────────────────────────────────────────
echo '@AGENTS.md' > CLAUDE.md
success "Created CLAUDE.md"

# ── AGENTS.md (copy from reference project) ───────────────────────────────────
if [[ -f "$TEMPLATE_DIR/AGENTS.md" ]]; then
  cp "$TEMPLATE_DIR/AGENTS.md" AGENTS.md
  success "Copied AGENTS.md from reference project"
else
  warn "Reference AGENTS.md not found at $TEMPLATE_DIR/AGENTS.md — creating stub"
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
```

## Architecture

@docs/architecture.md

## Conventions

@docs/conventions.md

## Workflow

- Plan before implementing (>3 files → map touch points first)
- Type-check + lint before committing
- Conventional commits (`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`)
- Never add AI attribution

## Effort Level Discipline

Default: **`high`**. Escalate to `xhigh` only for architectural decisions, unknown-root cross-cutting bugs, or security-critical analysis.

@docs/multi-agent.md
MD
fi

# ── docs/ (copy from reference) ───────────────────────────────────────────────
mkdir -p docs
for f in architecture.md conventions.md environment.md multi-agent.md planning-template.md AGENT_TASKS.md; do
  if [[ -f "$TEMPLATE_DIR/docs/$f" ]]; then
    cp "$TEMPLATE_DIR/docs/$f" "docs/$f"
    success "Copied docs/$f"
  fi
done

# ── .codex/ config ────────────────────────────────────────────────────────────
mkdir -p .codex
if [[ -f "$TEMPLATE_DIR/.codex/config.toml" ]]; then
  cp "$TEMPLATE_DIR/.codex/config.toml" .codex/config.toml
  # Update the project name comment
  sed -i '' "s|PROJECT_NAME|$PROJECT_NAME|g" .codex/config.toml
  success "Copied .codex/config.toml"
fi

# ── HANDOFF.md stub ───────────────────────────────────────────────────────────
cat > HANDOFF.md <<MD
# HANDOFF.md

## Current task

_Project just initialized. No active task._

## Next steps

1. Run \`impeccable teach\` to generate \`.impeccable.md\` design context
2. Set up environment variables (see \`docs/environment.md\`)
3. Add architecture details to \`docs/architecture.md\`

## Known issues

None.

## Recent decisions

- Project scaffolded with new-ai-project.sh

## Session log

### $(date '+%Y-%m-%d') — Init
- Initialized project with AI agent workflow scaffold
MD
success "Created HANDOFF.md"

# ── .gitignore stub ───────────────────────────────────────────────────────────
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
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  $PROJECT_NAME scaffolded at $PROJECT_DIR${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "  1.  cd \"$PROJECT_DIR\""
echo "  2.  Initialize your framework (e.g. npx create-next-app@latest .)"
echo "  3.  Open Claude Code and run: /impeccable teach"
echo "  4.  Fill in docs/architecture.md and docs/environment.md"
echo "  5.  Commit: git add -A && git commit -m 'chore: initial scaffold'"
echo ""
warn "Remember: run 'impeccable teach' before any UI work."
warn "Global settings.json (effortLevel, token limits) are already set in ~/.claude/settings.json"

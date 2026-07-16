#!/usr/bin/env bash
# session-start.sh — shared hook for Claude Code (UserPromptSubmit) and Codex (SessionStart).
#
# Outputs a session brief so the agent has full context before responding.
# Gate: runs once per hour per project, keyed by flag in .scripts/.
# CC fires this on every user prompt — the gate prevents repeated output.
# Codex fires this once per SessionStart — the gate is harmless but keeps
# both platforms behaving identically.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Session gate ───────────────────────────────────────────────────────────────
SESSION_KEY=$(date +%Y%m%d%H)
FLAG_DIR="$PROJECT_ROOT/.scripts"
FLAG="$FLAG_DIR/.session-${SESSION_KEY}"

if [[ -f "$FLAG" ]]; then
  exit 0
fi

touch "$FLAG"
find "$FLAG_DIR" -maxdepth 1 -name '.session-*' ! -name ".session-${SESSION_KEY}" -delete 2>/dev/null || true

# ── Output brief ───────────────────────────────────────────────────────────────
echo "<session-start-brief>"
echo ""

echo "## HANDOFF.md"
if [[ -f "$PROJECT_ROOT/HANDOFF.md" ]]; then
  cat "$PROJECT_ROOT/HANDOFF.md"
else
  echo "(HANDOFF.md not found — treat this as a fresh session)"
fi

echo ""
echo "## Active AGENT_TASKS"
if [[ -f "$PROJECT_ROOT/docs/AGENT_TASKS.md" ]]; then
  ACTIVE=$(grep -B2 -A12 'Status.*`ready`\|Status.*`in-progress`' "$PROJECT_ROOT/docs/AGENT_TASKS.md" 2>/dev/null || true)
  if [[ -n "$ACTIVE" ]]; then
    echo "$ACTIVE"
  else
    echo "(no active tasks)"
  fi
else
  echo "(docs/AGENT_TASKS.md not found)"
fi

echo ""
echo "## Roster freshness"
ROSTER="$PROJECT_ROOT/docs/agent-roster.json"
if [[ -f "$ROSTER" ]]; then
  python3 -c "
import json, datetime, sys
try:
    data = json.load(open('$ROSTER'))
    lv = data.get('last_verified')
    if not lv:
        print('(agent-roster.json has no last_verified field — add one and verify model IDs)')
        sys.exit()
    age = (datetime.date.today() - datetime.date.fromisoformat(lv)).days
    if age > 60:
        print(f'WARNING: agent-roster.json last verified {age} days ago ({lv}). Ask the human to reconfirm model IDs, then update last_verified.')
    else:
        print(f'(roster verified {age} days ago — OK)')
except Exception:
    print('(could not read agent-roster.json freshness)')
" 2>/dev/null || echo "(could not read agent-roster.json freshness)"
else
  echo "(docs/agent-roster.json not found)"
fi

echo ""
echo "</session-start-brief>"

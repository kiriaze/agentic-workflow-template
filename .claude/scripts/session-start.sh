#!/usr/bin/env bash
# session-start.sh — injected once per session via UserPromptSubmit hook.
# Outputs a session brief (HANDOFF.md + active AGENT_TASKS) so Claude Code
# has full context before responding to the first message.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ── Session gate ───────────────────────────────────────────────────────────────
# Key by hour so the flag naturally expires. Multiple CC windows in the same
# hour share the flag — acceptable; the second window already has fresh context.
SESSION_KEY=$(date +%Y%m%d%H)
FLAG_DIR="$PROJECT_ROOT/.claude"
FLAG="$FLAG_DIR/.session-${SESSION_KEY}"

if [[ -f "$FLAG" ]]; then
  exit 0
fi

touch "$FLAG"
# Clean up flags from previous hours
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
  # Extract task blocks with ready or in-progress status
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
echo "</session-start-brief>"

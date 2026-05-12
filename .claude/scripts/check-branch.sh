#!/usr/bin/env bash
# check-branch.sh — PreToolUse hook (Claude Code only).
#
# Blocks Write/Edit to src/ files when on main/master.
# Fires before the file is written — earlier than the git pre-commit hook.
#
# Claude Code pipes the tool call payload as JSON to stdin:
#   { "tool_name": "Write", "tool_input": { "file_path": "...", ... } }

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Parse file_path from stdin JSON
FILE_PATH=$(python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

# Only enforce for src/ paths — docs, config, and root files may go to main
if [[ "$FILE_PATH" == *"/src/"* ]]; then
  BRANCH=$(git -C "$PROJECT_ROOT" branch --show-current 2>/dev/null || echo "")

  if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
    echo ""
    echo "BLOCKED: Cannot write to src/ directly on '$BRANCH'."
    echo "Create a feature branch before modifying source files:"
    echo "  git checkout -b feat/<task-name>"
    echo ""
    echo "File attempted: $FILE_PATH"
    echo ""
    exit 1
  fi
fi

exit 0

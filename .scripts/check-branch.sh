#!/usr/bin/env bash
# check-branch.sh — shared PreToolUse hook for Claude Code and Codex.
#
# Blocks writes/edits to src/ files when on main/master.
# Both platforms deliver the hook payload via stdin as JSON.
#
# CC    (Write/Edit):   tool_input.file_path     — single path string
# Codex (apply_patch):  tool_input.command[1]    — patch string; paths in "*** Update/Add File:" headers

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FILE_PATHS=$(python3 -c "
import sys, json, re
try:
    data = json.load(sys.stdin)
    inp = data.get('tool_input', {})
    if 'file_path' in inp:
        print(inp['file_path'])
        sys.exit()
    command = inp.get('command', [])
    if len(command) >= 2:
        for m in re.finditer(r'^\*\*\* (?:Update|Add) File: (.+)$', command[1], re.MULTILINE):
            print(m.group(1).strip())
except Exception:
    pass
" 2>/dev/null || true)

[[ -z "$FILE_PATHS" ]] && exit 0

BRANCH=$(git -C "$PROJECT_ROOT" branch --show-current 2>/dev/null || echo "")
[[ "$BRANCH" != "main" && "$BRANCH" != "master" ]] && exit 0

while IFS= read -r FILE_PATH; do
  if [[ "$FILE_PATH" == *"/src/"* || "$FILE_PATH" == src/* ]]; then
    echo ""
    echo "BLOCKED: Cannot write to src/ directly on '$BRANCH'."
    echo "Create a feature branch before modifying source files:"
    echo "  git checkout -b feat/<task-name>"
    echo ""
    echo "File attempted: $FILE_PATH"
    echo ""
    exit 1
  fi
done <<< "$FILE_PATHS"

exit 0

#!/usr/bin/env bash
# auto-lint.sh — shared PostToolUse hook for Claude Code and Codex.
#
# Auto-fixes lint errors on .ts/.tsx files after writes/edits.
# Both platforms deliver the hook payload via stdin as JSON.
#
# CC    (Write/Edit):   tool_input.file_path     — single path string
# Codex (apply_patch):  tool_input.command[1]    — patch string; paths in "*** Update/Add File:" headers
# A patch may touch multiple files; eslint runs on each .ts/.tsx path found.

set -uo pipefail

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
command -v npx &>/dev/null || exit 0
[[ -f "package.json" ]] || exit 0

while IFS= read -r FILE_PATH; do
  if [[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx ]]; then
    npx eslint --fix "$FILE_PATH" 2>/dev/null || true
  fi
done <<< "$FILE_PATHS"

exit 0

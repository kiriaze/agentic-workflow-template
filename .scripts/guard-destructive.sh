#!/usr/bin/env bash
# guard-destructive.sh — shared PreToolUse hook for Claude Code (Bash) and Codex (shell).
#
# Blocks destructive shell commands pending explicit per-action user approval.
# Pairs with the "Never destroy without approval" rule in AGENTS.md — the rule covers
# everything; this hook mechanically stops the worst offenders.
#
# CC    (Bash):  tool_input.command — string
# Codex (shell): tool_input.command — string or argv list
#
# Exit 2 + stderr is the blocking convention for CC PreToolUse hooks
# (exit 1 is non-blocking and would let the command run).

set -uo pipefail

PY=$(cat <<'PYEOF'
import sys, json, re
try:
    data = json.load(sys.stdin)
    cmd = data.get('tool_input', {}).get('command', '')
    if isinstance(cmd, list):
        cmd = ' '.join(str(c) for c in cmd)
    # Strip quoted strings so text that merely mentions these commands (commit
    # messages, echo output) does not false-positive. A destructive command hidden
    # inside quotes (bash -c '...') is deliberate evasion, not an accident — the
    # AGENTS.md rule covers it; this hook covers mistakes.
    stripped = re.sub(r"'[^']*'", "''", cmd)
    stripped = re.sub(r'"[^"]*"', '""', stripped)
    patterns = [
        (r'\brm\s+(-\S*\s+)*-\S*r', 'rm with recursive delete'),
        (r'\bgit\s+reset\s+(-\S*\s+)*--hard\b', 'git reset --hard'),
        (r'\bgit\s+push\b[^|;&]*(\s--force(-with-lease)?\b|\s-f\b)', 'git push --force'),
        (r'\bgit\s+clean\b[^|;&]*\s-\S*[fdx]', 'git clean -f/-d/-x'),
        (r'\bgit\s+branch\s+(-\S*\s+)*-D\b', 'git branch -D (force delete)'),
    ]
    for pat, label in patterns:
        if re.search(pat, stripped):
            print(label + '|' + cmd)
            break
except Exception:
    pass
PYEOF
)

RESULT=$(python3 -c "$PY" 2>/dev/null || true)

[[ -z "$RESULT" ]] && exit 0

LABEL="${RESULT%%|*}"
CMD="${RESULT#*|}"

{
  echo "BLOCKED: destructive command ($LABEL) requires explicit per-action user approval."
  echo "Command attempted: $CMD"
  echo "Ask the user to approve this exact command or run it themselves. Do not retry unapproved."
} >&2
exit 2

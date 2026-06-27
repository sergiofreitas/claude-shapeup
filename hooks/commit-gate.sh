#!/bin/bash
# commit-gate.sh — PreToolUse hook. Intercepts `git commit` invocations and
# runs the .shapeup/ consistency gate before the commit executes.
#
# Input: JSON on stdin with the standard PreToolUse payload
#        ({tool_name, tool_input.command, ...}).
# Exits:
#   0 — not a `git commit`, or the gate passed; let the tool run
#   2 — gate reported drift; Claude Code blocks the tool call and shows stderr
#
# Non-invasive: only reacts to Bash tool calls whose command starts with (or
# chains into) `git commit`. Anything else passes through untouched.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# Match `git commit` as a whole command — not `git commit-tree`, not the
# substring inside a quoted message. Boundary before `git` can be start-of-
# string, whitespace, or a chain operator (;, &&, ||). After `commit`, require
# whitespace or end-of-line.
if ! echo "$COMMAND" | grep -qE '(^|[[:space:]]|;|&&|\|\|)git[[:space:]]+commit([[:space:]]|$)'; then
  exit 0
fi

PROJECT_ROOT="${SHAPEUP_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CODEX_WORKSPACE_ROOT:-$(pwd)}}}"
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$HOOKS_DIR/lib/commit-gate.sh"

if [ ! -f "$GATE" ]; then
  echo "commit-gate: gate library not found at $GATE; passing through." >&2
  exit 0
fi

bash "$GATE" "$PROJECT_ROOT"
status=$?

if [ "$status" -ne 0 ]; then
  exit 2
fi

exit 0

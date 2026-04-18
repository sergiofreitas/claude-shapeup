#!/bin/bash
# build-guard.sh — UserPromptSubmit hook to prevent /build on completed/shipped features
# Deterministically blocks re-entry instead of relying on prompt instructions alone.

INPUT=$(cat)

# Extract the user's prompt text
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Only check for /build commands
if [[ ! "$PROMPT" =~ ^/build[[:space:]]+([0-9]+) ]] && [[ ! "$PROMPT" =~ build[[:space:]]+feature[[:space:]]+([0-9]+) ]]; then
  exit 0
fi

# Extract the feature number
if [[ "$PROMPT" =~ ([0-9]{1,3}) ]]; then
  NNN="${BASH_REMATCH[1]}"
else
  exit 0
fi

# Find the .shapeup directory (search from project root)
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"
SHAPEUP_DIR="$PROJECT_ROOT/.shapeup"

if [ ! -d "$SHAPEUP_DIR" ]; then
  exit 0
fi

# Check if feature is already shipped
SHIPPED=$(ls -d "$SHAPEUP_DIR"/${NNN}-*-shipped 2>/dev/null)
if [ -n "$SHIPPED" ]; then
  echo "Feature $NNN is already shipped. To iterate, frame a new feature." >&2
  exit 2
fi

# Check if build is already complete (build-summary.md exists)
SUMMARY=$(ls "$SHAPEUP_DIR"/${NNN}-*/build-summary.md 2>/dev/null)
if [ -n "$SUMMARY" ]; then
  echo "Build for feature $NNN is complete. Run /ship $NNN to archive and document decisions." >&2
  exit 2
fi

exit 0

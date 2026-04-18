#!/bin/bash
# phase-guard.sh — UserPromptSubmit hook enforcing phase transition gates
# Deterministically blocks skill invocations when prerequisites aren't met.

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"
SHAPEUP_DIR="$PROJECT_ROOT/.shapeup"

# Only process Shape Up skill invocations
# Extract command and feature number
COMMAND=""
NNN=""

if [[ "$PROMPT" =~ ^/shape[[:space:]]+([0-9]+) ]]; then
  COMMAND="shape"
  NNN="${BASH_REMATCH[1]}"
elif [[ "$PROMPT" =~ ^/build[[:space:]]+([0-9]+) ]]; then
  COMMAND="build"
  NNN="${BASH_REMATCH[1]}"
elif [[ "$PROMPT" =~ ^/ship[[:space:]]+([0-9]+) ]]; then
  COMMAND="ship"
  NNN="${BASH_REMATCH[1]}"
else
  exit 0
fi

# No .shapeup directory — nothing to guard
if [ ! -d "$SHAPEUP_DIR" ]; then
  exit 0
fi

# Find the feature folder
FEATURE_DIR=$(ls -d "$SHAPEUP_DIR"/${NNN}-* 2>/dev/null | head -1)
if [ -z "$FEATURE_DIR" ]; then
  exit 0
fi

case "$COMMAND" in
  shape)
    # Gate: frame.md must exist with Frame Go
    FRAME="$FEATURE_DIR/frame.md"
    if [ ! -f "$FRAME" ]; then
      echo "Feature $NNN has no frame document. Run /frame first." >&2
      exit 2
    fi
    if ! grep -q "Frame Go" "$FRAME" 2>/dev/null; then
      echo "Feature $NNN hasn't been approved for shaping. Run /frame to complete framing and get Frame Go approval." >&2
      exit 2
    fi
    # Check if already shaped or beyond
    if [[ "$FEATURE_DIR" == *-shaped ]] || [[ "$FEATURE_DIR" == *-building ]] || [[ "$FEATURE_DIR" == *-shipped ]]; then
      echo "Feature $NNN is already shaped. Run /build $NNN to build it." >&2
      exit 2
    fi
    ;;

  build)
    # Gate: already shipped
    if [[ "$FEATURE_DIR" == *-shipped ]]; then
      echo "Feature $NNN is already shipped. To iterate, frame a new feature." >&2
      exit 2
    fi
    # Gate: build already complete
    if [ -f "$FEATURE_DIR/build-summary.md" ]; then
      echo "Build for feature $NNN is complete. Run /ship $NNN to archive and document decisions." >&2
      exit 2
    fi
    # Gate: package.md must exist with Shape Go
    PACKAGE="$FEATURE_DIR/package.md"
    if [ ! -f "$PACKAGE" ]; then
      echo "Feature $NNN has no package. Run /shape $NNN first." >&2
      exit 2
    fi
    if ! grep -q "Shape Go" "$PACKAGE" 2>/dev/null; then
      echo "Feature $NNN hasn't been approved for building. Run /shape $NNN to complete shaping and get Shape Go approval." >&2
      exit 2
    fi
    ;;

  ship)
    # Gate: already shipped
    if [[ "$FEATURE_DIR" == *-shipped ]]; then
      echo "Feature $NNN is already shipped." >&2
      exit 2
    fi
    # Gate: build-summary.md must exist
    if [ ! -f "$FEATURE_DIR/build-summary.md" ]; then
      echo "Feature $NNN hasn't completed building. Run /build $NNN first." >&2
      exit 2
    fi
    ;;
esac

exit 0

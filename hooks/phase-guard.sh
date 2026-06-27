#!/bin/bash
# phase-guard.sh — UserPromptSubmit hook enforcing phase transition gates.
# Deterministically blocks skill invocations when prerequisites aren't met.
#
# Feature keys accepted by /shape, /build, /ship:
#   - Full date-slug:   2026-04-20-csv-import
#   - With disambig:    2026-04-20-csv-import-bc89
#   - Short slug:       csv-import (fails if multiple features share the slug)
#   - Legacy NNN:       001 / 042 / 42  (back-compat; resolves to the single folder)

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
PROJECT_ROOT="${SHAPEUP_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CODEX_WORKSPACE_ROOT:-$(pwd)}}}"
SHAPEUP_DIR="$PROJECT_ROOT/.shapeup"
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVER="$HOOKS_DIR/lib/resolve-feature.sh"

COMMAND=""
KEY=""

# Accept /<skill>, /shapeup:<skill>, or legacy /<skill>. Key = first non-space arg.
if [[ "$PROMPT" =~ ^/(shapeup:)?shape[[:space:]]+([^[:space:]]+) ]]; then
  COMMAND="shape"
  KEY="${BASH_REMATCH[2]}"
elif [[ "$PROMPT" =~ ^/(shapeup:)?build[[:space:]]+([^[:space:]]+) ]]; then
  COMMAND="build"
  KEY="${BASH_REMATCH[2]}"
elif [[ "$PROMPT" =~ ^/(shapeup:)?ship[[:space:]]+([^[:space:]]+) ]]; then
  COMMAND="ship"
  KEY="${BASH_REMATCH[2]}"
else
  exit 0
fi

# No .shapeup directory — nothing to guard
if [ ! -d "$SHAPEUP_DIR" ]; then
  exit 0
fi

# Resolve feature key → folder path
if [ ! -x "$RESOLVER" ]; then
  exit 0
fi

RESOLVED=$("$RESOLVER" "$SHAPEUP_DIR" "$KEY" 2>/tmp/phase-guard-resolver.err)
RESOLVE_STATUS=$?

if [ "$RESOLVE_STATUS" = "2" ]; then
  # Ambiguous — surface the resolver's message, block the invocation.
  cat /tmp/phase-guard-resolver.err >&2
  rm -f /tmp/phase-guard-resolver.err
  exit 2
fi

rm -f /tmp/phase-guard-resolver.err

if [ "$RESOLVE_STATUS" != "0" ] || [ -z "$RESOLVED" ]; then
  # No match — let the skill handle the "feature not found" case itself.
  exit 0
fi

FEATURE_DIR="$RESOLVED"

case "$COMMAND" in
  shape)
    FRAME="$FEATURE_DIR/frame.md"
    if [ ! -f "$FRAME" ]; then
      echo "Feature '$KEY' has no frame document. Run /frame first." >&2
      exit 2
    fi
    if ! grep -q "Frame Go" "$FRAME" 2>/dev/null; then
      echo "Feature '$KEY' hasn't been approved for shaping. Run /frame to complete framing and get Frame Go approval." >&2
      exit 2
    fi
    if [[ "$FEATURE_DIR" == *-shaped ]] || [[ "$FEATURE_DIR" == *-building ]] || [[ "$FEATURE_DIR" == *-shipped ]]; then
      echo "Feature '$KEY' is already shaped. Run /build $KEY to build it." >&2
      exit 2
    fi
    ;;

  build)
    if [[ "$FEATURE_DIR" == *-shipped ]]; then
      echo "Feature '$KEY' is already shipped. To iterate, frame a new feature." >&2
      exit 2
    fi
    if [ -f "$FEATURE_DIR/build-summary.md" ]; then
      echo "Build for feature '$KEY' is complete. Run /ship $KEY to archive and document decisions." >&2
      exit 2
    fi
    PACKAGE="$FEATURE_DIR/package.md"
    if [ ! -f "$PACKAGE" ]; then
      echo "Feature '$KEY' has no package. Run /shape $KEY first." >&2
      exit 2
    fi
    if ! grep -q "Shape Go" "$PACKAGE" 2>/dev/null; then
      echo "Feature '$KEY' hasn't been approved for building. Run /shape $KEY to complete shaping and get Shape Go approval." >&2
      exit 2
    fi
    ;;

  ship)
    if [[ "$FEATURE_DIR" == *-shipped ]]; then
      echo "Feature '$KEY' is already shipped." >&2
      exit 2
    fi
    if [ ! -f "$FEATURE_DIR/build-summary.md" ]; then
      echo "Feature '$KEY' hasn't completed building. Run /build $KEY first." >&2
      exit 2
    fi
    ;;
esac

exit 0

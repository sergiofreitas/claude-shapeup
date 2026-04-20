#!/bin/bash
# resolve-feature.sh — Resolve a feature key to an on-disk folder path.
# Usage: resolve-feature.sh <shapeup-dir> <key>
#   <key> can be any of:
#     - Full date-slug:   2026-04-20-csv-import
#     - With disambig:    2026-04-20-csv-import-bc89
#     - Short slug:       csv-import
#     - Legacy numeric:   001 or 1 (back-compat for pre-date-slug features)
# Prints the matching folder path on stdout.
# Exits 1 on no match, 2 on ambiguous match.
#
# Any status suffix is tolerated (-framing/-shaped/-building/-shipped/-discarded).

SHAPEUP_DIR="$1"
KEY="$2"

if [ -z "$SHAPEUP_DIR" ] || [ -z "$KEY" ]; then
  echo "Usage: resolve-feature.sh <shapeup-dir> <key>" >&2
  exit 1
fi

if [ ! -d "$SHAPEUP_DIR" ]; then
  exit 1
fi

STATUSES="framing shaped building shipped discarded"

match_status_suffix() {
  # Emit matching feature folders where the key is followed by a status suffix.
  # This prevents `csv-import` from matching `csv-import-bc89-framing`.
  local base="$1"
  for status in $STATUSES; do
    local d="$SHAPEUP_DIR/${base}-${status}"
    [ -d "$d" ] && echo "$d"
  done
}

MATCHES=""

# 1. Legacy NNN — pad to three digits (force base-10 to avoid octal parse of "042")
if [[ "$KEY" =~ ^[0-9]+$ ]]; then
  PADDED=$(printf "%03d" "$((10#$KEY))")
  MATCHES=$(match_status_suffix "${PADDED}-"*)
  # The previous line uses a glob that won't expand inside a function arg —
  # fall back to scanning all folders.
  if [ -z "$MATCHES" ]; then
    for dir in "$SHAPEUP_DIR"/${PADDED}-*; do
      [ -d "$dir" ] || continue
      MATCHES="$MATCHES"$'\n'"$dir"
    done
    MATCHES=$(echo "$MATCHES" | sed '/^$/d')
  fi
fi

# 2. Exact date-slug: YYYY-MM-DD-<slug> (optionally with -<hex> disambig)
if [ -z "$MATCHES" ] && [[ "$KEY" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}- ]]; then
  MATCHES=$(match_status_suffix "$KEY")
fi

# 3. Short slug — scan every folder, strip date/numeric prefix and status
#    suffix, compare slug portion to KEY.
if [ -z "$MATCHES" ]; then
  for dir in "$SHAPEUP_DIR"/*/; do
    [ -d "$dir" ] || continue
    NAME=$(basename "$dir")
    # Strip date-slug prefix OR legacy NNN prefix
    STRIPPED=$(echo "$NAME" \
      | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//' \
      | sed -E 's/^[0-9]{3}-//')
    # Strip trailing status
    SLUG_PART=""
    for status in $STATUSES; do
      case "$STRIPPED" in
        *-"$status")
          SLUG_PART="${STRIPPED%-"$status"}"
          break
          ;;
      esac
    done
    [ -z "$SLUG_PART" ] && continue
    # Strip trailing 4-hex disambiguator if present
    SLUG_BASE=$(echo "$SLUG_PART" | sed -E 's/-[0-9a-f]{4}$//')

    if [ "$SLUG_PART" = "$KEY" ] || [ "$SLUG_BASE" = "$KEY" ]; then
      MATCHES="$MATCHES"$'\n'"${dir%/}"
    fi
  done
  MATCHES=$(echo "$MATCHES" | sed '/^$/d' | sort -u)
fi

COUNT=$(echo "$MATCHES" | sed '/^$/d' | wc -l | tr -d ' ')

if [ "$COUNT" = "0" ]; then
  exit 1
fi

if [ "$COUNT" -gt 1 ]; then
  echo "resolve-feature.sh: key '$KEY' is ambiguous, matches multiple features:" >&2
  echo "$MATCHES" >&2
  echo "Use the full date-slug key (including any -<hex> disambiguator) to select one." >&2
  exit 2
fi

echo "$MATCHES" | head -1 | sed 's:/$::'

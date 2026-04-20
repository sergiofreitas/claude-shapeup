#!/bin/bash
# regenerate-index.sh — Scan .shapeup/ and produce index.md dashboard.
# Usage: regenerate-index.sh <shapeup-dir>
#
# Handles both legacy NNN-slug-<status> folders and the new
# YYYY-MM-DD-slug[-hex]-<status> folders.

SHAPEUP_DIR="$1"

if [ -z "$SHAPEUP_DIR" ] || [ ! -d "$SHAPEUP_DIR" ]; then
  echo "Usage: regenerate-index.sh <shapeup-dir>" >&2
  exit 1
fi

INDEX="$SHAPEUP_DIR/index.md"

cat > "$INDEX" << HEADER
# Shape Up Project Dashboard

**Generated**: $(date +%Y-%m-%d)

HEADER

# Extract the (id, slug) pair from a folder basename.
# Legacy folders use NNN as id; new folders use YYYY-MM-DD (plus any
# -<hex> disambiguator) as id.
extract_id_slug() {
  local name="$1"
  local status="$2"
  local stripped="${name%-${status}}"
  if [[ "$stripped" =~ ^([0-9]{3})-(.+)$ ]]; then
    echo "${BASH_REMATCH[1]}|${BASH_REMATCH[2]}"
  elif [[ "$stripped" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.+)$ ]]; then
    local date_part="${BASH_REMATCH[1]}"
    local rest="${BASH_REMATCH[2]}"
    # If rest ends with -<4hex>, fold it into the id so slug stays clean.
    if [[ "$rest" =~ ^(.+)-([0-9a-f]{4})$ ]]; then
      echo "${date_part}-${BASH_REMATCH[2]}|${BASH_REMATCH[1]}"
    else
      echo "${date_part}|${rest}"
    fi
  else
    echo "|${stripped}"
  fi
}

BUILDING=""
SHAPED=""
FRAMING=""
SHIPPED=""
DISCARDED=""

for dir in "$SHAPEUP_DIR"/*/; do
  [ -d "$dir" ] || continue
  NAME=$(basename "$dir")
  case "$NAME" in
    *-building)  BUILDING="$BUILDING $dir";;
    *-shaped)    SHAPED="$SHAPED $dir";;
    *-framing)   FRAMING="$FRAMING $dir";;
    *-shipped)   SHIPPED="$SHIPPED $dir";;
    *-discarded) DISCARDED="$DISCARDED $dir";;
  esac
done

write_section() {
  local title="$1"
  local status="$2"
  local dirs="$3"
  local include_decisions="$4"
  local include_discard="$5"

  [ -z "$dirs" ] && return

  echo "## $title" >> "$INDEX"
  echo "" >> "$INDEX"
  for dir in $dirs; do
    NAME=$(basename "$dir")
    PAIR=$(extract_id_slug "$NAME" "$status")
    ID="${PAIR%%|*}"
    SLUG="${PAIR##*|}"
    echo "### $ID: $SLUG" >> "$INDEX"
    if [ -f "$dir/frame.md" ] && [ "$status" = "building" ]; then
      PROBLEM=$(grep -A2 "^## Problem" "$dir/frame.md" | tail -1 | head -c 200)
      echo "- **Problem**: $PROBLEM" >> "$INDEX"
    fi
    if [ -f "$dir/hillchart.md" ] && [ "$status" = "building" ]; then
      echo "- **Hill Chart**: See \`$NAME/hillchart.md\`" >> "$INDEX"
    fi
    if [ "$include_decisions" = "yes" ] && [ -f "$dir/decisions.md" ]; then
      echo "- Decisions: \`$NAME/decisions.md\`" >> "$INDEX"
    fi
    if [ "$include_discard" = "yes" ] && [ -f "$dir/discard-reason.md" ]; then
      echo "- Reason: \`$NAME/discard-reason.md\`" >> "$INDEX"
    fi
    echo "" >> "$INDEX"
  done
}

write_section "Active — Building"      "building"  "$BUILDING"  "no"  "no"
write_section "Ready to Build — Shaped" "shaped"    "$SHAPED"    "no"  "no"
write_section "In Progress — Framing"   "framing"   "$FRAMING"   "no"  "no"
write_section "Completed — Shipped"     "shipped"   "$SHIPPED"   "yes" "no"
write_section "Discarded"               "discarded" "$DISCARDED" "no"  "yes"

echo "Dashboard regenerated at $INDEX"

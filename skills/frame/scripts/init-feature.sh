#!/bin/bash
# init-feature.sh — Create a new date-slug feature folder in .shapeup/
# Usage: init-feature.sh <shapeup-dir> <slug> [YYYY-MM-DD]
# Example: init-feature.sh /path/to/.shapeup "user-auth"
# Output: prints the created folder path
#
# Naming scheme: YYYY-MM-DD-<slug>-framing
# Rationale: date-slug keys are collision-free across teammates working on
# separate branches. Autoincrement NNN prefixes caused merge conflicts when
# two teammates both picked "042-" on diverged branches. If two features are
# created with the same date+slug (rare), a 4-hex disambiguator is appended:
# YYYY-MM-DD-<slug>-<hex>-framing.

set -e

SHAPEUP_DIR="$1"
SLUG="$2"
DATE_OVERRIDE="$3"

if [ -z "$SHAPEUP_DIR" ] || [ -z "$SLUG" ]; then
  echo "Usage: init-feature.sh <shapeup-dir> <slug> [YYYY-MM-DD]" >&2
  exit 1
fi

# Normalize slug: lowercase, kebab-case, alphanumerics and hyphens only
SLUG_NORMALIZED=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g' | sed -E 's/-+/-/g' | sed -E 's/^-|-$//g')
if [ -z "$SLUG_NORMALIZED" ]; then
  echo "init-feature.sh: slug normalized to empty string — provide alphanumerics" >&2
  exit 1
fi

DATE="${DATE_OVERRIDE:-$(date +%Y-%m-%d)}"

mkdir -p "$SHAPEUP_DIR"

BASE_KEY="${DATE}-${SLUG_NORMALIZED}"
FOLDER_NAME="${BASE_KEY}-framing"
FOLDER_PATH="${SHAPEUP_DIR}/${FOLDER_NAME}"

# If a folder with this exact key already exists (any status), append a
# 4-char hex disambiguator so the new feature gets its own folder.
EXISTING=$(find "$SHAPEUP_DIR" -maxdepth 1 -type d -name "${BASE_KEY}-*" 2>/dev/null | head -1 || true)
if [ -n "$EXISTING" ]; then
  HEX=$(LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom 2>/dev/null | head -c 4)
  if [ -z "$HEX" ]; then
    HEX=$(printf '%04x' $((RANDOM * RANDOM % 65536)))
  fi
  BASE_KEY="${DATE}-${SLUG_NORMALIZED}-${HEX}"
  FOLDER_NAME="${BASE_KEY}-framing"
  FOLDER_PATH="${SHAPEUP_DIR}/${FOLDER_NAME}"
fi

mkdir -p "$FOLDER_PATH"
echo "$FOLDER_PATH"

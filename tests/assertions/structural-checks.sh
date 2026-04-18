#!/bin/bash
# structural-checks.sh — Verify build skill artifacts meet structural requirements
#
# Usage: ./structural-checks.sh <results-directory> [<package-path>]
#
# Checks:
# - Required files exist (orientation.md, hillchart.md, scopes/, unscoped.md)
# - Required sections present in each file
# - Scope files have required fields
# - No Package element names used verbatim as scope names (if package-path provided)
# - Hill chart has history entries
# - Handover files have structured reasoning (if present)
#
# Exit code: number of failures (0 = all passed)

set -uo pipefail
# Note: NOT using -e because assert functions use non-zero exits intentionally

RESULTS_DIR="${1:?Usage: structural-checks.sh <results-directory> [<package-path>]}"
PACKAGE_PATH="${2:-}"

PASS=0
FAIL=0
WARN=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

pass() {
  PASS=$((PASS + 1))
  echo -e "  ${GREEN}PASS${NC} $1"
}

fail() {
  FAIL=$((FAIL + 1))
  echo -e "  ${RED}FAIL${NC} $1"
}

warn() {
  WARN=$((WARN + 1))
  echo -e "  ${YELLOW}WARN${NC} $1"
}

# --- Assert helpers ---

assert_file_exists() {
  local file="$RESULTS_DIR/$1"
  if [ -f "$file" ]; then
    pass "File exists: $1"
  else
    fail "File missing: $1"
  fi
}

assert_dir_exists() {
  local dir="$RESULTS_DIR/$1"
  if [ -d "$dir" ]; then
    pass "Directory exists: $1"
  else
    fail "Directory missing: $1"
  fi
}

assert_file_count_gte() {
  local pattern="$RESULTS_DIR/$1"
  local min="$2"
  local count
  count=$(ls -1 $pattern 2>/dev/null | wc -l | xargs || echo 0)
  count=${count:-0}
  if [ "$count" -ge "$min" ]; then
    pass "File count ($1): $count >= $min"
  else
    fail "File count ($1): $count < $min (expected >= $min)"
  fi
}

assert_section_exists() {
  local file="$RESULTS_DIR/$1"
  local section="$2"
  if [ ! -f "$file" ]; then
    fail "Cannot check section '$section' — file missing: $1"
    return
  fi
  # Check for markdown heading containing the section text (case-insensitive)
  if grep -qi "^#.*$section" "$file" 2>/dev/null; then
    pass "Section '$section' found in $1"
  else
    fail "Section '$section' missing in $1"
  fi
}

assert_content_contains() {
  local file="$RESULTS_DIR/$1"
  local pattern="$2"
  local description="$3"
  if [ ! -f "$file" ]; then
    fail "Cannot check content — file missing: $1"
    return
  fi
  if grep -qi "$pattern" "$file" 2>/dev/null; then
    pass "$description in $1"
  else
    fail "$description missing in $1"
  fi
}

assert_history_entries_gte() {
  local file="$RESULTS_DIR/$1"
  local min="$2"
  if [ ! -f "$file" ]; then
    fail "Cannot check history entries — file missing: $1"
    return
  fi
  # Count "### Session" lines in the History section
  local count
  count=$(grep -c "^### Session" "$file" 2>/dev/null || true)
  count=$(echo "$count" | xargs)
  count=${count:-0}
  if [ "$count" -ge "$min" ]; then
    pass "Hill chart history entries: $count >= $min"
  else
    fail "Hill chart history entries: $count < $min (expected >= $min)"
  fi
}

assert_no_package_element_as_scope() {
  local pkg="$1"
  local scopes_dir="$RESULTS_DIR/$2"

  if [ -z "$pkg" ] || [ ! -f "$pkg" ]; then
    warn "No package path provided — skipping Package→Scope name check"
    return
  fi

  if [ ! -d "$scopes_dir" ]; then
    fail "Scopes directory missing — cannot check Package→Scope prohibition"
    return
  fi

  # Extract element names from Package (lines starting with "### Element:")
  local elements
  elements=$(grep -i "^### Element:" "$pkg" 2>/dev/null | sed 's/^### Element: *//' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')

  if [ -z "$elements" ]; then
    warn "No elements found in package — skipping Package→Scope name check"
    return
  fi

  local violations=0
  for scope_file in "$scopes_dir"/scope-*.md; do
    [ -f "$scope_file" ] || continue
    local scope_name
    scope_name=$(basename "$scope_file" .md | sed 's/^scope-//')
    for element in $elements; do
      if [ "$scope_name" = "$element" ]; then
        fail "PROHIBITION: scope name '$scope_name' matches Package element name verbatim"
        violations=$((violations + 1))
      fi
    done
  done

  if [ "$violations" -eq 0 ]; then
    pass "No scope names match Package element names verbatim"
  fi
}

# ============================================================
# Run checks
# ============================================================

echo ""
echo "=== Shape Up Build Artifact Structural Checks ==="
echo "    Directory: $RESULTS_DIR"
[ -n "$PACKAGE_PATH" ] && echo "    Package: $PACKAGE_PATH"
echo ""

# --- 1. File existence ---
echo "--- File Existence ---"
assert_file_exists "orientation.md"
assert_file_exists "hillchart.md"
assert_dir_exists "scopes"
assert_file_exists "scopes/unscoped.md"
assert_file_count_gte "scopes/scope-*.md" 1

# --- 2. Orientation quality ---
echo ""
echo "--- Orientation (orientation.md) ---"
assert_section_exists "orientation.md" "Problem Restated"
assert_section_exists "orientation.md" "Codebase Observations"
assert_section_exists "orientation.md" "Imagined vs. Discovered"
assert_section_exists "orientation.md" "First Piece Selection"
assert_content_contains "orientation.md" "core\|Core\|CORE" "Core reasoning"
assert_content_contains "orientation.md" "small\|Small\|SMALL" "Small reasoning"
assert_content_contains "orientation.md" "risk\|Risk\|uncertain\|unknown\|complexity\|challenging\|novel\|tricky\|careful\|uphill\|depends" "Risk/uncertainty reasoning"

# --- 3. Hill chart quality ---
echo ""
echo "--- Hill Chart (hillchart.md) ---"
assert_section_exists "hillchart.md" "Scopes"
assert_section_exists "hillchart.md" "Sequencing Rationale"
assert_section_exists "hillchart.md" "Risk"
assert_section_exists "hillchart.md" "Next"
assert_section_exists "hillchart.md" "History"
assert_history_entries_gte "hillchart.md" 1

# --- 4. Scope file quality ---
echo ""
echo "--- Scope Files ---"
scope_count=0
if [ -d "$RESULTS_DIR/scopes" ]; then
  for scope_file in "$RESULTS_DIR"/scopes/scope-*.md; do
    [ -f "$scope_file" ] || continue
    scope_count=$((scope_count + 1))
    relative=$(echo "$scope_file" | sed "s|$RESULTS_DIR/||")
    echo "  Checking: $relative"
    assert_section_exists "$relative" "Hill Position"
    assert_section_exists "$relative" "Prioritization Reasoning"
    assert_section_exists "$relative" "Must-Haves"
    assert_content_contains "$relative" "vertical slice\|Vertical slice\|end-to-end\|End-to-end\|integrated\|Integrated\|full stack\|user.* can\|customer.* can\|delivers\|verifiable\|testable\|complete.*capability\|business.*capability\|server-side\|UI\|test\|smoke test\|coverage\|endpoint.*UI\|backend.*frontend" "End-to-end / vertical description"
    assert_content_contains "$relative" "risk\|Risk\|depends on\|Depends on\|blocks\|Blocks\|before\|after\|first\|uncertainty\|unknown\|prerequisite\|requires\|enables\|critical\|priority" "Dependency/risk/sequencing reasoning"
  done
fi

if [ "$scope_count" -eq 0 ]; then
  fail "No scope files found (scopes/scope-*.md)"
fi

# --- 5. Package→Scope prohibition ---
echo ""
echo "--- Package→Scope Prohibition ---"
assert_no_package_element_as_scope "$PACKAGE_PATH" "scopes/"

# --- 6. Handover quality (if present) ---
echo ""
echo "--- Handover Files (if present) ---"
handover_count=0
for handover_file in "$RESULTS_DIR"/handover-*.md; do
  [ -f "$handover_file" ] || continue
  handover_count=$((handover_count + 1))
  relative=$(echo "$handover_file" | sed "s|$RESULTS_DIR/||")
  echo "  Checking: $relative"
  assert_section_exists "$relative" "Completed This Session"
  assert_section_exists "$relative" "Next Session Should"
  assert_section_exists "$relative" "Scope Health Assessment"
  assert_content_contains "$relative" "risk\|Risk\|WHY\|why\|priority\|Priority" "Priority reasoning in handover"
done

if [ "$handover_count" -eq 0 ]; then
  echo "  (no handover files found — OK for single-session features)"
fi

# ============================================================
# Summary
# ============================================================

echo ""
echo "=== Summary ==="
echo -e "  ${GREEN}PASS${NC}: $PASS"
echo -e "  ${RED}FAIL${NC}: $FAIL"
echo -e "  ${YELLOW}WARN${NC}: $WARN"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}All structural checks passed.${NC}"
else
  echo -e "${RED}$FAIL check(s) failed.${NC}"
fi

exit "$FAIL"

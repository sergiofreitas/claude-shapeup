#!/bin/bash
# test-phase-guard.sh — Unit tests for hooks/phase-guard.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GUARD="$PROJECT_ROOT/hooks/phase-guard.sh"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

run_guard() {
  local prompt="$1"
  local tmpdir="$2"
  echo "{\"prompt\": \"$prompt\"}" | CLAUDE_PROJECT_DIR="$tmpdir" bash "$GUARD" 2>/dev/null
  return $?
}

run_guard_stderr() {
  local prompt="$1"
  local tmpdir="$2"
  echo "{\"prompt\": \"$prompt\"}" | CLAUDE_PROJECT_DIR="$tmpdir" bash "$GUARD" 2>&1
}

echo "=== Phase Guard: /shape gates ==="

# shape without frame.md
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/001-test-framing"
run_guard "/shape 001" "$TMPDIR" && fail "should block /shape without frame.md" || pass "/shape blocked without frame.md"
rm -rf "$TMPDIR"

# shape with frame.md but no Frame Go
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/001-test-framing"
echo "Status: Framing" > "$TMPDIR/.shapeup/001-test-framing/frame.md"
run_guard "/shape 001" "$TMPDIR" && fail "should block /shape without Frame Go" || pass "/shape blocked without Frame Go"
rm -rf "$TMPDIR"

# shape with Frame Go
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/001-test-framing"
echo "Status: Frame Go — approved 2026-04-17" > "$TMPDIR/.shapeup/001-test-framing/frame.md"
run_guard "/shape 001" "$TMPDIR" && pass "/shape allowed with Frame Go" || fail "should allow /shape with Frame Go"
rm -rf "$TMPDIR"

# shape on already-shaped feature
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/001-test-shaped"
echo "Status: Frame Go" > "$TMPDIR/.shapeup/001-test-shaped/frame.md"
run_guard "/shape 001" "$TMPDIR" && fail "should block /shape on -shaped folder" || pass "/shape blocked on already-shaped feature"
rm -rf "$TMPDIR"

echo ""
echo "=== Phase Guard: /build gates ==="

# build without package.md
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/001-test-shaped"
run_guard "/build 001" "$TMPDIR" && fail "should block /build without package.md" || pass "/build blocked without package.md"
rm -rf "$TMPDIR"

# build with package.md but no Shape Go
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/001-test-shaped"
echo "Status: Shaping" > "$TMPDIR/.shapeup/001-test-shaped/package.md"
run_guard "/build 001" "$TMPDIR" && fail "should block /build without Shape Go" || pass "/build blocked without Shape Go"
rm -rf "$TMPDIR"

# build with Shape Go
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/001-test-shaped"
echo "Status: Shape Go — approved 2026-04-17" > "$TMPDIR/.shapeup/001-test-shaped/package.md"
run_guard "/build 001" "$TMPDIR" && pass "/build allowed with Shape Go" || fail "should allow /build with Shape Go"
rm -rf "$TMPDIR"

# build on shipped feature
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/001-test-shipped"
run_guard "/build 001" "$TMPDIR" && fail "should block /build on shipped" || pass "/build blocked on shipped feature"
rm -rf "$TMPDIR"

# build on completed feature (build-summary exists)
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/001-test-building"
echo "# Build Summary" > "$TMPDIR/.shapeup/001-test-building/build-summary.md"
run_guard "/build 001" "$TMPDIR" && fail "should block /build when build-summary exists" || pass "/build blocked when build-summary.md exists"
rm -rf "$TMPDIR"

echo ""
echo "=== Phase Guard: /ship gates ==="

# ship without build-summary.md
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/001-test-building"
run_guard "/ship 001" "$TMPDIR" && fail "should block /ship without build-summary" || pass "/ship blocked without build-summary.md"
rm -rf "$TMPDIR"

# ship with build-summary.md
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/001-test-building"
echo "# Build Summary" > "$TMPDIR/.shapeup/001-test-building/build-summary.md"
run_guard "/ship 001" "$TMPDIR" && pass "/ship allowed with build-summary.md" || fail "should allow /ship with build-summary.md"
rm -rf "$TMPDIR"

# ship on already-shipped feature
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/001-test-shipped"
run_guard "/ship 001" "$TMPDIR" && fail "should block /ship on shipped" || pass "/ship blocked on already-shipped feature"
rm -rf "$TMPDIR"

echo ""
echo "=== Phase Guard: date-slug keys ==="

# /shape on date-slug key with Frame Go
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/2026-04-20-csv-import-framing"
echo "Status: Frame Go — approved 2026-04-20" > "$TMPDIR/.shapeup/2026-04-20-csv-import-framing/frame.md"
run_guard "/shape 2026-04-20-csv-import" "$TMPDIR" && pass "/shape allowed with date-slug key + Frame Go" || fail "should allow /shape with date-slug key"
rm -rf "$TMPDIR"

# /build on short-slug key (unambiguous)
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/2026-04-20-csv-import-shaped"
echo "Status: Shape Go" > "$TMPDIR/.shapeup/2026-04-20-csv-import-shaped/package.md"
run_guard "/build csv-import" "$TMPDIR" && pass "/build allowed with short slug + Shape Go" || fail "should allow /build with short slug"
rm -rf "$TMPDIR"

# /build on short slug that's ambiguous (two matching folders)
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/2026-04-20-csv-import-shaped"
mkdir -p "$TMPDIR/.shapeup/2026-04-19-csv-import-building"
echo "Status: Shape Go" > "$TMPDIR/.shapeup/2026-04-20-csv-import-shaped/package.md"
run_guard "/build csv-import" "$TMPDIR" && fail "should block ambiguous short-slug /build" || pass "/build blocked when short slug matches multiple features"
rm -rf "$TMPDIR"

# /shapeup:<skill> form
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/2026-04-20-csv-import-shaped"
echo "Status: Shape Go" > "$TMPDIR/.shapeup/2026-04-20-csv-import-shaped/package.md"
run_guard "/shapeup:build 2026-04-20-csv-import" "$TMPDIR" && pass "/shapeup:build accepted as well as /build" || fail "should accept /shapeup:<skill> form"
rm -rf "$TMPDIR"

# Legacy zero-padded NNN with octal-trap value (042)
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.shapeup/042-legacy-shaped"
echo "Status: Shape Go" > "$TMPDIR/.shapeup/042-legacy-shaped/package.md"
run_guard "/build 042" "$TMPDIR" && pass "/build accepts legacy 042 without octal misparse" || fail "should not octal-parse 042"
rm -rf "$TMPDIR"

echo ""
echo "=== Phase Guard: passthrough ==="

# non-shapeup commands pass through
TMPDIR=$(mktemp -d)
run_guard "explain the code" "$TMPDIR" && pass "non-shapeup command passes through" || fail "should pass through non-shapeup commands"
rm -rf "$TMPDIR"

# no .shapeup directory passes through
TMPDIR=$(mktemp -d)
run_guard "/build 001" "$TMPDIR" && pass "no .shapeup directory passes through" || fail "should pass through when no .shapeup dir"
rm -rf "$TMPDIR"

echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All phase guard tests passed." || echo "$FAIL test(s) failed."
exit "$FAIL"

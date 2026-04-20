#!/bin/bash
# test-resolve-feature.sh — Unit tests for hooks/lib/resolve-feature.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESOLVER="$PROJECT_ROOT/hooks/lib/resolve-feature.sh"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

echo "=== resolve-feature.sh ==="

# Full date-slug resolves to its folder
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/2026-04-20-csv-import-framing"
OUT=$(bash "$RESOLVER" "$TMPDIR" "2026-04-20-csv-import" 2>/dev/null)
[ "$OUT" = "$TMPDIR/2026-04-20-csv-import-framing" ] && pass "full date-slug resolves" || fail "full date-slug resolves (got: $OUT)"
rm -rf "$TMPDIR"

# Short slug resolves when unique
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/2026-04-20-csv-import-framing"
OUT=$(bash "$RESOLVER" "$TMPDIR" "csv-import" 2>/dev/null)
[ "$OUT" = "$TMPDIR/2026-04-20-csv-import-framing" ] && pass "short slug resolves when unique" || fail "short slug resolves when unique"
rm -rf "$TMPDIR"

# Short slug ambiguous → exit 2
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/2026-04-20-csv-import-framing" "$TMPDIR/2026-04-19-csv-import-building"
bash "$RESOLVER" "$TMPDIR" "csv-import" >/dev/null 2>&1
[ "$?" = "2" ] && pass "short slug ambiguous → exit 2" || fail "short slug ambiguous should exit 2"
rm -rf "$TMPDIR"

# Disambiguator: base slug matches only the non-hex folder
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/2026-04-20-csv-import-framing" "$TMPDIR/2026-04-20-csv-import-bc89-framing"
OUT=$(bash "$RESOLVER" "$TMPDIR" "2026-04-20-csv-import" 2>/dev/null)
[ "$OUT" = "$TMPDIR/2026-04-20-csv-import-framing" ] && pass "full date-slug doesn't collide with disambiguated sibling" || fail "full date-slug should not match disambiguated sibling (got: $OUT)"
rm -rf "$TMPDIR"

# Disambiguator: full key-with-hex resolves to hex folder
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/2026-04-20-csv-import-framing" "$TMPDIR/2026-04-20-csv-import-bc89-framing"
OUT=$(bash "$RESOLVER" "$TMPDIR" "2026-04-20-csv-import-bc89" 2>/dev/null)
[ "$OUT" = "$TMPDIR/2026-04-20-csv-import-bc89-framing" ] && pass "disambiguated key resolves to hex folder" || fail "disambiguated key should resolve (got: $OUT)"
rm -rf "$TMPDIR"

# Legacy NNN resolves
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/042-legacy-shipped"
OUT=$(bash "$RESOLVER" "$TMPDIR" "042" 2>/dev/null)
[ "$OUT" = "$TMPDIR/042-legacy-shipped" ] && pass "legacy NNN=042 resolves" || fail "legacy NNN=042 should resolve (got: $OUT)"
rm -rf "$TMPDIR"

# Legacy non-padded numeric resolves
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/007-legacy-shipped"
OUT=$(bash "$RESOLVER" "$TMPDIR" "7" 2>/dev/null)
[ "$OUT" = "$TMPDIR/007-legacy-shipped" ] && pass "legacy NNN=7 pads correctly" || fail "legacy NNN=7 should pad to 007 (got: $OUT)"
rm -rf "$TMPDIR"

# Missing key → exit 1
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/2026-04-20-csv-import-framing"
bash "$RESOLVER" "$TMPDIR" "nope" >/dev/null 2>&1
[ "$?" = "1" ] && pass "missing key → exit 1" || fail "missing key should exit 1"
rm -rf "$TMPDIR"

echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All resolver tests passed." || echo "$FAIL test(s) failed."
exit "$FAIL"

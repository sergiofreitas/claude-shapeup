#!/bin/bash
# test-consistency-check.sh — Unit tests for hooks/lib/check-consistency.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHECK="$PROJECT_ROOT/hooks/lib/check-consistency.sh"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

seed_feature() {
  # Usage: seed_feature <dir> <scope-file-contents> [hillchart-contents]
  local dir="$1"
  mkdir -p "$dir/scopes"
  cat > "$dir/frame.md" <<'EOF'
Status: Frame Go — approved 2026-04-18
EOF
  cat > "$dir/package.md" <<'EOF'
Status: Shape Go — approved 2026-04-19
EOF
}

echo "=== Consistency Check: audit mode ==="

# Clean feature with no scopes
TMPDIR=$(mktemp -d)
BASE="$TMPDIR/2026-04-20-clean-building"
seed_feature "$BASE"
bash "$CHECK" "$BASE" audit >/dev/null 2>&1 && pass "audit passes on clean feature with no scopes" || fail "audit should pass with no scopes"
rm -rf "$TMPDIR"

# Scope with unchecked must-have but not claiming Done
TMPDIR=$(mktemp -d)
BASE="$TMPDIR/2026-04-20-test-building"
seed_feature "$BASE"
cat > "$BASE/scopes/scope-foo.md" <<'EOF'
# Scope: foo
## Hill Position
▼ Downhill
## Must-Haves
- [x] Task done
- [ ] Task pending
EOF
bash "$CHECK" "$BASE" audit >/dev/null 2>&1 && pass "audit doesn't fail a downhill scope with unchecked must-have" || fail "audit mode should not fail on downhill scope"
rm -rf "$TMPDIR"

# Scope claiming Done but with unchecked must-have — audit should WARN+FAIL
TMPDIR=$(mktemp -d)
BASE="$TMPDIR/2026-04-20-test-building"
seed_feature "$BASE"
cat > "$BASE/scopes/scope-foo.md" <<'EOF'
# Scope: foo
## Hill Position
✓ Done
## Must-Haves
- [x] Task done
- [ ] Task pending
EOF
OUTPUT=$(bash "$CHECK" "$BASE" audit)
echo "$OUTPUT" | grep -q "claims ✓ Done but has" && pass "audit flags done-with-unchecked contradiction" || fail "audit should flag done scopes with unchecked items"
rm -rf "$TMPDIR"

echo ""
echo "=== Consistency Check: pre-ship mode ==="

# Clean ready-to-ship feature
TMPDIR=$(mktemp -d)
BASE="$TMPDIR/2026-04-20-ready-building"
seed_feature "$BASE"
cat > "$BASE/hillchart.md" <<'EOF'
# Hill Chart
## Scopes
  ✓ foo — Done
EOF
cat > "$BASE/scopes/scope-foo.md" <<'EOF'
# Scope: foo
## Hill Position
✓ Done
## Must-Haves
- [x] Task done
## Nice-to-Haves (~)
- [ ] ~ Nice thing deferred
EOF
bash "$CHECK" "$BASE" pre-ship >/dev/null 2>&1 && pass "pre-ship passes when scopes are all done with nice-to-haves deferred" || fail "pre-ship should accept uncut nice-to-haves"
rm -rf "$TMPDIR"

# Pre-ship with uphill scope — should fail
TMPDIR=$(mktemp -d)
BASE="$TMPDIR/2026-04-20-uphill-building"
seed_feature "$BASE"
cat > "$BASE/hillchart.md" <<'EOF'
# Hill Chart
## Scopes
  ▲ foo — Uphill
EOF
bash "$CHECK" "$BASE" pre-ship >/dev/null 2>&1 && fail "pre-ship should block when hill chart has uphill scopes" || pass "pre-ship blocks when hill chart has uphill scopes"
rm -rf "$TMPDIR"

# Pre-ship with unchecked must-have — should fail
TMPDIR=$(mktemp -d)
BASE="$TMPDIR/2026-04-20-unchecked-building"
seed_feature "$BASE"
cat > "$BASE/hillchart.md" <<'EOF'
# Hill Chart
## Scopes
  ✓ foo — Done
EOF
cat > "$BASE/scopes/scope-foo.md" <<'EOF'
# Scope: foo
## Hill Position
✓ Done
## Must-Haves
- [x] Task A done
- [ ] Task B pending
EOF
bash "$CHECK" "$BASE" pre-ship >/dev/null 2>&1 && fail "pre-ship should block unchecked must-have" || pass "pre-ship blocks on unchecked must-have"
rm -rf "$TMPDIR"

# Pre-ship with missing Frame Go — should fail
TMPDIR=$(mktemp -d)
BASE="$TMPDIR/2026-04-20-nogo-building"
mkdir -p "$BASE"
echo "Status: Framing" > "$BASE/frame.md"
echo "Status: Shape Go" > "$BASE/package.md"
bash "$CHECK" "$BASE" pre-ship >/dev/null 2>&1 && fail "pre-ship should block missing Frame Go" || pass "pre-ship blocks on missing Frame Go"
rm -rf "$TMPDIR"

echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
[ "$FAIL" -eq 0 ] && echo "All consistency-check tests passed." || echo "$FAIL test(s) failed."
exit "$FAIL"
